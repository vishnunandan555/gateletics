import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../database/app_database.dart';
import '../../../providers/syllabus_provider.dart';
import '../../../providers/topic_font_size_provider.dart';
import '../../../providers/task_font_size_provider.dart';
import '../../../providers/overall_ui_scale_provider.dart';
import '../../../widgets/progress_bar.dart';
import 'syllabus_customization_sheets.dart';
import '../../../utils/ui_scaling.dart';

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

    final overallScale = ref.watch(overallUiScaleProvider).scaleFactor;
    final topicScaleFactor = ref.watch(topicFontSizeProvider).scaleFactor;
    final taskScaleFactor = ref.watch(taskFontSizeProvider).scaleFactor;

    // Proportional font sizes using context.s() scaling factor
    final topicFontSize = context.s(16.0) * topicScaleFactor;
    final percentFontSize = context.s(27.0) * topicScaleFactor;
    final countFontSize = context.s(11.5) * topicScaleFactor;
    final taskFontSize = context.s(14.0) * taskScaleFactor;

    late TapDownDetails topicTapDetails;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.s(16.0), vertical: context.s(2.5) * overallScale),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(context.s(10)),
        border: Border.all(
          color: categoryColor.withAlpha(20),
          width: context.s(1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: context.s(10),
            offset: Offset(0, context.s(4)),
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
              padding: EdgeInsets.symmetric(horizontal: context.s(12) * overallScale, vertical: context.s(8) * overallScale),
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
                        SizedBox(height: context.s(6) * overallScale),
                        ProgressBar(
                          percentage: percentage,
                          height: context.s(8) * overallScale,
                          color: categoryColor,
                          showTicks: false,
                          tickCount: 10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.s(16) * overallScale),
                  // RIGHT: Big % & Fraction count
                  Container(
                    width: context.s(80) * overallScale,
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
                            letterSpacing: context.s(-1.0),
                            height: 1,
                            shadows: [
                              Shadow(
                                color: categoryColor.withAlpha(140),
                                blurRadius: context.s(14),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.s(4) * overallScale),
                        Text(
                          '$completedCount/$totalCount',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: countFontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: context.s(0.5),
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
                padding: EdgeInsets.symmetric(vertical: 16 * overallScale, horizontal: 16 * overallScale),
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
                    padding: EdgeInsets.symmetric(horizontal: context.s(14) * overallScale, vertical: context.s(8) * overallScale),
                    child: Row(
                      children: [
                        // Custom Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: context.s(18) * overallScale,
                          height: context.s(18) * overallScale,
                          decoration: BoxDecoration(
                            color: task.isCompleted
                                ? categoryColor.withAlpha(38)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(context.s(5)),
                            border: Border.all(
                              color: task.isCompleted ? categoryColor : Colors.white24,
                              width: context.s(1.5),
                            ),
                          ),
                          child: task.isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  size: context.s(14) * overallScale,
                                  color: categoryColor,
                                )
                              : null,
                        ),
                        SizedBox(width: context.s(12) * overallScale),
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
