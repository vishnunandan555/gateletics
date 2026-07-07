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

// Peak hours provider - matrix[weekday][hour] = total minutes studied
// weekday index: 0=Sun, 1=Mon, ..., 6=Sat  (DateTime.weekday % 7)
// hour index: 0..23
// Each session is split across every clock-hour it spans (Option B: accurate distribution)
final peakHoursProvider = Provider<List<List<double>>>((ref) {
  final sessionsAsync = ref.watch(allFocusSessionsProvider);
  final emptyMatrix = List.generate(7, (_) => List<double>.filled(24, 0.0));

  return sessionsAsync.when(
    data: (sessions) {
      final matrix = List.generate(7, (_) => List<double>.filled(24, 0.0));
      for (final session in sessions) {
        if (session.durationSeconds <= 0) continue;

        int remaining = session.durationSeconds;
        DateTime current = session.startTime;

        while (remaining > 0) {
          final weekday = current.weekday % 7; // 0=Sun, 1=Mon,...,6=Sat
          final hour = current.hour;

          // Seconds left in this clock-hour slot
          final nextHour = DateTime(
              current.year, current.month, current.day, current.hour + 1);
          final secsToNextHour = nextHour.difference(current).inSeconds;

          final counted = remaining < secsToNextHour ? remaining : secsToNextHour;
          matrix[weekday][hour] += counted / 60.0; // store as minutes

          remaining -= counted;
          if (remaining > 0) current = nextHour;
        }
      }
      return matrix;
    },
    loading: () => emptyMatrix,
    error: (e, st) => emptyMatrix,
  );
});
