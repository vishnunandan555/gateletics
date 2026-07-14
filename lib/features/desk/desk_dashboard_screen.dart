import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/widgets/app_bar_title.dart';
import '../dashboard/widgets/countdown_widget.dart';
import '../../widgets/pill_progress_widget.dart';
import '../../providers/syllabus_provider.dart';
import '../dashboard/widgets/syllabus_category_header.dart';
import '../dashboard/widgets/syllabus_topic_card.dart';
import '../../providers/completion_provider.dart';

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

  // Removed unused _gridCrossAxisCount

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syllabusAsync = ref.watch(syllabusProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final double sidebarWidth = screenWidth < 768 ? 76.0 : 220.0;
    final double availableWidth = (screenWidth - sidebarWidth).clamp(0.0, 1600.0);

    return Scaffold(
      body: syllabusAsync.when(
        data: (syllabusData) {
          final isSyllabusEmpty = syllabusData.isEmpty;
          final stats = ref.watch(completionStatsProvider).value ?? CompletionStats(percentage: 0.0, completed: 0, total: 0);
          final overallProgress = stats.percentage;
          final totalCompleted = stats.completed;
          final totalTasks = stats.total;

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
                    child: _SyllabusMultiColumnLayout(
                      syllabusData: syllabusData,
                      availableWidth: availableWidth,
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
}

class _SyllabusMultiColumnLayout extends StatelessWidget {
  final List<SyllabusCategoryWithTopics> syllabusData;
  final double availableWidth;

  const _SyllabusMultiColumnLayout({
    required this.syllabusData,
    required this.availableWidth,
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

    int columnCount = 2;
    if (availableWidth >= 1300) {
      columnCount = 3;
    }
    if (availableWidth >= 1600) {
      columnCount = 4;
    }

    // Build lists for each column
    final columns = List.generate(columnCount, (_) => <Widget>[]);

    for (final entry in syllabusData.asMap().entries) {
      final index = entry.key;
      final catWithTopics = entry.value;
      final widget = _SyllabusCategoryBlock(
        index: index,
        catWithTopics: catWithTopics,
        syllabusData: syllabusData,
      );
      columns[index % columnCount].add(widget);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(columnCount, (colIndex) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: colIndex == 0 ? 0 : 8,
              right: colIndex == columnCount - 1 ? 0 : 8,
            ),
            child: Column(children: columns[colIndex]),
          ),
        );
      }),
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

    bool isPrevCollapsed = false;
    if (index > 0) {
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
