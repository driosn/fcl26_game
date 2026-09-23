import 'package:flutter/material.dart';

import '../../theme/game_palette.dart';

/// Every glyph the UI uses.
///
/// The swap to bundled art starts here: these names stay, their bodies become
/// `Image.asset`, and no HUD or menu code has to change.
abstract final class GameIcons {
  static const IconData kills = Icons.gps_fixed_rounded;
  static const IconData clock = Icons.timer_outlined;
  static const IconData rapidFire = Icons.bolt_rounded;
}

/// One unit of the player's health.
///
/// Hand drawn rather than a Material heart so the most prominent HUD element
/// carries the game's own look, and so it can grow a pulse without a font swap.
class HeartPip extends StatelessWidget {
  const HeartPip({required this.filled, this.size = 22, super.key});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.9),
      painter: _HeartPainter(filled: filled),
    );
  }
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _heartPath(size);

    if (!filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = GamePalette.healthEmpty
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      return;
    }

    // A wider, faint copy of the same shape reads as a glow without a blur pass.
    canvas.drawPath(
      path,
      Paint()
        ..color = GamePalette.health.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(GamePalette.health, Colors.white, 0.35)!,
            GamePalette.health,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  /// Two mirrored cubics: the lobes at the top, meeting at the point below.
  Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.95)
      ..cubicTo(w * -0.08, h * 0.6, w * 0.08, h * 0.0, w * 0.5, h * 0.3)
      ..cubicTo(w * 0.92, h * 0.0, w * 1.08, h * 0.6, w * 0.5, h * 0.95)
      ..close();
  }

  @override
  bool shouldRepaint(_HeartPainter oldDelegate) => oldDelegate.filled != filled;
}
