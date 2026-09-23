import 'dart:math';
import 'dart:ui';

import 'package:fcl_26_game/src/components/bullet.dart';
import 'package:fcl_26_game/src/components/enemy.dart';
import 'package:fcl_26_game/src/components/enemy_type.dart';
import 'package:fcl_26_game/src/components/power_up.dart';
import 'package:fcl_26_game/src/game/brotato_game.dart';
import 'package:fcl_26_game/src/render/game_skin.dart';
import 'package:fcl_26_game/src/render/shape_skin.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for a future sprite or Rive skin: it draws nothing and only records
/// that it was asked to.
class _RecordingSkin extends GameSkin {
  final List<String> calls = [];
  int loadCount = 0;

  @override
  Future<void> load() async => loadCount++;

  @override
  void paintArena(Canvas canvas, Size size) => calls.add('arena');

  @override
  void paintPlayer(
    Canvas canvas,
    Offset center, {
    required double radius,
    required bool hurt,
  }) => calls.add('player');

  @override
  void paintEnemy(
    Canvas canvas,
    Offset center, {
    required EnemyStats stats,
    required double flash,
    required double healthFraction,
    required double heading,
  }) => calls.add('enemy:${stats.type.name}');

  @override
  void paintBullet(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double heading,
  }) => calls.add('bullet');

  @override
  void paintPowerUp(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double age,
  }) => calls.add('power-up');

  @override
  void paintAim(
    Canvas canvas,
    Offset center, {
    required double tailRadius,
    required double length,
    required double coneLength,
    required double spread,
  }) => calls.add('aim');
}

/// Draws a frame of [game] into a throwaway canvas.
void _renderFrame(FCLGame game) {
  final recorder = PictureRecorder();
  game.render(Canvas(recorder));
  recorder.endRecording().dispose();
}

void main() {
  group('the skin seam', () {
    late _RecordingSkin skin;

    FCLGame newGame() {
      skin = _RecordingSkin();
      return FCLGame(random: Random(7), skin: skin);
    }

    testWithGame<FCLGame>('a skin gets to load before the first frame', () {
      skin = _RecordingSkin();
      return FCLGame(random: Random(7), skin: skin);
    }, (game) async {
      expect(skin.loadCount, 1);
    });

    testWithGame<FCLGame>(
      'every entity in the world draws through the skin',
      newGame,
      (game) async {
        // The point of the whole seam: swapping this one object has to be enough
        // to restyle the game, which only holds if no component paints itself.
        game.world.addAll([
          Enemy(stats: EnemyStats.tank, position: Vector2(200, 200)),
          Bullet(position: Vector2(300, 300), direction: Vector2(1, 0)),
          PowerUp(position: Vector2(400, 400)),
        ]);
        await game.ready();

        skin.calls.clear();
        _renderFrame(game);

        expect(
          skin.calls,
          containsAll([
            'arena',
            'player',
            'enemy:tank',
            'bullet',
            'power-up',
          ]),
        );
        expect(skin.calls, isNot(contains('aim')));
      },
    );

    testWithGame<FCLGame>('the default skin needs no assets', newGame, (
      game,
    ) async {
      expect(FCLGame().skin, isA<ShapeSkin>());
    });
  });

  group('ShapeSkin', () {
    final skin = ShapeSkin();

    /// Exercises the real drawing code, which a recording fake cannot vouch for.
    void paint(void Function(Canvas canvas) body) {
      final recorder = PictureRecorder();
      body(Canvas(recorder));
      recorder.endRecording().dispose();
    }

    test('paints the arena', () {
      expect(
        () => paint((canvas) => skin.paintArena(canvas, const Size(1280, 720))),
        returnsNormally,
      );
    });

    test('paints the player in both states', () {
      for (final hurt in [false, true]) {
        expect(
          () => paint(
            (canvas) => skin.paintPlayer(
              canvas,
              Offset.zero,
              radius: 14,
              hurt: hurt,
            ),
          ),
          returnsNormally,
        );
      }
    });

    test('paints every enemy type, hurt and healthy', () {
      for (final type in EnemyType.values) {
        for (final flash in [0.0, 1.0]) {
          expect(
            () => paint(
              (canvas) => skin.paintEnemy(
                canvas,
                Offset.zero,
                stats: EnemyStats.of(type),
                flash: flash,
                healthFraction: 0.4,
                heading: 1.2,
              ),
            ),
            returnsNormally,
            reason: '$type at flash $flash',
          );
        }
      }
    });

    test('paints bullets, pickups and the aim guide', () {
      expect(
        () => paint((canvas) {
          skin.paintBullet(canvas, Offset.zero, radius: 4, heading: 0.5);
          skin.paintPowerUp(canvas, Offset.zero, radius: 13, age: 3.2);
          skin.paintAim(
            canvas,
            Offset.zero,
            tailRadius: 20,
            length: 22,
            coneLength: 68,
            spread: 0.14,
          );
        }),
        returnsNormally,
      );
    });
  });
}
