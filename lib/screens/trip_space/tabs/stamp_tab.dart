import 'dart:io' show File;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../widgets/passport_stamp.dart';
import '../../../widgets/widgets.dart';

/// Completed-trip Stamp tab. Renders the passport stamp, lets the user
/// share it as an image, and hints at the stamp shelf living in the Me
/// sheet.
///
/// Rendered inside Trip Space's phase-aware tab set when the trip is
/// `completed`. For non-completed trips this tab doesn't appear (see
/// `_tabsForStatus` in trip_space_screen.dart).
class StampTab extends ConsumerStatefulWidget {
  const StampTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<StampTab> createState() => _StampTabState();
}

class _StampTabState extends ConsumerState<StampTab> {
  final _stampKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final dest = trip.selectedDestination ?? trip.name;
    final flag = trip.selectedFlag ?? '🌍';
    final dateLabel = _fmtDateLabel(trip);
    final accent = stampAccentFor(dest);
    final serial = _serialFor(trip);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
      children: [
        Center(
          child: Text('🎟️ STAMP EARNED',
              style: TSTextStyles.label(color: accent, size: 10)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('welcome to the collection',
              style: TSTextStyles.caption(color: TSColors.muted)),
        ),
        const SizedBox(height: 32),

        // The stamp, shareable. Wrapped in a RepaintBoundary so we
        // can export a clean PNG (including the scene's dark
        // background so the stamp reads on any messenger).
        Center(
          child: RepaintBoundary(
            key: _stampKey,
            child: Container(
              color: TSColors.bg,
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                PassportStamp(
                  destination: dest,
                  flag: flag,
                  dateLabel: dateLabel,
                  serial: serial,
                  accent: accent,
                  size: 260,
                ),
                const SizedBox(height: 18),
                Text('TRIPSQUAD PASSPORT',
                    style: TSTextStyles.label(
                        color: TSColors.muted, size: 10)),
              ]),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.86, 0.86),
              duration: 700.ms,
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 32),

        // Share CTAs — same link/card split pattern
        Builder(builder: (btnCtx) => TSButton(
              label: '↗ share the stamp',
              onTap: () => _shareLink(btnCtx, trip, dest),
            )),
        const SizedBox(height: 10),
        Builder(builder: (btnCtx) => TSButton(
              label: '📷 share as image',
              variant: TSButtonVariant.outline,
              onTap: () => _shareImage(btnCtx, trip, dest),
            )),

        const SizedBox(height: 28),

        // Stamp-shelf hint — points at Me sheet where the full
        // collection lives.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TSColors.s2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TSColors.border),
          ),
          child: Row(children: [
            const Text('📘', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('your passport is filling up',
                      style: TSTextStyles.body(size: 14)),
                  Text('tap your avatar to see the shelf',
                      style: TSTextStyles.caption(color: TSColors.muted)),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Serial derivation ────────────────────────────────────
  /// Deterministic serial line from the trip id + completion year.
  /// Format: "#XXX · YYYY". Three-digit number derived from trip_id
  /// hash so it feels unique without a DB column.
  String _serialFor(Trip t) {
    final year = (t.endDate ?? t.startDate ?? t.createdAt ?? DateTime.now()).year;
    final hash = t.id.codeUnits.fold<int>(0, (a, c) => a + c);
    final num = (hash % 999) + 1;
    return '#${num.toString().padLeft(3, '0')} · $year';
  }

  String _fmtDateLabel(Trip t) {
    final d = t.endDate ?? t.startDate;
    if (d == null) return '';
    const months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[d.month]} · ${d.year}';
  }

  // ── Share: text + URL ────────────────────────────────────
  Future<void> _shareLink(
      BuildContext btnCtx, Trip trip, String dest) async {
    TSHaptics.ctaCommit();
    final text =
        'stamped 🎟️ $dest · the squad touched down.\nhttps://gettripsquad.com';
    Rect? origin;
    try {
      final box = btnCtx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}
    try {
      await Share.share(text,
          subject: 'tripsquad', sharePositionOrigin: origin);
    } catch (e) {
      debugPrint('stamp link share failed: $e');
      try {
        await Clipboard.setData(const ClipboardData(
            text: 'https://gettripsquad.com'));
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t open share — link copied instead',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Share: stamp as image ────────────────────────────────
  Future<void> _shareImage(
      BuildContext btnCtx, Trip trip, String dest) async {
    TSHaptics.ctaCommit();
    final text = 'stamped 🎟️ $dest · tripsquad.com';
    Rect? origin;
    try {
      final box = btnCtx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}

    String? imagePath;
    try {
      final boundary = _stampKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final f = await File('${dir.path}/tripsquad-stamp-${trip.id}.png')
              .writeAsBytes(bytes.buffer.asUint8List());
          imagePath = f.path;
        }
      }
    } catch (e) {
      debugPrint('stamp image export failed: $e');
    }

    try {
      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: text,
          subject: 'tripsquad',
          sharePositionOrigin: origin,
        );
      } else {
        await Share.share(text,
            subject: 'tripsquad', sharePositionOrigin: origin);
      }
    } catch (e) {
      debugPrint('stamp image share failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t open share — try the link button',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
