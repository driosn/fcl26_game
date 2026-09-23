import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/brotato_game.dart';
import '../game/game_config.dart';
import '../input/input_device.dart';
import '../systems/aiming.dart';
import '../systems/status_effects.dart';
import 'enemy.dart';
import 'power_up.dart';
import 'rive_player_visual.dart';
import 'weapon.dart';

class Player extends PositionComponent
    with CollisionCallbacks, HasGameReference<FCLGame> {
  Player({required super.position})
    : super(
        anchor: Anchor.center,
        size: Vector2.all(GameConfig.playerRadius * 2),
        priority: 10,
      );

  /// Where the next bullet goes. Only updated while there is movement input, so
  /// releasing the keys keeps both the aim and the auto fire pointing at the
  /// last direction walked.
  ///
  /// It eases towards the input rather than snapping to it, so a change of
  /// direction fires through the angles in between. See [Aiming].
  final Vector2 facing = Vector2(0, -1);

  /// Low-pass filtered movement input, which [facing] reads its direction from.
  /// Unlike [facing] this is free to shrink, which is what lets opposing inputs
  /// average out into the direction between them.
  final Vector2 _aimBlend = Vector2(0, -1);

  final TimedEffect _invulnerability = TimedEffect(
    duration: GameConfig.invulnerabilityDuration,
  );
  final TimedEffect _dash = TimedEffect(duration: GameConfig.dashDuration);
  final TimedEffect _dashCooldown = TimedEffect(
    duration: GameConfig.dashCooldown,
  );

  /// Locked in at the start of a dash so a mid-burst direction change cannot
  /// steer it.
  final Vector2 _dashDirection = Vector2(0, -1);

  late final Weapon weapon;
  RivePlayerVisual? _riveVisual;

  /// Eight-way pose index. Starts on up to match the default [facing].
  int _heading = Aiming.facingUp;

  bool _isAlive = true;
  double _blinkTimer = 0;
  bool _visible = true;
  double _firePulse = 0;

  bool get isAlive => _isAlive;

  bool get isDashing => _dash.isActive;

  bool get isInvulnerable => _invulnerability.isActive || isDashing;

  /// True when the Rive rig is drawing Dash, so [render] must not also paint
  /// the shape-skin placeholder on top.
  bool get usesRiveVisual => _riveVisual != null;

  @override
  void onLoad() {
    // Solid, so an enemy or pickup that ends up fully inside the player still
    // registers as a collision. See the note in [Enemy.onLoad].
    add(CircleHitbox(isSolid: true));
    add(weapon = Weapon(owner: this));
    final visual = game.enableRive ? game.rive.createPlayer() : null;
    if (visual != null) {
      visual.position = size / 2;
      add(_riveVisual = visual);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isAlive) {
      return;
    }

    final wasDashing = _dash.isActive;
    _invulnerability.update(dt);
    _dash.update(dt);
    _dashCooldown.update(dt);
    if (wasDashing && !_dash.isActive) {
      _dashCooldown.trigger();
    }
    if (_firePulse > 0) {
      _firePulse = math.max(0, _firePulse - dt);
    }
    _updateBlink(dt);

    final input = game.inputState.moveDirection;
    final aim = game.inputState.aimDirection;
    if (isDashing) {
      position.addScaled(_dashDirection, GameConfig.dashSpeed * dt);
      _clampToWorld();
    } else if (!input.isZero()) {
      // Movement is applied straight from the input so the controls stay tight;
      // only the aim is allowed to lag behind.
      position.addScaled(input, GameConfig.playerSpeed * dt);
      _clampToWorld();
    }

    final aimInput = !aim.isZero()
        ? aim
        : (!input.isZero() &&
                  game.inputState.lastDevice.value == InputDeviceKind.keyboard
              ? input
              : null);
    if (aimInput != null) {
      Aiming.blendTowards(
        _aimBlend,
        aimInput,
        Aiming.smoothingFactor(GameConfig.aimResponsiveness, dt),
      );
      Aiming.applyBlend(facing, _aimBlend);
    }

    _updateHeading();
    final visual = _riveVisual;
    if (visual != null) {
      visual.scale.setAll(_visible ? 1 : 0);
      visual.sync(
        speed: isDashing ? 1 : input.length,
        dashing: isDashing,
        hurt: _invulnerability.isActive,
        firing: _firePulse > 0,
        facing: _heading,
      );
    }
  }

  /// Burst in the current move direction, or along [facing] if standing still.
  void tryDash() {
    if (!isAlive ||
        !game.state.isPlaying ||
        isDashing ||
        _dashCooldown.isActive) {
      return;
    }
    final input = game.inputState.moveDirection;
    _dashDirection.setFrom(input.isZero() ? facing : input);
    if (_dashDirection.length2 < 0.0001) {
      _dashDirection.setValues(0, -1);
    } else {
      _dashDirection.normalize();
    }
    facing.setFrom(_dashDirection);
    _aimBlend.setFrom(_dashDirection);
    _dash.trigger();
  }

  /// A one-shot pulse so the Rive muzzle flash can catch a rising edge.
  void notifyFired() => _firePulse = 0.06;

  void takeDamage(int amount) {
    if (!_isAlive || isInvulnerable) {
      return;
    }
    _invulnerability.trigger();

    final remaining = (game.state.hp.value - amount).clamp(
      0,
      GameConfig.playerMaxHp,
    );
    game.state.hp.value = remaining;

    if (remaining == 0) {
      _isAlive = false;
      _visible = true;
      game.onPlayerDied();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    // Checked every tick rather than only on collision start, otherwise standing
    // still inside an enemy would never deal damage again after the first hit.
    if (other is Enemy && other.isAlive) {
      takeDamage(GameConfig.enemyContactDamage);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PowerUp) {
      game.onPowerUpCollected(other);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_visible || usesRiveVisual) {
      return;
    }
    game.skin.paintPlayer(
      canvas,
      Offset(size.x / 2, size.y / 2),
      radius: GameConfig.playerRadius,
      hurt: _invulnerability.isActive,
    );
  }

  void _updateBlink(double dt) {
    if (!_invulnerability.isActive) {
      _blinkTimer = 0;
      _visible = true;
      return;
    }
    _blinkTimer += dt;
    if (_blinkTimer >= GameConfig.invulnerabilityBlinkInterval) {
      _blinkTimer = 0;
      _visible = !_visible;
    }
  }

  void _updateHeading() {
    _heading = Aiming.holdEightWay(
      _heading,
      facing,
      hold: GameConfig.facingHoldRadians,
    );
  }

  void _clampToWorld() {
    const r = GameConfig.playerRadius;
    position.setValues(
      position.x.clamp(r, GameConfig.worldWidth - r),
      position.y.clamp(r, GameConfig.worldHeight - r),
    );
  }
}
