import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/boarding_pass.dart';
import '../../widgets/widgets.dart';
import 'dart:io' show File;

/// The Invite Ceremony — a full-screen moment that plays after trip
/// creation. Black background. A Boarding Pass card renders in with
/// staged animation. Share + Copy buttons slide up at the end.
///
/// Per the redesign §9 — *the invite is the growth loop.* This is the
/// first viral asset in the product. Users should screenshot this
/// card before even hitting "share".
class InviteCeremonyScreen extends ConsumerStatefulWidget {
  const InviteCeremonyScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<InviteCeremonyScreen> createState() =>
      _InviteCeremonyScreenState();
}

class _InviteCeremonyScreenState
    extends ConsumerState<InviteCeremonyScreen> {
  final _cardKey = GlobalKey();
  bool _shared = false;

  @override
  void initState() {
    super.initState();
    // Staged haptic ladder — card materialising.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) TSHaptics.ctaTap();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) TSHaptics.ctaCommit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;

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
          data: (trip) => _Body(
            trip: trip,
            profile: profile,
            cardKey: _cardKey,
            shared: _shared,
            onShareLink: (btnCtx) =>
                _shareLink(btnCtx, trip, profile),
            onShareCard: (btnCtx) =>
                _share(btnCtx, trip, profile),
            onCopy: () => _copyLink(trip),
            // Close X — back to where the user came from (Home).
            onClose: () {
              final nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
              } else {
                context.go('/home');
              }
            },
            // "view trip →" — replace this screen with Trip Space so
            // the chevron on Trip Space pops to Home (not back to the
            // invite ceremony).
            onViewTrip: () =>
                context.pushReplacement('/trip/${trip.id}/space'),
          ),
        ),
      ),
    );
  }

  /// Text-only share. Universally supported — the invite URL renders
  /// as a tappable link in every messenger (WhatsApp, iMessage, Signal,
  /// Discord, SMS). No image attached, so no caption-stripping bugs.
  /// Use this as the primary share path.
  Future<void> _shareLink(
      BuildContext btnCtx, Trip trip, AppUser? profile) async {
    TSHaptics.ctaCommit();
    final inviteUrl = _inviteUrl(trip);
    final hostTag = profile?.tag ?? 'host';
    final text =
        '@$hostTag invited you to help plan ${trip.name}.\n90 seconds: $inviteUrl';

    Rect? origin;
    try {
      final box = btnCtx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}

    bool ok = false;
    try {
      await Share.share(
        text,
        subject: 'tripsquad',
        sharePositionOrigin: origin,
      );
      ok = true;
    } catch (e) {
      debugPrint('invite link share failed: $e');
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
    if (mounted && ok) {
      setState(() => _shared = true);
    }
  }

  /// Renders the Boarding Pass widget to a PNG and shares it alongside
  /// the invite URL. Hardened path — separates image export from the
  /// share call, attaches a position origin (iPad requirement), falls
  /// back to text-only + pasteboard + snackbar if anything fails.
  Future<void> _share(
      BuildContext btnCtx, Trip trip, AppUser? profile) async {
    TSHaptics.ctaCommit();

    final inviteUrl = _inviteUrl(trip);
    final hostTag = profile?.tag ?? 'host';
    final text =
        '@$hostTag invited you to help plan ${trip.name}. 90 seconds.\n$inviteUrl';

    // iPad requires a position origin. iPhone ignores it.
    Rect? origin;
    try {
      final box = btnCtx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}

    // 1) Try to export the Boarding Pass PNG.
    String? imagePath;
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final dir = await getTemporaryDirectory();
          final f =
              await File('${dir.path}/tripsquad-invite-${trip.id}.png')
                  .writeAsBytes(byteData.buffer.asUint8List());
          imagePath = f.path;
        }
      }
    } catch (e) {
      debugPrint('invite card export failed: $e');
    }

    // 2) Attempt the share. If it throws, fall back to pasteboard.
    bool shareSucceeded = false;
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
      shareSucceeded = true;
    } catch (e) {
      debugPrint('invite share failed: $e');
      if (!mounted) return;
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

    // Only flip the button to "↺ share again" if the share sheet
    // actually presented (so we don't gaslight the user).
    if (mounted && shareSucceeded) {
      setState(() => _shared = true);
    }
  }

  Future<void> _copyLink(Trip trip) async {
    TSHaptics.selection();
    final url = _inviteUrl(trip);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('copied — paste in your group chat',
            style: TSTextStyles.body(color: TSColors.bg, size: 14)),
        backgroundColor: TSColors.lime,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _inviteUrl(Trip trip) {
    final token = trip.inviteToken ?? trip.id;
    return 'https://gettripsquad.com/join/?t=$token';
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.trip,
    required this.profile,
    required this.cardKey,
    required this.shared,
    required this.onShareLink,
    required this.onShareCard,
    required this.onCopy,
    required this.onClose,
    required this.onViewTrip,
  });

  final Trip trip;
  final AppUser? profile;
  final GlobalKey cardKey;
  final bool shared;
  final void Function(BuildContext) onShareLink;
  final void Function(BuildContext) onShareCard;
  final VoidCallback onCopy;
  final VoidCallback onClose;
  final VoidCallback onViewTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadAsync = ref.watch(squadStreamProvider(trip.id));
    final squadCount = squadAsync.maybeWhen(
      data: (m) => m.isNotEmpty ? m.length : trip.squadMembers.length,
      orElse: () => trip.squadMembers.length,
    );
    final hostTag = profile?.tag ?? 'host';
    final dates = _fmtDates(trip);
    final destination = _destinationLabel(trip);
    final flag = trip.selectedFlag ?? '✈️';

    return Stack(children: [
      // ── Main content ──────────────────────────────────────
      //
      // Rendered FIRST (painted on the bottom of the Stack) so the
      // header bar below sits on top of it. Previously these two
      // children were reversed, which let the scroll view's
      // hit-test region absorb taps that should have reached the
      // close X in the header.
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "you're invited" lead-in
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(children: [
                  Text('you\'re invited',
                          style: TSTextStyles.display(
                              size: 34, color: TSColors.text))
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.2, duration: 600.ms),
                  const SizedBox(height: 6),
                  Text('share this with your squad',
                          style: TSTextStyles.body(
                              color: TSColors.muted, size: 13))
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 500.ms),
                ]),
              ),

              // The card itself, in a RepaintBoundary so we can export
              // it. Animated with fade + slight tilt on entry.
              RepaintBoundary(
                key: cardKey,
                child: BoardingPassCard(
                  kind: BoardingPassKind.invite,
                  destination: destination,
                  flag: flag,
                  hostTag: hostTag,
                  dates: dates,
                  squadCount: squadCount < 1 ? 1 : squadCount,
                  tripName: trip.name,
                  inviteUrl: 'https://gettripsquad.com/join/?t=${trip.inviteToken ?? trip.id}',
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 700.ms)
                  .slideY(
                      begin: 0.1,
                      delay: 200.ms,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic),

              const SizedBox(height: 32),

              // ── CTAs ──────────────────────────────────────
              // Two share paths, because WhatsApp strips captions on
              // image shares:
              //   • "share link"  → text + URL only. Universal. Link is
              //                     clickable in every messenger.
              //   • "share card"  → the Boarding Pass image. Beautiful
              //                     for Stories / iMessage. URL is
              //                     also baked into the image itself.
              SizedBox(
                width: 280,
                child: Column(children: [
                  Builder(builder: (btnCtx) => TSButton(
                        label: shared ? '↺ share again' : '↗ share link',
                        onTap: () => onShareLink(btnCtx),
                      ))
                      .animate(delay: 1100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3),
                  const SizedBox(height: 10),
                  Builder(builder: (btnCtx) => TSButton(
                        label: '📷 share as card',
                        variant: TSButtonVariant.outline,
                        onTap: () => onShareCard(btnCtx),
                      ))
                      .animate(delay: 1200.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3),
                  const SizedBox(height: 10),
                  TSButton(
                    label: '📋 copy link',
                    variant: TSButtonVariant.ghost,
                    onTap: onCopy,
                  )
                      .animate(delay: 1300.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3),
                  const SizedBox(height: 14),
                  TextButton(
                    // After sharing, "done →" should take the host to the
                    // trip. Before sharing, "skip for now" bails home.
                    onPressed: shared ? onViewTrip : onClose,
                    child: Text(
                      shared ? 'done → view trip' : 'skip for now',
                      style: TSTextStyles.body(
                          color: shared
                              ? TSColors.lime
                              : TSColors.muted),
                    ),
                  ).animate(delay: 1500.ms).fadeIn(),
                ]),
              ),
            ],
          ),
        ),
      ),

      // ── Header bar with close ─────────────────────────────
      //
      // Must be LAST in the Stack so it paints on top of the
      // scroll view and its tap target isn't eaten by the
      // scroll region's hit test.
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
              onPressed: onClose,
            ),
            const Spacer(),
            Text('invite your squad',
                style: TSTextStyles.label(color: TSColors.muted, size: 10)),
            const Spacer(),
            const SizedBox(width: 40),
          ]),
        ),
      ),
    ]);
  }

  String _destinationLabel(Trip t) {
    final picked = t.selectedDestination;
    if (picked != null && picked.isNotEmpty) return picked;
    // No destination yet — use the trip name as the headline.
    return t.name;
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
}
