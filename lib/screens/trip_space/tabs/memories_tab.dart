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
import '../../../widgets/trip_recap_card.dart';
import '../../../widgets/widgets.dart';
import '../kudos_sheet.dart';
import '../recap_sheet.dart';

/// Completed-trip view. Top-billed: the **Trip Recap card** — a
/// Stories-sized shareable summary of the trip. Below that: CTAs to
/// rate the destination and send kudos to the squad.
///
/// `stampMode: true` renders the Passport Stamp framing used on the
/// "stamp" tab (same completed-trip data, different top line).
class MemoriesTab extends ConsumerStatefulWidget {
  const MemoriesTab({super.key, required this.trip, this.stampMode = false});
  final Trip trip;
  final bool stampMode;

  @override
  ConsumerState<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends ConsumerState<MemoriesTab> {
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    // Pre-completion states show a locked teaser instead of the recap,
    // matching the Spotify Wrapped "you gotta wait" energy. We check
    // the effective status so a trip whose end_date has passed auto-
    // unlocks without needing a server-side status bump.
    if (trip.effectiveStatus != TripStatus.completed) {
      return _LockedRecap(trip: trip);
    }
    final dest = trip.selectedDestination ?? trip.name;
    final flag = trip.selectedFlag ?? '✈️';
    final days = _days(trip);
    final dates = _fmtDates(trip);
    final squadEmojis =
        trip.squadMembers.map((m) => m.emoji ?? '😎').toList();
    final accent = _accentFor(trip.vibes ?? const []);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      children: [
        // Top line
        Center(
          child: Text(
            widget.stampMode ? '🎟️ passport stamp' : '📸 trip wrapped',
            style: TSTextStyles.heading(size: 20, color: TSColors.lime),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            widget.stampMode
                ? '$flag $dest — earned'
                : trip.mode == TripMode.solo
                    ? 'share the trip you made happen'
                    : 'share the squad\'s win',
            style: TSTextStyles.caption(color: TSColors.muted),
          ),
        ),
        const SizedBox(height: 20),

        // The card — exported to PNG via RepaintBoundary. On iPad
        // (wide), bump the on-screen width so the recap has presence;
        // share-as-image gets a higher-res export too.
        Builder(builder: (ctx) {
          final isWide = MediaQuery.of(ctx).size.width >= 700;
          return Center(
            child: RepaintBoundary(
              key: _cardKey,
              child: TripRecapCard(
                destination: dest,
                flag: flag,
                tripName: trip.name,
                dates: dates,
                days: days,
                squadEmojis: squadEmojis,
                accent: accent,
                archetype: _archetypeFor(trip),
                width: isWide ? 420 : 300,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06);
        }),

        const SizedBox(height: 24),

        // Share path — text + URL (universal) and card-as-image.
        Builder(builder: (btnCtx) => TSButton(
              label: '↗ share the trip',
              onTap: () => _shareLink(btnCtx, trip, dest),
            )),
        const SizedBox(height: 10),
        Builder(builder: (btnCtx) => TSButton(
              label: '📷 share as card',
              variant: TSButtonVariant.outline,
              onTap: () => _shareCard(btnCtx, trip, dest),
            )),

        const SizedBox(height: 24),

        const _SectionLabel(label: 'close out the trip'),
        const SizedBox(height: 10),
        TSButton(
          label: '⭐ rate this trip',
          variant: TSButtonVariant.ghost,
          onTap: () {
            TSHaptics.ctaTap();
            RecapSheet.show(context, trip);
          },
        ),
        // Kudos doesn't apply on a solo trip — there's no one else
        // in the squad to send them to.
        if (trip.mode != TripMode.solo) ...[
          const SizedBox(height: 10),
          TSButton(
            label: '🏆 give your squad kudos',
            variant: TSButtonVariant.ghost,
            onTap: () {
              TSHaptics.ctaTap();
              KudosSheet.show(context, trip);
            },
          ),
        ],
      ],
    );
  }

  // ── Share: text + URL ──────────────────────────────────────
  Future<void> _shareLink(
      BuildContext btnCtx, Trip trip, String dest) async {
    TSHaptics.ctaCommit();
    final url =
        'https://gettripsquad.com/trip/${trip.inviteToken ?? trip.id}';
    final text =
        'we did it — $dest ✈️🎉\nplanned with tripsquad: $url';
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
      debugPrint('recap link share failed: $e');
      try {
        await Clipboard.setData(ClipboardData(text: url));
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

  // ── Share: card as image ───────────────────────────────────
  Future<void> _shareCard(
      BuildContext btnCtx, Trip trip, String dest) async {
    TSHaptics.ctaCommit();
    final url =
        'https://gettripsquad.com/trip/${trip.inviteToken ?? trip.id}';
    final text = 'we did it — $dest ✈️🎉 · planned with tripsquad\n$url';
    Rect? origin;
    try {
      final box = btnCtx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}

    String? imagePath;
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final f = await File('${dir.path}/tripsquad-recap-${trip.id}.png')
              .writeAsBytes(bytes.buffer.asUint8List());
          imagePath = f.path;
        }
      }
    } catch (e) {
      debugPrint('recap card export failed: $e');
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
      debugPrint('recap card share failed: $e');
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

  // ── Helpers ───────────────────────────────────────────────

  int _days(Trip t) {
    if (t.startDate == null || t.endDate == null) {
      return t.durationDays ?? 1;
    }
    return t.endDate!.difference(t.startDate!).inDays + 1;
  }

  String _fmtDates(Trip t) {
    if (t.startDate == null) return 'dates tbd';
    final s = t.startDate!;
    final e = t.endDate ?? s;
    const months = [
      '', 'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    if (s.year == e.year && s.month == e.month) {
      return '${months[s.month]} ${s.day} – ${e.day}, ${s.year}';
    }
    return '${months[s.month]} ${s.day} – ${months[e.month]} ${e.day}, ${s.year}';
  }

  /// Picks an accent colour based on the dominant vibe. Keeps the
  /// recap card tonally matched to how the trip felt.
  Color _accentFor(List<String> vibes) {
    if (vibes.isEmpty) return TSColors.lime;
    final v = vibes.first.toLowerCase();
    if (v.contains('party')) return TSColors.gold;
    if (v.contains('culture') || v.contains('food')) return TSColors.purple;
    if (v.contains('wellness') || v.contains('nature')) return TSColors.teal;
    if (v.contains('city') || v.contains('adventure')) return TSColors.lime;
    if (v.contains('beach')) return TSColors.gold;
    return TSColors.lime;
  }

  /// Very-lightweight archetype fallback derived from the trip's vibes.
  /// The real feature (Scout-generated archetypes via an edge function
  /// after 3+ trips together) is deferred to v1.5 per the redesign.
  String? _archetypeFor(Trip t) {
    final v = (t.vibes ?? const <String>[]).map((s) => s.toLowerCase()).toList();
    if (v.isEmpty) return null;
    if (v.contains('party')) return 'the late-night crew';
    if (v.contains('culture')) return 'the culture vultures';
    if (v.contains('food')) return 'the flavour hunters';
    if (v.contains('beach')) return 'the shoreline squad';
    if (v.contains('adventure')) return 'the no-plans crew';
    if (v.contains('wellness')) return 'the slow mornings club';
    if (v.contains('nature')) return 'the outdoors crew';
    if (v.contains('city')) return 'the streetside squad';
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        label.toUpperCase(),
        style: TSTextStyles.label(color: TSColors.muted, size: 10),
      ),
    );
  }
}

/// Pre-completion recap tab. Shows a "sealed" card with a gen-Z teaser
/// line + countdown. The real recap unlocks when `trip.status` flips
/// to `completed` (on trip end_date).
///
/// Rationale — anticipation > preview (Spotify Wrapped principle).
/// Letting users peek at the recap early ruins the share moment.
class _LockedRecap extends StatelessWidget {
  const _LockedRecap({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final daysUntilEnd = _daysUntilEnd(trip);
    final (line, sub) = _copyForState(trip, daysUntilEnd);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
      children: [
        // Sealed envelope visual
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient glow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TSColors.limeDim(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Envelope / seal
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TSColors.s1,
                  shape: BoxShape.circle,
                  border: Border.all(color: TSColors.lime, width: 1.4),
                ),
                child: const Text('🔒', style: TextStyle(fontSize: 38)),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.03, 1.03),
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Main line — leaning into Scout's voice
        Text(
          line,
          textAlign: TextAlign.center,
          style: TSTextStyles.heading(size: 26, color: TSColors.text),
        ),

        const SizedBox(height: 10),

        Text(
          sub,
          textAlign: TextAlign.center,
          style: TSTextStyles.body(size: 14, color: TSColors.muted),
        ),

        const SizedBox(height: 24),

        // Countdown pill (only if we know the end date)
        if (daysUntilEnd != null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: TSColors.s2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TSColors.limeDim(0.3)),
              ),
              child: Text(
                _countdownText(daysUntilEnd),
                style: TSTextStyles.title(size: 13, color: TSColors.lime),
              ),
            ),
          ),

        const SizedBox(height: 40),

        // Scout signature — tiny attribution
        Center(
          child: Text('— scout is sealing it 🧭',
              style: TSTextStyles.caption(color: TSColors.muted2)),
        ),
      ],
    );
  }

  /// Gen-Z tone, context-aware. Varies with trip phase so it doesn't
  /// read the same on every tab.
  (String, String) _copyForState(Trip t, int? daysUntilEnd) {
    final status = t.status;

    if (status == TripStatus.live) {
      // Trip's happening right now. Hype + tease.
      return (
        'sealed until you\'re home.',
        "too real to spoil 🌶️ scout's writing the squad's archetype as it happens. come back after you touch down.",
      );
    }

    if (status == TripStatus.planning || status == TripStatus.revealed) {
      if (daysUntilEnd != null && daysUntilEnd <= 14) {
        return (
          'spoilers, besties 🌶️',
          'the recap drops when you\'re home. till then — manifest it.',
        );
      }
      return (
        'not yet. y\'all haven\'t even gone 😭',
        "scout seals this when the trip ends. that's called patience, friend.",
      );
    }

    return (
      'this opens when the trip ends.',
      "scout's got a whole archetype cooking. make it happen first.",
    );
  }

  String _countdownText(int daysUntilEnd) {
    if (daysUntilEnd <= 0) return 'unlocks when you\'re back ✦';
    if (daysUntilEnd == 1) return 'drops in 1 day';
    if (daysUntilEnd <= 7) return 'drops in $daysUntilEnd days';
    final weeks = (daysUntilEnd / 7).round();
    if (weeks == 1) return 'drops in ~1 week';
    return 'drops in ~$weeks weeks';
  }

  int? _daysUntilEnd(Trip t) {
    final end = t.endDate ?? t.startDate;
    if (end == null) return null;
    final now = DateTime.now();
    return end.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
