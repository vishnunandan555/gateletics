import 'package:flutter/material.dart';
import '../providers/telemetry_service.dart';

class TelemetryLifecycleObserver extends StatefulWidget {
  final Widget child;

  const TelemetryLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  State<TelemetryLifecycleObserver> createState() =>
      _TelemetryLifecycleObserverState();
}

class _TelemetryLifecycleObserverState extends State<TelemetryLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer the initial launch ping until after the first frame has successfully rendered.
    // This frees up native platform channels during critical startup phases, ensuring
    // a faster and more responsive initial app launch experience.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TelemetryService.triggerLaunchPing();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("[Telemetry] App resumed/focused. Checking daily telemetry active user status...");
      TelemetryService.triggerLaunchPing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
