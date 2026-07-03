import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/subject_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/widgets/app_bar_title.dart';
import '../dashboard/widgets/countdown_widget.dart';
import '../dashboard/widgets/category_header.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/pill_progress_widget.dart';
import '../../providers/completion_type_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../dashboard/widgets/syllabus_category_header.dart';
import '../dashboard/widgets/syllabus_topic_card.dart';
import '../../providers/topic_font_size_provider.dart';

class DeskDashboardScreen extends ConsumerWidget {
  const DeskDashboardScreen({super.key});

  static const double _maxContentWidth = 1600;

  Widget _buildConstrainedBody(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }

  int _gridCrossAxisCount(double width) {
    if (width >= 1500) return 3;
    if (width >= 900) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesWithSubjectsProvider);
    final completionType = ref.watch(completionTypeProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = _gridCrossAxisCount(screenWidth);
    final topicScaleFactor = ref.watch(topicFontSizeProvider).scaleFactor;

    // Calculate dynamic child aspect ratio for SubjectCard to target a constant height of 132px * scale factor
    final double sidebarWidth = screenWidth < 768 ? 76.0 : 220.0;
    final double availableWidth = (screenWidth - sidebarWidth).clamp(0.0, 1600.0);
    final double gridWidth = availableWidth - 32.0; // horizontal margins
    final double spacingTotal = (crossAxisCount - 1) * 8.0;
    final double cardWidth = (gridWidth - spacingTotal) / crossAxisCount;
    final double targetCardHeight = 120.0 * topicScaleFactor;
    final double childAspectRatio = (cardWidth / targetCardHeight).clamp(1.5, 4.0);

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
                  centerTitle: false,
                  automaticallyImplyLeading: false,
                  title: const AppBarTitle(),
                  actions: const [CountdownWidget()],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                      child: _SyllabusTwoColumnLayout(
                        syllabusData: syllabusData,
                      ),
                    ),
                  ),
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
                centerTitle: false,
                automaticallyImplyLeading: false,
                title: const AppBarTitle(),
                actions: const [CountdownWidget()],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                ...categoriesWithSubs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final catWithSubs = entry.value;
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

                  final manuallyExpanded = ref.watch(manuallyExpandedCompletedCategoriesProvider);
                  final isCompleted = catProgress >= 100.0 && catTotal > 0;
                  final isCollapsed = isCompleted && !manuallyExpanded.contains(category.id);

                  bool isPrevCollapsed = false;
                  if (index > 0) {
                    final prevCat = categoriesWithSubs[index - 1];
                    int prevCompleted = 0, prevTotal = 0;
                    for (final s in prevCat.subjects) {
                      if (s.isActive) {
                        prevCompleted += s.completedVideos;
                        prevTotal += s.totalVideos;
                      }
                    }
                    final prevProgress = prevTotal == 0 ? 0.0 : (prevCompleted / prevTotal) * 100;
                    final prevCompletedCheck = prevProgress >= 100.0 && prevTotal > 0;
                    isPrevCollapsed = prevCompletedCheck && !manuallyExpanded.contains(prevCat.category.id);
                  }

                  final headerPadding = isCollapsed
                      ? const EdgeInsets.fromLTRB(24, 16, 24, 0)
                      : (isPrevCollapsed
                          ? const EdgeInsets.fromLTRB(24, 16, 24, 12)
                          : const EdgeInsets.fromLTRB(24, 32, 24, 12));

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: headerPadding,
                          child: CategoryHeader(
                            category: category,
                            progress: catProgress,
                            isCollapsed: isCollapsed,
                          ),
                        ),
                      ),
                      if (!isCollapsed)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: childAspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final s = catSubjects[index];
                                return SubjectCard(
                                  subject: s,
                                  color: s.color != null ? Color(s.color!) : catColor,
                                  onIncrement: () => ref.read(subjectControllerProvider.notifier).increment(s),
                                  onDecrement: () => ref.read(subjectControllerProvider.notifier).decrement(s),
                                  onEdit: ({
                                    required completed,
                                    required total,
                                    required sourceName,
                                    required playlistLink,
                                    required isActive,
                                  }) =>
                                      ref.read(subjectControllerProvider.notifier).updateSubjectDetails(
                                            s,
                                            completed: completed,
                                            total: total,
                                            sourceName: sourceName,
                                            playlistLink: playlistLink,
                                            isActive: isActive,
                                          ),
                                );
                              },
                              childCount: catSubjects.length,
                            ),
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

class _SyllabusTwoColumnLayout extends StatelessWidget {
  final List<SyllabusCategoryWithTopics> syllabusData;

  const _SyllabusTwoColumnLayout({
    required this.syllabusData,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 768;

    if (isCompact) {
      return Column(
        children: syllabusData.asMap().entries.map((entry) {
          return _SyllabusCategoryBlock(
            index: entry.key,
            catWithTopics: entry.value,
            syllabusData: syllabusData,
          );
        }).toList(),
      );
    }

    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (final entry in syllabusData.asMap().entries) {
      final index = entry.key;
      final catWithTopics = entry.value;
      final widget = _SyllabusCategoryBlock(
        index: index,
        catWithTopics: catWithTopics,
        syllabusData: syllabusData,
      );
      if (index.isEven) {
        leftColumn.add(widget);
      } else {
        rightColumn.add(widget);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftColumn)),
        const SizedBox(width: 16),
        Expanded(child: Column(children: rightColumn)),
      ],
    );
  }
}

class _SyllabusCategoryBlock extends ConsumerWidget {
  final int index;
  final SyllabusCategoryWithTopics catWithTopics;
  final List<SyllabusCategoryWithTopics> syllabusData;

  const _SyllabusCategoryBlock({
    required this.index,
    required this.catWithTopics,
    required this.syllabusData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = catWithTopics.category;
    final topics = catWithTopics.topics;

    int catCompleted = 0, catTotal = 0;
    for (final topic in topics) {
      catCompleted += topic.tasks.where((t) => t.isCompleted).length;
      catTotal += topic.tasks.length;
    }
    final catProgress = catTotal == 0 ? 0.0 : (catCompleted / catTotal) * 100;
    final rawTopics = topics.map((e) => e.topic).toList();

    final manuallyExpanded = ref.watch(manuallyExpandedCompletedSyllabusCategoriesProvider);
    final isCompleted = catProgress >= 100.0 && catTotal > 0;
    final isCollapsed = isCompleted && !manuallyExpanded.contains(category.id);

    bool isPrevCollapsed = false;
    if (index > 0) {
      final prevCat = syllabusData[index - 1];
      int prevCompleted = 0, prevTotal = 0;
      for (final topic in prevCat.topics) {
        prevCompleted += topic.tasks.where((t) => t.isCompleted).length;
        prevTotal += topic.tasks.length;
      }
      final prevProgress = prevTotal == 0 ? 0.0 : (prevCompleted / prevTotal) * 100;
      final prevCompletedCheck = prevProgress >= 100.0 && prevTotal > 0;
      isPrevCollapsed = prevCompletedCheck && !manuallyExpanded.contains(prevCat.category.id);
    }

    final headerPadding = isCollapsed
        ? const EdgeInsets.fromLTRB(8, 12, 8, 0)
        : (isPrevCollapsed
            ? const EdgeInsets.fromLTRB(8, 12, 8, 8)
            : const EdgeInsets.fromLTRB(8, 24, 8, 8));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: headerPadding,
          child: SyllabusCategoryHeader(
            category: category,
            progress: catProgress,
            topics: rawTopics,
            isCollapsed: isCollapsed,
          ),
        ),
        if (!isCollapsed)
          ...topics.map(
            (topicWithTasks) => SyllabusTopicCard(
              topicWithTasks: topicWithTasks,
              categoryColor: Color(category.color),
            ),
          ),
      ],
    );
  }
}
