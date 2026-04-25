import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/responsive.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/motion.dart';
import '../../../widgets/widgets.dart';

/// Full-screen swipeable voting UI — the "heart of the product" (UX
/// redesign §15).
///
/// - Horizontal PageView of destination dossiers (one per option).
/// - Swipe between them. Tap the vote button to commit.
/// - Live tide strip at the bottom: avatars bloom in as squad
///   members vote, bars grow per-option in real time.
/// - Host gets a "close voting + reveal" button once every squad
///   member has cast their vote (the trip auto-transitions to
///   `revealed` and TripSpace plays the cinematic).
class VoteTab extends ConsumerStatefulWidget {
  const VoteTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<VoteTab> createState() => _VoteTabState();
}

class _VoteTabState extends ConsumerState<VoteTab> {
  final _pager = PageController(viewportFraction: 0.9);
  String? _selectedOptionId;
  int _pageIndex = 0;
  bool _casting = false;
  bool _hasVoted = false;
  List<Map<String, dynamic>> _options = [];
  List<Map<String, dynamic>> _votes = [];

  /// Changes whenever the vote list changes — drives TheBloom on
  /// avatars that just appeared.
  int _voteTick = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _votesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _optionsSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Realtime: live-refresh on any vote for this trip. Covers in-app
    // votes which insert into the `votes` table.
    _votesSub = Supabase.instance.client
        .from('votes')
        .stream(primaryKey: ['id'])
        .eq('trip_id', widget.trip.id)
        .listen((_) {
      if (!mounted) return;
      _load();
    });
    // Web voters hit `increment_option_vote` RPC which bumps
    // trip_options.vote_count directly (no votes row). Subscribe to
    // trip_options so web votes also refresh the in-app counter.
    _optionsSub = Supabase.instance.client
        .from('trip_options')
        .stream(primaryKey: ['id'])
        .eq('trip_id', widget.trip.id)
        .listen((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _votesSub?.cancel();
    _optionsSub?.cancel();
    _pager.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    final opts = await db
        .from('trip_options')
        .select()
        .eq('trip_id', widget.trip.id)
        .order('compatibility_score', ascending: false);
    // Pull votes (trip-wide) so we can render the live tide strip.
    final votes = await db
        .from('votes')
        .select('user_id, option_id')
        .eq('trip_id', widget.trip.id);
    if (!mounted) return;
    final prevCount = _votes.length;
    setState(() {
      _options = List<Map<String, dynamic>>.from(opts);
      _votes = List<Map<String, dynamic>>.from(votes);
      if (_votes.length != prevCount) _voteTick++;
    });

    if (uid != null) {
      final my = _votes.firstWhere(
        (v) => v['user_id'] == uid,
        orElse: () => const {},
      );
      if (my.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _hasVoted = true;
          _selectedOptionId = my['option_id'] as String?;
        });
      }
    }
  }

  Future<void> _castVote() async {
    final id = _selectedOptionId;
    if (id == null) return;
    await TSHaptics.voteCommit();
    setState(() => _casting = true);
    try {
      await ref.read(tripServiceProvider).castVote(
            tripId: widget.trip.id,
            optionId: id,
          );
      ref.invalidate(myVotedTripIdsProvider);
      if (!mounted) return;
      setState(() => _hasVoted = true);
      await _load();
      // Auto-reveal when the last eligible squad member votes.
      // Eligible = members who have submitted preferences (status
      // 'submitted' or 'voted'). 'invited' members are skipped so a
      // lagging invitee doesn't block the reveal.
      _maybeAutoReveal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(humanizeError(e)),
              backgroundColor: TSColors.coral),
        );
      }
    } finally {
      if (mounted) setState(() => _casting = false);
    }
  }

  Future<void> _maybeAutoReveal() async {
    if (widget.trip.status != TripStatus.voting) return;
    // Pull the squad fresh from the DB — on iPad the stream can lag
    // behind the tab mount and .valueOrNull falls through to the
    // stale trip.squadMembers snapshot, which in turn lets the
    // auto-reveal fire before pending voters have actually voted.
    final db = Supabase.instance.client;
    List<SquadMember> liveSquad;
    try {
      final rows = await db
          .from('squad_members')
          .select()
          .eq('trip_id', widget.trip.id);
      liveSquad = (rows as List)
          .map((r) => SquadMember.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (_) {
      liveSquad = ref
              .read(squadStreamProvider(widget.trip.id))
              .valueOrNull ??
          widget.trip.squadMembers;
    }
    final eligible = liveSquad
        .where((m) =>
            m.status == MemberStatus.submitted ||
            m.status == MemberStatus.voted)
        .length;
    // Require at least 2 — a solo host shouldn't reveal immediately
    // after voting. They can close manually via the confirmation.
    if (eligible < 2) return;
    // Total votes must include web voters (who hit the RPC and don't
    // insert into the `votes` table). Use the per-option vote_count
    // sum as the authoritative count.
    final optionCountSum = _options.fold<int>(
      0,
      (acc, o) => acc + ((o['vote_count'] as int?) ?? 0),
    );
    final totalVotes =
        optionCountSum > _votes.length ? optionCountSum : _votes.length;
    if (totalVotes < eligible) return;
    // Everyone voted — pick winner + transition to revealed. setWinner
    // is idempotent at the app level; if a race happens, the first
    // write wins and subsequent ones overwrite with the same answer.
    try {
      final byVotes = [..._options]..sort((a, b) =>
          ((b['vote_count'] ?? 0) as int)
              .compareTo((a['vote_count'] ?? 0) as int));
      final winner = byVotes.first;
      await ref.read(tripServiceProvider).setWinner(
            tripId: widget.trip.id,
            destination: winner['destination'],
            flag: winner['flag'],
          );
      TSHaptics.success();
    } catch (_) {
      // Silent — host can still trigger manually.
    }
  }

  Future<void> _closeVotingAndReveal() async {
    // Pull the squad fresh from the DB. We were reading from the
    // riverpod stream, but on iPad the tab sometimes mounts before
    // the stream has hydrated and the .valueOrNull fallback to
    // widget.trip.squadMembers is stale — pending was computed as
    // empty and the warning never fired.
    final db = Supabase.instance.client;
    List<SquadMember> liveSquad;
    try {
      final rows = await db
          .from('squad_members')
          .select()
          .eq('trip_id', widget.trip.id);
      liveSquad = (rows as List)
          .map((r) => SquadMember.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (_) {
      // Fall back to whatever the stream or snapshot has — better to
      // try to reveal than to hard-fail.
      liveSquad = ref
              .read(squadStreamProvider(widget.trip.id))
              .valueOrNull ??
          widget.trip.squadMembers;
    }
    // Anyone whose status isn't `voted` hasn't cast a vote yet —
    // including `invited` members who never opened the link and
    // `submitted` members who filled prefs but didn't vote. Web
    // voters are the edge case: the RPC increments vote_count but
    // doesn't flip the row to `voted`, so totalVotes carries the
    // override check below.
    final me = Supabase.instance.client.auth.currentUser?.id;
    final pendingAll = liveSquad
        .where((m) => m.status != MemberStatus.voted && m.userId != me)
        .toList();
    // Web voters don't flip to `voted` — if total votes >= squad size
    // we treat the room as fully voted and skip the warning.
    final optionCountSum = _options.fold<int>(
      0,
      (acc, o) => acc + ((o['vote_count'] as int?) ?? 0),
    );
    final totalVotes =
        optionCountSum > _votes.length ? optionCountSum : _votes.length;
    final roomFullyVoted = totalVotes >= liveSquad.length;
    if (pendingAll.isNotEmpty && !roomFullyVoted) {
      final ok = await _confirmCloseEarly(pendingAll);
      if (ok != true) return;
    }

    TSHaptics.heavy();
    setState(() => _casting = true);
    try {
      if (_options.isEmpty) return;
      final byVotes = [..._options]..sort((a, b) => ((b['vote_count'] ?? 0) as int)
          .compareTo((a['vote_count'] ?? 0) as int));
      final winner = byVotes.first;
      // 800ms pre-reveal pause — the "standby" beat from the redesign
      // (§15 voting ceremony). Gives the host a heartbeat before the
      // cinematic fires.
      await Future.delayed(const Duration(milliseconds: 800));
      await ref.read(tripServiceProvider).setWinner(
            tripId: widget.trip.id,
            destination: winner['destination'],
            flag: winner['flag'],
          );
      TSHaptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(humanizeError(e)),
              backgroundColor: TSColors.coral),
        );
      }
    } finally {
      if (mounted) setState(() => _casting = false);
    }
  }

  /// Explicit confirmation when the host closes voting before every
  /// eligible member has cast a vote. Lists pending names so the host
  /// sees exactly who'll be skipped.
  Future<bool?> _confirmCloseEarly(List<SquadMember> pending) async {
    TSHaptics.medium();
    // Format the name list: up to 3 nicknames, then "and N more".
    final names = pending.map((m) => m.nickname).toList();
    final String namesLine;
    if (names.length <= 3) {
      namesLine = names.join(', ');
    } else {
      namesLine =
          '${names.take(3).join(', ')} and ${names.length - 3} more';
    }

    return showModalBottomSheet<bool>(
      context: context,
      constraints: TSResponsive.modalConstraints,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('close voting now?',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                "$namesLine haven't voted yet. their pick won't count if you close now.",
                style: TSTextStyles.caption(color: TSColors.muted),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheet).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TSColors.s2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('wait for them',
                          style: TSTextStyles.title(
                              size: 13, color: TSColors.text)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheet).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TSColors.coral,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('close anyway',
                          style: TSTextStyles.title(
                              size: 13, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_options.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: TSColors.lime),
      );
    }
    final isHost = Supabase.instance.client.auth.currentUser?.id ==
        widget.trip.hostId;
    // Live squad stream — `widget.trip.squadMembers` is only a
    // snapshot from the initial trip fetch and doesn't reflect
    // members joining / voting afterwards.
    final liveSquad = ref
            .watch(squadStreamProvider(widget.trip.id))
            .valueOrNull ??
        widget.trip.squadMembers;
    // Build a trip with the live squad list so child widgets that
    // render squadMembers (tide strip, vote card bottom sheet, etc.)
    // stay in sync without threading a separate param everywhere.
    final liveTrip = widget.trip.copyWith(squadMembers: liveSquad);
    final squadSize = liveSquad.length;
    // Derive total votes from the sum of per-option vote_count
    // (works for in-app votes via the trigger AND for web votes via
    // the increment_option_vote RPC). `_votes.length` alone misses
    // web voters because they never insert into the votes table.
    final optionCountSum = _options.fold<int>(
      0,
      (acc, o) => acc + ((o['vote_count'] as int?) ?? 0),
    );
    final totalVotes =
        optionCountSum > _votes.length ? optionCountSum : _votes.length;

    return Column(children: [
      const SizedBox(height: 10),
      _VoteHeader(
        hasVoted: _hasVoted,
        totalVotes: totalVotes,
        squadSize: squadSize,
        tick: _voteTick,
      ),
      const SizedBox(height: 8),

      // ── Full-screen card pager ──────────────────────────────
      Expanded(
        child: PageView.builder(
          controller: _pager,
          itemCount: _options.length,
          onPageChanged: (i) {
            TSHaptics.selection();
            setState(() => _pageIndex = i);
          },
          itemBuilder: (_, i) {
            final opt = _options[i];
            final id = opt['id'] as String;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: i == _pageIndex ? 8 : 16,
                vertical: i == _pageIndex ? 0 : 8,
              ),
              child: _VoteCard(
                option: opt,
                totalVotes: totalVotes,
                isSelected: _selectedOptionId == id,
                hasVoted: _hasVoted,
                onPick: () {
                  if (_hasVoted) return;
                  TSHaptics.ctaTap();
                  setState(() => _selectedOptionId = id);
                },
              ),
            );
          },
        ),
      ),

      // ── Dot indicator for the pager ─────────────────────────
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == _pageIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _pageIndex
                        ? TSColors.lime
                        : TSColors.border2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
      ),

      // ── Live tide strip ─────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: _TideStrip(
          trip: liveTrip,
          options: _options,
          votes: _votes,
          tick: _voteTick,
        ),
      ),

      // ── Action buttons ──────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: _Actions(
          hasVoted: _hasVoted,
          isHost: isHost,
          casting: _casting,
          totalVotes: totalVotes,
          squadSize: squadSize,
          selectedOptionId: _selectedOptionId,
          onCastVote: _castVote,
          onClose: _closeVotingAndReveal,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────

class _VoteHeader extends StatelessWidget {
  const _VoteHeader({
    required this.hasVoted,
    required this.totalVotes,
    required this.squadSize,
    required this.tick,
  });
  final bool hasVoted;
  final int totalVotes, squadSize;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Text(hasVoted ? 'you voted ✦' : 'swipe · pick · vote',
            style: TSTextStyles.heading(size: 20, color: TSColors.lime)),
        const SizedBox(height: 4),
        Text('$totalVotes of $squadSize voted',
            style: TSTextStyles.caption(color: TSColors.muted)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FULL-SCREEN VOTE CARD (Destination Dossier)
// ─────────────────────────────────────────────────────────────

class _VoteCard extends StatelessWidget {
  const _VoteCard({
    required this.option,
    required this.totalVotes,
    required this.isSelected,
    required this.hasVoted,
    required this.onPick,
  });
  final Map<String, dynamic> option;
  final int totalVotes;
  final bool isSelected;
  final bool hasVoted;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final flag = (option['flag'] as String?) ?? '🌍';
    final destination = (option['destination'] as String?) ?? '';
    final country = (option['country'] as String?) ?? '';
    final tagline = (option['tagline'] as String?) ?? '';
    final voteCount = (option['vote_count'] as int?) ?? 0;
    final cost = option['estimated_cost_pp'];
    final compatScoreRaw = option['compatibility_score'];
    final compatPct = compatScoreRaw is num
        ? (compatScoreRaw * 100).round()
        : null;
    final highlights = (option['highlights'] as List?)?.cast<String>() ??
        const <String>[];

    final pctOfVotes = totalVotes == 0
        ? 0.0
        : (voteCount / totalVotes).clamp(0.0, 1.0).toDouble();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: TSColors.s1,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isSelected ? TSColors.lime : TSColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: TSColors.limeDim(0.22),
                blurRadius: 22,
                spreadRadius: -4,
              ),
          ],
        ),
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flag + destination
                    Text(flag, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(destination,
                        style: TSTextStyles.heading(
                            size: 34, color: TSColors.text)),
                    Text(country,
                        style: TSTextStyles.caption(color: TSColors.muted)),
                    const SizedBox(height: 14),

                    // Tagline
                    Text(tagline,
                        style: TSTextStyles.body(
                            size: 15, color: TSColors.text2)),
                    const SizedBox(height: 20),

                    // Stats pills
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (compatPct != null)
                        TSPill('✦ $compatPct% match',
                            variant: TSPillVariant.lime),
                      if (cost != null)
                        TSPill('~\$$cost / pp',
                            variant: TSPillVariant.muted),
                    ]),

                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('TOP PICKS',
                          style: TSTextStyles.label(
                              color: TSColors.muted, size: 10)),
                      const SizedBox(height: 8),
                      for (final h in highlights.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('·  ',
                                  style:
                                      TextStyle(color: TSColors.lime)),
                              Expanded(
                                child: Text(h,
                                    style: TSTextStyles.body(
                                        size: 13.5,
                                        color: TSColors.text2)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ]),
            ),
          ),

          const SizedBox(height: 12),
          // Per-option live vote bar (THE TIDE on a single card)
          if (totalVotes > 0) ...[
            Row(children: [
              Expanded(
                child: TheTide(progress: pctOfVotes, height: 6),
              ),
              const SizedBox(width: 10),
              Text('$voteCount',
                  style: TSTextStyles.title(size: 13, color: TSColors.lime)),
            ]),
            const SizedBox(height: 6),
          ],

          // "tap to pick" hint / selected badge
          if (!hasVoted)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? TSColors.limeDim(0.18)
                    : TSColors.s2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? TSColors.lime
                      : TSColors.border,
                ),
              ),
              child: Text(
                isSelected ? '✓ picked' : 'tap to pick',
                style: TSTextStyles.caption(
                    color: isSelected ? TSColors.lime : TSColors.muted),
              ),
            ),
          if (hasVoted && isSelected)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TSColors.limeDim(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TSColors.lime),
              ),
              child: Text('your vote',
                  style: TSTextStyles.caption(color: TSColors.lime)),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TIDE STRIP  (squad avatars + per-option bars)
// ─────────────────────────────────────────────────────────────

class _TideStrip extends StatelessWidget {
  const _TideStrip({
    required this.trip,
    required this.options,
    required this.votes,
    required this.tick,
  });

  final Trip trip;
  final List<Map<String, dynamic>> options;
  final List<Map<String, dynamic>> votes;
  final int tick;

  @override
  Widget build(BuildContext context) {
    // Build a map of user_id → SquadMember so we can render avatars
    // for the users who've voted (no names — just bloom + emoji).
    final votedUids = votes
        .map((v) => v['user_id'] as String?)
        .whereType<String>()
        .toSet();

    // Members go through two ordered buckets:
    //  1. voted (left, highlighted)
    //  2. pending (right, muted + pulse)
    final voted = trip.squadMembers
        .where((m) => m.userId != null && votedUids.contains(m.userId))
        .toList();
    final pending = trip.squadMembers
        .where((m) => m.userId == null || !votedUids.contains(m.userId))
        .toList();

    return SizedBox(
      height: 44,
      child: Row(children: [
        for (final m in voted)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: TheBloom(
              // Key by tick so the bloom replays for the newest voter.
              trigger: tick,
              child: _TideAvatar(
                emoji: m.emoji ?? '😎',
                active: true,
              ),
            ),
          ),
        for (final m in pending)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _TideAvatar(
              emoji: m.emoji ?? '😎',
              active: false,
            ),
          ),
      ]),
    );
  }
}

class _TideAvatar extends StatelessWidget {
  const _TideAvatar({required this.emoji, required this.active});
  final String emoji;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? TSColors.limeDim(0.15) : TSColors.s2,
        border: Border.all(
          color: active ? TSColors.lime : TSColors.border,
          width: active ? 1.2 : 1,
        ),
      ),
      child: Opacity(
        opacity: active ? 1 : 0.45,
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ACTIONS
// ─────────────────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  const _Actions({
    required this.hasVoted,
    required this.isHost,
    required this.casting,
    required this.totalVotes,
    required this.squadSize,
    required this.selectedOptionId,
    required this.onCastVote,
    required this.onClose,
  });

  final bool hasVoted;
  final bool isHost;
  final bool casting;
  final int totalVotes, squadSize;
  final String? selectedOptionId;
  final VoidCallback onCastVote;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!hasVoted) {
      return TSButton(
        label: selectedOptionId == null
            ? 'pick a destination'
            : 'cast your vote ✦',
        loading: casting,
        onTap: selectedOptionId == null || casting ? () {} : onCastVote,
      );
    }
    if (isHost) {
      return TSButton(
        label: totalVotes >= squadSize
            ? 'close + reveal 🎉'
            : 'close + reveal',
        variant: totalVotes >= squadSize
            ? TSButtonVariant.primary
            : TSButtonVariant.outline,
        loading: casting,
        onTap: casting ? () {} : onClose,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          'waiting on the squad…',
          style: TSTextStyles.caption(color: TSColors.muted),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.2.seconds),
    );
  }
}
