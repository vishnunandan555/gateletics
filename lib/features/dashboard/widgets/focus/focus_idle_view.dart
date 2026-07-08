import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../providers/focus_provider.dart';
import '../../../../utils/string_utils.dart';
import 'focus_dialogs.dart';
import 'timer_painters.dart';
import '../../../../utils/ui_scaling.dart';

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
          padding: EdgeInsets.only(left: context.s(24), right: context.s(24), top: context.s(16), bottom: context.s(40)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              SizedBox(height: context.s(12)),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: context.s(32),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: context.s(0.5),
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
              SizedBox(height: context.s(24)),

              // Timer Start Box
              _buildTimerStartBox(context, ref, sessionState, accentColor),
              SizedBox(height: context.s(16)),

              // Method Selector Chip
              Center(
                child: GestureDetector(
                  onTap: () => showMethodSelectionMenu(context, sessionState, accentColor, ref),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.s(20), vertical: context.s(10)),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(35),
                      borderRadius: BorderRadius.circular(context.s(12)),
                      border: Border.all(color: accentColor.withAlpha(100), width: context.s(1.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildMethodIcon(sessionState.details, accentColor, size: context.s(24)),
                        SizedBox(width: context.s(12)),
                        Text(
                          sessionState.details.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: context.s(14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final categoriesAsync = ref.watch(syllabusCategoriesProvider);
                  return categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) return const SizedBox();

                      final selectedCat = sessionState.selectedCategoryId != null
                          ? categories.firstWhere(
                              (c) => c.id == sessionState.selectedCategoryId,
                              orElse: () => categories.first,
                            )
                          : null;

                      final buttonColor = selectedCat != null ? Color(selectedCat.color) : accentColor;
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: context.s(16)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: buttonColor.withAlpha(35),
                              borderRadius: BorderRadius.circular(context.s(12)),
                              border: Border.all(
                                color: buttonColor.withAlpha(100),
                                width: context.s(1.5),
                              ),
                            ),
                            child: IntrinsicWidth(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _showCategorySelectionBottomSheet(
                                          context,
                                          ref,
                                          categories,
                                          sessionState.selectedCategoryId,
                                          accentColor,
                                        );
                                      },
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(context.s(12)),
                                        bottomLeft: Radius.circular(context.s(12)),
                                        topRight: selectedCat == null
                                            ? Radius.circular(context.s(12))
                                            : Radius.zero,
                                        bottomRight: selectedCat == null
                                            ? Radius.circular(context.s(12))
                                            : Radius.zero,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: context.s(20),
                                          vertical: context.s(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (selectedCat != null) ...[
                                              Container(
                                                width: context.s(10),
                                                height: context.s(10),
                                                decoration: BoxDecoration(
                                                  color: Color(selectedCat.color),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(selectedCat.color).withValues(alpha: 0.6),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: context.s(12)),
                                            ] else ...[
                                              Icon(
                                                Icons.label_outline_rounded,
                                                color: Colors.white70,
                                                size: context.s(20),
                                              ),
                                              SizedBox(width: context.s(12)),
                                            ],
                                            Text(
                                              selectedCat != null ? getCategoryShortName(selectedCat.name) : "Choose Category",
                                              style: GoogleFonts.outfit(
                                                color: selectedCat != null ? Colors.white : Colors.white70,
                                                fontSize: context.s(14),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (selectedCat == null) ...[
                                              SizedBox(width: context.s(12)),
                                              Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                color: Colors.white70,
                                                size: context.s(20),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (selectedCat != null) ...[
                                    Container(
                                      width: 1.5,
                                      height: context.s(24),
                                      color: buttonColor.withAlpha(100),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          ref.read(focusProvider.notifier).setSelectedCategory(null);
                                        },
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(context.s(12)),
                                          bottomRight: Radius.circular(context.s(12)),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.s(14),
                                            vertical: context.s(10),
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: Colors.white70,
                                            size: context.s(20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (e, _) => const SizedBox(),
                  );
                },
              ),
              SizedBox(height: context.s(32)),

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
                      padding: EdgeInsets.all(context.s(16)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131316),
                        borderRadius: BorderRadius.circular(context.s(16)),
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
                                  fontSize: context.s(15),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                progressInfo,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: context.s(15),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.s(10)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(context.s(8)),
                            child: Stack(
                              children: [
                                Container(
                                  height: context.s(32),
                                  color: Colors.white.withAlpha(8),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progressPercent,
                                  child: Container(
                                    height: context.s(32),
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
              SizedBox(height: context.s(32)),

              // Today's History Header
              Text(
                "Today’s History:",
                style: GoogleFonts.outfit(
                  fontSize: context.s(24),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: context.s(16)),

              // History List Timeline
              todaySessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: context.s(24.0)),
                      child: Center(
                        child: Text(
                          "No focus sessions completed today yet.",
                          style: GoogleFonts.outfit(
                            color: Colors.white30,
                            fontSize: context.s(14),
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
                        context,
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

  void _showCategorySelectionBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> categories,
    int? selectedId,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131316),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.s(24))),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select Study Category',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.label_off_rounded, color: Colors.white30),
                      title: const Text('General Focus (No Category)'),
                      trailing: selectedId == null
                          ? Icon(Icons.check_circle_rounded, color: accentColor)
                          : null,
                      onTap: () {
                        ref.read(focusProvider.notifier).setSelectedCategory(null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ...categories.map((c) {
                      final isSelected = c.id == selectedId;
                      return ListTile(
                        leading: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Color(c.color),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(c.color).withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          c.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: accentColor)
                            : null,
                        onTap: () {
                          ref.read(focusProvider.notifier).setSelectedCategory(c.id);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Interactive start box (Play button or Digital representation)
  Widget _buildTimerStartBox(BuildContext context, WidgetRef ref, FocusSessionState sessionState, Color accentColor) {
    if (sessionState.details.isCountUp) {
      // Freestyle big play button
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.s(56.0)),
          child: GestureDetector(
            onTap: () => ref.read(focusProvider.notifier).startSession(),
            child: Container(
              width: context.s(140),
              height: context.s(140),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(38),
                    blurRadius: context.s(16),
                    spreadRadius: context.s(1),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.black,
                size: context.s(72),
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
      padding: EdgeInsets.symmetric(horizontal: context.s(20), vertical: context.s(24)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(20)),
        border: Border.all(color: Colors.white.withAlpha(8), width: context.s(1.5)),
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
                        fontSize: context.s(10),
                        fontWeight: FontWeight.bold,
                        letterSpacing: context.s(1.5),
                      ),
                    ),
                    SizedBox(height: context.s(6)),
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
                          fontSize: context.s(32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(24.0)),
                  child: Container(
                    width: context.s(1),
                    height: context.s(40),
                    color: Colors.white12,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "BREAK",
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: context.s(10),
                        fontWeight: FontWeight.bold,
                        letterSpacing: context.s(1.5),
                      ),
                    ),
                    SizedBox(height: context.s(6)),
                    Text(
                      breakStr,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: context.s(32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: context.s(24)),
          SizedBox(
            width: double.infinity,
            height: context.s(48),
            child: FilledButton.icon(
              onPressed: () => ref.read(focusProvider.notifier).startSession(),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.s(14)),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
              label: Text(
                "Lets Do This!",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  letterSpacing: context.s(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // History timeline entry
  Widget _buildHistoryTimelineEntry(
    BuildContext context, {
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
            width: context.s(72),
            child: Padding(
              padding: EdgeInsets.only(top: context.s(14.0)),
              child: Text(
                time,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: context.s(12),
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          SizedBox(width: context.s(16)),

          // Timeline node
          SizedBox(
            width: context.s(16),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? context.s(16) : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? context.s(16) : null,
                  child: Container(
                    width: context.s(2),
                    color: accentColor.withAlpha(50),
                  ),
                ),
                Positioned(
                  top: context.s(16),
                  child: Container(
                    width: context.s(10),
                    height: context.s(10),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.s(16)),

          // Entry Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: context.s(16)),
              padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(12)),
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(context.s(14)),
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
                          Icon(Icons.access_time_rounded, color: accentColor, size: context.s(16)),
                          SizedBox(width: context.s(6)),
                          Text(
                            duration,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: context.s(14),
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
                          fontSize: context.s(13),
                        ),
                      ),
                      Text(
                        method,
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: context.s(12),
                        ),
                      ),
                    ],
                  ),
                  if (accomplishments != null && accomplishments.isNotEmpty) ...[
                    SizedBox(height: context.s(8)),
                    const Divider(color: Colors.white10),
                    SizedBox(height: context.s(4)),
                    Text(
                      accomplishments,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: context.s(12),
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
