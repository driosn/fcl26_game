import '../game/game_state.dart';

/// `m:ss`, the format players expect on a survival clock.
String formatClock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// The numbers both the pause and the game over menus report, so the two screens
/// can never drift apart.
List<(String, String)> runStats(GameState state) => [
  ('Puntos', '${state.score.value}'),
  ('Eliminaciones', '${state.kills.value}'),
  ('Tiempo', formatClock(state.survivedSeconds.value)),
];
