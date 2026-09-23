import 'package:flutter/material.dart';

import '../game/brotato_game.dart';
import '../input/input_device.dart';
import '../theme/game_palette.dart';
import 'menu_panel.dart';
import 'prompt_set.dart';
import 'run_stats.dart';
import 'widgets/chips.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.game, super.key});

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    final actions = [
      MenuAction(
        label: 'Continuar',
        onPressed: game.togglePause,
        primary: true,
      ),
      MenuAction(label: 'Reiniciar', onPressed: game.restart),
      MenuAction(label: 'Salir', onPressed: game.quit),
    ];

    return MenuPanel(
      game: game,
      title: 'Alto el Fuego',
      accent: GamePalette.accent,
      details: MenuStats(entries: runStats(game.state)),
      hint: ValueListenableBuilder<int>(
        valueListenable: game.menuNav.index,
        builder: (context, index, _) {
          final label = actions[index.clamp(0, actions.length - 1)].label;
          return ValueListenableBuilder<InputDeviceKind>(
            valueListenable: game.inputState.lastDevice,
            builder: (context, device, _) => PromptLine.forId(
              device: device,
              id: PromptId.confirm,
              label: label,
            ),
          );
        },
      ),
      actions: actions,
    );
  }
}
