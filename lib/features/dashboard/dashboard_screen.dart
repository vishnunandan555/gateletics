import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';
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
        'sourceName': s.sourceName,
        'playlistLink': s.playlistLink,
        'isActive': s.isActive,
      }).toList();

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = utf8.encode(jsonString);

      final result = await FilePicker.saveFile(
        dialogTitle: 'Export Subjects Data',
        fileName: 'subjects_export.json',
        bytes: bytes,
      );

      if (result != null && context.mounted) {
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
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);

      for (final item in data) {
        final Map<String, dynamic> map = item as Map<String, dynamic>;
        await ref.read(subjectControllerProvider.notifier).addSubject(
              name: map['name'] ?? 'Imported Subject',
              completed: map['completedVideos'] ?? 0,
              total: map['totalVideos'] ?? 100,
              category: map['category'] ?? 'General',
              sourceName: map['sourceName'] ?? '',
              playlistLink: map['playlistLink'] ?? '',
              isActive: map['isActive'] ?? true,
            );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully!')),
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

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SETTINGS',
              style: TextStyle(
                fontFamily: 'BatmanForever',
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Export Data'),
              subtitle: const Text('Save your progress to a JSON file'),
              onTap: () {
                Navigator.pop(context);
                _exportData(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Import Data'),
              subtitle: const Text('Load progress from a JSON file'),
              onTap: () {
                Navigator.pop(context);
                _importData(context, ref);
              },
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              'GATE Tracker v0.0.4',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
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
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: progressColor,
                height: 1.0,
                shadows: [Shadow(color: progressColor.withAlpha(204), blurRadius: 12)],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'DAYS LEFT',
              style: TextStyle(
                fontSize: 10,
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
