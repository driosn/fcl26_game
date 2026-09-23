import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'src/game/brotato_game.dart';
import 'src/game/game_state.dart';
import 'src/theme/game_palette.dart';
import 'src/theme/game_theme.dart';
import 'src/ui/game_over_overlay.dart';
import 'src/ui/hud_overlay.dart';
import 'src/ui/pause_overlay.dart';

void main() {
  runApp(const FclGameApp());
}

class FclGameApp extends StatelessWidget {
  const FclGameApp({this.enableRive = true, super.key});

  /// Widget tests turn this off: `rive_native` cannot load its dylib inside
  /// `flutter test`, and a failed init is reported as a test error even when
  /// we catch it.
  final bool enableRive;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DASH RAMBO',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.build(),
      home: GameScreen(enableRive: enableRive),
    );
  }
}

/// Owns the game instance and layers the UI on top of it.
///
/// Which menu is visible is derived from [GameState.status] rather than pushed by
/// the game, so the simulation has no dependency on the widget tree.
class GameScreen extends StatefulWidget {
  const GameScreen({this.enableRive = true, super.key});

  final bool enableRive;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final FCLGame _game = FCLGame(
    enableRive: widget.enableRive,
    listenToGamepadHardware: widget.enableRive,
  );

  /// Owned here rather than left to `GameWidget`, because keyboard input depends
  /// entirely on this node holding *primary* focus: Flame silently drops every
  /// key event while it does not.
  final FocusNode _gameFocus = FocusNode(debugLabel: 'FCLGame');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // On desktop the window can open without keyboard focus, in which case the
    // widget's own autofocus is dropped and never retried. Claiming focus after
    // the first frame covers that case.
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _claimFocus();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_game.state.status.value == GameStatus.playing) {
          _game.togglePause();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameFocus.dispose();
    // Safe here: the listening builders below are disposed before their parent.
    _game.state.dispose();
    _game.inputState.dispose();
    super.dispose();
  }

  void _claimFocus() {
    if (mounted && !_gameFocus.hasPrimaryFocus) {
      _gameFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamePalette.letterbox,
      body: Listener(
        // The escape hatch: clicking anywhere hands keyboard control back to the
        // game, so focus can never be lost in a way the player cannot recover
        // from.
        onPointerDown: (_) => _claimFocus(),
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: Stack(
            children: [
              GameWidget<FCLGame>(
                game: _game,
                focusNode: _gameFocus,
                autofocus: true,
              ),
              // The HUD is purely informational, so it must never swallow input
              // meant for the game.
              IgnorePointer(child: HudOverlay(game: _game)),
              ValueListenableBuilder<GameStatus>(
                valueListenable: _game.state.status,
                builder: (context, status, _) => switch (status) {
                  GameStatus.playing => const SizedBox.shrink(),
                  GameStatus.paused => PauseOverlay(game: _game),
                  GameStatus.gameOver => GameOverOverlay(game: _game),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
