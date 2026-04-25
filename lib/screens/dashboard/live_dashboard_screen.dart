import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../core/effects.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/tappable.dart';
import '../../widgets/ts_scaffold.dart';
import '../../widgets/widgets.dart';

class LiveDashboardScreen extends ConsumerWidget {
  const LiveDashboardScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripStream  = ref.watch(tripStreamProvider(tripId));
    final squadStream = ref.watch(squadStreamProvider(tripId));
    final aiState     = ref.watch(aIGenerationProvider);

    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: TSAppBar(
        title: 'squad status 👀',
        trailing: const LiveBadge(),
      ),
      body: tripStream.when(
        data: (trip) => squadStream.when(
          data: (squad) => _Body(
            trip: trip,
            squad: squad,
            aiState: aiState,
            onGenerate: () async {
              TSHaptics.medium();
              await ref.read(aIGenerationProvider.notifier)
                  .generateOptions(tripId);
              if (context.mounted &&
                  ref.read(aIGenerationProvider).status ==
                      AIGenStatus.success) {
                context.push('/trip/$tripId/voting');
              }
            },
          ),
          loading: () => const _Loading(),
          error: (e, _) => _Error(e.toString()),
        ),
        loading: () => const _Loading(),
        error: (e, _) => _Error(e.toString()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.trip,
    required this.squad,
    required this.aiState,
    required this.onGenerate,
  });

  final Trip trip;
  final List<SquadMember> squad;
  final AIGenState aiState;
  final VoidCallback onGenerate;

  int get _responded =>
      squad.where((m) => m.status != MemberStatus.invited).length;
  double get _progress => squad.isEmpty ? 0 : _responded / squad.length;
  bool get _canGenerate => _responded >= 2;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TSSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats row ─────────────────────────────────
              Row(children: [
                _StatCard(
                  value: '$_responded/${squad.length}',
                  label: 'responded',
                  color: TSColors.lime,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  value: '87%',
                  label: 'compat.',
                  color: TSColors.purple,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  value: _avgBudget(),
                  label: 'avg budget',
                  color: TSColors.gold,
                ),
              ]).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // Progress
              TSProgressBar(progress: _progress),
              const SizedBox(height: 6),
              Text('$_responded/${squad.length} squad responded',
                style: TSTextStyles.caption()),

              const SizedBox(height: 20),

              // ── Squad list ────────────────────────────────
              const SectionLabel(label: 'who\'s responded?'),
              ...squad.map((m) => _MemberRow(member: m)
                  .animate().fadeIn(delay: 150.ms)),

              const SizedBox(height: 20),

              // ── Invite link ───────────────────────────────
              if (_responded < squad.length)
                _InviteCard(token: trip.inviteToken ?? ''),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // ── Bottom CTA ────────────────────────────────────────
      _BottomBar(
        canGenerate: _canGenerate,
        aiState: aiState,
        onGenerate: onGenerate,
      ),
    ]);
  }

  String _avgBudget() {
    final budgets = squad
        .where((m) => m.budgetMax != null)
        .map((m) => m.budgetMax!)
        .toList();
    if (budgets.isEmpty) return 'TBD';
    final avg = budgets.reduce((a, b) => a + b) ~/ budgets.length;
    return '\$${(avg / 1000).toStringAsFixed(1)}k';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value, required this.label, required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TSCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TSTextStyles.heading(size: 20, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TSTextStyles.label()),
        ]),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});
  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final responded = member.status != MemberStatus.invited;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TSCard(
        borderColor: responded ? TSColors.limeDim(0.18) : null,
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: TSColors.s3,
              shape: BoxShape.circle,
              border: Border.all(
                color: responded ? TSColors.limeDim(0.30) : TSColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(member.emoji ?? '😎',
              style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(member.nickname, style: TSTextStyles.title(size: 13)),
                if (member.role == MemberRole.host) ...[
                  const SizedBox(width: 6),
                  TSPill('Host', variant: TSPillVariant.muted, small: true),
                ],
              ]),
              Text(
                responded ? _timeAgo(member.respondedAt) : 'Invited',
                style: TSTextStyles.caption(),
              ),
            ],
          )),
          if (responded)
            TSPill('Done ✓', variant: TSPillVariant.lime, small: true)
          else
            TSPill('Waiting', variant: TSPillVariant.gold, small: true),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.token});
  final String token;

  String get _link => 'https://gettripsquad.com/join/?t=$token';

  @override
  Widget build(BuildContext context) {
    return TSCard(
      borderColor: TSColors.limeDim(0.20),
      child: Row(children: [
        const Text('🔗', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _link));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 2)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INVITE LINK', style: TSTextStyles.label()),
              Text('gettripsquad.com/join/?t=$token',
                style: TSTextStyles.body(color: TSColors.lime, size: 12),
                overflow: TextOverflow.ellipsis),
            ],
          ),
        )),
        GestureDetector(
          onTap: () {
            TSHaptics.medium();
            Share.share('join my trip on TripSquad! 🌍✈️\n$_link');
          },
          child: TSPill('share', variant: TSPillVariant.lime, small: true),
        ),
      ]),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canGenerate,
    required this.aiState,
    required this.onGenerate,
  });
  final bool canGenerate;
  final AIGenState aiState;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          TSSpacing.md, TSSpacing.sm, TSSpacing.md, TSSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, TSColors.bg],
        ),
      ),
      child: TSButton(
        label: aiState.status == AIGenStatus.loading
            ? 'scout is thinking...'
            : canGenerate
                ? 'let scout find options 🧭'
                : 'waiting for more responses...',
        onTap: canGenerate && aiState.status != AIGenStatus.loading
            ? onGenerate
            : null,
        variant: TSButtonVariant.primary,
        loading: aiState.status == AIGenStatus.loading,
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(_) => const Center(
    child: CircularProgressIndicator(color: TSColors.lime),
  );
}

class _Error extends StatelessWidget {
  const _Error(this.message);
  final String message;
  @override
  Widget build(_) => Center(
    child: Text(message, style: TSTextStyles.body(color: TSColors.coral)),
  );
}
