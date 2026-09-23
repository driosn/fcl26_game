import 'dart:math' as math;

import 'package:fcl_26_game/src/systems/aiming.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

final _up = Vector2(0, -1);
final _down = Vector2(0, 1);
final _left = Vector2(-1, 0);
final _right = Vector2(1, 0);
final _downRight = Vector2(1, 1)..normalize();
final _upRight = Vector2(1, -1)..normalize();
final _upLeft = Vector2(-1, -1)..normalize();
final _downLeft = Vector2(-1, 1)..normalize();

void main() {
  group('smoothingFactor', () {
    test('stays inside the unit range', () {
      for (final dt in [1 / 240, 1 / 60, 1 / 30, 1.0, 10.0]) {
        expect(Aiming.smoothingFactor(14, dt), inInclusiveRange(0, 1));
      }
    });

    test('moves further the longer the frame', () {
      expect(
        Aiming.smoothingFactor(14, 1 / 30),
        greaterThan(Aiming.smoothingFactor(14, 1 / 60)),
      );
    });

    test('does not depend on the framerate', () {
      // Two half frames have to land in the same place as one whole frame,
      // otherwise the aim would feel different on a 30 Hz and a 144 Hz display.
      const dt = 1 / 60;
      final whole = Aiming.smoothingFactor(14, dt);
      final half = Aiming.smoothingFactor(14, dt / 2);
      expect(1 - (1 - half) * (1 - half), closeTo(whole, 1e-12));
    });

    test('is zero when there is no time or no rate', () {
      expect(Aiming.smoothingFactor(14, 0), 0);
      expect(Aiming.smoothingFactor(0, 1 / 60), 0);
      expect(Aiming.smoothingFactor(-5, 1 / 60), 0);
    });
  });

  group('blendTowards', () {
    test('moves part of the way at a fraction', () {
      final blend = Vector2(0, 0);
      Aiming.blendTowards(blend, _right, 0.25);
      expect(blend.x, closeTo(0.25, 1e-6));
    });

    test('lands on the target at a full step', () {
      final blend = _up.clone();
      Aiming.blendTowards(blend, _right, 1);
      expect(blend.x, closeTo(1, 1e-6));
      expect(blend.y, closeTo(0, 1e-6));
    });

    test('never overshoots, even on an oversized step', () {
      final blend = _up.clone();
      Aiming.blendTowards(blend, _right, 3);
      expect(blend.x, closeTo(1, 1e-6));
      expect(blend.y, closeTo(0, 1e-6));
    });

    test('does nothing without a step', () {
      final blend = _up.clone();
      Aiming.blendTowards(blend, _right, 0);
      expect(blend.x, 0);
      expect(blend.y, -1);
    });
  });

  group('applyBlend', () {
    test('turns the blend into a unit aim', () {
      final aim = _up.clone();
      expect(Aiming.applyBlend(aim, Vector2(0.3, -0.3)), isTrue);
      expect(aim.length, closeTo(1, 1e-6));
      expect(aim.x, closeTo(math.sqrt1_2, 1e-6));
    });

    test('holds the last aim when the blend has no direction left', () {
      final aim = _up.clone();
      expect(Aiming.applyBlend(aim, Vector2(0.001, -0.001)), isFalse);
      expect(aim.y, -1);
    });
  });

  group('aim behaviour', () {
    /// Runs [frames] frames of 60 Hz input, the way [Player] does.
    void hold(Vector2 blend, Vector2 input, int frames) {
      const dt = 1 / 60;
      for (var i = 0; i < frames; i++) {
        Aiming.blendTowards(blend, input, Aiming.smoothingFactor(14, dt));
      }
    }

    test('alternating up and right sweeps the aim around the diagonal', () {
      // The behaviour this whole system exists for: hammering two perpendicular
      // directions should shoot between them, not only along each axis. The aim
      // rocks back and forth, and it is the band it covers that matters, since
      // the weapon fires at arbitrary moments inside it.
      final blend = _up.clone();
      final aim = _up.clone();
      final sum = Vector2.zero();
      var samples = 0;
      var leanedPastDiagonal = false;
      var leanedShortOfDiagonal = false;
      var closestToVertical = 1.0;

      for (var tap = 0; tap < 40; tap++) {
        for (var frame = 0; frame < 3; frame++) {
          hold(blend, tap.isEven ? _right : _up, 1);
          Aiming.applyBlend(aim, blend);
          if (tap < 4) {
            continue; // Let the rocking settle before measuring it.
          }
          sum.add(aim);
          samples++;
          // On the diagonal x == -y, so the sign of the sum says which side of it
          // the aim currently sits on.
          leanedPastDiagonal |= aim.x + aim.y > 0;
          leanedShortOfDiagonal |= aim.x + aim.y < 0;
          closestToVertical = math.min(closestToVertical, aim.x);
        }
      }

      expect(leanedPastDiagonal && leanedShortOfDiagonal, isTrue,
          reason: 'the aim has to cross the diagonal, not stop next to it');
      expect(closestToVertical, greaterThan(0.3),
          reason: 'the aim must never snap back onto the vertical axis');

      final average = sum..scale(1 / samples);
      Aiming.applyBlend(aim, average);
      expect(aim.x, closeTo(math.sqrt1_2, 0.05),
          reason: 'on average it should point down the diagonal, got $aim');
    });

    test('leans towards the new direction on the very first frame', () {
      final blend = _up.clone();
      hold(blend, _right, 1);

      expect(blend.x, greaterThan(0), reason: 'already leaning right');
      expect(blend.y, lessThan(0), reason: 'still leaning up');
    });

    test('holding one direction converges on it', () {
      final blend = _up.clone();
      hold(blend, _right, 60);

      final aim = _up.clone();
      Aiming.applyBlend(aim, blend);
      expect(aim.x, closeTo(1, 0.01));
    });

    test('reaches a held direction in well under half a second', () {
      final blend = _up.clone();
      hold(blend, _right, 18); // 0.3 s

      final aim = _up.clone();
      Aiming.applyBlend(aim, blend);
      expect(aim.x, greaterThan(0.99), reason: 'aiming must not feel sluggish');
    });

    test('a reversal keeps the old aim instead of pointing nowhere', () {
      // Up and down average out to nothing, so there is no direction to read.
      final blend = _up.clone();
      final aim = _up.clone();
      for (var tap = 0; tap < 40; tap++) {
        hold(blend, tap.isEven ? _down : _up, 3);
        Aiming.applyBlend(aim, blend);
      }
      expect(aim.length, closeTo(1, 1e-6));
      expect(aim.x.abs(), lessThan(1e-6), reason: 'stays on the vertical axis');
    });
  });

  group('eightWayIndex', () {
    test('maps the eight stick directions onto distinct poses', () {
      expect(Aiming.eightWayIndex(_down), Aiming.facingDown);
      expect(Aiming.eightWayIndex(_downRight), Aiming.facingDownRight);
      expect(Aiming.eightWayIndex(_right), Aiming.facingRight);
      expect(Aiming.eightWayIndex(_upRight), Aiming.facingUpRight);
      expect(Aiming.eightWayIndex(_up), Aiming.facingUp);
      expect(Aiming.eightWayIndex(_upLeft), Aiming.facingUpLeft);
      expect(Aiming.eightWayIndex(_left), Aiming.facingLeft);
      expect(Aiming.eightWayIndex(_downLeft), Aiming.facingDownLeft);
    });

    test('keeps analog magnitudes on the same pose as the unit stick', () {
      expect(
        Aiming.eightWayIndex(Vector2(0.3, 0.3)),
        Aiming.facingDownRight,
      );
      expect(
        Aiming.eightWayIndex(Vector2(-0.2, -0.8)),
        Aiming.facingUp,
      );
    });

    test('falls back to up when the stick is at rest', () {
      expect(Aiming.eightWayIndex(Vector2.zero()), Aiming.facingUp);
    });
  });

  group('holdEightWay', () {
    test('stays on the current pose while the stick sits on a boundary', () {
      // Exactly halfway between down and down-right. Without hysteresis this
      // would flip every time the analog rest noise crosses the line.
      final seam = Vector2(math.sin(math.pi / 8), math.cos(math.pi / 8));
      expect(
        Aiming.holdEightWay(Aiming.facingDown, seam, hold: 0.20),
        Aiming.facingDown,
      );
      expect(
        Aiming.holdEightWay(Aiming.facingDownRight, seam, hold: 0.20),
        Aiming.facingDownRight,
      );
    });

    test('changes pose once the stick is clearly inside the next sector', () {
      expect(
        Aiming.holdEightWay(Aiming.facingDown, _downRight, hold: 0.20),
        Aiming.facingDownRight,
      );
      expect(
        Aiming.holdEightWay(Aiming.facingRight, _up, hold: 0.20),
        Aiming.facingUp,
      );
    });

    test('holds the last pose when the stick returns to rest', () {
      expect(
        Aiming.holdEightWay(Aiming.facingLeft, Vector2.zero()),
        Aiming.facingLeft,
      );
    });
  });
}
