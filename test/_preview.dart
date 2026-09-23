import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:fcl_26_game/src/components/bullet.dart';
import 'package:fcl_26_game/src/components/enemy.dart';
import 'package:fcl_26_game/src/components/enemy_type.dart';
import 'package:fcl_26_game/src/components/power_up.dart';
import 'package:fcl_26_game/src/game/brotato_game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';

void main() {
  testWithGame<FCLGame>('world preview', () => FCLGame(random: Random(11)), (
    game,
  ) async {
    game.onGameResize(Vector2(1280, 720));
    game.world.removeWhere((c) => c.runtimeType.toString().contains('Spawner'));
    await game.ready();

    final player = game.player!;
    player.position.setValues(430, 400);
    player.facing.setValues(0.82, -0.57);

    final aim = Vector2(0.82, -0.57)..normalize();
    for (var i = 1; i <= 7; i++) {
      game.world.add(
        Bullet(
          position: player.position + aim * (30.0 + i * 52),
          direction: aim.clone(),
        ),
      );
    }

    final tank = Enemy(stats: EnemyStats.tank, position: Vector2(880, 190));
    final runner = Enemy(
      stats: EnemyStats.runner,
      position: Vector2(1030, 470),
    );
    game.world.addAll([
      tank,
      runner,
      Enemy(stats: EnemyStats.grunt, position: Vector2(700, 150)),
      Enemy(stats: EnemyStats.grunt, position: Vector2(240, 250)),
      Enemy(stats: EnemyStats.grunt, position: Vector2(620, 600)),
      PowerUp(position: Vector2(250, 590)),
    ]);
    await game.ready();

    // Chip the tank so its health ring shows, and catch the runner mid-hit.
    tank.takeDamage(2);
    runner.takeDamage(1);
    game.update(1 / 600);

    final recorder = PictureRecorder();
    game.render(Canvas(recorder));
    final image = await recorder.endRecording().toImage(1280, 720);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    File('preview_world.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
