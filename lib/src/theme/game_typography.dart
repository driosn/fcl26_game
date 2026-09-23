import 'package:flutter/painting.dart';

import 'game_palette.dart';

/// The type scale for every piece of text in the game.
///
/// Labels stay small-caps and tracked; values are large enough to read at a
/// glance over the playfield, like a shipped twin-stick HUD.
abstract final class GameTypography {
  static const String? fontFamily = null;

  /// Fixed-width digits, so counters do not wobble as they tick.
  static const List<FontFeature> _steadyDigits = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    color: GamePalette.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    height: 1.1,
  );

  static const TextStyle score = TextStyle(
    fontFamily: fontFamily,
    color: GamePalette.accent,
    fontSize: 56,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    height: 1,
    fontFeatures: _steadyDigits,
    shadows: [
      Shadow(color: GamePalette.scoreShadow, blurRadius: 10, offset: Offset(0, 2)),
      Shadow(color: GamePalette.scoreGlow, blurRadius: 18),
    ],
  );

  static const TextStyle clock = TextStyle(
    fontFamily: fontFamily,
    color: GamePalette.textPrimary,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    height: 1,
    fontFeatures: _steadyDigits,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    color: GamePalette.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
    fontFeatures: _steadyDigits,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    color: GamePalette.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.4,
    height: 1,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: fontFamily,
    color: GamePalette.textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1,
    fontFeatures: _steadyDigits,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: fontFamily,
    color: GamePalette.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static const TextStyle keyCap = TextStyle(
    fontFamily: fontFamily,
    color: GamePalette.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    height: 1,
  );
}
