import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/game_palette.dart';

/// Dash's face as a profile. Health is the ring around him, so the bird
/// never gets clipped away.
class DashPortrait extends StatelessWidget {
  const DashPortrait({
    required this.health,
    this.size = 80,
    this.warning = false,
    super.key,
  });

  /// Remaining health as a 0–1 fraction.
  final double health;
  final double size;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DashPortraitPainter(
        health: health.clamp(0, 1),
        warning: warning,
      ),
    );
  }
}

class _DashPortraitPainter extends CustomPainter {
  const _DashPortraitPainter({required this.health, required this.warning});

  final double health;
  final bool warning;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ring = radius - 4;

    canvas.drawCircle(
      center,
      radius - 2,
      Paint()..color = GamePalette.letterbox.withValues(alpha: 0.94),
    );

    canvas.drawCircle(
      center,
      ring,
      Paint()
        ..color = GamePalette.healthEmpty
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    if (health > 0) {
      final rect = Rect.fromCircle(center: center, radius: ring);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * health,
        false,
        Paint()
          ..color = warning ? GamePalette.danger : GamePalette.player
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(size.width / 88);
    _paintDash(canvas, GamePalette.player);
    canvas.restore();
  }

  void _paintDash(Canvas canvas, Color body) {
    final fill = Paint()..color = body;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 44, height: 48),
      fill,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -16), width: 48, height: 10),
        const Radius.circular(5),
      ),
      Paint()..color = GamePalette.powerUp,
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -28), width: 11, height: 16),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-9, -24), width: 9, height: 13),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(9, -24), width: 9, height: 13),
      fill,
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 9), width: 14, height: 10),
      Paint()..color = GamePalette.beak,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-7, -4), width: 9, height: 10),
      Paint()..color = GamePalette.entityOutline,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(7, -4), width: 9, height: 10),
      Paint()..color = GamePalette.entityOutline,
    );
  }

  @override
  bool shouldRepaint(_DashPortraitPainter oldDelegate) =>
      oldDelegate.health != health || oldDelegate.warning != warning;
}
