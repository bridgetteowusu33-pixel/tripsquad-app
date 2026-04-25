import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'passport_stamp.dart';
import 'trip_recap_card.dart';

// ─────────────────────────────────────────────────────────────
//  TRIP WRAP OVERLAY
//
//  Fullscreen ceremony the first time a user opens a trip after
//  it flips to `completed`. Mirror of the reveal moment — the
//  trip ends with a small celebration rather than silently
//  turning into a "completed" pill.
//
//  Structure:
//   - "TRIP WRAPPED 🎉" header
//   - Procedural passport stamp (rising + haptic pulse)
//   - Trip Recap card (Stories-sized summary)
//   - "done" CTA — close
//
//  Triggered once per trip per device via `seen_wrap_ids` in
//  SharedPreferences (see trip_space_screen.dart).
// ─────────────────────────────────────────────────────────────

class TripWrapOverlay extends ConsumerWidget {
  const TripWrapOverlay({super.key, required this.trip});
  final Trip trip;

  static Future<void> show(BuildContext context, Trip trip) {
    TSHaptics.revealBeat(3);
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => TripWrapOverlay(trip: trip),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dest = trip.selectedDestination ?? trip.name;
    final flag = trip.selectedFlag ?? '🌍';
    final dateLabel = _fmtDateLabel(trip);
    final accent = stampAccentFor(dest);
    final squad = ref.watch(squadStreamProvider(trip.id)).valueOrNull ??
        const <SquadMember>[];
    final squadEmojis = squad.map((m) => m.emoji ?? '😎').toList();
    final days = _daysBetween(trip);
    final dates = _fmtDates(trip);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: LayoutBuilder(builder: (context, constraints) {
            // Fixed chrome we must fit around the hero pieces:
            //   header block (label + tagline)   ≈ 42
            //   4× internal gaps                 ≈ 58
            //   done button + bottom margin       ≈ 56
            const fixedChrome = 42 + 58 + 56;
            final flex = (constraints.maxHeight - fixedChrome)
                .clamp(280.0, double.infinity);

            // Split the remaining height between stamp and card.
            // The card is the hero — gets the larger share. Clamps
            // keep both inside a tasteful range on iPhone SE at the
            // low end and iPad at the high end.
            final stampSize = (flex * 0.28).clamp(110.0, 180.0);
            final cardHeight = (flex * 0.72).clamp(320.0, 520.0);
            // Card is stories-ratio (9:16), so width derives from
            // height. Also cap width to the available horizontal so
            // narrow phones don't overflow.
            final maxCardWidth = constraints.maxWidth;
            final cardWidth =
                (cardHeight * 9 / 16).clamp(180.0, maxCardWidth);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('TRIP WRAPPED 🎉',
                        style: TSTextStyles.label(color: accent, size: 11))
                    .animate()
                    .fadeIn(duration: 360.ms),
                const SizedBox(height: 4),
                Text('one for the books',
                    style: TSTextStyles.caption(color: TSColors.muted)),
                const SizedBox(height: 16),
                PassportStamp(
                  destination: dest,
                  flag: flag,
                  dateLabel: dateLabel,
                  serial: _serialFor(trip),
                  accent: accent,
                  size: stampSize,
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 14),
                TripRecapCard(
                  destination: dest,
                  flag: flag,
                  tripName: trip.name,
                  dates: dates,
                  days: days,
                  squadEmojis: squadEmojis,
                  accent: accent,
                  width: cardWidth,
                )
                    .animate(delay: 320.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    TSHaptics.light();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: TSColors.s2,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: TSColors.border2),
                    ),
                    child: Text('done',
                        style: TSTextStyles.title(
                            size: 13, color: TSColors.text)),
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _serialFor(Trip t) {
    final year =
        (t.endDate ?? t.startDate ?? t.createdAt ?? DateTime.now()).year;
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

  int _daysBetween(Trip t) {
    if (t.startDate == null || t.endDate == null) return 0;
    return t.endDate!.difference(t.startDate!).inDays + 1;
  }

  String _fmtDates(Trip t) {
    final s = t.startDate;
    final e = t.endDate;
    if (s == null || e == null) return '';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (s.year == e.year && s.month == e.month) {
      return '${months[s.month]} ${s.day}–${e.day}, ${e.year}';
    }
    return '${months[s.month]} ${s.day} – ${months[e.month]} ${e.day}, ${e.year}';
  }
}
