import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../../providers/completion_type_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/package_info_provider.dart';
import '../../providers/progress_font_provider.dart';
import '../../providers/category_autosort_provider.dart';
import '../../providers/category_font_size_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../database/backup_service.dart';
import '../../widgets/settings/about_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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

      if (payload is List || (payload is Map && !payload.containsKey('categories'))) {
        // Fallback: old style progress restoration by subject name
        final list = (payload is List ? payload : payload['subjects'] as List<dynamic>);
        final existingSubjects = await db.select(db.subjects).get();
        final subjectMap = {for (var s in existingSubjects) s.name.trim(): s};

        int importedCount = 0;
        await db.transaction(() async {
          for (final item in list) {
            final name = item['name'] as String?;
            if (name == null) continue;

            final s = subjectMap[name.trim()];
            if (s != null) {
              await db.updateSubjectDetails(
                id: s.id,
                name: s.name,
                completed: (item['completedVideos'] as int?) ?? s.completedVideos,
                total: (item['totalVideos'] as int?) ?? s.totalVideos,
                sourceName: (item['sourceName'] as String?) ?? s.sourceName,
                playlistLink: (item['playlistLink'] as String?) ?? s.playlistLink,
                isActive: (item['isActive'] as bool?) ?? s.isActive,
                color: item['color'] as int?,
                categoryId: s.categoryId,
              );
              importedCount++;
            }
          }
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✓ Restored progress for $importedCount matching subjects!')),
          );
        }
      } else {
        // Full restore using BackupService
        await BackupService.restoreDatabase(db, payload);
        ref.read(syncProvider.notifier).clearDatabaseCaches();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Backup data successfully restored!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
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
        await ref.read(subjectControllerProvider.notifier).resetEverything();
        await ref.read(syllabusControllerProvider.notifier).resetEverything();

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('has_agreed_legal');
        await prefs.remove('has_completed_setup');
        await prefs.remove('completion_type');
        await prefs.remove('has_seen_desktop_warning');
        await prefs.remove('last_seen_desktop_warning_version');
        await prefs.remove('desktop_warning_seen_time_ms');

        ref.invalidate(agreementProvider);
        ref.invalidate(setupCompletedProvider);
      } else {
        final currentType = ref.read(completionTypeProvider);
        if (currentType == CompletionType.syllabus) {
          await ref.read(syllabusControllerProvider.notifier).resetTrackingData();
        } else {
          await ref
              .read(subjectControllerProvider.notifier)
              .resetTrackingData();
        }
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
              const SizedBox(height: 20),
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

    final cloudSyncHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'CLOUD SYNC',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

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

    final localBackupsHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'LOCAL BACKUPS',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final localBackupsContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file, color: Color(0xFF00E5FF)),
          title: const Text('Export Data'),
          subtitle: const Text(
            'Save progress to JSON',
            style: TextStyle(color: Colors.grey),
          ),
          onTap: () => _exportData(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.download, color: Color(0xFF69F0AE)),
          title: const Text('Import Data'),
          subtitle: const Text(
            'Restore from JSON file',
            style: TextStyle(color: Colors.grey),
          ),
          onTap: () => _importData(context, ref),
        ),
      ],
    );

    final completionTypeHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'COMPLETION TYPE',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final completionTypeContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Consumer(
        builder: (context, ref, _) {
          final currentType = ref.watch(completionTypeProvider);

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(completionTypeProvider.notifier)
                          .setCompletionType(CompletionType.resource),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: currentType == CompletionType.resource
                              ? accentColor.withValues(alpha: 0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentType == CompletionType.resource
                                ? accentColor
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Resource Based',
                            style: TextStyle(
                              color: currentType == CompletionType.resource
                                  ? accentColor
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(completionTypeProvider.notifier)
                          .setCompletionType(CompletionType.syllabus),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: currentType == CompletionType.syllabus
                              ? accentColor.withValues(alpha: 0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentType == CompletionType.syllabus
                                ? accentColor
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Syllabus Based',
                            style: TextStyle(
                              color: currentType == CompletionType.syllabus
                                  ? accentColor
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                title: Text(currentType == CompletionType.resource
                    ? 'Apply Resource Preset'
                    : 'Apply Syllabus Preset'),
                subtitle: Text(
                  currentType == CompletionType.resource
                      ? 'Apply default GoClasses/YouTube sources'
                      : 'Restore the default GATE CSE checklist',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      title: Text(currentType == CompletionType.resource
                          ? 'Apply Resource Preset'
                          : 'Apply Syllabus Preset'),
                      content: Text(
                        currentType == CompletionType.resource
                            ? 'This will overwrite current sources and counts for some subjects. Continue?'
                            : 'This will reset and overwrite all current syllabus categories and checklist progress. Continue?',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey)),
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
                    if (currentType == CompletionType.resource) {
                      await ref
                          .read(subjectControllerProvider.notifier)
                          .applyPreset();
                    } else {
                      await ref
                          .read(syllabusControllerProvider.notifier)
                          .applyPreset();
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );

    final categoryOrderingHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'CATEGORY ORDERING',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final categoryOrderingContent = SwitchListTile(
      activeColor: accentColor,
      title: const Text('Auto-Sort Categories'),
      subtitle: const Text(
        'Move last interacted category to the top automatically',
        style: TextStyle(color: Colors.grey, fontSize: 11),
      ),
      value: autoSort,
      onChanged: (val) {
        ref.read(categoryAutoSortProvider.notifier).setAutoSort(val);
      },
    );

    final fontHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'ACCENT & CATEGORY FONT',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final fontContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Consumer(
        builder: (context, ref, _) {
          final currentFont = ref.watch(progressFontProvider);

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: ProgressFont.values.map((font) {
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
                  label = 'Odibee Sans';
                  break;
                case ProgressFont.pressStart2P:
                  label = 'Press Start 2P';
                  break;
                case ProgressFont.boldonse:
                  label = 'Boldonse';
                  break;
              }

              final isSelected = currentFont == font;

              return InkWell(
                onTap: () => ref
                    .read(progressFontProvider.notifier)
                    .setProgressFont(font),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.2)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? accentColor
                          : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );

    final fontSizeHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'CATEGORY FONT SIZE',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final fontSizeContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Consumer(
        builder: (context, ref, _) {
          final currentSize = ref.watch(categoryFontSizeProvider);

          String getFontLevelLabel(CategoryFontSize size) {
            switch (size) {
              case CategoryFontSize.level1:
                return 'XS';
              case CategoryFontSize.level2:
                return 'S';
              case CategoryFontSize.level3:
                return 'Normal';
              case CategoryFontSize.level4:
                return 'L';
              case CategoryFontSize.level5:
                return 'XL';
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getFontLevelLabel(currentSize),
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (currentSize == CategoryFontSize.level3)
                    Text(
                      'DEFAULT',
                      style: GoogleFonts.outfit(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accentColor,
                  inactiveTrackColor: Colors.white.withAlpha(20),
                  thumbColor: accentColor,
                  overlayColor: accentColor.withAlpha(40),
                  valueIndicatorColor: accentColor,
                  tickMarkShape: const RoundSliderTickMarkShape(),
                  activeTickMarkColor: Colors.black,
                  inactiveTickMarkColor: Colors.white30,
                ),
                child: Slider(
                  value: CategoryFontSize.values.indexOf(currentSize).toDouble(),
                  min: 0,
                  max: 4,
                  divisions: 4,
                  label: getFontLevelLabel(currentSize),
                  onChanged: (val) {
                    final newSize = CategoryFontSize.values[val.toInt()];
                    ref.read(categoryFontSizeProvider.notifier).setFontSize(newSize);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('XS', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                    Text('S', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                    Text('Normal (Def)', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('L', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                    Text('XL', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final uiSwitchHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'LAYOUT',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final uiSwitchContent = ListTile(
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
            GoRouterState.of(context).uri.path.startsWith('/desk')
                ? 'Switch to Mobile UI'
                : 'Switch to Desktop UI',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
      onTap: () {
        if (GoRouterState.of(context).uri.path.startsWith('/desk')) {
          context.go('/');
        } else {
          context.go('/desk');
        }
      },
    );

    final resetDataHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'RESET DATA',
        style: TextStyle(
          color: Colors.redAccent.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final resetDataContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.history_rounded, color: Colors.redAccent),
          title: const Text('Reset Tracking Data'),
          subtitle: const Text(
            'Set all progress counts to zero',
            style: TextStyle(color: Colors.grey),
          ),
          onTap: () => _performReset(context, ref, everything: false),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
          title: const Text('Reset Everything'),
          subtitle: const Text(
            'Clear sources, links, and progress',
            style: TextStyle(color: Colors.grey),
          ),
          onTap: () => _performReset(context, ref, everything: true),
        ),
      ],
    );

    final advancedOptionsContent = Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: accentColor,
        collapsedIconColor: Colors.white30,
        leading: Icon(Icons.settings_suggest_rounded, color: accentColor),
        title: const Text(
          'Advanced Options',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        children: [
          Consumer(
            builder: (context, ref, _) {
              final freq = ref.watch(syncFrequencyProvider);
              String label;
              switch (freq) {
                case SyncFrequency.instant:
                  label = 'Instant';
                  break;
                case SyncFrequency.fiveMinutes:
                  label = 'Every 5 Minutes';
                  break;
                case SyncFrequency.appClose:
                  label = 'On App Close';
                  break;
                case SyncFrequency.manual:
                  label = 'Manual';
                  break;
              }
              return ListTile(
                leading: Icon(Icons.sync_lock_rounded, color: accentColor),
                title: const Text('Background Sync Frequency'),
                subtitle: Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white30),
                onTap: () => _showSyncFrequencyDialog(context, ref, freq, accentColor),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    final aboutAppContent = ListTile(
      leading: Icon(Icons.info_outline_rounded, color: accentColor),
      title: const Text('About App'),
      subtitle: const Text(
        'Show Info about App, Developer and Repository',
        style: TextStyle(color: Colors.grey),
      ),
      onTap: () {
        showAboutTrackerDialog(context, ref);
      },
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
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
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              localBackupsHeader,
                              localBackupsContent,
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              completionTypeHeader,
                              completionTypeContent,
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              resetDataHeader,
                              resetDataContent,
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              aboutAppContent,
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              categoryOrderingHeader,
                              categoryOrderingContent,
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              fontHeader,
                              fontContent,
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              fontSizeHeader,
                              fontSizeContent,
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),
                              advancedOptionsContent,
                              if ((kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) &&
                                  defaultTargetPlatform != TargetPlatform.android &&
                                  defaultTargetPlatform != TargetPlatform.iOS) ...[
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white12),
                                const SizedBox(height: 8),
                                uiSwitchHeader,
                                uiSwitchContent,
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    versionText,
                    const SizedBox(height: 24),
                  ],
                ),
              )
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  cloudSyncHeader,
                  cloudSyncContent,
                  const Divider(color: Colors.white12),
                  localBackupsHeader,
                  localBackupsContent,
                  const Divider(color: Colors.white12),
                  completionTypeHeader,
                  completionTypeContent,
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  categoryOrderingHeader,
                  categoryOrderingContent,
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  fontHeader,
                  fontContent,
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  fontSizeHeader,
                  fontSizeContent,
                  if ((kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) &&
                      defaultTargetPlatform != TargetPlatform.android &&
                      defaultTargetPlatform != TargetPlatform.iOS) ...[
                    const Divider(color: Colors.white12),
                    uiSwitchHeader,
                    uiSwitchContent,
                  ],
                  const Divider(color: Colors.white12),
                  resetDataHeader,
                  resetDataContent,
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  advancedOptionsContent,
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  aboutAppContent,
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  versionText,
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  void _showSyncFrequencyDialog(
      BuildContext context, WidgetRef ref, SyncFrequency currentFreq, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Sync Frequency',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: SyncFrequency.values.map((freq) {
              String title;
              String subtitle;
              switch (freq) {
                case SyncFrequency.instant:
                  title = 'Instant';
                  subtitle = 'Upload changes to the cloud immediately.';
                  break;
                case SyncFrequency.fiveMinutes:
                  title = 'Every 5 Minutes';
                  subtitle = 'Batch and upload changes every 5 minutes.';
                  break;
                case SyncFrequency.appClose:
                  title = 'On App Close';
                  subtitle = 'Upload changes when app goes to background.';
                  break;
                case SyncFrequency.manual:
                  title = 'Manual';
                  subtitle = 'Only upload when you manually press Sync.';
                  break;
              }

              return Theme(
                data: Theme.of(ctx).copyWith(
                  unselectedWidgetColor: Colors.white30,
                ),
                child: RadioListTile<SyncFrequency>(
                  activeColor: accentColor,
                  title: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  value: freq,
                  groupValue: currentFreq,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(syncFrequencyProvider.notifier).setFrequency(val);
                    }
                    Navigator.of(ctx).pop();
                  },
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
