import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/widgets.dart';
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

  Future<void> _refresh() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    TSHaptics.light();
    try {
      await ref
          .read(recommendationsServiceProvider)
          .generateForTrip(widget.trip.id, regenerate: true);
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
          .read(recommendationsServiceProvider)
          .generateForTrip(widget.trip.id);
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

        return RefreshIndicator(
          color: TSColors.lime,
          backgroundColor: TSColors.s2,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (area != null) ...[
                AreaHeroCard(area: area)
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.04, end: 0),
                const SizedBox(height: 24),
              ],

              if (hotels.isNotEmpty) ...[
                _SectionHeader(
                  label: 'stays',
                  count: hotels.length,
                  trailing: _RefreshChip(
                    onTap: _refresh,
                    refreshing: _regenerating,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < hotels.length; i++) ...[
                  RecommendationCard(rec: hotels[i])
                      .animate()
                      .fadeIn(delay: (i * 40).ms),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
              ],

              if (restaurants.isNotEmpty) ...[
                _SectionHeader(
                  label: 'eats',
                  count: restaurants.length,
                ),
                const SizedBox(height: 12),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    this.trailing,
  });
  final String label;
  final int count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TSTextStyles.heading(size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          '· $count',
          style: TSTextStyles.caption(color: TSColors.muted),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
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
