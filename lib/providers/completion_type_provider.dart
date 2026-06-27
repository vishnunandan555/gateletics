import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CompletionType {
  resource,
  syllabus,
}

class CompletionTypeNotifier extends Notifier<CompletionType> {
  @override
  CompletionType build() {
    _load();
    return CompletionType.syllabus;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('completion_type');
    if (val != null) {
      state = CompletionType.values.firstWhere(
        (e) => e.name == val,
        orElse: () => CompletionType.syllabus,
      );
    }
  }

  Future<void> setCompletionType(CompletionType val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('completion_type', val.name);
    state = val;
  }
}

final completionTypeProvider = NotifierProvider<CompletionTypeNotifier, CompletionType>(() {
  return CompletionTypeNotifier();
});
