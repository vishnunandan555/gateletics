import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/subject_provider.dart';
import '../../providers/target_date_provider.dart';
import '../../providers/updater_provider.dart';
import 'widgets/empty_state_view.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/pill_progress_widget.dart';
import '../../widgets/updater_dialog.dart';
import '../../widgets/settings_sheet.dart';

class HasCheckedForUpdates extends Notifier<bool> {
  @override
  bool build() => false;

  void setChecked(bool val) {
    state = val;
  }
}

final hasCheckedForUpdatesProvider = NotifierProvider<HasCheckedForUpdates, bool>(() {
  return HasCheckedForUpdates();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Widget _textFillHeader(BuildContext context, String title, Color color, double progress) {
    final normalized = (progress / 100).clamp(0.0, 1.0);
    const baseStyle = TextStyle(
      fontFamily: 'Legend',
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
      color: Colors.white54,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: normalized),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Measure the actual rendered text width so the fill
                  // is proportional to the text, not the container.
                  final textPainter = TextPainter(
                    text: TextSpan(text: title.toUpperCase(), style: baseStyle),
                    textDirection: TextDirection.ltr,
                  )..layout(maxWidth: constraints.maxWidth);

                  final fillWidth = textPainter.width * animValue;

                  return Stack(
                    children: [
                      Text(title.toUpperCase(), style: baseStyle),
                      ClipRect(
                        clipper: _ProgressClipper(fillWidth),
                        child: Text(
                          title.toUpperCase(),
                          style: baseStyle.copyWith(color: color),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${progress.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasChecked = ref.watch(hasCheckedForUpdatesProvider);
    if (!hasChecked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(hasCheckedForUpdatesProvider.notifier).setChecked(true);
        ref.read(updaterProvider.notifier).checkForUpdates(isAutomatic: true);
      });
    }

    ref.listen<UpdaterState>(updaterProvider, (previous, next) {
      // Update available → show the update dialog
      if (next.status == UpdaterStatus.updateAvailable &&
          previous?.status != UpdaterStatus.updateAvailable) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const UpdaterDialog(),
        );
      }

      // Already on latest version → snackbar feedback then reset
      if (next.status == UpdaterStatus.noUpdateAvailable &&
          previous?.status != UpdaterStatus.noUpdateAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ You\'re already on the latest version!'),
            duration: Duration(seconds: 3),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(updaterProvider.notifier).resetToIdle();
        });
      }

      // Check failed (not a download error — those are shown inside the dialog)
      if (next.status == UpdaterStatus.error &&
          previous?.status != UpdaterStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update check failed — check your connection and try again.'),
            duration: Duration(seconds: 4),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(updaterProvider.notifier).resetToIdle();
        });
      }
    });

    final categoriesAsync = ref.watch(categoriesWithSubjectsProvider);

    return Scaffold(
      body: categoriesAsync.when(
        data: (categoriesWithSubs) {
          if (categoriesWithSubs.isEmpty) {
            return const EmptyStateView();
          }

          int totalCompleted = 0, totalVideos = 0;
          for (final cat in categoriesWithSubs) {
            for (final s in cat.subjects) {
              if (s.isActive) {
                totalCompleted += s.completedVideos;
                totalVideos += s.totalVideos;
              }
            }
          }
          final overallProgress = totalVideos == 0 ? 0.0 : (totalCompleted / totalVideos) * 100;

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
                  onPressed: () => showSettingsSheet(context, ref),
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
              ...categoriesWithSubs.map((catWithSubs) {
                final category = catWithSubs.category;
                final catSubjects = catWithSubs.subjects;
                final catColor = Color(category.color);
                
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
                        child: _textFillHeader(context, category.name, catColor, catProgress),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final s = catSubjects[index];
                          return SubjectCard(
                            subject: s,
                            color: s.color != null ? Color(s.color!) : catColor,
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

class _ProgressClipper extends CustomClipper<Rect> {
  const _ProgressClipper(this.width);

  final double width;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(_ProgressClipper oldClipper) {
    return oldClipper.width != width;
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
                'v0.0.5 ',
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

