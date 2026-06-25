import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_completed_setup') ?? false;
  }

  Future<void> completeSetup() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_setup', true);
    state = const AsyncValue.data(true);
  }

  Future<void> resetSetup() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_setup', false);
    state = const AsyncValue.data(false);
  }
}

final setupCompletedProvider = AsyncNotifierProvider<SetupNotifier, bool>(() {
  return SetupNotifier();
});
