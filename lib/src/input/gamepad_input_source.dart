import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

import '../game/game_config.dart';
import '../platform/host.dart';
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
  StreamSubscription<GamepadEvent>? _rawSubscription;
  StreamSubscription<GamepadConnectionEvent>? _connectedSub;
  StreamSubscription<GamepadConnectionEvent>? _disconnectedSub;

  int? _vendorId;
  int? _productId;
  bool _axis2IsStick = false;
  double? _axis2Rest;
  double _raw2 = 0;
  double _raw3 = 0;
  double _raw4 = 0;

  double _pointerX = 0;
  double _pointerY = 0;

  double _leftX = 0;
  double _leftY = 0;
  double _rightX = 0;
  double _rightY = 0;
  double _rightTrigger = 0;

  bool _a = false;
  bool _b = false;
  bool _start = false;
  bool _dpadUp = false;
  bool _dpadDown = false;
  bool _dpadLeft = false;
  bool _dpadRight = false;

  bool _wasA = false;
  bool _wasB = false;
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
        case GamepadButton.b:
          _b = pressed;
        case GamepadButton.back:
          _b = pressed;
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
      case GamepadButton.b:
      case GamepadButton.back:
        _b = pressed;
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

    _publishRightFromRaw();
    final aim = _stickToScreen(_rightX, _rightY);
    final pointerAim = _stickToScreen(_pointerX, _pointerY);
    _pointerX = 0;
    _pointerY = 0;
    if (aim != null) {
      state.aimDirection.add(aim);
      state.noteDevice(InputDeviceKind.gamepad);
    } else if (pointerAim != null) {
      state.aimDirection.add(pointerAim);
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

  /// Steam Input sometimes turns the right stick into mouse motion.
  void applyPointerAim({required double dx, required double dy}) {
    const scale = 0.12;
    _pointerX = (dx * scale).clamp(-1.0, 1.0);
    _pointerY = (-dy * scale).clamp(-1.0, 1.0);
    if (!connected.value &&
        (_pointerX.abs() > 0.01 || _pointerY.abs() > 0.01)) {
      connected.value = true;
    }
  }

  /// Raw Linux js / evdev event. Used when the normalizer drops Deck axes.
  void applyRawEvent(GamepadEvent event) {
    _vendorId ??= event.vendorId;
    _productId ??= event.productId;
    if (event.type == KeyType.analog) {
      final axis = int.tryParse(event.key);
      if (axis == null) {
        return;
      }
      _applyRawAxis(axis, event.value);
      _collectEdges();
      return;
    }
    if (event.type == KeyType.button) {
      _applyRawButton(event.key, event.value != 0);
      _collectEdges();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _rawSubscription?.cancel();
    _connectedSub?.cancel();
    _disconnectedSub?.cancel();
    _subscription = null;
    _rawSubscription = null;
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
      _rawSubscription = Gamepads.events.listen((event) {
        if (!connected.value) {
          connected.value = true;
        }
        applyRawEvent(event);
      });
    } on Object {
      // Headless tests and a missing plugin must not take the game down.
    }
  }

  void _applyRawAxis(int axis, double raw) {
    final stick = _normalizeRawStick(raw);
    switch (axis) {
      case 2:
        _learnAxis2(stick);
        _raw2 = stick;
      case 3:
        _raw3 = stick;
      case 4:
        _raw4 = stick;
      case 5:
        if (!_useSdlRightStick) {
          _rightTrigger = _normalizeRawTrigger(raw);
        }
      case 8:
        _rightTrigger = _normalizeRawTrigger(raw);
      default:
        break;
    }
  }

  void _applyRawButton(String key, bool pressed) {
    final index = int.tryParse(key);
    if (index == null) {
      return;
    }
    // Xbox js: A=0, Start=7. Deck native: A=3, Start=12.
    if (index == 0 || index == 3) {
      _a = pressed;
    }
    if (index == 1 || index == 4) {
      _b = pressed;
    }
    if (index == 6) {
      _b = pressed;
    }
    if (index == 7 || index == 12) {
      _start = pressed;
    }
  }

  void _publishRightFromRaw() {
    final chosen = _useSdlRightStick
        ? Vector2(_raw2, -_raw3)
        : Vector2(_raw3, -_raw4);
    if (chosen.length < GameConfig.stickDeadzone) {
      return;
    }
    _rightX = chosen.x;
    _rightY = chosen.y;
  }

  void _learnAxis2(double stick) {
    _axis2Rest ??= stick;
    if (_axis2Rest!.abs() < 0.3) {
      _axis2IsStick = true;
    }
  }

  /// Deck native (and some Valve pads) put the right stick on axes 2/3.
  /// Xbox / Steam Virtual use 3/4; axis 2 is the left trigger there.
  bool get _useSdlRightStick {
    if (_axis2IsStick) {
      return true;
    }
    final vendor = _vendorId;
    final product = _productId;
    if (vendor == 0x28de && (product == 0x1205 || product == 0x0512)) {
      return true;
    }
    return false;
  }

  double _normalizeRawStick(double raw) {
    if (raw.abs() > 1.5) {
      return (raw / 32767.0).clamp(-1.0, 1.0);
    }
    return raw.clamp(-1.0, 1.0);
  }

  double _normalizeRawTrigger(double raw) {
    if (raw.abs() > 1.5) {
      return ((raw + 32768) / 65535).clamp(0.0, 1.0);
    }
    if (raw < 0) {
      return ((raw + 1) / 2).clamp(0.0, 1.0);
    }
    return raw.clamp(0.0, 1.0);
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
    if (_b && !_wasB) {
      _pendingActions.add(GameAction.quit);
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
    _wasB = _b;
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
    return hostEnv('SteamDeck') == '1' ||
        hostEnv('DASH_RAMBO_FULLSCREEN') == '1';
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
