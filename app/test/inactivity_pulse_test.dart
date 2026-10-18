/// Unit tests for the spec §9 inactivity helper.
///
/// Uses short real durations (no fake clock): the helper is plain Dart
/// timers + a ValueNotifier.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_repair_town_app/widgets/inactivity_pulse.dart';

void main() {
  group('InactivityPulse', () {
    test('fires once after the inactivity window', () async {
      final pulse = InactivityPulse(
        isSuppressed: () => false,
        inactivity: const Duration(milliseconds: 60),
      );
      var fires = 0;
      pulse.signal.addListener(() => fires++);
      pulse.start();
      await Future.delayed(const Duration(milliseconds: 120));
      expect(pulse.fired, isTrue);
      expect(fires, 1);
      // Never repeats, even long after.
      await Future.delayed(const Duration(milliseconds: 150));
      expect(fires, 1);
      pulse.dispose();
    });

    test('reset() restarts the window', () async {
      final pulse = InactivityPulse(
        isSuppressed: () => false,
        inactivity: const Duration(milliseconds: 80),
      );
      pulse.start();
      await Future.delayed(const Duration(milliseconds: 50));
      pulse.reset(); // interaction inside the window
      await Future.delayed(const Duration(milliseconds: 50));
      expect(pulse.fired, isFalse, reason: 'window restarted by interaction');
      await Future.delayed(const Duration(milliseconds: 60));
      expect(pulse.fired, isTrue);
      pulse.dispose();
    });

    test('suppression defers (not drops) the pulse; still fires once',
        () async {
      var suppressed = true;
      final pulse = InactivityPulse(
        isSuppressed: () => suppressed,
        inactivity: const Duration(milliseconds: 60),
      );
      var fires = 0;
      pulse.signal.addListener(() => fires++);
      pulse.start();
      await Future.delayed(const Duration(milliseconds: 120));
      expect(fires, 0, reason: 'must not fire while suppressed');
      suppressed = false; // menu closed / animation finished
      await Future.delayed(const Duration(milliseconds: 120));
      expect(fires, 1, reason: 'fires once conditions allow');
      await Future.delayed(const Duration(milliseconds: 150));
      expect(fires, 1, reason: 'still exactly once');
      pulse.dispose();
    });

    test('pause() stops the countdown until start() resumes', () async {
      final pulse = InactivityPulse(
        isSuppressed: () => false,
        inactivity: const Duration(milliseconds: 60),
      );
      pulse.start();
      pulse.pause();
      await Future.delayed(const Duration(milliseconds: 120));
      expect(pulse.fired, isFalse);
      pulse.start();
      await Future.delayed(const Duration(milliseconds: 120));
      expect(pulse.fired, isTrue);
      pulse.dispose();
    });

    test('dispose() prevents any later fire', () async {
      final pulse = InactivityPulse(
        isSuppressed: () => false,
        inactivity: const Duration(milliseconds: 60),
      );
      var fires = 0;
      pulse.signal.addListener(() => fires++);
      pulse.start();
      pulse.dispose();
      await Future.delayed(const Duration(milliseconds: 120));
      expect(fires, 0);
    });
  });
}
