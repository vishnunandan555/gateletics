import 'dart:convert';
import 'dart:io' show File;
import 'dart:ui' show ImageFilter;
import '../../core/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/agreement_provider.dart';
import '../../providers/setup_provider.dart';

import '../../providers/subject_provider.dart';
// Removed completion_type_provider import
import '../../providers/syllabus_provider.dart';
import '../../providers/package_info_provider.dart';
import '../../providers/progress_font_provider.dart';
import '../../providers/quotes_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/category_autosort_provider.dart';
import '../../providers/focus_animation_provider.dart';
import '../../providers/category_font_size_provider.dart';
import '../../providers/topic_font_size_provider.dart';
import '../../providers/task_font_size_provider.dart';
import '../../providers/overall_ui_scale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/hide_download_banner_provider.dart';
import '../../providers/show_projected_completion_provider.dart';
import '../../providers/disable_graph_glow_provider.dart';
import '../../providers/glow_strength_provider.dart';
import '../../providers/disable_home_screen_widget_provider.dart';
import 'widgets/shell_common.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database/backup_service.dart';
import '../../database/app_database.dart';
import '../../providers/rollover_provider.dart';
import '../../providers/daily_history_provider.dart';
import 'package:drift/drift.dart' hide Column;
import '../../widgets/settings/about_dialog.dart';
import '../../utils/ui_scaling.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget _buildDownloadBanner(BuildContext context, WidgetRef ref, Color accentColor) {
    final hideBanner = ref.watch(hideDownloadBannerProvider);
    if (!kIsWeb || hideBanner) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices_rounded, color: accentColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Get GATEletics on all devices',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Sync your prep status seamlessly! GATEletics is also available as a native app for Android, Windows, and Linux.',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 11,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final url = Uri.parse('https://vishnunandan555.github.io/gateletics/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Download Now',
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new_rounded, color: accentColor, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final exportPayload = await BackupService.exportDatabase(db);
      final json = const JsonEncoder.withIndent('  ').convert(exportPayload);

      String? path;
      if (kIsWeb) {
        final bytes = Uint8List.fromList(utf8.encode(json));
        path = await FilePicker.saveFile(
          dialogTitle: 'Save backup to device',
          fileName: 'gateletics_backup.json',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } else if (defaultTargetPlatform == TargetPlatform.android ||
                 defaultTargetPlatform == TargetPlatform.iOS) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/gateletics_backup.json');
        await tempFile.writeAsString(json);

        final params = SaveFileDialogParams(
          sourceFilePath: tempFile.path,
          fileName: 'gateletics_backup.json',
        );
        path = await FlutterFileDialog.saveFile(params: params);
      } else {
        final bytes = Uint8List.fromList(utf8.encode(json));
        path = await FilePicker.saveFile(
          dialogTitle: 'Save backup to device',
          fileName: 'gateletics_backup.json',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(bytes);
        }
      }

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      Uint8List? bytes;
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
           defaultTargetPlatform != TargetPlatform.iOS)) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (result == null || result.files.isEmpty) return;
        bytes = await result.files.single.readAsBytes();
      } else {
        final params = OpenFileDialogParams(
          dialogType: OpenFileDialogType.document,
          fileExtensionsFilter: ['json'],
        );
        final filePath = await FlutterFileDialog.pickFile(params: params);
        if (filePath == null) return;
        bytes = await File(filePath).readAsBytes();
      }

      final raw = utf8.decode(bytes);
      final payload = jsonDecode(raw);
      final db = ref.read(appDatabaseProvider);

      // Full restore using BackupService
      await BackupService.restoreDatabase(db, payload);
      ref.read(syncProvider.notifier).clearDatabaseCaches();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Backup data successfully restored!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        String message = 'Import failed: $e';
        if (e is PlatformException && e.code == 'invalid_file_extension') {
          message = 'Invalid file type selected. Only JSON (.json) files are supported for importing backup files.';
        } else if (e is FormatException) {
          message = 'The selected file is not a valid JSON file. Please ensure you picked a valid backup file.';
        } else if (e is TypeError || e is StateError) {
          message = 'The selected file does not contain valid backup data.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _performReset(BuildContext context, WidgetRef ref,
      {required bool everything}) async {
    final title = everything ? 'Reset Everything' : 'Reset Tracking Data';
    final content = everything
        ? 'This will clear ALL your sources, links, and progress. This cannot be undone.'
        : 'This will reset all your progress counts to zero but keep your sources and links.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      if (everything) {
        // 1. Sign out on the server and locally
        await ref.read(authProvider.notifier).resetAuthChoice();

        // 2. Delete all database tables completely
        final db = ref.read(appDatabaseProvider);
        await db.delete(db.syllabusTasks).go();
        await db.delete(db.syllabusTopics).go();
        await db.delete(db.syllabusCategories).go();
        await db.delete(db.focusSessions).go();
        await db.delete(db.dailyHistory).go();
        await db.delete(db.customTasks).go();

        // 3. Clear SharedPreferences completely
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // 4. Invalidate/reset all providers
        ref.invalidate(authProvider);
        ref.invalidate(syllabusProvider);
        ref.read(focusProvider.notifier).resetState();
        ref.invalidate(todayFocusSessionsProvider);
        ref.invalidate(todayFocusDurationProvider);
        ref.invalidate(dailyFocusGoalProvider);
        ref.invalidate(focusQuotesEnabledProvider);

        ref.invalidate(agreementProvider);
        ref.invalidate(setupCompletedProvider);
        ref.invalidate(categoryFontSizeProvider);
        ref.invalidate(topicFontSizeProvider);
        ref.invalidate(taskFontSizeProvider);
        ref.invalidate(overallUiScaleProvider);
        await ref.read(overallProgressColorProvider.notifier).setAutoMode();
      } else {
        // 1. Reset syllabus tracking completions
        await ref.read(syllabusControllerProvider.notifier).resetTrackingData();

        // 2. Delete focus sessions, daily history, and custom tasks tables
        final db = ref.read(appDatabaseProvider);
        await db.delete(db.focusSessions).go();
        await db.delete(db.dailyHistory).go();
        await db.delete(db.customTasks).go();

        // 3. Invalidate relevant tracking providers
        ref.invalidate(todayFocusSessionsProvider);
        ref.invalidate(todayFocusDurationProvider);
        ref.invalidate(dailyFocusGoalProvider);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(everything ? 'System reset!' : 'Progress reset!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  void _showSyncConflictDialog(BuildContext context, WidgetRef ref) {
    final accentColor = ref.read(overallProgressColorProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Sync Conflict Detected",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Both your local device and cloud backup contain study tracking progress. How would you like to resolve this conflict?",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final localData = await ref.read(syncProvider.notifier).exportLocalData();
                  final cloudData = ref.read(syncProvider).pendingCloudData;
                  if (cloudData != null && context.mounted) {
                    showConflictDetailsDialog(context, localData, cloudData, accentColor);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor.withAlpha(100)),
                  foregroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: Text(
                  "Compare Data (View Conflicts)",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              _buildDialogOption(
                context: context,
                title: "Merge Progress (Recommended)",
                subtitle: "Combine local and cloud progress (no data lost)",
                icon: Icons.merge_type_rounded,
                color: Colors.cyanAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).mergeCloudAndLocal();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                context: context,
                title: "Use Cloud Backup",
                subtitle: "Overwrite local data with your cloud backup",
                icon: Icons.cloud_download_rounded,
                color: Colors.greenAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).downloadCloudToLocal();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                context: context,
                title: "Keep Local Progress",
                subtitle: "Overwrite cloud data with your local progress",
                icon: Icons.cloud_upload_rounded,
                color: Colors.orangeAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).uploadLocalToCloud();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withAlpha(5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    if (isToday) {
      return "$hour:$minute";
    } else {
      final day = time.day.toString().padLeft(2, '0');
      final month = time.month.toString().padLeft(2, '0');
      return "$day/$month $hour:$minute";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final accentColor = ref.watch(overallProgressColorProvider);
    final autoSort = ref.watch(categoryAutoSortProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 900;

    final titleStyle = GoogleFonts.outfit(
      color: Colors.white,
      fontSize: context.s(13),
      fontWeight: FontWeight.bold,
    );

    final subtitleStyle = GoogleFonts.outfit(
      color: Colors.white30,
      fontSize: context.s(11),
    );

    Widget buildHeader(String title, {Color? color}) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
        child: Text(
          title,
          style: TextStyle(
            color: (color ?? accentColor).withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            fontSize: context.s(11),
            letterSpacing: context.s(1.2),
          ),
        ),
      );
    }

    Widget buildSettingsGroup(Widget child) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(6)),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(context.s(16)),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.s(16)),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      );
    }

    final cloudSyncHeader = buildHeader('CLOUD SYNC');

    final cloudSyncContent = isFirebaseSupported()
        ? Consumer(
            builder: (context, ref, _) {
              final authAsync = ref.watch(authProvider);
              final syncState = ref.watch(syncProvider);

              return authAsync.when(
                data: (authState) {
                  final user = authState.user;
                  final isOffline = authState.isOfflineMode;

                  if (user == null || isOffline) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cloud_off_rounded, color: Colors.white60),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Offline Mode Enabled",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your progress is stored locally on this device. Sign in with Google to enable automatic cloud sync and backups.",
                              style: GoogleFonts.outfit(
                                color: Colors.white30,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () async {
                                try {
                                  await ref.read(authProvider.notifier).signInWithGoogle();
                                  final needsAction = await ref.read(syncProvider.notifier).initializeSync();
                                  if (needsAction && context.mounted) {
                                    _showSyncConflictDialog(context, ref);
                                  } else if (context.mounted) {
                                    final finalState = ref.read(syncProvider);
                                    if (finalState.status == SyncStatus.success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✓ Sync initialized successfully!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Google Sign-in failed: $e')),
                                    );
                                  }
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: Text(
                                "SIGN IN WITH GOOGLE",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            _buildDownloadBanner(context, ref, accentColor),
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                                backgroundColor: accentColor.withValues(alpha: 0.2),
                                child: user.photoURL == null ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName ?? "GATEletics User",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      user.email ?? "",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white30,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Sync Status:",
                                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      syncState.status == SyncStatus.syncing
                                          ? "Syncing..."
                                          : syncState.status == SyncStatus.error
                                              ? "Sync Error"
                                              : syncState.lastSyncedAt != null
                                                  ? "Last Synced: ${_formatSyncTime(syncState.lastSyncedAt!)}"
                                                  : "Not synced",
                                      style: GoogleFonts.outfit(
                                        color: syncState.status == SyncStatus.error
                                            ? Colors.redAccent
                                            : accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (syncState.status == SyncStatus.syncing)
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                                )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: syncState.status == SyncStatus.syncing
                                      ? null
                                      : () async {
                                          await ref.read(syncProvider.notifier).uploadLocalToCloud();
                                          if (context.mounted) {
                                            final finalState = ref.read(syncProvider);
                                            if (finalState.status == SyncStatus.success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('✓ Progress successfully saved to cloud!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else if (finalState.status == SyncStatus.error) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('✗ Cloud upload failed: ${finalState.errorMessage ?? "Unknown error"}'),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                                  label: Text(
                                    "Sync",
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: syncState.status == SyncStatus.syncing
                                      ? null
                                      : () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: const Color(0xFF18181B),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                              title: const Text("Restore Data from Cloud?"),
                                              content: const Text(
                                                "This will overwrite your local device progress with the cloud backup. This cannot be undone.",
                                                style: TextStyle(color: Colors.white70),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                                ),
                                                FilledButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
                                                  child: const Text('Restore'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed != true) return;

                                          await ref.read(syncProvider.notifier).downloadCloudToLocal();
                                          if (context.mounted) {
                                            final finalState = ref.read(syncProvider);
                                            if (finalState.status == SyncStatus.success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('✓ Cloud data successfully restored!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else if (finalState.status == SyncStatus.error) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('✗ Cloud download failed: ${finalState.errorMessage ?? "Unknown error"}'),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: accentColor),
                                    foregroundColor: accentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.cloud_download_rounded, size: 16),
                                  label: Text(
                                    "Restore Data",
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await ref.read(authProvider.notifier).signOut();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: Text(
                              "SIGN OUT",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Center(
                            child: TextButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF161B22),
                                    title: Text(
                                      'Delete Account',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete your account? This will permanently delete all your synced data backups from the cloud. Your local database will remain intact.',
                                      style: GoogleFonts.outfit(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.outfit(color: Colors.grey),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: Text(
                                          'Delete Permanently',
                                      style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && context.mounted) {
                                  // Show loading spinner
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  try {
                                    // 1. Delete server account first
                                    await ref.read(authProvider.notifier).deleteServerAccountOnly();

                                    // Hide loading spinner
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }

                                    // 2. Show prompt "local data still exists"
                                    if (context.mounted) {
                                      await showDialog<void>(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(0xFF161B22),
                                          title: Text(
                                            'Local Data Remains',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            'local data still exists',
                                            style: GoogleFonts.outfit(color: Colors.white70),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text(
                                                'OK',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.cyanAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    // 3. Log out and navigate back to logged out version
                                    await ref.read(authProvider.notifier).completeLocalSignOut();

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Account and synced data deleted successfully.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    // Hide loading spinner if it is still showing
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                    if (e.code == 'requires-recent-login' && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please sign out and sign in again to verify your identity before deleting your account.'),
                                          backgroundColor: Colors.redAccent,
                                          duration: Duration(seconds: 5),
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.message}'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // Hide loading spinner if it is still showing
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: Colors.redAccent,
                              ),
                              child: const Text(
                                "Delete Account",
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.redAccent,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          _buildDownloadBanner(context, ref, accentColor),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: accentColor),
                ),
                error: (err, _) => Text(
                  'Auth Error: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            },
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Cloud Sync is supported on Web & Android. To transfer data to/from this desktop app, please use the Local Backup & Restore tools below.",
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    final profileSettingsHeader = buildHeader('PROFILE SETTINGS');

    final profileSettingsContent = Consumer(
      builder: (context, ref, _) {
        final profile = ref.watch(profileProvider);
        final displayName = ref.watch(displayNameProvider);
        final displayImage = ref.watch(displayProfileImageProvider);
        final authAsync = ref.watch(authProvider);
        final isGoogleUser = authAsync.value?.user != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: Colors.cyanAccent),
              title: Text('Change Display Name', style: titleStyle),
              subtitle: Text(
                'Current: ${profile.customDisplayName != null ? profile.customDisplayName! : (displayName ?? 'Not set')}',
                style: subtitleStyle,
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit_rounded, color: accentColor),
                onPressed: () async {
                  final controller = TextEditingController(text: profile.customDisplayName ?? displayName ?? '');
                  final result = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text("Set Custom Name"),
                      content: TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter name",
                          hintStyle: const TextStyle(color: Colors.white30),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: accentColor),
                          ),
                        ),
                        maxLength: 30,
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(profileProvider.notifier).setCustomDisplayName(null);
                            Navigator.pop(ctx);
                          },
                          child: Text('Reset', style: TextStyle(color: Colors.redAccent)),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, controller.text),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                  if (result != null) {
                    await ref.read(profileProvider.notifier).setCustomDisplayName(result);
                  }
                },
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 1),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: displayImage,
                  backgroundColor: Colors.white12,
                  child: displayImage == null ? const Icon(Icons.person, size: 18, color: Colors.white54) : null,
                ),
              ),
              title: Text('Set Profile Photo', style: titleStyle),
              subtitle: Text(
                profile.profilePhotoMode == 'custom'
                    ? 'Current: Custom Photo'
                    : profile.profilePhotoMode == 'google'
                        ? 'Current: Google Avatar'
                        : 'No Profile Photo',
                style: subtitleStyle,
              ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.photo_camera_rounded, color: accentColor),
                    color: const Color(0xFF1F1F23),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) async {
                      if (val == 'none') {
                        await ref.read(profileProvider.notifier).setProfilePhotoMode('none');
                      } else if (val == 'google') {
                        await ref.read(profileProvider.notifier).setProfilePhotoMode('google');
                      } else if (val == 'pick') {
                        final result = await FilePicker.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null) {
                          final file = result.files.single;
                          final bytes = await file.readAsBytes();
                          if (file.path != null) {
                            final path = file.path!;
                            String savedPath = path;
                            if (!kIsWeb) {
                              final dir = await getApplicationDocumentsDirectory();
                              final targetFile = File('${dir.path}/custom_profile_${DateTime.now().millisecondsSinceEpoch}.png');
                              await File(path).copy(targetFile.path);
                              savedPath = targetFile.path;
                            } else {
                              savedPath = 'data:image/png;base64,${base64Encode(bytes)}';
                            }

                            await ref.read(profileProvider.notifier).setCustomProfilePhotoPath(savedPath);
                            await ref.read(profileProvider.notifier).setProfilePhotoMode('custom');
                          } else {
                            final savedPath = 'data:image/png;base64,${base64Encode(bytes)}';
                            await ref.read(profileProvider.notifier).setCustomProfilePhotoPath(savedPath);
                            await ref.read(profileProvider.notifier).setProfilePhotoMode('custom');
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'pick',
                        child: Row(
                          children: [
                            Icon(Icons.photo_library_rounded, size: 18, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Choose Custom Photo', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      if (isGoogleUser)
                        const PopupMenuItem(
                          value: 'google',
                          child: Row(
                            children: [
                              Icon(Icons.account_circle_rounded, size: 18, color: Colors.white70),
                              SizedBox(width: 8),
                              Text('Use Google Photo', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'none',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Remove Photo', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );

    final resetDataContent = Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: Colors.redAccent,
        collapsedIconColor: Colors.redAccent.withValues(alpha: 0.5),
        leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
        title: Text(
          'Reset Data',
          style: titleStyle.copyWith(color: Colors.redAccent),
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Colors.redAccent),
            title: Text('Reset Tracking Data', style: titleStyle),
            subtitle: Text(
              'Set all progress counts to zero',
              style: subtitleStyle,
            ),
            onTap: () => _performReset(context, ref, everything: false),
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            title: Text('Reset Everything', style: titleStyle),
            subtitle: Text(
              'Clear sources, links, and progress',
              style: subtitleStyle,
            ),
            onTap: () => _performReset(context, ref, everything: true),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    final localBackupsContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file, color: Color(0xFF00E5FF)),
          title: Text('Export Data', style: titleStyle),
          subtitle: Text(
            'Save progress to JSON',
            style: subtitleStyle,
          ),
          onTap: () => _exportData(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.download, color: Color(0xFF69F0AE)),
          title: Text('Import Data', style: titleStyle),
          subtitle: Text(
            'Restore from JSON file',
            style: subtitleStyle,
          ),
          onTap: () => _importData(context, ref),
        ),
        resetDataContent,
      ],
    );

    final uiSwitchHeader = buildHeader('LAYOUT');

    final uiSwitchContent = buildSettingsGroup(
      ListTile(
        leading: Icon(
          GoRouterState.of(context).uri.path.startsWith('/desk')
              ? Icons.phone_android_rounded
              : Icons.desktop_windows_rounded,
          color: Colors.cyanAccent,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'App Layout Mode',
              style: titleStyle,
            ),
            if (!GoRouterState.of(context).uri.path.startsWith('/desk')) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  'BETA',
                  style: GoogleFonts.outfit(
                    color: Colors.cyanAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          GoRouterState.of(context).uri.path.startsWith('/desk')
              ? 'Return to the mobile-optimized layout'
              : 'Experience the desktop layout on your web browser',
          style: subtitleStyle,
        ),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          if (context.mounted) {
            if (GoRouterState.of(context).uri.path.startsWith('/desk')) {
              await prefs.setBool('user_wants_desktop_ui', false);
              if (context.mounted) context.go('/');
            } else {
              await prefs.setBool('user_wants_desktop_ui', true);
              if (context.mounted) context.go('/desk');
            }
          }
        },
      ),
    );

    final devOptionsContent = ListTile(
      leading: Icon(Icons.developer_mode_rounded, color: accentColor),
      title: Text('Inject Mock Session', style: titleStyle),
      subtitle: Text(
        'Generate fake study sessions for testing statistics and charts',
        style: subtitleStyle,
      ),
      onTap: () => _showDevInjectDialog(context, ref, accentColor),
    );

    final focusQuotesContent = Consumer(
      builder: (context, ref, _) {
        final quotesEnabled = ref.watch(focusQuotesEnabledProvider);
        return SwitchListTile(
          activeThumbColor: accentColor,
          secondary: Icon(Icons.format_quote_rounded, color: accentColor),
          title: Text('Motivational Quotes', style: titleStyle),
          subtitle: Text(
            'Display study motivation quotes during focus sessions (except Freestyle)',
            style: subtitleStyle,
          ),
          value: quotesEnabled,
          onChanged: (val) {
            ref.read(focusQuotesEnabledProvider.notifier).setEnabled(val);
          },
        );
      },
    );

    final focusAnimationStyleContent = Consumer(
      builder: (context, ref, _) {
        final animType = ref.watch(focusAnimationProvider);
        return ListTile(
          leading: Icon(Icons.animation_rounded, color: accentColor),
          title: Text('Focus Loop Animation', style: titleStyle),
          subtitle: Text(
            'Looping visual graphic shown during active focus countdowns',
            style: subtitleStyle,
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<FocusAnimationType>(
              value: animType,
              dropdownColor: const Color(0xFF18181B),
              alignment: Alignment.centerRight,
              items: FocusAnimationType.values.map((type) {
                String name = '';
                switch (type) {
                  case FocusAnimationType.doubleWave:
                    name = 'Double Wave';
                    break;
                  case FocusAnimationType.singleWave:
                    name = 'Single Wave';
                    break;
                  case FocusAnimationType.pulseDots:
                    name = 'Pulsing Dots';
                    break;
                  case FocusAnimationType.sonicEqualizer:
                    name = 'Sonic Equalizer';
                    break;
                  case FocusAnimationType.heartbeatECG:
                    name = 'Heartbeat ECG';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(focusAnimationProvider.notifier).setFocusAnimationType(val);
                }
              },
            ),
          ),
        );
      },
    );

    final resumeButtonStyleContent = Consumer(
      builder: (context, ref, _) {
        final fillStyle = ref.watch(resumeFillStyleProvider);
        return ListTile(
          leading: Icon(Icons.smart_button_rounded, color: accentColor),
          title: Text('Resume Button Style', style: titleStyle),
          subtitle: Text(
            'Configure preparation progress visual filling style on Home page',
            style: subtitleStyle,
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<ResumeFillStyle>(
              value: fillStyle,
              dropdownColor: const Color(0xFF18181B),
              alignment: Alignment.centerRight,
              items: ResumeFillStyle.values.map((type) {
                String name = '';
                switch (type) {
                  case ResumeFillStyle.rectangularFill:
                    name = 'Rectangular Fill';
                    break;
                  case ResumeFillStyle.neonGradient:
                    name = 'Neon Gradient';
                    break;
                  case ResumeFillStyle.bottomMicroIndicator:
                    name = 'Bottom Micro Line';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(resumeFillStyleProvider.notifier).setResumeFillStyle(val);
                }
              },
            ),
          ),
        );
      },
    );

    final accentColorContent = Consumer(
      builder: (context, ref, _) {
        final colorNotifier = ref.watch(overallProgressColorProvider.notifier);
        final currentColor = ref.watch(overallProgressColorProvider);
        final isAuto = colorNotifier.mode == 'auto';

        return ListTile(
          leading: Icon(
            isAuto ? Icons.brightness_auto_rounded : Icons.color_lens_rounded,
            color: currentColor,
          ),
          title: Text(
            'Theme Accent Color',
            style: titleStyle,
          ),
          subtitle: Text(
            isAuto ? 'Dynamic color auto-cycling' : 'Frozen custom color',
            style: subtitleStyle,
          ),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: currentColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          onTap: () => _showAccentColorDialog(context, ref),
        );
      },
    );

    final fontSizeExpansionContent = Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: accentColor,
        collapsedIconColor: Colors.white30,
        leading: Icon(Icons.format_size_rounded, color: accentColor),
        title: Text('Font Size & UI Scale', style: titleStyle),
        subtitle: Text(
          'Adjust category headers, subject cards, checklist text, and global UI scaling',
          style: subtitleStyle,
        ),
        children: [
          Consumer(
            builder: (context, ref, _) {
              final currentScale = ref.watch(overallUiScaleProvider);
              final currentCategorySize = ref.watch(categoryFontSizeProvider);
              final currentTopicSize = ref.watch(topicFontSizeProvider);
              final currentTaskSize = ref.watch(taskFontSizeProvider);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Global UI Scale', style: titleStyle),
                      subtitle: Text('Resize all margins, card panels, and text blocks', style: subtitleStyle),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<OverallUiScale>(
                          value: currentScale,
                          dropdownColor: const Color(0xFF18181B),
                          alignment: Alignment.centerRight,
                          items: OverallUiScale.values.map((scale) {
                            String name = '';
                            switch (scale) {
                              case OverallUiScale.xs: name = 'XS (0.8x)'; break;
                              case OverallUiScale.s: name = 'S (0.9x)'; break;
                              case OverallUiScale.normal: name = 'Normal (1.0x)'; break;
                              case OverallUiScale.l: name = 'L (1.1x)'; break;
                              case OverallUiScale.xl: name = 'XL (1.2x)'; break;
                            }
                            return DropdownMenuItem(
                              value: scale,
                              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(overallUiScaleProvider.notifier).setScale(val);
                            }
                          },
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Category Headers', style: titleStyle),
                      subtitle: Text('Adjust font size of syllabus category headers', style: subtitleStyle),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<CategoryFontSize>(
                          value: currentCategorySize,
                          dropdownColor: const Color(0xFF18181B),
                          alignment: Alignment.centerRight,
                          items: CategoryFontSize.values.map((size) {
                            String name = '';
                            switch (size) {
                              case CategoryFontSize.level1: name = 'XS'; break;
                              case CategoryFontSize.level2: name = 'S'; break;
                              case CategoryFontSize.level3: name = 'Normal'; break;
                              case CategoryFontSize.level4: name = 'L'; break;
                              case CategoryFontSize.level5: name = 'XL'; break;
                            }
                            return DropdownMenuItem(
                              value: size,
                              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(categoryFontSizeProvider.notifier).setFontSize(val);
                            }
                          },
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Subject Cards', style: titleStyle),
                      subtitle: Text('Adjust font size of subject card titles', style: subtitleStyle),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<TopicFontSize>(
                          value: currentTopicSize,
                          dropdownColor: const Color(0xFF18181B),
                          alignment: Alignment.centerRight,
                          items: TopicFontSize.values.map((size) {
                            String name = '';
                            switch (size) {
                              case TopicFontSize.level1: name = 'XS'; break;
                              case TopicFontSize.level2: name = 'S'; break;
                              case TopicFontSize.level3: name = 'Normal'; break;
                              case TopicFontSize.level4: name = 'L'; break;
                              case TopicFontSize.level5: name = 'XL'; break;
                            }
                            return DropdownMenuItem(
                              value: size,
                              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(topicFontSizeProvider.notifier).setFontSize(val);
                            }
                          },
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Checklist Tasks', style: titleStyle),
                      subtitle: Text('Adjust font size of checklist task checkboxes', style: subtitleStyle),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<TaskFontSize>(
                          value: currentTaskSize,
                          dropdownColor: const Color(0xFF18181B),
                          alignment: Alignment.centerRight,
                          items: TaskFontSize.values.map((size) {
                            String name = '';
                            switch (size) {
                              case TaskFontSize.level1: name = 'XS'; break;
                              case TaskFontSize.level2: name = 'S'; break;
                              case TaskFontSize.level3: name = 'Normal'; break;
                              case TaskFontSize.level4: name = 'L'; break;
                              case TaskFontSize.level5: name = 'XL'; break;
                            }
                            return DropdownMenuItem(
                              value: size,
                              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(taskFontSizeProvider.notifier).setFontSize(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    final appSettingsHeader = buildHeader('APP SETTINGS');

    final appSettingsContent = buildSettingsGroup(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            activeThumbColor: accentColor,
            secondary: Icon(Icons.sort_rounded, color: accentColor),
            title: Text('Auto-Sort Categories', style: titleStyle),
            subtitle: Text(
              'Move recently studied categories to the top automatically',
              style: subtitleStyle,
            ),
            value: autoSort,
            onChanged: (val) {
              ref.read(categoryAutoSortProvider.notifier).setAutoSort(val);
            },
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
            title: Text('Syllabus Checklist Preset', style: titleStyle),
            subtitle: Text(
              'Reset and apply the default standard GATE checklist preset',
              style: subtitleStyle,
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Text('Apply Syllabus Preset'),
                  content: const Text(
                    'This will reset and overwrite all current syllabus categories and checklist progress. Continue?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(syllabusControllerProvider.notifier).applyPreset();
              }
            },
          ),
          const Divider(color: Colors.white10, height: 1),
          accentColorContent,
          const Divider(color: Colors.white10, height: 1),
          Consumer(
            builder: (context, ref, _) {
              final currentFont = ref.watch(progressFontProvider);
              return ListTile(
                leading: Icon(Icons.font_download_rounded, color: accentColor),
                title: Text('Checklist Typography', style: titleStyle),
                subtitle: Text(
                  'Choose font style for progress headers and text statistics',
                  style: subtitleStyle,
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ProgressFont>(
                    value: currentFont,
                    dropdownColor: const Color(0xFF18181B),
                    alignment: Alignment.centerRight,
                    icon: Icon(Icons.arrow_drop_down, color: accentColor),
                    style: TextStyle(color: accentColor),
                    items: ProgressFont.values.map((font) {
                      String label;
                      switch (font) {
                        case ProgressFont.orbitron:
                          label = 'Orbitron';
                          break;
                        case ProgressFont.jersey15:
                          label = 'Jersey 15';
                          break;
                        case ProgressFont.jersey10:
                          label = 'Jersey 10';
                          break;
                        case ProgressFont.tektur:
                          label = 'Tektur';
                          break;
                        case ProgressFont.odibeeSans:
                          label = 'Odibee';
                          break;
                        case ProgressFont.pressStart2P:
                          label = 'Press Start';
                          break;
                        case ProgressFont.boldonse:
                          label = 'Boldonse';
                          break;
                      }
                      return DropdownMenuItem(
                        value: font,
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(progressFontProvider.notifier).setProgressFont(val);
                      }
                    },
                  ),
                ),
              );
            },
          ),
          const Divider(color: Colors.white10, height: 1),
          fontSizeExpansionContent,
        ],
      ),
    );

    final advancedOptionsContent = buildSettingsGroup(
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: Colors.white30,
          leading: Icon(Icons.settings_suggest_rounded, color: accentColor),
          title: Text(
            'Advanced Options',
            style: titleStyle,
          ),
          subtitle: Text(
            'Check-in target goals, slider glow effects, and avatar sizing',
            style: subtitleStyle,
          ),
          children: [

            Consumer(
              builder: (context, ref, _) {
                final mins = ref.watch(checkInGoalMinutesProvider);
                return ListTile(
                  leading: Icon(Icons.check_circle_outline_rounded, color: accentColor),
                  title: Text('Daily Focus Goal', style: titleStyle),
                  subtitle: Text(
                    'Daily check-in study threshold: $mins minutes',
                    style: subtitleStyle,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white30),
                  onTap: () => _showCheckInGoalDialog(context, ref, mins, accentColor),
                );
              },
            ),
            const Divider(color: Colors.white10, height: 1),
            Consumer(
              builder: (context, ref, _) {
                final hideBanner = ref.watch(hideDownloadBannerProvider);
                return SwitchListTile(
                  activeThumbColor: accentColor,
                  secondary: Icon(Icons.devices_other_rounded, color: accentColor),
                  title: Text('Download Promotion Banner', style: titleStyle),
                  subtitle: Text(
                    'Display native app download links for other platforms',
                    style: subtitleStyle,
                  ),
                  value: !hideBanner,
                  onChanged: (val) async {
                    await ref.read(hideDownloadBannerProvider.notifier).setHidden(!val);
                    ref.read(syncProvider.notifier).triggerAutoSync();
                  },
                );
              },
            ),
            const Divider(color: Colors.white10, height: 1),
            Consumer(
              builder: (context, ref, _) {
                final strength = ref.watch(glowStrengthProvider);
                return ListTile(
                  leading: Icon(Icons.blur_circular_rounded, color: accentColor),
                  title: Text('Timer Glow Intensity', style: titleStyle),
                  subtitle: Text(
                    'Glow strength: ${(strength * 100).toStringAsFixed(0)}%',
                    style: subtitleStyle,
                  ),
                  trailing: SizedBox(
                    width: 140,
                    child: Slider(
                      min: 0.0,
                      max: 4.0,
                      divisions: 16,
                      activeColor: accentColor,
                      inactiveColor: Colors.white10,
                      value: strength.clamp(0.0, 4.0),
                      onChanged: (val) async {
                         await ref.read(glowStrengthProvider.notifier).setStrength(val);
                      },
                    ),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white10, height: 1),
            Consumer(
              builder: (context, ref, _) {
                final profile = ref.watch(profileProvider);
                return ListTile(
                  leading: Icon(Icons.photo_size_select_large_rounded, color: accentColor),
                  title: Text('Avatar Circle Size', style: titleStyle),
                  subtitle: Text(
                    'Radius dimensions: ${profile.profilePhotoSize.toStringAsFixed(0)} px',
                    style: subtitleStyle,
                  ),
                  trailing: SizedBox(
                    width: 140,
                    child: Slider(
                      min: 15.0,
                      max: 60.0,
                      divisions: 9,
                      activeColor: accentColor,
                      inactiveColor: Colors.white10,
                      value: profile.profilePhotoSize.clamp(15.0, 60.0),
                      onChanged: (val) async {
                        await ref.read(profileProvider.notifier).setProfilePhotoSize(val);
                      },
                    ),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white10, height: 1),
            Consumer(
              builder: (context, ref, _) {
                final disableWidget = ref.watch(disableHomeScreenWidgetProvider);
                return SwitchListTile(
                  activeThumbColor: accentColor,
                  secondary: Icon(Icons.disabled_by_default_rounded, color: accentColor),
                  title: Text('Disable Countdown Widget', style: titleStyle),
                  subtitle: Text(
                    'Remove countdown widget panel from home screen layout',
                    style: subtitleStyle,
                  ),
                  value: disableWidget,
                  onChanged: (val) async {
                    await ref.read(disableHomeScreenWidgetProvider.notifier).setEnabled(val);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    final betaOptionsContent = buildSettingsGroup(
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: Colors.white30,
          leading: Icon(Icons.science_rounded, color: accentColor),
          title: Text(
            'Beta Options',
            style: titleStyle,
          ),
          subtitle: Text(
            'Handwritten quotes, timer button styles, and charts velocity forecasts',
            style: subtitleStyle,
          ),
          children: [
            Consumer(
              builder: (context, ref, _) {
                final showProjComp = ref.watch(showProjectedCompletionProvider);
                return SwitchListTile(
                  activeThumbColor: accentColor,
                  secondary: Icon(Icons.trending_up_rounded, color: accentColor),
                  title: Text('Projected Completion Card', style: titleStyle),
                  subtitle: Text(
                    'Display syllabus completion target forecasting on Stats Hub',
                    style: subtitleStyle,
                  ),
                  value: showProjComp,
                  onChanged: (val) async {
                    await ref.read(showProjectedCompletionProvider.notifier).setEnabled(val);
                  },
                );
              },
            ),
            const Divider(color: Colors.white10, height: 1),
            Consumer(
              builder: (context, ref, _) {
                final disableGlow = ref.watch(disableGraphGlowProvider);
                return SwitchListTile(
                  activeThumbColor: accentColor,
                  secondary: Icon(Icons.blur_off_rounded, color: accentColor),
                  title: Text('Chart Glow Effect', style: titleStyle),
                  subtitle: Text(
                    'Display neon glow gradients behind statistics graphs',
                    style: subtitleStyle,
                  ),
                  value: !disableGlow,
                  onChanged: (val) async {
                    await ref.read(disableGraphGlowProvider.notifier).setEnabled(!val);
                  },
                );
              },
            ),
            const Divider(color: Colors.white10, height: 1),
            resumeButtonStyleContent,
            const Divider(color: Colors.white10, height: 1),
            focusAnimationStyleContent,
            const Divider(color: Colors.white10, height: 1),
            focusQuotesContent,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    final aboutAppContent = ListTile(
      leading: Icon(Icons.info_outline_rounded, color: accentColor),
      title: Text('About GATEletics', style: titleStyle),
      subtitle: Text(
        'View app details, credits, developer info, and source code',
        style: subtitleStyle,
      ),
      onTap: () {
        showAboutTrackerDialog(context, ref);
      },
    );

    final systemOptionsHeader = buildHeader('SYSTEM INFO');

    final systemOptionsContent = buildSettingsGroup(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          aboutAppContent,
          const Divider(color: Colors.white10, height: 1),
          devOptionsContent,
        ],
      ),
    );

    final versionText = Center(
      child: Text(
        'GATEletics v${packageInfo.version}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
        ),
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: ListTileThemeData(
          dense: true,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: context.s(13),
            fontWeight: FontWeight.bold,
          ),
          subtitleTextStyle: GoogleFonts.outfit(
            color: Colors.white30,
            fontSize: context.s(11),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'SETTINGS',
            style: GoogleFonts.orbitron(
              fontSize: context.s(20),
              fontWeight: FontWeight.w900,
              letterSpacing: context.s(1.5),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: isDesktop
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                cloudSyncHeader,
                                cloudSyncContent,
                                const SizedBox(height: 12),
                                profileSettingsHeader,
                                profileSettingsContent,
                                if ((kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) &&
                                    defaultTargetPlatform != TargetPlatform.android &&
                                    defaultTargetPlatform != TargetPlatform.iOS) ...[
                                  const SizedBox(height: 12),
                                  uiSwitchHeader,
                                  uiSwitchContent,
                                ],
                                const SizedBox(height: 12),
                                buildHeader('LOCAL BACKUPS & DATA'),
                                localBackupsContent,
                                const SizedBox(height: 12),
                                systemOptionsHeader,
                                systemOptionsContent,
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                appSettingsHeader,
                                appSettingsContent,
                                const SizedBox(height: 12),
                                buildHeader('ADVANCED'),
                                advancedOptionsContent,
                                const SizedBox(height: 12),
                                buildHeader('EXPERIMENTS & BETA'),
                                betaOptionsContent,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      versionText,
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
                  children: [
                    cloudSyncHeader,
                    cloudSyncContent,
                    profileSettingsHeader,
                    profileSettingsContent,
                    if ((kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) &&
                        defaultTargetPlatform != TargetPlatform.android &&
                        defaultTargetPlatform != TargetPlatform.iOS) ...[
                      uiSwitchHeader,
                      uiSwitchContent,
                    ],
                    appSettingsHeader,
                    appSettingsContent,
                    buildHeader('ADVANCED'),
                    advancedOptionsContent,
                    buildHeader('EXPERIMENTS & BETA'),
                    betaOptionsContent,
                    buildHeader('LOCAL BACKUPS & DATA'),
                    localBackupsContent,
                    systemOptionsHeader,
                    systemOptionsContent,
                    SizedBox(height: context.s(12)),
                    versionText,
                    SizedBox(height: context.s(16)),
                  ],
                ),
        ),
      ),
    );
  }




  void _showAccentColorDialog(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final colorNotifier = ref.read(overallProgressColorProvider.notifier);
    final currentColor = ref.read(overallProgressColorProvider);

    int r = (currentColor.r * 255).round().clamp(0, 255);
    int g = (currentColor.g * 255).round().clamp(0, 255);
    int b = (currentColor.b * 255).round().clamp(0, 255);

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (size.width * 0.85).clamp(280.0, 360.0),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withAlpha(12), width: 1.5),
              ),
              padding: const EdgeInsets.all(24.0),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  final isAuto = colorNotifier.mode == 'auto';
                  final previewColor = Color.fromARGB(255, r, g, b);

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Accent Color',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () {
                            colorNotifier.setAutoMode();
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isAuto
                                  ? currentColor.withAlpha(38)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAuto ? currentColor : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.brightness_auto_rounded,
                                  color: isAuto ? currentColor : Colors.white70,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Auto-change color',
                                    style: GoogleFonts.outfit(
                                      color: isAuto ? Colors.white : Colors.white70,
                                      fontSize: 15,
                                      fontWeight: isAuto ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isAuto)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: currentColor,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Preset Colors:',
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: AppColors.neonCycle.map((color) {
                              final isSelected = !isAuto &&
                                  colorNotifier.frozenColor?.toARGB32() == color.toARGB32();

                              return InkWell(
                                onTap: () {
                                  colorNotifier.setFrozenColor(color);
                                  Navigator.pop(context);
                                },
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.white24,
                                      width: isSelected ? 2.5 : 1.2,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: color.withAlpha(150),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.black,
                                          size: 18,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Custom Color Picker:',
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: previewColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: previewColor.withAlpha(100),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'RGB: ($r, $g, $b)\nHex: #${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(width: 24, child: Text('R', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                            Expanded(
                              child: Slider(
                                value: r.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.redAccent,
                                inactiveColor: Colors.white10,
                                onChanged: (val) {
                                  setDialogState(() {
                                    r = val.round();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 24, child: Text('G', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                            Expanded(
                              child: Slider(
                                value: g.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.greenAccent,
                                inactiveColor: Colors.white10,
                                onChanged: (val) {
                                  setDialogState(() {
                                    g = val.round();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 24, child: Text('B', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                            Expanded(
                              child: Slider(
                                value: b.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.blueAccent,
                                inactiveColor: Colors.white10,
                                onChanged: (val) {
                                  setDialogState(() {
                                    b = val.round();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            colorNotifier.setFrozenColor(Color.fromARGB(255, r, g, b));
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: previewColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Apply Custom Color', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckInGoalDialog(BuildContext context, WidgetRef ref, int currentMins, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Daily Check-in Goal',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [5, 10, 15, 20, 30, 45].map((mins) {
              final isSelected = mins == currentMins;
              return ListTile(
                title: Text(
                  '$mins minutes${mins == 15 ? ' (default)' : ''}',
                  style: GoogleFonts.outfit(
                    color: isSelected ? accentColor : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: accentColor) : null,
                onTap: () {
                  ref.read(checkInGoalMinutesProvider.notifier).setMinutes(mins);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showDevInjectDialog(BuildContext context, WidgetRef ref, Color accentColor) {
    DateTime selectedDate = DateTime.now();
    final durationController = TextEditingController(text: "60");
    final goalController = TextEditingController(text: "120");

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF18181B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Dev: Inject Study Session",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Date: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                          style: GoogleFonts.outfit(color: Colors.white70),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: accentColor),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) {
                              setState(() {
                                selectedDate = d;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Duration (Minutes)",
                        labelStyle: GoogleFonts.outfit(color: Colors.white60),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      ),
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: goalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Daily Goal (Minutes)",
                        labelStyle: GoogleFonts.outfit(color: Colors.white60),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      ),
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text("Cancel", style: TextStyle(color: accentColor)),
                ),
                TextButton(
                  onPressed: () async {
                    final durationMin = int.tryParse(durationController.text) ?? 60;
                    final goalMin = int.tryParse(goalController.text) ?? 120;

                    final db = ref.read(appDatabaseProvider);
                    final rollover = ref.read(studyDayRolloverProvider);

                    final startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0);

                    // Insert Focus Session
                    await db.into(db.focusSessions).insert(FocusSessionsCompanion.insert(
                      method: "Freestyle",
                      startTime: startTime,
                      durationSeconds: durationMin * 60,
                      accomplishments: const Value("Developer Mode injected study session"),
                    ));

                    // Read focus sessions on this study day to update DailyHistory
                    final studyDayStart = getStudyDayStart(startTime, rollover: rollover);
                    final studyDayEnd = studyDayStart.add(const Duration(hours: 24));
                    final sessions = await (db.select(db.focusSessions)
                          ..where((t) => t.startTime.isBiggerOrEqualValue(studyDayStart) & t.startTime.isSmallerThanValue(studyDayEnd)))
                        .get();
                    final totalSeconds = sessions.fold(0, (sum, s) => sum + s.durationSeconds);

                    final studyDay = studyDayFor(startTime, rollover);
                    final dateStr = "${studyDay.year}-${studyDay.month.toString().padLeft(2, '0')}-${studyDay.day.toString().padLeft(2, '0')}";

                    await db.upsertDailyHistory(
                      dateStr: dateStr,
                      totalFocusSeconds: totalSeconds,
                      targetGoalSeconds: goalMin * 60,
                      isGoalCompleted: totalSeconds >= (goalMin * 60),
                      syllabusProgressPct: 50.0,
                    );

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✓ Study session injected successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text("Inject", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
