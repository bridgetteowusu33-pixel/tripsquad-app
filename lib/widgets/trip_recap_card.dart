import 'package:flutter/material.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  TRIP RECAP CARD  ("Trip Wrapped")
//
//  Stories-sized 9:16 card summarising a completed trip. Meant to
//  be screenshot or exported-as-PNG and dropped into Instagram
//  Stories / WhatsApp / iMessage.
//
//  Carries: destination + flag, trip name, date range, days,
//  squad emoji row, a Scout-generated one-line archetype
//  ("The Late Starters"), and a dominant colour band at the top
//  that tints the card to the trip's mood (lime = adventurous,
//  purple = culture, gold = party, teal = wellness).
// ─────────────────────────────────────────────────────────────

class TripRecapCard extends StatelessWidget {
  const TripRecapCard({
    super.key,
    required this.destination,
    required this.flag,
    required this.tripName,
    required this.dates,
    required this.days,
    required this.squadEmojis,
    this.archetype,
    this.accent = TSColors.lime,
    this.width,
  });

  final String destination;
  final String flag;
  final String tripName;
  final String dates;
  final int days;
  final List<String> squadEmojis;

  /// Scout-generated squad label, e.g. "the late starters" or "the
  /// culture vultures". Optional — if null, a generic line shows.
  final String? archetype;

  /// Primary accent colour for the top band + highlights. Defaults
  /// to lime; pass purple for culture, gold for party, teal for
  /// wellness per the vibe palette.
  final Color accent;

  /// Explicit width override; defaults to 320pt.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 320.0;
    final h = w * 16 / 9; // stories 9:16
    // No AspectRatio wrapper — it was stretching the card to the
    // parent's cross-axis on iPad and inside scroll views, blowing
    // the card up to full screen width × 16/9. Same bug pattern as
    // BoardingPassCard. The SizedBox is the source of truth.
    return Center(
      child: SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          painter: _TripRecapPainter(
            destination: destination,
            flag: flag,
            tripName: tripName,
            dates: dates,
            days: days,
            squadEmojis: squadEmojis,
            archetype: archetype,
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _TripRecapPainter extends CustomPainter {
  _TripRecapPainter({
    required this.destination,
    required this.flag,
    required this.tripName,
    required this.dates,
    required this.days,
    required this.squadEmojis,
    required this.archetype,
    required this.accent,
  });

  final String destination;
  final String flag;
  final String tripName;
  final String dates;
  final int days;
  final List<String> squadEmojis;
  final String? archetype;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = Radius.circular(w * 0.06);

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), radius),
      Paint()..color = TSColors.bg,
    );

    // Top band — accent wash, gradient to transparent.
    final band = Rect.fromLTWH(0, 0, w, h * 0.38);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndCorners(
      band,
      topLeft: radius,
      topRight: radius,
    ));
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withOpacity(0.25),
          accent.withOpacity(0.04),
        ],
      ).createShader(band);
    canvas.drawRect(band, bandPaint);
    canvas.restore();

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, w - 2, h - 2), radius),
      Paint()
        ..color = accent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final pad = w * 0.07;
    double y = h * 0.05;

    // Masthead
    _draw(
      canvas,
      'TRIP WRAPPED',
      Offset(pad, y),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.038,
        fontWeight: FontWeight.w800,
        letterSpacing: w * 0.006,
        color: accent,
      ),
    );
    _draw(
      canvas,
      'TRIPSQUAD',
      Offset(w - pad, y),
      anchor: _Anchor.right,
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.028,
        fontWeight: FontWeight.w700,
        letterSpacing: w * 0.006,
        color: TSColors.muted2,
      ),
    );
    y += w * 0.06;

    // Flag
    _draw(canvas, flag, Offset(pad, y),
        style: TextStyle(fontSize: w * 0.26, height: 1));
    y += w * 0.26 + w * 0.02;

    // Destination (big)
    _draw(
      canvas,
      destination,
      Offset(pad, y),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.16,
        fontWeight: FontWeight.w800,
        letterSpacing: -w * 0.004,
        height: 0.95,
        color: TSColors.text,
      ),
    );
    y += w * 0.17;

    // Dates + trip name
    _draw(
      canvas,
      dates,
      Offset(pad, y),
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: w * 0.036,
        color: TSColors.text2,
      ),
    );
    y += w * 0.055;
    _draw(
      canvas,
      tripName,
      Offset(pad, y),
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: w * 0.032,
        color: TSColors.muted,
        fontStyle: FontStyle.italic,
      ),
    );
    y += w * 0.09;

    // Divider
    canvas.drawLine(
      Offset(pad, y),
      Offset(w - pad, y),
      Paint()
        ..color = accent.withOpacity(0.5)
        ..strokeWidth = 1,
    );
    y += w * 0.045;

    // Big number block: DAYS
    _draw(
      canvas,
      '$days',
      Offset(pad, y),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.24,
        fontWeight: FontWeight.w800,
        height: 0.9,
        color: accent,
      ),
    );
    // "days away" to the right of the number
    _draw(
      canvas,
      days == 1 ? 'day away' : 'days away',
      Offset(pad + w * 0.3, y + w * 0.12),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.05,
        fontWeight: FontWeight.w700,
        color: TSColors.text,
      ),
    );
    y += w * 0.28;

    // Squad section
    _draw(
      canvas,
      'SQUAD',
      Offset(pad, y),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.028,
        fontWeight: FontWeight.w700,
        letterSpacing: w * 0.006,
        color: TSColors.muted,
      ),
    );
    y += w * 0.04;

    // Squad emojis in a row
    final emojiSize = w * 0.07;
    final maxEmojis = 8;
    final shown = squadEmojis.take(maxEmojis).toList();
    for (var i = 0; i < shown.length; i++) {
      final x = pad + i * (emojiSize * 1.25);
      _draw(
        canvas,
        shown[i],
        Offset(x, y),
        style: TextStyle(fontSize: emojiSize),
      );
    }
    if (squadEmojis.length > maxEmojis) {
      _draw(
        canvas,
        '+${squadEmojis.length - maxEmojis}',
        Offset(pad + shown.length * (emojiSize * 1.25), y + emojiSize * 0.2),
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: emojiSize * 0.5,
          color: TSColors.muted,
        ),
      );
    }
    y += emojiSize + w * 0.06;

    // Archetype line ("the late starters" etc.)
    final line = archetype ?? 'a trip the squad won\'t forget';
    _draw(
      canvas,
      '"$line"',
      Offset(pad, y),
      maxWidth: w - pad * 2,
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.048,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: TSColors.text,
        height: 1.2,
      ),
    );

    // Footer
    final footerY = h - w * 0.07;
    _draw(
      canvas,
      'gettripsquad.com',
      Offset(pad, footerY),
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: w * 0.03,
        color: TSColors.muted,
      ),
    );
    _draw(
      canvas,
      '— scout 🧭',
      Offset(w - pad, footerY),
      anchor: _Anchor.right,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: w * 0.03,
        color: accent,
      ),
    );
  }

  void _draw(
    Canvas canvas,
    String text,
    Offset offset, {
    required TextStyle style,
    _Anchor anchor = _Anchor.left,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxWidth == null ? 1 : null,
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final dx = switch (anchor) {
      _Anchor.left => offset.dx,
      _Anchor.right => offset.dx - painter.width,
      _Anchor.center => offset.dx - painter.width / 2,
    };
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _TripRecapPainter old) =>
      old.destination != destination ||
      old.flag != flag ||
      old.tripName != tripName ||
      old.dates != dates ||
      old.days != days ||
      old.squadEmojis.length != squadEmojis.length ||
      old.archetype != archetype ||
      old.accent != accent;
}

enum _Anchor { left, right, center }
