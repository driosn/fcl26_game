import 'package:flutter/material.dart';

import '../game/brotato_game.dart';
import '../input/input_device.dart';
import '../theme/game_palette.dart';
import 'menu_panel.dart';
import 'prompt_set.dart';
import 'run_stats.dart';
import 'widgets/chips.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({required this.game, super.key});

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    final actions = [
      MenuAction(label: 'Reintentar', onPressed: game.restart, primary: true),
      MenuAction(label: 'Salir', onPressed: game.quit),
    ];

    return MenuPanel(
      game: game,
      title: 'Misión Fallida',
      accent: GamePalette.danger,
      details: MenuStats(entries: runStats(game.state)),
      hint: ValueListenableBuilder<int>(
        valueListenable: game.menuNav.index,
        builder: (context, index, _) {
          final label = actions[index.clamp(0, actions.length - 1)].label;
          return ValueListenableBuilder<bool>(
            valueListenable: game.gamepadSource.connected,
            builder: (context, pad, _) {
              return ValueListenableBuilder<InputDeviceKind>(
                valueListenable: game.inputState.lastDevice,
                builder: (context, last, _) => PromptLine.forId(
                  device: promptDevice(lastDevice: last, gamepadConnected: pad),
                  id: PromptId.confirm,
                  label: label,
                ),
              );
            },
          );
        },
      ),
      actions: actions,
    );
  }
}
