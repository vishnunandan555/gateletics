import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/subject_provider.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key});

  Future<void> _handleLongPress(BuildContext context) async {
    final bool? shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open GitHub Repo?'),
        content: const Text('Would you like to visit the project repository on GitHub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      final Uri url = Uri.parse('https://github.com/vishnunandan555/gate-tracker');
      if (!await launchUrl(url)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the link.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _handleLongPress(context),
      child: Column(
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
                'v1.0.0 ',
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
      ),
    );
  }
}
