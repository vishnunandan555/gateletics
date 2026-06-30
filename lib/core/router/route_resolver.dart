import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';

const bool forceDeskUI = bool.fromEnvironment('FORCE_DESK_UI', defaultValue: false);

// Cached setting loaded synchronously from SharedPreferences before runApp
bool? persistedUserWantsDesktopUI;

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
    // 1. Previous mode user selected (saved in settings) takes first preference
    if (persistedUserWantsDesktopUI != null) {
      return persistedUserWantsDesktopUI! ? '/desk' : '/';
    }

    // 2. Mobile platforms always default to mobile UI
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return '/';
    }

    // 3. Fallback: auto-detect large screen (desktop displays)
    try {
      final view = PlatformDispatcher.instance.views.first;
      final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
      if (logicalWidth > 600) {
        return '/desk';
      }
    } catch (_) {}
  }
  return '/';
}
