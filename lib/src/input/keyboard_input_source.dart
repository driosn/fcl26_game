import 'package:flutter/services.dart';

import 'input_device.dart';
import 'input_source.dart';
import 'input_state.dart';

/// Keyboard implementation of [InputSource]: arrow keys for movement, with WASD
/// as an alternative.
class KeyboardInputSource implements InputSource {
  KeyboardInputSource({Set<LogicalKeyboardKey> Function()? heldKeys})
    : _overrideHeldKeys = heldKeys;

  /// Test seam. When set, [poll] reads this instead of the engine or Flame.
  final Set<LogicalKeyboardKey> Function()? _overrideHeldKeys;

  // These cannot be `const`, since LogicalKeyboardKey overrides `==`.
  static final _up = {LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW};
  static final _down = {LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS};
  static final _left = {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA};
  static final _right = {
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
  };
  static final _pause = {LogicalKeyboardKey.escape, LogicalKeyboardKey.keyP};
  static final _confirm = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
  };
  static final _dash = {
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.space,
  };

  static final Set<LogicalKeyboardKey> _handledKeys = {
    ..._up,
    ..._down,
    ..._left,
    ..._right,
    ..._pause,
    ..._confirm,
    ..._dash,
  };

  /// Last set Flame delivered. Used only when [HardwareKeyboard] is unavailable
  /// (headless `flame_test` games).
  final Set<LogicalKeyboardKey> _eventKeys = {};

  final Set<GameAction> _pendingActions = {};

  /// Discrete commands, plus a copy of [keysPressed] for headless tests.
  bool handleKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _eventKeys
      ..clear()
      ..addAll(keysPressed);
    if (event is KeyDownEvent) {
      if (_pause.contains(event.logicalKey)) {
        _pendingActions.add(GameAction.pauseToggle);
      }
      if (_confirm.contains(event.logicalKey)) {
        _pendingActions.add(GameAction.confirm);
      }
      if (_dash.contains(event.logicalKey)) {
        _pendingActions.add(GameAction.dash);
      }
    }
    return _handledKeys.contains(event.logicalKey);
  }

  @override
  void poll(InputState state) {
    final pressed = _overrideHeldKeys != null
        ? _overrideHeldKeys!()
        : (_engineKeyboardAvailable ? _engineHeldKeys() : _eventKeys);
    var spoke = false;
    if (_isDown(pressed, _left)) {
      state.moveDirection.x -= 1;
      spoke = true;
    }
    if (_isDown(pressed, _right)) {
      state.moveDirection.x += 1;
      spoke = true;
    }
    if (_isDown(pressed, _up)) {
      state.moveDirection.y -= 1;
      spoke = true;
    }
    if (_isDown(pressed, _down)) {
      state.moveDirection.y += 1;
      spoke = true;
    }
    if (spoke) {
      state.noteDevice(InputDeviceKind.keyboard);
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
    _pendingActions.clear();
  }

  static Set<LogicalKeyboardKey> _engineHeldKeys() {
    try {
      return HardwareKeyboard.instance.logicalKeysPressed;
    } on Object {
      return const {};
    }
  }

  static bool get _engineKeyboardAvailable {
    try {
      HardwareKeyboard.instance;
      return true;
    } on Object {
      return false;
    }
  }

  bool _isDown(Set<LogicalKeyboardKey> pressed, Set<LogicalKeyboardKey> keys) =>
      keys.any(pressed.contains);
}
