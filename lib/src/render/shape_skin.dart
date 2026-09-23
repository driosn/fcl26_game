import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, LinearGradient, RadialGradient;

import '../components/enemy_type.dart';
import '../game/game_config.dart';
import '../theme/game_palette.dart';
import 'game_skin.dart';

/// The asset-free look: every entity is built from primitives.
///
/// Each method draws around the origin of a canvas it translates itself, so the
/// cached gradient shaders below stay valid no matter where an entity moves to.
class ShapeSkin extends GameSkin {
  ShapeSkin();

  // Shaders have to be built against a rect, which makes them the one thing here
  // that cannot be a plain const paint. Radii are fixed per entity kind, so one
  // shader per kind is built on first use and then reused forever.
  final Map<Object, Paint> _orbFills = {};

  Size? _arenaSize;
  Picture? _arenaPicture;

  final Paint _shadow = Paint()..color = GamePalette.entityShadow;
  final Paint _glow = Paint();
  final Paint _flatFill = Paint();
  final Paint _outline = Paint()
    ..color = GamePalette.entityOutline
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Path _scratchPath = Path();

  // --- Arena -----------------------------------------------------------------

  @override
  void paintArena(Canvas canvas, Size size) {
    _prepareArena(size);
    canvas.drawPicture(_arenaPicture!);
  }

  void _prepareArena(Size size) {
    if (_arenaSize == size && _arenaPicture != null) {
      return;
    }
    _arenaPicture?.dispose();
    _arenaSize = size;

    final bounds = Offset.zero & size;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    _paintArenaLayers(canvas, size, bounds);
    _arenaPicture = recorder.endRecording();
  }

  /// Lead hangar floor: worn concrete, not a graph-paper grid.
  /// Everything here is static, so it is recorded once and replayed.
  void _paintArenaLayers(Canvas canvas, Size size, Rect bounds) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GamePalette.arenaTop, GamePalette.arenaBottom],
        ).createShader(bounds),
    );

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.28, -0.42),
          radius: 0.85,
          colors: [GamePalette.arenaMoon, GamePalette.arenaVignetteInner],
        ).createShader(bounds),
    );

    _paintDirt(canvas, size);
    _paintSlabs(canvas, size);
    _paintPaths(canvas, size);
    _paintPad(canvas, size);
    _paintTraces(canvas, size);
    _paintWalls(canvas, bounds);
    _paintFoliage(canvas, size);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.92,
          colors: [GamePalette.arenaVignetteInner, GamePalette.arenaVignetteOuter],
          stops: [0.48, 1],
        ).createShader(bounds),
    );
    _paintFrame(canvas, bounds);
  }

  void _paintDirt(Canvas canvas, Size size) {
    _flatFill.color = GamePalette.arenaDirt;
    for (final patch in const [
      (120.0, 90.0, 220.0, 110.0),
      (980.0, 80.0, 240.0, 100.0),
      (80.0, 520.0, 200.0, 130.0),
      (1060.0, 540.0, 210.0, 120.0),
      (540.0, 40.0, 180.0, 70.0),
      (700.0, 640.0, 220.0, 80.0),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(patch.$1, patch.$2),
          width: patch.$3,
          height: patch.$4,
        ),
        _flatFill,
      );
    }
  }

  void _paintSlabs(Canvas canvas, Size size) {
    const inset = 56.0;
    const cols = 4;
    const rows = 3;
    const gutter = 12.0;
    final slabW = (size.width - inset * 2 - gutter * (cols - 1)) / cols;
    final slabH = (size.height - inset * 2 - gutter * (rows - 1)) / rows;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final rect = Rect.fromLTWH(
          inset + col * (slabW + gutter),
          inset + row * (slabH + gutter),
          slabW,
          slabH,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
        _flatFill.color = GamePalette.arenaSlab;
        canvas.drawRRect(rrect, _flatFill);
        _stroke
          ..color = GamePalette.arenaSlabEdge
          ..strokeWidth = 1.8;
        canvas.drawRRect(rrect, _stroke);

        _stroke
          ..color = GamePalette.gridMinor
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(rect.center.dx, rect.top + 10),
          Offset(rect.center.dx, rect.bottom - 10),
          _stroke,
        );
        canvas.drawLine(
          Offset(rect.left + 12, rect.center.dy),
          Offset(rect.right - 12, rect.center.dy),
          _stroke,
        );

        if ((row + col).isOdd) {
          final hatch = Rect.fromCenter(
            center: rect.center.translate(col.isEven ? -36 : 36, row.isEven ? -22 : 22),
            width: 54,
            height: 28,
          );
          _flatFill.color = GamePalette.arenaHatch;
          canvas.drawRRect(
            RRect.fromRectAndRadius(hatch, const Radius.circular(4)),
            _flatFill,
          );
          _stroke
            ..color = GamePalette.arenaSlabEdge.withValues(alpha: 0.55)
            ..strokeWidth = 1;
          canvas.drawRRect(
            RRect.fromRectAndRadius(hatch, const Radius.circular(4)),
            _stroke,
          );
        }
      }
    }
  }

  void _paintPaths(Canvas canvas, Size size) {
    _flatFill.color = GamePalette.arenaPath;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width - 200,
          height: 58,
        ),
        const Radius.circular(18),
      ),
      _flatFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 58,
          height: size.height - 160,
        ),
        const Radius.circular(18),
      ),
      _flatFill,
    );
  }

  void _paintPad(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      148,
      Paint()
        ..shader = RadialGradient(
          colors: [
            GamePalette.arenaMoon.withValues(alpha: 0.28),
            GamePalette.arenaVignetteInner,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 148)),
    );

    _hexPath(center, 118);
    _flatFill.color = GamePalette.arenaPad;
    canvas.drawPath(_scratchPath, _flatFill);
    _stroke
      ..color = GamePalette.arenaPadRing
      ..strokeWidth = 3;
    canvas.drawPath(_scratchPath, _stroke);

    _hexPath(center, 78);
    _stroke
      ..color = GamePalette.accent.withValues(alpha: 0.45)
      ..strokeWidth = 1.6;
    canvas.drawPath(_scratchPath, _stroke);

    canvas.drawCircle(center, 12, Paint()..color = GamePalette.arenaPadRing);
    canvas.drawCircle(
      center,
      5,
      Paint()..color = GamePalette.accent.withValues(alpha: 0.85),
    );

    _stroke
      ..color = GamePalette.accent.withValues(alpha: 0.5)
      ..strokeWidth = 2.2;
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final inner = Offset(
        center.dx + math.cos(a) * 22,
        center.dy + math.sin(a) * 22,
      );
      final outer = Offset(
        center.dx + math.cos(a) * 42,
        center.dy + math.sin(a) * 42,
      );
      canvas.drawLine(inner, outer, _stroke);
    }
  }

  void _hexPath(Offset center, double radius) {
    _scratchPath.reset();
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final p = Offset(
        center.dx + math.cos(a) * radius,
        center.dy + math.sin(a) * radius,
      );
      if (i == 0) {
        _scratchPath.moveTo(p.dx, p.dy);
      } else {
        _scratchPath.lineTo(p.dx, p.dy);
      }
    }
    _scratchPath.close();
  }

  void _paintTraces(Canvas canvas, Size size) {
    _stroke
      ..color = GamePalette.arenaTrace
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final traces = <List<Offset>>[
      [const Offset(70, 160), const Offset(160, 160), const Offset(160, 250)],
      [const Offset(70, 200), const Offset(120, 200), const Offset(120, 300)],
      [const Offset(1210, 150), const Offset(1120, 150), const Offset(1120, 240)],
      [const Offset(1210, 560), const Offset(1110, 560), const Offset(1110, 470)],
      [const Offset(70, 560), const Offset(170, 560), const Offset(170, 470)],
      [const Offset(240, 50), const Offset(240, 110), const Offset(340, 110)],
      [const Offset(1040, 50), const Offset(1040, 110), const Offset(940, 110)],
      [const Offset(240, 670), const Offset(240, 620), const Offset(360, 620)],
      [const Offset(1040, 670), const Offset(1040, 620), const Offset(920, 620)],
    ];
    for (final points in traces) {
      _scratchPath
        ..reset()
        ..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        _scratchPath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(_scratchPath, _stroke);
    }

    _flatFill.color = GamePalette.arenaNode;
    for (final node in const [
      Offset(160, 160),
      Offset(160, 250),
      Offset(120, 300),
      Offset(1120, 150),
      Offset(1120, 240),
      Offset(1110, 560),
      Offset(170, 560),
      Offset(240, 110),
      Offset(1040, 110),
      Offset(240, 620),
      Offset(1040, 620),
    ]) {
      canvas.drawCircle(node, 3.8, _flatFill);
    }
  }

  void _paintFoliage(Canvas canvas, Size size) {
    _paintCornerBush(canvas, const Offset(18, 16), 1, 1);
    _paintCornerBush(canvas, Offset(size.width - 18, 16), -1, 1);
    _paintCornerBush(canvas, Offset(18, size.height - 16), 1, -1);
    _paintCornerBush(canvas, Offset(size.width - 18, size.height - 16), -1, -1);

    // Mid-edge rubble so the walls feel wrecked, not just the corners.
    _paintFern(
      canvas,
      Offset(size.width * 0.28, 8),
      Offset(size.width * 0.28 + 18, 70),
    );
    _paintFern(
      canvas,
      Offset(size.width * 0.72, 10),
      Offset(size.width * 0.72 - 14, 66),
    );
    _paintFern(
      canvas,
      Offset(size.width * 0.32, size.height - 8),
      Offset(size.width * 0.32 + 10, size.height - 68),
    );
    _paintFern(
      canvas,
      Offset(size.width * 0.68, size.height - 10),
      Offset(size.width * 0.68 - 16, size.height - 64),
    );
  }

  void _paintCornerBush(Canvas canvas, Offset origin, double sx, double sy) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(sx, sy);
    _flatFill.color = GamePalette.arenaRubble;
    canvas.drawOval(
      const Rect.fromLTWH(-16, -16, 190, 124),
      _flatFill,
    );
    _flatFill.color = GamePalette.arenaRubbleMid;
    canvas.drawOval(
      const Rect.fromLTWH(8, 4, 128, 78),
      _flatFill,
    );
    _flatFill.color = GamePalette.arenaScrap.withValues(alpha: 0.55);
    canvas.drawOval(
      const Rect.fromLTWH(28, 18, 72, 46),
      _flatFill,
    );
    _paintFern(canvas, const Offset(24, 10), const Offset(92, 104));
    _paintFern(canvas, const Offset(56, 4), const Offset(142, 88));
    _paintFern(canvas, const Offset(8, 32), const Offset(78, 118));
    canvas.restore();
  }

  void _paintFern(Canvas canvas, Offset base, Offset tip) {
    _scratchPath
      ..reset()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        (base.dx + tip.dx) / 2 + (tip.dy - base.dy) * 0.12,
        (base.dy + tip.dy) / 2 - (tip.dx - base.dx) * 0.12,
        tip.dx,
        tip.dy,
      );
    _stroke
      ..color = GamePalette.arenaScrap
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_scratchPath, _stroke);

    final along = tip - base;
    for (var i = 1; i <= 4; i++) {
      final t = i / 5;
      final stem = Offset(base.dx + along.dx * t, base.dy + along.dy * t);
      final side = Offset(-along.dy, along.dx);
      final length = 10.0 + i * 2.5;
      final leaf = Offset(
        stem.dx + side.dx / along.distance * length * (i.isOdd ? 1 : -1),
        stem.dy + side.dy / along.distance * length * (i.isOdd ? 1 : -1),
      );
      canvas.drawLine(stem, leaf, _stroke..strokeWidth = 2);
    }
  }

  void _paintWalls(Canvas canvas, Rect bounds) {
    _flatFill.color = GamePalette.arenaWall;
    const depth = 22.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, bounds.width, depth), _flatFill);
    canvas.drawRect(
      Rect.fromLTWH(0, bounds.height - depth, bounds.width, depth),
      _flatFill,
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, depth, bounds.height), _flatFill);
    canvas.drawRect(
      Rect.fromLTWH(bounds.width - depth, 0, depth, bounds.height),
      _flatFill,
    );
  }

  void _paintFrame(Canvas canvas, Rect bounds) {
    _stroke
      ..color = GamePalette.arenaBorder
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;
    canvas.drawRect(bounds.deflate(2), _stroke);

    _stroke
      ..color = GamePalette.arenaBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    canvas.drawRect(bounds.deflate(11), _stroke);

    const plate = 38.0;
    _flatFill.color = GamePalette.arenaDirt;
    for (final corner in [
      bounds.topLeft,
      Offset(bounds.right - plate, bounds.top),
      Offset(bounds.left, bounds.bottom - plate),
      Offset(bounds.right - plate, bounds.bottom - plate),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(corner.dx, corner.dy, plate, plate),
          const Radius.circular(4),
        ),
        _flatFill,
      );
    }

    const arm = 42.0;
    final inner = bounds.deflate(8);
    _stroke
      ..color = GamePalette.accent.withValues(alpha: 0.62)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.square;
    for (final (corner, towardsX, towardsY) in [
      (inner.topLeft, 1.0, 1.0),
      (inner.topRight, -1.0, 1.0),
      (inner.bottomLeft, 1.0, -1.0),
      (inner.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner.translate(arm * towardsX, 0), _stroke);
      canvas.drawLine(corner, corner.translate(0, arm * towardsY), _stroke);
    }

    _stroke
      ..color = GamePalette.accent.withValues(alpha: 0.28)
      ..strokeWidth = 1.4;
    const tick = 8.0;
    const step = GameConfig.gridCell;
    for (var x = step; x < bounds.width - step; x += step) {
      canvas.drawLine(Offset(x, 6), Offset(x, 6 + tick), _stroke);
      canvas.drawLine(
        Offset(x, bounds.height - 6),
        Offset(x, bounds.height - 6 - tick),
        _stroke,
      );
    }
    for (var y = step; y < bounds.height - step; y += step) {
      canvas.drawLine(Offset(6, y), Offset(6 + tick, y), _stroke);
      canvas.drawLine(
        Offset(bounds.width - 6, y),
        Offset(bounds.width - 6 - tick, y),
        _stroke,
      );
    }
  }

  // --- Player ----------------------------------------------------------------

  @override
  void paintPlayer(
    Canvas canvas,
    Offset center, {
    required double radius,
    required bool hurt,
  }) {
    final tint = hurt ? GamePalette.playerHurt : GamePalette.player;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    _paintShadow(canvas, radius);
    _paintHalo(canvas, radius, tint);

    // 3/4 Dash: one sphere, face toward the camera. Same masses as the Rive
    // rig so a missing .riv still reads as the bird, not a person.
    final body = _orbFill(hurt ? 'player-hurt' : 'player', radius, tint);
    canvas.drawCircle(Offset.zero, radius, body);
    canvas.drawCircle(Offset.zero, radius, _outline);

    _flatFill.color = GamePalette.playerCore;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, radius * 0.38),
        width: radius * 1.35,
        height: radius * 0.85,
      ),
      _flatFill,
    );

    _flatFill.color = tint;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 0.12),
        width: radius * 1.35,
        height: radius * 0.72,
      ),
      _flatFill,
    );

    _flatFill.color = const Color(0xFF1A1A1A);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * 0.28, -radius * 0.16),
        width: radius * 0.42,
        height: radius * 0.46,
      ),
      _flatFill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(radius * 0.28, -radius * 0.16),
        width: radius * 0.38,
        height: radius * 0.42,
      ),
      _flatFill,
    );
    _flatFill.color = const Color(0xFFFFFFFF);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * 0.34, -radius * 0.28),
        width: radius * 0.12,
        height: radius * 0.14,
      ),
      _flatFill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(radius * 0.22, -radius * 0.28),
        width: radius * 0.1,
        height: radius * 0.12,
      ),
      _flatFill,
    );

    _flatFill.color = const Color(0xFF6B4A3A);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, radius * 0.18),
        width: radius * 0.48,
        height: radius * 0.34,
      ),
      _flatFill,
    );

    _flatFill.color = GamePalette.powerUp;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -radius * 0.48),
          width: radius * 1.55,
          height: radius * 0.32,
        ),
        Radius.circular(radius * 0.16),
      ),
      _flatFill,
    );

    _flatFill.color = tint;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * 0.28, -radius * 1.05),
        width: radius * 0.28,
        height: radius * 0.48,
      ),
      _flatFill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 1.15),
        width: radius * 0.32,
        height: radius * 0.58,
      ),
      _flatFill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(radius * 0.28, -radius * 1.02),
        width: radius * 0.26,
        height: radius * 0.44,
      ),
      _flatFill,
    );

    canvas.restore();
  }

  // --- Enemies ---------------------------------------------------------------

  @override
  void paintEnemy(
    Canvas canvas,
    Offset center, {
    required EnemyStats stats,
    required double flash,
    required double healthFraction,
    required double heading,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    _paintShadow(canvas, stats.radius);

    // Drawn outside the leaned head, so a turning bug's health bar stays
    // upright and readable.
    if (stats.hitsToKill > 1 && healthFraction < 1) {
      _paintHealthBar(canvas, stats, healthFraction);
    }

    final metal = flash > 0
        ? Color.lerp(stats.color, GamePalette.hitFlash, flash * 0.75) ??
              stats.color
        : stats.color;
    // heading 0 is right; the visor slides that way instead of spinning the
    // whole head, so the bugs stay 3/4 and still look at Dash.
    final lookX = math.cos(heading);

    final flashed = flash > 0;
    switch (stats.type) {
      case EnemyType.grunt:
        _paintGruntBug(canvas, stats.radius, metal, lookX, flashed);
      case EnemyType.runner:
        _paintRunnerBug(canvas, stats.radius, metal, lookX, flashed);
      case EnemyType.tank:
        _paintTankBug(canvas, stats.radius, metal, lookX, flashed);
    }

    canvas.restore();
  }

  /// Round house-bug: a sphere helmet, two antennae, a wide visor.
  void _paintGruntBug(
    Canvas canvas,
    double r,
    Color metal,
    double lookX,
    bool flashed,
  ) {
    final face = lookX * r * 0.22;
    final plate = _shade(metal, 0.35);
    final eye = GamePalette.enemyGruntEye;

    _paintAntenna(
      canvas,
      Offset(-r * 0.28, -r * 0.55),
      Offset(-r * 0.48 + face * 0.25, -r * 1.15),
      plate,
      r * 0.12,
    );
    _paintAntenna(
      canvas,
      Offset(r * 0.28, -r * 0.55),
      Offset(r * 0.48 + face * 0.25, -r * 1.15),
      plate,
      r * 0.12,
    );

    _flatFill.color = plate;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * 0.72),
        width: r * 0.7,
        height: r * 0.38,
      ),
      _flatFill,
    );

    canvas.drawCircle(Offset.zero, r, _bodyPaint('bug-grunt', r, metal, flashed));
    canvas.drawCircle(Offset.zero, r, _outline);

    _flatFill.color = plate;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(face * 0.2, r * 0.42),
          width: r * 1.15,
          height: r * 0.38,
        ),
        Radius.circular(r * 0.16),
      ),
      _flatFill,
    );

    _paintVisor(
      canvas,
      Offset(face, -r * 0.06),
      width: r * 1.15,
      height: r * 0.52,
      radius: r * 0.2,
    );
    _paintEye(canvas, Offset(face - r * 0.22, -r * 0.06), r * 0.28, r * 0.3, eye);
    _paintEye(canvas, Offset(face + r * 0.22, -r * 0.06), r * 0.24, r * 0.26, eye);

    _flatFill.color = GamePalette.hitFlash.withValues(alpha: 0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.28, -r * 0.38),
        width: r * 0.42,
        height: r * 0.28,
      ),
      _flatFill,
    );
  }

  /// Wasp-bug: a pointed helmet and swept antennae, the fast one.
  void _paintRunnerBug(
    Canvas canvas,
    double r,
    Color metal,
    double lookX,
    bool flashed,
  ) {
    final face = lookX * r * 0.28;
    final plate = _shade(metal, 0.32);
    final eye = GamePalette.enemyRunnerEye;

    _paintAntenna(
      canvas,
      Offset(-r * 0.1, -r * 0.35),
      Offset(-r * 0.85 - lookX * r * 0.15, -r * 1.25),
      plate,
      r * 0.1,
    );
    _paintAntenna(
      canvas,
      Offset(r * 0.1, -r * 0.35),
      Offset(r * 0.85 - lookX * r * 0.15, -r * 1.25),
      plate,
      r * 0.1,
    );

    _scratchPath
      ..reset()
      ..moveTo(lookX * r * 0.15, -r * 1.05)
      ..lineTo(r * 0.72, r * 0.15)
      ..lineTo(r * 0.2, r * 0.95)
      ..lineTo(-r * 0.2, r * 0.95)
      ..lineTo(-r * 0.72, r * 0.15)
      ..close();
    canvas.drawPath(_scratchPath, _bodyPaint('bug-runner', r, metal, flashed));
    canvas.drawPath(_scratchPath, _outline);

    _flatFill.color = plate;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(face * 0.15, r * 0.55),
          width: r * 0.7,
          height: r * 0.32,
        ),
        Radius.circular(r * 0.1),
      ),
      _flatFill,
    );

    _paintVisor(
      canvas,
      Offset(face, -r * 0.08),
      width: r * 0.95,
      height: r * 0.38,
      radius: r * 0.16,
    );
    _paintEye(canvas, Offset(face, -r * 0.08), r * 0.42, r * 0.18, eye);

    _flatFill.color = GamePalette.hitFlash.withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.12, -r * 0.42),
        width: r * 0.3,
        height: r * 0.22,
      ),
      _flatFill,
    );
  }

  /// Beetle-bug: a wide armored helmet with a horn and a small visor.
  void _paintTankBug(
    Canvas canvas,
    double r,
    Color metal,
    double lookX,
    bool flashed,
  ) {
    final face = lookX * r * 0.16;
    final plate = _shade(metal, 0.28);
    final eye = GamePalette.enemyTankEye;

    _flatFill.color = plate;
    _scratchPath
      ..reset()
      ..moveTo(face * 0.2, -r * 1.55)
      ..lineTo(r * 0.42, -r * 0.72)
      ..lineTo(r * 0.12, -r * 0.72)
      ..lineTo(0, -r * 0.95)
      ..lineTo(-r * 0.12, -r * 0.72)
      ..lineTo(-r * 0.42, -r * 0.72)
      ..close();
    canvas.drawPath(_scratchPath, _flatFill);
    canvas.drawPath(_scratchPath, _outline);

    final helm = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: r * 2.05,
        height: r * 1.85,
      ),
      Radius.circular(r * 0.38),
    );
    canvas.drawRRect(helm, _bodyPaint('bug-tank', r, metal, flashed));
    canvas.drawRRect(helm, _outline);

    _flatFill.color = _shade(metal, 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -r * 0.42),
          width: r * 1.85,
          height: r * 0.32,
        ),
        Radius.circular(r * 0.08),
      ),
      _flatFill,
    );
    _flatFill.color = plate;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(face * 0.15, r * 0.58),
          width: r * 1.35,
          height: r * 0.42,
        ),
        Radius.circular(r * 0.12),
      ),
      _flatFill,
    );

    for (final x in [-r * 0.72, r * 0.72]) {
      canvas.drawCircle(Offset(x, r * 0.08), r * 0.1, _flatFill);
    }

    _paintVisor(
      canvas,
      Offset(face, r * 0.02),
      width: r * 1.05,
      height: r * 0.4,
      radius: r * 0.1,
    );
    _paintEye(canvas, Offset(face - r * 0.2, r * 0.02), r * 0.22, r * 0.2, eye);
    _paintEye(canvas, Offset(face + r * 0.2, r * 0.02), r * 0.2, r * 0.18, eye);
  }

  void _paintAntenna(
    Canvas canvas,
    Offset base,
    Offset tip,
    Color metal,
    double thickness,
  ) {
    _stroke
      ..color = metal
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, tip, _stroke);
    _flatFill.color = metal;
    canvas.drawCircle(tip, thickness * 0.85, _flatFill);
  }

  void _paintVisor(
    Canvas canvas,
    Offset center, {
    required double width,
    required double height,
    required double radius,
  }) {
    final visor = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      Radius.circular(radius),
    );
    _flatFill.color = GamePalette.enemyVisor;
    canvas.drawRRect(visor, _flatFill);
    canvas.drawRRect(visor, _outline);
  }

  void _paintEye(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Color glow,
  ) {
    _glow.color = glow.withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: width * 1.7,
        height: height * 1.7,
      ),
      _glow,
    );
    _flatFill.color = glow;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: height),
      _flatFill,
    );
    _flatFill.color = GamePalette.hitFlash.withValues(alpha: 0.7);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-width * 0.18, -height * 0.18),
        width: width * 0.28,
        height: height * 0.28,
      ),
      _flatFill,
    );
  }

  Color _shade(Color color, double amount) {
    return Color.lerp(color, GamePalette.enemyPlate, amount) ?? color;
  }

  Paint _bodyPaint(Object key, double radius, Color metal, bool flashed) {
    if (flashed) {
      _flatFill.color = metal;
      return _flatFill;
    }
    return _orbFill(key, radius, metal);
  }

  /// A bar above the enemy rather than a ring around it: a ring traced around a
  /// square slab reads as a stray arc, and a bar works for any silhouette.
  void _paintHealthBar(Canvas canvas, EnemyStats stats, double fraction) {
    const height = 4.0;
    const corner = Radius.circular(height / 2);
    final width = stats.radius * 2.2;
    // Above antennae and the tank horn, otherwise the bar reads as part of
    // the head.
    final top = -stats.radius * 1.9;

    _flatFill.color = GamePalette.entityOutline.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-width / 2, top, width, height),
        corner,
      ),
      _flatFill,
    );

    _flatFill.color = stats.color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-width / 2, top, width * fraction, height),
        corner,
      ),
      _flatFill,
    );
  }

  // --- Bullets ---------------------------------------------------------------

  @override
  void paintBullet(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double heading,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    _glow.color = GamePalette.bullet.withValues(alpha: 0.16);
    canvas.drawCircle(Offset.zero, radius * 2.4, _glow);

    // A tracer instead of a dot: the streak is what makes the volume of fire
    // readable once a dozen bullets are in the air.
    canvas.rotate(heading);
    _stroke
      ..color = GamePalette.bullet.withValues(alpha: 0.22)
      ..strokeWidth = radius * 2.6;
    canvas.drawLine(Offset(-radius * 5, 0), Offset.zero, _stroke);
    _stroke
      ..color = GamePalette.bullet
      ..strokeWidth = radius * 1.2;
    canvas.drawLine(Offset(-radius * 2.6, 0), Offset.zero, _stroke);

    _flatFill.color = GamePalette.bullet;
    canvas.drawCircle(Offset.zero, radius, _flatFill);

    canvas.restore();
  }

  // --- Power-up --------------------------------------------------------------

  @override
  void paintPowerUp(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double age,
  }) {
    // Breathing, so a pickup lying on the floor still draws attention.
    final r = radius * (1 + 0.1 * math.sin(age * 5));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    _paintHalo(canvas, r, GamePalette.powerUp);

    canvas.save();
    canvas.rotate(age * 1.4);
    _stroke
      ..color = GamePalette.powerUp.withValues(alpha: 0.75)
      ..strokeWidth = 2.5;
    final ring = Rect.fromCircle(center: Offset.zero, radius: r + 7);
    for (var segment = 0; segment < 3; segment++) {
      canvas.drawArc(ring, segment * 2 * math.pi / 3, 1.25, false, _stroke);
    }
    canvas.restore();

    canvas.drawCircle(
      Offset.zero,
      r,
      _orbFill('power-up', radius, GamePalette.powerUp),
    );
    canvas.drawCircle(Offset.zero, r, _outline);
    _paintBolt(canvas, r);

    canvas.restore();
  }

  /// A lightning bolt, to read as "faster" without any text.
  void _paintBolt(Canvas canvas, double radius) {
    final h = radius * 0.72;
    final w = radius * 0.42;
    _scratchPath
      ..reset()
      ..moveTo(w * 0.4, -h)
      ..lineTo(-w, h * 0.15)
      ..lineTo(-w * 0.1, h * 0.15)
      ..lineTo(-w * 0.4, h)
      ..lineTo(w, -h * 0.2)
      ..lineTo(w * 0.1, -h * 0.2)
      ..close();
    _flatFill.color = GamePalette.letterbox;
    canvas.drawPath(_scratchPath, _flatFill);
  }

  // --- Aim guide -------------------------------------------------------------

  @override
  void paintAim(
    Canvas canvas,
    Offset center, {
    required double tailRadius,
    required double length,
    required double coneLength,
    required double spread,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    _paintSpreadCone(canvas, tailRadius, coneLength, spread);
    _paintArrow(canvas, tailRadius, length);

    canvas.restore();
  }

  void _paintSpreadCone(
    Canvas canvas,
    double tailRadius,
    double coneLength,
    double spread,
  ) {
    // Up is the zero direction, so x follows sin and y follows negative cos.
    Offset edge(int side, double distance) {
      final angle = side * spread;
      return Offset(math.sin(angle), -math.cos(angle)) * distance;
    }

    // A filled wedge shows the whole area shots can land in at a glance; the
    // outlines alone read as two unrelated lines.
    _scratchPath
      ..reset()
      ..moveTo(0, -tailRadius)
      ..lineTo(edge(-1, coneLength).dx, edge(-1, coneLength).dy)
      ..lineTo(edge(1, coneLength).dx, edge(1, coneLength).dy)
      ..close();
    _flatFill.color = GamePalette.aim.withValues(alpha: 0.1);
    canvas.drawPath(_scratchPath, _flatFill);

    _stroke
      ..color = GamePalette.aim.withValues(alpha: 0.45)
      ..strokeWidth = 1.5;
    for (final side in const [-1, 1]) {
      canvas.drawLine(edge(side, tailRadius), edge(side, coneLength), _stroke);
    }
  }

  void _paintArrow(Canvas canvas, double tailRadius, double length) {
    final tip = tailRadius + length;
    final headBase = tip - GameConfig.pointerHeadSize;
    final halfWidth = GameConfig.pointerHeadSize * 0.75;

    _stroke
      ..color = GamePalette.aim
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, -tailRadius), Offset(0, -headBase), _stroke);

    _scratchPath
      ..reset()
      ..moveTo(0, -tip)
      ..lineTo(-halfWidth, -headBase)
      ..lineTo(halfWidth, -headBase)
      ..close();
    _flatFill.color = GamePalette.aim;
    canvas.drawPath(_scratchPath, _flatFill);
  }

  // --- Shared bits -----------------------------------------------------------

  /// Two stacked translucent discs. Cheaper than a blur filter and, unlike one,
  /// costs the same no matter how many entities are on screen.
  void _paintHalo(Canvas canvas, double radius, Color tint) {
    _glow.color = tint.withValues(alpha: 0.14);
    canvas.drawCircle(Offset.zero, radius * 2.1, _glow);
    _glow.color = tint.withValues(alpha: 0.24);
    canvas.drawCircle(Offset.zero, radius * 1.45, _glow);
  }

  /// A squashed ellipse under the body, which lifts entities off the grid.
  void _paintShadow(Canvas canvas, double radius) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, radius * 0.7),
        width: radius * 1.9,
        height: radius * 0.75,
      ),
      _shadow,
    );
  }

  /// A lit sphere look: highlight towards the top left, base colour elsewhere.
  Paint _orbFill(Object key, double radius, Color base) {
    return _orbFills.putIfAbsent(
      key,
      () => Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [
            Color.lerp(base, const Color(0xFFFFFFFF), 0.45) ?? base,
            base,
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
  }
}
