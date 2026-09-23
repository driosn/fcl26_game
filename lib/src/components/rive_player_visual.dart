import 'package:flame/components.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:rive/rive.dart';

import '../game/game_config.dart';

/// Dash Rambo drawn by Rive, as a child of [Player].
///
/// Eight facing poses live on the artboard. The owner writes [facing] as
/// 0–7; the state machine cross-fades the drawing. Gameplay flags go into
/// the rest of the view model.
class RivePlayerVisual extends RiveComponent {
  RivePlayerVisual({
    required super.artboard,
    required super.stateMachine,
    required this.viewModel,
  }) : super(
         anchor: Anchor.center,
         size: Vector2.all(GameConfig.playerVisualSize),
         priority: 0,
       );

  final ViewModelInstance? viewModel;

  late final ViewModelInstanceNumber? _speed = viewModel?.number('speed');
  late final ViewModelInstanceBoolean? _dashing = viewModel?.boolean('dashing');
  late final ViewModelInstanceBoolean? _hurt = viewModel?.boolean('hurt');
  late final ViewModelInstanceBoolean? _firing = viewModel?.boolean('firing');
  late final ViewModelInstanceNumber? _facing = viewModel?.number('facing');

  void sync({
    required double speed,
    required bool dashing,
    required bool hurt,
    required bool firing,
    required int facing,
  }) {
    _speed?.value = speed;
    _dashing?.value = dashing;
    _hurt?.value = hurt;
    _firing?.value = firing;
    _facing?.value = facing.toDouble();
  }

  @override
  void onRemove() {
    viewModel?.dispose();
    stateMachine?.dispose();
    artboard.dispose();
    super.onRemove();
  }
}
