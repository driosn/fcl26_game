import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../game/brotato_game.dart';
import '../game/game_config.dart';
import '../systems/status_effects.dart';
import 'bullet.dart';
import 'player.dart';

/// Fires on its own, forever, towards wherever its [owner] is facing.
class Weapon extends Component with HasGameReference<FCLGame> {
  Weapon({required this.owner});

  final Player owner;

  final TimedEffect rapidFire = TimedEffect(
    duration: GameConfig.rapidFireDuration,
  );

  double _cooldown = 0;

  /// Seconds between shots right now, including the rapid fire buff.
  double get fireInterval => rapidFire.isActive
      ? GameConfig.baseFireInterval / GameConfig.rapidFireMultiplier
      : GameConfig.baseFireInterval;

  /// Starts the rapid fire window, or restarts it if it is already running.
  void activateRapidFire() => rapidFire.trigger();

  void reset() {
    rapidFire.reset();
    _cooldown = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    rapidFire.update(dt);
    game.state.rapidFireProgress.value = rapidFire.progress;

    if (!owner.isAlive) {
      return;
    }
    _cooldown -= dt;
    if (_cooldown <= 0) {
      _fire();
      _cooldown = fireInterval;
    }
  }

  void _fire() {
    // The muzzle stays on the aim line; only the bullet's heading is scattered.
    final aim = owner.facing.normalized();
    final origin =
        owner.position +
        aim * (GameConfig.playerRadius + GameConfig.pointerGap);

    aim.rotate(
      spreadOffset(game.random.nextDouble(), game.random.nextDouble()),
    );

    // Bullets live in the world, not under the player, so they keep flying
    // straight instead of being dragged along by the shooter.
    game.world.add(Bullet(position: origin, direction: aim));
    owner.notifyFired();
  }

  /// Widest angle, in radians, a shot can deviate from the aim line.
  static const maxSpread = GameConfig.bulletSpreadDegrees * math.pi / 180;

  /// Angular offset applied to a shot, in radians, from two rolls in `[0, 1)`.
  ///
  /// Averaging two uniform rolls gives a triangular distribution: most shots
  /// land near the centre of the cone and only a few reach its edges, which
  /// feels far better than a flat spread where every angle is equally likely.
  @visibleForTesting
  static double spreadOffset(double rollA, double rollB) {
    return ((rollA + rollB) - 1) * maxSpread;
  }
}
