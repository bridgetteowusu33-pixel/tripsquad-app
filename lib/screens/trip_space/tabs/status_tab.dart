import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import 'squad_tab.dart' show DeleteTripRow;
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/widgets.dart';

/// Collecting-phase status: shows squad response progress in realtime
/// and the host's "✨ generate options" CTA that transitions the trip
/// to the voting phase.
class StatusTab extends ConsumerStatefulWidget {
  const StatusTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends ConsumerState<StatusTab> {
  Map<String, String?> _avatarByUid = {};
  String _lastFetchedFor = '';
  bool _generating = false;

  Future<void> _maybeLoadAvatars(List<SquadMember> squad) async {
    final ids = squad
        .map((m) => m.userId)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final key = ids.join(',');
    if (key == _lastFetchedFor) return;
    _lastFetchedFor = key;
    if (ids.isEmpty) return;
    final profiles =
        await ref.read(dmServiceProvider).fetchProfilesByIds(ids);
    if (!mounted) return;
    setState(() {
      _avatarByUid = {
        for (final e in profiles.entries)
          e.key: e.value['avatar_url'] as String?,
      };
    });
  }

  Future<void> _generate() async {
    TSHaptics.ctaCommit();
    setState(() => _generating = true);
    try {
      // 1. AI generates 3 destination options from submitted prefs.
      await ref.read(aIGenerationProvider.notifier)
          .generateOptions(widget.trip.id);
      // 2. Flip trip to voting phase so the vote tab appears.
      await ref.read(tripServiceProvider)
          .updateStatus(widget.trip.id, TripStatus.voting);
      ref.invalidate(tripDetailProvider(widget.trip.id));
      ref.invalidate(myTripsProvider);
      TSHaptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('couldn\'t generate — ${humanizeError(e)}'),
            backgroundColor: TSColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final squadAsync = ref.watch(squadStreamProvider(widget.trip.id));
    final meUid = Supabase.instance.client.auth.currentUser?.id;
    final isHost = meUid != null && widget.trip.hostId == meUid;
    // Fall back to the embedded squad list if realtime hiccups — the
    // user shouldn't see a cryptic "channelError" just because the
    // websocket handshake failed.
    final squad = squadAsync.maybeWhen(
      data: (s) => s,
      error: (_, __) => widget.trip.squadMembers,
      orElse: () => widget.trip.squadMembers,
    );
    return squadAsync.when(
      loading: () => squad.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: TSColors.lime))
          : _content(context, squad, isHost),
      error: (_, __) => _content(context, squad, isHost),
      data: (s) => _content(context, s, isHost),
    );
  }

  Widget _content(
      BuildContext context, List<SquadMember> squad, bool isHost) {
    return Builder(builder: (context) {
        _maybeLoadAvatars(squad);
        final submitted =
            squad.where((m) => m.status != MemberStatus.invited).length;
        final total = squad.length;
        final pending = total - submitted;
        final progress = total > 0 ? submitted / total : 0.0;
        final canGenerate = isHost && submitted >= 1;

        return Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              TSCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('squad progress',
                          style: TSTextStyles.heading(size: 18)),
                      const SizedBox(height: 10),
                      TSProgressBar(progress: progress),
                      const SizedBox(height: 6),
                      Text('$submitted of $total responded',
                          style: TSTextStyles.caption()),
                    ]),
              ),
              const SizedBox(height: 12),
              for (final m in squad)
                _SquadRow(
                  member: m,
                  photoUrl: m.userId == null ? null : _avatarByUid[m.userId!],
                ),
              const SizedBox(height: 32),
              // Host-only delete affordance. Lives on this tab so a host
              // who started a group trip nobody answered can wind it
              // down without committing to generate options.
              if (isHost) DeleteTripRow(trip: widget.trip),
              const SizedBox(height: 24),
            ]),
          ),
          // ── Host CTA footer ─────────────────────────────────
          if (isHost)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      submitted == 0
                          ? "fill in your prefs first — tap your row above"
                          : pending > 0
                              ? '$pending still filling — you can start now or wait'
                              : "everyone's in — ready when you are",
                      style: TSTextStyles.caption(color: TSColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TSButton(
                    label: _generating
                        ? 'generating…'
                        : '✨ generate trip options',
                    onTap: canGenerate && !_generating ? _generate : null,
                    loading: _generating,
                  )
                      .animate(target: canGenerate ? 1 : 0)
                      .scaleXY(begin: 0.97, end: 1.0, duration: 220.ms),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}

class _SquadRow extends StatelessWidget {
  const _SquadRow({required this.member, required this.photoUrl});
  final SquadMember member;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final submitted = member.status != MemberStatus.invited;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        TSAvatar(
          emoji: member.emoji ?? '😎',
          photoUrl: photoUrl,
          size: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(member.nickname, style: TSTextStyles.body()),
        ),
        TSPill(
          submitted ? '✓ in' : 'waiting',
          variant: submitted ? TSPillVariant.lime : TSPillVariant.muted,
          small: true,
        ),
      ]),
    );
  }
}
