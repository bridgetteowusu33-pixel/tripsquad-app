import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/effects.dart';

// ─────────────────────────────────────────────────────────────
//  TS SCAFFOLD — replaces Scaffold with ambient backgrounds
//  standard: flat dark  |  ambient: + particles  |  hero: + morph gradient
// ─────────────────────────────────────────────────────────────

enum TSBackgroundStyle { standard, ambient, hero }

class TSScaffold extends StatelessWidget {
  const TSScaffold({
    super.key,
    required this.body,
    this.style = TSBackgroundStyle.standard,
    this.accentColor,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final TSBackgroundStyle style;
  final Color? accentColor;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          // Morph gradient (hero only)
          if (style == TSBackgroundStyle.hero)
            Positioned.fill(
              child: TSMorphGradient(
                color1: accentColor ?? TSColors.lime,
                color2: TSColors.purple,
                opacity: 0.06,
              ),
            ),

          // Particle field (ambient + hero)
          if (style == TSBackgroundStyle.ambient ||
              style == TSBackgroundStyle.hero)
            Positioned.fill(
              child: TSParticleField(
                color: accentColor ?? TSColors.lime,
                count: style == TSBackgroundStyle.hero ? 30 : 20,
                opacity: 0.12,
              ),
            ),

          // Ambient glow (ambient + hero)
          if (style == TSBackgroundStyle.ambient ||
              style == TSBackgroundStyle.hero)
            Positioned(
              top: -80,
              right: -60,
              child: TSGlowOrb(
                color: accentColor ?? TSColors.lime,
                size: 300,
                opacity: 0.06,
              ),
            ),

          // Actual content
          body,
        ],
      ),
    );
  }
}
