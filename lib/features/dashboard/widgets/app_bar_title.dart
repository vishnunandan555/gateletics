import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/subject_provider.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'GATE\nPROGRESS\nTRACKER',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BatmanForever',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'v1.1.1 ',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            Consumer(
              builder: (context, ref, _) {
                final progressColor = ref.watch(overallProgressColorProvider);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: progressColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Stable',
                    style: TextStyle(color: progressColor, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
