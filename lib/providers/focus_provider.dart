import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'syllabus_provider.dart';

enum FocusMethod {
  freestyle,
  timer,
  pomodoro,
  extendedPomodoro,
  rule45_15,
  rule52_17,
  ultradian90,
  ultradian120,
}

class FocusMethodDetails {
  final FocusMethod method;
  final String name;
  final int focusMinutes; // -1 for custom, 0 for count up (freestyle)
  final int breakMinutes; // 0 for no breaks
  final String description;
  final String iconPath;

  FocusMethodDetails({
    required this.method,
    required this.name,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.description,
    required this.iconPath,
  });

  bool get isCountUp => focusMinutes == 0;
  bool get isCustom => focusMinutes == -1;
  bool get hasBreaks => breakMinutes > 0;
}

final focusMethodsData = {
  FocusMethod.freestyle: FocusMethodDetails(
    method: FocusMethod.freestyle,
    name: 'Freestyle',
    focusMinutes: 0,
    breakMinutes: 0,
    description: 'Track your work without time limits or interruptions. Perfect for coding, reading, creative work, or whenever you prefer to work at your own pace.',
    iconPath: 'assets/freestyle-skiing.png',
  ),
  FocusMethod.timer: FocusMethodDetails(
    method: FocusMethod.timer,
    name: 'Timer',
    focusMinutes: -1,
    breakMinutes: 0,
    description: 'Set a custom countdown and focus until it ends. Great for timed practice, mock exams, workouts, homework, or one-time sessions.',
    iconPath: 'assets/timer.png',
  ),
  FocusMethod.pomodoro: FocusMethodDetails(
    method: FocusMethod.pomodoro,
    name: 'Pomodoro',
    focusMinutes: 25,
    breakMinutes: 5,
    description: 'Work in short, focused sessions with regular breaks. Ideal for beginners, revision, small tasks, and overcoming procrastination.',
    iconPath: 'assets/pomodoro.png',
  ),
  FocusMethod.extendedPomodoro: FocusMethodDetails(
    method: FocusMethod.extendedPomodoro,
    name: 'Extended Pomodoro',
    focusMinutes: 50,
    breakMinutes: 10,
    description: 'A longer version of Pomodoro with fewer interruptions. Best for assignments, programming, writing, and college study sessions.',
    iconPath: 'assets/ex_pomodoro.png',
  ),
  FocusMethod.rule45_15: FocusMethodDetails(
    method: FocusMethod.rule45_15,
    name: '45/15 Rule',
    focusMinutes: 45,
    breakMinutes: 15,
    description: 'A balanced study cycle with extra recovery time. Well suited for reading textbooks, theory-heavy subjects, and reviewing notes.',
    iconPath: 'assets/45-min.png',
  ),
  FocusMethod.rule52_17: FocusMethodDetails(
    method: FocusMethod.rule52_17,
    name: '52/17 Rule',
    focusMinutes: 52,
    breakMinutes: 17,
    description: 'A productivity-focused schedule that balances sustained concentration with meaningful breaks. Great for research, office work, and mixed workloads.',
    iconPath: 'assets/fifty-two.png',
  ),
  FocusMethod.ultradian90: FocusMethodDetails(
    method: FocusMethod.ultradian90,
    name: 'Ultradian 90',
    focusMinutes: 90,
    breakMinutes: 20,
    description: "Based on the body's natural focus cycles, this method encourages deep, uninterrupted work followed by a recovery break. Ideal for coding, mathematics, GATE preparation, and complex problem solving.",
    iconPath: 'assets/wave.png',
  ),
  FocusMethod.ultradian120: FocusMethodDetails(
    method: FocusMethod.ultradian120,
    name: 'Ultradian 120',
    focusMinutes: 120,
    breakMinutes: 30,
    description: 'An extended ultradian cycle for those who can maintain focus over long periods. Best for intensive study, research, writing, and projects requiring prolonged concentration.',
    iconPath: 'assets/ultradian120.png',
  ),
};

enum FocusStatus {
  idle,
  focusing,
  breakTime,
  paused,
}

class FocusSessionState {
  final FocusStatus status;
  final FocusMethod selectedMethod;
  final int customTimerMinutes;
  final int elapsedSeconds; // Current interval elapsed seconds
  final int totalSecondsFocused; // Total seconds focused in this session
  final int completedFocusIntervals;
  final Set<int> initialCompletedTaskIds;
  final Map<int, int> initialSubjectCompletedVideos;
  final List<String> sessionAccomplishments;
  final DateTime? sessionStartTime;
  final bool isBreakActive;

  FocusSessionState({
    required this.status,
    required this.selectedMethod,
    required this.customTimerMinutes,
    required this.elapsedSeconds,
    required this.totalSecondsFocused,
    required this.completedFocusIntervals,
    required this.initialCompletedTaskIds,
    required this.initialSubjectCompletedVideos,
    required this.sessionAccomplishments,
    required this.isBreakActive,
    this.sessionStartTime,
  });

  FocusSessionState copyWith({
    FocusStatus? status,
    FocusMethod? selectedMethod,
    int? customTimerMinutes,
    int? elapsedSeconds,
    int? totalSecondsFocused,
    int? completedFocusIntervals,
    Set<int>? initialCompletedTaskIds,
    Map<int, int>? initialSubjectCompletedVideos,
    List<String>? sessionAccomplishments,
    DateTime? sessionStartTime,
    bool? isBreakActive,
  }) {
    return FocusSessionState(
      status: status ?? this.status,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      customTimerMinutes: customTimerMinutes ?? this.customTimerMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalSecondsFocused: totalSecondsFocused ?? this.totalSecondsFocused,
      completedFocusIntervals: completedFocusIntervals ?? this.completedFocusIntervals,
      initialCompletedTaskIds: initialCompletedTaskIds ?? this.initialCompletedTaskIds,
      initialSubjectCompletedVideos: initialSubjectCompletedVideos ?? this.initialSubjectCompletedVideos,
      sessionAccomplishments: sessionAccomplishments ?? this.sessionAccomplishments,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      isBreakActive: isBreakActive ?? this.isBreakActive,
    );
  }

  factory FocusSessionState.initial() {
    return FocusSessionState(
      status: FocusStatus.idle,
      selectedMethod: FocusMethod.freestyle,
      customTimerMinutes: 30,
      elapsedSeconds: 0,
      totalSecondsFocused: 0,
      completedFocusIntervals: 0,
      initialCompletedTaskIds: const {},
      initialSubjectCompletedVideos: const {},
      sessionAccomplishments: const [],
      sessionStartTime: null,
      isBreakActive: false,
    );
  }

  FocusMethodDetails get details => focusMethodsData[selectedMethod]!;

  int get currentTargetSeconds {
    if (isBreakActive) {
      return details.breakMinutes * 60;
    }
    if (details.isCountUp) return 0;
    if (details.isCustom) return customTimerMinutes * 60;
    return details.focusMinutes * 60;
  }
}

class FocusStateNotifier extends Notifier<FocusSessionState> {
  Timer? _timer;
  DateTime? _lastTickTime;
  int _accumulatedMilliseconds = 0;

  @override
  FocusSessionState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    _loadSelection();
    return FocusSessionState.initial();
  }

  Future<void> _loadSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final methodIndex = prefs.getInt('focus_selected_method_index');
      final customMins = prefs.getInt('focus_custom_timer_minutes');
      FocusMethod? method;
      if (methodIndex != null && methodIndex >= 0 && methodIndex < FocusMethod.values.length) {
        method = FocusMethod.values[methodIndex];
      }
      if (state.status == FocusStatus.idle) {
        state = state.copyWith(
          selectedMethod: method ?? state.selectedMethod,
          customTimerMinutes: customMins ?? state.customTimerMinutes,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('focus_selected_method_index', state.selectedMethod.index);
      await prefs.setInt('focus_custom_timer_minutes', state.customTimerMinutes);
    } catch (_) {}
  }

  void selectMethod(FocusMethod method) {
    if (state.status != FocusStatus.idle) return;
    state = state.copyWith(selectedMethod: method, elapsedSeconds: 0);
    _saveSelection();
  }

  void setCustomTimerMinutes(int minutes) {
    if (state.status != FocusStatus.idle) return;
    state = state.copyWith(customTimerMinutes: minutes);
    _saveSelection();
  }

  void resetState() {
    _timer?.cancel();
    _accumulatedMilliseconds = 0;
    state = FocusSessionState.initial();
  }

  Future<void> startSession() async {
    if (state.status != FocusStatus.idle) return;

    final db = ref.read(appDatabaseProvider);
    final startTime = DateTime.now();

    // Capture initial snapshots for accomplishments comparison
    final initialCompletedTaskIds = <int>{};

    try {
      final tasks = await db.select(db.syllabusTasks).get();
      for (final t in tasks) {
        if (t.isCompleted) {
          initialCompletedTaskIds.add(t.id);
        }
      }
    } catch (_) {}

    // Removed resource tracking completion checks

    state = state.copyWith(
      status: FocusStatus.focusing,
      elapsedSeconds: 0,
      totalSecondsFocused: 0,
      completedFocusIntervals: 0,
      sessionStartTime: startTime,
      initialCompletedTaskIds: initialCompletedTaskIds,
      initialSubjectCompletedVideos: const {},
      sessionAccomplishments: [],
      isBreakActive: false,
    );

    _lastTickTime = DateTime.now();
    _accumulatedMilliseconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pauseSession() {
    if (state.status != FocusStatus.focusing && state.status != FocusStatus.breakTime) return;
    _timer?.cancel();
    state = state.copyWith(status: FocusStatus.paused);
  }

  void resumeSession() {
    if (state.status != FocusStatus.paused) return;
    state = state.copyWith(
      status: state.isBreakActive ? FocusStatus.breakTime : FocusStatus.focusing,
    );
    _lastTickTime = DateTime.now();
    _accumulatedMilliseconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> checkAccomplishments() async {
    if (state.status == FocusStatus.idle) return;

    final db = ref.read(appDatabaseProvider);
    final accomplishments = <String>[];

    // Check syllabus task achievements
    try {
      final tasks = await db.select(db.syllabusTasks).get();
      final topics = await db.select(db.syllabusTopics).get();
      final cats = await db.select(db.syllabusCategories).get();

      final categoryMap = {for (final c in cats) c.id: c.name};
      final topicMap = {for (final t in topics) t.id: t};

      final newCompletedTasksByTopic = <int, List<String>>{};

      for (final t in tasks) {
        if (t.isCompleted && !state.initialCompletedTaskIds.contains(t.id)) {
          newCompletedTasksByTopic.putIfAbsent(t.topicId, () => []).add(t.name);
        }
      }

      if (newCompletedTasksByTopic.isNotEmpty) {
        accomplishments.add("Completed:");
        for (final topicId in newCompletedTasksByTopic.keys) {
          final topic = topicMap[topicId];
          if (topic != null) {
            final catName = categoryMap[topic.categoryId] ?? "Syllabus";
            accomplishments.add("  $catName > ${topic.name}:");
            for (final taskName in newCompletedTasksByTopic[topicId]!) {
              accomplishments.add("    - $taskName");
            }
          }
        }
      }
    } catch (_) {}

    // Removed resource achievements check

    state = state.copyWith(sessionAccomplishments: accomplishments);
  }

  Future<FocusSession> stopSession() async {
    _timer?.cancel();
    final db = ref.read(appDatabaseProvider);

    await checkAccomplishments();

    final finalAccomplishments = state.sessionAccomplishments.join('\n');

    double progressDelta = 0.0;
    try {
      final tasks = await db.select(db.syllabusTasks).get();
      final totalTasks = tasks.length;
      if (totalTasks > 0) {
        final initialCount = state.initialCompletedTaskIds.length;
        final currentCount = tasks.where((t) => t.isCompleted).length;
        progressDelta = ((currentCount - initialCount) / totalTasks) * 100.0;
      }
    } catch (_) {}
    if (progressDelta < 0.0) progressDelta = 0.0;

    final completedEntry = FocusSessionsCompanion.insert(
      method: state.details.name,
      startTime: state.sessionStartTime ?? DateTime.now(),
      durationSeconds: state.totalSecondsFocused,
      accomplishments: Value(finalAccomplishments.isNotEmpty ? finalAccomplishments : null),
      progressDelta: Value(progressDelta),
    );

    int insertedId = -1;
    try {
      insertedId = await db.addFocusSession(completedEntry);
    } catch (_) {}

    final finalSession = FocusSession(
      id: insertedId,
      method: state.details.name,
      startTime: state.sessionStartTime ?? DateTime.now(),
      durationSeconds: state.totalSecondsFocused,
      accomplishments: finalAccomplishments.isNotEmpty ? finalAccomplishments : null,
      progressDelta: progressDelta,
    );

    // Refresh history provider by invalidating or updates
    ref.invalidate(todayFocusSessionsProvider);
    ref.invalidate(todayFocusDurationProvider);

    final prevMethod = state.selectedMethod;
    final prevCustomMins = state.customTimerMinutes;

    state = FocusSessionState.initial().copyWith(
      selectedMethod: prevMethod,
      customTimerMinutes: prevCustomMins,
    );
    return finalSession;
  }

  void _tick() {
    final now = DateTime.now();
    int diffMs = _lastTickTime != null ? now.difference(_lastTickTime!).inMilliseconds : 1000;
    _lastTickTime = now;

    // Normalize jitter: if the tick is roughly around 1s, count it as exactly 1s
    // to prevent the timer display from skipping/double-ticking on scheduling jitter.
    if (diffMs >= 800 && diffMs <= 1500) {
      diffMs = 1000;
    }

    _accumulatedMilliseconds += diffMs;
    final tickDelta = _accumulatedMilliseconds ~/ 1000;
    if (tickDelta <= 0) return;
    _accumulatedMilliseconds %= 1000;

    if (state.status == FocusStatus.focusing) {
      final target = state.currentTargetSeconds;
      final isFreestyle = state.details.isCountUp;

      int nextElapsed = state.elapsedSeconds + tickDelta;
      int nextTotalFocused = state.totalSecondsFocused + tickDelta;

      if (!isFreestyle && nextElapsed >= target) {
        // Interval completed!
        _timer?.cancel();
        state = state.copyWith(
          elapsedSeconds: target,
          totalSecondsFocused: nextTotalFocused,
          completedFocusIntervals: state.completedFocusIntervals + 1,
        );
        
        checkAccomplishments().then((_) {
          if (state.details.hasBreaks) {
            // Trigger break
            state = state.copyWith(
              status: FocusStatus.breakTime,
              elapsedSeconds: 0,
              isBreakActive: true,
            );
            _lastTickTime = DateTime.now();
            _accumulatedMilliseconds = 0;
            _timer?.cancel();
            _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
          } else {
            // Timer without break -> automatically finishes session
            stopSession();
          }
        });
      } else {
        state = state.copyWith(
          elapsedSeconds: nextElapsed,
          totalSecondsFocused: nextTotalFocused,
        );
        // Refresh accomplishments periodically during active session
        if (nextElapsed % 5 == 0) {
          checkAccomplishments();
        }
      }
    } else if (state.status == FocusStatus.breakTime) {
      final target = state.currentTargetSeconds;
      int nextElapsed = state.elapsedSeconds + tickDelta;

      if (nextElapsed >= target) {
        // Break ended, start next focus
        _timer?.cancel();
        state = state.copyWith(
          status: FocusStatus.focusing,
          elapsedSeconds: 0,
          isBreakActive: false,
        );
        _lastTickTime = DateTime.now();
        _accumulatedMilliseconds = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      } else {
        state = state.copyWith(elapsedSeconds: nextElapsed);
      }
    }
  }
}

final focusProvider = NotifierProvider<FocusStateNotifier, FocusSessionState>(() {
  return FocusStateNotifier();
});

// SharedPreferences backing for Daily Goal (in minutes)
class DailyFocusGoalNotifier extends Notifier<int> {
  @override
  int build() {
    _load();
    return 240; // Default: 4 hours (240 mins)
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final mins = prefs.getInt('daily_focus_goal_mins');
    if (mins != null) {
      state = mins;
    }
  }

  Future<void> setGoalMinutes(int mins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_focus_goal_mins', mins);
    state = mins;
  }
}

final dailyFocusGoalProvider = NotifierProvider<DailyFocusGoalNotifier, int>(() {
  return DailyFocusGoalNotifier();
});

// Streams and fetching for today's sessions
final todayFocusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTodayFocusSessions();
});

final todayFocusDurationProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTodayFocusDurationSeconds();
});

// Smart quotes engine loading from JSON file
class FocusQuotesState {
  final List<String> focusQuotes;
  final List<String> breakQuotes;

  FocusQuotesState({required this.focusQuotes, required this.breakQuotes});

  factory FocusQuotesState.fallback() {
    return FocusQuotesState(
      focusQuotes: [
        "Consistency is what transforms average into excellence.",
        "Your focus determines your reality.",
        "Do not stop when you are tired. Stop when you are done.",
        "Great things are done by a series of small things brought together.",
        "Hey {user_name}, stay in the zone! Focus determines your reality.",
        "Believe you can and you're halfway there."
      ],
      breakQuotes: [
        "Take a deep breath and relax. You've earned this break!",
        "Step away from the screen, stretch, and grab some water.",
        "Disconnect for a moment. Recharge and return stronger."
      ],
    );
  }
}

final focusQuotesProvider = FutureProvider<FocusQuotesState>((ref) async {
  try {
    final jsonStr = await rootBundle.loadString('focus_quotes.json');
    final Map<String, dynamic> data = json.decode(jsonStr);
    return FocusQuotesState(
      focusQuotes: List<String>.from(data['focus'] ?? []),
      breakQuotes: List<String>.from(data['break'] ?? []),
    );
  } catch (e) {
    return FocusQuotesState.fallback();
  }
});

// Helper provider to select and format a quote based on session status
final formattedQuoteProvider = Provider.family<String, String?>((ref, rawUserName) {
  final quotesStateAsync = ref.watch(focusQuotesProvider);
  final sessionState = ref.watch(focusProvider);

  return quotesStateAsync.when(
    data: (quotesState) {
      final isBreak = sessionState.status == FocusStatus.breakTime;
      final quotesList = isBreak ? quotesState.breakQuotes : quotesState.focusQuotes;
      if (quotesList.isEmpty) return "Keep going!";

      // Use a consistent quote based on session start time so it doesn't jitter every second
      final seed = sessionState.sessionStartTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
      final random = Random(seed + (isBreak ? 999 : 0));
      final rawQuote = quotesList[random.nextInt(quotesList.length)];

      final elapsedMin = (sessionState.totalSecondsFocused / 60).floor();
      final targetSecs = sessionState.currentTargetSeconds;
      final remainingMin = max(0, ((targetSecs - sessionState.elapsedSeconds) / 60).ceil());

      // Accomplishment summary
      final tasksCount = sessionState.sessionAccomplishments.where((line) => line.startsWith("    -")).length;

      final userName = rawUserName ?? "Champ";

      return rawQuote
          .replaceAll("{user_name}", userName)
          .replaceAll("{elapsed_minutes}", elapsedMin.toString())
          .replaceAll("{remaining_minutes}", remainingMin.toString())
          .replaceAll("{tasks_completed}", tasksCount.toString());
    },
    loading: () => "Focusing...",
    error: (e, _) => "Consistency is key.",
  );
});

/// Pure function that computes the accomplishments delta given:
/// - initial vs current completed task IDs (with names)
/// - initial vs current subject completed video counts
/// Returns a list of human-readable accomplishment strings.
List<String> calculateAccomplishmentsDelta({
  required Set<int> initialCompletedTaskIds,
  required Set<int> currentCompletedTaskIds,
  required Map<int, String> taskNames,
  required Map<int, int> initialSubjectVideos,
  required Map<int, int> currentSubjectVideos,
  required Map<int, String> subjectNames,
  required Map<int, int> subjectTotalVideos,
}) {
  final result = <String>[];

  // New tasks completed since session started
  final newTaskIds = currentCompletedTaskIds.difference(initialCompletedTaskIds);
  for (final id in newTaskIds) {
    final name = taskNames[id] ?? 'Unknown task';
    result.add('Completed task: $name');
  }

  // Video progress increments
  for (final entry in currentSubjectVideos.entries) {
    final subjectId = entry.key;
    final current = entry.value;
    final initial = initialSubjectVideos[subjectId] ?? 0;
    final total = subjectTotalVideos[subjectId] ?? 0;
    if (current > initial && total > 0) {
      final delta = current - initial;
      final deltaPercent = (delta / total) * 100;
      final name = subjectNames[subjectId] ?? 'Subject';
      result.add('$name: +${deltaPercent.toStringAsFixed(1)}% progress ($current/$total videos)');
    }
  }

  return result;
}
