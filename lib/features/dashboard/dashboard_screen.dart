import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/subject_provider.dart';
import '../../widgets/pill_progress_widget.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/completion_provider.dart';
import 'widgets/syllabus_category_header.dart';
import 'widgets/syllabus_topic_card.dart';
import 'widgets/syllabus_customization_sheets.dart';
import '../../utils/ui_scaling.dart';

class CompletionIsScrolledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setScrolled(bool val) {
    state = val;
  }
}

final completionIsScrolledProvider = NotifierProvider<CompletionIsScrolledNotifier, bool>(() {
  return CompletionIsScrolledNotifier();
});

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
    final syllabusAsync = ref.watch(syllabusProvider);
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final isScrolled = notification.metrics.pixels > 10.0;
          if (ref.read(completionIsScrolledProvider) != isScrolled) {
            Future.microtask(() {
              ref.read(completionIsScrolledProvider.notifier).setScrolled(isScrolled);
            });
          }
          return false;
        },
        child: syllabusAsync.when(
          data: (syllabusData) {
            final isSyllabusEmpty = syllabusData.isEmpty;

            final stats = ref.watch(completionStatsProvider).value ?? CompletionStats(percentage: 0.0, completed: 0, total: 0);
            final overallProgress = stats.percentage;
            final totalCompleted = stats.completed;
            final totalTasks = stats.total;


            return _buildConstrainedBody(CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: context.s(72) + MediaQuery.of(context).padding.top),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(context.s(20), context.s(24), context.s(20), context.s(20)),
                    child: PillProgressWidget(
                      percentage: overallProgress,
                      totalCompleted: totalCompleted,
                      totalVideos: totalTasks,
                    ),
                  ),
                ),
                if (isSyllabusEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.s(32.0), vertical: context.s(24.0)),
                      child: const WelcomeWidget(),
                    ),
                  )
                else ...[
                  ...syllabusData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final catWithTopics = entry.value;
                    final category = catWithTopics.category;
                    final topics = catWithTopics.topics;

                    int catCompleted = 0, catTotal = 0;
                    for (final topicWithTasks in topics) {
                      final topic = topicWithTasks.topic;
                      if (topic.isCounter) {
                        catCompleted += topic.currentCount;
                        catTotal += topic.maxCount;
                      } else {
                        catCompleted += topicWithTasks.tasks.where((t) => t.isCompleted).length;
                        catTotal += topicWithTasks.tasks.length;
                      }
                    }
                    final catProgress = catTotal == 0 ? 0.0 : (catCompleted / catTotal) * 100;
                    final rawTopics = topics.map((e) => e.topic).toList();

                    final manuallyExpanded = ref.watch(manuallyExpandedCompletedSyllabusCategoriesProvider);
                    final isCompleted = catProgress >= 100.0 && catTotal > 0;
                    final isCollapsed = isCompleted && !manuallyExpanded.contains(category.id);
                    final isPrevCollapsed = () {
                      if (index <= 0) return false;
                      final prevCat = syllabusData[index - 1];
                      int prevCompleted = 0, prevTotal = 0;
                      for (final topicWithTasks in prevCat.topics) {
                        final topic = topicWithTasks.topic;
                        if (topic.isCounter) {
                          prevCompleted += topic.currentCount;
                          prevTotal += topic.maxCount;
                        } else {
                          prevCompleted += topicWithTasks.tasks.where((t) => t.isCompleted).length;
                          prevTotal += topicWithTasks.tasks.length;
                        }
                      }
                      final prevProgress = prevTotal == 0 ? 0.0 : (prevCompleted / prevTotal) * 100;
                      final prevCompletedCheck = prevProgress >= 100.0 && prevTotal > 0;
                      return prevCompletedCheck && !manuallyExpanded.contains(prevCat.category.id);
                    }();

                    final headerPadding = isCollapsed
                        ? EdgeInsets.fromLTRB(context.s(16), context.s(12), context.s(16), 0)
                        : (isPrevCollapsed
                            ? EdgeInsets.fromLTRB(context.s(16), context.s(12), context.s(16), context.s(8))
                            : EdgeInsets.fromLTRB(context.s(16), context.s(24), context.s(16), context.s(8)));

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: headerPadding,
                            child: SyllabusCategoryHeader(
                              category: category,
                              progress: catProgress,
                              topics: rawTopics,
                              isCollapsed: isCollapsed,
                            ),
                          ),
                        ),
                        if (!isCollapsed)
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
                  SliverToBoxAdapter(child: SizedBox(height: context.s(48))),
                ],
              ],
            ));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class WelcomeWidget extends ConsumerWidget {
  const WelcomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = ref.watch(overallProgressColorProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.checklist_rtl_rounded,
          size: 64,
          color: progressColor.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 24),
        Text(
          "EMPTY SYLLABUS TRACKER",
          style: GoogleFonts.jersey15(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Create your first syllabus category to start building your custom exam check-list.",
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
              showCreateSyllabusCategoryDialog(context, ref);
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

