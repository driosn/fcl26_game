import 'package:flutter/material.dart';

import '../game/brotato_game.dart';
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
  /// never a question about what Enter / A does when the panel first opens.
  final bool primary;
}

/// Shared dimmed backdrop behind the pause and game over menus.
class MenuPanel extends StatefulWidget {
  const MenuPanel({
    required this.game,
    required this.title,
    required this.actions,
    this.accent = GamePalette.accent,
    this.details,
    this.hint,
    super.key,
  });

  final FCLGame game;
  final String title;
  final List<MenuAction> actions;
  final Color accent;
  final Widget? details;
  final Widget? hint;

  @override
  State<MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<MenuPanel> {
  @override
  void initState() {
    super.initState();
    _bindNav();
  }

  @override
  void didUpdateWidget(MenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameLabels(oldWidget.actions, widget.actions)) {
      _bindNav();
    }
  }

  bool _sameLabels(List<MenuAction> a, List<MenuAction> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    widget.game.menuNav.unbind();
    super.dispose();
  }

  void _bindNav() {
    final initial = widget.actions.indexWhere((action) => action.primary);
    widget.game.menuNav.bind(
      widget.actions.map((action) => action.onPressed).toList(),
      initial: initial < 0 ? 0 : initial,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GamePalette.scrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: GameTypography.display.copyWith(color: widget.accent),
            ),
            if (widget.details != null) ...[
              const SizedBox(height: 20),
              widget.details!,
            ],
            const SizedBox(height: 28),
            ExcludeFocus(
              child: ValueListenableBuilder<int>(
                valueListenable: widget.game.menuNav.index,
                builder: (context, selected, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final (index, action) in widget.actions.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _MenuButton(
                            action: action,
                            accent: widget.accent,
                            selected: index == selected,
                            onHover: () => widget.game.menuNav.select(index),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (widget.hint != null) ...[
              const SizedBox(height: 16),
              widget.hint!,
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.action,
    required this.accent,
    required this.selected,
    required this.onHover,
  });

  final MenuAction action;
  final Color accent;
  final bool selected;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: TextButton(
          onPressed: action.onPressed,
          style: action.primary || selected
              ? TextButton.styleFrom(foregroundColor: accent)
              : null,
          child: Text(action.label),
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
