import 'dart:io' show Platform;
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

  // 1. Check user preference saved in settings (applicable to both Web and native Desktop)
  if (persistedUserWantsDesktopUI != null) {
    return persistedUserWantsDesktopUI! ? '/desk' : '/';
  }

  // 2. Mobile platforms always default to mobile UI (Android/iOS)
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return '/';
  }

  // 3. Desktop layouts (Windows, Linux, macOS, Web on large screens)
  if (kIsWeb) {
    try {
      final view = PlatformDispatcher.instance.views.first;
      final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
      if (logicalWidth > 600) {
        return '/desk';
      }
    } catch (_) {}
  } else {
    // Native Desktop app (Windows/Linux) defaults to desktop UI
    return '/desk';
  }

  return '/';
}
