import 'package:flutter/foundation.dart';


// Cached setting loaded synchronously from SharedPreferences before runApp
bool? persistedUserWantsDesktopUI;

String resolveInitialRoute() {
  // 1. Native Mobile (Android, iOS) -> ALWAYS Mobile UI ('/')
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
       defaultTargetPlatform == TargetPlatform.iOS)) {
    return '/';
  }

  // 2. Native Desktop (Windows, Linux, macOS) -> ALWAYS Desktop UI ('/desk')
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.linux ||
       defaultTargetPlatform == TargetPlatform.macOS)) {
    return '/desk';
  }

  // 3. Web Target -> Adaptive layout resolution
  if (kIsWeb) {
    if (persistedUserWantsDesktopUI != null) {
      return persistedUserWantsDesktopUI! ? '/desk' : '/';
    }
    try {
      final path = Uri.base.path;
      if (path.contains('/desk')) {
        return '/desk';
      }
      final view = PlatformDispatcher.instance.views.first;
      final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
      if (logicalWidth > 600) {
        return '/desk';
      }
    } catch (_) {}
  }

  return '/';
}
