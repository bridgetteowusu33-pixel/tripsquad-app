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
        return;
      }
      final guide = await ref
          .read(placesServiceProvider)
          .fetchDestinationGuide(dest);
      if (mounted) {
        setState(() {
          _arrivalIata = guide?['airport_iata'] as String?;
          _arrivalIataLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _arrivalIataLoaded = true);
    }
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

        // Deadline row for the active scope. Hosts see edit / set
        // affordances; guests see read-only countdown.
        deadlinesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (list) {
            final d = list.where((x) => x.kind == scopeKind).toList();
            if (d.isNotEmpty) {
              return Row(children: [
                DeadlineChip(
                  deadline: d.first,
                  canEdit: isHost,
                  onTap: () => _openSetDeadline(scopeKind),
                ),
              ]);
            }
            if (isHost) {
              return Row(children: [
                SetDeadlineStub(
                  label: scope == BookScope.flights
                      ? 'set flight deadline'
                      : 'set accommodation deadline',
                  onTap: () => _openSetDeadline(scopeKind),
                ),
              ]);
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 12),

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
