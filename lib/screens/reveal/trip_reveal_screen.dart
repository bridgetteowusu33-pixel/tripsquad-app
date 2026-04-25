import 'dart:ui' as ui;
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/boarding_pass.dart';
import '../../widgets/reveal_cinematic.dart';
import '../../widgets/widgets.dart';

/// The destination reveal — plays a 4-second cinematic, then fades into
/// the Boarding Pass + share/view-trip CTAs.
///
/// Entered automatically by `TripSpaceScreen` when `trip.status`
/// transitions into `revealed`. Also reachable via `/trip/:id/reveal`.
class TripRevealScreen extends ConsumerStatefulWidget {
  const TripRevealScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<TripRevealScreen> createState() => _TripRevealScreenState();
}

class _TripRevealScreenState extends ConsumerState<TripRevealScreen> {
  final _cardKey = GlobalKey();
  bool _cinematicDone = false;
  bool _generatingItinerary = false;

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));

    return Scaffold(
      backgroundColor: TSColors.bg,
      body: SafeArea(
        child: tripAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: TSColors.lime),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(humanizeError(e), style: TSTextStyles.body()),
            ),
          ),
          data: (trip) => _body(context, trip),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Trip trip) {
    final dest = trip.selectedDestination ?? trip.name;
    final flag = trip.selectedFlag ?? '✈️';
    final squadEmojis = trip.squadMembers
        .map((m) => m.emoji ?? '😎')
        .take(8)
        .toList();

    return Stack(children: [
      // ── Cinematic (4.1s) → fades out on completion ───────────
      IgnorePointer(
        ignoring: _cinematicDone,
        child: AnimatedOpacity(
          opacity: _cinematicDone ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 500),
          child: RevealCinematic(
            destination: dest,
            flag: flag,
            dates: _fmtDates(trip),
            squadEmojis: squadEmojis,
            photoUrl: _hintPhotoFor(dest),
            onFinished: () {
              if (!mounted) return;
              setState(() => _cinematicDone = true);
            },
          ),
        ),
      ),

      // ── Post-cinematic content (boarding pass + CTAs) ──────
      IgnorePointer(
        ignoring: !_cinematicDone,
        child: AnimatedOpacity(
          opacity: _cinematicDone ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: _post(context, trip, dest, flag),
        ),
      ),

      // ── Top bar (close X + replay pill) ─────────────────────
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: TSColors.muted2, size: 22),
              onPressed: () {
                final nav = Navigator.of(context);
                if (nav.canPop()) {
                  nav.pop();
                } else {
                  context.go('/trip/${trip.id}/space');
                }
              },
            ),
            const Spacer(),
            if (_cinematicDone)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  TSHaptics.ctaTap();
                  setState(() => _cinematicDone = false);
                  // Force-recreate the cinematic by changing a key
                  // indirectly — simplest: toggle back to false,
                  // which replays via the cinematic's initState.
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('↻ replay',
                      style: TSTextStyles.label(
                          color: TSColors.muted, size: 10)),
                ),
              ),
          ]),
        ),
      ),
    ]);
  }

  Widget _post(BuildContext context, Trip trip, String dest, String flag) {
    final hostTag =
        ref.watch(currentProfileProvider).valueOrNull?.tag ?? 'host';
    final dates = _fmtDates(trip);
    final departure = _departureLabel(trip);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 16),
      child: TSResponsive.content(Column(children: [
        Text(dest,
                style: TSTextStyles.heading(size: 24, color: TSColors.lime))
            .animate()
            .fadeIn(duration: 500.ms),
        const SizedBox(height: 4),
        Text('your squad is going',
                style: TSTextStyles.caption(color: TSColors.muted))
            .animate(delay: 200.ms)
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 24),

        // Shareable Boarding Pass
        RepaintBoundary(
          key: _cardKey,
          child: BoardingPassCard(
            kind: BoardingPassKind.reveal,
            destination: dest,
            flag: flag,
            hostTag: hostTag,
            dates: dates,
            squadCount: trip.squadMembers.length < 1
                ? 1
                : trip.squadMembers.length,
            departure: departure,
            // Reveal cards carry the trip's invite URL so last-minute
            // joiners see a tappable link when the image is shared.
            inviteUrl:
                'https://gettripsquad.com/join/?t=${trip.inviteToken ?? trip.id}',
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
            begin: 0.08, delay: 400.ms, duration: 600.ms),

        const SizedBox(height: 28),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(children: [
            // Text-only share — works everywhere, including WhatsApp
            Builder(builder: (btnCtx) => TSButton(
              label: '↗ share the win',
              onTap: () => _shareLink(btnCtx, trip, dest, hostTag),
            )).animate(delay: 900.ms).fadeIn().slideY(begin: 0.3),
            const SizedBox(height: 10),
            // Image card — for Stories / iMessage
            Builder(builder: (btnCtx) => TSButton(
              label: '📷 share as card',
              variant: TSButtonVariant.outline,
              onTap: () => _share(btnCtx, trip, dest, hostTag),
            )).animate(delay: 1000.ms).fadeIn().slideY(begin: 0.3),
            const SizedBox(height: 10),
            TSButton(
              label: _generatingItinerary
                  ? 'scout\'s cooking…'
                  : '🧭 build the itinerary',
              variant: TSButtonVariant.ghost,
              onTap: _generatingItinerary
                  ? null
                  : () => _buildItinerary(context, trip),
            ).animate(delay: 1050.ms).fadeIn().slideY(begin: 0.3),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/trip/${trip.id}/space'),
              child: Text(
                'open the trip →',
                style: TSTextStyles.body(color: TSColors.muted),
              ),
            ).animate(delay: 1200.ms).fadeIn(),
          ]),
        ),
      ])),
    );
  }

  /// Text-only share — the primary path. Works in WhatsApp, iMessage,
  /// Signal, Discord, SMS; the invite URL auto-links in every
  /// messenger. No image means no caption-stripping.
  Future<void> _shareLink(
      BuildContext btnCtx, Trip trip, String dest, String hostTag) async {
    TSHaptics.ctaCommit();
    final inviteUrl =
        'https://gettripsquad.com/join/?t=${trip.inviteToken ?? trip.id}';
    final text =
        "we're going to $dest ✈️🎉\nplanned with tripsquad: $inviteUrl";

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
      debugPrint('reveal link share failed: $e');
      try {
        await Clipboard.setData(ClipboardData(text: inviteUrl));
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

  /// Renders the Boarding Pass to a PNG and shares it with a one-liner.
  /// Falls back to text-only if the image export fails; surfaces errors
  /// to a snackbar so failures aren't silent.
  Future<void> _share(
      BuildContext btnCtx, Trip trip, String dest, String hostTag) async {
    TSHaptics.ctaCommit();
    final text =
        "we're going to $dest ✈️🎉 · planned with tripsquad\nhttps://gettripsquad.com";

    // Position origin for iPad — iOS requires this for share sheets; on
    // iPhone it's ignored. Derived from the tapped button.
    Rect? origin;
    try {
      final box = btnCtx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}

    // First attempt: share with the rendered PNG attached.
    String? imagePath;
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final f =
              await File('${dir.path}/tripsquad-reveal-${trip.id}.png')
                  .writeAsBytes(bytes.buffer.asUint8List());
          imagePath = f.path;
        }
      }
    } catch (e) {
      // Swallow — we'll fall back to text-only share below.
      debugPrint('reveal card export failed: $e');
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
        await Share.share(
          text,
          subject: 'tripsquad',
          sharePositionOrigin: origin,
        );
      }
    } catch (e) {
      debugPrint('share failed: $e');
      if (!mounted) return;
      // Last-resort: copy URL to pasteboard + confirm.
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

  Future<void> _buildItinerary(BuildContext context, Trip trip) async {
    setState(() => _generatingItinerary = true);
    try {
      // Skip if itinerary already exists.
      final existing = await Supabase.instance.client
          .from('itinerary_days')
          .select('id')
          .eq('trip_id', trip.id)
          .limit(1);
      if ((existing as List).isEmpty) {
        await ref.read(aIGenerationProvider.notifier)
            .generateItinerary(trip.id);
      }
      if (context.mounted) {
        context.go('/trip/${trip.id}/space');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('scout hit a snag — $e',
                style: TSTextStyles.body(color: TSColors.bg, size: 13)),
            backgroundColor: TSColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingItinerary = false);
    }
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

  String? _departureLabel(Trip t) {
    if (t.startDate == null) return null;
    final days = t.startDate!
        .difference(DateTime.now())
        .inDays;
    if (days < 0) return 'in progress';
    if (days == 0) return 'today';
    if (days == 1) return 'tomorrow';
    return '$days days from now';
  }

  /// Low-effort photo fallback — Unsplash source as a best-effort bg.
  String? _hintPhotoFor(String destination) {
    if (destination.isEmpty) return null;
    final q = Uri.encodeQueryComponent('$destination city');
    return 'https://source.unsplash.com/featured/1080x1920/?$q';
  }
}
