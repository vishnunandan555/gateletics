import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/subject_provider.dart';
import '../../providers/updater_provider.dart';
import 'widgets/customization_sheets.dart';
import 'widgets/app_bar_title.dart';
import 'widgets/countdown_widget.dart';
import 'widgets/category_header.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/pill_progress_widget.dart';
import '../../widgets/updater_dialog.dart';
import '../../widgets/settings_sheet.dart';
import '../../providers/completion_type_provider.dart';

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

  void _showInstructionsThenCreateCategoryDialog(BuildContext context, WidgetRef ref) {
    final progressColor = ref.read(overallProgressColorProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: progressColor.withValues(alpha: 0.2), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: progressColor),
            const SizedBox(width: 10),
            Text(
              'QUICK GUIDE',
              style: GoogleFonts.outfit(
                textStyle: TextStyle(
                  fontFamily: 'BatmanForever',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'To Create New Category, Long Press on any Category Name and to Create New Subjects (inside category) Tap on three vertical dots beside Category % to its right',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close guide dialog
                showCreateCategoryDialog(context, ref); // Open category creation dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: progressColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Understood',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
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
      if (next.status == UpdaterStatus.updateAvailable &&
          previous?.status != UpdaterStatus.updateAvailable) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const UpdaterDialog(),
        );
      }

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

      if (next.status == UpdaterStatus.noReleasesAtAll &&
          previous?.status != UpdaterStatus.noReleasesAtAll) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No updates available at the moment.'),
            duration: Duration(seconds: 3),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(updaterProvider.notifier).resetToIdle();
        });
      }

      if (next.status == UpdaterStatus.error &&
          previous?.status != UpdaterStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage.isEmpty
                ? 'Update check failed — check your connection and try again.'
                : next.errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(updaterProvider.notifier).resetToIdle();
        });
      }
    });

    final categoriesAsync = ref.watch(categoriesWithSubjectsProvider);
    final progressColor = ref.watch(overallProgressColorProvider);
    final completionType = ref.watch(completionTypeProvider);

    return Scaffold(
      body: categoriesAsync.when(
        data: (categoriesWithSubs) {
          final isEmpty = categoriesWithSubs.isEmpty;

          int totalCompleted = 0, totalVideos = 0;
          if (!isEmpty) {
            for (final cat in categoriesWithSubs) {
              for (final s in cat.subjects) {
                if (s.isActive) {
                  totalCompleted += s.completedVideos;
                  totalVideos += s.totalVideos;
                }
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
                title: const AppBarTitle(),
                actions: const [
                  CountdownWidget(),
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
              if (completionType == CompletionType.syllabus)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox.shrink(),
                )
              else ...[
                if (isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'To Begin, either load our Pre-built Preset or Start Making your own custom syllabus.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 220,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ref.read(subjectControllerProvider.notifier).applyPreset();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: progressColor,
                                    foregroundColor: Colors.black,
                                    elevation: 8,
                                    shadowColor: progressColor.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Load Preset',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 220,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () {
                                    _showInstructionsThenCreateCategoryDialog(context, ref);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: progressColor.withValues(alpha: 0.5), width: 1.5),
                                    foregroundColor: progressColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Create Category',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  )
                else
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
                            child: CategoryHeader(
                              category: category,
                              progress: catProgress,
                            ),
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
                if (!isEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
