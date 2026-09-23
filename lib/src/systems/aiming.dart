import 'dart:math' as math;

import 'package:flame/components.dart';

/// Smoothing maths for the aim direction.
///
/// Pure and Flame-agnostic apart from [Vector2], so the behaviour is unit
/// testable without a running game.
///
/// The aim follows a low-pass filtered copy of the movement input rather than the
/// input itself. Filtering the *vector* instead of the angle is what makes rapid
/// alternation settle in between: tapping up and right in turn pulls the filtered
/// vector towards the average of the two, which is the diagonal. Steering the
/// angle towards each key instead would only make the aim wobble around wherever
/// it started.
abstract final class Aiming {
  /// Below this squared length the blended vector has no usable direction, which
  /// happens when the input keeps flipping to the exact opposite side.
  static const double _degenerateLength2 = 0.0025;

  /// How far to move towards a target this frame, as a fraction in `[0, 1]`.
  ///
  /// An exponential approach at [rate] per second. Derived from [dt] rather than
  /// applied per frame so the feel does not change with the framerate.
  static double smoothingFactor(double rate, double dt) {
    if (rate <= 0 || dt <= 0) {
      return 0;
    }
    return 1 - math.exp(-rate * dt);
  }

  /// Moves [current] a fraction [t] of the way towards [target], in place.
  static void blendTowards(Vector2 current, Vector2 target, double t) {
    if (t <= 0) {
      return;
    }
    final factor = math.min(t, 1.0);
    current.setValues(
      current.x + (target.x - current.x) * factor,
      current.y + (target.y - current.y) * factor,
    );
  }

  /// Writes the direction of [blend] into [aim] as a unit vector.
  ///
  /// Leaves [aim] untouched when [blend] is too short to point anywhere, so the
  /// aim holds its last direction instead of snapping to noise.
  /// Returns whether [aim] was updated.
  static bool applyBlend(Vector2 aim, Vector2 blend) {
    if (blend.length2 < _degenerateLength2) {
      return false;
    }
    aim
      ..setFrom(blend)
      ..normalize();
    return true;
  }

  /// Eight facing poses, counterclockwise from down (toward the camera).
  ///
  /// `0` down, `1` down-right, `2` right, `3` up-right, `4` up, `5` up-left,
  /// `6` left, `7` down-left. Analog sticks and keyboard diagonals both land
  /// on a sector instead of being forced onto the nearest axis.
  static const int facingDown = 0;
  static const int facingDownRight = 1;
  static const int facingRight = 2;
  static const int facingUpRight = 3;
  static const int facingUp = 4;
  static const int facingUpLeft = 5;
  static const int facingLeft = 6;
  static const int facingDownLeft = 7;
  static const int facingDirections = 8;

  static const double _sector = math.pi / 4;
  static const double _halfSector = math.pi / 8;

  /// Angle in radians where `0` is down and positive turns toward +X (right).
  static double eightWayAngle(Vector2 dir) => math.atan2(dir.x, dir.y);

  /// Nearest of the eight poses for [dir].
  static int eightWayIndex(Vector2 dir) {
    if (dir.length2 < _degenerateLength2) {
      return facingUp;
    }
    var angle = eightWayAngle(dir);
    if (angle < 0) {
      angle += math.pi * 2;
    }
    return ((angle + _halfSector) / _sector).floor() % facingDirections;
  }

  /// Sticks to [current] until [dir] is clearly inside another sector.
  ///
  /// [hold] is extra radians the stick must travel past the current sector
  /// centre before the pose is allowed to change, so a joystick resting on a
  /// boundary does not flicker.
  static int holdEightWay(
    int current,
    Vector2 dir, {
    double hold = math.pi / 16,
  }) {
    if (dir.length2 < _degenerateLength2) {
      return current;
    }
    final next = eightWayIndex(dir);
    if (next == current) {
      return current;
    }
    var angle = eightWayAngle(dir);
    if (angle < 0) {
      angle += math.pi * 2;
    }
    if (_angleDelta(angle, next * _sector) + hold <
        _angleDelta(angle, current * _sector)) {
      return next;
    }
    return current;
  }

  static double _angleDelta(double from, double to) {
    var delta = (to - from).abs();
    if (delta > math.pi) {
      delta = math.pi * 2 - delta;
    }
    return delta;
  }
}
