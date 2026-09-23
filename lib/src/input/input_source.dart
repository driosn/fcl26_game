import 'input_state.dart';

/// One-shot commands, as opposed to the continuous intent in [InputState].
enum GameAction { pauseToggle, confirm, dash, menuPrev, menuNext }

/// A device that can drive the game.
///
/// Continuous intent is polled once per frame via [poll]; discrete commands are
/// buffered by the source and collected with [drainActions]. Actions are drained
/// separately because they must keep working while the engine is paused, when
/// [poll] is not being called at all.
abstract class InputSource {
  /// Contributes this device's movement intent into [state].
  ///
  /// Implementations add to the existing values rather than overwriting them, so
  /// several sources can be active at once.
  void poll(InputState state);

  /// Returns the actions triggered since the last call and clears the buffer.
  Set<GameAction> drainActions();

  void dispose() {}
}
