import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/effects.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/tappable.dart';

class VotingScreen extends ConsumerStatefulWidget {
  const VotingScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  String? _selectedOptionId;
  bool _casting = false;
  bool _hasVoted = false;

  Future<void> _castVote() async {
    if (_selectedOptionId == null) return;
    TSHaptics.heavy();
    setState(() => _casting = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.castVote(
        tripId: widget.tripId,
        optionId: _selectedOptionId!,
      );
      TSHaptics.success();
      // Refresh the Home resume-vote banner — vote just landed.
      ref.invalidate(myVotedTripIdsProvider);
      if (mounted) {
        setState(() => _hasVoted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('vote cast! 🗳️ waiting for the squad...',
              style: TSTextStyles.title(color: TSColors.bg, size: 14)),
            backgroundColor: TSColors.lime,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e)), backgroundColor: TSColors.coral),
        );
      }
    } finally {
      if (mounted) setState(() => _casting = false);
    }
  }

  Future<void> _closeVotingAndReveal() async {
    TSHaptics.heavy();
    setState(() => _casting = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      // Find the option with the most votes
      final options = await Supabase.instance.client
          .from('trip_options')
          .select()
          .eq('trip_id', widget.tripId)
          .order('vote_count', ascending: false);

      if (options.isEmpty) return;
      final winner = options.first;

      await tripService.setWinner(
        tripId: widget.tripId,
        destination: winner['destination'],
        flag: winner['flag'],
      );
      ref.invalidate(tripDetailProvider(widget.tripId));
      await Future.delayed(500.ms);
      if (mounted) context.push('/trip/${widget.tripId}/reveal');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e)), backgroundColor: TSColors.coral),
        );
      }
    } finally {
      if (mounted) setState(() => _casting = false);
    }
  }

  Future<void> _aiChoose() async {
    TSHaptics.medium();
    final winner = await ref.read(aiServiceProvider).aiTiebreaker(widget.tripId);
    if (mounted) {
      setState(() => _selectedOptionId = winner.id);
      _castVote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    final aiState = ref.watch(aIGenerationProvider);

    return Scaffold(
      backgroundColor: TSColors.bg,
      body: Stack(children: [
        // Ambient background
        const Positioned.fill(
          child: TSParticleField(color: TSColors.purple, count: 12, opacity: 0.05),
        ),

        SafeArea(
          child: tripAsync.when(
            data: (trip) => Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(TSSpacing.lg, TSSpacing.md, TSSpacing.lg, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: TSColors.text, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('vote now 🗳️',
                        style: TSTextStyles.heading(size: 22)),
                      Text('pick your fave destination',
                        style: TSTextStyles.caption(color: TSColors.muted)),
                    ],
                  )),
                  const LiveBadge(),
                ]),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: TSSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (aiState.status == AIGenStatus.loading)
                        _AILoadingCard()
                      else ...[
                        Text(
                          'scout found ${trip.options.length} options from your squad\'s vibes ✨',
                          style: TSTextStyles.body(color: TSColors.muted),
                        ),
                        const SizedBox(height: 16),
                        ...trip.options.asMap().entries.map((e) {
                          final opt = e.value;
                          final sel = _selectedOptionId == opt.id;
                          return _VoteCard(
                            option: opt,
                            selected: sel,
                            onTap: () {
                              TSHaptics.selection();
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              setState(() =>
                                _selectedOptionId = sel ? null : opt.id);
                            },
                          ).animate().fadeIn(delay: (e.key * 120).ms)
                              .slideY(begin: 0.08, delay: (e.key * 120).ms);
                        }),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ]),
            loading: () => const Center(
              child: CircularProgressIndicator(color: TSColors.lime),
            ),
            error: (e, _) => Center(
              child: Text(e.toString(), style: TSTextStyles.body(color: TSColors.coral)),
            ),
          ),
        ),

        // Bottom CTAs — floating over content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(TSSpacing.md, TSSpacing.md, TSSpacing.md, TSSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TSColors.bg.withOpacity(0),
                  TSColors.bg.withOpacity(0.9),
                  TSColors.bg,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: Column(children: [
              if (!_hasVoted) ...[
                // Vote button
                TSTappable(
                  onTap: _selectedOptionId != null && !_casting ? _castVote : null,
                  child: AnimatedContainer(
                    duration: 200.ms,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedOptionId != null ? TSColors.lime : TSColors.s3,
                      borderRadius: TSRadius.full,
                      boxShadow: _selectedOptionId != null ? [
                        BoxShadow(color: TSColors.limeDim(0.3), blurRadius: 16),
                      ] : null,
                    ),
                    child: Center(
                      child: _casting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: TSColors.bg),
                            )
                          : Text(
                              _selectedOptionId == null
                                  ? 'pick a destination first'
                                  : 'cast my vote ✦',
                              style: TSTextStyles.title(
                                color: _selectedOptionId != null
                                    ? TSColors.bg : TSColors.muted,
                                size: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ] else ...[
                // Host has voted — show close voting button
                TSTappable(
                  onTap: !_casting ? _closeVotingAndReveal : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: TSColors.lime,
                      borderRadius: TSRadius.full,
                      boxShadow: [
                        BoxShadow(color: TSColors.limeDim(0.3), blurRadius: 16),
                      ],
                    ),
                    child: Center(
                      child: _casting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: TSColors.bg),
                            )
                          : Text(
                              'close voting & reveal winner 🎉',
                              style: TSTextStyles.title(color: TSColors.bg, size: 15),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'your vote is in. wait for the squad or close now.',
                  style: TSTextStyles.caption(color: TSColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (!_hasVoted) ...[
                const SizedBox(height: 8),
                TSTappable(
                  onTap: _aiChoose,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: TSColors.purpleDim(0.1),
                      borderRadius: TSRadius.full,
                      border: Border.all(color: TSColors.purpleDim(0.25)),
                    ),
                    child: Text(
                      '🧭 let scout decide',
                      style: TSTextStyles.title(color: TSColors.purple, size: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  VOTE CARD — taller, more visual, dramatic selection
// ─────────────────────────────────────────────────────────────
class _VoteCard extends StatelessWidget {
  const _VoteCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TripOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TSTappable(
        onTap: onTap,
        scaleOnPress: 0.98,
        child: AnimatedContainer(
          duration: 250.ms,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? TSColors.limeDim(0.06) : TSColors.s2,
            borderRadius: TSRadius.lg,
            border: Border.all(
              color: selected ? TSColors.limeDim(0.4) : TSColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? TSColors.limeDim(0.15) : Colors.transparent,
                blurRadius: selected ? 20 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(TSSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flag + destination + selection indicator
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(option.flag, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${option.destination}, ${option.country}',
                            style: TSTextStyles.heading(size: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(option.tagline,
                            style: TSTextStyles.body(color: TSColors.muted, size: 13)),
                        ],
                      )),
                      // Selection circle
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: selected ? TSColors.lime : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? TSColors.lime : TSColors.border2,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selected ? TSColors.limeDim(0.4) : Colors.transparent,
                              blurRadius: selected ? 8 : 0,
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: TSColors.bg, size: 16)
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description if available
                  if (option.description != null && option.description!.isNotEmpty) ...[
                    Text(option.description!,
                      style: TSTextStyles.body(color: TSColors.text2, size: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Pills row
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (option.estimatedCostPp != null)
                      TSPill('~\$${option.estimatedCostPp}',
                        variant: TSPillVariant.muted, small: true),
                    if (option.durationDays != null)
                      TSPill('${option.durationDays} days',
                        variant: TSPillVariant.muted, small: true),
                    ...?option.vibeMatch?.take(3).map(
                      (v) => TSPill(v, variant: TSPillVariant.lime, small: true),
                    ),
                  ]),
                ],
              ),
            ),

            // Compatibility bar
            Container(
              padding: const EdgeInsets.fromLTRB(TSSpacing.md, 0, TSSpacing.md, TSSpacing.md),
              child: Column(children: [
                if (option.compatibilityScore != null) ...[
                  Row(children: [
                    Text('squad compatibility', style: TSTextStyles.caption(color: TSColors.muted)),
                    const Spacer(),
                    Text(
                      '${(option.compatibilityScore! * 100).toInt()}%',
                      style: TSTextStyles.label(
                        color: selected ? TSColors.lime : TSColors.purple,
                        size: 10,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  TSProgressBar(
                    progress: option.compatibilityScore!.clamp(0.0, 1.0),
                    color: selected ? TSColors.lime : TSColors.purple,
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AI LOADING — cooking animation
// ─────────────────────────────────────────────────────────────
class _AILoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing orb
          Stack(
            alignment: Alignment.center,
            children: [
              TSGlowOrb(color: TSColors.purple, size: 160, opacity: 0.15),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    TSColors.lime,
                    TSColors.purpleDim(0.3),
                  ]),
                ),
              ).animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1500.ms, color: Colors.white24)
                .rotate(duration: 4000.ms),
            ],
          ),

          const SizedBox(height: 24),

          TSShimmerText(
            text: 'scout is thinking...',
            style: TSTextStyles.heading(size: 20),
            shimmerColor: TSColors.purple,
          ),

          const SizedBox(height: 8),

          Text('analysing your squad\'s vibes and budgets',
            style: TSTextStyles.body(color: TSColors.muted, size: 13),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          ...[
            ('scout is reading preferences', true),
            ('matching budgets and vibes', true),
            ('scout is building proposals', false),
            ('ranking by squad compatibility', false),
          ].asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e.value.$2 ? TSColors.lime : TSColors.s3,
                  ),
                ),
                const SizedBox(width: 10),
                Text(e.value.$1,
                  style: TSTextStyles.body(
                    color: e.value.$2 ? TSColors.text2 : TSColors.muted,
                    size: 13,
                  )),
              ],
            ).animate().fadeIn(delay: (e.key * 400).ms),
          )),
        ],
      ),
    );
  }
}
