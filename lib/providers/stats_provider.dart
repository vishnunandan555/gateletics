import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'syllabus_provider.dart';

class CategoryStudyTime {
  final int? id;
  final String name;
  final int colorValue;
  final double hours;
  final double percentage;

  CategoryStudyTime({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.hours,
    required this.percentage,
  });
}

// Category breakdown of completed tasks
final categoryStudyTimeProvider = Provider<AsyncValue<List<CategoryStudyTime>>>((ref) {
  final tasksAsync = ref.watch(syllabusTasksProvider);
  final topicsAsync = ref.watch(syllabusTopicsProvider);
  final categoriesAsync = ref.watch(syllabusCategoriesProvider);

  if (tasksAsync.hasError) return AsyncValue.error(tasksAsync.error!, tasksAsync.stackTrace!);
  if (topicsAsync.hasError) return AsyncValue.error(topicsAsync.error!, topicsAsync.stackTrace!);
  if (categoriesAsync.hasError) return AsyncValue.error(categoriesAsync.error!, categoriesAsync.stackTrace!);

  if (!tasksAsync.hasValue || !topicsAsync.hasValue || !categoriesAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final tasks = tasksAsync.value!;
  final topics = topicsAsync.value!;
  final categories = categoriesAsync.value!;

  final Map<int, int> completedTaskCounts = {};
  int totalCompleted = 0;

  final topicMap = {for (final t in topics) t.id: t.categoryId};

  for (final task in tasks) {
    if (task.isCompleted) {
      final catId = topicMap[task.topicId];
      if (catId != null) {
        completedTaskCounts[catId] = (completedTaskCounts[catId] ?? 0) + 1;
        totalCompleted++;
      }
    }
  }

  final List<CategoryStudyTime> list = [];
  final Map<int, SyllabusCategory> catMap = {for (final c in categories) c.id: c};

  for (final entry in completedTaskCounts.entries) {
    final catId = entry.key;
    final count = entry.value;
    final pct = totalCompleted > 0 ? (count / totalCompleted) * 100 : 0.0;

    final cat = catMap[catId];
    list.add(CategoryStudyTime(
      id: catId,
      name: cat?.name ?? 'Unknown Category',
      colorValue: cat?.color ?? 0xFF00FFCC,
      hours: count.toDouble(),
      percentage: pct,
    ));
  }

  // Sort descending by task count
  list.sort((a, b) => b.hours.compareTo(a.hours));
  return AsyncValue.data(list);
});
