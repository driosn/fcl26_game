import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/brotato_game.dart';
import '../game/game_config.dart';
import '../theme/game_palette.dart';
import 'enemy_type.dart';
import 'rive_world_visual.dart';

/// An enemy that walks straight at the player until it runs out of health.
///
/// All of its numbers come from [stats], so the three variants share this one
/// behaviour implementation.
class Enemy extends PositionComponent
    with CollisionCallbacks, HasGameReference<FCLGame> {
  Enemy({required this.stats, required super.position})
    : _health = stats.hitsToKill,
      super(
        anchor: Anchor.center,
        size: Vector2.all(stats.radius * 2),
        priority: 4,
      );

  static const _hitFlashDuration = 0.09;

  final EnemyStats stats;

  int _health;
  double _hitFlash = 0;

  /// Set the moment the enemy dies, so a second bullet landing in the same tick
  /// cannot score the same kill twice.
  bool _isDead = false;

  /// Counts down while the death pop plays; the corpse is removed at zero.
  double _deathLeft = 0;

  CircleHitbox? _hitbox;

  /// Reused each frame to avoid allocating a vector per enemy per tick.
  final Vector2 _towardsPlayer = Vector2.zero();

  /// Radians, 0 pointing right. The skin leans the bug's visor this way.
  double _heading = 0;

  RiveWorldVisual? _riveVisual;

  bool get usesRiveVisual => _riveVisual != null;

  /// False once the kill is scored, even while the corpse is still fading out.
  bool get isAlive => !_isDead;

  @override
  void onLoad() {
    // Solid, because Flame reports no intersection when one circle sits entirely
    // inside another. Without this a bullet that lands deep inside an enemy in a
    // single step would pass straight through it.
    add(_hitbox = CircleHitbox(isSolid: true));
    final visual = game.enableRive ? game.rive.createEnemy(stats) : null;
    if (visual != null) {
      visual.position = size / 2;
      add(_riveVisual = visual);
    }
  }

  /// Enemies should not be checked against each other; they only care about
  /// bullets and the player.
  @override
  bool onComponentTypeCheck(PositionComponent other) => other is! Enemy;

  @override
  void update(double dt) {
    super.update(dt);
    if (_hitFlash > 0) {
      _hitFlash = math.max(0, _hitFlash - dt);
    }

    if (_isDead) {
      _deathLeft -= dt;
      _riveVisual?.sync(
        speed: 0,
        hurt: false,
        lookX: math.cos(_heading),
        health: 0,
        dead: true,
      );
      if (_deathLeft <= 0) {
        removeFromParent();
      }
      return;
    }

    var moving = 0.0;
    final player = game.player;
    if (player != null && player.isAlive) {
      _towardsPlayer
        ..setFrom(player.position)
        ..sub(position);
      if (_towardsPlayer.length2 > 0.01) {
        _towardsPlayer.normalize();
        _heading = math.atan2(_towardsPlayer.y, _towardsPlayer.x);
        position.addScaled(_towardsPlayer, stats.speed * dt);
        moving = 1;
      }
    }
    _riveVisual?.sync(
      speed: moving,
      hurt: _hitFlash > 0,
      lookX: math.cos(_heading),
      health: _health / stats.hitsToKill,
    );
  }

  void takeDamage(int amount) {
    if (_isDead) {
      return;
    }
    _health -= amount;
    _hitFlash = _hitFlashDuration;
    if (_health <= 0) {
      _isDead = true;
      _deathLeft = GameConfig.enemyDeathDuration;
      _hitbox?.collisionType = CollisionType.inactive;
      game.onEnemyKilled(this);
      _riveVisual?.sync(
        speed: 0,
        hurt: false,
        lookX: math.cos(_heading),
        health: 0,
        dead: true,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (usesRiveVisual) {
      return;
    }
    if (_isDead) {
      final t = (1 - _deathLeft / GameConfig.enemyDeathDuration).clamp(
        0.0,
        1.0,
      );
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(t * 0.7);
      canvas.scale(1 - t * 0.85);
      canvas.translate(-size.x / 2, -size.y / 2);
      canvas.saveLayer(
        null,
        Paint()..color = GamePalette.hitFlash.withValues(alpha: 1 - t),
      );
      _paintBody(canvas);
      canvas.restore();
      canvas.restore();
      return;
    }
    _paintBody(canvas);
  }

  void _paintBody(Canvas canvas) {
    game.skin.paintEnemy(
      canvas,
      Offset(size.x / 2, size.y / 2),
      stats: stats,
      flash: _hitFlash / _hitFlashDuration,
      healthFraction: _health / stats.hitsToKill,
      heading: _heading,
    );
  }
}
