import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'dart:typed_data';
import '../../providers/subject_provider.dart';
import '../../database/models/subject.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/pill_progress_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // ── Settings actions ──────────────────────────────────────

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final subjects = ref.read(subjectsProvider).value;
      if (subjects == null) return;

      final data = subjects.map((s) => {
        'name': s.name,
        'category': s.category,
        'completedVideos': s.completedVideos,
        'totalVideos': s.totalVideos,
        'playlistLink': s.playlistLink,
        'sourceName': s.sourceName,
        'isActive': s.isActive,
      }).toList();

      final json = jsonEncode(data);
      final bytes = Uint8List.fromList(utf8.encode(json));

      // Trigger the native Android system "Save as" file manager dialog
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup to device',
        fileName: 'gate_tracker_backup.json',
        bytes: bytes,
      );

      if (path != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup saved successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      // Pick file using Storage Access Framework (SAF) - requires no storage permissions
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      if (!file.path.endsWith('.json')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid .json backup file.')),
          );
        }
        return;
      }

      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      final isar = await ref.read(isarServiceProvider).db;
      await isar.writeTxn(() async {
        for (final item in list) {
          final name = item['name'] as String?;
          if (name == null) continue;

          final s = await isar.subjects.filter().nameEqualTo(name).findFirst();
          if (s != null) {
            s.completedVideos = (item['completedVideos'] as int?) ?? 0;
            s.totalVideos = (item['totalVideos'] as int?) ?? s.totalVideos;
            s.playlistLink = (item['playlistLink'] as String?) ?? s.playlistLink;
            s.sourceName = (item['sourceName'] as String?) ?? s.sourceName;
            s.isActive = (item['isActive'] as bool?) ?? s.isActive;
            await isar.subjects.put(s);
          }
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Progress imported successfully!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
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

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Color(0xFF00E5FF)),
                  title: const Text('Export Data'),
                  subtitle: const Text(
                    'Save progress to JSON',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportData(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFF69F0AE)),
                  title: const Text('Import Data'),
                  subtitle: const Text(
                    'Restore from JSON file',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _importData(context, ref);
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
                    Navigator.pop(ctx);
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
                      await ref
                          .read(subjectControllerProvider.notifier)
                          .applyPreset();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preset applied!')),
                        );
                      }
                    }
                  },
                ),
                const Divider(color: Colors.white12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  leading: const Icon(Icons.history_rounded,
                      color: Colors.redAccent),
                  title: const Text('Reset Tracking Data'),
                  subtitle: const Text(
                    'Set all progress counts to zero',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _performReset(context, ref, everything: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded,
                      color: Colors.redAccent),
                  title: const Text('Reset Everything'),
                  subtitle: const Text(
                    'Clear sources, links, and progress',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _performReset(context, ref, everything: true);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Mathematical Foundation':
        return const Color(0xFFFF073A); // Ultra-punchy neon red
      case 'Programming Foundation':
        return const Color(0xFFFF6C00); // Vivid neon orange
      case 'System Depth':
        return const Color(0xFF00F0FF); // Electric neon cyan
      case 'Rest of the Stuff':
        return const Color(0xFFD500F9); // Bright neon magenta/purple
      default:
        return const Color(0xFF00F0FF);
    }
  }

  /// Renders large category text that fills left-to-right with [color] based on [progress].
  /// Grey base → colored fill from left at the progress percentage.
  Widget _textFillHeader(BuildContext context, String text, Color color, double progress) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        final fill = (progress / 100).clamp(0.0, 1.0);
        // Add a micro-interpolation stop zone (0.01 width) to prevent font pixel shifting/shaking on GPU
        final stop1 = (fill - 0.005).clamp(0.0, 1.0);
        final stop2 = (fill + 0.005).clamp(0.0, 1.0);
        return LinearGradient(
          colors: [
            color,
            color,
            const Color(0xFF4A4A4A), // Premium gunmetal grey base
            const Color(0xFF4A4A4A),
          ],
          stops: [0.0, stop1, stop2, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Legend',
          color: Colors.white, // white so ShaderMask paints through
          fontSize: (screenWidth * 0.07).clamp(20.0, 28.0),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(child: Text('No subjects found.'));
          }

          // Overall totals — only count subjects that are ACTIVE
          int totalCompleted = 0, totalVideos = 0;
          for (final s in subjects) {
            if (s.isActive) {
              totalCompleted += s.completedVideos;
              totalVideos += s.totalVideos;
            }
          }
          final overallProgress = totalVideos == 0
              ? 0.0
              : (totalCompleted / totalVideos) * 100;

          // Category grouping + ordering
          const categoryOrder = [
            'Mathematical Foundation',
            'Programming Foundation',
            'System Depth',
            'Rest of the Stuff',
          ];
          final grouped = groupBy(subjects, (s) => s.category);
          final sortedCategories = grouped.keys.toList()
            ..sort((a, b) {
              final ai = categoryOrder.indexOf(a);
              final bi = categoryOrder.indexOf(b);
              if (ai != -1 && bi != -1) return ai.compareTo(bi);
              return ai != -1 ? -1 : (bi != -1 ? 1 : a.compareTo(b));
            });

          return CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────
              SliverAppBar(
                toolbarHeight: 112,
                floating: true,
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 2,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () => _showSettingsSheet(context, ref),
                  tooltip: 'Settings',
                ),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GATE\nPROGRESS\nTRACKER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'BatmanForever',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'v0.0.3 ',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final progressColor = ref.watch(
                              overallProgressColorProvider,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: progressColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Alpha',
                                style: TextStyle(
                                  color: progressColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Overall progress squircle ────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: PillProgressWidget(
                    percentage: overallProgress,
                    totalCompleted: totalCompleted,
                    totalVideos: totalVideos,
                  ),
                ),
              ),

              // ── Category sections ────────────────────────
              ...sortedCategories.map((category) {
                final catSubjects = grouped[category]!;
                final catColor = _getCategoryColor(category);
                int catCompleted = 0, catTotal = 0;
                for (final s in catSubjects) {
                  if (s.isActive) {
                    catCompleted += s.completedVideos;
                    catTotal += s.totalVideos;
                  }
                }
                final catProgress = catTotal == 0
                    ? 0.0
                    : (catCompleted / catTotal) * 100;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Text-fill category header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                      child: _textFillHeader(context, category, catColor, catProgress),
                    ),
                    // Subject cards
                    ...catSubjects.map(
                      (s) => SubjectCard(
                        subject: s,
                        color: catColor,
                        onIncrement: () => ref
                            .read(subjectControllerProvider.notifier)
                            .increment(s),
                        onDecrement: () => ref
                            .read(subjectControllerProvider.notifier)
                            .decrement(s),
                        onEdit: ({
                          required completed,
                          required total,
                          required sourceName,
                          required playlistLink,
                          required isActive,
                        }) =>
                            ref
                                .read(subjectControllerProvider.notifier)
                                .updateSubjectDetails(
                                  s,
                                  completed: completed,
                                  total: total,
                                  sourceName: sourceName,
                                  playlistLink: playlistLink,
                                  isActive: isActive,
                                ),
                      ),
                    ),
                  ]),
                );
              }),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
