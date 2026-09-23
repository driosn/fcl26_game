import 'dart:ui';

import 'package:flame/components.dart';

import '../game/brotato_game.dart';
import '../game/game_config.dart';

/// The playfield backdrop.
///
/// Worth its own component because the world is a fixed 1280x720 box that gets
/// letterboxed inside a larger window: without a drawn frame there would be no
/// telling where the walls are.
class Arena extends PositionComponent with HasGameReference<FCLGame> {
  Arena()
    : super(
        size: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
        priority: -100,
      );

  @override
  void render(Canvas canvas) {
    game.skin.paintArena(canvas, Size(size.x, size.y));
  }
}
