import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/brotato_game.dart';
import '../game/game_config.dart';
import 'enemy.dart';
import 'rive_world_visual.dart';

class Bullet extends PositionComponent
    with CollisionCallbacks, HasGameReference<FCLGame> {
  Bullet({required super.position, required Vector2 direction})
    : _velocity = direction.normalized()..scale(GameConfig.bulletSpeed),
      _heading = math.atan2(direction.y, direction.x),
      super(
        anchor: Anchor.center,
        size: Vector2.all(GameConfig.bulletRadius * 2),
        priority: 5,
      );

  final Vector2 _velocity;

  /// Fixed for the bullet's whole life, so the tracer never has to recompute it.
  final double _heading;

  /// A bullet can overlap two enemies in the same tick; only the first one
  /// should take the hit.
  bool _spent = false;

  RiveWorldVisual? _riveVisual;

  bool get usesRiveVisual => _riveVisual != null;

  // Synchronous on purpose. An `async` onLoad defers mounting to a microtask,
  // which would leave a freshly fired bullet unable to hit anything for a frame.
  @override
  void onLoad() {
    // Passive, so bullets are never checked against each other.
    add(CircleHitbox(collisionType: CollisionType.passive));
    final visual = game.enableRive
        ? game.rive.createBullet(
            Vector2(
              GameConfig.bulletVisualWidth,
              GameConfig.bulletVisualHeight,
            ),
          )
        : null;
    if (visual != null) {
      visual.position = size / 2;
      visual.angle = _heading;
      add(_riveVisual = visual);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.addScaled(_velocity, dt);
    if (_isOutOfBounds) {
      removeFromParent();
    }
  }

  bool get _isOutOfBounds {
    const margin = GameConfig.bulletDespawnMargin;
    return position.x < -margin ||
        position.y < -margin ||
        position.x > GameConfig.worldWidth + margin ||
        position.y > GameConfig.worldHeight + margin;
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) => other is Enemy;

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_spent || other is! Enemy || !other.isAlive) {
      return;
    }
    _spent = true;
    other.takeDamage(GameConfig.bulletDamage);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (usesRiveVisual) {
      return;
    }
    game.skin.paintBullet(
      canvas,
      Offset(size.x / 2, size.y / 2),
      radius: GameConfig.bulletRadius,
      heading: _heading,
    );
  }
}
