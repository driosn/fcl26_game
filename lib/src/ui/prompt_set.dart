import 'package:flutter/material.dart';

import '../input/input_device.dart';
import '../theme/game_palette.dart';

/// What the player is being taught in a hint line.
enum PromptId { move, aim, dash, pause, confirm }

enum PromptGlyphKind { keyCap, stick, faceButton, trigger, menu }

/// One drawn control: a keyboard cap or a Deck-style glyph.
@immutable
class PromptSpec {
  const PromptSpec({required this.kind, required this.label, this.color});

  final PromptGlyphKind kind;
  final String label;
  final Color? color;
}

/// Keyboard caps vs Steam Deck buttons. Gameplay never reads this; the HUD does.
@immutable
class PromptSet {
  const PromptSet(this._glyphs);

  final Map<PromptId, List<PromptSpec>> _glyphs;

  List<PromptSpec> glyphs(PromptId id) => _glyphs[id] ?? const [];

  static PromptSet forDevice(InputDeviceKind kind) {
    return kind == InputDeviceKind.gamepad ? steamDeck : keyboard;
  }

  static const PromptSet keyboard = PromptSet({
    PromptId.move: [PromptSpec(kind: PromptGlyphKind.keyCap, label: 'WASD')],
    PromptId.aim: [],
    PromptId.dash: [PromptSpec(kind: PromptGlyphKind.keyCap, label: 'SHIFT')],
    PromptId.pause: [PromptSpec(kind: PromptGlyphKind.keyCap, label: 'ESC')],
    PromptId.confirm: [
      PromptSpec(kind: PromptGlyphKind.keyCap, label: 'ENTER'),
    ],
  });

  static const PromptSet steamDeck = PromptSet({
    PromptId.move: [PromptSpec(kind: PromptGlyphKind.stick, label: 'L')],
    PromptId.aim: [PromptSpec(kind: PromptGlyphKind.stick, label: 'R')],
    PromptId.dash: [
      PromptSpec(
        kind: PromptGlyphKind.faceButton,
        label: 'A',
        color: GamePalette.deckA,
      ),
      PromptSpec(kind: PromptGlyphKind.trigger, label: 'R2'),
    ],
    PromptId.pause: [PromptSpec(kind: PromptGlyphKind.menu, label: '☰')],
    PromptId.confirm: [
      PromptSpec(
        kind: PromptGlyphKind.faceButton,
        label: 'A',
        color: GamePalette.deckA,
      ),
    ],
  });
}
