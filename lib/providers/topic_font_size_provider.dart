import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TopicFontSize {
  level1,
  level2,
  level3,
  level4,
  level5,
}

extension TopicFontSizeExt on TopicFontSize {
  double get scaleFactor {
    switch (this) {
      case TopicFontSize.level1:
        return 17.0 / 26.0;
      case TopicFontSize.level2:
        return 20.0 / 26.0;
      case TopicFontSize.level3:
        return 23.0 / 26.0;
      case TopicFontSize.level4:
        return 1.0;
      case TopicFontSize.level5:
        return 29.0 / 26.0;
    }
  }
}

class TopicFontSizeNotifier extends Notifier<TopicFontSize> {
  @override
  TopicFontSize build() {
    _load();
    return TopicFontSize.level3;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('topic_font_size');
    if (val != null) {
      state = TopicFontSize.values.firstWhere(
        (e) => e.name == val,
        orElse: () => TopicFontSize.level3,
      );
    }
  }

  Future<void> setFontSize(TopicFontSize val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('topic_font_size', val.name);
    state = val;
  }
}

final topicFontSizeProvider = NotifierProvider<TopicFontSizeNotifier, TopicFontSize>(() {
  return TopicFontSizeNotifier();
});
