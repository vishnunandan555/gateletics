import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

// --- CONFIGURATION ---
// FOR TESTING: Pointing to a repository with active releases (jameskokoska/Cashew)
// To revert back to your original repository, simply comment out the Cashew variables and uncomment the gate-tracker variables.
const String kGitHubOwner = "jameskokoska"; // Original: "vishnunandan555"
const String kGitHubRepo = "Cashew";         // Original: "gate-tracker"

// Set to true to force update popup to display in dev mode
const bool kDebugForceUpdateAvailable = false;
const String kDebugMockVersion = "9.9.9";
const String kDebugMockChangelog = "GATE Tracker v9.9.9 (Premium Edition)\n\n"
    "• Added Multi-Platform Self-Updater!\n"
    "• Implemented isolated Desktop database path containment.\n"
    "• Extremely polished layout with dynamic accent colors.\n"
    "• Standard body text Outfit fonts, title BatmanForever uppercase.\n"
    "• High fidelity download speed statistics and remaining ETA indicators.\n"
    "• Restored Windows & Linux data integrity.";

enum UpdaterStatus {
  idle,
  checking,
  updateAvailable,
  noUpdateAvailable,
  downloading,
  downloadSuccess,
  downloadError,
  windowsSavedSuccess,
  error,
}

class UpdaterState {
  final UpdaterStatus status;
  final String currentVersion;
  final String latestVersion;
  final String changelog;
  final String downloadUrl;
  final double progress; // 0.0 to 1.0
  final double speedMBs; // MB/s
  final String etaString;
  final String downloadedFilePath;
  final Uint8List? downloadedBytes;
  final String errorMessage;
  final int bytesDownloaded;
  final int totalBytes;

  UpdaterState({
    this.status = UpdaterStatus.idle,
    this.currentVersion = '',
    this.latestVersion = '',
    this.changelog = '',
    this.downloadUrl = '',
    this.progress = 0.0,
    this.speedMBs = 0.0,
    this.etaString = '',
    this.downloadedFilePath = '',
    this.downloadedBytes,
    this.errorMessage = '',
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
  });

  UpdaterState copyWith({
    UpdaterStatus? status,
    String? currentVersion,
    String? latestVersion,
    String? changelog,
    String? downloadUrl,
    double? progress,
    double? speedMBs,
    String? etaString,
    String? downloadedFilePath,
    Uint8List? downloadedBytes,
    String? errorMessage,
    int? bytesDownloaded,
    int? totalBytes,
  }) {
    return UpdaterState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      changelog: changelog ?? this.changelog,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      progress: progress ?? this.progress,
      speedMBs: speedMBs ?? this.speedMBs,
      etaString: etaString ?? this.etaString,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }
}

class UpdaterNotifier extends Notifier<UpdaterState> {
  @override
  UpdaterState build() {
    return UpdaterState();
  }

  Timer? _simulatedTimer;

  // Semantically compares current version string vs latest version string
  bool isVersionNewer(String current, String latest) {
    String cleanCurrent = current.trim().startsWith('v') || current.trim().startsWith('V')
        ? current.trim().substring(1)
        : current.trim();
    String cleanLatest = latest.trim().startsWith('v') || latest.trim().startsWith('V')
        ? latest.trim().substring(1)
        : latest.trim();

    List<int> currentParts = cleanCurrent.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts = cleanLatest.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < math.max(currentParts.length, latestParts.length); i++) {
      int curr = i < currentParts.length ? currentParts[i] : 0;
      int lat = i < latestParts.length ? latestParts[i] : 0;
      if (lat > curr) return true;
      if (curr > lat) return false;
    }
    return false;
  }

  // Dismisses the update check, setting a 24-hour silence stamp
  Future<void> dismissUpdateFor24Hours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_update_dismissed_time', DateTime.now().millisecondsSinceEpoch);
    state = state.copyWith(status: UpdaterStatus.idle);
  }

  // Checks GitHub for updates
  Future<void> checkForUpdates({bool isAutomatic = false}) async {
    if (state.status == UpdaterStatus.checking || state.status == UpdaterStatus.downloading) return;

    state = state.copyWith(status: UpdaterStatus.checking);

    try {
      // 1. Resolve local/current version
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVer = packageInfo.version;

      // 2. Get shared prefs once for all checks
      final prefs = await SharedPreferences.getInstance();

      // 3. Auto-check guards (skip for manual checks)
      if (isAutomatic && !kDebugForceUpdateAvailable) {
        final int nowMs = DateTime.now().millisecondsSinceEpoch;

        // Don't check if user dismissed within 24 hours
        final int lastDismissed = prefs.getInt('last_update_dismissed_time') ?? 0;
        if ((nowMs - lastDismissed) < 24 * 60 * 60 * 1000) {
          state = state.copyWith(status: UpdaterStatus.idle, currentVersion: currentVer);
          return;
        }

        // Respect the user's chosen check frequency (Daily/Weekly/Monthly)
        final String frequency = prefs.getString('update_check_frequency') ?? 'Weekly';
        final String? lastCheckStr = prefs.getString('last_update_check_time');
        if (lastCheckStr != null) {
          final lastCheck = DateTime.tryParse(lastCheckStr);
          if (lastCheck != null) {
            final Duration sinceLastCheck = DateTime.now().difference(lastCheck);
            final int freqDays = frequency == 'Daily' ? 1 : frequency == 'Monthly' ? 30 : 7;
            if (sinceLastCheck.inDays < freqDays) {
              state = state.copyWith(status: UpdaterStatus.idle, currentVersion: currentVer);
              return;
            }
          }
        }
      }

      // 4. Record check timestamp immediately (before network call)
      await prefs.setString('last_update_check_time', DateTime.now().toIso8601String());
      ref.invalidate(lastUpdateCheckTimeProvider);

      // 3. Debug mock override
      if (kDebugForceUpdateAvailable) {
        state = state.copyWith(
          status: UpdaterStatus.updateAvailable,
          currentVersion: currentVer,
          latestVersion: kDebugMockVersion,
          changelog: kDebugMockChangelog,
          downloadUrl: "mock://download-url-for-demo.apk",
        );
        return;
      }

      // 4. API Request to GitHub
      final response = await http.get(
        Uri.parse("https://api.github.com/repos/$kGitHubOwner/$kGitHubRepo/releases/latest"),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) {
        throw Exception("GitHub API returned status ${response.statusCode}");
      }

      final json = jsonDecode(response.body);
      final String latestVer = json['tag_name'] as String;
      final String changelogText = json['body'] as String? ?? "No changelog details provided.";

      final bool hasNewUpdate = isVersionNewer(currentVer, latestVer);

      if (hasNewUpdate) {
        // Find matching binary download url based on platform
        String dlUrl = "";
        final assets = json['assets'] as List<dynamic>? ?? [];

        if (Platform.isAndroid) {
          // Look for .apk file asset
          final apkAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.apk'),
            orElse: () => null,
          );
          if (apkAsset != null) {
            dlUrl = apkAsset['browser_download_url'] as String;
          }
        } else if (Platform.isWindows) {
          // Look for windows.zip or any .zip asset
          final zipAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).toLowerCase().contains('windows') || (asset['name'] as String).endsWith('.zip'),
            orElse: () => null,
          );
          if (zipAsset != null) {
            dlUrl = zipAsset['browser_download_url'] as String;
          }
        }

        // If no matching asset url was found but version is newer, fallback to browser redirection on HTML url
        if (dlUrl.isEmpty) {
          dlUrl = json['html_url'] as String? ?? "https://github.com/$kGitHubOwner/$kGitHubRepo/releases/latest";
        }

        state = state.copyWith(
          status: UpdaterStatus.updateAvailable,
          currentVersion: currentVer,
          latestVersion: latestVer,
          changelog: changelogText,
          downloadUrl: dlUrl,
        );
      } else {
        state = state.copyWith(
          status: UpdaterStatus.noUpdateAvailable,
          currentVersion: currentVer,
          latestVersion: latestVer,
        );
      }
      ref.invalidate(lastUpdateCheckTimeProvider);
    } catch (e) {
      debugPrint("Updater failed checking updates: $e");
      state = state.copyWith(
        status: UpdaterStatus.error,
        errorMessage: e.toString(),
      );
      ref.invalidate(lastUpdateCheckTimeProvider);
    }
  }

  // Cancels active simulated or real download
  void cancelDownload() {
    _simulatedTimer?.cancel();
    state = state.copyWith(
      status: UpdaterStatus.idle,
      progress: 0.0,
      speedMBs: 0.0,
      etaString: '',
    );
  }

  // Resets to idle (used after noUpdateAvailable / check error snackbars)
  void resetToIdle() {
    state = state.copyWith(status: UpdaterStatus.idle);
  }

  // Triggered to start the download sequence
  Future<void> downloadUpdate() async {
    if (state.status != UpdaterStatus.updateAvailable && state.status != UpdaterStatus.downloadError) return;

    state = state.copyWith(
      status: UpdaterStatus.downloading,
      progress: 0.0,
      speedMBs: 0.0,
      etaString: 'Calculating...',
    );

    // MOCK SIMULATION OR REAL DOWNLOAD FLOW
    if (kDebugForceUpdateAvailable || state.downloadUrl.startsWith("mock://")) {
      await _runSimulatedDownload();
      return;
    }

    if (Platform.isLinux) {
      // Linux just forwards to browser directly, no background downloading needed!
      await launchUrl(Uri.parse(state.downloadUrl));
      state = state.copyWith(status: UpdaterStatus.idle);
      return;
    }

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(state.downloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception("Server returned code ${response.statusCode} while downloading.");
      }

      final total = response.contentLength;
      final bytesBuilder = BytesBuilder(copy: false);
      int downloaded = 0;

      final stopwatch = Stopwatch()..start();

      final streamSubscription = response.listen(
        (chunk) {
          bytesBuilder.add(chunk);
          downloaded += chunk.length;

          final progress = total > 0 ? downloaded / total : 0.0;
          final elapsedSecs = stopwatch.elapsedMilliseconds / 1000.0;
          final speed = elapsedSecs > 0 ? (downloaded / (1024 * 1024)) / elapsedSecs : 0.0;

          String eta = 'Calculating...';
          if (speed > 0 && total > 0) {
            final remainingBytes = total - downloaded;
            final remainingSecs = (remainingBytes / (1024 * 1024)) / speed;
            eta = 'ETA: ${remainingSecs.toStringAsFixed(0)}s';
          }

          state = state.copyWith(
            progress: progress,
            speedMBs: speed,
            etaString: eta,
            bytesDownloaded: downloaded,
            totalBytes: total,
          );
        },
        onError: (e) {
          throw Exception("Streaming download error: $e");
        },
        cancelOnError: true,
      );

      await streamSubscription.asFuture();
      stopwatch.stop();

      final fileBytes = bytesBuilder.takeBytes();

      if (Platform.isAndroid) {
        // Save APK to temporary cache
        final tempDir = await getTemporaryDirectory();
        final apkFile = File('${tempDir.path}/gate_tracker_update.apk');
        if (apkFile.existsSync()) {
          await apkFile.delete();
        }
        await apkFile.writeAsBytes(fileBytes);

        state = state.copyWith(
          status: UpdaterStatus.downloadSuccess,
          downloadedFilePath: apkFile.path,
          progress: 1.0,
        );
      } else if (Platform.isWindows) {
        state = state.copyWith(
          status: UpdaterStatus.downloadSuccess,
          downloadedBytes: fileBytes,
          progress: 1.0,
        );
      }
    } catch (e) {
      debugPrint("Updater download failed: $e");
      state = state.copyWith(
        status: UpdaterStatus.downloadError,
        errorMessage: e.toString(),
      );
    }
  }

  // Run the simulated download flow for visual testing
  Future<void> _runSimulatedDownload() async {
    const totalSimBytes = 18.5 * 1024 * 1024; // 18.5 MB
    int simDownloaded = 0;
    final stopwatch = Stopwatch()..start();

    _simulatedTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      // Increments download by random amount between 300KB and 800KB
      final chunk = (300 + math.Random().nextInt(500)) * 1024;
      simDownloaded += chunk;

      if (simDownloaded >= totalSimBytes) {
        simDownloaded = totalSimBytes.toInt();
        timer.cancel();
        stopwatch.stop();

        // APK or Windows complete
        if (Platform.isAndroid) {
          state = state.copyWith(
            status: UpdaterStatus.downloadSuccess,
            progress: 1.0,
            downloadedFilePath: "/simulated/cache/gate_tracker_update.apk",
          );
        } else {
          state = state.copyWith(
            status: UpdaterStatus.downloadSuccess,
            progress: 1.0,
            downloadedBytes: Uint8List(0),
          );
        }
      } else {
        final progress = simDownloaded / totalSimBytes;
        final elapsedSecs = stopwatch.elapsedMilliseconds / 1000.0;
        final speed = elapsedSecs > 0 ? (simDownloaded / (1024 * 1024)) / elapsedSecs : 0.0;

        String eta = 'Calculating...';
        if (speed > 0) {
          final remainingBytes = totalSimBytes - simDownloaded;
          final remainingSecs = (remainingBytes / (1024 * 1024)) / speed;
          eta = 'ETA: ${remainingSecs.toStringAsFixed(0)}s';
        }

        state = state.copyWith(
          progress: progress,
          speedMBs: speed,
          etaString: eta,
          bytesDownloaded: simDownloaded,
          totalBytes: totalSimBytes.toInt(),
        );
      }
    });
  }

  // Opens the save dialog on Windows to store the ZIP
  Future<void> saveWindowsZip() async {
    final bytes = state.downloadedBytes;
    if (bytes == null) return;

    try {
      final path = await FilePicker.saveFile(
        dialogTitle: 'Save Windows Zip package',
        fileName: 'gate_tracker_windows.zip',
        bytes: bytes,
      );

      if (path != null) {
        state = state.copyWith(status: UpdaterStatus.windowsSavedSuccess);
      }
    } catch (e) {
      state = state.copyWith(
        status: UpdaterStatus.downloadError,
        errorMessage: "Failed to save file: $e",
      );
    }
  }

  // Opens the file manager so the user can save the APK.
  // Result is intentionally ignored — user stays on the download-complete screen.
  Future<void> saveAndroidApk() async {
    if (Platform.isAndroid && state.downloadedFilePath.isNotEmpty) {
      // Mock flow: nothing to do
      if (kDebugForceUpdateAvailable || state.downloadedFilePath.contains("simulated")) {
        return;
      }
      try {
        final file = File(state.downloadedFilePath);
        if (!file.existsSync()) return;
        final bytes = await file.readAsBytes();
        // Open the file manager — don't check the returned path or result
        await FilePicker.saveFile(
          dialogTitle: 'Save GATE Tracker Update APK',
          fileName: 'gate_tracker_update.apk',
          bytes: bytes,
        );
      } catch (_) {
        // Silently ignore any errors — user stays on the same screen
      }
    }
  }
}

// Global provider for accessing the Updater
final updaterProvider = NotifierProvider<UpdaterNotifier, UpdaterState>(() {
  return UpdaterNotifier();
});

final lastUpdateCheckTimeProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final timeStr = prefs.getString('last_update_check_time');
  if (timeStr == null) return 'Never';
  try {
    final dt = DateTime.parse(timeStr);
    final now = DateTime.now();
    final diff = now.difference(dt).abs();
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      final tStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return 'Today, $tStr';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  } catch (_) {
    return 'Never';
  }
});

class UpdateFrequencyNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'Weekly';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('update_check_frequency') ?? 'Weekly';
  }

  Future<void> setFrequency(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('update_check_frequency', val);
    state = val;
  }
}

final updateFrequencyProvider = NotifierProvider<UpdateFrequencyNotifier, String>(() {
  return UpdateFrequencyNotifier();
});
