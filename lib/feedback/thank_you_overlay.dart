import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

/// Full-screen confetti + "you're a real one" overlay shown after a happy
/// user is sent to Apple's review prompt. Auto-dismisses after 2.5s.
void showThankYouOverlay(BuildContext context) {
  final overlay = OverlayEntry(builder: (_) => const _ThankYouOverlay());
  Overlay.of(context).insert(overlay);
  Future.delayed(const Duration(milliseconds: 2500), () {
    overlay.remove();
  });
}

class _ThankYouOverlay extends StatefulWidget {
  const _ThankYouOverlay();

  @override
  State<_ThankYouOverlay> createState() => _ThankYouOverlayState();
}

class _ThankYouOverlayState extends State<_ThankYouOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeCtrl,
      builder: (_, __) => Opacity(
        opacity: 1.0 - _fadeCtrl.value,
        child: Material(
          color: Colors.black.withOpacity(0.7),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(progress: _confettiCtrl.value),
                  size: Size.infinite,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 14),
                    Text(
                      "you're a real one",
                      style: TSTextStyles.heading(
                          size: 26, color: TSColors.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'thanks for the love. it means everything.',
                      style: TSTextStyles.body(color: TSColors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});
  final double progress;

  static const _colors = [
    TSColors.lime,
    TSColors.gold,
    TSColors.coral,
    TSColors.blue,
    TSColors.purple,
    TSColors.teal,
    TSColors.pink,
  ];

  static final List<_P> _particles = List.generate(40, (i) {
    final rng = Random(i * 11 + 3);
    return _P(
      x: rng.nextDouble(),
      startY: -0.1 - rng.nextDouble() * 0.3,
      speed: 0.3 + rng.nextDouble() * 0.7,
      size: 3 + rng.nextDouble() * 5,
      rotation: rng.nextDouble() * pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 4,
      ci: rng.nextInt(_colors.length),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = p.startY + progress * p.speed * 1.5;
      if (y < -0.5 || y > 1.2) continue;
      final alpha = progress > 0.7 ? (1.0 - (progress - 0.7) / 0.3) : 1.0;
      if (alpha <= 0) continue;
      canvas.save();
      canvas.translate(p.x * size.width, y * size.height);
      canvas.rotate(p.rotation + progress * p.rotSpeed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1.5),
        ),
        Paint()..color = _colors[p.ci].withOpacity(alpha.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _P {
  const _P({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.ci,
  });
  final double x, startY, speed, size, rotation, rotSpeed;
  final int ci;
}
