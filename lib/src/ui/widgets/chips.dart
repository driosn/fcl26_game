import 'package:flutter/material.dart';

import '../../input/input_device.dart';
import '../../theme/game_palette.dart';
import '../../theme/game_typography.dart';
import '../prompt_set.dart';

/// Small pill pairing a glyph with a value, for the secondary HUD readouts.
class StatChip extends StatelessWidget {
  const StatChip({
    required this.icon,
    required this.label,
    this.tint,
    super.key,
  });

  final IconData icon;
  final String label;

  /// Defaults to the muted UI text colour.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? GamePalette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GamePalette.panelHighlight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GamePalette.panelBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GameTypography.chip.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// A keyboard key drawn as a physical cap, so control hints read as controls
/// rather than as prose.
class KeyCap extends StatelessWidget {
  const KeyCap(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      constraints: const BoxConstraints(minWidth: 24),
      decoration: BoxDecoration(
        color: GamePalette.panelHighlight,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: GamePalette.panelBorder),
        // A brighter bottom edge gives the cap its depth.
        boxShadow: const [
          BoxShadow(color: Color(0x33FFFFFF), offset: Offset(0, -1)),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GameTypography.keyCap,
      ),
    );
  }
}

/// A line of control guidance: glyphs, then what they do.
class PromptLine extends StatelessWidget {
  const PromptLine({required this.glyphs, required this.label, super.key});

  factory PromptLine.forId({
    required InputDeviceKind device,
    required PromptId id,
    required String label,
    Key? key,
  }) {
    return PromptLine(
      glyphs: PromptSet.forDevice(device).glyphs(id),
      label: label,
      key: key,
    );
  }

  final List<PromptSpec> glyphs;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (glyphs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final glyph in glyphs) PromptGlyph(glyph),
        const SizedBox(width: 6),
        Text(label, style: GameTypography.hint),
      ],
    );
  }
}

/// Keyboard cap, Deck face button, stick, trigger, or menu glyph.
class PromptGlyph extends StatelessWidget {
  const PromptGlyph(this.spec, {super.key});

  final PromptSpec spec;

  @override
  Widget build(BuildContext context) {
    return switch (spec.kind) {
      PromptGlyphKind.keyCap => KeyCap(spec.label),
      PromptGlyphKind.faceButton => _FaceButton(spec.label, spec.color),
      PromptGlyphKind.stick => _StickGlyph(spec.label),
      PromptGlyphKind.trigger => _TriggerGlyph(spec.label),
      PromptGlyphKind.menu => const _MenuGlyph(),
    };
  }
}

class _FaceButton extends StatelessWidget {
  const _FaceButton(this.label, this.color);

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? GamePalette.deckA;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x66000000)),
      ),
      child: Text(
        label,
        style: GameTypography.keyCap.copyWith(
          color: GamePalette.textPrimary,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StickGlyph extends StatelessWidget {
  const _StickGlyph(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 28,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GamePalette.panelHighlight,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: GamePalette.panelBorder),
      ),
      child: Text('$label●', style: GameTypography.keyCap),
    );
  }
}

class _TriggerGlyph extends StatelessWidget {
  const _TriggerGlyph(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: GamePalette.panelHighlight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
          bottom: Radius.circular(3),
        ),
        border: Border.all(color: GamePalette.panelBorder),
      ),
      child: Text(label, style: GameTypography.keyCap),
    );
  }
}

class _MenuGlyph extends StatelessWidget {
  const _MenuGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GamePalette.panelHighlight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GamePalette.panelBorder),
      ),
      child: const Icon(Icons.menu, size: 14, color: GamePalette.textPrimary),
    );
  }
}
