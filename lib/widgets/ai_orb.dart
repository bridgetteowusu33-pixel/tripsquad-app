import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  AI ORB — the visual identity of all AI moments
//  Idle: slow rotate  |  Thinking: wavy + fast  |  Success: burst
// ─────────────────────────────────────────────────────────────

enum AIOrbState { idle, thinking, success, error }

class TSAIOrb extends StatefulWidget {
  const TSAIOrb({
    super.key,
    this.size = 80,
    this.state = AIOrbState.thinking,
  });
  final double size;
  final AIOrbState state;

  @override
  State<TSAIOrb> createState() => _TSAIOrbState();
}

class _TSAIOrbState extends State<TSAIOrb> with SingleTickerProviderStateMixin {
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
    final isThinking = widget.state == AIOrbState.thinking;
    final isError = widget.state == AIOrbState.error;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
          return CustomPaint(
            painter: _OrbPainter(
              time: time,
              size: widget.size,
              isThinking: isThinking,
              isError: isError,
            ),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.time,
    required this.size,
    required this.isThinking,
    required this.isError,
  });

  final double time;
  final double size;
  final bool isThinking;
  final bool isError;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 4;

    // Outer glow
    final glowColor = isError
        ? TSColors.coral.withOpacity(0.15)
        : TSColors.lime.withOpacity(0.1 + (isThinking ? 0.05 * sin(time * 3) : 0));
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..shader = RadialGradient(
          colors: [glowColor, glowColor.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 20)),
    );

    // Main orb with wavy edge when thinking
    final path = Path();
    final speed = isThinking ? 4.0 : 1.0;
    final amplitude = isThinking ? 3.0 : 0.5;

    for (var i = 0; i <= 360; i += 2) {
      final angle = i * pi / 180;
      final wave = amplitude * sin(angle * 6 + time * speed);
      final r = radius + wave;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Gradient fill
    final color1 = isError ? TSColors.coral : TSColors.purple;
    final color2 = isError ? TSColors.coral : TSColors.lime;
    final gradientAngle = time * (isThinking ? 1.5 : 0.3);

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(cos(gradientAngle), sin(gradientAngle)),
          end: Alignment(-cos(gradientAngle), -sin(gradientAngle)),
          colors: [
            color1.withOpacity(0.6),
            color2.withOpacity(0.4),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Inner highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.2),
      radius * 0.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(center.dx - radius * 0.2, center.dy - radius * 0.2),
          radius: radius * 0.4,
        )),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
