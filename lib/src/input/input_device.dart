/// Which physical device last contributed intent this session.
///
/// The HUD reads this to pick keyboard caps or Steam Deck glyphs. Gameplay
/// never branches on it except for “aim follows movement” on keyboard.
enum InputDeviceKind { keyboard, gamepad }

/// Prompts follow a connected pad, not the last keypress.
///
/// On the Deck the built-in controls are always there; showing ESC after a
/// stray keyboard event would be wrong.
InputDeviceKind promptDevice({
  required InputDeviceKind lastDevice,
  required bool gamepadConnected,
}) {
  return gamepadConnected ? InputDeviceKind.gamepad : lastDevice;
}
