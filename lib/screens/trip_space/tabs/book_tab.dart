import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/widgets.dart';
import '../widgets/deadline_chip.dart';
import '../widgets/flight_card.dart';
import '../widgets/set_deadline_sheet.dart';
import '../widgets/set_departure_sheet.dart';

/// "Book" tab — the squad-coordination layer between Stays + Eats
/// (discovery) and the partner site (conversion). Two sections via
/// pill toggle:
///   - flights: per-member arrival plan cards. Anchor badge on
///     first booker. Find-flights deep links go through
///     affiliate_redirect for attribution.
///   - accommodation: lock-in count + jump-back to Stays + Eats.
///     The actual hotel booking flow lives in Stays + Eats — this
///     section tracks who's confirmed.
///
/// Visible from `revealed` phase onward.
class BookTab extends ConsumerStatefulWidget {
  const BookTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<BookTab> createState() => _BookTabState();
}

class _BookTabState extends ConsumerState<BookTab> {
  String? _arrivalIata;
  bool _arrivalIataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadArrivalIata();
  }

  /// Resolve the trip destination to an IATA via destination_guides.
  /// Used by the flight card's search URL builder. Null when the
  /// destination isn't curated — the search falls back to Google
  /// Flights with text city names.
  Future<void> _loadArrivalIata() async {
    try {
      final dest = widget.trip.selectedDestination;
      if (dest == null || dest.isEmpty) {
        if (mounted) setState(() => _arrivalIataLoaded = true);
      } else {
        final guide = await ref
            .read(placesServiceProvider)
            .fetchDestinationGuide(dest);
        if (mounted) {
          setState(() {
            _arrivalIata = guide?['airport_iata'] as String?;
            _arrivalIataLoaded = true;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _arrivalIataLoaded = true);
    }

    // Auto-fill the user's per-trip departure from their profile
    // (home_city + home_airport set in onboarding / settings). Without
    // this, the user got the "set departure airport" CTA every time —
    // even though we already had the data on the profiles row. Realtime
    // stream picks up the new arrival_plan and the card re-renders.
    try {
      await ref.read(bookingServiceProvider).bootstrapArrivalPlanFromProfile(
            tripId: widget.trip.id,
            arrivalIata: _arrivalIata,
          );
    } catch (_) { /* non-fatal */ }
  }

  Future<void> _openSetDeparture(MemberArrivalPlan? existing) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetDepartureSheet(
        trip: widget.trip,
        arrivalIata: _arrivalIata,
        initialCity: existing?.departureCity,
        initialIata: existing?.departureIata,
      ),
    );
    if (result == true && mounted) TSHaptics.light();
  }

  Future<void> _openSetDeadline(BookingKind kind) async {
    // Find any existing deadline for this kind so the modal opens
    // pre-populated. AsyncValue.maybeWhen + nullable firstWhere avoids
    // throwing when the list is empty or hasn't loaded yet.
    final deadlinesAsync =
        ref.read(tripBookingDeadlinesProvider(widget.trip.id));
    final existing = deadlinesAsync.maybeWhen(
      data: (list) {
        try {
          return list.firstWhere((d) => d.kind == kind);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetDeadlineSheet(
        trip: widget.trip,
        kind: kind,
        existing: existing,
      ),
    );
    if (result == true && mounted) TSHaptics.success();
  }

  /// Returns a non-null banner widget when the host should reconsider
  /// the squad accommodation pick: pick was set >24h ago and less than
  /// half the squad has confirmed. Surfaces a "rethink the pick?"
  /// CTA so the host isn't railroading the squad. Hidden for non-hosts
  /// and for the flights scope.
  Widget? _maybeSquadPickStaleWarning({
    required AsyncValue<TripLockinStatus?> lockinAsync,
    required bool isHost,
    required bool onAccommodation,
  }) {
    if (!isHost || !onAccommodation) return null;
    final pickedAt = widget.trip.squadPickSetAt;
    final pickId = widget.trip.squadPickAccommodationId;
    if (pickId == null || pickedAt == null) return null;
    final age = DateTime.now().difference(pickedAt);
    if (age.inHours < 24) return null;
    final lockin = lockinAsync.valueOrNull;
    if (lockin == null || lockin.squadSize == 0) return null;
    final pct = lockin.accommodationLockinPct ?? 0;
    if (pct >= 50) return null;
    return _StalePickBanner(
      bookedCount: lockin.accommodationBooked,
      squadSize: lockin.squadSize,
      onNudge: () => _nudgeUnset(BookingKind.accommodation),
    );
  }

  /// Host action: ping unset squad members. Returns count for the
  /// snackbar copy ("nudged 3 squadmates"). Backed by the
  /// nudge_unset_members RPC which throttles per recipient (24h).
  Future<void> _nudgeUnset(BookingKind kind) async {
    TSHaptics.ctaTap();
    try {
      final n = await ref.read(bookingServiceProvider).nudgeUnsetMembers(
            tripId: widget.trip.id,
            kind: kind == BookingKind.flight ? 'flight' : 'accommodation',
          );
      if (mounted) {
        TSHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(n == 0
                ? "everyone's already nudged in the last 24h ✨"
                : 'nudged $n squadmate${n == 1 ? '' : 's'} ✦'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }

  Future<void> _markMyBooked() async {
    TSHaptics.ctaTap();
    try {
      await ref
          .read(bookingServiceProvider)
          .markMyFlightBooked(tripId: widget.trip.id);
      if (mounted) {
        TSHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('locked in. squad will see it ✦'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trip.selectedDestination == null ||
        widget.trip.selectedDestination!.isEmpty) {
      return _Empty(
        title: 'reveal your destination first',
        body: 'booking tools open up once the trip is real.',
      );
    }

    final scope = ref.watch(bookScopeProvider);
    final lockinAsync =
        ref.watch(tripLockinStatusProvider(widget.trip.id));
    final deadlinesAsync =
        ref.watch(tripBookingDeadlinesProvider(widget.trip.id));
    final meUid = Supabase.instance.client.auth.currentUser?.id;
    final isHost = meUid != null && widget.trip.hostId == meUid;
    final scopeKind = scope == BookScope.flights
        ? BookingKind.flight
        : BookingKind.accommodation;

    // Low-confirm warning: when the squad pick is >24h old AND less
    // than half the squad has confirmed, surface a host-facing banner
    // so they can rethink. Read from trip + lock-in status.
    final squadPickStaleWarning = _maybeSquadPickStaleWarning(
      lockinAsync: lockinAsync,
      isHost: isHost,
      onAccommodation: scope == BookScope.accommodation,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Lock-in counter (real even before deadlines exist).
        lockinAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (s) => s == null
              ? const SizedBox.shrink()
              : _LockinHeader(status: s),
        ),

        const SizedBox(height: 16),

        _PillToggle(
          scope: scope,
          onChange: (s) =>
              ref.read(bookScopeProvider.notifier).state = s,
        ),

        const SizedBox(height: 12),

        // Deadline + nudge row for the active scope. Hosts see edit
        // / set affordances and a "nudge unset members" button on
        // the right; guests see read-only countdown.
        deadlinesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (list) {
            final d = list.where((x) => x.kind == scopeKind).toList();
            return Row(children: [
              if (d.isNotEmpty)
                DeadlineChip(
                  deadline: d.first,
                  canEdit: isHost,
                  onTap: () => _openSetDeadline(scopeKind),
                )
              else if (isHost)
                SetDeadlineStub(
                  label: scope == BookScope.flights
                      ? 'set flight deadline'
                      : 'set accommodation deadline',
                  onTap: () => _openSetDeadline(scopeKind),
                ),
              const Spacer(),
              if (isHost)
                _NudgeButton(onTap: () => _nudgeUnset(scopeKind)),
            ]);
          },
        ),

        const SizedBox(height: 12),

        if (squadPickStaleWarning != null) ...[
          squadPickStaleWarning,
          const SizedBox(height: 12),
        ],

        if (scope == BookScope.flights)
          _FlightsSection(
            trip: widget.trip,
            arrivalIata: _arrivalIata,
            arrivalIataLoaded: _arrivalIataLoaded,
            onSetDeparture: _openSetDeparture,
            onMarkBooked: _markMyBooked,
          )
        else
          _AccommodationSection(trip: widget.trip),

        const SizedBox(height: 24),
        Center(
          child: Text(
            "lock in together · the trip becomes real when the squad books",
            style: TSTextStyles.caption(color: TSColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Lock-in header
// ──────────────────────────────────────────────────────────────
class _LockinHeader extends StatelessWidget {
  const _LockinHeader({required this.status});
  final TripLockinStatus status;

  @override
  Widget build(BuildContext context) {
    final flights = status.flightsBooked;
    final accom = status.accommodationBooked;
    final size = status.squadSize == 0 ? 1 : status.squadSize;
    final maxBooked = flights > accom ? flights : accom;
    return TSCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('🔒', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              '$maxBooked / $size squad locked in',
              style: TSTextStyles.heading(size: 16),
            ),
          ]),
          const SizedBox(height: 8),
          _LockinBar(label: '✈️ flights', booked: flights, total: size),
          const SizedBox(height: 6),
          _LockinBar(label: '🏨 accommodation', booked: accom, total: size),
        ],
      ),
    );
  }
}

class _LockinBar extends StatelessWidget {
  const _LockinBar({
    required this.label,
    required this.booked,
    required this.total,
  });
  final String label;
  final int booked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : booked / total;
    return Row(children: [
      SizedBox(
        width: 110,
        child: Text(label,
            style: TSTextStyles.body(size: 12, color: TSColors.text2)),
      ),
      Expanded(
        child: Stack(children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: TSColors.s2,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: TSColors.lime,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 10),
      Text(
        '$booked/$total',
        style: TSTextStyles.label(color: TSColors.muted, size: 11),
      ),
    ]);
  }
}

// ──────────────────────────────────────────────────────────────
//  Pill toggle (flights | accommodation)
// ──────────────────────────────────────────────────────────────
class _PillToggle extends StatelessWidget {
  const _PillToggle({required this.scope, required this.onChange});
  final BookScope scope;
  final ValueChanged<BookScope> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Pill(
        label: 'flights',
        emoji: '✈️',
        selected: scope == BookScope.flights,
        onTap: () {
          TSHaptics.light();
          onChange(BookScope.flights);
        },
      ),
      const SizedBox(width: 8),
      _Pill(
        label: 'accommodation',
        emoji: '🏨',
        selected: scope == BookScope.accommodation,
        onTap: () {
          TSHaptics.light();
          onChange(BookScope.accommodation);
        },
      ),
    ]);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? TSColors.limeDim(0.14) : TSColors.s2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? TSColors.lime : TSColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TSTextStyles.label(
              color: selected ? TSColors.lime : TSColors.text,
              size: 13,
            ),
          ),
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Flights section — per-member cards
// ──────────────────────────────────────────────────────────────
class _FlightsSection extends ConsumerWidget {
  const _FlightsSection({
    required this.trip,
    required this.arrivalIata,
    required this.arrivalIataLoaded,
    required this.onSetDeparture,
    required this.onMarkBooked,
  });
  final Trip trip;
  final String? arrivalIata;
  final bool arrivalIataLoaded;
  final void Function(MemberArrivalPlan? existing) onSetDeparture;
  final VoidCallback onMarkBooked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadAsync = ref.watch(squadStreamProvider(trip.id));
    final plansAsync = ref.watch(arrivalPlansProvider(trip.id));
    final meUid = Supabase.instance.client.auth.currentUser?.id;

    return squadAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: TSColors.lime)),
      ),
      error: (e, _) => _Empty(
        title: "couldn't load the squad",
        body: humanizeError(e),
      ),
      data: (squad) {
        return plansAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(color: TSColors.lime)),
          ),
          error: (e, _) => _Empty(
            title: "couldn't load flight plans",
            body: humanizeError(e),
          ),
          data: (plans) {
            // Only render members who've actually joined (userId is
            // null for invited-not-yet-joined members).
            final joinedSquad =
                squad.where((m) => m.userId != null).toList();
            final byUser = {for (final p in plans) p.userId: p};
            // Find the anchor (first booker on the trip) — others get
            // a "match arrival ~Xpm" hint so the squad converges on
            // the same arrival window.
            MemberArrivalPlan? anchor;
            try {
              anchor = plans.firstWhere((p) => p.isAnchor);
            } catch (_) {
              anchor = null;
            }
            final anchorMember = anchor == null
                ? null
                : joinedSquad.firstWhere(
                    (m) => m.userId == anchor!.userId,
                    orElse: () => joinedSquad.first,
                  );
            // Stable order: anchor first, then booked, searching, not_set.
            final sortedSquad = [...joinedSquad];
            sortedSquad.sort((a, b) {
              final pa = byUser[a.userId];
              final pb = byUser[b.userId];
              if (pa?.isAnchor == true && pb?.isAnchor != true) return -1;
              if (pb?.isAnchor == true && pa?.isAnchor != true) return 1;
              return _stateOrder(pa?.state).compareTo(_stateOrder(pb?.state));
            });

            return Column(
              children: [
                for (var i = 0; i < sortedSquad.length; i++) ...[
                  _wrapWithSearchUrl(
                    context: context,
                    ref: ref,
                    member: sortedSquad[i],
                    plan: byUser[sortedSquad[i].userId],
                    isMe: sortedSquad[i].userId == meUid,
                    anchorArrivalAt: anchor?.outboundAt,
                    anchorMemberName: anchorMember == null
                        ? null
                        : (anchorMember.userId == meUid
                            ? 'you'
                            : anchorMember.nickname),
                  ).animate().fadeIn(delay: (i * 60).ms),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _wrapWithSearchUrl({
    required BuildContext context,
    required WidgetRef ref,
    required SquadMember member,
    required MemberArrivalPlan? plan,
    required bool isMe,
    DateTime? anchorArrivalAt,
    String? anchorMemberName,
  }) {
    String? url;
    if (plan != null &&
        plan.departureIata != null &&
        plan.departureIata!.isNotEmpty) {
      url = ref.read(bookingServiceProvider).buildFlightSearchUrl(
            tripId: trip.id,
            memberUserId: member.userId!, // filtered to non-null above
            departureIata: plan.departureIata,
            arrivalIata: arrivalIata,
            departDate: trip.startDate,
            returnDate: trip.endDate,
            adults: 1,
          );
    }
    return FlightCard(
      plan: plan,
      member: member,
      isMe: isMe,
      searchUrl: url,
      onSetDeparture: () => onSetDeparture(plan),
      onMarkBooked: onMarkBooked,
      anchorArrivalAt: anchorArrivalAt,
      anchorMemberName: anchorMemberName,
    );
  }

  int _stateOrder(ArrivalPlanState? s) {
    switch (s) {
      case ArrivalPlanState.booked:
        return 0;
      case ArrivalPlanState.searching:
        return 1;
      case ArrivalPlanState.cancelled:
        return 3;
      case ArrivalPlanState.not_set:
      case null:
        return 2;
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  Accommodation section — link back to Stays + Eats + lock-in
// ──────────────────────────────────────────────────────────────
class _AccommodationSection extends ConsumerWidget {
  const _AccommodationSection({required this.trip});
  final Trip trip;

  Future<void> _markAccommodationBooked(WidgetRef ref) async {
    TSHaptics.ctaTap();
    try {
      await ref.read(bookingServiceProvider).recordBookingConfirmation(
            tripId: trip.id,
            kind: 'accommodation',
          );
    } catch (_) { /* surfaced via stream error if any */ }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmationsAsync =
        ref.watch(bookingConfirmationsProvider(trip.id));
    final meUid = Supabase.instance.client.auth.currentUser?.id;

    return confirmationsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: TSColors.lime)),
      ),
      error: (e, _) => _Empty(
        title: "couldn't load",
        body: humanizeError(e),
      ),
      data: (confirms) {
        final accomConfirms =
            confirms.where((c) => c.kind == BookingKind.accommodation).toList();
        final iBooked = accomConfirms.any((c) => c.userId == meUid);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TSCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("scout's picks live in stays + eats",
                      style: TSTextStyles.heading(size: 15)),
                  const SizedBox(height: 6),
                  Text(
                    "browse hotels, tap find rates to book through our partners. then come back and lock yourself in.",
                    style: TSTextStyles.body(size: 13, color: TSColors.text2),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    InkWell(
                      onTap: () {
                        TSHaptics.light();
                        // Cross-tab nav: jump to stays + eats (uses
                        // the existing tripSpaceJumpProvider plumbing).
                        final prev = ref.read(tripSpaceJumpProvider);
                        ref.read(tripSpaceJumpProvider.notifier).state =
                            TripSpaceJumpRequest(
                          tabKey: 'stays',
                          seq: (prev?.seq ?? 0) + 1,
                        );
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: TSColors.lime,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.hotel,
                              size: 14, color: TSColors.bg),
                          const SizedBox(width: 6),
                          Text(
                            'browse stays',
                            style: TSTextStyles.label(
                                color: TSColors.bg, size: 12),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!iBooked)
                      InkWell(
                        onTap: () => _markAccommodationBooked(ref),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: TSColors.s2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: TSColors.border),
                          ),
                          child: Text(
                            '✓ I booked',
                            style: TSTextStyles.label(
                                color: TSColors.text, size: 12),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: TSColors.lime.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: TSColors.lime.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check,
                              size: 14, color: TSColors.lime),
                          const SizedBox(width: 6),
                          Text(
                            'booked',
                            style: TSTextStyles.label(
                                color: TSColors.lime, size: 12),
                          ),
                        ]),
                      ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (accomConfirms.isNotEmpty)
              Text(
                '${accomConfirms.length} of squad locked in their accommodation',
                style: TSTextStyles.body(size: 13, color: TSColors.text2),
              )
            else
              Text(
                "nobody's booked accommodation yet. be the first.",
                style: TSTextStyles.body(size: 13, color: TSColors.muted),
              ),
          ],
        );
      },
    );
  }
}

/// Host-only banner: "your squad pick isn't catching." Shown when
/// the squad pick was set >24h ago and confirms < 50%. Two actions:
/// nudge the holdouts (existing nudge_unset_members RPC), or
/// "rethink" which currently scrolls back to alternatives — the host
/// re-taps "make this our pick" on a different hotel; setSquadPick
/// upserts the trip column.
class _StalePickBanner extends StatelessWidget {
  const _StalePickBanner({
    required this.bookedCount,
    required this.squadSize,
    required this.onNudge,
  });
  final int bookedCount;
  final int squadSize;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFFFB800).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🤔', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'only $bookedCount of $squadSize are in for this stay',
                style: TSTextStyles.heading(size: 14),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            "the squad pick is more than a day old. nudge the holdouts, or change the pick — tap 'make this our pick' on a different hotel.",
            style: TSTextStyles.body(size: 13, color: TSColors.text2),
          ),
          const SizedBox(height: 10),
          Row(children: [
            InkWell(
              onTap: onNudge,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: TSColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.notifications_outlined,
                      size: 12, color: TSColors.text2),
                  const SizedBox(width: 5),
                  Text('nudge holdouts',
                      style: TSTextStyles.label(
                          color: TSColors.text2, size: 11)),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Host-only nudge button. Tap → fires the nudge_unset_members RPC
/// for the active scope. Outline style so it doesn't compete visually
/// with the lime-filled action buttons elsewhere on the surface.
class _NudgeButton extends StatelessWidget {
  const _NudgeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: TSColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_outlined,
              size: 12, color: TSColors.text2),
          const SizedBox(width: 5),
          Text('nudge unset',
              style:
                  TSTextStyles.label(color: TSColors.text2, size: 11)),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text(title, style: TSTextStyles.heading(size: 16)),
          const SizedBox(height: 6),
          Text(body,
              style: TSTextStyles.body(color: TSColors.text2),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
