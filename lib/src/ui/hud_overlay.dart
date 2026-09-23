import 'package:flutter/material.dart';

import '../game/brotato_game.dart';
import '../game/game_config.dart';
import '../input/input_device.dart';
import '../theme/game_palette.dart';
import '../theme/game_typography.dart';
import 'prompt_set.dart';
import 'run_stats.dart';
import 'widgets/chips.dart';
import 'widgets/dash_portrait.dart';
import 'widgets/game_icons.dart';
import 'widgets/game_panel.dart';
import 'widgets/hud_rive.dart';
import 'widgets/meter.dart';

/// Score, clock, health and buffs, drawn over the playfield.
///
/// The chrome is a Rive artboard when the catalog has loaded. Numbers stay
/// Flutter so they stay sharp and testable. A painted Dash portrait is the
/// fallback for the health tank.
class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  static const int criticalHp = GameConfig.hudCriticalHp;

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _LowHealthVignette(game: game),
        SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 148,
                        child: _HudChrome(game: game),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: _HealthBlock(game: game),
                              ),
                            ),
                            _ClockBlock(game: game),
                            Flexible(
                              child: ValueListenableBuilder<double>(
                                valueListenable: game.state.rapidFireProgress,
                                builder: (context, progress, _) => Padding(
                                  padding: EdgeInsets.only(
                                    right: progress > 0 ? 196 : 0,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: _ScoreBlock(game: game),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ControlsHint(game: game),
                  ),
                ],
              ),
              Positioned(top: 14, right: 16, child: _PowerUpBadge(game: game)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HudChrome extends StatelessWidget {
  const _HudChrome({required this.game});

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    if (!game.enableRive) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: game.rive.ready,
      builder: (context, ready, _) {
        if (!ready || !game.rive.isLoaded) {
          return const SizedBox.shrink();
        }
        return HudRiveBar(game: game);
      },
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.game});

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    return _HudPlate(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('PUNTOS', style: GameTypography.label),
          const SizedBox(height: 2),
          ValueListenableBuilder<int>(
            valueListenable: game.state.score,
            builder: (context, score, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('$score', style: GameTypography.score),
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<int>(
            valueListenable: game.state.kills,
            builder: (context, kills, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ELIMINACIONES', style: GameTypography.label),
                const SizedBox(width: 8),
                Text('$kills', style: GameTypography.statValue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockBlock extends StatelessWidget {
  const _ClockBlock({required this.game});

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    return _HudPlate(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('TIEMPO', style: GameTypography.label),
          const SizedBox(height: 4),
          ValueListenableBuilder<int>(
            valueListenable: game.state.survivedSeconds,
            builder: (context, seconds, _) =>
                Text(formatClock(seconds), style: GameTypography.clock),
          ),
        ],
      ),
    );
  }
}

class _HealthBlock extends StatelessWidget {
  const _HealthBlock({required this.game});

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.state.hp,
      builder: (context, hp, _) {
        final warning = hp > 0 && hp <= HudOverlay.criticalHp;
        return _HudPlate(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DashPortrait(
                health: hp / GameConfig.playerMaxHp,
                warning: warning,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('VIDA', style: GameTypography.label),
                  const SizedBox(height: 4),
                  Text(
                    '$hp / ${GameConfig.playerMaxHp}',
                    style: GameTypography.statValue.copyWith(
                      color: warning
                          ? GamePalette.danger
                          : GamePalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HudPlate extends StatelessWidget {
  const _HudPlate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      radius: 16,
      child: child,
    );
  }
}

class _PowerUpBadge extends StatelessWidget {
  const _PowerUpBadge({required this.game});

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: game.state.rapidFireProgress,
      builder: (context, progress, _) {
        final seconds = (progress * GameConfig.rapidFireDuration).ceil();
        return AnimatedOpacity(
          opacity: progress > 0 ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: GamePanel(
            accent: GamePalette.powerUp,
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
            radius: 18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(GameIcons.rapidFire, color: GamePalette.powerUp, size: 36),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RÁFAGA x${GameConfig.rapidFireMultiplier.toInt()}',
                      style: GameTypography.statValue.copyWith(
                        color: GamePalette.powerUp,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$seconds s',
                      style: GameTypography.chip.copyWith(
                        color: GamePalette.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Meter(
                      value: progress,
                      tint: GamePalette.powerUp,
                      width: 120,
                      height: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlsHint extends StatelessWidget {
  const _ControlsHint({required this.game});

  final FCLGame game;

  static const int _fadeAfterSeconds = 7;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.state.survivedSeconds,
      builder: (context, seconds, _) {
        return AnimatedOpacity(
          opacity: seconds < _fadeAfterSeconds ? 1 : 0,
          duration: const Duration(milliseconds: 700),
          child: ValueListenableBuilder<bool>(
            valueListenable: game.gamepadSource.connected,
            builder: (context, pad, _) {
              return ValueListenableBuilder<InputDeviceKind>(
                valueListenable: game.inputState.lastDevice,
                builder: (context, lastDevice, _) {
                  final device = promptDevice(
                    lastDevice: lastDevice,
                    gamepadConnected: pad,
                  );
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: GamePanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PromptLine.forId(
                            device: device,
                            id: PromptId.move,
                            label: 'Mover',
                          ),
                          if (device == InputDeviceKind.gamepad) ...[
                            const SizedBox(width: 16),
                            PromptLine.forId(
                              device: device,
                              id: PromptId.aim,
                              label: 'Apuntar',
                            ),
                          ],
                          const SizedBox(width: 16),
                          PromptLine.forId(
                            device: device,
                            id: PromptId.dash,
                            label: 'Dash',
                          ),
                          const SizedBox(width: 16),
                          PromptLine.forId(
                            device: device,
                            id: PromptId.pause,
                            label: 'Pausa',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _LowHealthVignette extends StatelessWidget {
  const _LowHealthVignette({required this.game});

  final FCLGame game;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ValueListenableBuilder<int>(
        valueListenable: game.state.hp,
        builder: (context, hp, child) => AnimatedOpacity(
          opacity: hp > 0 && hp <= HudOverlay.criticalHp ? 1 : 0,
          duration: const Duration(milliseconds: 450),
          child: child,
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.95,
              colors: [Color(0x00000000), Color(0x4DFF4D6D)],
              stops: [0.5, 1],
            ),
          ),
        ),
      ),
    );
  }
}
