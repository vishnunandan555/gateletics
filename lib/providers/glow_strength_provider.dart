import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlowStrengthNotifier extends Notifier<double> {
  @override
  double build() {
    _load();
    return 2.0; // Default strength is 2.0 (200%)
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getDouble('home_glow_strength');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setStrength(double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('home_glow_strength', val);
    state = val;
  }
}

final glowStrengthProvider = NotifierProvider<GlowStrengthNotifier, double>(() {
  return GlowStrengthNotifier();
});
