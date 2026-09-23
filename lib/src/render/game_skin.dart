import 'dart:ui';

import '../components/enemy_type.dart';

/// The look of everything drawn on the game canvas.
///
/// Components hold no paints and draw nothing themselves; they hand their state
/// to the active skin. That keeps the whole art style in one replaceable object:
/// [ShapeSkin] is the code-drawn placeholder, and a sprite based skin only has to
/// implement these same calls, blitting images at the centres and radii it is
/// handed. Pass an alternative to `FCLGame(skin: ...)`.
///
/// Rive is the one case this seam does not cover, since it needs its own
/// component rather than a paint call. That swap replaces the component's visual
/// child instead, which is why gameplay state is kept out of `render` entirely.
abstract class GameSkin {
  const GameSkin();

  /// Called once before the first frame, for skins that need to pull in images.
  Future<void> load() async {}

  /// Paints the playfield backdrop, filling a box of [size] from its origin.
  void paintArena(Canvas canvas, Size size);

  /// [center] is in the component's local coordinates for every call below, so a
  /// skin never needs to know where an entity sits in the world.
  void paintPlayer(
    Canvas canvas,
    Offset center, {
    required double radius,
    required bool hurt,
  });

  void paintEnemy(
    Canvas canvas,
    Offset center, {
    required EnemyStats stats,

    /// 0 when idle, 1 at the peak of a hit reaction.
    required double flash,

    /// Remaining health as a fraction of the maximum.
    required double healthFraction,

    /// Radians, 0 pointing right, matching `Vector2.angleToSigned` conventions.
    required double heading,
  });

  void paintBullet(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double heading,
  });

  void paintPowerUp(
    Canvas canvas,
    Offset center, {
    required double radius,

    /// Seconds since the pickup appeared, for idle animation.
    required double age,
  });

  /// The aim guide: an arrow of [length] along the +Y-up axis plus the edges of
  /// the spread cone at [spread] radians to either side.
  void paintAim(
    Canvas canvas,
    Offset center, {
    required double tailRadius,
    required double length,
    required double coneLength,
    required double spread,
  });
}
