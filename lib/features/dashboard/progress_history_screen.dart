import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/daily_history_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/subject_provider.dart';
import '../../utils/ui_scaling.dart';
import '../../database/app_database.dart';

class ProgressHistoryScreen extends ConsumerStatefulWidget {
  const ProgressHistoryScreen({super.key});

  @override
  ConsumerState<ProgressHistoryScreen> createState() => _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends ConsumerState<ProgressHistoryScreen> {
  bool _isHeatmapMode = false;
  DateTime _selectedMonth = DateTime.now();
  String _timeframe = 'Week'; // 'Week' | 'Month' | 'Year'
  int _heatmapYear = DateTime.now().year;
  int? _selectedChartIndex;

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(overallProgressColorProvider);
    final history = ref.watch(dailyHistoryProvider).value ?? [];
    final currentStreak = ref.watch(currentStreakProvider);
    final longestStreak = ref.watch(longestStreakProvider);
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);
    final categoriesStudyAsync = ref.watch(categoryStudyTimeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'STATS HUB',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: context.s(15),
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
              // Calendar / Heatmap Toggle Selector
              _buildSlidingToggle(accentColor),
              SizedBox(height: context.s(14)),

              // Calendar or Heatmap Container
              _isHeatmapMode
                  ? _buildHeatmapContainer(context, history, accentColor)
                  : _buildCalendarContainer(context, history, dailyGoalMinutes, accentColor),

              SizedBox(height: context.s(16)),

              // Graph Segment Bar (Week / Month / Year)
              _buildTimeframeSelector(accentColor),
              SizedBox(height: context.s(12)),

              // Graph Summary Card & Visualization
              _buildGraphCard(context, history, dailyGoalMinutes, accentColor),
              SizedBox(height: context.s(16)),

              // Insights Summary row (Streak & Goal Average)
              Row(
                children: [
                  Expanded(
                    child: _buildStreakCard(context, currentStreak, longestStreak, accentColor),
                  ),
                  SizedBox(width: context.s(8)),
                  Expanded(
                    child: _buildAverageGoalCard(context, history, dailyGoalMinutes, accentColor),
                  ),
                ],
              ),
              SizedBox(height: context.s(12)),

              // Donut Chart - Syllabus Category Study Breakdown
              categoriesStudyAsync.when(
                data: (categoriesStudy) => _buildDonutChartCard(context, categoriesStudy, accentColor),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox(),
              ),

              SizedBox(height: context.s(12)),
              _buildBestDayCard(context, history, accentColor),
              SizedBox(height: context.s(20)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Construction ---

  Widget _buildSlidingToggle(Color accentColor) {
    return Container(
      height: context.s(36),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(context.s(18)),
      ),
      padding: EdgeInsets.all(context.s(4)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isHeatmapMode = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isHeatmapMode ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(context.s(14)),
                ),
                alignment: Alignment.center,
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
              onTap: () => setState(() => _isHeatmapMode = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isHeatmapMode ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(context.s(14)),
                ),
                alignment: Alignment.center,
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
    );
  }

  Widget _buildCalendarContainer(BuildContext context, List<DailyHistoryData> history, int dailyGoalMinutes, Color accentColor) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final Map<String, DailyHistoryData> historyMap = {for (final h in history) h.dateStr: h};

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: EdgeInsets.all(context.s(8)),
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
                icon: Icon(Icons.chevron_left_rounded, color: accentColor, size: context.s(18)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                },
              ),
              Text(
                '${_selectedMonth.year} | ${monthNames[_selectedMonth.month - 1]}',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.s(14.5),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: accentColor, size: context.s(18)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  });
                },
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
              final totalCells = startWeekday + daysInMonth;
              final rowsNeeded = (totalCells / 7).ceil();
              final gridItemCount = rowsNeeded * 7;

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
                    child: SizedBox(
                      width: context.s(36),
                      height: context.s(36),
                      child: CustomPaint(
                        painter: CalendarCellRingPainter(
                          progress: progress,
                          color: accentColor,
                          strokeWidth: context.s(2.5),
                        ),
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
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapContainer(BuildContext context, List<DailyHistoryData> history, Color accentColor) {
    final Map<String, DailyHistoryData> historyMap = {for (final h in history) h.dateStr: h};

    int minYear = DateTime.now().year;
    for (final h in history) {
      final d = DateTime.tryParse(h.dateStr);
      if (d != null && d.year < minYear) {
        minYear = d.year;
      }
    }
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
              Text(
                '$activeYear',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.s(13),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: activeYear > minYear ? Colors.white60 : Colors.white12,
                      size: context.s(18),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: activeYear > minYear
                        ? () {
                            setState(() {
                              _heatmapYear = activeYear - 1;
                            });
                          }
                        : null,
                  ),
                  SizedBox(width: context.s(4)),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: activeYear < currentYear ? Colors.white60 : Colors.white12,
                      size: context.s(18),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: activeYear < currentYear
                        ? () {
                            setState(() {
                              _heatmapYear = activeYear + 1;
                            });
                          }
                        : null,
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

                                      final dateStr = "${mDateTime.year}-${mDateTime.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}";
                                      final record = historyMap[dateStr];
                                      final focusSeconds = (record?.totalFocusSeconds ?? 0).toDouble();
                                      final ratio = focusSeconds / maxVal;

                                      Color blockColor = Colors.white.withAlpha(8);
                                      if (focusSeconds > 0.0) {
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

                                      return Container(
                                        width: context.s(15),
                                        height: context.s(15),
                                        margin: EdgeInsets.symmetric(vertical: context.s(1.5)),
                                        decoration: BoxDecoration(
                                          color: blockColor,
                                          borderRadius: BorderRadius.circular(context.s(3.5)),
                                          border: Border.all(
                                            color: Colors.white.withAlpha(15),
                                            width: 0.8,
                                          ),
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
    return Container(
      height: context.s(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(8)),
        border: Border.all(color: Colors.white.withAlpha(6)),
      ),
      padding: EdgeInsets.all(context.s(2)),
      child: Row(
        children: ['Week', 'Month', 'Year'].map((time) {
          final isSel = _timeframe == time;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _timeframe = time;
                _selectedChartIndex = null;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: isSel ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(context.s(6)),
                ),
                alignment: Alignment.center,
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
    );
  }

  Widget _buildGraphCard(BuildContext context, List<DailyHistoryData> history, int dailyGoalMinutes, Color accentColor) {
    double totalHours = 0.0;
    List<double> dataPoints = [];
    List<String> labels = [];

    final now = DateTime.now();

    // Comparison calculation variables
    double pctChange = 0.0;
    bool isUp = true;

    if (_timeframe == 'Week') {
      // Comparison: This Calendar Week vs Last Calendar Week
      double currentSum = 0.0;
      double previousSum = 0.0;
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
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
    } else if (_timeframe == 'Month') {
      // Comparison: This Calendar Month vs Last Calendar Month
      double currentSum = 0.0;
      double previousSum = 0.0;
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
      double currentSum = 0.0;
      double previousSum = 0.0;
      for (final h in history) {
        final d = DateTime.tryParse(h.dateStr);
        if (d != null) {
          if (d.year == now.year) {
            currentSum += h.totalFocusSeconds;
          } else if (d.year == now.year - 1) {
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
        final monthPrefix = "${now.year}-${m.toString().padLeft(2, '0')}";
        final monthSumSeconds = history
            .where((h) => h.dateStr.startsWith(monthPrefix))
            .fold(0, (sum, h) => sum + h.totalFocusSeconds);
        final hrs = monthSumSeconds / 3600.0;
        dataPoints.add(hrs);
        totalHours += hrs;
      }
    }

    final List<String> tooltipLabels = [];
    if (_timeframe == 'Week') {
      final weekdayLongNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      for (int i = 0; i < dataPoints.length; i++) {
        if (i < weekdayLongNames.length) {
          tooltipLabels.add("${weekdayLongNames[i]}: ${dataPoints[i].toStringAsFixed(1)} hrs");
        }
      }
    } else if (_timeframe == 'Month') {
      final monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthName = monthNamesShort[now.month - 1];
      for (int i = 0; i < dataPoints.length; i++) {
        tooltipLabels.add("${i + 1} $monthName: ${dataPoints[i].toStringAsFixed(1)} hrs");
      }
    } else {
      final monthNamesLong = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      for (int i = 0; i < dataPoints.length; i++) {
        if (i < monthNamesLong.length) {
          tooltipLabels.add("${monthNamesLong[i]}: ${dataPoints[i].toStringAsFixed(1)} hrs");
        }
      }
    }

    final dailyGoalHours = dailyGoalMinutes / 60.0;
    // For yearly comparison, the goal line represents monthly goal
    final referenceGoal = _timeframe == 'Year' ? (dailyGoalHours * 30.4) : dailyGoalHours;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${totalHours.toStringAsFixed(1).replaceAll('.0', '')} hrs',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: context.s(20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.s(2)),
                  Text(
                    'total this ${_timeframe.toLowerCase()}',
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
                          "${pctChange.abs().toStringAsFixed(0)}%",
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
                    "vs last ${_timeframe.toLowerCase()}",
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: context.s(10),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.s(16)),
          // Custom scaled line/bar chart
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;
              return GestureDetector(
                onPanStart: (details) {
                  final colWidth = chartWidth / dataPoints.length;
                  final index = (details.localPosition.dx / colWidth).floor().clamp(0, dataPoints.length - 1);
                  setState(() {
                    _selectedChartIndex = index;
                  });
                },
                onPanUpdate: (details) {
                  final colWidth = chartWidth / dataPoints.length;
                  final index = (details.localPosition.dx / colWidth).floor().clamp(0, dataPoints.length - 1);
                  setState(() {
                    _selectedChartIndex = index;
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _selectedChartIndex = null;
                  });
                },
                onTapDown: (details) {
                  final colWidth = chartWidth / dataPoints.length;
                  final index = (details.localPosition.dx / colWidth).floor().clamp(0, dataPoints.length - 1);
                  setState(() {
                    _selectedChartIndex = index;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _selectedChartIndex = null;
                  });
                },
                child: SizedBox(
                  height: context.s(120),
                  child: CustomPaint(
                    painter: WaveAreaChartPainter(
                      data: dataPoints,
                      goalValue: referenceGoal,
                      accentColor: accentColor,
                      selectedIndex: _selectedChartIndex,
                      tooltipLabels: tooltipLabels,
                    ),
                  ),
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
              final showLabel = _timeframe != 'Month' || (dayNum == 1 || dayNum % 5 == 0 || dayNum == labels.length);
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
                    fontSize: context.s(_timeframe == 'Month' ? 8.5 : 10),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int current, int longest, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(context.s(12)),
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
              Text(
                'Streak',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: context.s(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.whatshot_rounded, color: Colors.orangeAccent, size: context.s(18)),
            ],
          ),
          SizedBox(height: context.s(8)),
          Text(
            '$current days',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: context.s(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.s(4)),
          Text(
            'Best: $longest days',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: context.s(11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageGoalCard(BuildContext context, List<DailyHistoryData> history, int dailyGoalMinutes, Color accentColor) {
    double averagePercent = 0.0;
    if (history.isNotEmpty) {
      double totalPercent = 0.0;
      final recentHistory = history.length > 7 ? history.sublist(history.length - 7) : history;
      for (final h in recentHistory) {
        final goal = h.targetGoalSeconds;
        if (goal > 0) {
          totalPercent += (h.totalFocusSeconds / goal);
        }
      }
      averagePercent = min(1.0, totalPercent / recentHistory.length);
    }

    return Container(
      padding: EdgeInsets.all(context.s(12)),
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
              Text(
                'Daily Goal',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: context.s(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.track_changes_rounded, color: Colors.cyanAccent, size: context.s(18)),
            ],
          ),
          SizedBox(height: context.s(8)),
          Text(
            '${(averagePercent * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: context.s(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.s(4)),
          Text(
            'of weekly avg',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: context.s(11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartCard(BuildContext context, List<CategoryStudyTime> categoriesStudy, Color accentColor) {
    if (categoriesStudy.isEmpty) return const SizedBox();

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
            'SUBJECT / CATEGORY BALANCE',
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
                child: CustomPaint(
                  painter: DonutChartPainter(
                    sections: categoriesStudy,
                  ),
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

  Widget _buildBestDayCard(BuildContext context, List<DailyHistoryData> history, Color accentColor) {
    String bestDayName = "None";
    double maxHours = 0.0;

    final dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    if (history.isNotEmpty) {
      final Map<int, double> dayTotals = {};
      final recentHistory = history.length > 14 ? history.sublist(history.length - 14) : history;
      for (final h in recentHistory) {
        final date = DateTime.tryParse(h.dateStr);
        if (date != null) {
          final weekday = date.weekday % 7;
          final hrs = h.totalFocusSeconds / 3600.0;
          dayTotals[weekday] = (dayTotals[weekday] ?? 0.0) + hrs;
        }
      }

      int bestDayIdx = 0;
      for (final entry in dayTotals.entries) {
        if (entry.value > maxHours) {
          maxHours = entry.value;
          bestDayIdx = entry.key;
        }
      }
      if (maxHours > 0.0) {
        bestDayName = dayNames[bestDayIdx];
      }
    }

    return Container(
      padding: EdgeInsets.all(context.s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Best Day',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: context.s(11),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: context.s(4)),
              Text(
                bestDayName,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: context.s(15),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (maxHours > 0.0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.star_rounded, color: Colors.amberAccent, size: context.s(22)),
                SizedBox(height: context.s(2)),
                Text(
                  '${maxHours.toStringAsFixed(1).replaceAll('.0', '')} hrs avg',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: context.s(10),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
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

  WaveAreaChartPainter({
    required this.data,
    required this.goalValue,
    required this.accentColor,
    this.selectedIndex,
    this.tooltipLabels = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;
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

    // Draw reference Daily Goal dashed line
    final yGoal = height - (goalValue / (maxY > 0 ? maxY : 1.0)) * usableHeight - 10;
    final goalPaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double dashWidth = 6.0;
    double dashSpace = 4.0;
    double startX = 0.0;
    while (startX < width) {
      canvas.drawLine(
        Offset(startX, yGoal),
        Offset(min(startX + dashWidth, width), yGoal),
        goalPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Fill area under path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = p0.dx + colWidth / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, height);
    fillPath.lineTo(points.first.dx, height);
    fillPath.close();

    final fillGradient = LinearGradient(
      colors: [accentColor.withAlpha(80), accentColor.withAlpha(0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw smooth thin neon path line
    final strokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Draw thin neon blur glow
    final shadowPaint = Paint()
      ..color = accentColor.withAlpha(65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(path, shadowPaint);

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

      // 3. Draw tooltip bubble above the point if label exists
      if (selectedIndex! < tooltipLabels.length) {
        final tooltipText = tooltipLabels[selectedIndex!];
        final textPainter = TextPainter(
          text: TextSpan(
            text: tooltipText,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10.0,
            ),
          ),
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
          ..color = const Color(0xFF1C1C1E)
          ..style = PaintingStyle.fill;
        final bubbleBorderPaint = Paint()
          ..color = accentColor.withAlpha(120)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.drawRRect(bubbleRect, bubblePaint);
        canvas.drawRRect(bubbleRect, bubbleBorderPaint);

        textPainter.paint(
          canvas,
          Offset(bubbleX + bubblePaddingH, bubbleY + bubblePaddingV),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GradientBarChartPainter extends CustomPainter {
  final List<double> data;
  final double goalValue;
  final Color accentColor;

  GradientBarChartPainter({
    required this.data,
    required this.goalValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;

    final maxData = data.reduce(max);
    final maxY = maxData > goalValue ? (maxData * 1.15) : (goalValue > 0.0 ? goalValue : 1.0);

    final usableHeight = height - 24;

    final barWidth = (width / data.length) * 0.5;
    final stepX = width / data.length;

    // Draw reference Goal dashed line
    final yGoal = height - (goalValue / (maxY > 0 ? maxY : 1.0)) * usableHeight - 12;
    final goalPaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double dashWidth = 6.0;
    double dashSpace = 4.0;
    double startX = 0.0;
    while (startX < width) {
      canvas.drawLine(
        Offset(startX, yGoal),
        Offset(min(startX + dashWidth, width), yGoal),
        goalPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / (maxY > 0 ? maxY : 1.0)) * usableHeight;
      final left = i * stepX + (stepX - barWidth) / 2;
      final top = height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(4),
      );

      final fillGradient = LinearGradient(
        colors: [accentColor, accentColor.withAlpha(50)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      final barPaint = Paint()
        ..shader = fillGradient.createShader(rect.outerRect)
        ..style = PaintingStyle.fill;

      // Glow shadow
      final glowPaint = Paint()
        ..color = accentColor.withAlpha(70)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(rect, glowPaint);

      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DonutChartPainter extends CustomPainter {
  final List<CategoryStudyTime> sections;

  DonutChartPainter({required this.sections});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (final s in sections) {
      final sweepAngle = (s.percentage / 100) * 2 * pi;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = Color(s.colorValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.3;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
