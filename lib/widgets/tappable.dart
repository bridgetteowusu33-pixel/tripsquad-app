import 'package:flutter/material.dart';
import '../core/haptics.dart';

// ─────────────────────────────────────────────────────────────
//  TAPPABLE — wraps any widget with press animation + haptic
//  Makes everything in the app feel physical
// ─────────────────────────────────────────────────────────────

class TSTappable extends StatefulWidget {
  const TSTappable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleOnPress = 0.97,
    this.opacityOnPress = 0.85,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleOnPress;
  final double opacityOnPress;
  final bool enableHaptic;

  @override
  State<TSTappable> createState() => _TSTappableState();
}

class _TSTappableState extends State<TSTappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (widget.enableHaptic) TSHaptics.light();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleOnPress : 1.0,
        duration: Duration(milliseconds: _pressed ? 80 : 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? widget.opacityOnPress : 1.0,
          duration: Duration(milliseconds: _pressed ? 80 : 120),
          child: widget.child,
        ),
      ),
    );
  }
}
