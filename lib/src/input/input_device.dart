/// Which physical device last contributed intent this session.
///
/// The HUD reads this to pick keyboard caps or Steam Deck glyphs. Gameplay
/// never branches on it except for “aim follows movement” on keyboard.
enum InputDeviceKind { keyboard, gamepad }
