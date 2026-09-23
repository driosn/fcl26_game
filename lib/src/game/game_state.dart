import 'package:flutter/foundation.dart';

import 'game_config.dart';

enum GameStatus { playing, paused, gameOver }

/// Observable run state shared between the Flame world and the Flutter HUD.
///
/// Keeping this outside the component tree is what lets the HUD live as a
/// Flutter overlay, and later be swapped for Rive animations, without gameplay
/// code knowing anything about it.
class GameState {
  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> hp = ValueNotifier(GameConfig.playerMaxHp);
  final ValueNotifier<int> kills = ValueNotifier(0);
  final ValueNotifier<GameStatus> status = ValueNotifier(GameStatus.playing);

  /// Whole seconds survived. Only notifies when the integer changes, to avoid
  /// rebuilding the HUD on every frame.
  final ValueNotifier<int> survivedSeconds = ValueNotifier(0);

  /// Remaining rapid fire time, normalized to 0..1 for the HUD bar.
  final ValueNotifier<double> rapidFireProgress = ValueNotifier(0);

  double _elapsed = 0;

  /// Seconds elapsed in the current run, used to scale difficulty.
  double get elapsed => _elapsed;

  bool get isPlaying => status.value == GameStatus.playing;

  void tick(double dt) {
    _elapsed += dt;
    final whole = _elapsed.floor();
    if (whole != survivedSeconds.value) {
      survivedSeconds.value = whole;
    }
  }

  void addKill({required int points}) {
    score.value += points;
    kills.value += 1;
  }

  void reset() {
    _elapsed = 0;
    score.value = 0;
    kills.value = 0;
    hp.value = GameConfig.playerMaxHp;
    survivedSeconds.value = 0;
    rapidFireProgress.value = 0;
    status.value = GameStatus.playing;
  }

  void dispose() {
    score.dispose();
    hp.dispose();
    kills.dispose();
    status.dispose();
    survivedSeconds.dispose();
    rapidFireProgress.dispose();
  }
}
