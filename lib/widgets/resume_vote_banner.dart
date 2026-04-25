import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────
//  RESUME ACTION BANNER
//
//  A pinned lime banner on Home for any trip that *needs you right
//  now*. One card per pending action; stacked.
//
//  Covered states:
//   1. voting, you haven't voted                     → "vote needed"
//   2. host, collecting, ≥2 members submitted        → "ready to generate"
//   3. member, collecting, you haven't submitted     → "share your prefs"
//   4. revealed, you haven't seen the reveal yet (v2 — not yet tracked)
//
//  Persistent — no dismiss button. Card disappears when the state
//  resolves itself (you voted, options generated, prefs submitted).
// ─────────────────────────────────────────────────────────────

enum _ActionKind { vote, generate, submitPrefs }

class _PendingAction {
  _PendingAction({
    required this.trip,
    required this.kind,
    required this.label,
    required this.sub,
  });
  final Trip trip;
  final _ActionKind kind;
  final String label;
  final String sub;
}

/// Computes the list of trips that need the user's attention right now.
/// Watches [myTripsProvider] + [myVotedTripIdsProvider] + the current user id.
final pendingActionsProvider = Provider<List<_PendingAction>>((ref) {
  final trips = ref.watch(myTripsProvider).valueOrNull ?? const <Trip>[];
  final voted = ref.watch(myVotedTripIdsProvider).valueOrNull ?? <String>{};
  final uid = Supabase.instance.client.auth.currentUser?.id;
  final actions = <_PendingAction>[];

  for (final t in trips) {
    final isHost = uid != null && t.hostId == uid;

    if (t.status == TripStatus.voting && !voted.contains(t.id)) {
      actions.add(_PendingAction(
        trip: t,
        kind: _ActionKind.vote,
        label: 'VOTE NEEDED',
        sub: "your squad's waiting on you",
      ));
      continue;
    }

    if (t.status == TripStatus.collecting) {
      final submitted = t.squadMembers
          .where((m) => m.status != MemberStatus.invited)
          .length;
      // Host view — enough prefs in to generate?
      if (isHost && submitted >= 2) {
        actions.add(_PendingAction(
          trip: t,
          kind: _ActionKind.generate,
          label: 'READY TO GENERATE',
          sub: "$submitted of ${t.squadMembers.length} submitted · scout can run",
        ));
        continue;
      }
      // Squad member view — they haven't submitted theirs yet.
      if (!isHost && uid != null) {
        final me = t.squadMembers.firstWhere(
          (m) => m.userId == uid,
          orElse: () => SquadMember(
            id: '',
            tripId: t.id,
            nickname: '',
            status: MemberStatus.voted, // placeholder = don't nag
          ),
        );
        if (me.id.isNotEmpty && me.status == MemberStatus.invited) {
          actions.add(_PendingAction(
            trip: t,
            kind: _ActionKind.submitPrefs,
            label: 'SHARE YOUR PREFS',
            sub: "${t.hostId == uid ? 'you' : 'the host'} is waiting",
          ));
          continue;
        }
      }
    }
  }

  return actions;
});

/// Pinned lime action banner on Home.
class ResumeVoteBanner extends ConsumerWidget {
  const ResumeVoteBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(pendingActionsProvider);
    if (actions.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(TSSpacing.md, 6, TSSpacing.md, 6),
      child: Column(
        children: [
          for (final a in actions) _ActionCard(action: a),
        ],
      ),
    );
  }
}

class _ActionCard extends ConsumerStatefulWidget {
  const _ActionCard({required this.action});
  final _PendingAction action;

  @override
  ConsumerState<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends ConsumerState<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _handle() async {
    final a = widget.action;
    switch (a.kind) {
      case _ActionKind.vote:
      case _ActionKind.submitPrefs:
        TSHaptics.ctaCommit();
        context.push('/trip/${a.trip.id}/space');
        break;
      case _ActionKind.generate:
        // Generate options right from the banner. Closes the loop in
        // one tap instead of making the host dig into the dashboard.
        if (_busy) return;
        TSHaptics.ctaCommit();
        setState(() => _busy = true);
        try {
          await ref.read(aIGenerationProvider.notifier)
              .generateOptions(a.trip.id);
          // myTrips stream will update; banner will refresh.
          ref.invalidate(myTripsProvider);
          if (mounted) {
            context.push('/trip/${a.trip.id}/space');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('scout hit a snag — $e',
                    style: TSTextStyles.body(color: TSColors.bg, size: 13)),
                backgroundColor: TSColors.coral,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _busy = false);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    final t = a.trip;
    final title = t.selectedDestination ?? t.name;
    final emoji = t.selectedFlag ??
        (a.kind == _ActionKind.vote
            ? '🗳️'
            : a.kind == _ActionKind.generate
                ? '🧭'
                : '✍️');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handle,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) {
            final glow = 8 + _pulse.value * 6;
            return Container(
              decoration: BoxDecoration(
                color: TSColors.s1,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TSColors.lime, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: TSColors.lime.withOpacity(
                        0.18 + _pulse.value * 0.12),
                    blurRadius: glow,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.label,
                        style: TSTextStyles.label(
                            color: TSColors.lime, size: 9)),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TSTextStyles.title(size: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(a.sub,
                        style:
                            TSTextStyles.caption(color: TSColors.muted2)),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: TSColors.lime,
                    strokeWidth: 2,
                  ),
                )
              else
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(_pulse.value * 3, 0),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: TSColors.lime,
                      size: 22,
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
