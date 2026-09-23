import 'package:fcl_26_game/src/systems/status_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimedEffect', () {
    test('starts inactive', () {
      final effect = TimedEffect(duration: 15);
      expect(effect.isActive, isFalse);
      expect(effect.remaining, 0);
      expect(effect.progress, 0);
    });

    test('runs for its full duration and then expires', () {
      final effect = TimedEffect(duration: 15)..trigger();
      expect(effect.isActive, isTrue);

      for (var i = 0; i < 14; i++) {
        effect.update(1);
      }
      expect(effect.isActive, isTrue);
      expect(effect.remaining, closeTo(1, 1e-9));

      effect.update(1);
      expect(effect.isActive, isFalse);
      expect(effect.remaining, 0);
    });

    test('never reports a negative remaining time on a long frame', () {
      final effect = TimedEffect(duration: 15)..trigger();
      effect.update(100);
      expect(effect.remaining, 0);
      expect(effect.progress, 0);
    });

    test('re-triggering refreshes the duration instead of stacking', () {
      final effect = TimedEffect(duration: 15)..trigger();
      effect.update(10);
      expect(effect.remaining, closeTo(5, 1e-9));

      effect.trigger();
      expect(effect.remaining, 15);

      // A refresh must not extend the effect beyond one full duration.
      effect.update(15);
      expect(effect.isActive, isFalse);
    });

    test('progress goes from 1 down to 0', () {
      final effect = TimedEffect(duration: 10)..trigger();
      expect(effect.progress, 1);
      effect.update(5);
      expect(effect.progress, closeTo(0.5, 1e-9));
    });

    test('reset cancels an active effect', () {
      final effect = TimedEffect(duration: 15)..trigger();
      effect.reset();
      expect(effect.isActive, isFalse);
    });
  });
}
