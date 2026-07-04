import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CategoryFontSize {
  level1,
  level2,
  level3,
  level4,
  level5,
}

extension CategoryFontSizeExt on CategoryFontSize {
  double get size => getSize(1.0);
  double get scaleFactor => getScaleFactor(1.0);

  double getSize([double overallScale = 1.0]) {
    double baseSize = 22.0;
    switch (this) {
      case CategoryFontSize.level1:
        baseSize = 16.0;
        break;
      case CategoryFontSize.level2:
        baseSize = 19.0;
        break;
      case CategoryFontSize.level3:
        baseSize = 22.0;
        break;
      case CategoryFontSize.level4:
        baseSize = 25.0;
        break;
      case CategoryFontSize.level5:
        baseSize = 28.0;
        break;
    }
    return baseSize * overallScale;
  }

  double getScaleFactor([double overallScale = 1.0]) {
    double baseScale = 1.0;
    switch (this) {
      case CategoryFontSize.level1:
        baseScale = 16.0 / 28.0;
        break;
      case CategoryFontSize.level2:
        baseScale = 19.0 / 28.0;
        break;
      case CategoryFontSize.level3:
        baseScale = 22.0 / 28.0;
        break;
      case CategoryFontSize.level4:
        baseScale = 25.0 / 28.0;
        break;
      case CategoryFontSize.level5:
        baseScale = 1.0;
        break;
    }
    return baseScale * overallScale;
  }

  double getTopicScaleFactor([double overallScale = 1.0]) {
    double baseScale = 1.0;
    switch (this) {
      case CategoryFontSize.level1:
        baseScale = 17.0 / 26.0;
        break;
      case CategoryFontSize.level2:
        baseScale = 20.0 / 26.0;
        break;
      case CategoryFontSize.level3:
        baseScale = 23.0 / 26.0;
        break;
      case CategoryFontSize.level4:
        baseScale = 1.0;
        break;
      case CategoryFontSize.level5:
        baseScale = 29.0 / 26.0;
        break;
    }
    return baseScale * overallScale;
  }
}

class CategoryFontSizeNotifier extends Notifier<CategoryFontSize> {
  @override
  CategoryFontSize build() {
    _load();
    return CategoryFontSize.level3;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('category_font_size');
    if (val != null) {
      if (val == 'smaller' || val == 'small' || val == 'level3') {
        state = CategoryFontSize.level3;
      } else if (val == 'xxSmall' || val == 'level1') {
        state = CategoryFontSize.level1;
      } else if (val == 'xSmall' || val == 'level2') {
        state = CategoryFontSize.level2;
      } else if (val == 'medium' || val == 'level4') {
        state = CategoryFontSize.level4;
      } else if (val == 'normal' || val == 'larger' || val == 'level5') {
        state = CategoryFontSize.level5;
      } else {
        state = CategoryFontSize.values.firstWhere(
          (e) => e.name == val,
          orElse: () => CategoryFontSize.level3,
        );
      }
    }
  }

  Future<void> setFontSize(CategoryFontSize val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category_font_size', val.name);
    state = val;
  }
}

final categoryFontSizeProvider = NotifierProvider<CategoryFontSizeNotifier, CategoryFontSize>(() {
  return CategoryFontSizeNotifier();
});
