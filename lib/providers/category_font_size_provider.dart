import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CategoryFontSize {
  smaller,
  normal,
  larger,
}

extension CategoryFontSizeExt on CategoryFontSize {
  double get size {
    switch (this) {
      case CategoryFontSize.smaller:
        return 20.0;
      case CategoryFontSize.normal:
        return 26.0;
      case CategoryFontSize.larger:
        return 32.0;
    }
  }
}

class CategoryFontSizeNotifier extends Notifier<CategoryFontSize> {
  @override
  CategoryFontSize build() {
    _load();
    return CategoryFontSize.normal;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('category_font_size');
    if (val != null) {
      state = CategoryFontSize.values.firstWhere(
        (e) => e.name == val,
        orElse: () => CategoryFontSize.normal,
      );
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
