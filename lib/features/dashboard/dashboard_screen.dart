import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/app_database.dart';
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  late final TextEditingController _searchController;
  Timer? _autoHideTimer;

  bool searchBarVisible = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _resetAutoHideTimer() {
    _autoHideTimer?.cancel();
    if (searchQuery.isEmpty) {
      _autoHideTimer = Timer(const Duration(seconds: 8), () {
        if (mounted && searchQuery.isEmpty) {
          setState(() {
            searchBarVisible = false;
          });
          _focusNode.unfocus();
        }
      });
    }
  }

  Widget _buildConstrainedBody(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: child,
      ),
    );
  }

  double _calculateScore(SyllabusTopicWithTasks topicWithTasks, String query, String categoryName) {
    final topic = topicWithTasks.topic;
    final name = topic.name.toLowerCase();
    final catName = categoryName.toLowerCase();
    
    // Extract note
    final rawUrl = topic.resourceUrl ?? '';
    String note = '';
    if (rawUrl.trim().isNotEmpty) {
      final parts = rawUrl.trim().split('|');
      if (parts.length > 2) {
        note = parts[2].trim().toLowerCase();
      }
    }

    double score = 0;
    
    // Category Name Match (highest weight)
    if (catName == query) {
      score += 150;
    } else if (catName.contains(query)) {
      score += 80 + (1.0 / (catName.indexOf(query) + 1));
    }
    
    // Topic Name Match
    if (name == query) {
      score += 100;
    } else if (name.contains(query)) {
      score += 50 + (1.0 / (name.indexOf(query) + 1));
    }
    
    if (note.isNotEmpty) {
      if (note == query) {
        score += 40;
      } else if (note.contains(query)) {
        score += 20;
      }
    }
    
    for (final task in topicWithTasks.tasks) {
      final taskName = task.name.toLowerCase();
      if (taskName == query) {
        score += 30;
      } else if (taskName.contains(query)) {
        score += 15;
      }
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final syllabusAsync = ref.watch(syllabusProvider);

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Track overall scrolled state for app bar transparency
          final isScrolled = notification.metrics.pixels > 10.0;
          if (ref.read(completionIsScrolledProvider) != isScrolled) {
            Future.microtask(() {
              ref.read(completionIsScrolledProvider.notifier).setScrolled(isScrolled);
            });
          }

          // Track overscroll to show Search Bar
          if (notification is ScrollUpdateNotification) {
            final double pixels = notification.metrics.pixels;
            if (pixels < 0) {
              final double overscroll = -pixels;
              if (overscroll > 15.0) {
                if (!searchBarVisible) {
                  setState(() {
                    searchBarVisible = true;
                  });
                  _resetAutoHideTimer();
                }
              }
              if (overscroll >= 65.0) {
                if (!_focusNode.hasFocus) {
                  _focusNode.requestFocus();
                  _resetAutoHideTimer();
                }
              }
            }
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

            // Search processing logic
            final query = searchQuery.trim().toLowerCase();
            List<SyllabusCategoryWithTopics> filteredSyllabus = [];
            SyllabusTopicWithTasks? bestMatchTopic;
            SyllabusCategory? bestMatchCategory;
            double maxScore = 0;

            if (query.isNotEmpty) {
              for (final catWithTopics in syllabusData) {
                List<SyllabusTopicWithTasks> matchedTopics = [];
                for (final topicWithTasks in catWithTopics.topics) {
                  double score = _calculateScore(topicWithTasks, query, catWithTopics.category.name);
                  if (score > 0) {
                    matchedTopics.add(topicWithTasks);
                    if (score > maxScore) {
                      maxScore = score;
                      bestMatchTopic = topicWithTasks;
                      bestMatchCategory = catWithTopics.category;
                    }
                  }
                }
                
                if (matchedTopics.isNotEmpty) {
                  filteredSyllabus.add(SyllabusCategoryWithTopics(
                    category: catWithTopics.category,
                    topics: matchedTopics,
                  ));
                }
              }
              
              if (bestMatchTopic != null && bestMatchCategory != null) {
                filteredSyllabus = filteredSyllabus.map((catWithTopics) {
                  if (catWithTopics.category.id == bestMatchCategory!.id) {
                    return SyllabusCategoryWithTopics(
                      category: catWithTopics.category,
                      topics: catWithTopics.topics.where((t) => t.topic.id != bestMatchTopic!.topic.id).toList(),
                    );
                  }
                  return catWithTopics;
                }).where((catWithTopics) => catWithTopics.topics.isNotEmpty).toList();
              }
            } else {
              filteredSyllabus = syllabusData;
            }

            return _buildConstrainedBody(CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Header spacing
                SliverToBoxAdapter(
                  child: SizedBox(height: context.s(72) + MediaQuery.of(context).padding.top),
                ),

                // Animated Search Bar
                SliverToBoxAdapter(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    height: searchBarVisible ? context.s(64) : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: searchBarVisible ? 1.0 : 0.0,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: context.s(14)),
                            decoration: InputDecoration(
                              hintText: 'Search syllabus topics, notes, or tasks...',
                              hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: context.s(13)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    searchQuery = "";
                                    searchBarVisible = false;
                                  });
                                  _focusNode.unfocus();
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFF27272A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(context.s(12)),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: context.s(10)),
                            ),
                            onChanged: (val) {
                              setState(() {
                                searchQuery = val;
                              });
                              _resetAutoHideTimer();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(context.s(20), context.s(12), context.s(20), context.s(20)),
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
                  // 1. BEST MATCH IF APPLICABLE
                  if (query.isNotEmpty && bestMatchTopic != null && bestMatchCategory != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(context.s(16), context.s(12), context.s(16), context.s(4)),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: Color(bestMatchCategory.color), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'BEST MATCH (FROM ${bestMatchCategory.name.toUpperCase()})',
                              style: GoogleFonts.jersey15(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(bestMatchCategory.color),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SyllabusTopicCard(
                        topicWithTasks: bestMatchTopic,
                        categoryColor: Color(bestMatchCategory.color),
                        forceExpanded: true,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.s(16)),
                        child: const Divider(color: Colors.white10, height: 16),
                      ),
                    ),
                  ],

                  // 2. NORMAL / FILTERED LIST
                  ...filteredSyllabus.asMap().entries.map((entry) {
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
                      final prevCat = filteredSyllabus[index - 1];
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
                              (context, idx) {
                                final topicWithTasks = topics[idx];
                                return SyllabusTopicCard(
                                  topicWithTasks: topicWithTasks,
                                  categoryColor: Color(category.color),
                                  forceExpanded: query.isNotEmpty,
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
