import 'package:fcl_26_game/src/components/enemy_type.dart';
import 'package:fcl_26_game/src/game/game_config.dart';
import 'package:fcl_26_game/src/systems/spawn_director.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const director = SpawnDirector();

  group('intervalAt', () {
    test('starts at the initial interval and ends at the minimum', () {
      expect(director.intervalAt(0), GameConfig.initialSpawnInterval);
      expect(
        director.intervalAt(GameConfig.spawnRampDuration),
        closeTo(GameConfig.minSpawnInterval, 1e-9),
      );
    });

    test('never drops below the minimum, however long the run lasts', () {
      expect(
        director.intervalAt(GameConfig.spawnRampDuration * 10),
        GameConfig.minSpawnInterval,
      );
    });

    test('decreases monotonically', () {
      var previous = director.intervalAt(0);
      for (var t = 5.0; t <= GameConfig.spawnRampDuration; t += 5) {
        final current = director.intervalAt(t);
        expect(current, lessThan(previous));
        previous = current;
      }
    });
  });

  group('weightsAt', () {
    test('only grunts appear at the start of a run', () {
      final weights = director.weightsAt(0);
      expect(weights[EnemyType.grunt], 1);
      expect(weights[EnemyType.runner], 0);
      expect(weights[EnemyType.tank], 0);
    });

    test('runners and tanks stay locked until their unlock time', () {
      final beforeRunner = director.weightsAt(
        GameConfig.runnerUnlockTime - 0.1,
      );
      expect(beforeRunner[EnemyType.runner], 0);

      final beforeTank = director.weightsAt(GameConfig.tankUnlockTime - 0.1);
      expect(beforeTank[EnemyType.tank], 0);
    });

    test('runners unlock before tanks', () {
      final weights = director.weightsAt(GameConfig.tankUnlockTime - 1);
      expect(weights[EnemyType.runner], greaterThan(0));
      expect(weights[EnemyType.tank], 0);
    });

    test('every type has weight once the run has matured', () {
      final weights = director.weightsAt(300);
      for (final type in EnemyType.values) {
        expect(weights[type], greaterThan(0), reason: '$type should spawn');
      }
    });

    test('the grunt share shrinks over time but never disappears', () {
      final early = director.weightsAt(0)[EnemyType.grunt]!;
      final late = director.weightsAt(300)[EnemyType.grunt]!;
      expect(late, lessThan(early));
      expect(late, greaterThan(0));
    });
  });

  group('pickType', () {
    test('can only return grunts at the start', () {
      for (var roll = 0.0; roll < 1; roll += 0.05) {
        expect(director.pickType(0, roll), EnemyType.grunt);
      }
    });

    test('covers all three types once the run has matured', () {
      final seen = <EnemyType>{};
      for (var roll = 0.0; roll < 1; roll += 0.01) {
        seen.add(director.pickType(300, roll));
      }
      expect(seen, containsAll(EnemyType.values));
    });

    test('is deterministic for a given elapsed time and roll', () {
      expect(director.pickType(120, 0.42), director.pickType(120, 0.42));
    });

    test('handles the boundary rolls without throwing', () {
      expect(director.pickType(300, 0), isNotNull);
      expect(director.pickType(300, 0.999999), isNotNull);
    });
  });

  group('pickEdge', () {
    test('maps the roll range across all four edges', () {
      expect(director.pickEdge(0), WorldEdge.top);
      expect(director.pickEdge(0.3), WorldEdge.right);
      expect(director.pickEdge(0.6), WorldEdge.bottom);
      expect(director.pickEdge(0.99), WorldEdge.left);
    });
  });

  group('spawnPointOn', () {
    const radius = 20.0;

    test('places enemies just outside the edge they come from', () {
      expect(director.spawnPointOn(WorldEdge.top, 0.5, radius).y, -radius);
      expect(director.spawnPointOn(WorldEdge.left, 0.5, radius).x, -radius);
      expect(
        director.spawnPointOn(WorldEdge.bottom, 0.5, radius).y,
        GameConfig.worldHeight + radius,
      );
      expect(
        director.spawnPointOn(WorldEdge.right, 0.5, radius).x,
        GameConfig.worldWidth + radius,
      );
    });

    test('slides the spawn point along the edge with the roll', () {
      final start = director.spawnPointOn(WorldEdge.top, 0, radius);
      final end = director.spawnPointOn(WorldEdge.top, 1, radius);
      expect(start.x, 0);
      expect(end.x, GameConfig.worldWidth);
    });

    test('stays reachable by bullets while walking in', () {
      // Enemies must remain inside the bullet despawn margin, or they could not
      // be shot before they enter the arena.
      for (final edge in WorldEdge.values) {
        final point = director.spawnPointOn(edge, 0.5, radius);
        expect(point.x, greaterThanOrEqualTo(-GameConfig.bulletDespawnMargin));
        expect(point.y, greaterThanOrEqualTo(-GameConfig.bulletDespawnMargin));
        expect(
          point.x,
          lessThanOrEqualTo(
            GameConfig.worldWidth + GameConfig.bulletDespawnMargin,
          ),
        );
        expect(
          point.y,
          lessThanOrEqualTo(
            GameConfig.worldHeight + GameConfig.bulletDespawnMargin,
          ),
        );
      }
    });
  });
}
