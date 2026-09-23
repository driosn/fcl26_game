import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/brotato_game.dart';
import '../game/game_config.dart';
import '../systems/status_effects.dart';
import 'player.dart';
import 'rive_world_visual.dart';

/// The rapid fire pickup. Collected on contact, and disappears on its own if
/// nobody grabs it in time.
class PowerUp extends PositionComponent
    with CollisionCallbacks, HasGameReference<FCLGame> {
  PowerUp({required super.position})
    : super(
        anchor: Anchor.center,
        size: Vector2.all(GameConfig.powerUpRadius * 2),
        priority: 3,
      );

  /// Seconds of remaining lifetime under which the pickup starts blinking.
  static const _warningTime = 3.0;

  final TimedEffect _lifetime = TimedEffect(
    duration: GameConfig.powerUpLifetime,
  )..trigger();

  double _pulse = 0;

  RiveWorldVisual? _riveVisual;

  bool get usesRiveVisual => _riveVisual != null;

  @override
  void onLoad() {
    add(CircleHitbox(isSolid: true, collisionType: CollisionType.passive));
    final visual = game.enableRive
        ? game.rive.createPowerUp(Vector2.all(GameConfig.powerUpVisualSize))
        : null;
    if (visual != null) {
      visual.position = size / 2;
      add(_riveVisual = visual);
    }
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) => other is Player;

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt;
    _lifetime.update(dt);
    if (!_lifetime.isActive) {
      removeFromParent();
      return;
    }
    _riveVisual?.sync(warning: _lifetime.remaining < _warningTime);
  }

  void collect() {
    if (!isRemoving && !isRemoved) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (usesRiveVisual) {
      return;
    }
    // Blink faster and faster as the pickup is about to expire.
    if (_lifetime.remaining < _warningTime) {
      final blinkRate = 6 + (_warningTime - _lifetime.remaining) * 4;
      if (math.sin(_pulse * blinkRate) < 0) {
        return;
      }
    }

    game.skin.paintPowerUp(
      canvas,
      Offset(size.x / 2, size.y / 2),
      radius: GameConfig.powerUpRadius,
      age: _pulse,
    );
  }
}
