import 'package:fcl_26_game/src/components/enemy_type.dart';
import 'package:fcl_26_game/src/game/game_config.dart';
import 'package:fcl_26_game/src/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    test('starts a run at zero score with full health', () {
      final state = GameState();
      addTearDown(state.dispose);

      expect(state.score.value, 0);
      expect(state.kills.value, 0);
      expect(state.hp.value, GameConfig.playerMaxHp);
      expect(state.status.value, GameStatus.playing);
      expect(state.isPlaying, isTrue);
    });

    test('awards each enemy type its own score', () {
      final state = GameState();
      addTearDown(state.dispose);

      state.addKill(points: EnemyStats.grunt.score);
      expect(state.score.value, 10);
      state.addKill(points: EnemyStats.runner.score);
      expect(state.score.value, 35);
      state.addKill(points: EnemyStats.tank.score);
      expect(state.score.value, 85);
      expect(state.kills.value, 3);
    });

    test('exposes whole survived seconds without notifying every frame', () {
      final state = GameState();
      addTearDown(state.dispose);

      var notifications = 0;
      state.survivedSeconds.addListener(() => notifications++);

      // Sixty frames at 1/60s is exactly one second of play.
      for (var i = 0; i < 60; i++) {
        state.tick(1 / 60);
      }
      expect(state.survivedSeconds.value, 1);
      expect(notifications, 1);
      expect(state.elapsed, closeTo(1, 1e-6));
    });

    test('reset clears everything for the next run', () {
      final state = GameState();
      addTearDown(state.dispose);

      state.addKill(points: 50);
      state.hp.value = 1;
      state.tick(30);
      state.status.value = GameStatus.gameOver;
      state.rapidFireProgress.value = 0.5;

      state.reset();

      expect(state.score.value, 0);
      expect(state.kills.value, 0);
      expect(state.hp.value, GameConfig.playerMaxHp);
      expect(state.elapsed, 0);
      expect(state.survivedSeconds.value, 0);
      expect(state.rapidFireProgress.value, 0);
      expect(state.status.value, GameStatus.playing);
    });
  });

  group('EnemyStats', () {
    test('tougher enemies are worth more points', () {
      expect(EnemyStats.grunt.score, lessThan(EnemyStats.runner.score));
      expect(EnemyStats.runner.score, lessThan(EnemyStats.tank.score));
    });

    test('every type has stats registered', () {
      for (final type in EnemyType.values) {
        final stats = EnemyStats.of(type);
        expect(stats.type, type);
        expect(stats.hitsToKill, greaterThan(0));
        expect(stats.speed, greaterThan(0));
        expect(stats.radius, greaterThan(0));
      }
    });

    test('the three types differ in speed and in bullets needed', () {
      expect(EnemyStats.runner.speed, greaterThan(EnemyStats.grunt.speed));
      expect(EnemyStats.tank.speed, lessThan(EnemyStats.grunt.speed));
      expect(
        EnemyStats.tank.hitsToKill,
        greaterThan(EnemyStats.runner.hitsToKill),
      );
    });
  });
}
