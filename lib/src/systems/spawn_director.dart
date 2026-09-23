import 'package:flame/components.dart';

import '../components/enemy_type.dart';
import '../game/game_config.dart';

enum WorldEdge { top, right, bottom, left }

/// Decides *what* and *where* to spawn, given only the elapsed run time and
/// random rolls.
///
/// All difficulty scaling lives here as pure functions of time: no hidden state,
/// no Flame dependency, fully unit testable. [EnemySpawner] is just the component
/// that calls into it on a timer.
class SpawnDirector {
  const SpawnDirector();

  /// Seconds between spawns, ramping from [GameConfig.initialSpawnInterval] down
  /// to [GameConfig.minSpawnInterval] over [GameConfig.spawnRampDuration].
  double intervalAt(double elapsed) {
    final t = _progress(elapsed, 0, GameConfig.spawnRampDuration);
    // Written as a weighted average rather than `a + (b - a) * t` so that a
    // fully ramped run lands exactly on the minimum instead of a float near it.
    return GameConfig.initialSpawnInterval * (1 - t) +
        GameConfig.minSpawnInterval * t;
  }

  /// Relative spawn weights per type at [elapsed].
  ///
  /// At the start only grunts appear; runners unlock at
  /// [GameConfig.runnerUnlockTime] and tanks at [GameConfig.tankUnlockTime],
  /// each fading in over [GameConfig.enemyWeightRampDuration] while the grunt
  /// share shrinks.
  Map<EnemyType, double> weightsAt(double elapsed) {
    final ramp = GameConfig.enemyWeightRampDuration;
    final maturity = _progress(elapsed, 0, GameConfig.spawnRampDuration);
    return {
      EnemyType.grunt: 1.0 - 0.55 * maturity,
      EnemyType.runner:
          0.35 * _progress(elapsed, GameConfig.runnerUnlockTime, ramp),
      EnemyType.tank:
          0.20 * _progress(elapsed, GameConfig.tankUnlockTime, ramp),
    };
  }

  /// Picks a type using [roll] in `[0, 1)` against the weights at [elapsed].
  EnemyType pickType(double elapsed, double roll) {
    final weights = weightsAt(elapsed);
    final total = weights.values.fold(0.0, (sum, w) => sum + w);
    var threshold = roll.clamp(0.0, 1.0) * total;
    // Iterating the enum rather than the map keeps the outcome deterministic.
    for (final type in EnemyType.values) {
      threshold -= weights[type] ?? 0;
      if (threshold <= 0) {
        return type;
      }
    }
    return EnemyType.grunt;
  }

  WorldEdge pickEdge(double roll) {
    final index = (roll.clamp(0.0, 0.999) * WorldEdge.values.length).floor();
    return WorldEdge.values[index];
  }

  /// A point just outside [edge], so the enemy visibly walks into the arena
  /// instead of popping into existence.
  ///
  /// [alongRoll] in `[0, 1)` slides the point along that edge.
  Vector2 spawnPointOn(WorldEdge edge, double alongRoll, double radius) {
    final t = alongRoll.clamp(0.0, 1.0);
    return switch (edge) {
      WorldEdge.top => Vector2(GameConfig.worldWidth * t, -radius),
      WorldEdge.bottom =>
        Vector2(GameConfig.worldWidth * t, GameConfig.worldHeight + radius),
      WorldEdge.left => Vector2(-radius, GameConfig.worldHeight * t),
      WorldEdge.right =>
        Vector2(GameConfig.worldWidth + radius, GameConfig.worldHeight * t),
    };
  }

  /// Ramps from 0 to 1 between [start] and `start + duration`.
  double _progress(double elapsed, double start, double duration) =>
      ((elapsed - start) / duration).clamp(0.0, 1.0);
}
