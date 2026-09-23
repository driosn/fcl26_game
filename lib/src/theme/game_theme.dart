import 'package:flutter/material.dart';

import 'game_palette.dart';
import 'game_typography.dart';

/// Wires [GamePalette] and [GameTypography] into the Material widgets the menus
/// are built from, so buttons and dialogs never need per-call styling.
abstract final class GameTheme {
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: GamePalette.letterbox,
      colorScheme: base.colorScheme.copyWith(
        primary: GamePalette.accent,
        onPrimary: GamePalette.letterbox,
        surface: GamePalette.panel,
        onSurface: GamePalette.textPrimary,
        error: GamePalette.danger,
      ),
      textTheme: base.textTheme.apply(fontFamily: GameTypography.fontFamily),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GamePalette.textSecondary,
          textStyle: GameTypography.button,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GamePalette.accent,
          textStyle: GameTypography.button.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GamePalette.textMuted,
          textStyle: GameTypography.button,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}
