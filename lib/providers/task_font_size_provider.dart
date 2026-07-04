import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskFontSize {
  level1,
  level2,
  level3,
  level4,
  level5,
}

extension TaskFontSizeExt on TaskFontSize {
  double get scaleFactor => getScaleFactor(1.0);

  double getScaleFactor([double overallScale = 1.0]) {
    double baseScale = 1.0;
    switch (this) {
      case TaskFontSize.level1:
        baseScale = 0.7;
        break;
      case TaskFontSize.level2:
        baseScale = 0.85;
        break;
      case TaskFontSize.level3:
        baseScale = 1.0;
        break;
      case TaskFontSize.level4:
        baseScale = 1.15;
        break;
      case TaskFontSize.level5:
        baseScale = 1.3;
        break;
    }
    return baseScale * overallScale;
  }
}

class TaskFontSizeNotifier extends Notifier<TaskFontSize> {
  @override
  TaskFontSize build() {
    _load();
    return TaskFontSize.level3;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('task_font_size');
    if (val != null) {
      state = TaskFontSize.values.firstWhere(
        (e) => e.name == val,
        orElse: () => TaskFontSize.level3,
      );
    }
  }

  Future<void> setFontSize(TaskFontSize val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('task_font_size', val.name);
    state = val;
  }
}

final taskFontSizeProvider = NotifierProvider<TaskFontSizeNotifier, TaskFontSize>(() {
  return TaskFontSizeNotifier();
});
