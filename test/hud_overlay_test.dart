import 'package:fcl_26_game/src/game/brotato_game.dart';
import 'package:fcl_26_game/src/game/game_config.dart';
import 'package:fcl_26_game/src/input/input_device.dart';
import 'package:fcl_26_game/src/theme/game_theme.dart';
import 'package:fcl_26_game/src/ui/hud_overlay.dart';
import 'package:fcl_26_game/src/ui/run_stats.dart';
import 'package:fcl_26_game/src/ui/widgets/dash_portrait.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders just the HUD, with no Flame canvas under it, at a given window size.
Future<FCLGame> _pumpHud(
  WidgetTester tester, {
  Size size = const Size(1280, 720),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final game = FCLGame(listenToGamepadHardware: false);
  addTearDown(game.state.dispose);
  addTearDown(game.inputState.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: GameTheme.build(),
      home: Scaffold(body: HudOverlay(game: game)),
    ),
  );
  return game;
}

void main() {
  group('formatClock', () {
    test('counts up in minutes and seconds', () {
      expect(formatClock(0), '0:00');
      expect(formatClock(9), '0:09');
      expect(formatClock(59), '0:59');
      expect(formatClock(60), '1:00');
      expect(formatClock(605), '10:05');
    });
  });

  group('HudOverlay', () {
    testWidgets('shows the live score, kills and clock', (tester) async {
      final game = await _pumpHud(tester);

      game.state.score.value = 1234;
      game.state.kills.value = 42;
      game.state.survivedSeconds.value = 95;
      await tester.pump();

      expect(find.text('1234'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('1:35'), findsOneWidget);
      expect(find.text('PUNTOS'), findsOneWidget);
      expect(find.text('TIEMPO'), findsOneWidget);
      expect(find.text('VIDA'), findsOneWidget);
      expect(find.text('ELIMINACIONES'), findsOneWidget);
    });

    testWidgets('shows keyboard tutorial caps by default', (tester) async {
      await _pumpHud(tester);
      expect(find.text('WASD'), findsOneWidget);
      expect(find.text('SHIFT'), findsOneWidget);
      expect(find.text('ESC'), findsOneWidget);
      expect(find.text('Mover'), findsOneWidget);
    });

    testWidgets('swaps tutorial glyphs when the pad speaks', (tester) async {
      final game = await _pumpHud(tester);
      game.inputState.noteDevice(InputDeviceKind.gamepad);
      await tester.pump();
      expect(find.text('WASD'), findsNothing);
      expect(find.text('Apuntar'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('R2'), findsOneWidget);
    });

    testWidgets('draws the Dash portrait as the health tank', (tester) async {
      await _pumpHud(tester);
      expect(find.byType(DashPortrait), findsOneWidget);
    });

    testWidgets('drains the Dash portrait as health drops', (tester) async {
      final game = await _pumpHud(tester);

      game.state.hp.value = 2;
      await tester.pump();

      final portrait = tester.widget<DashPortrait>(find.byType(DashPortrait));
      expect(portrait.health, 2 / GameConfig.playerMaxHp);
      expect(portrait.warning, isTrue);
    });

    testWidgets('hides the rapid fire badge until the buff is up', (
      tester,
    ) async {
      final game = await _pumpHud(tester);
      expect(
        find.text('RÁFAGA x5'),
        findsOneWidget,
        reason: 'built but transparent',
      );

      final hidden = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('RÁFAGA x5'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(hidden.opacity, 0);

      game.state.rapidFireProgress.value = 0.5;
      await tester.pump();

      final shown = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('RÁFAGA x5'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(shown.opacity, 1);
      expect(find.text('8 s'), findsOneWidget);
    });

    // The HUD sits over a fixed 1280x720 world, but the window it is drawn in can
    // be any size, including smaller than the readouts it holds.
    for (final size in const [
      Size(1280, 720),
      Size(1920, 1080),
      Size(800, 600),
      Size(640, 480),
    ]) {
      testWidgets('lays out without overflowing at ${size.width.toInt()}px', (
        tester,
      ) async {
        final game = await _pumpHud(tester, size: size);

        // With every readout showing at once, which is the widest the HUD gets.
        game.state.score.value = 999999;
        game.state.kills.value = 9999;
        game.state.survivedSeconds.value = 3599;
        game.state.hp.value = 1;
        game.state.rapidFireProgress.value = 1;
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
