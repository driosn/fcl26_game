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
    return MenuPanel(
      title: 'Misión Fallida',
      accent: GamePalette.danger,
      details: MenuStats(entries: runStats(game.state)),
      hint: ValueListenableBuilder<InputDeviceKind>(
        valueListenable: game.inputState.lastDevice,
        builder: (context, device, _) => PromptLine.forId(
          device: device,
          id: PromptId.confirm,
          label: 'Reintentar',
        ),
      ),
      actions: [
        MenuAction(label: 'Reintentar', onPressed: game.restart, primary: true),
      ],
    );
  }
}
