import 'dart:math';

import 'package:flame/components.dart';

import '../components/enemy.dart';
import '../components/enemy_type.dart';
import '../game/brotato_game.dart';
import '../game/game_config.dart';
import 'spawn_director.dart';

/// Drops enemies into the world one at a time, from a random screen edge.
///
/// The component is only the clock; every decision about pacing and enemy mix
/// lives in [SpawnDirector].
class EnemySpawner extends Component with HasGameReference<FCLGame> {
  EnemySpawner({Random? random, SpawnDirector director = const SpawnDirector()})
    : _random = random ?? Random(),
      _director = director,
      _timer = GameConfig.firstEnemyDelay;

  final Random _random;
  final SpawnDirector _director;

  double _timer;

  @override
  void update(double dt) {
    super.update(dt);
    _timer -= dt;
    if (_timer > 0) {
      return;
    }
    _spawn();
    _timer = _director.intervalAt(game.state.elapsed);
  }

  void _spawn() {
    final elapsed = game.state.elapsed;
    final stats = EnemyStats.of(
      _director.pickType(elapsed, _random.nextDouble()),
    );
    final edge = _director.pickEdge(_random.nextDouble());
    final position = _director.spawnPointOn(
      edge,
      _random.nextDouble(),
      stats.radius,
    );
    game.world.add(Enemy(stats: stats, position: position));
  }
}
