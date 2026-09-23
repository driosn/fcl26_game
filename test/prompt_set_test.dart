import 'package:fcl_26_game/src/ui/prompt_set.dart';
import 'package:fcl_26_game/src/ui/widgets/chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keyboard prompts use key caps, not Deck faces', () {
    final glyphs = PromptSet.keyboard.glyphs(PromptId.move);
    expect(glyphs, hasLength(1));
    expect(glyphs.first.kind, PromptGlyphKind.keyCap);
    expect(glyphs.first.label, 'WASD');
  });

  test('Steam Deck prompts use the left stick for move and A+R2 for dash', () {
    final move = PromptSet.steamDeck.glyphs(PromptId.move);
    expect(move.single.kind, PromptGlyphKind.stick);
    expect(move.single.label, 'L');

    final dash = PromptSet.steamDeck.glyphs(PromptId.dash);
    expect(dash.map((g) => g.label), ['A', 'R2']);
  });

  testWidgets('PromptLine draws Deck glyphs for a gamepad device', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PromptLine(
            glyphs: [
              PromptSpec(kind: PromptGlyphKind.faceButton, label: 'A'),
              PromptSpec(kind: PromptGlyphKind.trigger, label: 'R2'),
            ],
            label: 'Dash',
          ),
        ),
      ),
    );
    expect(find.text('Dash'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('R2'), findsOneWidget);
    expect(find.byType(PromptGlyph), findsNWidgets(2));
  });

  testWidgets('PromptLine draws WASD for a keyboard device', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PromptLine(
            glyphs: [PromptSpec(kind: PromptGlyphKind.keyCap, label: 'WASD')],
            label: 'Mover',
          ),
        ),
      ),
    );
    expect(find.text('WASD'), findsOneWidget);
    expect(find.text('Mover'), findsOneWidget);
  });
}
