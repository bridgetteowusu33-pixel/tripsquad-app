import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../widgets/tappable.dart';
import '../../widgets/ts_scaffold.dart';
import '../../widgets/me_sheet.dart';
import '../../widgets/home_focus.dart';
import '../../widgets/home_countdown.dart';
import '../../widgets/home_daily_question.dart';
import '../../widgets/home_on_this_day.dart';
import '../../widgets/home_push_banner.dart';
import '../../widgets/home_recap_prompt.dart';
import '../../widgets/home_scout_prompts.dart';
import '../../widgets/whats_new_sheet.dart';
import '../../widgets/trip_card.dart' as tc;
import '../../widgets/resume_vote_banner.dart';
import '../paywall/create_trip_gate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  RealtimeChannel? _tripsChannel;

  @override
  void initState() {
    super.initState();
    _subscribeToTripChanges();
    // Show "what's new" half-sheet once per upgrade. Internal flag in
    // SharedPreferences keeps it from re-firing on the same device.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowWhatsNew(context);
    });
  }

  /// Keep Home's trip cards live without pull-to-refresh.
  ///
  /// `myTripsProvider` is a Future (one-shot fetch via a complex
  /// `squad_members → trips` join that Supabase realtime streams
  /// can't express). Instead of rewriting the provider as a stream,
  /// we open a realtime channel here that listens for INSERT /
  /// UPDATE / DELETE on the two source tables and invalidates the
  /// provider on any change. RLS scopes the incoming events to
  /// trips the current user is actually in.
  ///
  /// Covers:
  ///   - trip status flip (voting → revealed → planning → live → completed)
  ///   - new trip created (squad_members insert for host + guests)
  ///   - someone joining / leaving the squad
  ///   - destination selected on reveal
  ///   - trip deleted
  void _subscribeToTripChanges() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    void refresh() {
      if (!mounted) return;
      ref.invalidate(myTripsProvider);
    }

    _tripsChannel = Supabase.instance.client
        .channel('home-trips-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'squad_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) => refresh(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    final ch = _tripsChannel;
    if (ch != null) {
      Supabase.instance.client.removeChannel(ch);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile  = ref.watch(currentProfileProvider);
    final myTrips  = ref.watch(myTripsProvider);

    return TSScaffold(
      style: TSBackgroundStyle.ambient,
      body: SafeArea(
        child: RefreshIndicator(
          color: TSColors.lime,
          backgroundColor: TSColors.s2,
          onRefresh: () async {
            TSHaptics.light();
            ref.invalidate(myTripsProvider);
            ref.invalidate(myRecentActivityProvider);
            await ref.read(myTripsProvider.future);
          },
          child: TSResponsive.feed(CustomScrollView(slivers: [
            // ── App bar ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    TSSpacing.md, TSSpacing.sm, TSSpacing.md, 0),
                child: Row(children: [
                  // Logo
                  Row(children: [
                    Text('Trip', style: TSTextStyles.title(size: 20)),
                    Text(
                      'squad',
                      style: TSTextStyles.title(size: 20, color: TSColors.lime)
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ]),
                  const Spacer(),
                  // Active trips badge
                  myTrips.when(
                    data: (trips) {
                      final active = trips.where((t) =>
                          t.status != TripStatus.completed).length;
                      if (active == 0) return const SizedBox();
                      return TSPill('$active active', variant: TSPillVariant.lime);
                    },
                    loading: () => const SizedBox(),
                    error:   (_, __) => const SizedBox(),
                  ),
                  const SizedBox(width: 6),
                  const _StreakPill(),
                  const SizedBox(width: 6),
                  const _KnowsYouPill(),
                  const SizedBox(width: 10),
                  // 🔍 search
                  TSTappable(
                    onTap: () {
                      TSHaptics.light();
                      context.push('/search');
                    },
                    child: const Icon(Icons.search_rounded,
                        color: TSColors.text, size: 24),
                  ),
                  const SizedBox(width: 10),
                  // ✉️ DM envelope with unread badge
                  _DmButton(),
                  const SizedBox(width: 10),
                  // Profile avatar — tap opens Me sheet (redesign §C IA)
                  profile.when(
                    data: (p) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => MeSheet.show(context),
                      child: TSAvatar(
                        emoji: p?.emoji ?? '😎',
                        photoUrl: p?.avatarUrl,
                        size: 28,
                      ),
                    ),
                    loading: () => const SizedBox(width: 28),
                    error:   (_, __) => const SizedBox(),
                  ),
                ]),
              ),
            ),

            // ── HomeFocusLine — one line, one specific ask, one CTA ─
            const SliverToBoxAdapter(child: HomeFocusLine()),

            // ── Push permissions nudge (quiet if already on) ──
            const SliverToBoxAdapter(child: HomePushBanner()),

            // ── Resume voting — persistent, pulses until you vote ─
            const SliverToBoxAdapter(child: ResumeVoteBanner()),

            // ── Live countdown to next trip (revealed/planning within 60 days) ─
            const SliverToBoxAdapter(child: HomeCountdown()),

            // ── Scout's daily question — one per calendar day ─
            const SliverToBoxAdapter(child: HomeDailyQuestion()),

            // ── "on this day" flashback — anniversary of a past trip ─
            const SliverToBoxAdapter(child: HomeOnThisDay()),

            // ── "rate your trip" — wrapped in the last 14 days, not dismissed ─
            const SliverToBoxAdapter(child: HomeRecapPrompt()),

            // ── Ask Scout quick prompts (horizontal) ──────────
            const SliverToBoxAdapter(child: HomeScoutPrompts()),

            // ── Activity ticker (horizontal scroll) ───────────
            const SliverToBoxAdapter(child: _ActivityTicker()),

            // ── Trips list (active only) ─────────────────────
            myTrips.when(
              data: (trips) {
                final activeTrips = trips
                    .where((t) => t.status != TripStatus.completed)
                    .toList();
                if (activeTrips.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(),
                  );
                }
                // On iPad portrait and wider, lay trip cards out in a
                // 2-column grid. Fixed count (rather than
                // maxCrossAxisExtent) so landscape iPads still show 2
                // per row instead of squeezing in a third.
                final wide = TSResponsive.isWide(context);
                final cardBuilder = (BuildContext c, int i) =>
                    tc.TripCard(
                      trip: activeTrips[i],
                      compactMargin: wide,
                    )
                        .animate()
                        .fadeIn(delay: (i * 60).ms)
                        .slideY(begin: 0.1, delay: (i * 60).ms);
                if (wide) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        TSSpacing.md, TSSpacing.sm, TSSpacing.md, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 172,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        cardBuilder,
                        childCount: activeTrips.length,
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, TSSpacing.sm, 0, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      cardBuilder,
                      childCount: activeTrips.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: TSColors.lime)),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(TSSpacing.lg),
                  child: Text('Error: $e', style: TSTextStyles.body(color: TSColors.coral, size: 12)),
                ),
              ),
            ),

            // ── New trip CTA (only when trips exist) ─────────
            if (myTrips.valueOrNull?.isNotEmpty == true)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    TSSpacing.md, TSSpacing.md, TSSpacing.md, TSSpacing.xxl),
                child: TSTappable(
                  onTap: () => gateAndOpenTripWizard(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(TSSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: TSRadius.md,
                      border: Border.all(
                        color: TSColors.border2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🗺️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('+ plan a new trip',
                          style: TSTextStyles.title(color: TSColors.text2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ])),
        ),
      ),
    );
  }
}


// ── 🧭 "Scout knows you" pill ────────────────────────────────
// Small percentage pill in the top bar. Tap → opens Me sheet so
// the user can see what's missing. Hidden while the profile is
// loading.
class _KnowsYouPill extends ConsumerWidget {
  const _KnowsYouPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox();
    final pct = scoutKnowsScore(profile);
    return TSTappable(
      onTap: () {
        TSHaptics.light();
        MeSheet.show(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TSColors.purple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: TSColors.purple.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🧭', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text('$pct%',
              style: TSTextStyles.label(
                  color: TSColors.purple, size: 10)),
        ]),
      ),
    );
  }
}

// ── 🔥 Scout daily-question streak pill ──────────────────────
// Hidden below 2 days so it lands as a reward, not a zero state.
// Tap → jumps to Scout tab (where the streak lives at the top).
class _StreakPill extends ConsumerWidget {
  const _StreakPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(scoutStreakProvider).valueOrNull ?? 0;
    if (streak < 2) return const SizedBox();
    return TSTappable(
      onTap: () {
        TSHaptics.light();
        context.push('/scout');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TSColors.limeDim(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TSColors.limeDim(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔥', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text('$streak',
              style: TSTextStyles.label(color: TSColors.lime, size: 10)),
        ]),
      ),
    );
  }
}

// ── ✉️ DM button with unread badge ───────────────────────────
class _DmButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotifCountProvider).maybeWhen(
          data: (n) => n,
          orElse: () => 0,
        );
    return TSTappable(
      onTap: () {
        TSHaptics.light();
        context.push('/messages');
      },
      child: Stack(clipBehavior: Clip.none, children: [
        const Icon(Icons.mail_outline_rounded,
            color: TSColors.text, size: 24),
        if (unread > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: TSColors.lime,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: TSTextStyles.label(color: TSColors.bg, size: 9),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Squad activity ticker (horizontal scroll) ────────────────
class _ActivityTicker extends ConsumerWidget {
  const _ActivityTicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(myRecentActivityProvider);
    return events.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.only(top: TSSpacing.lg),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: TSSpacing.md),
              itemCount: items.length > 15 ? 15 : items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final e = items[i];
                final title = (e.payload?['title'] as String?) ?? e.kind;
                final emoji = _emojiForKind(e.kind);
                return Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TSColors.s1,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TSColors.limeDim(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 220),
                          child: Text(
                            title,
                            style: TSTextStyles.caption(color: TSColors.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  String _emojiForKind(String kind) {
    switch (kind) {
      case 'vote_cast':         return '🗳️';
      case 'reveal':            return '🎉';
      case 'status_changed':    return '📍';
      case 'options_generated': return '🧭';
      case 'itinerary_ready':   return '🗺️';
      case 'member_joined':     return '👋';
      case 'chat_message':      return '💬';
      default:                  return '✨';
    }
  }
}

// ── Empty state ───────────────────────────────────────────────
/// First-time empty state for Home. Instead of a dead "no trips
/// yet" wall, sets the user up with the product promise (Scout
/// gradient margin + 3-step how-it-works) and a prominent CTA.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget step(String emoji, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(emoji,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TSTextStyles.title(
                            size: 13, color: TSColors.text)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: TSTextStyles.caption(
                            color: TSColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TSSpacing.md, 32, TSSpacing.md, TSSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The app in one line. Names the pain point: the squad
          // always *talks* about a trip in the group chat — tripsquad
          // is where it actually happens.
          Text(
            'finally take the trip out of the group chat.',
            style: TSTextStyles.heading(size: 20),
          ),
          const SizedBox(height: 20),

          // How-it-works — three minimum viable steps.
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: TSColors.s1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TSColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('how it works',
                    style: TSTextStyles.label(
                        color: TSColors.muted, size: 10)),
                const SizedBox(height: 4),
                step('🗺️', 'plan a trip',
                    'pick dates, invite your squad. no app store needed.'),
                step('🗳️', 'scout cooks, squad votes',
                    'everyone says their vibe. we generate. you choose.'),
                step('🎟️', 'earn a stamp',
                    'when you get home — a passport stamp, recap, memory.'),
              ],
            ),
          ),
          const SizedBox(height: 56),

          TSButton(
            label: '+ plan a trip 🗺️',
            onTap: () => context.push('/trip/create'),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                TSHaptics.light();
                context.push('/scout');
              },
              child: Text('or ask scout where to go →',
                  style: TSTextStyles.caption(color: TSColors.lime)),
            ),
          ),
        ],
      ),
    );
  }
}
