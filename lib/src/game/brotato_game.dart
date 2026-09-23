import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/arena.dart';
import '../components/enemy.dart';
import '../components/player.dart';
import '../components/power_up.dart';
import '../input/gamepad_input_source.dart';
import '../input/input_device.dart';
import '../input/input_source.dart';
import '../input/input_state.dart';
import '../input/keyboard_input_source.dart';
import '../render/game_skin.dart';
import '../render/rive_catalog.dart';
import '../render/shape_skin.dart';
import '../systems/enemy_spawner.dart';
import '../systems/power_up_spawner.dart';
import '../theme/game_palette.dart';
import 'game_config.dart';
import 'game_state.dart';

/// Root of the simulation.
///
/// Deliberately knows nothing about the Flutter UI: menus and the HUD are driven
/// by watching [GameState.status], which keeps the game runnable headlessly in
/// tests and leaves the presentation layer free to become Rive later.
class FCLGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  FCLGame({
    math.Random? random,
    GameSkin? skin,
    this.enableRive = false,
    this.listenToGamepadHardware = true,
  }) : _random = random ?? math.Random(),
       skin = skin ?? ShapeSkin(),
       super(
         camera: CameraComponent.withFixedResolution(
           width: GameConfig.worldWidth,
           height: GameConfig.worldHeight,
         ),
       ) {
    gamepadSource = GamepadInputSource(
      listenToHardware: listenToGamepadHardware,
      onImmediateActions: _drainActions,
    );
    _inputSources = [keyboardSource, gamepadSource];
  }

  final math.Random _random;

  /// Shared source of randomness, so a seeded game replays identically.
  math.Random get random => _random;

  /// How the world is drawn. Components own no paints of their own, so replacing
  /// this is all it takes to re-skin the game, assets included.
  final GameSkin skin;

  /// Shared Rive file. Loaded once in [onLoad]; a failed load leaves the
  /// player on [ShapeSkin].
  final RiveCatalog rive = RiveCatalog.instance;

  /// Off in tests so a missing `.riv` or a failed native init cannot change
  /// collision or render behaviour. The real app turns it on in `main.dart`.
  final bool enableRive;

  /// Off in unit tests so the gamepads plugin channel is never opened.
  final bool listenToGamepadHardware;

  final GameState state = GameState();
  final InputState inputState = InputState();
  final KeyboardInputSource keyboardSource = KeyboardInputSource();
  late final GamepadInputSource gamepadSource;
  late final List<InputSource> _inputSources;

  Player? _player;

  /// Null between runs, while the world is being rebuilt.
  Player? get player => _player;

  /// Pausing is deferred to the end of the frame: [onPlayerDied] can fire from
  /// inside the collision pass, and stopping the engine there would cut that
  /// pass short.
  bool _pausePending = false;

  /// Fills the letterbox bars when the window is not 16:9.
  @override
  Color backgroundColor() => GamePalette.letterbox;

  @override
  Future<void> onLoad() async {
    await skin.load();
    if (enableRive) {
      await rive.load();
    }
    // The viewfinder is centred by default, so aiming it at the middle of the
    // world makes the 1280x720 box exactly fill the viewport.
    camera.viewfinder.position = Vector2(
      GameConfig.worldWidth / 2,
      GameConfig.worldHeight / 2,
    );
    world.add(Arena());
    _startRun();
  }

  @override
  void update(double dt) {
    // A long frame must not let anything tunnel through a hitbox.
    final clamped = math.min(dt, GameConfig.maxDelta);

    inputState.beginFrame();
    for (final source in _inputSources) {
      source.poll(inputState);
    }
    inputState.endFrame();
    _drainActions();

    if (state.isPlaying) {
      state.tick(clamped);
    }
    super.update(clamped);

    if (_pausePending) {
      _pausePending = false;
      pauseEngine();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final consumed = keyboardSource.handleKeyEvent(event, keysPressed);
    if (consumed) {
      inputState.noteDevice(InputDeviceKind.keyboard);
    }
    // Actions are handled here as well as in [update], because the update loop
    // is not running while the engine is paused.
    _drainActions();
    return consumed ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  // --- Run lifecycle ---------------------------------------------------------

  void restart() {
    resumeEngine();
    _startRun();
  }

  void togglePause() {
    switch (state.status.value) {
      case GameStatus.playing:
        state.status.value = GameStatus.paused;
        pauseEngine();
      case GameStatus.paused:
        state.status.value = GameStatus.playing;
        resumeEngine();
      case GameStatus.gameOver:
        break;
    }
  }

  void _startRun() {
    // Everything except the backdrop belongs to a single run.
    world.removeWhere((component) => component is! Arena);
    state.reset();
    _pausePending = false;

    final player = Player(
      position: Vector2(GameConfig.worldWidth / 2, GameConfig.worldHeight / 2),
    );
    _player = player;
    world.addAll([
      player,
      EnemySpawner(random: _random),
      PowerUpSpawner(random: _random),
    ]);
  }

  // --- Gameplay events -------------------------------------------------------

  void onEnemyKilled(Enemy enemy) {
    state.addKill(points: enemy.stats.score);
  }

  void onPowerUpCollected(PowerUp powerUp) {
    powerUp.collect();
    _player?.weapon.activateRapidFire();
  }

  void onPlayerDied() {
    if (state.status.value == GameStatus.gameOver) {
      return;
    }
    state.status.value = GameStatus.gameOver;
    _pausePending = true;
  }

  // --- Internals -------------------------------------------------------------

  void _drainActions() {
    for (final source in _inputSources) {
      for (final action in source.drainActions()) {
        inputState.noteDevice(
          source is GamepadInputSource
              ? InputDeviceKind.gamepad
              : InputDeviceKind.keyboard,
        );
        switch (action) {
          case GameAction.pauseToggle:
            togglePause();
          case GameAction.confirm:
            _confirm();
          case GameAction.dash:
            _player?.tryDash();
        }
      }
    }
  }

  void _confirm() {
    switch (state.status.value) {
      case GameStatus.gameOver:
        restart();
      case GameStatus.paused:
        togglePause();
      case GameStatus.playing:
        break;
    }
  }

  @override
  void onRemove() {
    for (final source in _inputSources) {
      source.dispose();
    }
    super.onRemove();
  }
}
