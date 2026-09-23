import 'dart:io';
import 'dart:ui' as ui;

import 'package:fcl_26_game/src/game/brotato_game.dart';
import 'package:fcl_26_game/src/game/game_state.dart';
import 'package:fcl_26_game/src/render/shape_skin.dart';
import 'package:fcl_26_game/src/theme/game_palette.dart';
import 'package:fcl_26_game/src/theme/game_theme.dart';
import 'package:fcl_26_game/src/ui/game_over_overlay.dart';
import 'package:fcl_26_game/src/ui/hud_overlay.dart';
import 'package:fcl_26_game/src/ui/pause_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _boundary = GlobalKey();

class _ArenaBackdrop extends StatelessWidget {
  const _ArenaBackdrop();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ArenaPainter(), size: Size.infinite);
}

class _ArenaPainter extends CustomPainter {
  final skin = ShapeSkin();

  @override
  void paint(Canvas canvas, Size size) => skin.paintArena(canvas, size);

  @override
  bool shouldRepaint(_) => false;
}

Future<void> _shoot(WidgetTester tester, String name) async {
  final boundary =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<FCLGame> _pump(WidgetTester tester, Widget Function(FCLGame) ui,
    {GameStatus status = GameStatus.playing}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final game = FCLGame();
  addTearDown(game.state.dispose);
  game.state.score.value = 12480;
  game.state.kills.value = 137;
  game.state.survivedSeconds.value = 194;
  game.state.hp.value = 2;
  game.state.rapidFireProgress.value = 0.62;
  game.state.status.value = status;

  await tester.pumpWidget(
    MaterialApp(
      theme: GameTheme.build(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: GamePalette.letterbox,
        body: RepaintBoundary(
          key: _boundary,
          child: Stack(
            children: [const Positioned.fill(child: _ArenaBackdrop()), ui(game)],
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return game;
}

void main() {
  testWidgets('hud preview', (tester) async {
    await _pump(tester, (game) => HudOverlay(game: game));
    await _shoot(tester, 'preview_hud');
  });

  testWidgets('pause preview', (tester) async {
    await _pump(
      tester,
      (game) => Stack(
        children: [HudOverlay(game: game), PauseOverlay(game: game)],
      ),
      status: GameStatus.paused,
    );
    await _shoot(tester, 'preview_pause');
  });

  testWidgets('game over preview', (tester) async {
    await _pump(
      tester,
      (game) => Stack(
        children: [HudOverlay(game: game), GameOverOverlay(game: game)],
      ),
      status: GameStatus.gameOver,
    );
    await _shoot(tester, 'preview_gameover');
  });
}
