import 'dart:math' as math;

/// A buff that runs for a fixed duration and refreshes instead of stacking.
///
/// Refreshing rather than stacking is deliberate: collecting two rapid fire
/// power-ups back to back extends the window to a full 15 seconds again, but it
/// never multiplies the fire rate twice.
///
/// Pure Dart with no Flame dependency, so the timing is unit testable.
class TimedEffect {
  TimedEffect({required this.duration}) : assert(duration > 0);

  final double duration;

  double _remaining = 0;

  bool get isActive => _remaining > 0;

  double get remaining => _remaining;

  /// Remaining time as 0..1, for progress bars.
  double get progress => _remaining / duration;

  /// Starts the effect, or restarts its full duration if already running.
  void trigger() => _remaining = duration;

  void update(double dt) {
    if (_remaining > 0) {
      _remaining = math.max(0, _remaining - dt);
    }
  }

  void reset() => _remaining = 0;
}
