import 'package:flutter/material.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  BOARDING PASS CARD
//
//  The shareable invite/reveal artifact. Structured like a real
//  boarding pass so it reads as a travel moment, not an ad.
//
//  Dimensions: intrinsic aspect of 9:16 so the same component
//  renders on-screen at any size and exports cleanly to 1080×1920
//  via `RepaintBoundary.toImage`.
//
//  Per the UX redesign §18 — the purple→lime gradient is Scout's.
//  This card uses it sparingly: one hairline divider + the QR block
//  frame. The rest is lime + near-black.
// ─────────────────────────────────────────────────────────────

class BoardingPassCard extends StatelessWidget {
  const BoardingPassCard({
    super.key,
    required this.kind,
    required this.destination,
    required this.flag,
    required this.hostTag,
    required this.dates,
    required this.squadCount,
    this.tripName,
    this.departure,
    this.inviteUrl,
    this.width,
  });

  /// Invite card (pre-vote, soft) vs Reveal card (destination locked).
  final BoardingPassKind kind;

  /// Display destination, e.g. "LISBON" (will be uppercased).
  final String destination;

  /// Flag emoji, e.g. "🇵🇹".
  final String flag;

  /// Host's @tag (without the @).
  final String hostTag;

  /// Formatted date line, e.g. "jul 12 – 19, 2026" or "jul 12 (flexible)".
  final String dates;

  /// How many squad members total (including host).
  final int squadCount;

  /// Trip name like "Lisbon Girls' Week" — shown in small caps on invite.
  final String? tripName;

  /// Days-until-departure text, e.g. "7 days from now". Reveal-only.
  final String? departure;

  /// Optional full invite URL. Rendered as readable text in the footer
  /// so the link survives when the card image is shared to apps like
  /// WhatsApp / iMessage that often strip the accompanying text body.
  final String? inviteUrl;

  /// Explicit width override; defaults to 360pt.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 360.0;
    final h = w * 16 / 9; // Stories-native 9:16
    // No AspectRatio wrapper — on iPad that stretched the card to fill
    // the parent column and blew the pass up to ~1500pt tall. The
    // SizedBox is the source of truth.
    return Center(
      child: SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          painter: _BoardingPassPainter(
            kind: kind,
            destination: destination,
            flag: flag,
            hostTag: hostTag,
            dates: dates,
            squadCount: squadCount,
            tripName: tripName,
            departure: departure,
            inviteUrl: inviteUrl,
          ),
        ),
      ),
    );
  }
}

enum BoardingPassKind { invite, reveal }

class _BoardingPassPainter extends CustomPainter {
  _BoardingPassPainter({
    required this.kind,
    required this.destination,
    required this.flag,
    required this.hostTag,
    required this.dates,
    required this.squadCount,
    required this.tripName,
    required this.departure,
    required this.inviteUrl,
  });

  final BoardingPassKind kind;
  final String destination;
  final String flag;
  final String hostTag;
  final String dates;
  final int squadCount;
  final String? tripName;
  final String? departure;
  final String? inviteUrl;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body — near-black with a destination-tint wash at the top.
    final body = Paint()..color = TSColors.bg;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.06),
      ),
      body,
    );

    // Soft destination-tint wash top 45%.
    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TSColors.limeDim(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.06),
      ),
      wash,
    );

    // Top border stroke (lime at low opacity)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, w - 2, h - 2),
        Radius.circular(w * 0.06 - 1),
      ),
      Paint()
        ..color = TSColors.limeDim(0.25)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    final pad = w * 0.07;
    double cursorY = h * 0.05;

    // ── Masthead: TRIPSQUAD ────────────────────────────────
    _drawText(
      canvas,
      'TRIPSQUAD',
      Offset(pad, cursorY),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.045,
        fontWeight: FontWeight.w800,
        letterSpacing: w * 0.006,
        color: TSColors.lime,
      ),
    );

    // Kind badge, right-aligned
    final kindText = kind == BoardingPassKind.invite
        ? 'INVITATION'
        : 'BOARDING PASS';
    _drawText(
      canvas,
      kindText,
      Offset(w - pad, cursorY),
      align: TextAlign.right,
      anchor: _Anchor.right,
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.03,
        fontWeight: FontWeight.w700,
        letterSpacing: w * 0.006,
        color: TSColors.muted2,
      ),
    );

    cursorY += w * 0.08;

    // ── Horizontal hairline divider (purple→lime gradient) ─
    _drawGradientLine(canvas, pad, cursorY, w - 2 * pad);
    cursorY += w * 0.045;

    // ── Flag huge ──────────────────────────────────────────
    final flagSize = w * 0.26;
    _drawText(
      canvas,
      flag,
      Offset(pad, cursorY),
      style: TextStyle(fontSize: flagSize, height: 1),
    );

    // ── Destination name — big, auto-shrinks for long names so the
    // text never overlaps the card edges.
    cursorY += flagSize + w * 0.02;
    final maxDestWidth = w - 2 * pad;
    double destFontSize = w * 0.18;
    TextPainter destPainter() => TextPainter(
          text: TextSpan(
            text: destination.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: destFontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -w * 0.004,
              color: TSColors.text,
              height: 0.95,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
    var painter = destPainter();
    // Shrink until it fits, floor at 40% of the starting size.
    while (painter.width > maxDestWidth && destFontSize > w * 0.07) {
      destFontSize -= w * 0.005;
      painter = destPainter();
    }
    painter.paint(canvas, Offset(pad, cursorY));

    cursorY += destFontSize + w * 0.02;

    // ── Dates / flexible ──────────────────────────────────
    _drawText(
      canvas,
      dates,
      Offset(pad, cursorY),
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: w * 0.04,
        color: TSColors.text2,
      ),
    );

    cursorY += w * 0.09;

    // ── Divider ────────────────────────────────────────────
    _drawGradientLine(canvas, pad, cursorY, w - 2 * pad);
    cursorY += w * 0.05;

    // ── Passengers section ────────────────────────────────
    _drawText(
      canvas,
      'PASSENGERS',
      Offset(pad, cursorY),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.028,
        fontWeight: FontWeight.w700,
        letterSpacing: w * 0.006,
        color: TSColors.muted,
      ),
    );
    cursorY += w * 0.04;

    // Host @tag + squad count
    _drawText(
      canvas,
      '@$hostTag',
      Offset(pad, cursorY),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.055,
        fontWeight: FontWeight.w700,
        color: TSColors.lime,
      ),
    );
    cursorY += w * 0.075;

    final rest = squadCount - 1;
    if (rest > 0) {
      _drawText(
        canvas,
        rest == 1 ? '+ 1 more joining' : '+ $rest more joining',
        Offset(pad, cursorY),
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: w * 0.035,
          color: TSColors.text2,
        ),
      );
    }

    cursorY += w * 0.08;
    _drawGradientLine(canvas, pad, cursorY, w - 2 * pad);
    cursorY += w * 0.05;

    // ── Trip name or departure line ──────────────────────
    if (kind == BoardingPassKind.reveal && departure != null) {
      _drawText(
        canvas,
        'DEPARTURE',
        Offset(pad, cursorY),
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: w * 0.028,
          fontWeight: FontWeight.w700,
          letterSpacing: w * 0.006,
          color: TSColors.muted,
        ),
      );
      cursorY += w * 0.04;
      _drawText(
        canvas,
        departure!,
        Offset(pad, cursorY),
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: w * 0.06,
          fontWeight: FontWeight.w800,
          color: TSColors.text,
        ),
      );
    } else if (kind == BoardingPassKind.invite && tripName != null) {
      _drawText(
        canvas,
        'TRIP',
        Offset(pad, cursorY),
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: w * 0.028,
          fontWeight: FontWeight.w700,
          letterSpacing: w * 0.006,
          color: TSColors.muted,
        ),
      );
      cursorY += w * 0.04;
      _drawText(
        canvas,
        tripName!,
        Offset(pad, cursorY),
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: w * 0.05,
          fontWeight: FontWeight.w700,
          color: TSColors.text,
        ),
      );
    }

    // ── Footer: brand wordmark, invite URL, QR ──
    // The full invite URL is painted on the card itself so the link
    // survives even when the image is shared to apps (WhatsApp,
    // iMessage) that strip the accompanying text body.
    final footerY = h - w * 0.08;
    final qrSize = w * 0.13;
    final qrRect = Rect.fromLTWH(
      w - pad - qrSize,
      footerY - qrSize * 0.6,
      qrSize,
      qrSize,
    );
    _drawQrPlaceholder(canvas, qrRect);

    // Brand wordmark (top line of footer)
    _drawText(
      canvas,
      'TRIPSQUAD',
      Offset(pad, footerY - w * 0.05),
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: w * 0.03,
        fontWeight: FontWeight.w800,
        letterSpacing: w * 0.004,
        color: TSColors.muted,
      ),
    );

    // Invite URL — shown verbatim so it's readable (and typeable) from
    // a screenshot. Truncated to the portion right of the domain so the
    // line stays on one row.
    final urlToShow = _displayableInviteUrl();
    _drawText(
      canvas,
      urlToShow,
      Offset(pad, footerY),
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: w * 0.028,
        color: TSColors.text2,
      ),
    );
  }

  /// Returns the invite URL shortened to fit the footer. Defaults to the
  /// brand URL when no invite URL was passed (e.g., Reveal card).
  String _displayableInviteUrl() {
    final raw = inviteUrl ?? 'https://gettripsquad.com';
    // Strip scheme for a cleaner rendered URL.
    return raw
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
  }

  void _drawGradientLine(Canvas canvas, double x, double y, double len) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [TSColors.purple, TSColors.lime],
      ).createShader(Rect.fromLTWH(x, y, len, 1))
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, y), Offset(x + len, y), paint);
  }

  void _drawQrPlaceholder(Canvas canvas, Rect rect) {
    final bg = Paint()..color = TSColors.text;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      bg,
    );
    final cell = rect.width / 9;
    final dot = Paint()..color = TSColors.bg;
    // Deterministic "noise" — not a real QR but reads as one at thumbnail size.
    const pattern = [
      0x1E7, 0x125, 0x1E7, 0x000, 0x0AB,
      0x045, 0x1DE, 0x022, 0x1E7, 0x125, 0x0AB,
    ];
    for (var r = 0; r < 9; r++) {
      final row = pattern[r % pattern.length];
      for (var c = 0; c < 9; c++) {
        if ((row >> c) & 1 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              rect.left + c * cell + cell * 0.15,
              rect.top + r * cell + cell * 0.15,
              cell * 0.7,
              cell * 0.7,
            ),
            dot,
          );
        }
      }
    }
    // Corner finders — classic QR look.
    for (final corner in [
      Offset(rect.left, rect.top),
      Offset(rect.right - cell * 2.5, rect.top),
      Offset(rect.left, rect.bottom - cell * 2.5),
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(corner.dx, corner.dy, cell * 2.5, cell * 2.5),
        dot,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          corner.dx + cell * 0.5,
          corner.dy + cell * 0.5,
          cell * 1.5,
          cell * 1.5,
        ),
        bg,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          corner.dx + cell,
          corner.dy + cell,
          cell * 0.5,
          cell * 0.5,
        ),
        dot,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required TextStyle style,
    TextAlign align = TextAlign.left,
    _Anchor anchor = _Anchor.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (anchor) {
      _Anchor.left => offset.dx,
      _Anchor.right => offset.dx - painter.width,
      _Anchor.center => offset.dx - painter.width / 2,
    };
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _BoardingPassPainter old) =>
      old.kind != kind ||
      old.destination != destination ||
      old.flag != flag ||
      old.hostTag != hostTag ||
      old.dates != dates ||
      old.squadCount != squadCount ||
      old.tripName != tripName ||
      old.departure != departure ||
      old.inviteUrl != inviteUrl;
}

enum _Anchor { left, right, center }
