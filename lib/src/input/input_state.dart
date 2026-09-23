import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../platform/host.dart';
import 'input_device.dart';

/// Continuous input intent for the current frame.
///
/// Gameplay components only ever read from this buffer, never from raw keyboard
/// or gamepad events. That indirection is what makes adding a Steam Deck
/// controller a matter of writing one new `InputSource`.
class InputState {
  InputState({InputDeviceKind? initialDevice})
    : lastDevice = ValueNotifier(initialDevice ?? defaultInputDevice());

  /// Normalized movement direction. Zero when the player is standing still.
  final Vector2 moveDirection = Vector2.zero();

  /// Independent aim, typically the right stick. Zero when nobody is aiming
  /// analog this frame, in which case the player keeps the last facing (pad)
  /// or follows [moveDirection] (keyboard).
  final Vector2 aimDirection = Vector2.zero();

  /// Last device that contributed movement, aim, or an action.
  final ValueNotifier<InputDeviceKind> lastDevice;

  /// Latest cursor position in world space. Sticky until the next move.
  Vector2? pointerWorld;

  void setPointerWorld(Vector2 world) {
    pointerWorld = Vector2.copy(world);
  }

  void noteDevice(InputDeviceKind kind) {
    if (lastDevice.value != kind) {
      lastDevice.value = kind;
    }
  }

  void beginFrame() {
    moveDirection.setZero();
    aimDirection.setZero();
  }

  void endFrame() {
    if (moveDirection.length2 > 1) {
      moveDirection.normalize();
    }
    if (aimDirection.length2 > 1) {
      aimDirection.normalize();
    }
  }

  void dispose() {
    lastDevice.dispose();
  }

  /// SteamOS Gaming Mode sets `SteamDeck=1`. Elsewhere we start on keyboard
  /// prompts until a pad actually speaks.
  static InputDeviceKind defaultInputDevice() {
    final deck = hostEnv('SteamDeck');
    final fullscreen = hostEnv('DASH_RAMBO_FULLSCREEN');
    if (deck == '1' || fullscreen == '1') {
      return InputDeviceKind.gamepad;
    }
    return InputDeviceKind.keyboard;
  }
}
