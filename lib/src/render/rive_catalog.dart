import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart' as rive;
import 'package:rive/rive.dart' show ArtboardSelector, DataBind, RiveWidgetController, ViewModelInstance;

import '../components/enemy_type.dart';
import '../components/rive_player_visual.dart';
import '../components/rive_world_visual.dart';

/// Loads the Dash Rambo `.riv` once and hands out per-entity artboard instances.
///
/// A missing file or a failed native init must not take the game down: tests and
/// a clean checkout without a built `.riv` still run on [ShapeSkin].
class RiveCatalog {
  RiveCatalog._();

  static final RiveCatalog instance = RiveCatalog._();

  static const assetPath = 'assets/rive/dashrambo.riv';
  static const playerArtboard = 'DashRambo';
  static const tracerArtboard = 'Tracer';
  static const pickupArtboard = 'Pickup';
  static const hudArtboard = 'Hud';

  static const Map<EnemyType, String> enemyArtboards = {
    EnemyType.grunt: 'BugGrunt',
    EnemyType.runner: 'BugRunner',
    EnemyType.tank: 'BugTank',
  };

  rive.File? _file;

  /// Flips true after [load] finishes, whether the file arrived or not.
  final ValueNotifier<bool> ready = ValueNotifier(false);

  bool get isLoaded => _file != null;

  Future<void> load() async {
    if (_file != null) {
      ready.value = true;
      return;
    }
    try {
      // Factory.flutter, not Factory.rive: flame_rive draws the artboard onto
      // a Dart [Canvas]. The Rive GPU factory produces textures that
      // `Renderer.make(canvas)` cannot paint, so Dash would load and then
      // vanish — and the shape-skin fallback would stay off because the
      // component exists.
      _file = await rive.File.asset(
        assetPath,
        riveFactory: rive.Factory.flutter,
      );
    } on Object catch (error, stack) {
      debugPrint('RiveCatalog: could not load $assetPath ($error)');
      debugPrint('$stack');
      _file = null;
    }
    ready.value = true;
  }

  /// The top-bar HUD artboard, bound to [HudState].
  ({RiveWidgetController controller, ViewModelInstance? viewModel})? createHud() {
    final file = _file;
    if (file == null) {
      return null;
    }
    try {
      final controller = RiveWidgetController(
        file,
        artboardSelector: ArtboardSelector.byName(hudArtboard),
      );
      ViewModelInstance? viewModel;
      try {
        viewModel = controller.dataBind(DataBind.auto());
      } on Object {
        viewModel = null;
      }
      return (controller: controller, viewModel: viewModel);
    } on Object {
      return null;
    }
  }

  /// A fresh artboard + state machine bound to its default view model.
  ///
  /// Returns null when the catalog failed to load, so the player can keep
  /// painting through the skin.
  RivePlayerVisual? createPlayer() {
    final mounted = _mount(playerArtboard);
    if (mounted == null) {
      return null;
    }
    final (artboard, stateMachine, viewModel) = mounted;
    return RivePlayerVisual(
      artboard: artboard,
      stateMachine: stateMachine,
      viewModel: viewModel,
    );
  }

  RiveWorldVisual? createEnemy(EnemyStats stats) {
    final name = enemyArtboards[stats.type];
    if (name == null) {
      return null;
    }
    return _createWorld(name, Vector2.all(stats.visualSize));
  }

  RiveWorldVisual? createBullet(Vector2 size) => _createWorld(tracerArtboard, size);

  RiveWorldVisual? createPowerUp(Vector2 size) =>
      _createWorld(pickupArtboard, size);

  RiveWorldVisual? _createWorld(String name, Vector2 size) {
    final mounted = _mount(name);
    if (mounted == null) {
      return null;
    }
    final (artboard, stateMachine, viewModel) = mounted;
    return RiveWorldVisual(
      artboard: artboard,
      stateMachine: stateMachine,
      viewModel: viewModel,
      size: size,
    );
  }

  (rive.Artboard, rive.StateMachine?, rive.ViewModelInstance?)? _mount(
    String name,
  ) {
    final file = _file;
    if (file == null) {
      return null;
    }
    final artboard = file.artboard(name);
    if (artboard == null) {
      return null;
    }
    final viewModel = file.createDefaultViewModelInstance(artboard);
    final stateMachine = artboard.defaultStateMachine();
    if (viewModel != null) {
      stateMachine?.bindViewModelInstance(viewModel);
    }
    return (artboard, stateMachine, viewModel);
  }

  void dispose() {
    _file?.dispose();
    _file = null;
    ready.value = false;
  }
}
