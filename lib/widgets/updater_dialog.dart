import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/updater_provider.dart';
import '../providers/subject_provider.dart';
import '../core/theme/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:typed_data';

class UpdaterDialog extends ConsumerStatefulWidget {
  const UpdaterDialog({super.key});

  @override
  ConsumerState<UpdaterDialog> createState() => _UpdaterDialogState();
}

class _UpdaterDialogState extends ConsumerState<UpdaterDialog> {
  bool _showBackupPrompt = false;
  // Explicit controller required for Scrollbar on desktop (Linux/Windows)
  final ScrollController _changelogScrollController = ScrollController();

  @override
  void dispose() {
    _changelogScrollController.dispose();
    super.dispose();
  }

  // Standalone backup export inside dialog to guarantee data safety
  Future<void> _exportBackup(BuildContext context) async {
    try {
      final db = ref.read(appDatabaseProvider);
      
      final categoriesList = await db.select(db.categories).get();
      final subjectsList = await db.select(db.subjects).get();

      final categoryMap = {for (var c in categoriesList) c.id: c.name};

      final exportedCategories = categoriesList.map((c) => {
        'name': c.name,
        'color': c.color,
        'position': c.position,
      }).toList();

      final exportedSubjects = subjectsList.map((s) => {
        'name': s.name,
        'categoryName': categoryMap[s.categoryId] ?? 'General',
        'completedVideos': s.completedVideos,
        'totalVideos': s.totalVideos,
        'playlistLink': s.playlistLink,
        'sourceName': s.sourceName,
        'isActive': s.isActive,
        'position': s.position,
        'color': s.color,
      }).toList();

      final exportPayload = {
        'version': 1,
        'categories': exportedCategories,
        'subjects': exportedSubjects,
      };

      final json = const JsonEncoder.withIndent('  ').convert(exportPayload);
      final bytes = Uint8List.fromList(utf8.encode(json));

      final path = await FilePicker.saveFile(
        dialogTitle: 'Save backup before updating',
        fileName: 'gate_tracker_backup_pre_update.json',
        bytes: bytes,
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup saved successfully!')),
        );
        setState(() {
          _showBackupPrompt = false; // Progress to actual download
        });
        ref.read(updaterProvider.notifier).downloadUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final state = ref.watch(updaterProvider);
    final accentColor = ref.watch(overallProgressColorProvider);

    // Limit layout constraint strictly to maximum 75% of screen dimensions
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width * 0.75,
          maxHeight: size.height * 0.75,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withAlpha(51), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(26),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _buildDialogContent(context, state, accentColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context, UpdaterState state, Color accentColor) {
    // 1. Android Backup Intercept UI
    if (_showBackupPrompt) {
      return _buildBackupPromptContent(context, accentColor);
    }

    switch (state.status) {
      case UpdaterStatus.idle:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final route = ModalRoute.of(context);
            if (route != null && route.isCurrent) {
              Navigator.of(context).pop();
            }
          }
        });
        return const SizedBox.shrink();

      case UpdaterStatus.checking:
        return _buildLoadingContent("CHECKING FOR UPDATES...", accentColor);

      case UpdaterStatus.updateAvailable:
        return _buildUpdateAvailableContent(context, state, accentColor);

      case UpdaterStatus.downloading:
        return _buildDownloadingContent(state, accentColor);

      case UpdaterStatus.downloadSuccess:
        return _buildDownloadSuccessContent(state, accentColor);

      case UpdaterStatus.windowsSavedSuccess:
        return _buildWindowsSavedSuccessContent(accentColor);

      case UpdaterStatus.downloadError:
      case UpdaterStatus.error:
        return _buildErrorContent(state, accentColor);

      default:
        // Fallback loading check
        return _buildLoadingContent("PROCESSING...", accentColor);
    }
  }

  Widget _buildLoadingContent(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 16,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupPromptContent(BuildContext context, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.amberAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "BACKUP STRONGLY ADVISED",
            style: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 15,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Before upgrading, we strongly recommend backing up your subject tracking progress to prevent any potential data loss.",
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _exportBackup(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(
              "EXPORT BACKUP DATA",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _showBackupPrompt = false;
              });
              ref.read(updaterProvider.notifier).downloadUpdate();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              "Skip & Continue Download",
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailableContent(BuildContext context, UpdaterState state, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            "NEW UPDATE AVAILABLE",
            style: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 16,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Version badge indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVersionBadge(state.currentVersion, Colors.grey),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: accentColor, size: 16),
              const SizedBox(width: 8),
              _buildVersionBadge(state.latestVersion, accentColor),
            ],
          ),
          const SizedBox(height: 20),

          // Changelog Header
          Text(
            "WHAT'S NEW",
            style: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 11,
              letterSpacing: 1.2,
              color: Colors.white.withAlpha(128),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable Changelog
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                controller: _changelogScrollController,
                child: SingleChildScrollView(
                  controller: _changelogScrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      state.changelog,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    ref.read(updaterProvider.notifier).dismissUpdateFor24Hours();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
                  ),
                  child: Text(
                    "REMIND LATER",
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (Platform.isAndroid) {
                      setState(() {
                        _showBackupPrompt = true; // Launch backup intercept
                      });
                    } else if (Platform.isLinux) {
                      // Redirect directly
                      ref.read(updaterProvider.notifier).downloadUpdate();
                      Navigator.pop(context);
                    } else {
                      // Windows starts downloading directly
                      ref.read(updaterProvider.notifier).downloadUpdate();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "DOWNLOAD",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVersionBadge(String version, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        version.startsWith('v') ? version : 'v$version',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDownloadingContent(UpdaterState state, Color accentColor) {
    final double pct = state.progress;
    final String pctText = "${(pct * 100).toStringAsFixed(1)}%";

    // Parse bytes downloaded and total
    final String sizeText = state.totalBytes > 0
        ? "${(state.bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB / ${(state.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB"
        : "... MB / ... MB";

    final String speedText = "${state.speedMBs.toStringAsFixed(1)} MB/s";

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Icon(
              Icons.cloud_download_rounded,
              color: accentColor,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "DOWNLOADING UPDATE",
            style: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 14,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Size text and percentage side-by-side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sizeText,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                pctText,
                style: GoogleFonts.outfit(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Premium Linear progress bar with neon overlay shadows
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withAlpha(26),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Download speed & ETA estimated details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                speedText,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              Text(
                state.etaString,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Android-only: open download link in browser as fallback
          if (Platform.isAndroid && state.downloadUrl.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(state.downloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: accentColor.withAlpha(80)),
              ),
              icon: Icon(Icons.open_in_browser_rounded, size: 16, color: accentColor),
              label: Text(
                "DOWNLOAD IN BROWSER INSTEAD",
                style: GoogleFonts.outfit(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Abort Cancel button
          OutlinedButton(
            onPressed: () {
              ref.read(updaterProvider.notifier).cancelDownload();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.white10),
            ),
            child: Text(
              "CANCEL",
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSuccessContent(UpdaterState state, Color accentColor) {
    final bool isAndroid = Platform.isAndroid;

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Icon(
              Icons.download_done_rounded,
              color: accentColor,
              size: 52,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "DOWNLOAD COMPLETE",
            style: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 14,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          if (isAndroid) ...[
            // Android: manual install instructions
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                "The APK is ready. Save it to your device and install it manually.\n\n"
                "⚠️  You may need to uninstall the current version first. "
                "If so, backup your data from Settings before proceeding.",
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // Primary action: Save APK
            FilledButton.icon(
              onPressed: () => ref.read(updaterProvider.notifier).saveAndroidApk(),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save_alt_rounded, size: 18),
              label: Text(
                "SAVE APK FILE",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary: dismiss
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
              ),
              child: Text(
                "OK",
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ] else ...[
            // Windows: save zip
            Text(
              "The ZIP archive downloaded successfully. Click below to choose where to save the file.",
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => ref.read(updaterProvider.notifier).saveWindowsZip(),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "SAVE ZIP FILE",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWindowsSavedSuccessContent(Color accentColor) {
    final bool isAndroid = Platform.isAndroid;

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Icon(
              isAndroid ? Icons.save_alt_rounded : Icons.archive_outlined,
              color: accentColor,
              size: 52,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "SAVED SUCCESSFULLY",
            style: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 13,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              isAndroid
                  ? "APK shared successfully! If you chose 'Save to Files' or 'Copy to folder' from your share sheet, please open your device's File Manager, locate that APK, and tap it to install the update manually."
                  : "To use the new version, simply extract the downloaded ZIP file and run the new 'gate_tracker.exe' file inside. You can safely delete your old app folder. All tracking records will remain fully intact.",
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),

          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "DONE",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(UpdaterState state, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "SOMETHING WENT WRONG",
            style: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 13,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            state.errorMessage.isNotEmpty
                ? state.errorMessage
                : "An unexpected failure occurred while updating.",
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    ref.read(updaterProvider.notifier).cancelDownload();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
                  ),
                  child: Text(
                    "DISMISS",
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (state.status == UpdaterStatus.error) {
                      ref.read(updaterProvider.notifier).checkForUpdates();
                    } else {
                      ref.read(updaterProvider.notifier).downloadUpdate();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "RETRY",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
