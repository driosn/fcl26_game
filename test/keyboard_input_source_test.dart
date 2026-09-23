import 'package:fcl_26_game/src/input/input_source.dart';
import 'package:flame/components.dart';
import 'package:fcl_26_game/src/input/input_state.dart';
import 'package:fcl_26_game/src/input/keyboard_input_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Feeds a key down event plus the resulting held-key set into [source].
bool _press(
  KeyboardInputSource source,
  LogicalKeyboardKey key, {
  Set<LogicalKeyboardKey> held = const {},
}) {
  return source.handleKeyEvent(
    KeyDownEvent(
      logicalKey: key,
      physicalKey: PhysicalKeyboardKey.keyA,
      timeStamp: Duration.zero,
    ),
    {key, ...held},
  );
}

/// Runs one input frame and returns the resulting movement direction.
Vector2 _poll(KeyboardInputSource source) {
  final state = InputState()..beginFrame();
  source.poll(state);
  state.endFrame();
  return state.moveDirection;
}

/// A source whose held keys are a set the test owns, not HardwareKeyboard.
(KeyboardInputSource, Set<LogicalKeyboardKey>) _source() {
  final held = <LogicalKeyboardKey>{};
  return (KeyboardInputSource(heldKeys: () => held), held);
}

void main() {
  group('KeyboardInputSource movement', () {
    test('arrow keys map to the four directions', () {
      final (source, held) = _source();

      held.add(LogicalKeyboardKey.arrowRight);
      expect(_poll(source).x, 1);

      held
        ..clear()
        ..add(LogicalKeyboardKey.arrowLeft);
      expect(_poll(source).x, -1);

      // Up is negative on screen coordinates.
      held
        ..clear()
        ..add(LogicalKeyboardKey.arrowUp);
      expect(_poll(source).y, -1);

      held
        ..clear()
        ..add(LogicalKeyboardKey.arrowDown);
      expect(_poll(source).y, 1);
    });

    test('WASD works as an alternative to the arrows', () {
      final (source, held) = _source();
      held.add(LogicalKeyboardKey.keyD);
      expect(_poll(source).x, 1);
      held
        ..clear()
        ..add(LogicalKeyboardKey.keyW);
      expect(_poll(source).y, -1);
    });

    test('diagonals are normalized so they are not faster', () {
      final (source, held) = _source();
      held.addAll({
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowDown,
      });

      expect(_poll(source).length, closeTo(1, 1e-6));
    });

    test('opposite keys cancel out', () {
      final (source, held) = _source();
      held.addAll({
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
      });
      final direction = _poll(source);
      expect(direction.x, 0);
      expect(direction.y, 0);
    });

    test('releasing everything stops the movement intent', () {
      final (source, held) = _source();
      held.add(LogicalKeyboardKey.arrowRight);
      expect(_poll(source).x, 1);

      held.clear();
      expect(_poll(source).x, 0);
    });
  });

  group('KeyboardInputSource actions', () {
    test('escape and P both request a pause toggle', () {
      final source = KeyboardInputSource(heldKeys: () => {});

      _press(source, LogicalKeyboardKey.escape);
      expect(source.drainActions(), contains(GameAction.pauseToggle));

      _press(source, LogicalKeyboardKey.keyP);
      expect(source.drainActions(), contains(GameAction.pauseToggle));
    });

    test('enter and space confirm', () {
      final source = KeyboardInputSource(heldKeys: () => {});

      _press(source, LogicalKeyboardKey.enter);
      expect(source.drainActions(), contains(GameAction.confirm));

      _press(source, LogicalKeyboardKey.space);
      expect(source.drainActions(), contains(GameAction.confirm));
    });

    test('shift and space request a dash', () {
      final source = KeyboardInputSource(heldKeys: () => {});

      _press(source, LogicalKeyboardKey.shiftLeft);
      expect(source.drainActions(), contains(GameAction.dash));

      _press(source, LogicalKeyboardKey.space);
      expect(source.drainActions(), contains(GameAction.dash));
    });

    test('draining clears the buffer, so an action fires only once', () {
      final source = KeyboardInputSource(heldKeys: () => {});
      _press(source, LogicalKeyboardKey.escape);

      expect(source.drainActions(), hasLength(1));
      expect(source.drainActions(), isEmpty);
    });

    test('actions survive until drained, even across several frames', () {
      final source = KeyboardInputSource(heldKeys: () => {});
      _press(source, LogicalKeyboardKey.escape);

      _poll(source);
      _poll(source);

      expect(source.drainActions(), contains(GameAction.pauseToggle));
    });

    test('arrows walk the menu', () {
      final source = KeyboardInputSource(heldKeys: () => {});

      _press(source, LogicalKeyboardKey.arrowRight);
      expect(source.drainActions(), contains(GameAction.menuNext));

      _press(source, LogicalKeyboardKey.arrowLeft);
      expect(source.drainActions(), contains(GameAction.menuPrev));
    });

    test('a key up does not trigger an action', () {
      final source = KeyboardInputSource(heldKeys: () => {});
      source.handleKeyEvent(
        KeyUpEvent(
          logicalKey: LogicalKeyboardKey.escape,
          physicalKey: PhysicalKeyboardKey.escape,
          timeStamp: Duration.zero,
        ),
        const {},
      );
      expect(source.drainActions(), isEmpty);
    });
  });

  group('KeyboardInputSource event consumption', () {
    test('reports game keys as handled', () {
      final source = KeyboardInputSource(heldKeys: () => {});
      expect(_press(source, LogicalKeyboardKey.arrowUp), isTrue);
      expect(_press(source, LogicalKeyboardKey.escape), isTrue);
    });

    test('lets unrelated keys through to the rest of the app', () {
      final source = KeyboardInputSource(heldKeys: () => {});
      expect(_press(source, LogicalKeyboardKey.keyQ), isFalse);
    });
  });
}
