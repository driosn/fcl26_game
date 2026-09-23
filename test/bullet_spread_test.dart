import 'dart:math' as math;

import 'package:fcl_26_game/src/components/weapon.dart';
import 'package:fcl_26_game/src/game/game_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Weapon.maxSpread', () {
    test('matches the configured cone in radians', () {
      expect(
        Weapon.maxSpread,
        closeTo(GameConfig.bulletSpreadDegrees * math.pi / 180, 1e-12),
      );
    });
  });

  group('Weapon.spreadOffset', () {
    test('middling rolls shoot straight down the aim line', () {
      expect(Weapon.spreadOffset(0.5, 0.5), 0);
    });

    test('the extreme rolls reach exactly the edges of the cone', () {
      expect(Weapon.spreadOffset(0, 0), closeTo(-Weapon.maxSpread, 1e-12));
      expect(Weapon.spreadOffset(1, 1), closeTo(Weapon.maxSpread, 1e-12));
    });

    test('never leaves the cone, for any pair of rolls', () {
      for (var a = 0.0; a <= 1; a += 0.05) {
        for (var b = 0.0; b <= 1; b += 0.05) {
          expect(
            Weapon.spreadOffset(a, b).abs(),
            lessThanOrEqualTo(Weapon.maxSpread + 1e-12),
            reason: 'rolls ($a, $b) escaped the cone',
          );
        }
      }
    });

    test('is symmetric around the aim line', () {
      expect(
        Weapon.spreadOffset(0.2, 0.3),
        closeTo(-Weapon.spreadOffset(0.8, 0.7), 1e-12),
      );
    });

    test('clusters near the centre rather than spreading evenly', () {
      // The triangular distribution is the whole point: a flat spread would put
      // as many shots at the edge of the cone as down the middle, which reads as
      // a shotgun rather than slightly loose aim.
      final random = math.Random(7);
      var nearCentre = 0;
      var nearEdge = 0;
      const samples = 20000;

      for (var i = 0; i < samples; i++) {
        final offset =
            Weapon.spreadOffset(random.nextDouble(), random.nextDouble()).abs();
        if (offset < Weapon.maxSpread / 3) {
          nearCentre++;
        } else if (offset > Weapon.maxSpread * 2 / 3) {
          nearEdge++;
        }
      }

      expect(nearCentre, greaterThan(nearEdge * 3));
    });

    test('a seeded weapon produces a repeatable pattern of shots', () {
      List<double> sample(int seed) {
        final random = math.Random(seed);
        return List.generate(
          10,
          (_) => Weapon.spreadOffset(random.nextDouble(), random.nextDouble()),
        );
      }

      expect(sample(42), sample(42));
      expect(sample(42), isNot(sample(43)));
    });
  });
}
