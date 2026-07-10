import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/daily_history_provider.dart';
import '../../providers/show_projected_completion_provider.dart';
import '../../providers/disable_graph_glow_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../utils/ui_scaling.dart';
import '../../database/app_database.dart';
import '../../providers/auth_provider.dart';

class ProgressHistoryScreen extends ConsumerStatefulWidget {
  const ProgressHistoryScreen({super.key});

  @override
  ConsumerState<ProgressHistoryScreen> createState() => _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends ConsumerState<ProgressHistoryScreen>
    with TickerProviderStateMixin {
  bool _isHeatmapMode = false;
  DateTime _selectedMonth = DateTime.now();
  String _timeframe = 'Weekly'; // 'Weekly' | 'Monthly' | 'Yearly'
  int _heatmapYear = DateTime.now().year;
  int? _selectedChartIndex;
  late DateTime _selectedWeekStart;
  late int _selectedYear;

  late AnimationController _chartAnimController;
  late AnimationController _chartDataAnimController;
  late AnimationController _calendarDataAnimController;
  late Animation<double> _streakHeaderAnim;
  late Animation<double> _calendarHeatmapAnim;
  late Animation<double> _projectedCompletionAnim;
  late Animation<double> _chartCardAnim;
  late Animation<double> _donutChartAnim;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedWeekStart = now.subtract(Duration(days: now.weekday % 7));
    _selectedYear = now.year;
    _loadPersistedSettings();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _chartDataAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _calendarDataAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    
    _streakHeaderAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _calendarHeatmapAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic),
    );
    _projectedCompletionAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
    );
    _chartCardAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
    );
    _donutChartAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    );
    _chartAnimController.forward();
    _chartDataAnimController.forward();
    _calendarDataAnimController.forward();
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isHeatmapMode = prefs.getBool('stats_is_heatmap_mode') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _persistHeatmapMode(bool mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stats_is_heatmap_mode', mode);
    } catch (_) {}
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    _chartDataAnimController.dispose();
    _calendarDataAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(overallProgressColorProvider);
    final history = ref.watch(dailyHistoryProvider).value ?? [];
    final currentStreak = ref.watch(currentStreakProvider);
    final checkInStreak = ref.watch(checkInStreakProvider);
    final todayFocusSeconds = ref.watch(todayFocusDurationProvider).value ?? 0;
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);
    final categoriesAsync = ref.watch(syllabusCategoriesProvider);
    final topicsAsync = ref.watch(syllabusTopicsProvider);
    final tasksAsync = ref.watch(syllabusTasksProvider);
    final projection = ref.watch(projectedCompletionProvider);
    final showProjComp = ref.watch(showProjectedCompletionProvider);
    final accountCreationDateAsync = ref.watch(accountCreationDateProvider);
    final accountCreationDate = accountCreationDateAsync.value ?? DateTime.now();

    final todayGoalSeconds = dailyGoalMinutes * 60;
    final todayProgressPct = todayGoalSeconds == 0 ? 0.0 : (todayFocusSeconds.toDouble() / todayGoalSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Statistics',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: context.s(18),
            letterSpacing: context.s(1.5),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.s(12), vertical: context.s(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // New Streak & Completion Header
              _buildAnimatedEntrance(
                animation: _streakHeaderAnim,
                child: _buildTopStreakHeader(context, currentStreak, checkInStreak, todayProgressPct, accentColor),
              ),
              SizedBox(height: context.s(16)),

              // Calendar / Heatmap Toggle Selector
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: _buildSlidingToggle(accentColor),
                ),
              ),
              SizedBox(height: context.s(14)),

              _buildAnimatedEntrance(
                animation: _calendarHeatmapAnim,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isHeatmapMode
                      ? KeyedSubtree(
                          key: ValueKey('heatmap_$_heatmapYear'),
                          child: _buildHeatmapContainer(context, history, accentColor, accountCreationDate),
                        )
                      : KeyedSubtree(
                          key: ValueKey('calendar_${_selectedMonth.year}_${_selectedMonth.month}'),
                          child: _buildCalendarContainer(context, history, dailyGoalMinutes, accentColor, accountCreationDate),
                        ),
                ),
              ),

              // Projected Completion Card, if enabled in settings
              if (showProjComp) ...[
                SizedBox(height: context.s(16)),
                _buildAnimatedEntrance(
                  animation: _projectedCompletionAnim,
                  child: _buildProjectedCompletionCard(context, projection, accentColor),
                ),
              ],

              SizedBox(height: context.s(16)),

              // Graph Segment Bar & Graph Summary Card
              _buildAnimatedEntrance(
                animation: _chartCardAnim,
                child: Column(
                  children: [
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.9,
                        child: _buildTimeframeSelector(accentColor),
                      ),
                    ),
                    SizedBox(height: context.s(12)),
                    _buildGraphCard(context, history, dailyGoalMinutes, accentColor, accountCreationDate),
                  ],
                ),
              ),
              SizedBox(height: context.s(16)),

              // Pie Chart - Syllabus Category Study Breakdown
              Builder(
                builder: (context) {
                  if (tasksAsync.hasError || topicsAsync.hasError || categoriesAsync.hasError) return const SizedBox();
                  if (!tasksAsync.hasValue || !topicsAsync.hasValue || !categoriesAsync.hasValue) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final filteredList = getFilteredCategoriesStudy(
                    tasksAsync.value!,
                    topicsAsync.value!,
                    categoriesAsync.value!,
                  );
                  return _buildAnimatedEntrance(
                    animation: _donutChartAnim,
                    child: _buildPieChartCard(context, filteredList, accentColor),
                  );
                },
              ),

              SizedBox(height: context.s(20)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Construction ---

  Widget _buildAnimatedEntrance({required Widget child, required Animation<double> animation}) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 15),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSlidingToggle(Color accentColor) {
    return Container(
      height: context.s(36),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(context.s(18)),
      ),
      padding: EdgeInsets.all(context.s(4)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _isHeatmapMode ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(context.s(14)),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isHeatmapMode) {
                      setState(() => _isHeatmapMode = false);
                      _persistHeatmapMode(false);
                      _calendarDataAnimController.forward(from: 0.0);
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      'Calendar',
                      style: GoogleFonts.outfit(
                        color: !_isHeatmapMode ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: context.s(12),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isHeatmapMode) {
                      setState(() => _isHeatmapMode = true);
                      _persistHeatmapMode(true);
                      _calendarDataAnimController.forward(from: 0.0);
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      'Heatmap',
                      style: GoogleFonts.outfit(
                        color: _isHeatmapMode ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: context.s(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContainer(BuildContext context, List<DailyHistoryData> history, int dailyGoalMinutes, Color accentColor, DateTime accountCreationDate) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final Map<String, DailyHistoryData> historyMap = {for (final h in history) h.dateStr: h};

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final canGoLeft = _selectedMonth.year > accountCreationDate.year ||
        (_selectedMonth.year == accountCreationDate.year && _selectedMonth.month > accountCreationDate.month);

    final now = DateTime.now();
    final canGoRight = _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);

    return Container(
      padding: EdgeInsets.only(top: 0, left: context.s(12), right: context.s(12), bottom: context.s(8)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(12)),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: canGoLeft ? Colors.white.withAlpha(12) : Colors.white.withAlpha(4),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.all(context.s(4)),
                ),
                constraints: BoxConstraints.tightFor(width: context.s(28), height: context.s(28)),
                icon: Icon(Icons.chevron_left_rounded, color: canGoLeft ? accentColor : Colors.white24, size: context.s(18)),
                onPressed: canGoLeft ? () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                  _calendarDataAnimController.forward(from: 0.0);
                } : null,
              ),
              Text(
                '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.s(14.5),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: canGoRight ? Colors.white.withAlpha(12) : Colors.white.withAlpha(4),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.all(context.s(4)),
                ),
                constraints: BoxConstraints.tightFor(width: context.s(28), height: context.s(28)),
                icon: Icon(Icons.chevron_right_rounded, color: canGoRight ? accentColor : Colors.white24, size: context.s(18)),
                onPressed: canGoRight ? () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  });
                  _calendarDataAnimController.forward(from: 0.0);
                } : null,
              ),
            ],
          ),
          SizedBox(height: context.s(6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: context.s(36),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontWeight: FontWeight.bold,
                    fontSize: context.s(11),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: context.s(4)),
          Builder(
            builder: (context) {
              const rowsNeeded = 6;
              const gridItemCount = rowsNeeded * 7;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gridItemCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: context.s(4),
                  crossAxisSpacing: context.s(4),
                  mainAxisExtent: context.s(38),
                ),
                itemBuilder: (ctx, index) {
                  final dayNum = index - startWeekday + 1;
                  if (dayNum <= 0 || dayNum > daysInMonth) {
                    return const SizedBox();
                  }

                  final cellDate = DateTime(_selectedMonth.year, _selectedMonth.month, dayNum);
                  final dateStr = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
                  final record = historyMap[dateStr];

                  final focusSeconds = record?.totalFocusSeconds ?? 0;
                  final goalSeconds = (record?.targetGoalSeconds ?? (dailyGoalMinutes * 60));
                  final progress = goalSeconds == 0 ? 0.0 : min(1.0, focusSeconds / goalSeconds);

                  final isToday = cellDate.year == DateTime.now().year &&
                      cellDate.month == DateTime.now().month &&
                      cellDate.day == DateTime.now().day;

                  return Center(
                    child: Tooltip(
                      message: _getTooltipMessage(dateStr, record, dailyGoalMinutes),
                      triggerMode: TooltipTriggerMode.tap,
                      preferBelow: false,
                      textStyle: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: context.s(11),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(context.s(6)),
                      ),
                      child: SizedBox(
                        width: context.s(36),
                        height: context.s(36),
                        child: AnimatedBuilder(
                          animation: _calendarDataAnimController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: CalendarCellRingPainter(
                                progress: progress * _calendarDataAnimController.value,
                                color: accentColor,
                                strokeWidth: context.s(2.5),
                              ),
                              child: child,
                            );
                          },
                          child: Center(
                            child: Container(
                              width: context.s(24),
                              height: context.s(24),
                              decoration: BoxDecoration(
                                color: isToday ? accentColor.withAlpha(45) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$dayNum',
                                style: GoogleFonts.outfit(
                                  color: (isToday && progress < 1.0) ? accentColor : (progress > 0 ? Colors.white : Colors.white38),
                                  fontWeight: isToday || progress > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: context.s(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapContainer(BuildContext context, List<DailyHistoryData> history, Color accentColor, DateTime accountCreationDate) {
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);
    final Map<String, DailyHistoryData> historyMap = {for (final h in history) h.dateStr: h};

    final minYear = accountCreationDate.year;
    // Clamp chosen year between min year and current year
    final currentYear = DateTime.now().year;
    final activeYear = _heatmapYear.clamp(minYear, currentYear);

    // Displays months chronologically (January up to current month for the current year; all 12 months for past years)
    final monthsToShow = List.generate(
      activeYear == DateTime.now().year ? DateTime.now().month : 12,
      (i) => DateTime(activeYear, i + 1, 1),
    );

    final weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final double maxFocusSeconds = history.isEmpty
        ? 1.0
        : history.map((e) => e.totalFocusSeconds.toDouble()).reduce(max);
    final maxVal = maxFocusSeconds > 0 ? maxFocusSeconds : 1.0;

    final canGoLeft = activeYear > minYear;
    final canGoRight = activeYear < currentYear;

    return Container(
      padding: EdgeInsets.only(top: 0, left: context.s(12), right: context.s(12), bottom: context.s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.s(12), vertical: context.s(6)),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(context.s(8)),
                  border: Border.all(
                    color: Colors.white.withAlpha(8),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$activeYear',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: context.s(14),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: canGoLeft ? Colors.white.withAlpha(12) : Colors.white.withAlpha(4),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(context.s(4)),
                    ),
                    constraints: BoxConstraints.tightFor(width: context.s(28), height: context.s(28)),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: canGoLeft ? accentColor : Colors.white24,
                      size: context.s(18),
                    ),
                    onPressed: canGoLeft ? () {
                      setState(() {
                        _heatmapYear = activeYear - 1;
                      });
                      _calendarDataAnimController.forward(from: 0.0);
                    } : null,
                  ),
                  SizedBox(width: context.s(6)),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: canGoRight ? Colors.white.withAlpha(12) : Colors.white.withAlpha(4),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(context.s(4)),
                    ),
                    constraints: BoxConstraints.tightFor(width: context.s(28), height: context.s(28)),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: canGoRight ? accentColor : Colors.white24,
                      size: context.s(18),
                    ),
                    onPressed: canGoRight ? () {
                      setState(() {
                        _heatmapYear = activeYear + 1;
                      });
                      _calendarDataAnimController.forward(from: 0.0);
                    } : null,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.s(10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIXED Weekday Labels (Locked on the left side)
              Padding(
                padding: EdgeInsets.only(top: context.s(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weekdayNames.map((name) {
                    return SizedBox(
                      height: context.s(18),
                      child: Center(
                        child: Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: context.s(9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(width: context.s(8)),
              // SCROLLABLE Heatmap columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: monthsToShow.map((mDateTime) {
                      final daysInMonth = DateTime(mDateTime.year, mDateTime.month + 1, 0).day;
                      final firstWeekday = DateTime(mDateTime.year, mDateTime.month, 1).weekday; // 1 = Mon, ..., 7 = Sun
                      final startOffset = firstWeekday % 7; // Sunday = 0, Monday = 1, ...

                      final List<List<int?>> weekColumns = [];
                      List<int?> currentWeek = List.filled(7, null);

                      int weekdayIndex = startOffset;
                      for (int day = 1; day <= daysInMonth; day++) {
                        currentWeek[weekdayIndex] = day;
                        if (weekdayIndex == 6 || day == daysInMonth) {
                          weekColumns.add(currentWeek);
                          currentWeek = List.filled(7, null);
                          weekdayIndex = 0;
                        } else {
                          weekdayIndex++;
                        }
                      }

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.s(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              monthNamesShort[mDateTime.month - 1],
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: context.s(10),
                              ),
                            ),
                            SizedBox(height: context.s(8)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: weekColumns.map((week) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: context.s(1.5)),
                                  child: Column(
                                    children: week.map((dayNum) {
                                      if (dayNum == null) {
                                        return Container(
                                          width: context.s(15),
                                          height: context.s(15),
                                          margin: EdgeInsets.symmetric(vertical: context.s(1.5)),
                                          decoration: const BoxDecoration(
                                            color: Colors.transparent,
                                          ),
                                        );
                                      }

                                      final isToday = mDateTime.year == DateTime.now().year &&
                                          mDateTime.month == DateTime.now().month &&
                                          dayNum == DateTime.now().day;

                                      final isFuture = mDateTime.year == DateTime.now().year &&
                                          mDateTime.month == DateTime.now().month &&
                                          dayNum > DateTime.now().day;

                                      final dateStr = "${mDateTime.year}-${mDateTime.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}";
                                      final record = historyMap[dateStr];
                                      final focusSeconds = (record?.totalFocusSeconds ?? 0).toDouble();
                                      final ratio = focusSeconds / maxVal;

                                      Color blockColor = isFuture
                                          ? Colors.white.withAlpha(3)
                                          : Colors.white.withAlpha(8);

                                      if (focusSeconds > 0.0 && !isToday) {
                                        if (ratio <= 0.25) {
                                          blockColor = accentColor.withAlpha(60);
                                        } else if (ratio <= 0.5) {
                                          blockColor = accentColor.withAlpha(120);
                                        } else if (ratio <= 0.75) {
                                          blockColor = accentColor.withAlpha(180);
                                        } else {
                                          blockColor = accentColor;
                                        }
                                      }

                                      return Tooltip(
                                        message: _getTooltipMessage(dateStr, record, dailyGoalMinutes),
                                        triggerMode: TooltipTriggerMode.tap,
                                        preferBelow: false,
                                        textStyle: GoogleFonts.outfit(
                                          color: Colors.black,
                                          fontSize: context.s(11),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          borderRadius: BorderRadius.circular(context.s(6)),
                                        ),
                                        child: AnimatedBuilder(
                                          animation: _calendarDataAnimController,
                                          builder: (context, _) {
                                            final val = _calendarDataAnimController.value;
                                            return Opacity(
                                              opacity: val,
                                              child: Transform.scale(
                                                scale: 0.6 + 0.4 * val,
                                                child: Container(
                                                  width: context.s(15),
                                                  height: context.s(15),
                                                  margin: EdgeInsets.symmetric(vertical: context.s(1.5)),
                                                  decoration: BoxDecoration(
                                                    color: blockColor,
                                                    borderRadius: BorderRadius.circular(context.s(3.5)),
                                                    border: isToday
                                                        ? Border.all(
                                                            color: accentColor,
                                                            width: 1.4,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(Color accentColor) {
    Alignment alignment = Alignment.center;
    if (_timeframe == 'Weekly') {
      alignment = Alignment.centerLeft;
    } else if (_timeframe == 'Yearly') {
      alignment = Alignment.centerRight;
    }

    return Container(
      height: context.s(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(8)),
        border: Border.all(color: Colors.white.withAlpha(6)),
      ),
      padding: EdgeInsets.all(context.s(2)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: alignment,
            child: FractionallySizedBox(
              widthFactor: 0.33,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(context.s(6)),
                ),
              ),
            ),
          ),
          Row(
            children: ['Weekly', 'Monthly', 'Yearly'].map((time) {
              final isSel = _timeframe == time;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _timeframe = time;
                      _selectedChartIndex = null;
                    });
                    _chartDataAnimController.forward(from: 0.0);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      time,
                      style: GoogleFonts.outfit(
                        color: isSel ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: context.s(11),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphCard(BuildContext context, List<DailyHistoryData> history, int dailyGoalMinutes, Color accentColor, DateTime accountCreationDate) {
    final disableGlow = ref.watch(disableGraphGlowProvider);
    double totalHours = 0.0;
    List<double> dataPoints = [];
    List<String> labels = [];

    // Comparison calculation variables
    double pctChange = 0.0;
    bool isUp = true;
    double currentSum = 0.0;
    double previousSum = 0.0;

    if (_timeframe == 'Weekly') {
      // Comparison: This Calendar Week vs Last Calendar Week
      currentSum = 0.0;
      previousSum = 0.0;
      final startOfWeek = _selectedWeekStart;
      final prevStartOfWeek = startOfWeek.subtract(const Duration(days: 7));

      for (int i = 0; i < 7; i++) {
        final dCurr = startOfWeek.add(Duration(days: i));
        final dateStrCurr = "${dCurr.year}-${dCurr.month.toString().padLeft(2, '0')}-${dCurr.day.toString().padLeft(2, '0')}";
        final recordCurr = history.firstWhere((h) => h.dateStr == dateStrCurr, orElse: () => DailyHistoryData(dateStr: dateStrCurr, totalFocusSeconds: 0, targetGoalSeconds: dailyGoalMinutes * 60, isGoalCompleted: false, syllabusProgressPct: 0));
        currentSum += recordCurr.totalFocusSeconds;

        final dPrev = prevStartOfWeek.add(Duration(days: i));
        final dateStrPrev = "${dPrev.year}-${dPrev.month.toString().padLeft(2, '0')}-${dPrev.day.toString().padLeft(2, '0')}";
        final recordPrev = history.firstWhere((h) => h.dateStr == dateStrPrev, orElse: () => DailyHistoryData(dateStr: dateStrPrev, totalFocusSeconds: 0, targetGoalSeconds: dailyGoalMinutes * 60, isGoalCompleted: false, syllabusProgressPct: 0));
        previousSum += recordPrev.totalFocusSeconds;
      }

      if (previousSum > 0) {
        pctChange = ((currentSum - previousSum) / previousSum) * 100;
      } else {
        pctChange = currentSum > 0 ? 100.0 : 0.0;
      }
      isUp = pctChange >= 0;

      // Chart values
      labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      for (int i = 0; i < 7; i++) {
        final d = startOfWeek.add(Duration(days: i));
        final dateStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        final record = history.firstWhere((h) => h.dateStr == dateStr, orElse: () => DailyHistoryData(dateStr: dateStr, totalFocusSeconds: 0, targetGoalSeconds: dailyGoalMinutes * 60, isGoalCompleted: false, syllabusProgressPct: 0));
        final hrs = record.totalFocusSeconds / 3600.0;
        dataPoints.add(hrs);
        totalHours += hrs;
      }
    } else if (_timeframe == 'Monthly') {
      // Comparison: This Calendar Month vs Last Calendar Month
      currentSum = 0.0;
      previousSum = 0.0;
      for (final h in history) {
        final d = DateTime.tryParse(h.dateStr);
        if (d != null) {
          if (d.year == _selectedMonth.year && d.month == _selectedMonth.month) {
            currentSum += h.totalFocusSeconds;
          } else {
            final prevMonth = _selectedMonth.month == 1
                ? DateTime(_selectedMonth.year - 1, 12)
                : DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            if (d.year == prevMonth.year && d.month == prevMonth.month) {
              previousSum += h.totalFocusSeconds;
            }
          }
        }
      }
      if (previousSum > 0) {
        pctChange = ((currentSum - previousSum) / previousSum) * 100;
      } else {
        pctChange = currentSum > 0 ? 100.0 : 0.0;
      }
      isUp = pctChange >= 0;

      // Chart values: Day 1 to Day N of the selected calendar month
      final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
      labels = List.generate(daysInMonth, (i) => "${i + 1}");
      for (int d = 1; d <= daysInMonth; d++) {
        final dateStr = "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
        final record = history.firstWhere((h) => h.dateStr == dateStr, orElse: () => DailyHistoryData(dateStr: dateStr, totalFocusSeconds: 0, targetGoalSeconds: dailyGoalMinutes * 60, isGoalCompleted: false, syllabusProgressPct: 0));
        final hrs = record.totalFocusSeconds / 3600.0;
        dataPoints.add(hrs);
        totalHours += hrs;
      }
    } else {
      // Comparison: This Year vs Last Year
      currentSum = 0.0;
      previousSum = 0.0;
      for (final h in history) {
        final d = DateTime.tryParse(h.dateStr);
        if (d != null) {
          if (d.year == _selectedYear) {
            currentSum += h.totalFocusSeconds;
          } else if (d.year == _selectedYear - 1) {
            previousSum += h.totalFocusSeconds;
          }
        }
      }
      if (previousSum > 0) {
        pctChange = ((currentSum - previousSum) / previousSum) * 100;
      } else {
        pctChange = currentSum > 0 ? 100.0 : 0.0;
      }
      isUp = pctChange >= 0;

      // Chart values: Jan to Dec
      labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (int m = 1; m <= 12; m++) {
        final monthPrefix = "$_selectedYear-${m.toString().padLeft(2, '0')}";
        final monthSumSeconds = history
            .where((h) => h.dateStr.startsWith(monthPrefix))
            .fold(0, (sum, h) => sum + h.totalFocusSeconds);
        final hrs = monthSumSeconds / 3600.0;
        dataPoints.add(hrs);
        totalHours += hrs;
      }
    }

    final List<String> tooltipLabels = [];
    if (_timeframe == 'Weekly') {
      for (int i = 0; i < 7; i++) {
        final d = _selectedWeekStart.add(Duration(days: i));
        final dd = d.day.toString().padLeft(2, '0');
        final mm = d.month.toString().padLeft(2, '0');
        final yy = (d.year % 100).toString().padLeft(2, '0');
        tooltipLabels.add("$dd/$mm/$yy\n${dataPoints[i].toStringAsFixed(1)} hrs");
      }
    } else if (_timeframe == 'Monthly') {
      for (int i = 0; i < dataPoints.length; i++) {
        final d = i + 1;
        final dd = d.toString().padLeft(2, '0');
        final mm = _selectedMonth.month.toString().padLeft(2, '0');
        final yy = (_selectedMonth.year % 100).toString().padLeft(2, '0');
        tooltipLabels.add("$dd/$mm/$yy\n${dataPoints[i].toStringAsFixed(1)} hrs");
      }
    } else {
      for (int i = 0; i < 12; i++) {
        final mm = (i + 1).toString().padLeft(2, '0');
        final yy = (_selectedYear % 100).toString().padLeft(2, '0');
        tooltipLabels.add("$mm/$yy\n${dataPoints[i].toStringAsFixed(1)} hrs");
      }
    }

    final dailyGoalHours = dailyGoalMinutes / 60.0;
    // For yearly comparison, the goal line represents monthly goal
    final referenceGoal = _timeframe == 'Yearly' ? (dailyGoalHours * 30.4) : dailyGoalHours;

    final hasData = dataPoints.any((v) => v > 0);

    return Container(
      padding: EdgeInsets.all(context.s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _chartDataAnimController,
            builder: (context, _) {
              final val = _chartDataAnimController.value;
              final animatedHours = totalHours * val;
              final animatedPctChange = pctChange * val;
              final timeframeNoun = _timeframe.toLowerCase() == 'weekly'
                  ? 'week'
                  : (_timeframe.toLowerCase() == 'monthly' ? 'month' : 'year');

              final showOnlyUpArrow = previousSum == 0 && currentSum > 0;
              final showNeutralZero = previousSum == 0 && currentSum == 0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${animatedHours.toStringAsFixed(1).replaceAll('.0', '')} hrs',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: context.s(20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.s(2)),
                      Text(
                        'total this $timeframeNoun',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: context.s(11),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showNeutralZero)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: context.s(8), vertical: context.s(4)),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(context.s(6)),
                          ),
                          child: Text(
                            "0%",
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: context.s(11),
                            ),
                          ),
                        )
                      else if (showOnlyUpArrow)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: context.s(8), vertical: context.s(4)),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withAlpha(20),
                            borderRadius: BorderRadius.circular(context.s(6)),
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.greenAccent,
                            size: context.s(12),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: context.s(8), vertical: context.s(4)),
                          decoration: BoxDecoration(
                            color: isUp ? Colors.greenAccent.withAlpha(20) : Colors.redAccent.withAlpha(20),
                            borderRadius: BorderRadius.circular(context.s(6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: isUp ? Colors.greenAccent : Colors.redAccent,
                                size: context.s(12),
                              ),
                              SizedBox(width: context.s(4)),
                              Text(
                                "${animatedPctChange.abs().toStringAsFixed(0)}%",
                                style: GoogleFonts.outfit(
                                  color: isUp ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.s(11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: context.s(4)),
                      Text(
                        "vs last $timeframeNoun",
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: context.s(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          SizedBox(height: context.s(16)),
          // Custom scaled line/bar chart
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;
              return GestureDetector(
                onTapDown: (details) {
                  final colWidth = chartWidth / dataPoints.length;
                  final index = (details.localPosition.dx / colWidth).floor().clamp(0, dataPoints.length - 1);
                  setState(() {
                    if (_selectedChartIndex == index) {
                      _selectedChartIndex = null;
                    } else {
                      _selectedChartIndex = index;
                    }
                  });
                },
                child: AnimatedBuilder(
                  animation: _chartDataAnimController,
                  builder: (context, _) {
                    return SizedBox(
                      height: context.s(120),
                      child: hasData
                          ? CustomPaint(
                              painter: WaveAreaChartPainter(
                                data: dataPoints,
                                goalValue: referenceGoal,
                                accentColor: accentColor,
                                selectedIndex: _selectedChartIndex,
                                tooltipLabels: tooltipLabels,
                                animValue: _chartDataAnimController.value,
                                showGoalLine: _timeframe != 'Yearly',
                                sharpLines: false,
                                disableGlow: disableGlow,
                              ),
                            )
                          : Center(
                              child: Text(
                                'No data found',
                                style: GoogleFonts.outfit(
                                  color: Colors.white30,
                                  fontSize: context.s(13),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              );
            },
          ),
          SizedBox(height: context.s(8)),
          // Chart labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(labels.length, (index) {
              final label = labels[index];
              final dayNum = index + 1;
              final showLabel = _timeframe != 'Monthly' || (dayNum == 1 || dayNum % 5 == 0 || dayNum == labels.length);
              final displayLabel = showLabel ? label : '';
              return Expanded(
                child: Text(
                  displayLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontSize: context.s(_timeframe == 'Monthly' ? 8.5 : 10),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: context.s(14)),
          // Bottom Pagination Info / Left-Right Controls
          _buildGraphPaginationRow(accentColor, accountCreationDate),
        ],
      ),
    );
  }

  // --- Graph Pagination / SWIPE Helper Methods ---

  String _getWeekInfoString(DateTime weekStart) {
    int sundayCount = 0;
    DateTime temp = DateTime(weekStart.year, weekStart.month, 1);
    while (temp.isBefore(weekStart) || temp.isAtSameMomentAs(weekStart)) {
      if (temp.weekday == DateTime.sunday) {
        sundayCount++;
      }
      temp = temp.add(const Duration(days: 1));
    }

    final monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = monthNamesShort[weekStart.month - 1];

    return "Week $sundayCount | $monthName | ${weekStart.year}";
  }

  bool _canGoToNextWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    final currentWeekClean = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    final selectedWeekClean = DateTime(_selectedWeekStart.year, _selectedWeekStart.month, _selectedWeekStart.day);
    return selectedWeekClean.isBefore(currentWeekClean);
  }

  bool _canGoToNextMonth() {
    final now = DateTime.now();
    return _selectedMonth.year < now.year || (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  bool _canGoToNextYear() {
    final now = DateTime.now();
    return _selectedYear < now.year;
  }

  bool _canGoToPreviousWeek(DateTime accountCreationDate) {
    final prevWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    final creationWeekStart = accountCreationDate.subtract(Duration(days: accountCreationDate.weekday % 7));
    final prevWeekClean = DateTime(prevWeekStart.year, prevWeekStart.month, prevWeekStart.day);
    final creationWeekClean = DateTime(creationWeekStart.year, creationWeekStart.month, creationWeekStart.day);
    return prevWeekClean.isAtSameMomentAs(creationWeekClean) || prevWeekClean.isAfter(creationWeekClean);
  }

  bool _canGoToPreviousMonth(DateTime accountCreationDate) {
    final prevMonth = _selectedMonth.month == 1
        ? DateTime(_selectedMonth.year - 1, 12)
        : DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    return prevMonth.year > accountCreationDate.year ||
        (prevMonth.year == accountCreationDate.year && prevMonth.month >= accountCreationDate.month);
  }

  bool _canGoToPreviousYear(DateTime accountCreationDate) {
    final prevYear = _selectedYear - 1;
    return prevYear >= accountCreationDate.year;
  }

  void _goToPrevSet(DateTime accountCreationDate) {
    if (_timeframe == 'Weekly') {
      if (_canGoToPreviousWeek(accountCreationDate)) {
        setState(() {
          _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
          _selectedChartIndex = null;
        });
        _chartDataAnimController.forward(from: 0.0);
      }
    } else if (_timeframe == 'Monthly') {
      if (_canGoToPreviousMonth(accountCreationDate)) {
        setState(() {
          _selectedMonth = _selectedMonth.month == 1
              ? DateTime(_selectedMonth.year - 1, 12)
              : DateTime(_selectedMonth.year, _selectedMonth.month - 1);
          _selectedChartIndex = null;
        });
        _chartDataAnimController.forward(from: 0.0);
      }
    } else {
      if (_canGoToPreviousYear(accountCreationDate)) {
        setState(() {
          _selectedYear--;
          _selectedChartIndex = null;
        });
        _chartDataAnimController.forward(from: 0.0);
      }
    }
  }

  void _goToNextSet() {
    if (_timeframe == 'Weekly') {
      if (_canGoToNextWeek()) {
        setState(() {
          _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
          _selectedChartIndex = null;
        });
        _chartDataAnimController.forward(from: 0.0);
      }
    } else if (_timeframe == 'Monthly') {
      if (_canGoToNextMonth()) {
        setState(() {
          _selectedMonth = _selectedMonth.month == 12
              ? DateTime(_selectedMonth.year + 1, 1)
              : DateTime(_selectedMonth.year, _selectedMonth.month + 1);
          _selectedChartIndex = null;
        });
        _chartDataAnimController.forward(from: 0.0);
      }
    } else {
      if (_canGoToNextYear()) {
        setState(() {
          _selectedYear++;
          _selectedChartIndex = null;
        });
        _chartDataAnimController.forward(from: 0.0);
      }
    }
  }

  void _resetToCurrentPeriod() {
    final now = DateTime.now();
    setState(() {
      _selectedWeekStart = now.subtract(Duration(days: now.weekday % 7));
      _selectedMonth = DateTime(now.year, now.month);
      _selectedYear = now.year;
      _selectedChartIndex = null;
    });
    _chartDataAnimController.forward(from: 0.0);
  }

  Widget _buildGraphPaginationRow(Color accentColor, DateTime accountCreationDate) {
    final now = DateTime.now();
    String infoText = '';
    bool isNotCurrent = false;
    bool canGoPrev = false;
    bool canGoNext = false;

    if (_timeframe == 'Weekly') {
      infoText = _getWeekInfoString(_selectedWeekStart);
      final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
      final currentWeekClean = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
      final selectedWeekClean = DateTime(_selectedWeekStart.year, _selectedWeekStart.month, _selectedWeekStart.day);
      isNotCurrent = !selectedWeekClean.isAtSameMomentAs(currentWeekClean);
      canGoPrev = _canGoToPreviousWeek(accountCreationDate);
      canGoNext = _canGoToNextWeek();
    } else if (_timeframe == 'Monthly') {
      final monthNamesLong = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      infoText = "${monthNamesLong[_selectedMonth.month - 1]} | ${_selectedMonth.year}";
      isNotCurrent = _selectedMonth.year != now.year || _selectedMonth.month != now.month;
      canGoPrev = _canGoToPreviousMonth(accountCreationDate);
      canGoNext = _canGoToNextMonth();
    } else {
      infoText = "$_selectedYear";
      isNotCurrent = _selectedYear != now.year;
      canGoPrev = _canGoToPreviousYear(accountCreationDate);
      canGoNext = _canGoToNextYear();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: canGoPrev ? () => _goToPrevSet(accountCreationDate) : null,
          child: Container(
            width: context.s(32),
            height: context.s(32),
            decoration: BoxDecoration(
              color: canGoPrev ? Colors.white.withAlpha(12) : Colors.white.withAlpha(4),
              shape: BoxShape.circle,
              border: Border.all(
                color: canGoPrev ? Colors.white.withAlpha(8) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: context.s(20),
              color: canGoPrev ? accentColor : Colors.white24,
            ),
          ),
        ),
        SizedBox(width: context.s(12)),
        GestureDetector(
          onLongPress: () => _showPeriodSelectionDialog(context, history),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(6)),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(context.s(8)),
              border: Border.all(color: Colors.white.withAlpha(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  infoText,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: context.s(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isNotCurrent) ...[
                  SizedBox(width: context.s(8)),
                  GestureDetector(
                    onTap: _resetToCurrentPeriod,
                    child: Icon(
                      Icons.restore_rounded,
                      color: accentColor,
                      size: context.s(14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: context.s(12)),
        GestureDetector(
          onTap: canGoNext ? _goToNextSet : null,
          child: Container(
            width: context.s(32),
            height: context.s(32),
            decoration: BoxDecoration(
              color: canGoNext ? Colors.white.withAlpha(12) : Colors.white.withAlpha(4),
              shape: BoxShape.circle,
              border: Border.all(
                color: canGoNext ? Colors.white.withAlpha(8) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: context.s(20),
              color: canGoNext ? accentColor : Colors.white24,
            ),
          ),
        ),
      ],
    );
  }

  void _showPeriodSelectionDialog(BuildContext context, List<DailyHistoryData> history) {
    final now = DateTime.now();
    final years = <int>{now.year};
    for (final h in history) {
      if (h.totalFocusSeconds > 0) {
        final d = DateTime.tryParse(h.dateStr);
        if (d != null) {
          years.add(d.year);
        }
      }
    }
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));

    int selectedY = _timeframe == 'Yearly' ? _selectedYear : (_timeframe == 'Monthly' ? _selectedMonth.year : _selectedWeekStart.year);
    int selectedM = _timeframe == 'Yearly' ? 1 : (_timeframe == 'Monthly' ? _selectedMonth.month : _selectedWeekStart.month);

    int selectedW = 1;
    if (_timeframe == 'Weekly') {
      final info = _getWeekInfoString(_selectedWeekStart);
      final match = RegExp(r'Week (\d+)').firstMatch(info);
      if (match != null) {
        selectedW = int.parse(match.group(1)!);
      }
    }

    final accentColor = ref.read(overallProgressColorProvider);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131316),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.s(16)),
                side: BorderSide(color: Colors.white.withAlpha(8)),
              ),
              title: Text(
                'Jump to Period',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.s(14),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Year:', style: TextStyle(color: Colors.white70, fontSize: context.s(12))),
                      DropdownButton<int>(
                        value: selectedY,
                        dropdownColor: const Color(0xFF1E1E22),
                        style: TextStyle(color: Colors.white, fontSize: context.s(12)),
                        onChanged: (y) {
                          if (y != null) {
                            setDialogState(() {
                              selectedY = y;
                            });
                          }
                        },
                        items: sortedYears.map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text('$y'),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  if (_timeframe != 'Yearly') ...[
                    SizedBox(height: context.s(8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Month:', style: TextStyle(color: Colors.white70, fontSize: context.s(12))),
                        DropdownButton<int>(
                          value: selectedM,
                          dropdownColor: const Color(0xFF1E1E22),
                          style: TextStyle(color: Colors.white, fontSize: context.s(12)),
                          onChanged: (m) {
                            if (m != null) {
                              setDialogState(() {
                                selectedM = m;
                              });
                            }
                          },
                          items: List.generate(12, (i) => i + 1).map((m) {
                            final monthNames = [
                              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                            ];
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text(monthNames[m - 1]),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                  if (_timeframe == 'Weekly') ...[
                    SizedBox(height: context.s(8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Week:', style: TextStyle(color: Colors.white70, fontSize: context.s(12))),
                        DropdownButton<int>(
                          value: selectedW,
                          dropdownColor: const Color(0xFF1E1E22),
                          style: TextStyle(color: Colors.white, fontSize: context.s(12)),
                          onChanged: (w) {
                            if (w != null) {
                              setDialogState(() {
                                selectedW = w;
                              });
                            }
                          },
                          items: List.generate(5, (i) => i + 1).map((w) {
                            return DropdownMenuItem<int>(
                              value: w,
                              child: Text('Week $w'),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.white30, fontSize: context.s(12))),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                TextButton(
                  child: Text('Go', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: context.s(12))),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _applySelectedPeriod(selectedY, selectedM, selectedW);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applySelectedPeriod(int year, int month, int week) {
    setState(() {
      if (_timeframe == 'Weekly') {
        _selectedWeekStart = _getSundayForWeek(year, month, week);
        final now = DateTime.now();
        final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
        final currentWeekClean = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
        final selectedWeekClean = DateTime(_selectedWeekStart.year, _selectedWeekStart.month, _selectedWeekStart.day);
        if (selectedWeekClean.isAfter(currentWeekClean)) {
          _selectedWeekStart = currentWeekStart;
        }
      } else if (_timeframe == 'Monthly') {
        _selectedMonth = DateTime(year, month);
        final now = DateTime.now();
        if (_selectedMonth.year > now.year || (_selectedMonth.year == now.year && _selectedMonth.month > now.month)) {
          _selectedMonth = DateTime(now.year, now.month);
        }
      } else {
        _selectedYear = year;
        final now = DateTime.now();
        if (_selectedYear > now.year) {
          _selectedYear = now.year;
        }
      }
      _selectedChartIndex = null;
    });
    _chartDataAnimController.forward(from: 0.0);
  }

  DateTime _getSundayForWeek(int year, int month, int weekNum) {
    DateTime temp = DateTime(year, month, 1);
    while (temp.weekday != DateTime.sunday) {
      temp = temp.add(const Duration(days: 1));
    }
    final targetSunday = temp.add(Duration(days: (weekNum - 1) * 7));
    if (targetSunday.month != month) {
      DateTime lastDay = DateTime(year, month + 1, 0);
      while (lastDay.weekday != DateTime.sunday) {
        lastDay = lastDay.subtract(const Duration(days: 1));
      }
      return lastDay;
    }
    return targetSunday;
  }

  Widget _buildTopStreakHeader(
    BuildContext context,
    int dailyGoalStreak,
    int checkInStreak,
    double progressPct,
    Color accentColor,
  ) {
    return AnimatedBuilder(
      animation: _streakHeaderAnim,
      builder: (context, _) {
        final animVal = _streakHeaderAnim.value;
        final animatedGoalStreak = (dailyGoalStreak * animVal).round();
        final animatedCheckInStreak = (checkInStreak * animVal).round();
        final animatedProgressPct = progressPct * animVal;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.s(4)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStreakHeaderCard(
                  context,
                  'Daily Goal Streak',
                  animatedGoalStreak,
                  SvgPicture.asset(
                    'assets/fire.svg',
                    width: context.s(22),
                    height: context.s(22),
                  ),
                  accentColor,
                ),
              ),
              SizedBox(width: context.s(8)),
              Expanded(
                child: _buildStreakHeaderCard(
                  context,
                  'Daily Check-in Streak',
                  animatedCheckInStreak,
                  Icon(
                    Icons.check_circle_rounded,
                    color: accentColor,
                    size: context.s(22),
                  ),
                  accentColor,
                ),
              ),
              SizedBox(width: context.s(8)),
              Expanded(
                child: _buildProgressHeaderCard(
                  context,
                  'Daily Goal Completion',
                  animatedProgressPct,
                  accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakHeaderCard(
    BuildContext context,
    String label,
    int count,
    Widget iconWidget,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: context.s(11),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.s(6)),
        Container(
          height: context.s(54),
          decoration: BoxDecoration(
            color: const Color(0xFF131316),
            borderRadius: BorderRadius.circular(context.s(12)),
            border: Border.all(color: accentColor.withAlpha(50), width: 1.2),
          ),
          padding: EdgeInsets.symmetric(horizontal: context.s(6)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              SizedBox(width: context.s(6)),
              Text(
                '$count ',
                style: GoogleFonts.orbitron(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: context.s(16),
                ),
              ),
              Text(
                'DAYS',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: context.s(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeaderCard(
    BuildContext context,
    String label,
    double progressPct,
    Color accentColor,
  ) {
    final pctString = '${(progressPct * 100).toStringAsFixed(0)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: context.s(11),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.s(6)),
        Container(
          height: context.s(54),
          decoration: BoxDecoration(
            color: const Color(0xFF131316),
            borderRadius: BorderRadius.circular(context.s(12)),
            border: Border.all(color: accentColor.withAlpha(50), width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.s(11)),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progressPct.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(200),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    pctString,
                    style: GoogleFonts.orbitron(
                      color: progressPct > 0.5 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: context.s(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<CategoryStudyTime> getFilteredCategoriesStudy(
    List<SyllabusTask> tasks,
    List<SyllabusTopic> topics,
    List<SyllabusCategory> categories,
  ) {
    final Map<int, int> completedTaskCounts = {};
    int totalCompletedInPeriod = 0;

    // Determine date range for filtering
    DateTime startDate;
    DateTime endDate;

    if (_timeframe == 'Weekly') {
      startDate = _selectedWeekStart;
      endDate = _selectedWeekStart.add(const Duration(days: 7));
    } else if (_timeframe == 'Monthly') {
      startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    } else {
      startDate = DateTime(_selectedYear, 1, 1);
      endDate = DateTime(_selectedYear + 1, 1, 1);
    }

    final topicMap = {for (final t in topics) t.id: t.categoryId};

    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        if (task.completedAt!.compareTo(startDate) >= 0 && task.completedAt!.isBefore(endDate)) {
          final catId = topicMap[task.topicId];
          if (catId != null) {
            completedTaskCounts[catId] = (completedTaskCounts[catId] ?? 0) + 1;
            totalCompletedInPeriod++;
          }
        }
      }
    }

    final List<CategoryStudyTime> list = [];
    final Map<int, SyllabusCategory> catMap = {for (final c in categories) c.id: c};

    for (final entry in completedTaskCounts.entries) {
      final catId = entry.key;
      final count = entry.value;
      final pct = totalCompletedInPeriod > 0 ? (count / totalCompletedInPeriod) * 100 : 0.0;

      final cat = catMap[catId];
      list.add(CategoryStudyTime(
        id: catId,
        name: cat?.name ?? 'Unknown Category',
        colorValue: cat?.color ?? 0xFF00FFCC,
        hours: count.toDouble(),
        percentage: pct,
      ));
    }

    list.sort((a, b) => b.hours.compareTo(a.hours));
    return list;
  }

  Widget _buildPieChartCard(BuildContext context, List<CategoryStudyTime> categoriesStudy, Color accentColor) {
    if (categoriesStudy.isEmpty) {
      return Container(
        padding: EdgeInsets.all(context.s(12)),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(context.s(16)),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FOCUS AREA DISTRIBUTION',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: context.s(11),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: context.s(20)),
            Center(
              child: Text(
                'Complete syllabus tasks during your focus sessions to build your distribution chart.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: context.s(12),
                ),
              ),
            ),
            SizedBox(height: context.s(10)),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(context.s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'FOCUS AREA DISTRIBUTION',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: context.s(11),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: context.s(14)),
          Row(
            children: [
              SizedBox(
                width: context.s(90),
                height: context.s(90),
                child: AnimatedBuilder(
                  animation: _chartDataAnimController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: PieChartPainter(
                        sections: categoriesStudy,
                        animValue: _chartDataAnimController.value,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: context.s(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categoriesStudy.take(4).map((c) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: context.s(3)),
                      child: Row(
                        children: [
                          Container(
                            width: context.s(8),
                            height: context.s(8),
                            decoration: BoxDecoration(
                              color: Color(c.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: context.s(6)),
                          Expanded(
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: context.s(11),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: context.s(6)),
                          Text(
                            '${c.percentage.toStringAsFixed(0)}%',
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: context.s(11),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ----------------------------------------------------------------
  // Projected Completion Card
  // ----------------------------------------------------------------

  Widget _buildProjectedCompletionCard(
    BuildContext context,
    Map<String, dynamic>? projection,
    Color accentColor,
  ) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Container(
      padding: EdgeInsets.all(context.s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: accentColor.withAlpha(40)),
      ),
      child: projection == null
          ? Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: Colors.white24, size: context.s(22)),
                SizedBox(width: context.s(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected Completion',
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: context.s(12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.s(2)),
                      Text(
                        'Study for a few more days to unlock your completion forecast',
                        style: GoogleFonts.outfit(
                          color: Colors.white30,
                          fontSize: context.s(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : projection['completed'] == true
              ? Row(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: context.s(24))),
                    SizedBox(width: context.s(10)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Syllabus Complete!',
                          style: GoogleFonts.orbitron(
                            color: accentColor,
                            fontSize: context.s(15),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '100% done — incredible work!',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: context.s(11),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : _buildProjectionDetails(
                  context, projection, accentColor, monthNames),
    );
  }

  Widget _buildProjectionDetails(
    BuildContext context,
    Map<String, dynamic> projection,
    Color accentColor,
    List<String> monthNames,
  ) {
    final projectedDate = projection['projectedDate'] as DateTime;
    final daysRemaining = projection['daysRemaining'] as int;
    final currentProgress = projection['currentProgress'] as double;
    final avgDailyGain = projection['avgDailyGain'] as double;
    final confidence = projection['confidence'] as String;

    final confidenceColor = confidence == 'high'
        ? Colors.greenAccent
        : confidence == 'medium'
            ? Colors.amberAccent
            : Colors.orangeAccent;
    final confidenceLabel = confidence == 'high'
        ? 'High confidence'
        : confidence == 'medium'
            ? 'Medium confidence'
            : 'Early estimate';
    final dateStr =
        '${projectedDate.day} ${monthNames[projectedDate.month - 1]} ${projectedDate.year}';

    return AnimatedBuilder(
      animation: _projectedCompletionAnim,
      builder: (context, _) {
        final val = _projectedCompletionAnim.value;
        final animatedDays = (daysRemaining * val).round();
        final animatedProgress = currentProgress * val;
        final animatedAvgDailyGain = avgDailyGain * val;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Projected Completion',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: context.s(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.s(6), vertical: context.s(2)),
                  decoration: BoxDecoration(
                    color: confidenceColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(context.s(4)),
                  ),
                  child: Text(
                    confidenceLabel,
                    style: GoogleFonts.outfit(
                      color: confidenceColor,
                      fontSize: context.s(9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.s(8)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.flag_rounded, color: accentColor, size: context.s(18)),
                SizedBox(width: context.s(6)),
                Opacity(
                  opacity: val,
                  child: Text(
                    dateStr,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: context.s(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.s(10)),
            Row(
              children: [
                _projStat(context, '$animatedDays', 'days left', accentColor),
                SizedBox(width: context.s(20)),
                _projStat(context, '${animatedProgress.toStringAsFixed(1)}%', 'done now',
                    Colors.white70),
                SizedBox(width: context.s(20)),
                _projStat(context, '+${animatedAvgDailyGain.toStringAsFixed(2)}%', 'per day avg',
                    Colors.white70),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _projStat(BuildContext context, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: context.s(12),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white30,
            fontSize: context.s(9),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------


  String _getTooltipMessage(String dateStr, DailyHistoryData? record, int dailyGoalMinutes) {
    String dateLabel = dateStr;
    try {
      final parsed = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateLabel = "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
    } catch (_) {}

    if (record == null || record.totalFocusSeconds == 0) {
      return "$dateLabel\nNo focus sessions recorded";
    }

    final mins = (record.totalFocusSeconds / 60).floor();
    final hrs = mins / 60.0;
    final hrsStr = hrs.toStringAsFixed(1).replaceAll('.0', '');

    final goalMins = (record.targetGoalSeconds / 60).floor();
    final pct = goalMins == 0 ? 0 : ((mins / goalMins) * 100).round();

    if (mins >= goalMins) {
      return "$dateLabel\nFocused for $hrsStr hrs and\nDaily Goal Reached ($pct%)";
    } else {
      return "$dateLabel\nFocused for $hrsStr hrs and\nDaily Goal Not Reached ($pct%)";
    }
  }
}

// --- Custom Painters ---

class CalendarCellRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CalendarCellRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0.0) return;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WaveAreaChartPainter extends CustomPainter {
  final List<double> data;
  final double goalValue;
  final Color accentColor;
  final int? selectedIndex;
  final List<String> tooltipLabels;
  final double animValue;
  final bool showGoalLine;
  final bool sharpLines;
  final bool disableGlow;

  WaveAreaChartPainter({
    required this.data,
    required this.goalValue,
    required this.accentColor,
    this.selectedIndex,
    this.tooltipLabels = const [],
    this.animValue = 1.0,
    this.showGoalLine = true,
    this.sharpLines = false,
    this.disableGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;

    // Clip for left-to-right animation reveal
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width * animValue.clamp(0.0, 1.0), height));

    final colWidth = width / data.length;

    // Max Y scales adaptively: if a point exceeds daily goal, scale to fit the peak. Otherwise, scale to 100% goal.
    final maxData = data.reduce(max);
    final maxY = maxData > goalValue ? (maxData * 1.15) : (goalValue > 0.0 ? goalValue : 1.0);

    final usableHeight = height - 20;

    // Points are centered inside each column chunk (aligning perfectly with centered labels)
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i + 0.5) * colWidth;
      final y = height - (data[i] / (maxY > 0 ? maxY : 1.0)) * usableHeight - 10;
      points.add(Offset(x, y));
    }

    // Draw reference Daily Goal dashed line (sits below chart lines)
    if (showGoalLine) {
      final yGoal = height - (goalValue / (maxY > 0 ? maxY : 1.0)) * usableHeight - 10;

      final goalPaint = Paint()
        ..color = Colors.white.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      double dashWidth = 6.0;
      double dashSpace = 4.0;
      double startX = 0.0;
      while (startX < width) {
        final endX = min(startX + dashWidth, width);
        canvas.drawLine(Offset(startX, yGoal), Offset(endX, yGoal), goalPaint);
        startX += dashWidth + dashSpace;
      }

      // "GOAL" label on the right end of the dashed line
      final goalLabelPainter = TextPainter(
        text: TextSpan(
          text: 'GOAL',
          style: GoogleFonts.outfit(
            color: Colors.white.withAlpha(100),
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      goalLabelPainter.paint(
        canvas,
        Offset(width - goalLabelPainter.width - 2, yGoal - goalLabelPainter.height - 1),
      );
    }

    // Fill area under path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (sharpLines) {
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX1 = p0.dx + colWidth / 3.2;
        final controlX2 = p1.dx - colWidth / 3.2;
        path.cubicTo(controlX1, p0.dy, controlX2, p1.dy, p1.dx, p1.dy);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, height);
    fillPath.lineTo(points.first.dx, height);
    fillPath.close();

    final fillGradient = LinearGradient(
      colors: [accentColor.withAlpha(45), accentColor.withAlpha(0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // NEON GLOW (Reduced)
    // Layer 2: Medium glow
    if (!disableGlow) {
      final shadowPaint2 = Paint()
        ..color = accentColor.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawPath(path, shadowPaint2);
    }

    // Layer 3: Main Accent color line
    final strokePaintAccent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaintAccent);

    // Layer 4: Lighter/White core for realistic neon tube effect
    final strokePaintCore = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaintCore);

    // Draw point nodes only for smaller data size (e.g., Week) to avoid clutter
    if (data.length <= 7) {
      final dotPaint = Paint()..color = Colors.white;
      final outerDotPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      for (final p in points) {
        canvas.drawCircle(p, 3.5, outerDotPaint);
        canvas.drawCircle(p, 1.8, dotPaint);
      }
    }

    // Draw vertical dotted indicator line and tooltip if a point is selected
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];

      // 1. Draw vertical dashed line
      final indicatorPaint = Paint()
        ..color = accentColor.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      double currentY = 0.0;
      double dashHt = 4.0;
      double spaceHt = 3.0;
      while (currentY < height) {
        canvas.drawLine(
          Offset(selectedPoint.dx, currentY),
          Offset(selectedPoint.dx, min(currentY + dashHt, height)),
          indicatorPaint,
        );
        currentY += dashHt + spaceHt;
      }

      // 2. Draw highlighted dot node
      final highlightOuterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final highlightInnerPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selectedPoint, 5.5, highlightOuterPaint);
      canvas.drawCircle(selectedPoint, 3.5, highlightInnerPaint);

      // 3. Draw tooltip bubble above the point if label exists (styled matching calendar tooltips)
      if (selectedIndex! < tooltipLabels.length) {
        final tooltipText = tooltipLabels[selectedIndex!];
        final textPainter = TextPainter(
          text: TextSpan(
            text: tooltipText,
            style: GoogleFonts.outfit(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 10.0,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final bubblePaddingH = 8.0;
        final bubblePaddingV = 4.0;
        final bubbleW = textPainter.width + bubblePaddingH * 2;
        final bubbleH = textPainter.height + bubblePaddingV * 2;

        // Position the bubble centered above the selected point
        double bubbleX = selectedPoint.dx - bubbleW / 2;
        bubbleX = bubbleX.clamp(4.0, width - bubbleW - 4.0);

        double bubbleY = selectedPoint.dy - bubbleH - 12.0;
        if (bubbleY < 4.0) {
          bubbleY = selectedPoint.dy + 12.0;
        }

        final bubbleRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bubbleX, bubbleY, bubbleW, bubbleH),
          const Radius.circular(6.0),
        );

        final bubblePaint = Paint()
          ..color = accentColor
          ..style = PaintingStyle.fill;

        canvas.drawRRect(bubbleRect, bubblePaint);

        textPainter.paint(
          canvas,
          Offset(bubbleX + bubblePaddingH, bubbleY + bubblePaddingV),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final List<CategoryStudyTime> sections;
  final double animValue;

  PieChartPainter({required this.sections, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (final s in sections) {
      final sweepAngle = (s.percentage / 100) * 2 * pi * animValue;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = Color(s.colorValue)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.sections != sections;
  }
}

