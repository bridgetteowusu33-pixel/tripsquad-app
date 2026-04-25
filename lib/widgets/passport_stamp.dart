import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  PASSPORT STAMP
//
//  A circular, destination-themed mark earned on trip completion.
//  Drawn procedurally (no per-destination illustrations required
//  for v1) so any destination can produce a stamp. Per-destination
//  bespoke illustrations land in v1.1 via a design pipeline.
//
//  Structure, concentric outward:
//  - Outer serrated ring (classic passport stamp silhouette)
//  - Inner hairline ring
//  - Flag emoji at centre
//  - Destination name arcing above the flag
//  - Dates arcing below
//  - Serial number at the 6-o-clock position
//
//  Colour: driven by vibe accent (same logic as Trip Recap card)
//  or the passed-in [accent]. A subtle 2° tilt gives the stamp a
//  stamped-by-hand feel.
// ─────────────────────────────────────────────────────────────

class PassportStamp extends StatelessWidget {
  const PassportStamp({
    super.key,
    required this.destination,
    required this.flag,
    required this.dateLabel,
    this.serial,
    this.accent = TSColors.lime,
    this.size = 180,
    this.tiltDegrees = -2,
  });

  final String destination;
  final String flag;
  final String dateLabel;

  /// Optional serial string, e.g. "#024 · 2026". Rendered at 6 o'clock.
  final String? serial;

  /// Ring + text colour. Defaults to lime.
  final Color accent;

  final double size;
  final double tiltDegrees;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tiltDegrees * math.pi / 180,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _StampPainter(
            destination: destination,
            flag: flag,
            dateLabel: dateLabel,
            serial: serial,
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  _StampPainter({
    required this.destination,
    required this.flag,
    required this.dateLabel,
    required this.serial,
    required this.accent,
  });

  final String destination;
  final String flag;
  final String dateLabel;
  final String? serial;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;

    // Faint ink wash — makes the stamp look "inked" on paper.
    final wash = Paint()
      ..color = accent.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centre, r * 0.98, wash);

    // Outer serrated ring — classic passport-stamp silhouette.
    // 48 teeth cut into a ring via a path.
    final teeth = 48;
    final outer = r * 0.98;
    final inner = r * 0.92;
    final toothPath = Path();
    for (var i = 0; i < teeth; i++) {
      final t = i / teeth;
      final a = t * 2 * math.pi;
      final radius = i.isEven ? outer : inner;
      final p = Offset(
        centre.dx + radius * math.cos(a),
        centre.dy + radius * math.sin(a),
      );
      if (i == 0) {
        toothPath.moveTo(p.dx, p.dy);
      } else {
        toothPath.lineTo(p.dx, p.dy);
      }
    }
    toothPath.close();
    canvas.drawPath(
      toothPath,
      Paint()
        ..color = accent.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Inner thin ring
    canvas.drawCircle(
      centre,
      r * 0.72,
      Paint()
        ..color = accent.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Curved destination name arcing ABOVE the flag.
    _drawCurvedText(
      canvas,
      destination.toUpperCase(),
      centre,
      r * 0.82,
      startAngle: -math.pi / 2,
      arcSweep: math.pi * 0.9,
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: size.width * 0.074,
        fontWeight: FontWeight.w800,
        letterSpacing: size.width * 0.004,
        color: accent,
      ),
      above: true,
    );

    // Flag emoji at centre — large, dominant.
    final flagPainter = TextPainter(
      text: TextSpan(
        text: flag,
        style: TextStyle(fontSize: r * 0.85, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    flagPainter.paint(
      canvas,
      Offset(centre.dx - flagPainter.width / 2,
          centre.dy - flagPainter.height / 2),
    );

    // Date arcing BELOW the flag.
    _drawCurvedText(
      canvas,
      dateLabel,
      centre,
      r * 0.82,
      startAngle: math.pi / 2,
      arcSweep: math.pi * 0.6,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: size.width * 0.052,
        fontWeight: FontWeight.w500,
        letterSpacing: size.width * 0.002,
        color: accent.withOpacity(0.9),
      ),
      above: false,
    );

    // Serial stamp below the date arc (small, at 6 o'clock).
    if (serial != null) {
      final serialPainter = TextPainter(
        text: TextSpan(
          text: serial,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: size.width * 0.04,
            fontWeight: FontWeight.w700,
            letterSpacing: size.width * 0.003,
            color: accent.withOpacity(0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      serialPainter.paint(
        canvas,
        Offset(centre.dx - serialPainter.width / 2,
            centre.dy + r * 0.58),
      );
    }

    // Tiny star ornament at 12 o'clock
    _drawStar(
        canvas,
        Offset(centre.dx, centre.dy - r * 0.58),
        size.width * 0.022,
        accent);
  }

  /// Paints a single word/string along an arc. Characters are rotated
  /// so they sit upright relative to the arc.
  void _drawCurvedText(
    Canvas canvas,
    String text,
    Offset centre,
    double radius, {
    required double startAngle,
    required double arcSweep,
    required TextStyle style,
    required bool above,
  }) {
    if (text.isEmpty) return;
    // Measure each character's width so we distribute them along the arc.
    final chars = text.split('');
    final painters = [
      for (final c in chars)
        TextPainter(
          text: TextSpan(text: c, style: style),
          textDirection: TextDirection.ltr,
        )..layout()
    ];
    final totalWidth = painters.fold<double>(0, (a, p) => a + p.width);
    // Angular width of the string along the arc.
    final stringArc = (totalWidth / radius).clamp(0.0, arcSweep);
    // Start at [startAngle] - half the stringArc if "above"; different
    // direction if "below".
    final dir = above ? -1 : 1;
    var angle = startAngle - dir * stringArc / 2;

    for (final p in painters) {
      final charArc = (p.width / radius);
      angle += dir * charArc / 2;
      final cx = centre.dx + radius * math.cos(angle);
      final cy = centre.dy + radius * math.sin(angle);
      final rotation =
          angle + (above ? math.pi / 2 : -math.pi / 2);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rotation);
      p.paint(canvas, Offset(-p.width / 2, -p.height / 2));
      canvas.restore();
      angle += dir * charArc / 2;
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color colour) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerAngle = -math.pi / 2 + i * (2 * math.pi / 5);
      final innerAngle = outerAngle + math.pi / 5;
      final outer = Offset(
        c.dx + r * math.cos(outerAngle),
        c.dy + r * math.sin(outerAngle),
      );
      final inner = Offset(
        c.dx + r * 0.45 * math.cos(innerAngle),
        c.dy + r * 0.45 * math.sin(innerAngle),
      );
      if (i == 0) path.moveTo(outer.dx, outer.dy);
      else path.lineTo(outer.dx, outer.dy);
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = colour.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(covariant _StampPainter old) =>
      old.destination != destination ||
      old.flag != flag ||
      old.dateLabel != dateLabel ||
      old.serial != serial ||
      old.accent != accent;
}

// ─────────────────────────────────────────────────────────────
//  STAMP ACCENT DERIVER
//
//  Choose an accent colour per-destination so a user's stamp shelf
//  reads as a colourful collection, not 20 lime discs. Deterministic
//  from the destination name so the same place always stamps the
//  same colour.
// ─────────────────────────────────────────────────────────────

Color stampAccentFor(String destination) {
  if (destination.isEmpty) return TSColors.lime;
  const palette = [
    TSColors.lime,
    TSColors.purple,
    TSColors.gold,
    TSColors.teal,
    TSColors.pink,
    TSColors.orange,
    TSColors.blue,
  ];
  final hash = destination.codeUnits.fold<int>(0, (a, c) => a + c);
  return palette[hash % palette.length];
}
