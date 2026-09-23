import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../theme/game_palette.dart';

enum EnemyType { grunt, runner, tank }

/// Per-type enemy data, kept separate from behaviour so the three bug heads
/// can be rebalanced without touching [Enemy].
@immutable
class EnemyStats {
  const EnemyStats({
    required this.type,
    required this.label,
    required this.speed,
    required this.hitsToKill,
    required this.score,
    required this.radius,
    required this.color,
  });

  final EnemyType type;
  final String label;

  /// Pixels per second, in world units.
  final double speed;

  /// How many bullets it takes to bring this enemy down.
  final int hitsToKill;

  final int score;
  final double radius;
  final Color color;

  /// Drawn larger than [radius] so antennae and visors stay readable.
  double get visualSize => radius * 4;

  static const grunt = EnemyStats(
    type: EnemyType.grunt,
    label: 'Bicho',
    speed: 70,
    hitsToKill: 1,
    score: 10,
    radius: 18,
    color: GamePalette.enemyGrunt,
  );

  static const runner = EnemyStats(
    type: EnemyType.runner,
    label: 'Avispa',
    speed: 150,
    hitsToKill: 2,
    score: 25,
    radius: 14,
    color: GamePalette.enemyRunner,
  );

  static const tank = EnemyStats(
    type: EnemyType.tank,
    label: 'Escarabajo',
    speed: 40,
    hitsToKill: 5,
    score: 50,
    radius: 30,
    color: GamePalette.enemyTank,
  );

  static const Map<EnemyType, EnemyStats> byType = {
    EnemyType.grunt: grunt,
    EnemyType.runner: runner,
    EnemyType.tank: tank,
  };

  static EnemyStats of(EnemyType type) => byType[type]!;
}
