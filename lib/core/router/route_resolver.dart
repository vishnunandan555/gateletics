import 'package:flutter/foundation.dart';

String resolveInitialRoute() {
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
