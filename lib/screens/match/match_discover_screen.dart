import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../widgets/widgets.dart';

class MatchDiscoverScreen extends ConsumerWidget {
  const MatchDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TSSpacing.md, TSSpacing.sm, TSSpacing.md, 0),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Solo Match', style: TSTextStyles.title(size: 20)),
                  Text('Find your travel companion', style: TSTextStyles.caption()),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TSColors.s2,
                    borderRadius: TSRadius.full,
                    border: Border.all(color: TSColors.border),
                  ),
                  child: Text('Filters', style: TSTextStyles.label()),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(TSSpacing.md),
              child: TSCard(
                borderColor: TSColors.blueDim(0.25),
                color: TSColors.blueDim(0.07),
                child: Row(children: [
                  const Text('🛡️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anonymous until both wave. Travel companion — not dating.',
                      style: TSTextStyles.body(color: TSColors.blue, size: 12),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(TSSpacing.md, 0, TSSpacing.md, TSSpacing.xxl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MatchCard(index: i)
                    .animate()
                    .fadeIn(delay: (i * 80).ms)
                    .slideY(begin: 0.1, delay: (i * 80).ms),
                childCount: 3,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.index});
  final int index;

  static const _data = [
    (emoji: '🌸', name: 'Jamie · 27', dest: '🇵🇹 Lisbon', overlap: '6 days overlap', vibes: ['🍜 Foodie', '🏛️ Culture'], compat: 0.92, bio: '"Love food markets, hidden cafés, and getting completely lost 🎵"'),
    (emoji: '⚡', name: 'Alex · 31', dest: '🇵🇹 Lisbon', overlap: '4 days overlap', vibes: ['🎉 Party', '🌆 City Break'], compat: 0.88, bio: '"Here for the nightlife, rooftops, and meeting interesting people."'),
    (emoji: '🌊', name: 'Sam · 25', dest: '🇵🇹 Lisbon', overlap: '7 days overlap', vibes: ['🏛️ Culture', '🍜 Foodie'], compat: 0.85, bio: '"Solo travel since 22. Always up for spontaneous detours."'),
  ];

  @override
  Widget build(BuildContext context) {
    final d = _data[index % _data.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TSCard(
        borderColor: index == 0 ? TSColors.purpleDim(0.28) : null,
        color: index == 0 ? TSColors.purpleDim(0.06) : TSColors.s2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  TSColors.purpleDim(0.3), TSColors.blueDim(0.3),
                ]),
              ),
              alignment: Alignment.center,
              child: Text(d.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: TSTextStyles.title(size: 14)),
                Text('${d.dest} · ${d.overlap}', style: TSTextStyles.caption()),
              ],
            )),
          ]),
          const SizedBox(height: 10),

          // Vibes
          Wrap(spacing: 6, children: d.vibes
              .map((v) => TSPill(v, variant: TSPillVariant.purple, small: true))
              .toList()),
          const SizedBox(height: 10),

          // Bio
          Container(
            padding: const EdgeInsets.all(TSSpacing.xs),
            decoration: BoxDecoration(
              color: TSColors.s3,
              borderRadius: TSRadius.xs,
              border: const Border(
                  left: BorderSide(color: TSColors.purple, width: 2)),
            ),
            child: Text(d.bio, style: TSTextStyles.body(size: 12)),
          ),
          const SizedBox(height: 10),

          // Compat bar
          Row(children: [
            Text('Travel compatibility', style: TSTextStyles.caption()),
            const Spacer(),
            Text('${(d.compat * 100).toInt()}%',
              style: TSTextStyles.label(color: TSColors.purple, size: 9)),
          ]),
          const SizedBox(height: 4),
          TSProgressBar(progress: d.compat, color: TSColors.purple),
          const SizedBox(height: 12),

          // Actions
          Row(children: [
            Expanded(
              child: TSButton(
                label: 'Skip',
                variant: TSButtonVariant.ghost,
                small: true,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TSButton(
                label: '👋 Wave',
                variant: TSButtonVariant.ai,
                small: true,
                onTap: () {},
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
