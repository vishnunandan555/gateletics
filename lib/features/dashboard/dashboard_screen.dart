import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:isar_community/isar.dart';
import '../../providers/subject_provider.dart';
import '../../providers/target_date_provider.dart';
import '../../database/models/subject.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/pill_progress_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final subjects = ref.read(subjectsProvider).value;
      if (subjects == null) return;

      final data = subjects.map((s) => {
        'name': s.name,
        'completedVideos': s.completedVideos,
        'totalVideos': s.totalVideos,
        'category': s.category,
        'playlistLink': s.playlistLink,
        'sourceName': s.sourceName,
        'isActive': s.isActive,
      }).toList();

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = Uint8List.fromList(utf8.encode(json));

      final path = await FilePicker.saveFile(
        dialogTitle: 'Save backup to device',
        fileName: 'subjects_export.json',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress imported successfully!')),
        );
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

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Material(
        color: const Color(0xFF18181B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
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
                    onTap: () {
                      Navigator.pop(context);
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
                      Navigator.pop(context);
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
                      Navigator.pop(context);
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
                    onTap: () {
                      Navigator.pop(context);
                      _performReset(context, ref, everything: false);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    title: const Text('Reset Everything'),
                    subtitle: const Text(
                      'Clear sources, links, and progress',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _performReset(context, ref, everything: true);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'GATE Tracker v0.0.4',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final intColor = Subject.categoryColors[category];
    if (intColor != null) {
      return Color(intColor);
    }
    switch (category.toLowerCase()) {
      case 'engineering mathematics': return Colors.blueAccent;
      case 'digital logic': return Colors.cyanAccent;
      case 'computer organization': return Colors.orangeAccent;
      case 'programming & data structures': return Colors.greenAccent;
      case 'algorithms': return Colors.redAccent;
      case 'theory of computation': return Colors.purpleAccent;
      case 'compiler design': return Colors.yellowAccent;
      case 'operating systems': return Colors.pinkAccent;
      case 'databases': return Colors.tealAccent;
      case 'computer networks': return Colors.indigoAccent;
      case 'general aptitude': return Colors.amberAccent;
      default: return Colors.cyanAccent;
    }
  }

  Widget _textFillHeader(BuildContext context, String title, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'BatmanForever',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${progress.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      body: subjectsAsync.when(
        data: (subjects) {
          int totalCompleted = 0, totalVideos = 0;
          for (final s in subjects) {
            if (s.isActive) {
              totalCompleted += s.completedVideos;
              totalVideos += s.totalVideos;
            }
          }
          final overallProgress = totalVideos == 0 ? 0.0 : (totalCompleted / totalVideos) * 100;
          final grouped = groupBy(subjects, (s) => s.category);
          final sortedCategories = grouped.keys.toList()
            ..sort((a, b) {
              final ai = Subject.categories.indexOf(a);
              final bi = Subject.categories.indexOf(b);
              if (ai != -1 && bi != -1) return ai.compareTo(bi);
              return ai != -1 ? -1 : (bi != -1 ? 1 : a.compareTo(b));
            });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
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
                title: const _AppBarTitle(),
                actions: const [
                  _CountdownWidget(),
                ],
              ),
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
                final catProgress = catTotal == 0 ? 0.0 : (catCompleted / catTotal) * 100;

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                        child: _textFillHeader(context, category, catColor, catProgress),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final s = catSubjects[index];
                          return SubjectCard(
                            subject: s,
                            color: catColor,
                            onIncrement: () => ref.read(subjectControllerProvider.notifier).increment(s),
                            onDecrement: () => ref.read(subjectControllerProvider.notifier).decrement(s),
                            onEdit: ({required completed, required total, required sourceName, required playlistLink, required isActive}) =>
                                ref.read(subjectControllerProvider.notifier).updateSubjectDetails(
                                  s, completed: completed, total: total, sourceName: sourceName, playlistLink: playlistLink, isActive: isActive,
                                ),
                          );
                        },
                        childCount: catSubjects.length,
                      ),
                    ),
                  ],
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

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  Future<void> _handleLongPress(BuildContext context) async {
    final bool? shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open GitHub Repo?'),
        content: const Text('Would you like to visit the project repository on GitHub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      final Uri url = Uri.parse('https://github.com/vishnunandan555/gate-tracker');
      if (!await launchUrl(url)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the link.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _handleLongPress(context),
      child: Column(
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
                'v0.0.4 ',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final progressColor = ref.watch(overallProgressColorProvider);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: progressColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Alpha',
                      style: TextStyle(color: progressColor, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownWidget extends ConsumerWidget {
  const _CountdownWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetDate = ref.watch(targetDateProvider);
    final progressColor = ref.watch(overallProgressColorProvider);
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    final daysLeft = difference.inDays > 0 ? difference.inDays : 0;

    return GestureDetector(
      onLongPress: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: targetDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (selected != null) {
          ref.read(targetDateProvider.notifier).setDate(selected);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$daysLeft',
              style: TextStyle(
                fontFamily: 'BatmanForever',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: progressColor,
                height: 1.0,
                shadows: [Shadow(color: progressColor.withAlpha(204), blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'DAYS LEFT',
              style: TextStyle(
                fontSize: 8,
                fontFamily: 'BatmanForever',
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
