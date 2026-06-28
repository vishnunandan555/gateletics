import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../database/app_database.dart';
import '../../../providers/focus_provider.dart';

class FocusScreen extends ConsumerStatefulWidget {
  final Color progressColor;

  const FocusScreen({super.key, required this.progressColor});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  double _swipeDelta = 0.0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(focusProvider);
    final accentColor = widget.progressColor;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Ambient Glowing Background
            _buildAmbientGlow(accentColor, sessionState.status),

            // Main Contents
            SafeArea(
              child: sessionState.status == FocusStatus.idle
                  ? _buildIdleView(context, sessionState, accentColor)
                  : _buildActiveSessionView(context, sessionState, accentColor),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTotalDuration(int totalSeconds) {
    final hours = (totalSeconds / 3600).floor();
    final minutes = ((totalSeconds % 3600) / 60).floor();
    if (hours > 0) {
      final hoursStr = hours.toString();
      final minsStr = minutes.toString();
      return "Total: ${hoursStr}h ${minsStr}m";
    }
    return "Total: ${minutes}min";
  }

  Widget _buildMethodIcon(FocusMethodDetails details, Color color, {double size = 18}) {
    if (details.method == FocusMethod.ultradian120) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            details.iconPath,
            width: size - 2,
            height: size - 2,
            color: color,
          ),
          const SizedBox(width: 1),
          Image.asset(
            details.iconPath,
            width: size - 2,
            height: size - 2,
            color: color,
          ),
        ],
      );
    }
    return Image.asset(
      details.iconPath,
      width: size,
      height: size,
      color: color,
    );
  }

  // Radial Glowing background
  Widget _buildAmbientGlow(Color accentColor, FocusStatus status) {
    if (status == FocusStatus.idle) {
      return Container(); // Minimal background for idle
    }
    
    final glowColor = status == FocusStatus.breakTime 
        ? Colors.white.withAlpha(20) 
        : accentColor.withAlpha(40);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                glowColor.withOpacity(_glowAnimation.value),
                const Color(0xFF0F0F12).withOpacity(0.0),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // IDLE VIEW BUILDER
  // ----------------------------------------------------
  // Helper to format DateTime to "h:mm AM/PM"
  String formatTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return "$displayHour:$displayMinute $ampm";
  }

  Widget _buildIdleView(BuildContext context, FocusSessionState sessionState, Color accentColor) {
    final todaySessionsAsync = ref.watch(todayFocusSessionsProvider);
    final todayDurationAsync = ref.watch(todayFocusDurationProvider);
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Ready to Begin?',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Timer Start Box
              _buildTimerStartBox(sessionState, accentColor),
              const SizedBox(height: 16),

              // Method Selector Chip
              Center(
                child: GestureDetector(
                  onTap: () => _showMethodSelectionMenu(context, sessionState, accentColor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withAlpha(60), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMethodIcon(sessionState.details, accentColor, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          sessionState.details.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Daily Goal Progress
              dailyGoalMinutes == 0 ? const SizedBox() : todayDurationAsync.when(
                data: (elapsedSeconds) {
                  final elapsedMinutes = (elapsedSeconds / 60).floor();
                  final progressPercent = dailyGoalMinutes == 0 ? 0.0 : min(1.0, elapsedMinutes / dailyGoalMinutes);
                  final elapsedHoursStr = (elapsedMinutes / 60).toStringAsFixed(1).replaceAll('.0', '');
                  final goalHoursStr = (dailyGoalMinutes / 60).toStringAsFixed(1).replaceAll('.0', '');

                  return GestureDetector(
                    onLongPress: () => _showDailyGoalDialog(context, dailyGoalMinutes),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131316),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(10)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Daily Goal:",
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "${elapsedHoursStr}hr / ${goalHoursStr}hr",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Container(
                                  height: 32,
                                  color: Colors.white.withAlpha(8),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progressPercent,
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [accentColor.withAlpha(200), accentColor],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${(progressPercent * 100).floor()}%",
                                      style: GoogleFonts.outfit(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("Goal error: $e"),
              ),
              const SizedBox(height: 32),

              // Today's History Header
              Text(
                "Today’s History:",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // History List Timeline
              todaySessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          "No focus sessions completed today yet.",
                          style: GoogleFonts.outfit(
                            color: Colors.white30,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final durationMin = (s.durationSeconds / 60).floor();
                      final durationStr = durationMin >= 60 
                          ? "${(durationMin / 60).toStringAsFixed(1).replaceAll('.0', '')} hr" 
                          : "$durationMin min";
                      
                      final formattedTime = formatTimeOfDay(s.startTime);

                      return _buildHistoryTimelineEntry(
                        time: formattedTime,
                        method: s.method,
                        duration: durationStr,
                        accomplishments: s.accomplishments,
                        isLast: index == sessions.length - 1,
                        accentColor: accentColor,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("History error: $e"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Interactive start box (Play button or Digital representation)
  Widget _buildTimerStartBox(FocusSessionState sessionState, Color accentColor) {
    if (sessionState.details.isCountUp) {
      // Freestyle big play button
      return Center(
        child: GestureDetector(
          onTap: () => ref.read(focusProvider.notifier).startSession(),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.black,
              size: 72,
            ),
          ),
        ),
      );
    }

    // Standard timer start box
    final focusStr = sessionState.details.isCustom 
        ? "${sessionState.customTimerMinutes.toString().padLeft(2, '0')}:00" 
        : "${sessionState.details.focusMinutes.toString().padLeft(2, '0')}:00";
    final breakStr = sessionState.details.isCustom 
        ? "--:--" 
        : "${sessionState.details.breakMinutes.toString().padLeft(2, '0')}:00";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(8), width: 1.5),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (sessionState.details.isCustom) {
                      _showCustomDurationPicker(context, sessionState.customTimerMinutes);
                    }
                  },
                  child: Text(
                    focusStr,
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "|",
                    style: GoogleFonts.orbitron(
                      fontSize: 32,
                      color: Colors.white24,
                    ),
                  ),
                ),
                Text(
                  breakStr,
                  style: GoogleFonts.orbitron(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => ref.read(focusProvider.notifier).startSession(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A24),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: accentColor.withAlpha(100), width: 1.5),
                ),
              ),
              icon: Icon(Icons.play_arrow_rounded, color: accentColor),
              label: Text(
                "Lets Do This!",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // History timeline entry
  Widget _buildHistoryTimelineEntry({
    required String time,
    required String method,
    required String duration,
    required String? accomplishments,
    required bool isLast,
    required Color accentColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timestamp
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Text(
                time,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Timeline node
          Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: accentColor.withAlpha(50),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Entry Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: accentColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            duration,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            method,
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle_rounded, color: accentColor, size: 16),
                        ],
                      ),
                    ],
                  ),
                  if (accomplishments != null && accomplishments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 4),
                    Text(
                      accomplishments,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ACTIVE TIMER VIEW BUILDER
  // ----------------------------------------------------
  Widget _buildActiveSessionView(BuildContext context, FocusSessionState sessionState, Color accentColor) {
    final isBreak = sessionState.status == FocusStatus.breakTime;
    final isPaused = sessionState.status == FocusStatus.paused;
    final isCountUp = sessionState.details.isCountUp;

    final quoteText = ref.watch(formattedQuoteProvider(null));

    final displaySeconds = isCountUp
        ? sessionState.totalSecondsFocused
        : (isBreak
            ? max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds)
            : max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds));

    final hours = (displaySeconds / 3600).floor();
    final minutes = ((displaySeconds % 3600) / 60).floor();
    final seconds = displaySeconds % 60;

    final progress = sessionState.currentTargetSeconds == 0
        ? 0.0
        : min(1.0, sessionState.elapsedSeconds / sessionState.currentTargetSeconds);

    final ringColor = isBreak ? Colors.white : accentColor;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Technique Tag
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ringColor, width: 1.5),
                ),
                child: Text(
                  isBreak ? "Break Period" : "${sessionState.details.name} Mode",
                  style: GoogleFonts.outfit(
                    color: ringColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Motivational quotes (standard modes only, not freestyle)
            if (!isCountUp && !isBreak) ...[
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Center(
                  child: Text(
                    "“$quoteText”",
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withAlpha(204),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],

            const Spacer(),

            // ── Timer Display ──────────────────────────────────────────────
            // Freestyle: simple digital countup in a plain card
            // All timed modes: reuse squircle ring progress (same as main progress bar)
            if (isCountUp)
              // Freestyle box — a simple card with HH:MM:SS
              Center(
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131316),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accentColor.withAlpha(60), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      _buildTimerUnit(hours.toString().padLeft(2, '0'), 'hr'),
                      Text(':', style: GoogleFonts.orbitron(fontSize: 28, color: Colors.white30)),
                      _buildTimerUnit(minutes.toString().padLeft(2, '0'), 'min'),
                      Text(':', style: GoogleFonts.orbitron(fontSize: 28, color: Colors.white30)),
                      _buildTimerUnit(seconds.toString().padLeft(2, '0'), 's', highlightColor: accentColor),
                    ],
                  ),
                ),
              )
            else
              // Timed modes: squircle ring (same style as main overall progress bar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 140,
                    child: CustomPaint(
                      painter: _SquircleTimerPainter(
                        progress: progress,
                        color: ringColor,
                        trackColor: Colors.white.withAlpha(18),
                        strokeWidth: 10,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                              style: GoogleFonts.orbitron(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: ringColor,
                                shadows: [
                                  Shadow(color: ringColor.withAlpha(120), blurRadius: 18),
                                ],
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isBreak ? "Break Time" : (isPaused ? "Paused" : "Focusing"),
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Status label (freestyle only)
            if (isCountUp) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  isPaused ? "Paused" : "Focusing...",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Session indicator circles (timed modes)
            if (!isCountUp)
              _buildSessionIndicators(sessionState, accentColor),

            const SizedBox(height: 8),

            // Total focus chip
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(5)),
                ),
                child: Text(
                  _formatTotalDuration(sessionState.totalSecondsFocused),
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Controls section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  if (isBreak) ...[
                    // Accomplishments box during break
                    if (sessionState.sessionAccomplishments.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "This session:",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131316),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withAlpha(60)),
                        ),
                        constraints: const BoxConstraints(maxHeight: 90),
                        child: SingleChildScrollView(
                          child: Text(
                            sessionState.sessionAccomplishments.join('\n'),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withAlpha(220),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => _handleStopSessionConfirm(context, sessionState),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF221111),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(
                          "Stop Session",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Pause/Resume button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          if (isPaused) {
                            ref.read(focusProvider.notifier).resumeSession();
                          } else {
                            ref.read(focusProvider.notifier).pauseSession();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E24),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: ringColor.withAlpha(100)),
                          ),
                        ),
                        icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: ringColor),
                        label: Text(
                          isPaused ? "Resume" : "Pause",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSlideToStop(sessionState),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerUnit(String val, String label, {Color? highlightColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          val,
          style: GoogleFonts.orbitron(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: highlightColor ?? Colors.white,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Chain of circles under timer
  Widget _buildSessionIndicators(FocusSessionState sessionState, Color accentColor) {
    // Show completed intervals (with ticks) and the ongoing pulsing circle
    final completed = sessionState.completedFocusIntervals;
    final hasBreaks = sessionState.details.hasBreaks;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(completed + 2, (index) {
              final isCompletedCircle = index < completed;
              final isOngoingCircle = index == completed;
              final isBreakActive = sessionState.status == FocusStatus.breakTime;

              if (index > completed && !hasBreaks) {
                return const SizedBox(); // No extra indicator if no breaks
              }

              return Row(
                children: [
                  // Dot Node
                  if (isCompletedCircle)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 2),
                      ),
                      child: Icon(Icons.check_rounded, color: accentColor, size: 14),
                    )
                  else if (isOngoingCircle)
                    _PulsingIndicatorNode(
                      accentColor: isBreakActive ? Colors.white : accentColor,
                      isPulsing: sessionState.status != FocusStatus.paused,
                    )
                  else
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                    ),

                  // Connection Dotted Line
                  if (index < completed + 1)
                    _DottedLineConnection(
                      accentColor: index < completed ? accentColor : (isBreakActive ? Colors.white : Colors.white24),
                      isFlashing: index == completed && isBreakActive && sessionState.status != FocusStatus.paused,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // Slide to stop gesture indicator
  Widget _buildSlideToStop(FocusSessionState sessionState) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _swipeDelta -= details.delta.dy;
          if (_swipeDelta < 0.0) _swipeDelta = 0.0;
          if (_swipeDelta > 80.0) {
            _swipeDelta = 0.0;
            _handleStopSessionConfirm(context, sessionState);
          }
        });
      },
      onVerticalDragEnd: (_) {
        setState(() {
          _swipeDelta = 0.0;
        });
      },
      child: Container(
        height: 60,
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 12),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: (1.0 - (_swipeDelta / 80.0)).clamp(0.2, 1.0),
              child: const Icon(
                Icons.keyboard_double_arrow_up_rounded,
                color: Colors.white38,
                size: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Slide up to Stop",
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle slide up or stop button confirm overlay
  Future<void> _handleStopSessionConfirm(BuildContext context, FocusSessionState sessionState) async {
    ref.read(focusProvider.notifier).pauseSession();

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF131316),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Are you sure you want to stop?",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "All your accrued focus progress and accomplishments will be saved.",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: Text(
                        "No, Continue",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: widget.progressColor,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        "Yes, Stop",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      final finalSession = await ref.read(focusProvider.notifier).stopSession();
      if (mounted) {
        _showSessionSummary(context, finalSession, widget.progressColor);
      }
    } else {
      ref.read(focusProvider.notifier).resumeSession();
    }
  }

  // Displays summary of session
  void _showSessionSummary(BuildContext context, FocusSession session, Color accentColor) {
    final durationMin = (session.durationSeconds / 60).floor();
    final durationStr = durationMin >= 60 
        ? "${(durationMin / 60).toStringAsFixed(1).replaceAll('.0', '')} hr" 
        : "$durationMin min";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF131316),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: accentColor.withAlpha(60), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.stars_rounded, color: accentColor, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Session Summary",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Technique:", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                    Text(session.method, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Focused Time:", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                    Text(durationStr, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: accentColor, fontSize: 13)),
                  ],
                ),
                
                if (session.accomplishments != null && session.accomplishments!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  Text(
                    "Accomplishments:",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        session.accomplishments!,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withAlpha(230),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  ),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Awesome!",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // OVERLAY DIALOGS (METHOD SELECTION & GUIDE)
  // ----------------------------------------------------
  void _showMethodSelectionMenu(BuildContext context, FocusSessionState sessionState, Color accentColor) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F0F12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentColor.withAlpha(100), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Choose Focus Method",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Grid of options
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: FocusMethod.values.map((method) {
                        final details = focusMethodsData[method]!;
                        final isSelected = sessionState.selectedMethod == method;
                        return InkWell(
                          onTap: () {
                            ref.read(focusProvider.notifier).selectMethod(method);
                            Navigator.pop(context);
                            if (method == FocusMethod.timer) {
                              _showCustomDurationPicker(context, 30);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 110,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor.withAlpha(20) : const Color(0xFF131316),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? accentColor : Colors.white.withAlpha(5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMethodIcon(details, isSelected ? accentColor : Colors.white70, size: 24),
                                const SizedBox(height: 10),
                                Text(
                                  details.name,
                                  style: GoogleFonts.outfit(
                                    color: isSelected ? accentColor : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Learn More
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showTechniqueGuideModal(context, sessionState, accentColor);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: accentColor.withAlpha(100)),
                  ),
                  child: Text(
                    "Learn More ?",
                    style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTechniqueGuideModal(BuildContext context, FocusSessionState sessionState, Color accentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Technique Guide:",
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("Exit", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    itemCount: FocusMethod.values.length,
                    itemBuilder: (context, index) {
                      final method = FocusMethod.values[index];
                      final details = focusMethodsData[method]!;
                      final isSelected = sessionState.selectedMethod == method;

                      final targetStr = details.isCountUp 
                          ? "Count Up | No Breaks" 
                          : (details.isCustom 
                              ? "Custom Timer | No Breaks" 
                              : "${details.focusMinutes}m Focus | ${details.breakMinutes}m Break");

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131316),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? accentColor : Colors.white.withAlpha(8),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left Icon + Name
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? accentColor.withAlpha(20) : Colors.white.withAlpha(5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _buildMethodIcon(details, isSelected ? accentColor : Colors.white70, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      details.name,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                // Right Selection State
                                isSelected
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accentColor.withAlpha(40),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "Active",
                                          style: GoogleFonts.outfit(
                                            color: accentColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : OutlinedButton(
                                        onPressed: () {
                                          ref.read(focusProvider.notifier).selectMethod(method);
                                          Navigator.pop(context);
                                          if (method == FocusMethod.timer) {
                                            _showCustomDurationPicker(context, 30);
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                          side: BorderSide(color: Colors.white24),
                                        ),
                                        child: Text(
                                          "Select",
                                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                                        ),
                                      ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              targetStr,
                              style: GoogleFonts.outfit(
                                color: isSelected ? accentColor : Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              details.description,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to configure daily target focus goal
  void _showDailyGoalDialog(BuildContext context, int currentGoalMins) {
    int localMins = currentGoalMins;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hrStr = (localMins / 60).toStringAsFixed(1).replaceAll('.0', '');

            return AlertDialog(
              backgroundColor: const Color(0xFF131316),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withAlpha(8)),
              ),
              title: Text(
                "Set Daily Goal",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$hrStr hours ($localMins minutes)",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.progressColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: (localMins / 60).roundToDouble(),   // hourly steps
                    min: 1.0,
                    max: 16.0,
                    divisions: 15,
                    activeColor: widget.progressColor,
                    inactiveColor: Colors.white12,
                    label: '${(localMins / 60).round()}h',
                    onChanged: (val) {
                      setDialogState(() {
                        localMins = (val.round() * 60);
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.outfit(color: Colors.white54),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    ref.read(dailyFocusGoalProvider.notifier).setGoalMinutes(localMins);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.progressColor,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    "Save",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to configure custom timer duration
  void _showCustomDurationPicker(BuildContext context, int currentMins) {
    int localMins = currentMins;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131316),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withAlpha(8)),
              ),
              title: Text(
                "Focus Duration",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$localMins minutes",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.progressColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: localMins.toDouble(),
                    min: 1.0,
                    max: 180.0,
                    divisions: 179,
                    activeColor: widget.progressColor,
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setDialogState(() {
                        localMins = val.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.outfit(color: Colors.white54),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    ref.read(focusProvider.notifier).setCustomTimerMinutes(localMins);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.progressColor,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    "Apply",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ----------------------------------------------------
// CUSTOM PAINTER FOR PROGRESS BORDER
// ----------------------------------------------------

// Pulsing Indicator circle widget
class _PulsingIndicatorNode extends StatefulWidget {
  final Color accentColor;
  final bool isPulsing;

  const _PulsingIndicatorNode({required this.accentColor, required this.isPulsing});

  @override
  State<_PulsingIndicatorNode> createState() => _PulsingIndicatorNodeState();
}

class _PulsingIndicatorNodeState extends State<_PulsingIndicatorNode> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingIndicatorNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: widget.accentColor, width: 2),
            ),
          ),
        );
      },
    );
  }
}

// Connecting line widget
class _DottedLineConnection extends StatefulWidget {
  final Color accentColor;
  final bool isFlashing;

  const _DottedLineConnection({required this.accentColor, required this.isFlashing});

  @override
  State<_DottedLineConnection> createState() => _DottedLineConnectionState();
}

class _DottedLineConnectionState extends State<_DottedLineConnection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);

    if (widget.isFlashing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _DottedLineConnection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlashing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isFlashing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: SizedBox(
            width: 32,
            height: 2,
            child: CustomPaint(
              painter: _DottedPainter(color: widget.accentColor),
            ),
          ),
        );
      },
    );
  }
}

class _DottedPainter extends CustomPainter {
  final Color color;

  _DottedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SquircleTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _SquircleTimerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  Path _bottomCenterStartRoundedRectPath(Rect rect, double radius) {
    final path = Path();
    final left = rect.left;
    final top = rect.top;
    final width = rect.width;
    final height = rect.height;

    final startX = left + width / 2;
    final startY = top + height;

    path.moveTo(startX, startY);

    path.lineTo(left + radius, top + height);

    path.arcToPoint(
      Offset(left, top + height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    path.lineTo(left, top + radius);

    path.arcToPoint(
      Offset(left + radius, top),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    path.lineTo(left + width - radius, top);

    path.arcToPoint(
      Offset(left + width, top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    path.lineTo(left + width, top + height - radius);

    path.arcToPoint(
      Offset(left + width - radius, top + height),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    path.lineTo(startX, startY);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2 + 1;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    final fullPath = _bottomCenterStartRoundedRectPath(rect, 24);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, trackPaint);

    if (progress < 0.005) return;

    final metric = fullPath.computeMetrics().first;
    final progressPath = metric.extractPath(0, metric.length * progress);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(_SquircleTimerPainter old) =>
      old.progress != progress || old.color != color;
}

