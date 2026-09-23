/// Every gameplay tuning value lives here so balancing never requires touching
/// logic files.
///
/// Strictly numbers: the look of the game lives in `theme/` and `render/`.
abstract final class GameConfig {
  // --- World -----------------------------------------------------------------

  /// The game always simulates in this virtual resolution, regardless of the
  /// real window size, so spawn positions and balance stay identical on a Mac
  /// window and on the Steam Deck screen.
  static const double worldWidth = 1280;
  static const double worldHeight = 720;

  static const double gridCell = 80;

  /// Upper bound on the simulated step, so a frame hiccup cannot teleport
  /// entities through each other.
  ///
  /// It has to keep the per-frame bullet travel (`bulletSpeed * maxDelta`) below
  /// the smallest enemy's collision diameter (`2 * (radius + bulletRadius)`,
  /// which is 36 for the runner), otherwise a bullet could skip over an enemy
  /// between two frames.
  static const double maxDelta = 1 / 30;

  // --- Player ----------------------------------------------------------------

  static const double playerRadius = 24;
  static const double playerSpeed = 230;

  /// How large Dash Rambo is drawn. Larger than the hitbox on purpose: the
  /// rifle and bandana have to read at playfield scale, but collisions stay
  /// honest to the body.
  static const double playerVisualSize = 120;

  /// Tracer artboard, longer than the hitbox so the streak reads in flight.
  static const double bulletVisualWidth = 56;
  static const double bulletVisualHeight = 20;

  static const double powerUpVisualSize = 52;

  /// Burst speed while dashing, in pixels per second.
  static const double dashSpeed = 640;
  static const double dashDuration = 0.16;
  static const double dashCooldown = 0.65;

  /// How quickly the aim catches up with the direction of movement, per second.
  ///
  /// Movement itself stays instant, only the aim lags. If the aim snapped, then
  /// tapping up and right in turn would only ever fire along those two axes and
  /// never through the diagonal between them. Easing is what gives the run-and-gun
  /// feel of Brotato or Metal Slug. Raise it for a twitchier turret, lower it for
  /// heavier, more committed aiming.
  static const double aimResponsiveness = 14;

  /// How many facing poses Dash can show. Eight covers a stick and the
  /// keyboard diagonals without snapping everything onto the cardinals.
  static const int facingDirections = 8;

  /// Extra radians a stick must travel past the current pose centre before
  /// Dash is allowed to change drawing. Stops flicker on sector boundaries.
  static const double facingHoldRadians = 0.20;

  /// Analog sticks rest a little off centre. Below this length they are noise.
  static const double stickDeadzone = 0.18;

  /// How far R2 / RT must travel before it counts as a dash press.
  static const double triggerThreshold = 0.45;

  static const int playerMaxHp = 5;
  static const int enemyContactDamage = 1;

  /// Health at or below which the HUD treats the run as critical.
  static const int hudCriticalHp = 2;

  /// Grace period after taking a hit, so a single enemy hug cannot drain the
  /// whole health bar.
  static const double invulnerabilityDuration = 0.8;
  static const double invulnerabilityBlinkInterval = 0.08;

  // --- Aim pointer -----------------------------------------------------------

  static const double pointerLength = 42;
  static const double pointerGap = 10;
  static const double pointerHeadSize = 9;

  /// How far the spread guide lines reach. Longer than the arrow itself, since a
  /// narrow cone is only legible once it has some distance to fan out over.
  static const double pointerConeLength = 90;

  // --- Weapon ----------------------------------------------------------------

  static const double baseFireInterval = 0.35;
  static const double rapidFireMultiplier = 5;
  static const double rapidFireDuration = 15;

  /// Half-angle, in degrees, of the cone shots are scattered into.
  ///
  /// Perfectly straight fire reads as mechanical; a small random spread is what
  /// gives twin-stick survivors their loose, organic feel. Raise it for sloppier
  /// aim, drop it to zero for a laser.
  static const double bulletSpreadDegrees = 8;

  // --- Bullets ---------------------------------------------------------------

  static const double bulletSpeed = 600;
  static const double bulletRadius = 4;
  static const int bulletDamage = 1;

  /// How far outside the world a bullet may travel before it despawns. Must
  /// stay larger than the biggest enemy diameter, since enemies spawn just off
  /// screen and have to remain shootable while they walk in.
  static const double bulletDespawnMargin = 48;

  // --- Enemy spawning --------------------------------------------------------

  /// Breathing room at the start of a run before the first enemy shows up.
  static const double firstEnemyDelay = 1.2;

  static const double initialSpawnInterval = 1.8;
  static const double minSpawnInterval = 0.45;

  /// Seconds it takes for the spawn interval to ramp from initial to minimum.
  static const double spawnRampDuration = 120;

  /// Seconds before the runner and the tank start appearing at all.
  static const double runnerUnlockTime = 15;
  static const double tankUnlockTime = 35;

  /// Seconds each type needs after unlocking to reach its full spawn weight.
  static const double enemyWeightRampDuration = 45;

  /// How long a dead bug stays on the playfield while it pops and fades.
  static const double enemyDeathDuration = 0.28;

  // --- Power-up --------------------------------------------------------------

  static const double firstPowerUpDelay = 12;
  static const double minPowerUpInterval = 18;
  static const double maxPowerUpInterval = 25;

  /// How long an uncollected power-up stays on the map.
  static const double powerUpLifetime = 10;
  static const double powerUpRadius = 13;

  /// Keeps power-ups away from the walls and from spawning on top of the
  /// player.
  static const double powerUpEdgeMargin = 90;
  static const double powerUpMinDistanceFromPlayer = 140;
}
