import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/subject_provider.dart';
import '../providers/updater_provider.dart';
import '../providers/telemetry_service.dart';

void showSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(180),
    builder: (context) => const SettingsSheet(),
  );
}

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
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
        dialogTitle: 'Save backup to device',
        fileName: 'gate_tracker_backup.json',
        bytes: bytes,
      );

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
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;

      final singleFile = result.files.single;
      final isJson = singleFile.name.toLowerCase().endsWith('.json');
      if (!isJson) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid .json backup file.')),
          );
        }
        return;
      }

      final bytes = await singleFile.readAsBytes();
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
        // Premium new style: complete restore
        final categoriesData = payload['categories'] as List<dynamic>;
        final subjectsData = payload['subjects'] as List<dynamic>;

        await db.transaction(() async {
          // 1. Wipe database first to guarantee fresh clean restore
          await db.delete(db.subjects).go();
          await db.delete(db.categories).go();

          // 2. Insert all categories and keep map of name -> new ID
          final categoryNameToNewId = <String, int>{};
          for (final c in categoriesData) {
            final name = c['name'] as String;
            final color = c['color'] as int;
            final position = c['position'] as int;
            
            final id = await db.addCategory(name, color, position: position);
            categoryNameToNewId[name] = id;
          }

          // 3. Insert all subjects
          for (final s in subjectsData) {
            final categoryName = s['categoryName'] as String;
            final catId = categoryNameToNewId[categoryName];
            if (catId == null) continue; // Skip if category is missing

            await db.addSubject(
              name: s['name'] as String,
              categoryId: catId,
              totalVideos: s['totalVideos'] as int,
              sourceName: s['sourceName'] as String,
              playlistLink: s['playlistLink'] as String,
              isActive: s['isActive'] as bool,
              color: s['color'] as int?,
              position: s['position'] as int? ?? 0,
            );
          }
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Full syllabus and progress successfully restored!')),
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
      } else {
        await ref
            .read(subjectControllerProvider.notifier)
            .resetTrackingData();
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

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final accentColor = ref.read(overallProgressColorProvider);

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
              maxWidth: (size.width * 0.85).clamp(280.0, 420.0),
              maxHeight: size.height * 0.8,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withAlpha(12), width: 1.5),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Icon squircle (professional, no glow)
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: accentColor.withAlpha(50), width: 1.5),
                          ),
                          child: Icon(
                            Icons.track_changes_rounded,
                            color: accentColor,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // App Title (no shadows)
                      const Center(
                        child: Text(
                          "GATE TRACKER",
                          style: TextStyle(
                            fontFamily: 'BatmanForever',
                            fontSize: 18,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Version Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                          child: Text(
                            "v1.0.0 (Stable)",
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Clean subtle divider
                      const Divider(color: Colors.white10, height: 32),

                      // App Description
                      Text(
                        "A syllabus tracker for tracking syllabus completion of GATE Exam.",
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.55,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Creator Profile Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(8)),
                        ),
                        child: Row(
                          children: [
                            // Initial avatar (clean, no glow)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(8),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white12, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "VN",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DEVELOPED BY",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white30,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Vishnu Nandan",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    "Lead Architect & Developer",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Love / Country Badge (flat)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("🇮🇳", style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Text(
                                "Made in India with Love",
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text("❤️", style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final Uri url = Uri.parse('https://github.com/vishnunandan555/gate-tracker');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: Colors.white24, width: 1),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.code_rounded, size: 18, color: Colors.white70),
                              label: Text(
                                "GITHUB",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "CLOSE",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      builder: (context, scrollController) {
        return Material(
          color: const Color(0xFF18181B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Settings',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.upload_file, color: Color(0xFF00E5FF)),
                    title: const Text('Export Data'),
                    subtitle: const Text(
                      'Save progress to JSON',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      // Grab ref before popping
                      await _exportData(context, ref);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download, color: Color(0xFF69F0AE)),
                    title: const Text('Import Data'),
                    subtitle: const Text(
                      'Restore from JSON file',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      await _importData(context, ref);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                    title: const Text('Apply Preset'),
                    subtitle: const Text(
                      'Apply default GoClasses/YouTube sources',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF18181B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          title: const Text('Apply Preset'),
                          content: const Text(
                            'This will overwrite current sources and counts for some subjects. Continue?',
                            style: TextStyle(color: Colors.white70),
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
                        // Close the settings sheet now
                        if (context.mounted) Navigator.pop(context);
                        
                        await ref
                            .read(subjectControllerProvider.notifier)
                            .applyPreset();
                      }
                    },
                  ),
                  const Divider(color: Colors.white12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'SYSTEM UPDATES',
                      style: TextStyle(
                        color: ref.watch(overallProgressColorProvider).withAlpha(178),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const LastCheckedSubtitleTile(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.settings_rounded, color: Colors.white30, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Update Check Frequency',
                          style: TextStyle(
                            color: Colors.white.withAlpha(128),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final currentFreq = ref.watch(updateFrequencyProvider);
                        final accentColor = ref.watch(overallProgressColorProvider);

                        return Row(
                          children: ['Daily', 'Weekly', 'Monthly'].map((freq) {
                            final isSelected = currentFreq == freq;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => ref.read(updateFrequencyProvider.notifier).setFrequency(freq),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? accentColor.withAlpha(51) : Colors.white10,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? accentColor : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      freq,
                                      style: TextStyle(
                                        color: isSelected ? accentColor : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      leading: const Icon(Icons.tune_rounded, color: Colors.amberAccent),
                      title: const Text('Advanced Settings'),
                      subtitle: const Text(
                        'Telemetry, custom endpoints, diagnostics',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      iconColor: Colors.amberAccent,
                      collapsedIconColor: Colors.white70,
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 0),
                      children: const [
                        TelemetrySettingsSection(),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  Padding(
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
                  ),
                  ListTile(
                    leading: const Icon(Icons.history_rounded, color: Colors.redAccent),
                    title: const Text('Reset Tracking Data'),
                    subtitle: const Text(
                      'Set all progress counts to zero',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      await _performReset(context, ref, everything: false);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    title: const Text('Reset Everything'),
                    subtitle: const Text(
                      'Clear sources, links, and progress',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      await _performReset(context, ref, everything: true);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: ref.watch(overallProgressColorProvider)),
                    title: const Text('About GATE Tracker'),
                    subtitle: const Text(
                      'Developer info, repository and description',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      _showAboutDialog(context, ref);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'GATE Tracker v1.0.0',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LastCheckedSubtitleTile extends ConsumerStatefulWidget {
  const LastCheckedSubtitleTile({super.key});

  @override
  ConsumerState<LastCheckedSubtitleTile> createState() => _LastCheckedSubtitleTileState();
}

class _LastCheckedSubtitleTileState extends ConsumerState<LastCheckedSubtitleTile> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Invalidate immediately upon opening to ensure the timestamp is fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(lastUpdateCheckTimeProvider);
      }
    });
    // Live countdown refresh timer - auto-invalidates the cached relative time provider every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        ref.invalidate(lastUpdateCheckTimeProvider);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastCheckedAsync = ref.watch(lastUpdateCheckTimeProvider);
    final lastChecked = lastCheckedAsync.value ?? 'Never';
    final accentColor = ref.watch(overallProgressColorProvider);

    return ListTile(
      leading: Icon(Icons.sync_rounded, color: accentColor),
      title: const Text('Check For Updates Now'),
      subtitle: Text(
        'Last checked: $lastChecked',
        style: const TextStyle(color: Colors.grey),
      ),
      onTap: () {
        // Close the sheet immediately — DashboardScreen's ref.listen handles all results
        Navigator.of(context).pop();
        ref.read(updaterProvider.notifier).checkForUpdates();
      },
    );
  }
}

class TelemetrySettingsSection extends StatefulWidget {
  const TelemetrySettingsSection({super.key});

  @override
  State<TelemetrySettingsSection> createState() => _TelemetrySettingsSectionState();
}

class _TelemetrySettingsSectionState extends State<TelemetrySettingsSection> {
  bool _isEnabled = true;
  final TextEditingController _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final enabled = await TelemetryService.isTelemetryEnabled();
    final customUrl = await TelemetryService.getCustomUrl();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _urlController.text = customUrl;
      });
    }
  }

  Future<void> _toggleTelemetry(bool value) async {
    await TelemetryService.setTelemetryEnabled(value);
    setState(() {
      _isEnabled = value;
    });
  }

  Future<void> _saveCustomUrl(String value) async {
    await TelemetryService.setCustomUrl(value);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final result = await TelemetryService.sendTestPing(_urlController.text);
    
    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = result['success'] as bool;
        _testMessage = result['message'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(color: Colors.white12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'TELEMETRY & DIAGNOSTICS',
            style: TextStyle(
              color: Colors.amberAccent.withAlpha(178),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SwitchListTile(
          value: _isEnabled,
          onChanged: _toggleTelemetry,
          activeThumbColor: Colors.amberAccent,
          secondary: const Icon(Icons.analytics_outlined, color: Colors.amberAccent),
          title: const Text('Anonymous Daily Telemetry'),
          subtitle: const Text(
            'Ping server securely with SHA256 tokens upon app launch. GDPR-compliant. No personal data collected.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
        if (_isEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Custom Telemetry Endpoint URL',
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'https://gate-tracker-telemetry.vercel.app/api/ping',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: _saveCustomUrl,
                          onSubmitted: _saveCustomUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isTesting ? null : _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(12),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                        ),
                        child: _isTesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.bolt, color: Colors.amberAccent, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Leave blank to use the default production telemetry server.',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
                if (_testMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _testSuccess == true
                          ? Colors.green.withAlpha(20)
                          : Colors.redAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _testSuccess == true
                            ? Colors.green.withAlpha(80)
                            : Colors.redAccent.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testSuccess == true
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          color: _testSuccess == true ? Colors.greenAccent : Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testMessage!,
                            style: TextStyle(
                              color: _testSuccess == true ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
