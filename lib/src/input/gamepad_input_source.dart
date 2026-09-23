import 'dart:async';
import 'dart:io';

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
  GamepadInputSource({this.listenToHardware = true, this.onImmediateActions})
    : connected = ValueNotifier(assumeGamepadConnected()) {
    if (listenToHardware) {
      _bindHardware();
    }
  }

  /// Tests turn this off so `flutter test` never opens the plugin channel.
  final bool listenToHardware;

  /// Invoked as soon as a rising-edge action is queued, matching keyboard
  /// handling in `onKeyEvent` (the update loop is frozen while paused).
  final VoidCallback? onImmediateActions;

  /// A pad is plugged in (or this is Gaming Mode on the Deck).
  ///
  /// The shell hides the mouse while this is true so menus play like a console.
  final ValueNotifier<bool> connected;

  StreamSubscription<NormalizedGamepadEvent>? _subscription;
  StreamSubscription<GamepadConnectionEvent>? _connectedSub;
  StreamSubscription<GamepadConnectionEvent>? _disconnectedSub;

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
  bool _wasDpadUp = false;
  bool _wasDpadDown = false;
  bool _wasDpadLeft = false;
  bool _wasDpadRight = false;
  bool _wasStickLeft = false;
  bool _wasStickRight = false;
  bool _wasStickUp = false;
  bool _wasStickDown = false;

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
    _connectedSub?.cancel();
    _disconnectedSub?.cancel();
    _subscription = null;
    _connectedSub = null;
    _disconnectedSub = null;
    _pendingActions.clear();
    connected.dispose();
  }

  void _bindHardware() {
    try {
      _refreshConnected();
      _connectedSub = Gamepads.onConnected.listen((_) {
        connected.value = true;
      });
      _disconnectedSub = Gamepads.onDisconnected.listen((_) {
        _refreshConnected();
      });
      _subscription = Gamepads.normalizedEvents.listen((event) {
        if (!connected.value) {
          connected.value = true;
        }
        applyEvent(event);
      });
    } on Object {
      // Headless tests and a missing plugin must not take the game down.
    }
  }

  Future<void> _refreshConnected() async {
    try {
      final pads = await Gamepads.list();
      connected.value = pads.isNotEmpty || assumeGamepadConnected();
      for (final pad in pads) {
        pad.dispose();
      }
    } on Object {
      // Keep the last known value.
    }
  }

  void _collectEdges() {
    final triggerDown = _rightTrigger >= GameConfig.triggerThreshold;
    final stickLeft = _leftX <= -GameConfig.stickDeadzone;
    final stickRight = _leftX >= GameConfig.stickDeadzone;
    final stickUp = _leftY >= GameConfig.stickDeadzone;
    final stickDown = _leftY <= -GameConfig.stickDeadzone;
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
    if ((_dpadLeft && !_wasDpadLeft) || (stickLeft && !_wasStickLeft)) {
      _pendingActions.add(GameAction.menuPrev);
      queued = true;
    }
    if ((_dpadRight && !_wasDpadRight) || (stickRight && !_wasStickRight)) {
      _pendingActions.add(GameAction.menuNext);
      queued = true;
    }
    if ((_dpadUp && !_wasDpadUp) || (stickUp && !_wasStickUp)) {
      _pendingActions.add(GameAction.menuPrev);
      queued = true;
    }
    if ((_dpadDown && !_wasDpadDown) || (stickDown && !_wasStickDown)) {
      _pendingActions.add(GameAction.menuNext);
      queued = true;
    }
    _wasA = _a;
    _wasRightTrigger = triggerDown;
    _wasStart = _start;
    _wasDpadLeft = _dpadLeft;
    _wasDpadRight = _dpadRight;
    _wasDpadUp = _dpadUp;
    _wasDpadDown = _dpadDown;
    _wasStickLeft = stickLeft;
    _wasStickRight = stickRight;
    _wasStickUp = stickUp;
    _wasStickDown = stickDown;
    if (queued) {
      onImmediateActions?.call();
    }
  }

  /// Gaming Mode always has the built-in pad, even before the plugin lists it.
  static bool assumeGamepadConnected() {
    if (kIsWeb) {
      return false;
    }
    try {
      return Platform.environment['SteamDeck'] == '1';
    } on Object {
      return false;
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
