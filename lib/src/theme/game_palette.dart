import 'dart:ui';

/// Every colour the game uses, gameplay and UI alike.
///
/// This is the first stop for re-skinning: nothing else in the codebase is
/// allowed to hardcode a colour, so a new look never means hunting through
/// component and widget files. When real art arrives these stay useful as the
/// tint and glow colours that have to match it.
abstract final class GamePalette {
  // --- Surfaces --------------------------------------------------------------

  /// Behind the arena, filling the letterbox bars when the window is not 16:9.
  /// Darker than the arena on purpose, so the playfield reads as a lit screen.
  static const Color letterbox = Color(0xFF07080A);

  /// Lead hangar: cool slate so the green bug heads stay readable.
  static const Color arenaTop = Color(0xFF2A2E34);
  static const Color arenaBottom = Color(0xFF101216);
  static const Color arenaMoon = Color(0x33C8D0D8);
  static const Color arenaDirt = Color(0xFF0A0C10);
  static const Color arenaPath = Color(0xFF3A4048);
  static const Color arenaSlab = Color(0xFF2C3138);
  static const Color arenaSlabEdge = Color(0xFF6A727C);
  static const Color arenaHatch = Color(0xFF1C2026);
  static const Color arenaPad = Color(0xFF3E454E);
  static const Color arenaPadRing = Color(0xFFC4B05A);
  static const Color arenaTrace = Color(0x88A8B0B8);
  static const Color arenaNode = Color(0xCCD0D6DC);
  static const Color arenaRubble = Color(0xFF181C22);
  static const Color arenaRubbleMid = Color(0xFF2C323A);
  static const Color arenaScrap = Color(0xFF6A727C);
  static const Color arenaWall = Color(0xC2000000);
  static const Color gridMinor = Color(0x263A4048);
  static const Color gridMajor = Color(0x40586068);
  static const Color arenaBorder = Color(0xFF8A929C);
  static const Color arenaVignetteInner = Color(0x00000000);
  static const Color arenaVignetteOuter = Color(0x80000000);

  /// Brass, shared by the arena frame and the HUD so the hangar and the
  /// menus feel like the same movie.
  static const Color accent = Color(0xFFE8C15A);
  static const Color scoreShadow = Color(0xE6000000);
  static const Color scoreGlow = Color(0x99E8C15A);

  // --- Entities --------------------------------------------------------------

  /// Dash's body blue. The Rive rig uses the same pair.
  static const Color player = Color(0xFF54C5F8);
  static const Color playerCore = Color(0xFFE8F4FA);
  static const Color playerHurt = Color(0xFFFF4D6D);
  static const Color beak = Color(0xFF6B4A3A);

  /// Warm on purpose. A cyan guide, however logical, disappears into the player's
  /// own glow, and the aim line is the one thing that must always be readable.
  static const Color aim = Color(0xFFFFE08A);

  static const Color bullet = Color(0xFFFFF6D5);
  static const Color powerUp = Color(0xFFE03C3C);
  static const Color hitFlash = Color(0xFFFFFFFF);

  /// Dark outline that keeps entities legible against any backdrop.
  static const Color entityOutline = Color(0xFF080A12);
  static const Color entityShadow = Color(0x4D000000);

  static const Color enemyGrunt = Color(0xFF6F8F4E);
  static const Color enemyRunner = Color(0xFFC9A24A);
  static const Color enemyTank = Color(0xFF8B3A2A);

  /// Dark plates and the visor cavity shared by every bug head.
  static const Color enemyPlate = Color(0xFF161A14);
  static const Color enemyVisor = Color(0xFF07090C);

  static const Color enemyGruntEye = Color(0xFF7DFFB3);
  static const Color enemyRunnerEye = Color(0xFFFFE08A);
  static const Color enemyTankEye = Color(0xFFFF6B4A);

  // --- UI --------------------------------------------------------------------

  static const Color panel = Color(0xFF141A2B);
  static const Color panelHighlight = Color(0x1AFFFFFF);
  static const Color panelBorder = Color(0x26FFFFFF);
  static const Color scrim = Color(0xB305060B);

  static const Color textPrimary = Color(0xFFF2F5FF);
  static const Color textSecondary = Color(0xFFA7B0CC);
  static const Color textMuted = Color(0xFF6B7492);

  static const Color health = Color(0xFFE03C3C);
  static const Color healthEmpty = Color(0x1FFFFFFF);
  static const Color danger = Color(0xFFFF4D6D);

  /// Steam Deck / Xbox face buttons, for tutorial glyphs.
  static const Color deckA = Color(0xFF3CB44A);
  static const Color deckB = Color(0xFFE03C3C);
  static const Color deckX = Color(0xFF3D7EFF);
  static const Color deckY = Color(0xFFE8C15A);
}
