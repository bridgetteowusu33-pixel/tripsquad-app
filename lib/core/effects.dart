import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';

// ─────────────────────────────────────────────────────────────
//  TRIPSQUAD VISUAL EFFECTS LIBRARY
//  Ambient animations, glass cards, shimmer text, glow orbs
// ─────────────────────────────────────────────────────────────

/// Animated pulsing radial gradient orb — floats behind content
class TSGlowOrb extends StatefulWidget {
  const TSGlowOrb({
    super.key,
    this.color = TSColors.lime,
    this.size = 160,
    this.opacity = 0.15,
    this.duration = const Duration(seconds: 4),
  });
  final Color color;
  final double size;
  final double opacity;
  final Duration duration;

  @override
  State<TSGlowOrb> createState() => _TSGlowOrbState();
}

class _TSGlowOrbState extends State<TSGlowOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOutSine.transform(_ctrl.value);
        final scale = 0.95 + (t * 0.1);
        final opacity = (widget.opacity * 0.6) + (t * widget.opacity * 0.4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(opacity),
                  widget.color.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Floating particle field — subtle living background
class TSParticleField extends StatefulWidget {
  const TSParticleField({
    super.key,
    this.color = TSColors.lime,
    this.count = 25,
    this.opacity = 0.1,
  });
  final Color color;
  final int count;
  final double opacity;

  @override
  State<TSParticleField> createState() => _TSParticleFieldState();
}

class _TSParticleFieldState extends State<TSParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (_) => _Particle(_rand));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        for (final p in _particles) {
          p.update();
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            color: widget.color,
            opacity: widget.opacity,
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle(Random rand)
      : x = rand.nextDouble(),
        y = rand.nextDouble(),
        dx = (rand.nextDouble() - 0.5) * 0.001,
        dy = (rand.nextDouble() - 0.5) * 0.0005 - 0.0002,
        radius = 1.0 + rand.nextDouble() * 2.0,
        alpha = 0.3 + rand.nextDouble() * 0.7;

  double x, y, dx, dy, radius, alpha;

  void update() {
    x += dx;
    y += dy;
    if (x < 0) x = 1.0;
    if (x > 1) x = 0.0;
    if (y < 0) y = 1.0;
    if (y > 1) y = 0.0;
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.opacity,
  });
  final List<_Particle> particles;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        Paint()..color = color.withOpacity(opacity * p.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Full-screen animated mesh gradient background
class TSMorphGradient extends StatefulWidget {
  const TSMorphGradient({
    super.key,
    this.color1 = TSColors.lime,
    this.color2 = TSColors.purple,
    this.opacity = 0.06,
  });
  final Color color1;
  final Color color2;
  final double opacity;

  @override
  State<TSMorphGradient> createState() => _TSMorphGradientState();
}

class _TSMorphGradientState extends State<TSMorphGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size.infinite,
        painter: _MorphPainter(
          time: DateTime.now().millisecondsSinceEpoch.toDouble(),
          color1: widget.color1,
          color2: widget.color2,
          opacity: widget.opacity,
        ),
      ),
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter({
    required this.time,
    required this.color1,
    required this.color2,
    required this.opacity,
  });
  final double time;
  final Color color1;
  final Color color2;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time * 0.0003;
    final points = [
      Offset(
        size.width * (0.3 + 0.2 * sin(t * 0.7)),
        size.height * (0.2 + 0.15 * cos(t * 0.5)),
      ),
      Offset(
        size.width * (0.7 + 0.15 * cos(t * 0.6)),
        size.height * (0.3 + 0.2 * sin(t * 0.8)),
      ),
      Offset(
        size.width * (0.4 + 0.2 * sin(t * 0.9)),
        size.height * (0.7 + 0.15 * cos(t * 0.4)),
      ),
      Offset(
        size.width * (0.8 + 0.1 * cos(t * 0.5)),
        size.height * (0.8 + 0.1 * sin(t * 0.7)),
      ),
    ];

    for (var i = 0; i < points.length; i++) {
      final color = i.isEven ? color1 : color2;
      final radius = size.width * (0.3 + 0.1 * sin(t + i));
      canvas.drawCircle(
        points[i],
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0),
            ],
          ).createShader(
            Rect.fromCircle(center: points[i], radius: radius),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Shimmer text — sweeping highlight effect
class TSShimmerText extends StatefulWidget {
  const TSShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.shimmerColor = TSColors.lime,
    this.duration = const Duration(milliseconds: 2000),
    this.textAlign,
  });
  final String text;
  final TextStyle style;
  final Color shimmerColor;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  State<TSShimmerText> createState() => _TSShimmerTextState();
}

class _TSShimmerTextState extends State<TSShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value * 3 - 1; // sweep from -1 to 2
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              widget.style.color ?? Colors.white,
              widget.shimmerColor,
              widget.style.color ?? Colors.white,
            ],
            stops: [
              (t - 0.3).clamp(0.0, 1.0),
              t.clamp(0.0, 1.0),
              (t + 0.3).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: Text(
            widget.text,
            style: widget.style.copyWith(color: Colors.white),
            textAlign: widget.textAlign,
          ),
        );
      },
    );
  }
}

/// Concentric pulse rings — sonar/presence indicator
class TSPulseRing extends StatefulWidget {
  const TSPulseRing({
    super.key,
    this.color = TSColors.lime,
    this.size = 60,
    this.ringCount = 3,
  });
  final Color color;
  final double size;
  final int ringCount;

  @override
  State<TSPulseRing> createState() => _TSPulseRingState();
}

class _TSPulseRingState extends State<TSPulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _PulseRingPainter(
            progress: _ctrl.value,
            color: widget.color,
            ringCount: widget.ringCount,
          ),
        ),
      ),
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  _PulseRingPainter({
    required this.progress,
    required this.color,
    required this.ringCount,
  });
  final double progress;
  final Color color;
  final int ringCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < ringCount; i++) {
      final delay = i / ringCount;
      final t = (progress + delay) % 1.0;
      final scale = 0.3 + t * 0.7;
      final opacity = (1.0 - t) * 0.4;
      canvas.drawCircle(
        center,
        maxRadius * scale,
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Glass card — frosted blur surface
class TSGlassCard extends StatelessWidget {
  const TSGlassCard({
    super.key,
    required this.child,
    this.accentColor,
    this.borderRadius,
    this.padding,
    this.onTap,
  });
  final Widget child;
  final Color? accentColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(TSRadius.mdValue);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(TSSpacing.md),
            decoration: BoxDecoration(
              color: TSColors.s2.withOpacity(0.6),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: accentColor != null
                  ? [
                      BoxShadow(
                        color: accentColor!.withOpacity(0.08),
                        blurRadius: 24,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
