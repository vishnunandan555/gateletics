import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
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

// Watch all focus sessions
final allFocusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.focusSessions)
        ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
      .watch();
});

// Category breakdown of focus hours
final categoryStudyTimeProvider = Provider<AsyncValue<List<CategoryStudyTime>>>((ref) {
  final focusSessionsAsync = ref.watch(allFocusSessionsProvider);
  final categoriesAsync = ref.watch(syllabusCategoriesProvider);

  if (focusSessionsAsync.hasError) return AsyncValue.error(focusSessionsAsync.error!, focusSessionsAsync.stackTrace!);
  if (categoriesAsync.hasError) return AsyncValue.error(categoriesAsync.error!, categoriesAsync.stackTrace!);

  if (!focusSessionsAsync.hasValue || !categoriesAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final sessions = focusSessionsAsync.value!;
  final categories = categoriesAsync.value!;

  final Map<int?, double> stats = {};
  double totalHours = 0.0;
  for (final s in sessions) {
    final hours = s.durationSeconds / 3600.0;
    stats[s.categoryId] = (stats[s.categoryId] ?? 0.0) + hours;
    totalHours += hours;
  }

  final List<CategoryStudyTime> list = [];
  final Map<int, SyllabusCategory> catMap = {for (final c in categories) c.id: c};

  for (final entry in stats.entries) {
    final catId = entry.key;
    final hrs = entry.value;
    final pct = totalHours > 0 ? (hrs / totalHours) * 100 : 0.0;

    if (catId == null) {
      list.add(CategoryStudyTime(
        id: null,
        name: 'General Focus',
        colorValue: 0xFF9E9E9E, // Grey
        hours: hrs,
        percentage: pct,
      ));
    } else {
      final cat = catMap[catId];
      list.add(CategoryStudyTime(
        id: catId,
        name: cat?.name ?? 'Unknown Category',
        colorValue: cat?.color ?? 0xFF00FFCC,
        hours: hrs,
        percentage: pct,
      ));
    }
  }

  // Sort descending by hours
  list.sort((a, b) => b.hours.compareTo(a.hours));
  return AsyncValue.data(list);
});
