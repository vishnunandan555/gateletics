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
  double get size {
    switch (this) {
      case CategoryFontSize.level1:
        return 14.0;
      case CategoryFontSize.level2:
        return 17.0;
      case CategoryFontSize.level3:
        return 20.0;
      case CategoryFontSize.level4:
        return 23.0;
      case CategoryFontSize.level5:
        return 26.0;
    }
  }

  double get scaleFactor {
    switch (this) {
      case CategoryFontSize.level1:
        return 14.0 / 26.0;
      case CategoryFontSize.level2:
        return 17.0 / 26.0;
      case CategoryFontSize.level3:
        return 20.0 / 26.0;
      case CategoryFontSize.level4:
        return 23.0 / 26.0;
      case CategoryFontSize.level5:
        return 1.0;
    }
  }

  double get topicScaleFactor {
    switch (this) {
      case CategoryFontSize.level1:
        return 17.0 / 26.0;
      case CategoryFontSize.level2:
        return 20.0 / 26.0;
      case CategoryFontSize.level3:
        return 23.0 / 26.0;
      case CategoryFontSize.level4:
        return 1.0;
      case CategoryFontSize.level5:
        return 29.0 / 26.0;
    }
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
