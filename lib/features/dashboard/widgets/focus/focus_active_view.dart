import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/focus_provider.dart';
import '../../../../providers/quotes_provider.dart';
import 'timer_painters.dart';
import '../../../../utils/ui_scaling.dart';

class FocusActiveView extends ConsumerStatefulWidget {
  final Color accentColor;

  const FocusActiveView({
    super.key,
    required this.accentColor,
  });

  @override
  ConsumerState<FocusActiveView> createState() => _FocusActiveViewState();
}

class _FocusActiveViewState extends ConsumerState<FocusActiveView> {
  double _swipeDelta = 0.0;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(focusProvider);
    final accentColor = widget.accentColor;

    final isBreak = sessionState.isBreakActive;
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
    final totalMinutes = (displaySeconds / 60).floor();

    final progress = sessionState.currentTargetSeconds == 0
        ? 0.0
        : min(1.0, sessionState.elapsedSeconds / sessionState.currentTargetSeconds);

    final ringColor = isBreak ? Colors.white : accentColor;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Technique Tag
                    SizedBox(height: context.s(16)),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(6)),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(context.s(20)),
                          border: Border.all(color: ringColor, width: context.s(1.5)),
                        ),
                        child: Text(
                          isBreak ? "Break Period" : sessionState.details.name,
                          style: GoogleFonts.outfit(
                            color: ringColor,
                            fontSize: context.s(12),
                            fontWeight: FontWeight.bold,
                            letterSpacing: context.s(0.5),
                          ),
                        ),
                      ),
                    ),

                    // Motivational quotes (standard modes only, not freestyle, and only if enabled in Settings)
                    if (!isCountUp && !isBreak && ref.watch(focusQuotesEnabledProvider)) ...[
                      SizedBox(height: context.s(28)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.s(32.0)),
                        child: Center(
                          child: Text(
                            "“$quoteText”",
                            style: GoogleFonts.caveat(
                              fontSize: context.s(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withAlpha(204),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: context.s(40)),

                    // ── Timer Display ──────────────────────────────────────────────
                    if (isCountUp)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            _buildTimerUnit(hours.toString().padLeft(2, '0'), 'hr'),
                            SizedBox(width: context.s(8)),
                            _buildTimerUnit(minutes.toString().padLeft(2, '0'), 'min'),
                            SizedBox(width: context.s(8)),
                            _buildTimerUnit(seconds.toString().padLeft(2, '0'), 's', highlightColor: accentColor),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.s(24.0)),
                        child: Center(
                          child: SizedBox(
                            width: double.infinity,
                            height: context.s(140),
                            child: CustomPaint(
                              painter: SquircleTimerPainter(
                                progress: progress,
                                color: ringColor,
                                trackColor: Colors.white.withAlpha(18),
                                strokeWidth: context.s(10),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                                      style: GoogleFonts.orbitron(
                                        fontSize: context.s(52),
                                        fontWeight: FontWeight.w900,
                                        color: ringColor,
                                        shadows: [
                                          Shadow(color: ringColor.withAlpha(120), blurRadius: context.s(18)),
                                        ],
                                        letterSpacing: context.s(2),
                                      ),
                                    ),
                                    SizedBox(height: context.s(2)),
                                    Text(
                                      isBreak ? "Break Time" : (isPaused ? "Paused" : "Focusing"),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white54,
                                        fontSize: context.s(11),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: context.s(0.5),
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
                      SizedBox(height: context.s(16)),
                      Center(
                        child: Text(
                          isPaused ? "Paused" : "Focusing...",
                          style: GoogleFonts.outfit(
                            fontSize: context.s(18),
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: context.s(16)),

                    // Session indicator circles (timed modes)
                    if (!isCountUp)
                      _buildSessionIndicators(sessionState, accentColor),

                    SizedBox(height: context.s(8)),

                    // Total focus chip
                    if (!isCountUp)
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: context.s(14), vertical: context.s(6)),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181F),
                            borderRadius: BorderRadius.circular(context.s(16)),
                            border: Border.all(color: Colors.white.withAlpha(5)),
                          ),
                          child: Text(
                            _formatTotalDuration(sessionState.totalSecondsFocused),
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: context.s(12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: context.s(40)),

                    // Controls section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.s(24.0)),
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
                                    fontSize: context.s(13),
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                              SizedBox(height: context.s(6)),
                              Container(
                                padding: EdgeInsets.all(context.s(12)),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131316),
                                  borderRadius: BorderRadius.circular(context.s(12)),
                                  border: Border.all(color: accentColor.withAlpha(60)),
                                ),
                                constraints: BoxConstraints(maxHeight: context.s(90)),
                                child: SingleChildScrollView(
                                  child: Text(
                                    sessionState.sessionAccomplishments.join('\n'),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: context.s(12),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.s(12)),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: context.s(48),
                              child: FilledButton.icon(
                                onPressed: () => _handleStopSessionConfirm(context, sessionState),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF221111),
                                  foregroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(context.s(14)),
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
                            if (isCountUp) ...[
                              // Pause/Resume button (Freestyle only, horizontally smaller)
                              Center(
                                child: SizedBox(
                                  width: context.s(150),
                                  height: context.s(48),
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
                                        borderRadius: BorderRadius.circular(context.s(14)),
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
                              ),
                              SizedBox(height: context.s(16)),
                            ],
                            _buildSlideToStop(sessionState),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: context.s(8)),
                  ],
                ),
              ),
            );
          },
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
            fontSize: context.s(32),
            fontWeight: FontWeight.bold,
            color: highlightColor ?? Colors.white,
          ),
        ),
        SizedBox(width: context.s(2)),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: context.s(10),
            color: Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionIndicators(FocusSessionState sessionState, Color accentColor) {
    final completed = sessionState.completedFocusIntervals;
    final isBreakActive = sessionState.isBreakActive;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.s(24.0), vertical: context.s(12.0)),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(completed + 1, (index) {
              final isCompletedCircle = index < completed;

              return Row(
                children: [
                  if (isCompletedCircle)
                    Container(
                      width: context.s(24),
                      height: context.s(24),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: context.s(2)),
                      ),
                      child: Icon(Icons.check_rounded, color: accentColor, size: context.s(14)),
                    )
                  else
                    PulsingIndicatorNode(
                      accentColor: isBreakActive ? Colors.white : accentColor,
                      isPulsing: sessionState.status != FocusStatus.paused,
                    ),

                  if (isBreakActive && index == completed - 1)
                    DottedLineConnection(
                      accentColor: Colors.white,
                      isFlashing: sessionState.status != FocusStatus.paused,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideToStop(FocusSessionState sessionState) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _swipeDelta -= details.delta.dy;
          if (_swipeDelta < 0.0) _swipeDelta = 0.0;
          if (_swipeDelta > context.s(80.0)) {
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
        height: context.s(60),
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(bottom: context.s(12)),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: (1.0 - (_swipeDelta / context.s(80.0))).clamp(0.2, 1.0),
              child: Icon(
                Icons.keyboard_double_arrow_up_rounded,
                color: Colors.white38,
                size: context.s(18),
              ),
            ),
            SizedBox(height: context.s(2)),
            Text(
              "Slide up to Stop",
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: context.s(10),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                        backgroundColor: widget.accentColor,
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
      if (context.mounted) {
        _showSessionSummary(context, finalSession, widget.accentColor);
      }
    } else {
      ref.read(focusProvider.notifier).resumeSession();
    }
  }

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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Duration:", style: GoogleFonts.outfit(color: Colors.white54)),
                    Text(durationStr, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Method:", style: GoogleFonts.outfit(color: Colors.white54)),
                    Text(session.method, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Progress:", style: GoogleFonts.outfit(color: Colors.white54)),
                    Text(
                      "+${session.progressDelta.toStringAsFixed(session.progressDelta == session.progressDelta.toInt() ? 0 : 1)}%",
                      style: GoogleFonts.outfit(
                        color: session.progressDelta > 0 ? accentColor : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                if (session.accomplishments != null && session.accomplishments!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Accomplishments:",
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        session.accomplishments!,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, height: 1.4),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text("Awesome", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          ),
        );
      },
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
}
