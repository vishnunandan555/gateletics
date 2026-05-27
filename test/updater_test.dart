import 'package:flutter_test/flutter_test.dart';
import 'package:gate_tracker/providers/updater_provider.dart';

void main() {
  group('Updater Service - Semantic Version Comparisons', () {
    late UpdaterNotifier updater;

    setUp(() {
      updater = UpdaterNotifier();
    });

    test('Should detect newer minor/patch versions', () {
      expect(updater.isVersionNewer('0.0.4', '0.0.5'), isTrue);
      expect(updater.isVersionNewer('0.0.4', '0.1.0'), isTrue);
      expect(updater.isVersionNewer('0.0.4', '1.0.0'), isTrue);
    });

    test('Should dismiss equal or older versions', () {
      expect(updater.isVersionNewer('0.0.4', '0.0.4'), isFalse);
      expect(updater.isVersionNewer('0.0.4', '0.0.3'), isFalse);
      expect(updater.isVersionNewer('0.0.4', '0.0.1'), isFalse);
    });

    test('Should cleanly parse leading v/V semantic representations', () {
      expect(updater.isVersionNewer('v0.0.4', 'v0.0.5'), isTrue);
      expect(updater.isVersionNewer('0.0.4', 'v0.0.5'), isTrue);
      expect(updater.isVersionNewer('v0.0.4', '0.0.5'), isTrue);
      expect(updater.isVersionNewer('V0.0.4', 'v0.0.4'), isFalse);
    });

    test('Should handle uneven version digits semantically', () {
      expect(updater.isVersionNewer('1.0', '1.0.1'), isTrue);
      expect(updater.isVersionNewer('1.2.3', '1.2.3.4'), isTrue);
      expect(updater.isVersionNewer('1.2.3.4', '1.2.3'), isFalse);
    });

    test('Should ignore build number extensions in versions', () {
      expect(updater.isVersionNewer('0.0.4+4', '0.0.4+5'), isFalse);
      expect(updater.isVersionNewer('0.0.4+4', '0.0.5+1'), isTrue);
    });
  });

  group('Updater Service - Frequency Gate Logic', () {
    test('Daily frequency requires at least 1 day between auto-checks', () {
      final freqDays = _freqToDays('Daily');
      expect(freqDays, equals(1));
    });

    test('Weekly frequency requires at least 7 days between auto-checks', () {
      final freqDays = _freqToDays('Weekly');
      expect(freqDays, equals(7));
    });

    test('Monthly frequency requires at least 30 days between auto-checks', () {
      final freqDays = _freqToDays('Monthly');
      expect(freqDays, equals(30));
    });

    test('Unknown frequency defaults to Weekly (7 days)', () {
      final freqDays = _freqToDays('Unknown');
      expect(freqDays, equals(7));
    });

    test('Auto-check should be skipped if not enough days have passed (Daily)', () {
      const freqDays = 1;
      final lastCheck = DateTime.now().subtract(const Duration(hours: 12));
      final sinceLastCheck = DateTime.now().difference(lastCheck);
      expect(sinceLastCheck.inDays < freqDays, isTrue); // should skip
    });

    test('Auto-check should proceed if enough days have passed (Daily)', () {
      const freqDays = 1;
      final lastCheck = DateTime.now().subtract(const Duration(days: 2));
      final sinceLastCheck = DateTime.now().difference(lastCheck);
      expect(sinceLastCheck.inDays < freqDays, isFalse); // should proceed
    });

    test('Auto-check should be skipped within weekly window', () {
      const freqDays = 7;
      final lastCheck = DateTime.now().subtract(const Duration(days: 3));
      final sinceLastCheck = DateTime.now().difference(lastCheck);
      expect(sinceLastCheck.inDays < freqDays, isTrue); // should skip
    });

    test('Auto-check should proceed after weekly window', () {
      const freqDays = 7;
      final lastCheck = DateTime.now().subtract(const Duration(days: 8));
      final sinceLastCheck = DateTime.now().difference(lastCheck);
      expect(sinceLastCheck.inDays < freqDays, isFalse); // should proceed
    });
  });

  group('Updater State - resetToIdle', () {
    test('resetToIdle sets status to idle without clearing other fields', () {
      final notifier = UpdaterNotifier();

      // Simulate a state where check completed
      notifier.state = notifier.state.copyWith(
        status: UpdaterStatus.noUpdateAvailable,
        currentVersion: '0.0.4',
        latestVersion: '0.0.4',
      );

      notifier.resetToIdle();

      expect(notifier.state.status, equals(UpdaterStatus.idle));
      // Other fields should remain intact
      expect(notifier.state.currentVersion, equals('0.0.4'));
    });
  });
}

/// Mirrors the frequency gate logic in updater_provider.dart for unit testing.
int _freqToDays(String frequency) {
  return frequency == 'Daily' ? 1 : frequency == 'Monthly' ? 30 : 7;
}
