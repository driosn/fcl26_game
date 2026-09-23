import 'package:flame/components.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:rive/rive.dart';

/// A Rive artboard drawn as a child of an enemy, bullet or pickup.
///
/// The owner writes the view-model fields it cares about; missing properties
/// on a given artboard are ignored.
class RiveWorldVisual extends RiveComponent {
  RiveWorldVisual({
    required super.artboard,
    required super.stateMachine,
    required this.viewModel,
    required Vector2 size,
  }) : super(anchor: Anchor.center, size: size, priority: 0);

  final ViewModelInstance? viewModel;

  late final ViewModelInstanceNumber? _speed = viewModel?.number('speed');
  late final ViewModelInstanceBoolean? _hurt = viewModel?.boolean('hurt');
  late final ViewModelInstanceNumber? _lookX = viewModel?.number('lookX');
  late final ViewModelInstanceNumber? _health = viewModel?.number('health');
  late final ViewModelInstanceBoolean? _warning = viewModel?.boolean('warning');
  late final ViewModelInstanceBoolean? _dead = viewModel?.boolean('dead');

  void sync({
    double? speed,
    bool? hurt,
    double? lookX,
    double? health,
    bool? warning,
    bool? dead,
  }) {
    if (speed != null) {
      _speed?.value = speed;
    }
    if (hurt != null) {
      _hurt?.value = hurt;
    }
    if (lookX != null) {
      _lookX?.value = lookX;
    }
    if (health != null) {
      _health?.value = health;
    }
    if (warning != null) {
      _warning?.value = warning;
    }
    if (dead != null) {
      _dead?.value = dead;
    }
  }

  @override
  void onRemove() {
    viewModel?.dispose();
    stateMachine?.dispose();
    artboard.dispose();
    super.onRemove();
  }
}
