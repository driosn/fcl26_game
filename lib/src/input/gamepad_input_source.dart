import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

import '../game/game_config.dart';
import 'input_device.dart';
import 'input_source.dart';
import 'input_state.dart';

/// Steam Deck / Xbox-layout pad. Steam Input presents the Deck as this layout
/// to a non-Steam Linux game.
///
/// Analog state is sampled every [poll]; button actions fire on the rising
/// edge so dash and pause still work while Flame's engine is paused.
class GamepadInputSource implements InputSource {
  GamepadInputSource({this.listenToHardware = true, this.onImmediateActions}) {
    if (listenToHardware) {
      _bindHardware();
    }
  }

  /// Tests turn this off so `flutter test` never opens the plugin channel.
  final bool listenToHardware;

  /// Invoked as soon as a rising-edge action is queued, matching keyboard
  /// handling in `onKeyEvent` (the update loop is frozen while paused).
  final VoidCallback? onImmediateActions;

  StreamSubscription<NormalizedGamepadEvent>? _subscription;

  double _leftX = 0;
  double _leftY = 0;
  double _rightX = 0;
  double _rightY = 0;
  double _rightTrigger = 0;

  bool _a = false;
  bool _start = false;
  bool _dpadUp = false;
  bool _dpadDown = false;
  bool _dpadLeft = false;
  bool _dpadRight = false;

  bool _wasA = false;
  bool _wasStart = false;
  bool _wasRightTrigger = false;

  final Set<GameAction> _pendingActions = {};

  /// Apply a normalized event, as if it came from [Gamepads.normalizedEvents].
  void applyEvent(NormalizedGamepadEvent event) {
    final button = event.button;
    if (button != null) {
      final pressed = event.value != 0;
      switch (button) {
        case GamepadButton.a:
          _a = pressed;
        case GamepadButton.start:
          _start = pressed;
        case GamepadButton.dpadUp:
          _dpadUp = pressed;
        case GamepadButton.dpadDown:
          _dpadDown = pressed;
        case GamepadButton.dpadLeft:
          _dpadLeft = pressed;
        case GamepadButton.dpadRight:
          _dpadRight = pressed;
        case GamepadButton.rightTrigger:
          _rightTrigger = pressed ? 1 : 0;
        default:
          break;
      }
    }
    final axis = event.axis;
    if (axis != null) {
      switch (axis) {
        case GamepadAxis.leftStickX:
          _leftX = event.value;
        case GamepadAxis.leftStickY:
          _leftY = event.value;
        case GamepadAxis.rightStickX:
          _rightX = event.value;
        case GamepadAxis.rightStickY:
          _rightY = event.value;
        case GamepadAxis.rightTrigger:
          _rightTrigger = event.value;
        default:
          break;
      }
    }
    _collectEdges();
  }

  /// Test seam: write analog axes in normalized stick space (up = +Y).
  void setAxes({
    double? leftX,
    double? leftY,
    double? rightX,
    double? rightY,
    double? rightTrigger,
  }) {
    if (leftX != null) {
      _leftX = leftX;
    }
    if (leftY != null) {
      _leftY = leftY;
    }
    if (rightX != null) {
      _rightX = rightX;
    }
    if (rightY != null) {
      _rightY = rightY;
    }
    if (rightTrigger != null) {
      _rightTrigger = rightTrigger;
    }
    _collectEdges();
  }

  /// Test seam: press or release a face / d-pad / start button.
  void setButton(GamepadButton button, bool pressed) {
    switch (button) {
      case GamepadButton.a:
        _a = pressed;
      case GamepadButton.start:
        _start = pressed;
      case GamepadButton.dpadUp:
        _dpadUp = pressed;
      case GamepadButton.dpadDown:
        _dpadDown = pressed;
      case GamepadButton.dpadLeft:
        _dpadLeft = pressed;
      case GamepadButton.dpadRight:
        _dpadRight = pressed;
      case GamepadButton.rightTrigger:
        _rightTrigger = pressed ? 1 : 0;
      default:
        break;
    }
    _collectEdges();
  }

  @override
  void poll(InputState state) {
    final move = _stickToScreen(_leftX, _leftY);
    if (move != null) {
      state.moveDirection.add(move);
      state.noteDevice(InputDeviceKind.gamepad);
    }
    if (_dpadLeft) {
      state.moveDirection.x -= 1;
      state.noteDevice(InputDeviceKind.gamepad);
    }
    if (_dpadRight) {
      state.moveDirection.x += 1;
      state.noteDevice(InputDeviceKind.gamepad);
    }
    if (_dpadUp) {
      state.moveDirection.y -= 1;
      state.noteDevice(InputDeviceKind.gamepad);
    }
    if (_dpadDown) {
      state.moveDirection.y += 1;
      state.noteDevice(InputDeviceKind.gamepad);
    }

    final aim = _stickToScreen(_rightX, _rightY);
    if (aim != null) {
      state.aimDirection.add(aim);
      state.noteDevice(InputDeviceKind.gamepad);
    }
  }

  @override
  Set<GameAction> drainActions() {
    if (_pendingActions.isEmpty) {
      return const {};
    }
    final drained = Set<GameAction>.of(_pendingActions);
    _pendingActions.clear();
    return drained;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _pendingActions.clear();
  }

  void _bindHardware() {
    try {
      _subscription = Gamepads.normalizedEvents.listen(applyEvent);
    } on Object {
      // Headless tests and a missing plugin must not take the game down.
    }
  }

  void _collectEdges() {
    final triggerDown = _rightTrigger >= GameConfig.triggerThreshold;
    var queued = false;
    if (_a && !_wasA) {
      _pendingActions
        ..add(GameAction.dash)
        ..add(GameAction.confirm);
      queued = true;
    }
    if (triggerDown && !_wasRightTrigger) {
      _pendingActions.add(GameAction.dash);
      queued = true;
    }
    if (_start && !_wasStart) {
      _pendingActions.add(GameAction.pauseToggle);
      queued = true;
    }
    _wasA = _a;
    _wasRightTrigger = triggerDown;
    _wasStart = _start;
    if (queued) {
      onImmediateActions?.call();
    }
  }

  /// Stick space is up = +Y. The playfield is up = -Y. Values inside the
  /// deadzone are dropped so a resting stick does not leak intent.
  Vector2? _stickToScreen(double x, double y) {
    final screen = Vector2(x, -y);
    if (screen.length < GameConfig.stickDeadzone) {
      return null;
    }
    if (screen.length2 > 1) {
      screen.normalize();
    }
    return screen;
  }
}
