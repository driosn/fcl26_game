import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/game_palette.dart';

/// The surface every cluster of UI sits on: a dark translucent slab with a hair
/// line border and a soft drop shadow.
///
/// Using one panel everywhere is what keeps the HUD and the menus looking like
/// parts of the same machine.
class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.radius = 14,
    this.accent,
    this.blurred = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Draws a thin bar along the top edge, to colour-code the panel.
  final Color? accent;

  /// Frosts whatever sits behind the panel. Only worth the cost while the engine
  /// is paused, since it re-blurs the game canvas on every frame.
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GamePalette.panel.withValues(alpha: blurred ? 0.9 : 0.72),
            GamePalette.letterbox.withValues(alpha: blurred ? 0.94 : 0.78),
          ],
        ),
        border: Border.all(color: GamePalette.panelBorder),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (accent != null) {
      content = Stack(
        children: [
          content,
          Positioned(
            left: radius,
            right: radius,
            top: 0,
            child: Container(height: 2, color: accent),
          ),
        ],
      );
    }

    if (blurred) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: content,
      );
    }

    // The shadow lives outside the clip, or the clip would cut it off.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: borderRadius, child: content),
    );
  }
}
