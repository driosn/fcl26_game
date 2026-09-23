import 'package:fcl_26_game/src/game/game_config.dart';
import 'package:fcl_26_game/src/input/gamepad_input_source.dart';
import 'package:fcl_26_game/src/input/input_device.dart';
import 'package:fcl_26_game/src/input/input_source.dart';
import 'package:fcl_26_game/src/input/input_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

InputState _poll(GamepadInputSource source) {
  final state = InputState();
  state.beginFrame();
  source.poll(state);
  state.endFrame();
  return state;
}

void main() {
  GamepadInputSource source() => GamepadInputSource(listenToHardware: false);

  group('GamepadInputSource sticks', () {
    test('left stick maps to movement, inverting Y to screen space', () {
      final pad = source();
      pad.setAxes(leftX: 1, leftY: 0);
      expect(_poll(pad).moveDirection.x, closeTo(1, 1e-6));

      pad.setAxes(leftX: 0, leftY: 1);
      expect(_poll(pad).moveDirection.y, closeTo(-1, 1e-6));
      expect(_poll(pad).lastDevice.value, InputDeviceKind.gamepad);
    });

    test('right stick maps to aim, independent of movement', () {
      final pad = source();
      pad.setAxes(rightX: 1, rightY: 0);
      final state = _poll(pad);
      expect(state.moveDirection.length, 0);
      expect(state.aimDirection.x, closeTo(1, 1e-6));
      expect(state.aimDirection.y, closeTo(0, 1e-6));
    });

    test('values inside the deadzone are ignored', () {
      final pad = source();
      pad.setAxes(leftX: GameConfig.stickDeadzone * 0.4);
      final state = _poll(pad);
      expect(state.moveDirection.length, 0);
      expect(state.lastDevice.value, InputDeviceKind.keyboard);
    });

    test('diagonals are normalized', () {
      final pad = source();
      pad.setAxes(leftX: 1, leftY: -1);
      expect(_poll(pad).moveDirection.length, closeTo(1, 1e-6));
    });
  });

  group('GamepadInputSource d-pad', () {
    test('adds to movement like WASD', () {
      final pad = source();
      pad.setButton(GamepadButton.dpadRight, true);
      expect(_poll(pad).moveDirection.x, 1);
      pad.setButton(GamepadButton.dpadDown, true);
      expect(_poll(pad).moveDirection.length, closeTo(1, 1e-6));
    });
  });

  group('GamepadInputSource actions', () {
    test('A dashes and confirms on the rising edge', () {
      final pad = source();
      pad.setButton(GamepadButton.a, true);
      expect(
        pad.drainActions(),
        containsAll([GameAction.dash, GameAction.confirm]),
      );
      expect(pad.drainActions(), isEmpty);
      pad.setButton(GamepadButton.a, true);
      expect(pad.drainActions(), isEmpty, reason: 'held, not a new press');
    });

    test('R2 dashes once the trigger crosses the threshold', () {
      final pad = source();
      pad.setAxes(rightTrigger: GameConfig.triggerThreshold * 0.5);
      expect(pad.drainActions(), isEmpty);
      pad.setAxes(rightTrigger: GameConfig.triggerThreshold);
      expect(pad.drainActions(), contains(GameAction.dash));
      pad.setAxes(rightTrigger: 1);
      expect(pad.drainActions(), isEmpty);
    });

    test('Start toggles pause', () {
      final pad = source();
      pad.setButton(GamepadButton.start, true);
      expect(pad.drainActions(), contains(GameAction.pauseToggle));
    });

    test('Steam Deck raw axes 2/3 aim', () {
      final pad = source();
      pad.applyRawEvent(
        GamepadEvent(
          gamepadId: 'deck',
          timestamp: 0,
          type: KeyType.analog,
          key: '2',
          value: 1,
          vendorId: 0x28de,
          productId: 0x1205,
        ),
      );
      pad.applyRawEvent(
        GamepadEvent(
          gamepadId: 'deck',
          timestamp: 1,
          type: KeyType.analog,
          key: '3',
          value: -1,
          vendorId: 0x28de,
          productId: 0x1205,
        ),
      );
      final state = _poll(pad);
      expect(state.aimDirection.x, greaterThan(0.5));
      expect(state.aimDirection.y, lessThan(-0.5));
    });

    test('pointer motion aims when Steam remaps the right stick', () {
      final pad = source();
      pad.applyPointerAim(dx: 40, dy: -40);
      final state = _poll(pad);
      expect(state.aimDirection.x, greaterThan(0));
      expect(state.aimDirection.y, lessThan(0));
    });

    test('D-pad edges walk the menu', () {
      final pad = source();
      pad.setButton(GamepadButton.dpadRight, true);
      expect(pad.drainActions(), contains(GameAction.menuNext));
      pad.setButton(GamepadButton.dpadRight, false);
      pad.setButton(GamepadButton.dpadLeft, true);
      expect(pad.drainActions(), contains(GameAction.menuPrev));
    });
  });
}
