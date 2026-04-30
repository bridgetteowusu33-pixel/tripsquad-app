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
import '../widgets/area_hero_card.dart';
import '../widgets/recommendation_card.dart';

/// Stays + Eats tab: scout's where-to-stay + hotel + restaurant
/// recommendations for THIS trip. One scrollable view with three
/// sections (area hero · stays · eats). Auto-generated when the
/// itinerary lands; user can pull-to-refresh to regenerate.
class StaysEatsTab extends ConsumerStatefulWidget {
  const StaysEatsTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<StaysEatsTab> createState() => _StaysEatsTabState();
}

class _StaysEatsTabState extends ConsumerState<StaysEatsTab> {
  bool _regenerating = false;
  bool _autoKickedOff = false;

  /// Auto-trigger generation when the tab opens with no recs but the
  /// itinerary is already in place. Routes through aIGenerationProvider
  /// so the persistent "scout's cooking" banner at the top of trip
  /// space shows during gen — same UX as Plan / Pack tabs. The Edge
  /// Function's skip-if-exists guard means this is safe even when
  /// generate_itinerary already fired the kickoff in the background.
  Future<void> _autoTriggerIfNeeded() async {
    if (_autoKickedOff || _regenerating) return;
    _autoKickedOff = true;
    if (mounted) setState(() => _regenerating = true);
    try {
      await ref
          .read(aIGenerationProvider.notifier)
          .generateRecommendations(widget.trip.id);
    } catch (_) {
      // Swallow auto-kickoff errors so we don't surface a confusing
      // banner when the user didn't ask for anything. The error UI
      // surfaces naturally if the user later pull-to-refreshes.
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  /// Host-only: designate a hotel rec as the squad's accommodation
  /// pick. Updates trips.squad_pick_accommodation_id and fires a
  /// `squad_pick_set` push to the squad. Confirm via dialog so the
  /// host doesn't pick by accident — this is a coordination moment.
  Future<void> _setSquadPick(String recommendationId, String hotelName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TSColors.bg,
        title: Text('make $hotelName the squad stay?',
            style: TSTextStyles.heading(size: 17)),
        content: Text(
          "the squad gets a push: 'we're staying at $hotelName.' members can confirm they're in or pick somewhere else.",
          style: TSTextStyles.body(color: TSColors.text2, size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel',
                style: TSTextStyles.label(color: TSColors.text2, size: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('lock it in',
                style: TSTextStyles.label(color: TSColors.lime, size: 13)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(bookingServiceProvider).setSquadPick(
            tripId: widget.trip.id,
            recommendationId: recommendationId,
          );
      if (mounted) {
        TSHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 squad stay locked in: $hotelName'),
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

  /// Tie a booking_confirmation to a specific hotel rec so the
  /// group-stay tracker counts squadmates per hotel. Called from the
  /// "I'm staying here" button on each Stays + Eats hotel card.
  /// Re-tapping replaces the prior recommendation_id (UNIQUE constraint
  /// on trip+user+kind makes this an upsert).
  Future<void> _markBookedAtHotel(String recommendationId) async {
    try {
      await ref.read(bookingServiceProvider).recordBookingConfirmation(
            tripId: widget.trip.id,
            kind: 'accommodation',
            recommendationId: recommendationId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('locked in ✦'),
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

  Future<void> _refresh() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    TSHaptics.light();
    try {
      await ref
          .read(aIGenerationProvider.notifier)
          .generateRecommendations(widget.trip.id, regenerate: true);
      final genState = ref.read(aIGenerationProvider);
      if (genState.status == AIGenStatus.error) {
        throw Exception(genState.errorMessage ?? 'regeneration failed');
      }
      TSHaptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _generateFirstTime() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    TSHaptics.ctaTap();
    try {
      await ref
          .read(aIGenerationProvider.notifier)
          .generateRecommendations(widget.trip.id);
      final genState = ref.read(aIGenerationProvider);
      if (genState.status == AIGenStatus.error) {
        throw Exception(genState.errorMessage ?? 'generation failed');
      }
      TSHaptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRecs = ref.watch(tripRecommendationsProvider(widget.trip.id));

    // Pre-reveal: don't show anything substantive — Scout needs the
    // destination to do its job.
    if (widget.trip.selectedDestination == null ||
        widget.trip.selectedDestination!.isEmpty) {
      return _EmptyHint(
        emoji: '🗳️',
        title: 'reveal your destination first',
        body: 'scout picks stays + eats once voting closes and the trip is real.',
      );
    }

    return asyncRecs.when(
      loading: () => const _LoadingState(),
      error: (e, _) => _ErrorState(
        message: humanizeError(e),
        onRetry: _generateFirstTime,
        retrying: _regenerating,
      ),
      data: (recs) {
        if (recs.isEmpty) {
          // Reveal+itinerary phases imply gen is in flight (auto-fired
          // by generate_itinerary). Auto-trigger defensively (skip-if-
          // exists protects from double-call) and show the loading
          // state so users don't stare at a dead CTA. Pre-reveal is
          // already handled above so we know we have a destination.
          if (_regenerating) {
            return const _LoadingState();
          }
          final s = widget.trip.status;
          final hasItineraryPhase = s == TripStatus.revealed ||
              s == TripStatus.planning ||
              s == TripStatus.live;
          if (hasItineraryPhase) {
            // Schedule a kickoff after build — calling setState in
            // build is illegal.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _autoTriggerIfNeeded();
            });
            return const _LoadingState();
          }
          return _NotYetGenerated(
            onTap: _generateFirstTime,
            generating: _regenerating,
          );
        }

        final area = recs.firstWhereOrNull(
          (r) => r.kind == RecommendationKind.area,
        );
        final hotels =
            recs.where((r) => r.kind == RecommendationKind.hotel).toList();
        final restaurants =
            recs.where((r) => r.kind == RecommendationKind.restaurant).toList();
        final scope = ref.watch(staysEatsScopeProvider);
        final showStays = scope == StaysEatsScope.stays;

        // Group-stay tracker context: count squad members who've
        // confirmed each hotel rec, plus the squad size for the
        // "N of M" denominator. Watching here so cards re-render
        // as confirmations land in real time. Also track which rec
        // (if any) the current user is booked into, so we render the
        // "you're staying here" state on the right card.
        final confirmsAsync =
            ref.watch(bookingConfirmationsProvider(widget.trip.id));
        final lockinAsync =
            ref.watch(tripLockinStatusProvider(widget.trip.id));
        final meUid = Supabase.instance.client.auth.currentUser?.id;
        final bookedByRec = <String, int>{};
        String? myAccommodationRecId;
        confirmsAsync.whenData((list) {
          for (final c in list) {
            if (c.kind == BookingKind.accommodation &&
                c.recommendationId != null) {
              bookedByRec.update(c.recommendationId!, (n) => n + 1,
                  ifAbsent: () => 1);
              if (c.userId == meUid) {
                myAccommodationRecId = c.recommendationId;
              }
            }
          }
        });
        final squadSize = lockinAsync.valueOrNull?.squadSize ?? 0;

        return RefreshIndicator(
          color: TSColors.lime,
          backgroundColor: TSColors.s2,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Pill toggle: stays | eats. Lifts to a Riverpod
              // provider so other tabs can pre-select before jumping
              // here (e.g. Plan tab's hotel chip → stays).
              _PillToggle(
                scope: scope,
                staysCount: hotels.length,
                eatsCount: restaurants.length,
                onChange: (s) =>
                    ref.read(staysEatsScopeProvider.notifier).state = s,
                refreshing: _regenerating,
                onRefresh: _refresh,
              ),
              const SizedBox(height: 16),

              if (showStays) ...[
                if (area != null) ...[
                  AreaHeroCard(area: area)
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 20),
                ],
                if (hotels.isEmpty)
                  _NoneInScope(
                    label: 'no stays picked yet',
                    body: 'pull down to ask scout',
                  )
                else ...[
                  () {
                    // Re-order so the squad pick (if any) is first
                    // and the alternatives follow under their own
                    // subheader.
                    final pickId = widget.trip.squadPickAccommodationId;
                    final iAmHost =
                        meUid != null && widget.trip.hostId == meUid;
                    final pick = pickId == null
                        ? null
                        : hotels.firstWhereOrNull((h) => h.id == pickId);
                    final ordered = <TripRecommendation>[];
                    if (pick != null) ordered.add(pick);
                    ordered.addAll(hotels.where((h) => h.id != pickId));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < ordered.length; i++) ...[
                          // Once the squad pick exists, drop a
                          // subheader before the alternatives chunk.
                          if (pick != null && i == 1) ...[
                            const SizedBox(height: 4),
                            Text(
                              'alternatives',
                              style: TSTextStyles.label(
                                  color: TSColors.muted, size: 11),
                            ),
                            const SizedBox(height: 8),
                          ],
                          RecommendationCard(
                            rec: ordered[i],
                            bookedCount: bookedByRec[ordered[i].id] ?? 0,
                            squadSize: squadSize,
                            iAmBookedHere:
                                myAccommodationRecId == ordered[i].id,
                            squadPickState: pickId == null
                                ? SquadPickState.none
                                : (ordered[i].id == pickId
                                    ? SquadPickState.thisIsThePick
                                    : SquadPickState.pickIsElsewhere),
                            iAmHost: iAmHost,
                            onMarkBookedHere: () =>
                                _markBookedAtHotel(ordered[i].id),
                            onSetSquadPick: iAmHost && pickId == null
                                ? () => _setSquadPick(
                                    ordered[i].id, ordered[i].name)
                                : null,
                          ).animate().fadeIn(delay: (i * 40).ms),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }(),
                ],
              ] else ...[
                if (restaurants.isEmpty)
                  _NoneInScope(
                    label: 'no eats picked yet',
                    body: 'pull down to ask scout',
                  )
                else
                  for (var i = 0; i < restaurants.length; i++) ...[
                    RecommendationCard(rec: restaurants[i])
                        .animate()
                        .fadeIn(delay: (i * 35).ms),
                    const SizedBox(height: 12),
                  ],
              ],

              const SizedBox(height: 24),
              Center(
                child: Text(
                  "scout's picks · pull to refresh",
                  style: TSTextStyles.caption(color: TSColors.muted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PillToggle extends StatelessWidget {
  const _PillToggle({
    required this.scope,
    required this.staysCount,
    required this.eatsCount,
    required this.onChange,
    required this.refreshing,
    required this.onRefresh,
  });
  final StaysEatsScope scope;
  final int staysCount;
  final int eatsCount;
  final ValueChanged<StaysEatsScope> onChange;
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(
          label: 'stays',
          emoji: '🛏️',
          count: staysCount,
          selected: scope == StaysEatsScope.stays,
          onTap: () {
            TSHaptics.light();
            onChange(StaysEatsScope.stays);
          },
        ),
        const SizedBox(width: 8),
        _Pill(
          label: 'eats',
          emoji: '🍽️',
          count: eatsCount,
          selected: scope == StaysEatsScope.eats,
          onTap: () {
            TSHaptics.light();
            onChange(StaysEatsScope.eats);
          },
        ),
        const Spacer(),
        _RefreshChip(onTap: onRefresh, refreshing: refreshing),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final int count;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TSTextStyles.label(
                color: selected ? TSColors.lime : TSColors.text,
                size: 13,
              ),
            ),
            const SizedBox(width: 6),
            Text('$count',
                style: TSTextStyles.caption(color: TSColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _NoneInScope extends StatelessWidget {
  const _NoneInScope({required this.label, required this.body});
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: TSTextStyles.body(color: TSColors.text2)),
          const SizedBox(height: 4),
          Text(body,
              style: TSTextStyles.caption(color: TSColors.muted)),
        ],
      ),
    );
  }
}

class _RefreshChip extends StatelessWidget {
  const _RefreshChip({required this.onTap, required this.refreshing});
  final VoidCallback onTap;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: refreshing ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: TSColors.border),
        ),
        child: refreshing
            ? const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: TSColors.lime,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh,
                      size: 12, color: TSColors.text2),
                  const SizedBox(width: 4),
                  Text(
                    'refresh',
                    style: TSTextStyles.label(
                      color: TSColors.text2,
                      size: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: TSColors.lime),
          const SizedBox(height: 18),
          Text(
            'scout is picking your stays + eats…',
            style: TSTextStyles.body(color: TSColors.text2),
          ),
        ],
      ),
    );
  }
}

class _NotYetGenerated extends StatelessWidget {
  const _NotYetGenerated({required this.onTap, required this.generating});
  final VoidCallback onTap;
  final bool generating;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏨', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'where to sleep + eat',
              style: TSTextStyles.heading(size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'scout will pick the best area to stay, hotels that fit your squad, and restaurants for each day of the trip.',
              style: TSTextStyles.body(color: TSColors.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            InkWell(
              onTap: generating ? null : onTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: TSColors.lime,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (generating)
                      const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TSColors.bg,
                        ),
                      )
                    else
                      const Icon(Icons.auto_awesome,
                          size: 16, color: TSColors.bg),
                    const SizedBox(width: 8),
                    Text(
                      generating ? 'picking…' : 'ask scout',
                      style: TSTextStyles.label(
                          color: TSColors.bg, size: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.emoji,
    required this.title,
    required this.body,
  });
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(title, style: TSTextStyles.heading(size: 18)),
            const SizedBox(height: 6),
            Text(
              body,
              style: TSTextStyles.body(color: TSColors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.retrying,
  });
  final String message;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛟', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              "scout couldn't pick your stays + eats",
              style: TSTextStyles.heading(size: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TSTextStyles.caption(color: TSColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: retrying ? null : onRetry,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: TSColors.border),
                ),
                child: Text(
                  retrying ? 'trying again…' : 'try again',
                  style: TSTextStyles.label(color: TSColors.text, size: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
