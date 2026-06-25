import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/target_date_provider.dart';

class CountdownWidget extends ConsumerWidget {
  const CountdownWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetDate = ref.watch(targetDateProvider);
    final progressColor = ref.watch(overallProgressColorProvider);
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    final daysLeft = difference.inDays > 0 ? difference.inDays : 0;

    return GestureDetector(
      onLongPress: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: targetDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (selected != null) {
          ref.read(targetDateProvider.notifier).setDate(selected);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$daysLeft',
              style: GoogleFonts.jersey15(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: progressColor,
                height: 1.0,
                shadows: [Shadow(color: progressColor.withAlpha(204), blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'DAYS LEFT',
              style: GoogleFonts.jersey15(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
