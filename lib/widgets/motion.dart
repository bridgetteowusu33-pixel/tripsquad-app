import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  SIGNATURE MOTION PRIMITIVES
//
//  Named, ownable animations from the UX redesign spec. Use these
//  by name instead of rolling bespoke animations — that's how a
//  product builds a motion signature instead of a motion library.
//
//  - TheTide   — fluid horizontal progress (Live Response, Voting)
//  - ThePulse  — lime dot breathing (Splash, AI gen, Live "now")
//  - TheBloom  — soft aura around an avatar on action (Presence)
//  - ScoutLine — vertical lime→purple gradient line as "Scout's
//                margin of presence" on chat messages, Tips cards,
//                and other Scout surfaces
// ─────────────────────────────────────────────────────────────

/// Fluid horizontal progress bar used in the Live Response Dashboard
/// (tide filling as squad members respond) and the Voting screen
/// (tally bars growing live).
///
/// Not a LinearProgressIndicator — this bar eases with a subtle
/// overshoot and leaves a trailing glow for a few frames, so the
/// group energy feels liquid rather than mechanical.
class TheTide extends StatefulWidget {
  const TheTide({
    super.key,
    required this.progress,
    this.height = 6,
    this.color = TSColors.lime,
    this.trackColor,
    this.duration = const Duration(milliseconds: 520),
  }) : assert(progress >= 0 && progress <= 1);

  final double progress;
  final double height;
  final Color color;
  final Color? trackColor;
  final Duration duration;

  @override
  State<TheTide> createState() => _TheTideState();
}

class _TheTideState extends State<TheTide>
    with SingleTickerProviderStateMixin {
  double _displayed = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.progress;
  }

  @override
  void didUpdateWidget(covariant TheTide old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      setState(() => _displayed = widget.progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.trackColor ?? TSColors.border2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height),
      child: Container(
        height: widget.height,
        color: track,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _displayed),
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => LayoutBuilder(
            builder: (context, c) => Stack(children: [
              Container(
                width: c.maxWidth * v,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.85),
                      widget.color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Lime dot breathing at 0.8 Hz. Core visual element of:
/// - Splash (single pulse → globe expand)
/// - AI Generation loading ("the Consulting")
/// - Live Trip Mode ("NOW" indicator on current activity)
///
/// The pulse is a scale + opacity wave. No bounce. No overshoot.
class ThePulse extends StatefulWidget {
  const ThePulse({
    super.key,
    this.size = 12,
    this.color = TSColors.lime,
    this.frequencyHz = 0.8,
  });

  final double size;
  final Color color;
  final double frequencyHz;

  @override
  State<ThePulse> createState() => _ThePulseState();
}

class _ThePulseState extends State<ThePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000 / widget.frequencyHz).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        // Cosine wave 0..1..0 — smooth breathing.
        final t = (1 - math.cos(_c.value * 2 * math.pi)) / 2;
        final halo = widget.size + widget.size * 1.4 * t;
        return SizedBox(
          width: halo,
          height: halo,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: halo,
              height: halo,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.18 * (1 - t)),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.55),
                    blurRadius: 10 + 10 * t,
                    spreadRadius: 1 + 2 * t,
                  ),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Soft lime aura that pulses once around a child widget and fades.
/// Used when a user acts (on Presence strip, voting tide). Non-intrusive
/// — the child stays fully rendered; TheBloom is decoration around it.
///
/// Trigger: change [trigger] to any new object (a timestamp, a counter)
/// to replay the bloom. The widget watches for changes via
/// [didUpdateWidget].
class TheBloom extends StatefulWidget {
  const TheBloom({
    super.key,
    required this.child,
    required this.trigger,
    this.color = TSColors.lime,
    this.maxRadius = 26,
  });

  final Widget child;
  final Object trigger;
  final Color color;
  final double maxRadius;

  @override
  State<TheBloom> createState() => _TheBloomState();
}

class _TheBloomState extends State<TheBloom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant TheBloom old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Container(
                  width: widget.maxRadius * t + 4,
                  height: widget.maxRadius * t + 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.25),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.35),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// The vertical lime→purple gradient line that identifies Scout-authored
/// content. Not a full bubble — a *margin of presence*.
///
/// Wraps any child widget and prepends a 3pt-wide vertical gradient
/// bar, with configurable padding between the bar and the content.
///
/// Used on:
/// - Scout messages in the trip chat (chat_tab.dart)
/// - Scout nudge cards on the Tips tab
/// - Scout messages in the Scout tab history
///
/// NOTE: the purple→lime gradient is a scarce brand asset. Restrict to
/// Scout-authored surfaces only. Do not reuse elsewhere.
class ScoutLine extends StatelessWidget {
  const ScoutLine({
    super.key,
    required this.child,
    this.width = 3,
    this.gap = 12,
    this.radius = 2,
  });

  final Widget child;
  final double width;
  final double gap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                colors: [TSColors.purple, TSColors.lime],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Horizontal row of response dots — filled for responded, muted
/// for pending. Used on the Trip Card and the Status tab header.
///
/// This is the visual language of group energy: dots filling in
/// one at a time as the squad commits.
class ResponseDots extends StatelessWidget {
  const ResponseDots({
    super.key,
    required this.total,
    required this.responded,
    this.size = 8,
    this.gap = 6,
  });

  final int total;
  final int responded;
  final double size;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < responded ? TSColors.lime : TSColors.border2,
              boxShadow: i < responded
                  ? [
                      BoxShadow(
                        color: TSColors.lime.withOpacity(0.35),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          ),
          if (i != total - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}
