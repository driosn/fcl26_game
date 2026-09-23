import 'package:flutter/material.dart';

import '../../theme/game_palette.dart';

/// A horizontal bar with a bright leading edge, for timed buffs.
///
/// Hand painted rather than a [LinearProgressIndicator] so the cap can glow, and
/// so it keeps its shape at the small sizes the HUD uses.
class Meter extends StatelessWidget {
  const Meter({
    required this.value,
    required this.tint,
    this.width = 150,
    this.height = 8,
    super.key,
  });

  /// Fraction filled, clamped to `[0, 1]`.
  final double value;
  final Color tint;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _MeterPainter(value: value.clamp(0, 1), tint: tint),
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter({required this.value, required this.tint});

  final double value;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);

    canvas.drawRRect(track, Paint()..color = GamePalette.healthEmpty);

    if (value <= 0) {
      return;
    }

    final filledWidth = size.width * value;
    final filled = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, filledWidth, size.height),
      radius,
    );
    canvas.drawRRect(
      filled,
      Paint()
        ..shader = LinearGradient(
          colors: [tint.withValues(alpha: 0.65), tint],
        ).createShader(filled.outerRect),
    );

    // The cap is what makes a draining bar feel alive rather than just shorter.
    canvas.drawCircle(
      Offset(filledWidth - size.height / 2, size.height / 2),
      size.height * 0.75,
      Paint()..color = tint.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_MeterPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.tint != tint;
}
