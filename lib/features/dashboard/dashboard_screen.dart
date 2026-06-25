import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/subject_provider.dart';
import 'widgets/customization_sheets.dart';
import 'widgets/app_bar_title.dart';
import 'widgets/countdown_widget.dart';
import 'widgets/category_header.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/pill_progress_widget.dart';
import '../../widgets/settings_sheet.dart';
import '../../providers/completion_type_provider.dart';
import '../../providers/syllabus_provider.dart';
import 'widgets/syllabus_category_header.dart';
import 'widgets/syllabus_topic_card.dart';
import 'widgets/syllabus_customization_sheets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Widget _buildConstrainedBody(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final categoriesAsync = ref.watch(categoriesWithSubjectsProvider);
    final completionType = ref.watch(completionTypeProvider);

    if (completionType == CompletionType.syllabus) {
      final syllabusAsync = ref.watch(syllabusProvider);
      return Scaffold(
        body: syllabusAsync.when(
          data: (syllabusData) {
            final isSyllabusEmpty = syllabusData.isEmpty;

            int totalCompleted = 0, totalTasks = 0;
            if (!isSyllabusEmpty) {
              for (final cat in syllabusData) {
                for (final topic in cat.topics) {
                  totalCompleted += topic.tasks.where((t) => t.isCompleted).length;
                  totalTasks += topic.tasks.length;
                }
              }
            }
            final overallProgress = totalTasks == 0 ? 0.0 : (totalCompleted / totalTasks) * 100;

            return _buildConstrainedBody(CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  toolbarHeight: 72,
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
                      totalVideos: totalTasks,
                    ),
                  ),
                ),
                if (isSyllabusEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                      child: WelcomeWidget(),
                    ),
                  )
                else ...[
                  ...syllabusData.map((catWithTopics) {
                    final category = catWithTopics.category;
                    final topics = catWithTopics.topics;

                    int catCompleted = 0, catTotal = 0;
                    for (final topic in topics) {
                      catCompleted += topic.tasks.where((t) => t.isCompleted).length;
                      catTotal += topic.tasks.length;
                    }
                    final catProgress = catTotal == 0 ? 0.0 : (catCompleted / catTotal) * 100;
                    final rawTopics = topics.map((e) => e.topic).toList();

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: SyllabusCategoryHeader(
                              category: category,
                              progress: catProgress,
                              topics: rawTopics,
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final topicWithTasks = topics[index];
                              return SyllabusTopicCard(
                                topicWithTasks: topicWithTasks,
                                categoryColor: Color(category.color),
                              );
                            },
                            childCount: topics.length,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ],
            ));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      );
    }

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

          return _buildConstrainedBody(CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                toolbarHeight: 72,
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
              if (isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                    child: WelcomeWidget(),
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
          ));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class WelcomeWidget extends ConsumerWidget {
  const WelcomeWidget({super.key});

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
    final completionType = ref.watch(completionTypeProvider);
    final progressColor = ref.watch(overallProgressColorProvider);
    final isSyllabus = completionType == CompletionType.syllabus;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isSyllabus ? Icons.checklist_rtl_rounded : Icons.video_library_rounded,
          size: 64,
          color: progressColor.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 24),
        Text(
          isSyllabus ? "EMPTY SYLLABUS TRACKER" : "EMPTY RESOURCE TRACKER",
          style: GoogleFonts.outfit(
            textStyle: const TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isSyllabus
              ? "Create your first syllabus category to start building your custom exam check-list."
              : "Create your first resource category to start tracking study play-lists and course counts.",
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white38,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 220,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (isSyllabus) {
                showCreateSyllabusCategoryDialog(context, ref);
              } else {
                _showInstructionsThenCreateCategoryDialog(context, ref);
              }
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
              'Create Category',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

