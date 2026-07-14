import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../../providers/focus_provider.dart';
import '../../../../providers/daily_history_provider.dart';
import '../../../../providers/rollover_provider.dart';
import '../../../../providers/category_autosort_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../database/app_database.dart';

class TimerSettingsSection extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const TimerSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accentColor,
  });

  void _showFocusGoalDialog(BuildContext context, WidgetRef ref, int currentGoalMins, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Daily Study Goal',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [30, 60, 90, 120, 180, 240, 300, 360, 480].map((mins) {
              final isSelected = mins == currentGoalMins;
              final hrs = mins / 60;
              final label = hrs % 1 == 0 ? '${hrs.toInt()} hours' : '$hrs hours';
              return ListTile(
                title: Text(
                  '$label${mins == 120 ? ' (default)' : ''}',
                  style: GoogleFonts.outfit(
                    color: isSelected ? accentColor : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: accentColor) : null,
                onTap: () {
                  ref.read(dailyFocusGoalProvider.notifier).setGoalMinutes(mins);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCheckInGoalDialog(BuildContext context, WidgetRef ref, int currentMins, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Daily Check-in Goal',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [5, 10, 15, 20, 30, 45].map((mins) {
              final isSelected = mins == currentMins;
              return ListTile(
                title: Text(
                  '$mins minutes${mins == 15 ? ' (default)' : ''}',
                  style: GoogleFonts.outfit(
                    color: isSelected ? accentColor : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: accentColor) : null,
                onTap: () {
                  ref.read(checkInGoalMinutesProvider.notifier).setMinutes(mins);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showDevInjectDialog(BuildContext context, WidgetRef ref, Color accentColor) {
    DateTime selectedDate = DateTime.now();
    final durationController = TextEditingController(text: "60");
    final goalController = TextEditingController(text: "120");

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF18181B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Dev: Inject Study Session",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Date: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                          style: GoogleFonts.outfit(color: Colors.white70),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: accentColor),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) {
                              setState(() {
                                selectedDate = d;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Duration (Minutes)",
                        labelStyle: GoogleFonts.outfit(color: Colors.white60),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      ),
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: goalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Daily Goal (Minutes)",
                        labelStyle: GoogleFonts.outfit(color: Colors.white60),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      ),
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text("Cancel", style: TextStyle(color: accentColor)),
                ),
                TextButton(
                  onPressed: () async {
                    final durationMin = int.tryParse(durationController.text) ?? 60;
                    final goalMin = int.tryParse(goalController.text) ?? 120;

                    final db = ref.read(appDatabaseProvider);
                    final rollover = ref.read(studyDayRolloverProvider);

                    final startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0);

                    await db.into(db.focusSessions).insert(FocusSessionsCompanion.insert(
                      method: "Freestyle",
                      startTime: startTime,
                      durationSeconds: durationMin * 60,
                      accomplishments: const Value("Developer Mode injected study session"),
                    ));

                    final studyDayStart = getStudyDayStart(startTime, rollover: rollover);
                    final studyDayEnd = studyDayStart.add(const Duration(hours: 24));
                    final sessions = await (db.select(db.focusSessions)
                          ..where((t) => t.startTime.isBiggerOrEqualValue(studyDayStart) & t.startTime.isSmallerThanValue(studyDayEnd)))
                        .get();
                    final totalSeconds = sessions.fold(0, (sum, s) => sum + s.durationSeconds);

                    final studyDay = studyDayFor(startTime, rollover);
                    final dateStr = "${studyDay.year}-${studyDay.month.toString().padLeft(2, '0')}-${studyDay.day.toString().padLeft(2, '0')}";

                    await db.upsertDailyHistory(
                      dateStr: dateStr,
                      totalFocusSeconds: totalSeconds,
                      targetGoalSeconds: goalMin * 60,
                      isGoalCompleted: totalSeconds >= (goalMin * 60),
                      syllabusProgressPct: 50.0,
                    );

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✓ Study session injected successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text("Inject", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSort = ref.watch(categoryAutoSortProvider);
    final focusGoalMins = ref.watch(dailyFocusGoalProvider);
    final checkInMins = ref.watch(checkInGoalMinutesProvider);
    final rollover = ref.watch(studyDayRolloverProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          activeThumbColor: accentColor,
          secondary: Icon(Icons.sort_rounded, color: accentColor),
          title: Text('Auto-Sort Categories', style: titleStyle),
          subtitle: Text(
            'Move recently studied categories to the top automatically',
            style: subtitleStyle,
          ),
          value: autoSort,
          onChanged: (val) {
            ref.read(categoryAutoSortProvider.notifier).setAutoSort(val);
          },
        ),
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
          title: Text('Syllabus Checklist Preset', style: titleStyle),
          subtitle: Text(
            'Reset and apply the default standard GATE checklist preset',
            style: subtitleStyle,
          ),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Text('Apply Syllabus Preset'),
                content: const Text(
                  'This will reset and overwrite all current syllabus categories and checklist progress. Continue?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await ref.read(syllabusControllerProvider.notifier).applyPreset();
            }
          },
        ),
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: Icon(Icons.track_changes_rounded, color: accentColor),
          title: Text('Daily Study Goal', style: titleStyle),
          subtitle: Text(
            'Daily targeted countdown goal. Default is 2 hours.',
            style: subtitleStyle,
          ),
          trailing: Text(
            '${(focusGoalMins / 60).toStringAsFixed(1).replaceFirst('.0', '')} hrs',
            style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onTap: () => _showFocusGoalDialog(context, ref, focusGoalMins, accentColor),
        ),
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: Icon(Icons.task_alt_rounded, color: accentColor),
          title: Text('Daily Check-in Goal', style: titleStyle),
          subtitle: Text(
            'Minimum focused study duration required to mark check-in streak.',
            style: subtitleStyle,
          ),
          trailing: Text(
            '$checkInMins mins',
            style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onTap: () => _showCheckInGoalDialog(context, ref, checkInMins, accentColor),
        ),
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: Icon(Icons.alarm_rounded, color: accentColor),
          title: Text('Overnight Rollover Hour', style: titleStyle),
          subtitle: Text(
            'Hour of the day (0-23) when tracking transitions to the next day. Enables post-midnight study tracking.',
            style: subtitleStyle,
          ),
          trailing: Text(
            rollover == StudyDayRollover.midnight ? 'Midnight (12 AM)' : '04:00 AM',
            style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onTap: () async {
            final result = await showDialog<StudyDayRollover>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: const Text('Set Rollover Hour'),
                backgroundColor: const Color(0xFF18181B),
                children: [
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, StudyDayRollover.midnight),
                    child: Text('00:00 (12:00 AM - default)', style: TextStyle(color: rollover == StudyDayRollover.midnight ? accentColor : Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, StudyDayRollover.overnight),
                    child: Text('04:00 AM', style: TextStyle(color: rollover == StudyDayRollover.overnight ? accentColor : Colors.white)),
                  ),
                ],
              ),
            );
            if (result != null) {
              await ref.read(studyDayRolloverProvider.notifier).setRollover(result);
            }
          },
        ),
        if (kDebugMode) ...[
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            leading: Icon(Icons.developer_mode_rounded, color: accentColor),
            title: Text('Inject Mock Session', style: titleStyle),
            subtitle: Text(
              'Generate fake study sessions for testing statistics and charts',
              style: subtitleStyle,
            ),
            onTap: () => _showDevInjectDialog(context, ref, accentColor),
          ),
        ]
      ],
    );
  }
}
