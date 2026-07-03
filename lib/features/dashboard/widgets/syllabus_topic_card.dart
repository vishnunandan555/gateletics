import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../database/app_database.dart';
import '../../../providers/syllabus_provider.dart';
import '../../../providers/topic_font_size_provider.dart';
import '../../../widgets/progress_bar.dart';
import 'syllabus_customization_sheets.dart';

class SyllabusTopicCard extends ConsumerWidget {
  final SyllabusTopicWithTasks topicWithTasks;
  final Color categoryColor;

  const SyllabusTopicCard({
    super.key,
    required this.topicWithTasks,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = topicWithTasks.topic;
    final tasks = topicWithTasks.tasks;

    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final percentage = totalCount == 0 ? 0.0 : (completedCount / totalCount) * 100;

    final expandedSet = ref.watch(expandedTopicsProvider);
    final isExpanded = expandedSet.contains(topic.id);

    final topicScaleFactor = ref.watch(topicFontSizeProvider).scaleFactor;
    final screenWidth = MediaQuery.of(context).size.width;

    // Adaptive font sizes based on screen width
    final topicFontSize = (screenWidth * 0.04).clamp(13.0, 16.0) * topicScaleFactor;
    final percentFontSize = (screenWidth * 0.08).clamp(24.0, 32.0) * topicScaleFactor;
    final countFontSize = (screenWidth * 0.028).clamp(10.0, 12.0) * topicScaleFactor;
    final taskFontSize = (screenWidth * 0.035).clamp(12.0, 15.0);

    late TapDownDetails topicTapDetails;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withAlpha(20),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Topic Panel (Tappable area)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              topicTapDetails = details;
            },
            onTap: () {
              ref.read(expandedTopicsProvider.notifier).toggle(topic.id);
            },
            onLongPress: () {
              _showTopicContextMenu(context, topicTapDetails, topic, tasks, ref);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: Title & Progress Bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          topic.name,
                          style: GoogleFonts.outfit(
                            fontSize: topicFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withAlpha(235),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        ProgressBar(
                          percentage: percentage,
                          height: 8,
                          color: categoryColor,
                          showTicks: true,
                          tickCount: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // RIGHT: Big % & Fraction count
                  Container(
                    width: 80,
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: percentFontSize,
                            fontWeight: FontWeight.w900,
                            color: categoryColor,
                            letterSpacing: -1.0,
                            height: 1,
                            shadows: [
                              Shadow(
                                color: categoryColor.withAlpha(140),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount/$totalCount',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: countFontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Checklist Area
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            if (totalCount == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Center(
                  child: Text(
                    'No tasks in this topic. Long press topic name to add tasks!',
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...List.generate(totalCount, (index) {
                final task = tasks[index];
                late TapDownDetails taskTapDetails;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    taskTapDetails = details;
                  },
                  onTap: () {
                    ref
                        .read(syllabusControllerProvider.notifier)
                        .toggleTask(task.id, !task.isCompleted);
                  },
                  onLongPress: () {
                    _showTaskContextMenu(context, taskTapDetails, task, ref);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        // Custom Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: task.isCompleted
                                ? categoryColor.withAlpha(38)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: task.isCompleted ? categoryColor : Colors.white24,
                              width: 1.5,
                            ),
                          ),
                          child: task.isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: categoryColor,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Task Name
                        Expanded(
                          child: Text(
                            task.name,
                            style: GoogleFonts.outfit(
                              color: task.isCompleted ? Colors.white38 : Colors.white70,
                              fontSize: taskFontSize,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  void _showTopicContextMenu(
      BuildContext context, TapDownDetails details, SyllabusTopic topic, List<SyllabusTask> tasks, WidgetRef ref) {
    final position = details.globalPosition;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          value: 'rename',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.edit_rounded, color: categoryColor, size: 18),
              const SizedBox(width: 10),
              const Text('Rename Topic', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_task',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, color: categoryColor, size: 18),
              const SizedBox(width: 10),
              const Text('Add Task', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'complete',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: categoryColor, size: 18),
              const SizedBox(width: 10),
              const Text('Mark as Complete', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'reset',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.replay_rounded, color: categoryColor, size: 18),
              const SizedBox(width: 10),
              const Text('Reset Stats', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'reorder',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.swap_vert_rounded, color: categoryColor, size: 18),
              const SizedBox(width: 10),
              const Text('Reorder Tasks', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 10),
              Text('Delete Topic', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (!context.mounted) return;
      if (val == 'rename') {
        showRenameSyllabusTopicDialog(context, topic, categoryColor, ref);
      } else if (val == 'add_task') {
        showAddSyllabusTaskDialog(context, topic, categoryColor, ref);
      } else if (val == 'complete') {
        ref.read(syllabusControllerProvider.notifier).markTopicCompleted(topic.id);
      } else if (val == 'reset') {
        ref.read(syllabusControllerProvider.notifier).resetTopicStats(topic.id);
      } else if (val == 'reorder') {
        showReorderSyllabusTasksDialog(context, topic, tasks, categoryColor, ref);
      } else if (val == 'delete') {
        showDeleteSyllabusTopicConfirm(context, topic, categoryColor, ref);
      }
    });
  }

  void _showTaskContextMenu(BuildContext context, TapDownDetails details, SyllabusTask task, WidgetRef ref) {
    final position = details.globalPosition;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          value: 'rename',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.edit_rounded, color: categoryColor, size: 18),
              const SizedBox(width: 10),
              const Text('Rename Task', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 10),
              Text('Delete Task', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (!context.mounted) return;
      if (val == 'rename') {
        showRenameSyllabusTaskDialog(context, task, categoryColor, ref);
      } else if (val == 'delete') {
        showDeleteSyllabusTaskConfirm(context, task, categoryColor, ref);
      }
    });
  }
}
