import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/subject_provider.dart';
import '../../providers/target_date_provider.dart';
import '../../providers/progress_font_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../utils/ui_scaling.dart';
import '../../providers/focus_provider.dart';
import 'widgets/home_carousel.dart';
import '../../providers/glow_strength_provider.dart';
import '../../providers/focus_animation_provider.dart';
import '../../providers/rollover_provider.dart';
import '../../database/app_database.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final PageController? shellPageController;
  final void Function(int)? onNavigate;

  const HomeScreen({
    super.key,
    this.shellPageController,
    this.onNavigate,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _navigateToTab(int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
    } else if (widget.shellPageController != null) {
      widget.shellPageController!.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final accentColor = ref.watch(overallProgressColorProvider);
    final displayName = ref.watch(displayNameProvider);
    final profileImage = ref.watch(displayProfileImageProvider);
    final profileState = ref.watch(profileProvider);
    final launchQuote = ref.watch(launchQuoteProvider);
    final glowStrength = ref.watch(glowStrengthProvider);

    final focusState = ref.watch(focusProvider);
    final isFocusActive = focusState.status != FocusStatus.idle;

    // Watch values for daily progress calculation
    final todayFocusSeconds = ref.watch(todayFocusDurationProvider).value ?? 0;
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);
    final dailyGoalSeconds = dailyGoalMinutes * 60;
    final todayProgress = dailyGoalSeconds > 0 ? (todayFocusSeconds / dailyGoalSeconds).clamp(0.0, 1.0) : 0.0;
    final isDailyGoalReached = todayProgress >= 1.0;

    // Check if there are any focus sessions today to determine button text
    final todaySessions = ref.watch(todayFocusSessionsProvider).value ?? [];
    final hasStartedToday = todaySessions.isNotEmpty || todayFocusSeconds > 0;



    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -1.5),
            radius: 2.0,
            colors: [
              accentColor.withAlpha((45 * glowStrength).round().clamp(0, 255)),
              accentColor.withAlpha((25 * glowStrength).round().clamp(0, 255)),
              accentColor.withAlpha((12 * glowStrength).round().clamp(0, 255)),
              accentColor.withAlpha((4 * glowStrength).round().clamp(0, 255)),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 520 : double.infinity,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.s(20.0), vertical: context.s(16.0)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: isDesktop ? 24 : context.s(72)),
                          SizedBox(height: context.s(40)), // Push content down so it starts above middle

                          // Profile Avatar & Dynamic Greetings
                          if (profileState.profilePhotoMode != 'none') ...[
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(context.s(3)),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accentColor, width: context.s(1.5)),
                                ),
                                child: CircleAvatar(
                                  radius: context.s(profileState.profilePhotoSize),
                                  backgroundImage: profileImage,
                                  backgroundColor: accentColor.withAlpha(30),
                                  child: profileImage == null
                                      ? Icon(Icons.person_rounded, color: accentColor, size: context.s(profileState.profilePhotoSize))
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: context.s(10)),
                          ],

                          Center(
                            child: Column(
                              children: [
                                Text(
                                  displayName != null ? "Welcome Back," : "Welcome Back!",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: context.s(20),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (displayName != null) ...[
                                  SizedBox(height: context.s(4)),
                                  Text(
                                    "$displayName!",
                                    style: GoogleFonts.outfit(
                                      color: accentColor,
                                      fontSize: context.s(26),
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(color: accentColor.withAlpha(102), blurRadius: context.s(12)),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SizedBox(height: context.s(20)),

                          // Big Countdown Timer (DAYS : HRS : MINS : SECS)
                          const _TickingCountdownTimer(),

                          SizedBox(height: context.s(16)),

                          // Static Launch Quote
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: context.s(24.0)),
                              child: Text(
                                "“$launchQuote”",
                                style: GoogleFonts.outfit(
                                  color: Colors.white60,
                                  fontSize: context.s(13),
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          SizedBox(height: context.s(30)),

                          // Syllabus/Resource Completion Card
                          HomeCarousel(
                            accentColor: accentColor,
                            onTabChange: _navigateToTab,
                          ),

                          SizedBox(height: context.s(20)),

                           // Resume Prep / Active Focus Button
                          isFocusActive
                              ? ActiveFocusWaveWidget(
                                  accentColor: accentColor,
                                  onTap: () => _navigateToTab(3),
                                )
                              : _buildResumePrepButton(todayProgress, hasStartedToday, accentColor),

                          // Daily Goal Reached Tick Indicator
                          if (isDailyGoalReached) ...[
                            SizedBox(height: context.s(8)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: accentColor, size: context.s(14)),
                                SizedBox(width: context.s(4)),
                                Text(
                                  "Daily Goal Reached",
                                  style: GoogleFonts.outfit(
                                    color: accentColor,
                                    fontSize: context.s(11),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          SizedBox(height: context.s(30)),

                          // Bottom Consistency Grid
                          _buildConsistencyGrid(accentColor, dailyGoalMinutes),

                          SizedBox(height: context.s(8)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
  ),
);
  }



  // Resume / Start Prep Button with progress background
  Widget _buildResumePrepButton(double progress, bool hasStarted, Color accentColor) {
    final buttonText = hasStarted ? "RESUME PREPARATION" : "START PREPARATION";
    final fillStyle = ref.watch(resumeFillStyleProvider);

    Widget progressWidget;
    Color labelColor = Colors.white;
    Color iconBgColor = Colors.white;
    Color iconColor = Colors.black;

    switch (fillStyle) {
      case ResumeFillStyle.rectangularFill:
        progressWidget = Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              color: accentColor,
            ),
          ),
        );
        labelColor = progress > 0.45 ? Colors.black : Colors.white;
        iconBgColor = progress > 0.25 ? Colors.black : Colors.white;
        iconColor = progress > 0.25 ? accentColor : Colors.black;
        break;

      case ResumeFillStyle.neonGradient:
        progressWidget = Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.45),
                    accentColor.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
        );
        labelColor = Colors.white;
        iconBgColor = Colors.white;
        iconColor = Colors.black;
        break;

      case ResumeFillStyle.bottomMicroIndicator:
        progressWidget = Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: context.s(3.5),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: accentColor,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.6),
                    blurRadius: context.s(6),
                    offset: Offset(0, context.s(-1)),
                  ),
                ],
              ),
            ),
          ),
        );
        labelColor = Colors.white;
        iconBgColor = Colors.white;
        iconColor = Colors.black;
        break;
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: GestureDetector(
          onTap: () => _navigateToTab(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.s(30)),
            child: Container(
              height: context.s(48),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12), // Unfilled background
                borderRadius: BorderRadius.circular(context.s(30)),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Stack(
                children: [
                  // Progress layer
                  progressWidget,
                  // Button label/icon layer overlay
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.s(4)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconBgColor,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: iconColor,
                            size: context.s(16),
                          ),
                        ),
                        SizedBox(width: context.s(8)),
                        Text(
                          buttonText,
                          style: GoogleFonts.outfit(
                            color: labelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: context.s(12),
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
        ),
      ),
    );
  }

  // Horizontal Consistency Day Tracker
  Widget _buildConsistencyGrid(Color accentColor, int dailyGoalMinutes) {
    final recentSessionsAsync = ref.watch(recentDaysFocusProvider);
    final rollover = ref.watch(studyDayRolloverProvider);

    return recentSessionsAsync.when(
      data: (sessionsMap) {
        final now = DateTime.now();
        // Generate list of 7 study days with Today in the middle (index 3)
        final List<DateTime> days = List.generate(7, (index) {
          // index 3 is today, so range is: today-3 to today+3
          return studyDayFor(now, rollover).add(Duration(days: index - 3));
        });

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;

            final secondsFocused = sessionsMap[day] ?? 0;
            final minutesFocused = secondsFocused / 60;
            final progress = dailyGoalMinutes > 0 ? (minutesFocused / dailyGoalMinutes).clamp(0.0, 1.0) : 0.0;

            final dayName = _getDayName(day.weekday);
            final dayNumber = '${day.day}';

            final isMiddleToday = index == 3;
            final isPastDay = index < 3;

            if (isMiddleToday) {
              // Solid filled background for today
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(4.0)),
                  child: Container(
                    height: context.s(52),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(context.s(8)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: context.s(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: context.s(2)),
                        Text(
                          dayNumber,
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: context.s(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (isPastDay) {
              // Past days: accent outlines representing focus goal progress
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(4.0)),
                  child: CustomPaint(
                    painter: DailyGoalOutlinePainter(
                      progress: progress,
                      color: progress >= 1.0 ? Colors.green : accentColor,
                      borderRadius: context.s(8.0),
                      strokeWidth: context.s(1.8),
                    ),
                    child: Container(
                      height: context.s(52),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E22),
                        borderRadius: BorderRadius.circular(context.s(8)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: GoogleFonts.outfit(
                              color: progress > 0 ? (progress >= 1.0 ? Colors.green : accentColor) : Colors.white38,
                              fontSize: context.s(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.s(2)),
                          Text(
                            dayNumber,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: context.s(12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // Future days: subtle grey outline
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.s(4.0)),
                child: Container(
                  height: context.s(52),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(context.s(8)),
                    border: Border.all(
                      color: Colors.white.withAlpha(20),
                      width: context.s(1.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: context.s(10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.s(2)),
                      Text(
                        dayNumber,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: context.s(12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          "Consistency error: $e",
          style: const TextStyle(color: Colors.redAccent, fontSize: 10),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}

// Custom Painter to draw partial or full outlines around Day containers
class DailyGoalOutlinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;
  final double strokeWidth;

  DailyGoalOutlinePainter({
    required this.progress,
    required this.color,
    this.borderRadius = 8.0,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      final extract = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DailyGoalOutlinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Riverpod Provider for Consistency Days
final recentDaysFocusProvider = StreamProvider<Map<DateTime, int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  return db.watchRecentFocusSessions(7, rollover: rollover).map((sessions) {
    final map = <DateTime, int>{};
    for (final s in sessions) {
      final studyDay = studyDayFor(s.startTime, rollover);
      final current = map[studyDay] ?? 0;
      map[studyDay] = current + s.durationSeconds.toInt();
    }
    return map;
  });
});

class _TickingCountdownTimer extends ConsumerStatefulWidget {
  const _TickingCountdownTimer();

  @override
  ConsumerState<_TickingCountdownTimer> createState() => _TickingCountdownTimerState();
}

class _TickingCountdownTimerState extends ConsumerState<_TickingCountdownTimer> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  TextStyle getAccentStyle(double size, Color col, ProgressFont selectedFont) {
    final base = TextStyle(
      fontSize: context.s(size),
      fontWeight: FontWeight.bold,
      color: col,
      height: 1.0,
    );
    switch (selectedFont) {
      case ProgressFont.jersey15:
        return GoogleFonts.jersey15(textStyle: base.copyWith(fontSize: context.s(size + 8)));
      case ProgressFont.jersey10:
        return GoogleFonts.jersey10(textStyle: base.copyWith(fontSize: context.s(size + 8)));
      case ProgressFont.tektur:
        return GoogleFonts.tektur(textStyle: base);
      case ProgressFont.odibeeSans:
        return GoogleFonts.odibeeSans(textStyle: base.copyWith(fontSize: context.s(size + 4)));
      case ProgressFont.pressStart2P:
        return GoogleFonts.pressStart2p(textStyle: base.copyWith(fontSize: context.s(size - 8)));
      case ProgressFont.boldonse:
        return GoogleFonts.boldonse(textStyle: base.copyWith(fontSize: context.s(size - 2), height: 1.2));
      case ProgressFont.orbitron:
        return GoogleFonts.orbitron(textStyle: base);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetDate = ref.watch(targetDateProvider);
    final accentColor = ref.watch(overallProgressColorProvider);
    final selectedFont = ref.watch(progressFontProvider);

    final diff = targetDate.difference(_currentTime);
    final totalDays = diff.inDays > 0 ? diff.inDays : 0;
    final hours = diff.inHours > 0 ? diff.inHours % 24 : 0;
    final minutes = diff.inMinutes > 0 ? diff.inMinutes % 60 : 0;
    final seconds = diff.inSeconds > 0 ? diff.inSeconds % 60 : 0;

    Widget buildTimeSegment(String value, String label) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: getAccentStyle(28, Colors.white, selectedFont).copyWith(
              height: 1.1,
            ),
          ),
          SizedBox(height: context.s(4)),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: context.s(8),
              letterSpacing: context.s(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    Widget buildColon() {
      return Padding(
        padding: EdgeInsets.only(bottom: context.s(12.0)),
        child: Text(
          ':',
          style: GoogleFonts.orbitron(
            color: accentColor,
            fontSize: context.s(22),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.s(12), horizontal: context.s(16)),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: accentColor.withAlpha(102), width: context.s(1.2)),
            borderRadius: BorderRadius.circular(context.s(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildTimeSegment('$totalDays', 'DAYS'),
              buildColon(),
              buildTimeSegment('$hours', 'HRS'),
              buildColon(),
              buildTimeSegment('$minutes', 'MINS'),
              buildColon(),
              buildTimeSegment('$seconds', 'SECS'),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveFocusWaveWidget extends ConsumerStatefulWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const ActiveFocusWaveWidget({
    super.key,
    required this.accentColor,
    required this.onTap,
  });

  @override
  ConsumerState<ActiveFocusWaveWidget> createState() => _ActiveFocusWaveWidgetState();
}

class _ActiveFocusWaveWidgetState extends ConsumerState<ActiveFocusWaveWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Pulse controller for text fading to nothing and coming back (very slowly: 3.5s duration)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _pulseAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Wave controller for looping motion of the wave (2s duration)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _waveController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animType = ref.watch(focusAnimationProvider);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slowly pulsing "Focusing..." text (no glow/shadow)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Text(
                    "Focusing...",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Smooth looping animation restricted to width of the text
            SizedBox(
              height: 20,
              width: 100, // Matches width of "Focusing..." text
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  switch (animType) {
                    case FocusAnimationType.pulseDots:
                      return CustomPaint(
                        painter: _PulseDotsPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.sonicEqualizer:
                      return CustomPaint(
                        painter: _EqualizerPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.heartbeatECG:
                      return CustomPaint(
                        painter: _ECGPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.singleWave:
                      return CustomPaint(
                        painter: _WavePainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.35),
                          isDouble: false,
                        ),
                      );
                    case FocusAnimationType.doubleWave:
                      return CustomPaint(
                        painter: _WavePainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.35),
                          isDouble: true,
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final bool isDouble;

  _WavePainter({required this.phase, required this.color, this.isDouble = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final yCenter = size.height / 2;
    final waveLength = size.width;
    final amplitude = 12.0; // wave height

    path.moveTo(0, yCenter);

    for (double x = 0; x <= size.width; x++) {
      final y = yCenter + amplitude * sin((2 * pi * x / waveLength) - (phase * 2 * pi));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    if (isDouble) {
      // Draw a secondary out-of-phase wave for extra aesthetic depth
      final secondaryPaint = Paint()
        ..color = color.withValues(alpha: color.a * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final secondaryPath = Path();
      secondaryPath.moveTo(0, yCenter);
      for (double x = 0; x <= size.width; x++) {
        final y = yCenter + (amplitude * 0.7) * sin((2 * pi * x / (waveLength * 0.8)) - (phase * 2 * pi) + pi / 2);
        secondaryPath.lineTo(x, y);
      }
      canvas.drawPath(secondaryPath, secondaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color || oldDelegate.isDouble != isDouble;
  }
}

class _PulseDotsPainter extends CustomPainter {
  final double phase;
  final Color color;

  _PulseDotsPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final dotCount = 3;
    final spacing = 16.0;
    final startX = (size.width - (dotCount - 1) * spacing) / 2;
    final yCenter = size.height / 2;

    for (int i = 0; i < dotCount; i++) {
      final dotPhase = (phase * 2 * pi - (i * pi / 1.5)) % (2 * pi);
      final scale = 0.4 + 0.6 * (0.5 + 0.5 * sin(dotPhase));
      final dotPaint = Paint()
        ..color = color.withValues(alpha: color.a * scale)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(startX + i * spacing, yCenter), 4.5 * scale, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseDotsPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

class _EqualizerPainter extends CustomPainter {
  final double phase;
  final Color color;

  _EqualizerPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barCount = 4;
    final barWidth = 3.0;
    final barSpacing = 8.0;
    final totalWidth = barCount * barWidth + (barCount - 1) * barSpacing;
    final startX = (size.width - totalWidth) / 2;
    final bottom = size.height;

    for (int i = 0; i < barCount; i++) {
      final offset = (i * pi / 4);
      final heightFactor = 0.2 + 0.8 * (0.5 + 0.5 * sin(phase * 4 * pi + offset));
      final barHeight = size.height * heightFactor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + i * (barWidth + barSpacing), bottom - barHeight, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

class _ECGPainter extends CustomPainter {
  final double phase;
  final Color color;

  _ECGPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final yCenter = size.height / 2;
    path.moveTo(0, yCenter);

    for (double x = 0; x <= size.width; x++) {
      final nx = x / size.width;
      final pulsePos = phase;
      final dist = (nx - pulsePos).abs();
      
      double y = yCenter;
      if (dist < 0.12) {
        final localX = (nx - pulsePos) / 0.12; // ranges from -1 to 1
        double spike = 0.0;
        if (localX > -0.8 && localX < -0.4) {
          spike = -0.2 * sin((localX + 0.6) * pi / 0.2); // P wave
        } else if (localX >= -0.4 && localX <= 0.0) {
          spike = 1.0 * sin((localX + 0.2) * pi / 0.2); // QRS peak
        } else if (localX > 0.0 && localX < 0.3) {
          spike = -0.3 * sin((localX - 0.15) * pi / 0.15); // S depression
        } else if (localX >= 0.3 && localX < 0.7) {
          spike = 0.2 * sin((localX - 0.5) * pi / 0.2); // T wave
        }
        y = yCenter - spike * (size.height * 0.45);
      }
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ECGPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}
