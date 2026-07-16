import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import 'syllabus_provider.dart';
import 'focus_provider.dart';
import 'completion_provider.dart';
import 'rollover_provider.dart';

// Stream of historical snapshots
final dailyHistoryProvider = StreamProvider<List<DailyHistoryData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchDailyHistory();
});

// A manager provider that listens to active day changes and keeps dailyHistory table up-to-date
final dailyHistoryManagerProvider = Provider<void>((ref) {
  final db = ref.read(appDatabaseProvider);

  // Watch inputs
  final todayDurationAsync = ref.watch(todayFocusDurationProvider);
  final completionAsync = ref.watch(completionPercentageProvider);
  final dailyGoalMins = ref.watch(dailyFocusGoalProvider);
  final rollover = ref.watch(studyDayRolloverProvider);

  todayDurationAsync.whenData((totalFocusSeconds) {
    completionAsync.whenData((completionPct) {
      final now = DateTime.now();
      final date = studyDayFor(now, rollover);
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // Run asynchronously outside provider evaluation
      Future.microtask(() async {
        try {
          await db.upsertDailyHistory(
            dateStr: dateStr,
            totalFocusSeconds: totalFocusSeconds,
            targetGoalSeconds: dailyGoalMins * 60,
            isGoalCompleted: totalFocusSeconds >= (dailyGoalMins * 60),
            syllabusProgressPct: completionPct,
          );
          await db.deleteOldFocusSessions(rollover: rollover);
        } catch (e) {
          debugPrint("Failed to upsert daily history: $e");
        }
      });
    });
  });
});

final longestStreakProvider = Provider<int>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);
  return historyAsync.when(
    data: (historyList) {
      if (historyList.isEmpty) return 0;
      
      int longest = 0;
      int current = 0;
      DateTime? prevDate;

      // Ensure the history list is sorted by dateStr ascending
      final sortedHistory = List<DailyHistoryData>.from(historyList)
        ..sort((a, b) => a.dateStr.compareTo(b.dateStr));

      for (final h in sortedHistory) {
        if (!h.isGoalCompleted) {
          current = 0;
          prevDate = null;
          continue;
        }

        final date = DateTime.tryParse(h.dateStr);
        if (date == null) continue;
        
        if (prevDate == null) {
          current = 1;
        } else {
          final diff = date.difference(prevDate).inDays;
          if (diff == 1) {
            current++;
          } else if (diff > 1) {
            current = 1;
          }
        }
        if (current > longest) {
          longest = current;
        }
        prevDate = date;
      }
      return longest;
    },
    loading: () => 0,
    error: (e, st) => 0,
  );
});

// Current streak dynamically walked back starting from today
final currentStreakProvider = Provider<int>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);
  final rollover = ref.watch(studyDayRolloverProvider);

  return historyAsync.when(
    data: (historyList) {
      if (historyList.isEmpty) return 0;

      // Collect all dates where daily goal was met
      final completedDates = historyList
          .where((e) => e.isGoalCompleted)
          .map((e) => e.dateStr)
          .toSet();

      if (completedDates.isEmpty) return 0;

      final today = studyDayFor(DateTime.now(), rollover);
      int streak = 0;
      DateTime checkDate = today;

      while (true) {
        final checkDateStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
        
        if (completedDates.contains(checkDateStr)) {
          streak++;
          checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
        } else {
          // If checkDate is today, we check if they finished yesterday instead of breaking immediately
          if (checkDate == today) {
            checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
            continue;
          }
          break;
        }
      }

      return streak;
    },
    loading: () => 0,
    error: (err, stack) => 0,
  );
});


// Projected syllabus completion date based on rolling daily progress velocity
final projectedCompletionProvider = Provider<Map<String, dynamic>?>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);

  return historyAsync.when(
    data: (history) {
      if (history.isEmpty) return null;

      final sortedHistory = List<DailyHistoryData>.from(history)
        ..sort((a, b) => a.dateStr.compareTo(b.dateStr));

      final currentProgress = sortedHistory.last.syllabusProgressPct;
      if (currentProgress >= 100.0) {
        return {'completed': true, 'currentProgress': currentProgress};
      }

      final firstRecord = sortedHistory.first;
      final earliestDate = DateTime.tryParse(firstRecord.dateStr);
      if (earliestDate == null) return null;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final daysSinceStart = today.difference(earliestDate).inDays + 1;
      final n = daysSinceStart < 1 ? 1 : (daysSinceStart > 7 ? 7 : daysSinceStart);

      // Create a map of dateStr -> progress for fast lookup
      final progressMap = <String, double>{};
      for (final h in sortedHistory) {
        progressMap[h.dateStr] = h.syllabusProgressPct;
      }

      // Helper to retrieve progress for a given calendar day
      double getProgressForDate(DateTime date) {
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        if (progressMap.containsKey(dateStr)) {
          return progressMap[dateStr]!;
        }
        double lastProgress = 0.0;
        for (final h in sortedHistory) {
          final recDate = DateTime.tryParse(h.dateStr);
          if (recDate != null && recDate.isBefore(date)) {
            lastProgress = h.syllabusProgressPct;
          }
        }
        return lastProgress;
      }

      // Calculate daily deltas for the last N calendar days
      final deltas = <double>[];
      for (int i = 0; i < n; i++) {
        final day = today.subtract(Duration(days: n - 1 - i));
        final progressThisDay = getProgressForDate(day);
        final progressPrevDay = getProgressForDate(day.subtract(const Duration(days: 1)));
        double delta = progressThisDay - progressPrevDay;
        if (delta < 0) delta = 0.0; // clamp resets/drops
        deltas.add(delta);
      }

      if (deltas.isEmpty) return null;

      final avgDailyGain = deltas.reduce((a, b) => a + b) / n;
      if (avgDailyGain <= 0) return null;

      final daysRemaining = ((100.0 - currentProgress) / avgDailyGain).ceil();
      final projectedDate = today.add(Duration(days: daysRemaining));

      final String confidence;
      if (n >= 7) {
        confidence = 'high';
      } else if (n >= 3) {
        confidence = 'medium';
      } else {
        confidence = 'low';
      }

      return {
        'completed': false,
        'currentProgress': currentProgress,
        'daysRemaining': daysRemaining,
        'projectedDate': projectedDate,
        'avgDailyGain': avgDailyGain,
        'confidence': confidence,
      };
    },
    loading: () => null,
    error: (e, st) => null,
  );
});

// Check-in goal minutes notifier (5, 10, 15 (default), 20, 30, 45)
class CheckInGoalMinutesNotifier extends Notifier<int> {
  @override
  int build() {
    _load();
    return 15; // Default check-in goal is 15 minutes
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getInt('check_in_goal_minutes');
      if (val != null) {
        state = val;
      }
    } catch (_) {}
  }

  Future<void> setMinutes(int val) async {
    state = val;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('check_in_goal_minutes', val);
    } catch (_) {}
  }
}

final checkInGoalMinutesProvider = NotifierProvider<CheckInGoalMinutesNotifier, int>(() {
  return CheckInGoalMinutesNotifier();
});

// Current check-in streak dynamically calculated based on check-in target
final checkInStreakProvider = Provider<int>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  final checkInMins = ref.watch(checkInGoalMinutesProvider);
  final checkInSeconds = checkInMins * 60;

  return historyAsync.when(
    data: (historyList) {
      if (historyList.isEmpty) return 0;

      // Collect all dates where total focus seconds met the check-in goal
      final completedDates = historyList
          .where((e) => e.totalFocusSeconds >= checkInSeconds)
          .map((e) => e.dateStr)
          .toSet();

      if (completedDates.isEmpty) return 0;

      final today = studyDayFor(DateTime.now(), rollover);
      int streak = 0;
      DateTime checkDate = today;

      while (true) {
        final checkDateStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
        
        if (completedDates.contains(checkDateStr)) {
          streak++;
          checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
        } else {
          // If checkDate is today, we check if they finished yesterday instead of breaking immediately
          if (checkDate == today) {
            checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
            continue;
          }
          break;
        }
      }

      return streak;
    },
    loading: () => 0,
    error: (err, stack) => 0,
  );
});
