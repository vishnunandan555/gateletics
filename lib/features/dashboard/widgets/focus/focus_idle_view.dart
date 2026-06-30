import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/focus_provider.dart';
import '../../../../utils/string_utils.dart';
import 'focus_dialogs.dart';
import 'timer_painters.dart';

class FocusIdleView extends ConsumerStatefulWidget {
  final Color accentColor;

  const FocusIdleView({
    super.key,
    required this.accentColor,
  });

  @override
  ConsumerState<FocusIdleView> createState() => _FocusIdleViewState();
}

class _FocusIdleViewState extends ConsumerState<FocusIdleView> {
  int _displayMode = 0;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor;
    final sessionState = ref.watch(focusProvider);
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
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    children: [
                      const TextSpan(text: 'Ready to '),
                      TextSpan(
                        text: 'Begin',
                        style: TextStyle(color: accentColor),
                      ),
                      const TextSpan(text: '?'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Timer Start Box
              _buildTimerStartBox(context, ref, sessionState, accentColor),
              const SizedBox(height: 16),

              // Method Selector Chip
              Center(
                child: GestureDetector(
                  onTap: () => showMethodSelectionMenu(context, sessionState, accentColor, ref),
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
                        buildMethodIcon(sessionState.details, accentColor, size: 18),
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

                  final minutesLeft = max(0, dailyGoalMinutes - elapsedMinutes);
                  final hoursLeftStr = (minutesLeft / 60).toStringAsFixed(1).replaceAll('.0', '');

                  final pctCompleted = (progressPercent * 100);
                  final pctLeft = max(0.0, 100.0 - pctCompleted);

                  String progressInfo = "";
                  switch (_displayMode) {
                    case 0:
                      progressInfo = "${elapsedHoursStr}hr / ${goalHoursStr}hr";
                      break;
                    case 1:
                      progressInfo = "${hoursLeftStr}hr left / ${goalHoursStr}hr";
                      break;
                    case 2:
                      progressInfo = "${pctCompleted.toStringAsFixed(1).replaceAll('.0', '')}% completed";
                      break;
                    case 3:
                      progressInfo = "${pctLeft.toStringAsFixed(1).replaceAll('.0', '')}% left";
                      break;
                    default:
                      progressInfo = "${elapsedHoursStr}hr / ${goalHoursStr}hr";
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _displayMode = (_displayMode + 1) % 4;
                      });
                    },
                    onLongPress: () => showDailyGoalDialog(context, dailyGoalMinutes, accentColor, ref),
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
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                progressInfo,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
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
                        progressDelta: s.progressDelta,
                        isFirst: index == 0,
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
  Widget _buildTimerStartBox(BuildContext context, WidgetRef ref, FocusSessionState sessionState, Color accentColor) {
    if (sessionState.details.isCountUp) {
      // Freestyle big play button
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 56.0),
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
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
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
                Column(
                  children: [
                    Text(
                      "FOCUS",
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        if (sessionState.details.isCustom) {
                          showCustomDurationPicker(context, sessionState.customTimerMinutes, accentColor, ref);
                        }
                      },
                      child: Text(
                        focusStr,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    width: 1,
                    height: 40,
                    color: Colors.white12,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "BREAK",
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      breakStr,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
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
    required double progressDelta,
    required bool isFirst,
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
          SizedBox(
            width: 16,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? 16 : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? 16 : null,
                  child: Container(
                    width: 2,
                    color: accentColor.withAlpha(50),
                  ),
                ),
                Positioned(
                  top: 16,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
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
                      // Overall % increase in the middle
                      Text(
                        "+${progressDelta.toStringAsFixed(progressDelta == progressDelta.toInt() ? 0 : 1)}%",
                        style: GoogleFonts.outfit(
                          color: progressDelta > 0 ? accentColor : Colors.white24,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        method,
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
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
}
