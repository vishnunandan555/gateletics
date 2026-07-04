import 'package:flutter/material.dart';

extension ScaleExtension on BuildContext {
  double get _screenWidth => MediaQuery.sizeOf(this).width;

  double get scaleFactor {
    // 412.0 is the logical width of standard modern Android/iOS screens (e.g. Pixel 10 Pro)
    // where the user says the UI layout looks perfect.
    const baseWidth = 412.0;
    
    // Clamp standard mobile widths to prevent extreme sizing on wearables or desktop
    final clampedWidth = _screenWidth.clamp(320.0, 520.0);
    return clampedWidth / baseWidth;
  }

  /// Scales a layout/coordinate size value based on screen width.
  double s(double value) => value * scaleFactor;

  /// Scales a TextStyle's font size based on screen width.
  TextStyle scaleText(TextStyle style) {
    if (style.fontSize == null) return style;
    return style.copyWith(fontSize: style.fontSize! * scaleFactor);
  }
}
