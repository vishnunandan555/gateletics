import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

const bool forceDeskUI = bool.fromEnvironment('FORCE_DESK_UI', defaultValue: false);

String resolveInitialRoute() {
  if (forceDeskUI) {
    return '/desk';
  }
  if (!kIsWeb) {
    try {
      if (Platform.environment['FORCE_DESK_UI'] == 'true') {
        return '/desk';
      }
    } catch (_) {}
  }
  if (kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return '/';
    }
    if (Uri.base.path.contains('/desk') || Uri.base.pathSegments.contains('desk')) {
      return '/desk';
    }
  }
  return '/';
}
