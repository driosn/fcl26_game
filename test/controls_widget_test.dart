import 'package:fcl_26_game/main.dart';
import 'package:fcl_26_game/src/game/brotato_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _gameFinder = find.byType(GameWidget<FCLGame>);

GameWidget<FCLGame> _gameWidget(WidgetTester tester) =>
    tester.widget<GameWidget<FCLGame>>(_gameFinder);

/// Holds the right arrow down for [frames] rendered frames.
Future<void> _holdRightArrow(WidgetTester tester, {int frames = 10}) async {
  await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight);
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight);
}

Future<FCLGame> _bootApp(WidgetTester tester) async {
  await tester.pumpWidget(const FclGameApp(enableRive: false));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  return _gameWidget(tester).game!;
}

void main() {
  testWidgets('arrow keys move the player through the real widget tree', (
    tester,
  ) async {
    final game = await _bootApp(tester);
    final startX = game.player!.position.x;

    await _holdRightArrow(tester);

    expect(
      game.player!.position.x,
      greaterThan(startX),
      reason: 'the player did not react to the right arrow key',
    );
  });

  testWidgets('the game holds primary focus from the first frame', (
    tester,
  ) async {
    await _bootApp(tester);
    expect(_gameWidget(tester).focusNode!.hasPrimaryFocus, isTrue);
  });

  testWidgets('movement still works after GameWidget loses focus', (
    tester,
  ) async {
    final game = await _bootApp(tester);
    final focusNode = _gameWidget(tester).focusNode!;

    focusNode.unfocus();
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);

    // Movement reads HardwareKeyboard, not Flame's focused onKeyEvent.
    final startX = game.player!.position.x;
    await _holdRightArrow(tester);
    expect(game.player!.position.x, greaterThan(startX));
  });

  testWidgets('the pause panel buttons do not steal keyboard focus', (
    tester,
  ) async {
    final game = await _bootApp(tester);
    final focusNode = _gameWidget(tester).focusNode!;

    game.togglePause();
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Continuar'));
    await tester.pump();

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(game.paused, isFalse);
  });

  testWidgets('Salir on pause calls onQuit and does not kill the test', (
    tester,
  ) async {
    var quit = 0;
    await tester.pumpWidget(
      FclGameApp(enableRive: false, onQuit: () => quit++),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final game = _gameWidget(tester).game!;

    game.togglePause();
    await tester.pump();

    expect(find.text('Salir'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Salir'));
    await tester.pump();
    expect(quit, 1);
  });

  testWidgets('game over offers Reintentar and Salir', (tester) async {
    var quit = 0;
    await tester.pumpWidget(
      FclGameApp(enableRive: false, onQuit: () => quit++),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final game = _gameWidget(tester).game!;

    game.onPlayerDied();
    await tester.pump();

    expect(find.widgetWithText(TextButton, 'Reintentar'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Salir'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Salir'));
    await tester.pump();
    expect(quit, 1);
  });

  testWidgets('D-pad moves the pause highlight and A activates it', (
    tester,
  ) async {
    var quit = 0;
    await tester.pumpWidget(
      FclGameApp(enableRive: false, onQuit: () => quit++),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final game = _gameWidget(tester).game!;

    game.togglePause();
    await tester.pump();
    expect(game.menuNav.index.value, 0);

    game.menuNav.next();
    game.menuNav.next();
    await tester.pump();
    expect(game.menuNav.index.value, 2);

    game.menuNav.activate();
    await tester.pump();
    expect(quit, 1);
  });
}
