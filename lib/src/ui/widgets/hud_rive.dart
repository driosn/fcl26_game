import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../game/brotato_game.dart';
import '../../game/game_config.dart';

/// The Rive HUD chrome: plates, the Dash portrait tank, and the rapid-fire bar.
class HudRiveBar extends StatefulWidget {
  const HudRiveBar({required this.game, super.key});

  final FCLGame game;

  @override
  State<HudRiveBar> createState() => _HudRiveBarState();
}

class _HudRiveBarState extends State<HudRiveBar> {
  RiveWidgetController? _controller;
  ViewModelInstance? _viewModel;
  ViewModelInstanceNumber? _health;
  ViewModelInstanceNumber? _rapid;
  ViewModelInstanceBoolean? _warning;

  @override
  void initState() {
    super.initState();
    _mount();
    widget.game.state.hp.addListener(_sync);
    widget.game.state.rapidFireProgress.addListener(_sync);
  }

  @override
  void dispose() {
    widget.game.state.hp.removeListener(_sync);
    widget.game.state.rapidFireProgress.removeListener(_sync);
    _viewModel?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _mount() {
    final hud = widget.game.rive.createHud();
    if (hud == null) {
      return;
    }
    _controller = hud.controller;
    _viewModel = hud.viewModel;
    _health = _viewModel?.number('health');
    _rapid = _viewModel?.number('rapid');
    _warning = _viewModel?.boolean('warning');
    _sync();
  }

  void _sync() {
    final hp = widget.game.state.hp.value;
    _health?.value = hp / GameConfig.playerMaxHp;
    _rapid?.value = widget.game.state.rapidFireProgress.value;
    _warning?.value = hp > 0 && hp <= GameConfig.hudCriticalHp;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RiveWidget(
        controller: controller,
        fit: Fit.fitWidth,
        alignment: Alignment.topCenter,
        hitTestBehavior: RiveHitTestBehavior.transparent,
      ),
    );
  }
}
