import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/focus_provider.dart';
import 'focus/focus_idle_view.dart';
import 'focus/focus_active_view.dart';

class FocusScreen extends ConsumerWidget {
  final Color progressColor;

  const FocusScreen({super.key, required this.progressColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(focusProvider);
    final accentColor = progressColor;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: sessionState.status == FocusStatus.idle
              ? FocusIdleView(accentColor: accentColor)
              : FocusActiveView(accentColor: accentColor),
        ),
      ),
    );
  }
}
