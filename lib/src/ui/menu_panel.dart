import 'package:flutter/material.dart';

import '../theme/game_palette.dart';
import '../theme/game_typography.dart';

@immutable
class MenuAction {
  const MenuAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// Brighter text. Exactly one action per menu should be primary, so there is
  /// never a question about what Enter is going to do.
  final bool primary;
}

/// Shared dimmed backdrop behind the pause and game over menus.
class MenuPanel extends StatelessWidget {
  const MenuPanel({
    required this.title,
    required this.actions,
    this.accent = GamePalette.accent,
    this.details,
    this.hint,
    super.key,
  });

  final String title;
  final List<MenuAction> actions;
  final Color accent;
  final Widget? details;
  final Widget? hint;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GamePalette.scrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: GameTypography.display.copyWith(color: accent)),
            if (details != null) ...[const SizedBox(height: 20), details!],
            const SizedBox(height: 28),
            ExcludeFocus(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final action in actions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextButton(
                        onPressed: action.onPressed,
                        style: action.primary
                            ? TextButton.styleFrom(foregroundColor: accent)
                            : null,
                        child: Text(action.label),
                      ),
                    ),
                ],
              ),
            ),
            if (hint != null) ...[const SizedBox(height: 16), hint!],
          ],
        ),
      ),
    );
  }
}

/// A row of numbers summarising a run.
class MenuStats extends StatelessWidget {
  const MenuStats({required this.entries, super.key});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (index, (label, value)) in entries.indexed) ...[
          if (index > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('·', style: GameTypography.label),
            ),
          Text('$value  $label', style: GameTypography.chip),
        ],
      ],
    );
  }
}
