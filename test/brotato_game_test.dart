import 'dart:math' as math;

import 'package:fcl_26_game/src/components/bullet.dart';
import 'package:fcl_26_game/src/components/enemy.dart';
import 'package:fcl_26_game/src/components/enemy_type.dart';
import 'package:fcl_26_game/src/components/power_up.dart';
import 'package:fcl_26_game/src/components/weapon.dart';
import 'package:fcl_26_game/src/game/brotato_game.dart';
import 'package:fcl_26_game/src/game/game_config.dart';
import 'package:fcl_26_game/src/game/game_state.dart';
import 'package:fcl_26_game/src/systems/enemy_spawner.dart';
import 'package:fcl_26_game/src/systems/power_up_spawner.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seeded so that spawn positions and enemy types are reproducible.
FCLGame _newGame() =>
    FCLGame(random: math.Random(1234), listenToGamepadHardware: false);

/// Advances the simulation by [seconds] in 60 fps steps.
Future<void> _advance(FCLGame game, double seconds) async {
  const step = 1 / 60;
  for (var elapsed = 0.0; elapsed < seconds; elapsed += step) {
    game.update(step);
  }
  await game.ready();
}

Iterable<T> _find<T extends Component>(FCLGame game) =>
    game.world.children.whereType<T>();

/// Clears the arena of bullets, including any still queued for mounting.
///
/// The weapon fires on the very first tick, which `initializeGame` performs, so
/// tests that care about a specific shot have to discard that opening bullet.
Future<void> _clearBullets(FCLGame game) async {
  await game.ready();
  game.world.removeWhere((component) => component is Bullet);
  await game.ready();
}

/// Makes [key] the only key held down, as if the player had just tapped it.
void _pressOnly(FCLGame game, LogicalKeyboardKey key) {
  game.onKeyEvent(
    KeyDownEvent(
      logicalKey: key,
      physicalKey: PhysicalKeyboardKey.keyA,
      timeStamp: Duration.zero,
    ),
    {key},
  );
}

/// Removes the spawners so a test has full control over what is in the arena.
Future<void> _stopSpawners(FCLGame game) async {
  await game.ready();
  game.world.removeWhere(
    (component) => component is EnemySpawner || component is PowerUpSpawner,
  );
  await game.ready();
}

void main() {
  group('run setup', () {
    testWithGame<FCLGame>('starts with a player in the middle', _newGame, (
      game,
    ) async {
      expect(game.player, isNotNull);
      expect(game.player!.position.x, GameConfig.worldWidth / 2);
      expect(game.player!.position.y, GameConfig.worldHeight / 2);
      expect(game.state.status.value, GameStatus.playing);
    });
  });

  group('auto fire', () {
    testWithGame<FCLGame>('shoots without any input', _newGame, (game) async {
      await _advance(game, 0.1);
      expect(_find<Bullet>(game), isNotEmpty);
    });

    testWithGame<FCLGame>(
      'bullets fly towards where the player faces',
      _newGame,
      (game) async {
        final player = game.player!..facing.setValues(1, 0);
        await _clearBullets(game);

        await _advance(game, GameConfig.baseFireInterval + 0.02);
        final bullet = _find<Bullet>(game).single;
        final startX = bullet.position.x;

        await _advance(game, 0.1);
        expect(bullet.position.x, greaterThan(startX));

        // Spread means it will not be dead level with the player, but it has to
        // stay inside the cone.
        final travel = bullet.position - player.position;
        expect(
          math.atan2(travel.y, travel.x).abs(),
          lessThan(Weapon.maxSpread),
        );
      },
    );

    testWithGame<FCLGame>(
      'bullets despawn once they leave the arena',
      _newGame,
      (game) async {
        game.player!.facing.setValues(1, 0);
        // Long enough for the first bullets to cross the whole world.
        await _advance(game, 3);

        const margin = GameConfig.bulletDespawnMargin;
        for (final bullet in _find<Bullet>(game)) {
          expect(bullet.position.x, lessThan(GameConfig.worldWidth + margin));
          expect(bullet.position.x, greaterThan(-margin));
          expect(bullet.position.y, lessThan(GameConfig.worldHeight + margin));
          expect(bullet.position.y, greaterThan(-margin));
        }
      },
    );

    testWithGame<FCLGame>(
      'shots scatter instead of stacking in one line',
      _newGame,
      (game) async {
        game.player!.facing.setValues(1, 0);
        await _clearBullets(game);

        // Several shots, all aimed right, then compare how far each drifted off
        // the aim line.
        await _advance(game, GameConfig.baseFireInterval * 5);
        final offsets = _find<Bullet>(
          game,
        ).map((bullet) => bullet.position.y - game.player!.position.y).toList();

        expect(offsets.length, greaterThan(2));
        expect(
          offsets.toSet().length,
          greaterThan(1),
          reason: 'every bullet flew along the exact same line',
        );
      },
    );

    testWithGame<
      FCLGame
    >('the aim sweeps through the angles in between', _newGame, (game) async {
      // Walking right from a standing aim of up must not snap the aim sideways;
      // it has to pass through the diagonal so shots land there too.
      final player = game.player!;
      expect(player.facing.y, -1, reason: 'starts aiming up');

      _pressOnly(game, LogicalKeyboardKey.arrowRight);
      game.update(1 / 60);

      expect(player.facing.x, greaterThan(0), reason: 'leaning right already');
      expect(player.facing.y, lessThan(0), reason: 'still leaning up');
    });

    testWithGame<FCLGame>(
      'the right stick aims while the left stick moves independently',
      _newGame,
      (game) async {
        final player = game.player!;
        expect(player.facing.y, -1);
        final startX = player.position.x;

        // Stick up is +Y in pad space; the playfield is up = -Y.
        game.gamepadSource.setAxes(leftX: 1, rightY: 1);
        game.update(1 / 60);

        expect(player.position.x, greaterThan(startX));
        expect(
          player.facing.x.abs(),
          lessThan(0.15),
          reason: 'still aiming up',
        );
        expect(player.facing.y, closeTo(-1, 0.15));
      },
    );

    testWithGame<FCLGame>(
      'a gamepad left stick does not steal aim when the right stick is idle',
      _newGame,
      (game) async {
        final player = game.player!;
        game.gamepadSource.setAxes(leftX: 1);
        game.update(1 / 60);
        expect(player.facing.x.abs(), lessThan(0.05));
        expect(player.facing.y, closeTo(-1, 0.05));
      },
    );

    testWithGame<FCLGame>('the mouse aims independently of WASD', _newGame, (
      game,
    ) async {
      game.gamepadSource.connected.value = false;
      final player = game.player!;
      game.inputState.setPointerWorld(player.position + Vector2(0, 200));
      for (var i = 0; i < 45; i++) {
        game.update(1 / 60);
      }
      expect(player.facing.x.abs(), lessThan(0.25));
      expect(player.facing.y, closeTo(1, 0.25));
    });

    testWithGame<
      FCLGame
    >('flip flopping direction fires diagonally', _newGame, (game) async {
      // The complaint this behaviour exists for: alternating up and right as fast
      // as possible used to only ever shoot along those two axes.
      final player = game.player!;
      await _stopSpawners(game);
      await _clearBullets(game);

      var useRight = true;
      for (var flip = 0; flip < 30; flip++) {
        _pressOnly(
          game,
          useRight ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowUp,
        );
        useRight = !useRight;
        // Roughly a key tap every 50 ms.
        for (var frame = 0; frame < 3; frame++) {
          game.update(1 / 60);
        }
      }
      await game.ready();

      final diagonalShots = _find<Bullet>(game).where((bullet) {
        final travel = bullet.position - player.position;
        // Comfortably off both axes.
        return travel.x > 20 && travel.y < -20;
      });
      expect(diagonalShots, isNotEmpty);
    });

    testWithGame<
      FCLGame
    >('the aim itself is not thrown off by the spread', _newGame, (game) async {
      // Scattering a shot must not rotate the player's facing, or the aim would
      // wander on its own as the weapon fires.
      final player = game.player!..facing.setValues(1, 0);
      await _advance(game, GameConfig.baseFireInterval * 6);

      expect(player.facing.x, 1);
      expect(player.facing.y, 0);
    });

    testWithGame<FCLGame>(
      'rapid fire is exactly five times the base rate',
      _newGame,
      (game) async {
        final weapon = game.player!.weapon..activateRapidFire();
        expect(
          GameConfig.baseFireInterval / weapon.fireInterval,
          closeTo(GameConfig.rapidFireMultiplier, 1e-9),
        );
      },
    );

    testWithGame<FCLGame>(
      'rapid fire puts more bullets in the same window',
      _newGame,
      (game) async {
        // Aimed right so nothing despawns during the measurement windows.
        game.player!.facing.setValues(1, 0);
        await _clearBullets(game);
        await _advance(game, 0.6);
        final normalCount = _find<Bullet>(game).length;
        expect(normalCount, greaterThan(0));

        await _clearBullets(game);
        game.player!.weapon.activateRapidFire();
        await _advance(game, 0.6);

        expect(_find<Bullet>(game).length, greaterThan(normalCount));
      },
    );

    testWithGame<FCLGame>('the buff expires after its duration', _newGame, (
      game,
    ) async {
      final weapon = game.player!.weapon..activateRapidFire();
      expect(weapon.fireInterval, lessThan(GameConfig.baseFireInterval));

      await _advance(game, GameConfig.rapidFireDuration + 0.5);

      expect(weapon.fireInterval, GameConfig.baseFireInterval);
      expect(game.state.rapidFireProgress.value, 0);
    });
  });

  group('dash', () {
    testWithGame<FCLGame>(
      'shift bursts the player along their facing',
      _newGame,
      (game) async {
        final player = game.player!;
        final startY = player.position.y;
        expect(player.facing.y, -1);

        _pressOnly(game, LogicalKeyboardKey.shiftLeft);
        await _advance(game, GameConfig.dashDuration);

        expect(player.position.y, lessThan(startY));
        expect(
          startY - player.position.y,
          closeTo(GameConfig.dashSpeed * GameConfig.dashDuration, 8),
        );
      },
    );

    testWithGame<FCLGame>(
      'a second dash is ignored until the cooldown ends',
      _newGame,
      (game) async {
        final player = game.player!;
        _pressOnly(game, LogicalKeyboardKey.shiftLeft);
        await _advance(game, GameConfig.dashDuration);
        final afterFirst = player.position.clone();

        _pressOnly(game, LogicalKeyboardKey.shiftLeft);
        await _advance(game, GameConfig.dashDuration);

        expect(player.position.y, closeTo(afterFirst.y, 0.5));
      },
    );
  });

  group('enemies', () {
    testWithGame<FCLGame>(
      'spawn one at a time from outside the arena',
      _newGame,
      (game) async {
        await _advance(game, GameConfig.firstEnemyDelay + 0.1);

        final enemies = _find<Enemy>(game).toList();
        expect(enemies, hasLength(1));

        final position = enemies.single.position;
        final outside =
            position.x < 0 ||
            position.y < 0 ||
            position.x > GameConfig.worldWidth ||
            position.y > GameConfig.worldHeight;
        expect(outside, isTrue);
      },
    );

    testWithGame<FCLGame>('walk towards the player', _newGame, (game) async {
      await _advance(game, GameConfig.firstEnemyDelay + 0.1);

      final enemy = _find<Enemy>(game).single;
      final before = enemy.position.distanceTo(game.player!.position);

      await _advance(game, 0.5);
      expect(
        enemy.position.distanceTo(game.player!.position),
        lessThan(before),
      );
    });

    testWithGame<FCLGame>('keep coming one after another', _newGame, (
      game,
    ) async {
      await _advance(game, 5);
      // Enemies never leave on their own, so they accumulate over a run.
      expect(_find<Enemy>(game).length, greaterThanOrEqualTo(2));
    });

    testWithGame<FCLGame>('a grunt dies to a single bullet', _newGame, (
      game,
    ) async {
      final enemy = Enemy(stats: EnemyStats.grunt, position: Vector2(100, 100));
      await game.world.add(enemy);
      await game.ready();

      enemy.takeDamage(GameConfig.bulletDamage);
      await game.ready();

      expect(enemy.isAlive, isFalse);
      expect(enemy.isRemoved, isFalse);
      expect(game.state.score.value, EnemyStats.grunt.score);
      expect(game.state.kills.value, 1);

      await _advance(game, GameConfig.enemyDeathDuration);
      expect(enemy.isRemoved, isTrue);
    });

    testWithGame<FCLGame>('a tank needs its full hit count', _newGame, (
      game,
    ) async {
      final enemy = Enemy(stats: EnemyStats.tank, position: Vector2(100, 100));
      await game.world.add(enemy);
      await game.ready();

      for (var hit = 1; hit < EnemyStats.tank.hitsToKill; hit++) {
        enemy.takeDamage(1);
        await game.ready();
        expect(enemy.isRemoved, isFalse, reason: 'survives hit $hit');
        expect(game.state.score.value, 0);
      }

      enemy.takeDamage(1);
      await game.ready();
      expect(enemy.isAlive, isFalse);
      expect(enemy.isRemoved, isFalse);
      expect(game.state.score.value, EnemyStats.tank.score);

      await _advance(game, GameConfig.enemyDeathDuration);
      expect(enemy.isRemoved, isTrue);
    });

    testWithGame<FCLGame>('over-killing an enemy only scores once', _newGame, (
      game,
    ) async {
      final enemy = Enemy(stats: EnemyStats.grunt, position: Vector2(100, 100));
      await game.world.add(enemy);
      await game.ready();

      // Two bullets can land on the same enemy within one tick.
      enemy.takeDamage(1);
      enemy.takeDamage(1);
      await game.ready();

      expect(game.state.kills.value, 1);
      expect(game.state.score.value, EnemyStats.grunt.score);
    });

    testWithGame<FCLGame>(
      'auto fire eventually kills a nearby enemy',
      _newGame,
      (game) async {
        await _stopSpawners(game);
        final player = game.player!..facing.setValues(1, 0);
        await game.world.add(
          Enemy(
            stats: EnemyStats.grunt,
            position: player.position + Vector2(200, 0),
          ),
        );
        await game.ready();

        // Generous window, because spread means individual shots can miss.
        await _advance(game, 4);

        expect(_find<Enemy>(game), isEmpty);
        expect(game.state.kills.value, 1);
        expect(game.state.score.value, EnemyStats.grunt.score);
      },
    );

    testWithGame<
      FCLGame
    >('a bullet cannot skip over the smallest enemy', _newGame, (game) async {
      // Guards the maxDelta choice: at the longest allowed step, a bullet has to
      // land inside an enemy rather than jumping clean past it.
      await _stopSpawners(game);
      // Killing the player freezes the enemies and silences the auto fire, so the
      // only thing moving is the hand-placed bullet.
      game.player!.takeDamage(GameConfig.playerMaxHp);
      await _clearBullets(game);
      await game.world.addAll([
        Enemy(stats: EnemyStats.grunt, position: Vector2(600, 360)),
        Bullet(position: Vector2(300, 360), direction: Vector2(1, 0)),
      ]);
      await game.ready();

      for (var i = 0; i < 20; i++) {
        game.update(GameConfig.maxDelta);
      }
      await game.ready();

      expect(game.state.kills.value, 1);
      expect(_find<Enemy>(game).every((enemy) => !enemy.isAlive), isTrue);
    });
  });

  group('player damage', () {
    testWithGame<FCLGame>('touching an enemy costs health', _newGame, (
      game,
    ) async {
      game.player!.takeDamage(GameConfig.enemyContactDamage);
      expect(game.state.hp.value, GameConfig.playerMaxHp - 1);
    });

    testWithGame<FCLGame>(
      'an enemy on top of the player deals damage',
      _newGame,
      (game) async {
        final player = game.player!;
        await game.world.add(
          Enemy(stats: EnemyStats.grunt, position: player.position.clone()),
        );
        await game.ready();

        await _advance(game, 0.1);
        expect(game.state.hp.value, lessThan(GameConfig.playerMaxHp));
      },
    );

    testWithGame<FCLGame>('invulnerability blocks repeated damage', _newGame, (
      game,
    ) async {
      final player = game.player!;

      player.takeDamage(1);
      expect(player.isInvulnerable, isTrue);

      player.takeDamage(1);
      expect(game.state.hp.value, GameConfig.playerMaxHp - 1);

      await _advance(game, GameConfig.invulnerabilityDuration + 0.05);
      expect(player.isInvulnerable, isFalse);

      player.takeDamage(1);
      expect(game.state.hp.value, GameConfig.playerMaxHp - 2);
    });

    testWithGame<FCLGame>('running out of health ends the run', _newGame, (
      game,
    ) async {
      final player = game.player!;

      for (var i = 0; i < GameConfig.playerMaxHp; i++) {
        player.takeDamage(1);
        await _advance(game, GameConfig.invulnerabilityDuration + 0.05);
      }

      expect(game.state.hp.value, 0);
      expect(player.isAlive, isFalse);
      expect(game.state.status.value, GameStatus.gameOver);
      expect(game.paused, isTrue);
    });

    testWithGame<FCLGame>('health never goes below zero', _newGame, (
      game,
    ) async {
      game.state.hp.value = 1;
      game.player!.takeDamage(5);
      expect(game.state.hp.value, 0);
    });

    testWithGame<FCLGame>('a dead player stops shooting', _newGame, (
      game,
    ) async {
      game.player!.takeDamage(GameConfig.playerMaxHp);
      await _clearBullets(game);

      await _advance(game, 1);
      expect(_find<Bullet>(game), isEmpty);
    });
  });

  group('power-up', () {
    testWithGame<FCLGame>(
      'appears inside the arena after its delay',
      _newGame,
      (game) async {
        await _advance(game, GameConfig.firstPowerUpDelay + 0.1);

        final powerUp = _find<PowerUp>(game).single;
        expect(powerUp.position.x, greaterThan(0));
        expect(powerUp.position.x, lessThan(GameConfig.worldWidth));
        expect(powerUp.position.y, greaterThan(0));
        expect(powerUp.position.y, lessThan(GameConfig.worldHeight));
      },
    );

    testWithGame<FCLGame>('collecting it speeds up the weapon', _newGame, (
      game,
    ) async {
      final powerUp = PowerUp(position: Vector2(200, 200));
      await game.world.add(powerUp);
      await game.ready();

      game.onPowerUpCollected(powerUp);
      await game.ready();

      expect(powerUp.isRemoved, isTrue);
      expect(
        game.player!.weapon.fireInterval,
        closeTo(
          GameConfig.baseFireInterval / GameConfig.rapidFireMultiplier,
          1e-9,
        ),
      );
    });

    testWithGame<FCLGame>('walking into it collects it', _newGame, (
      game,
    ) async {
      final powerUp = PowerUp(position: game.player!.position.clone());
      await game.world.add(powerUp);
      await game.ready();

      await _advance(game, 0.1);

      expect(powerUp.isRemoved, isTrue);
      expect(game.state.rapidFireProgress.value, greaterThan(0));
    });

    testWithGame<FCLGame>(
      'expires on its own if nobody picks it up',
      _newGame,
      (game) async {
        final powerUp = PowerUp(position: Vector2(200, 200));
        await game.world.add(powerUp);
        await game.ready();

        await _advance(game, GameConfig.powerUpLifetime + 0.1);
        expect(powerUp.isRemoved, isTrue);
      },
    );

    testWithGame<FCLGame>('only one pickup exists at a time', _newGame, (
      game,
    ) async {
      await _advance(game, GameConfig.firstPowerUpDelay + 5);
      expect(_find<PowerUp>(game), hasLength(1));
    });
  });

  group('pause and restart', () {
    testWithGame<FCLGame>('pausing freezes the engine', _newGame, (game) async {
      game.togglePause();
      expect(game.state.status.value, GameStatus.paused);
      expect(game.paused, isTrue);

      game.togglePause();
      expect(game.state.status.value, GameStatus.playing);
      expect(game.paused, isFalse);
    });

    testWithGame<FCLGame>('pausing is ignored once the run is over', _newGame, (
      game,
    ) async {
      game.player!.takeDamage(GameConfig.playerMaxHp);
      await _advance(game, 0.05);

      game.togglePause();
      expect(game.state.status.value, GameStatus.gameOver);
    });

    testWithGame<FCLGame>(
      'restarting clears the world and the score',
      _newGame,
      (game) async {
        await _advance(game, GameConfig.firstEnemyDelay + 1);
        game.state.addKill(points: 100);

        game.restart();
        await game.ready();

        expect(game.state.score.value, 0);
        expect(game.state.kills.value, 0);
        expect(game.state.hp.value, GameConfig.playerMaxHp);
        expect(game.state.elapsed, 0);
        expect(game.state.status.value, GameStatus.playing);
        expect(game.paused, isFalse);
        expect(_find<Enemy>(game), isEmpty);
        expect(_find<Bullet>(game), isEmpty);
        expect(game.player!.isAlive, isTrue);
      },
    );

    testWithGame<FCLGame>(
      'a restarted run can be played and lost again',
      _newGame,
      (game) async {
        game.player!.takeDamage(GameConfig.playerMaxHp);
        await _advance(game, 0.05);
        expect(game.state.status.value, GameStatus.gameOver);

        game.restart();
        await game.ready();
        await _advance(game, 0.5);
        expect(_find<Bullet>(game), isNotEmpty);

        game.player!.takeDamage(GameConfig.playerMaxHp);
        await _advance(game, 0.05);
        expect(game.state.status.value, GameStatus.gameOver);
      },
    );
  });

  group('frame time safety', () {
    testWithGame<FCLGame>('a huge frame is clamped', _newGame, (game) async {
      game.player!.facing.setValues(1, 0);
      await _advance(game, 0.05);
      final bullet = _find<Bullet>(game).first;
      final before = bullet.position.x;

      // A two second stall must advance the world by one clamped step at most,
      // otherwise bullets would tunnel straight through enemies.
      game.update(2);

      expect(
        bullet.position.x - before,
        lessThanOrEqualTo(GameConfig.bulletSpeed * GameConfig.maxDelta + 0.001),
      );
    });
  });
}
