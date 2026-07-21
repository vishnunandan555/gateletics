import 'package:flutter/material.dart';

class DemoKeys {
  // ─── Bottom Nav Tabs ────────────────────────────────────────────────────
  static final homeTab = GlobalKey(debugLabel: 'homeTab');
  static final statsTab = GlobalKey(debugLabel: 'statsTab');
  static final completionTab = GlobalKey(debugLabel: 'completionTab');
  static final focusTab = GlobalKey(debugLabel: 'focusTab');
  static final settingsTab = GlobalKey(debugLabel: 'settingsTab');

  // ─── Home Screen ────────────────────────────────────────────────────────
  static final homeProgressCard = GlobalKey(debugLabel: 'homeProgressCard');
  static final homeCountdownTimer = GlobalKey(debugLabel: 'homeCountdownTimer');
  static final homeProfileAvatar = GlobalKey(debugLabel: 'homeProfileAvatar');
  static final homeStartButton = GlobalKey(debugLabel: 'homeStartButton');
  static final homeConsistencyGrid = GlobalKey(debugLabel: 'homeConsistencyGrid');
  static final homeNoticeBoardButton = GlobalKey(debugLabel: 'homeNoticeBoardButton');
  static final homeAddTaskContainer = GlobalKey(debugLabel: 'homeAddTaskContainer');
  static final homeAddTaskButton = GlobalKey(debugLabel: 'homeAddTaskButton');

  // ─── Syllabus / Completion Screen ───────────────────────────────────────
  static final completionProgressBar = GlobalKey(debugLabel: 'completionProgressBar');
  static final completionCategoryMenu = GlobalKey(debugLabel: 'completionCategoryMenu');
  static final completionFirstSubjectCard = GlobalKey(debugLabel: 'completionFirstSubjectCard');
  static final completionDaysLeft = GlobalKey(debugLabel: 'completionDaysLeft');
  // Legacy keys (still used)
  static final syllabusCategoryCard = GlobalKey(debugLabel: 'syllabusCategoryCard');
  static final syllabusSearchBar = GlobalKey(debugLabel: 'syllabusSearchBar');

  // ─── Focus Screen ───────────────────────────────────────────────────────
  static final focusTimerSelectors = GlobalKey(debugLabel: 'focusTimerSelectors');
  static final focusStartButton = GlobalKey(debugLabel: 'focusStartButton');
  static final focusDailyGoalBar = GlobalKey(debugLabel: 'focusDailyGoalBar');
  static final activeTimerCircle = GlobalKey(debugLabel: 'activeTimerCircle');
  static final accomplishmentsSaveButton = GlobalKey(debugLabel: 'accomplishmentsSaveButton');

  // ─── Stats / Analytics Screen ────────────────────────────────────────────
  static final statsStreakCard = GlobalKey(debugLabel: 'statsStreakCard');
  static final statsTopButtons = GlobalKey(debugLabel: 'statsTopButtons');
  static final statsProjectionCard = GlobalKey(debugLabel: 'statsProjectionCard');
  static final statsHeatmapCard = GlobalKey(debugLabel: 'statsHeatmapCard');
  static final statsChartCard = GlobalKey(debugLabel: 'statsChartCard');
}

