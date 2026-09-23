import 'dart:math';

import 'package:flame/components.dart';

import '../components/power_up.dart';
import '../game/brotato_game.dart';
import '../game/game_config.dart';

/// Places the rapid fire pickup on the map on a timer.
///
/// Only one pickup exists at a time; the countdown to the next one starts when
/// the previous one leaves the field, whether it was collected or expired.
class PowerUpSpawner extends Component with HasGameReference<FCLGame> {
  PowerUpSpawner({Random? random})
    : _random = random ?? Random(),
      _timer = GameConfig.firstPowerUpDelay;

  /// How many times to retry before accepting a spot close to the player.
  static const _placementAttempts = 12;

  final Random _random;

  double _timer;
  PowerUp? _current;

  @override
  void update(double dt) {
    super.update(dt);
    if (_current != null && !_current!.isRemoved) {
      return;
    }
    _current = null;

    _timer -= dt;
    if (_timer > 0) {
      return;
    }
    _spawn();
    _timer = _nextInterval();
  }

  void _spawn() {
    final powerUp = PowerUp(position: _pickPosition());
    _current = powerUp;
    game.world.add(powerUp);
  }

  double _nextInterval() {
    const min = GameConfig.minPowerUpInterval;
    const max = GameConfig.maxPowerUpInterval;
    return min + _random.nextDouble() * (max - min);
  }

  /// A spot inside the arena, away from the walls and preferably not right on
  /// top of the player.
  Vector2 _pickPosition() {
    const margin = GameConfig.powerUpEdgeMargin;
    final playerPosition = game.player?.position;
    late Vector2 candidate;

    for (var attempt = 0; attempt < _placementAttempts; attempt++) {
      candidate = Vector2(
        margin + _random.nextDouble() * (GameConfig.worldWidth - margin * 2),
        margin + _random.nextDouble() * (GameConfig.worldHeight - margin * 2),
      );
      if (playerPosition == null ||
          candidate.distanceTo(playerPosition) >=
              GameConfig.powerUpMinDistanceFromPlayer) {
        return candidate;
      }
    }
    return candidate;
  }
}
