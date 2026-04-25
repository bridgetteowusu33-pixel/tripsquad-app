import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: TSColors.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          // App bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  TSSpacing.md, TSSpacing.sm, TSSpacing.md, 0),
              child: Row(children: [
                Text('Passport 📘', style: TSTextStyles.title(size: 20)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TSColors.purpleDim(0.12),
                    borderRadius: TSRadius.full,
                    border: Border.all(color: TSColors.purpleDim(0.28)),
                  ),
                  child: Text('Share poster',
                    style: TSTextStyles.label(color: TSColors.purple)),
                ),
              ]),
            ),
          ),

          // Passport card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(TSSpacing.md),
              child: profile.when(
                data: (p) => _PassportCard(
                  nickname: p?.nickname ?? 'Traveller',
                  stamps: p?.passportStamps ?? [],
                ).animate().fadeIn(delay: 100.ms),
                loading: () => const SizedBox(height: 180),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          // Squad passport
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TSSpacing.md, 0, TSSpacing.md, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionLabel(label: 'Squad Passport'),
                _SquadPassportCard().animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),
                const SectionLabel(label: 'Achievements'),
              ]),
            ),
          ),

          // Achievements
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                TSSpacing.md, 0, TSSpacing.md, TSSpacing.xxl),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _AchievementCard('🔥', '4 Week Saver', 'Squad Fund streak', TSColors.gold),
                _AchievementCard('📘', 'First Edition', 'Lisbon stamp #47', TSColors.purple),
                _AchievementCard('✈️', 'First Flight', 'First trip completed', TSColors.lime),
                _AchievementCard('👥', 'Squad Leader', 'Hosted 3 trips', TSColors.coral),
              ].map((w) => w.animate().fadeIn(delay: 300.ms)).toList()),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.nickname, required this.stamps});
  final String nickname;
  final List<String> stamps;

  static const _defaultStamps = [
    (flag: '🇵🇹', city: 'Lisbon'),
    (flag: '🇯🇵', city: 'Tokyo'),
    (flag: '🇨🇴', city: 'Medellín'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSSpacing.md),
      decoration: BoxDecoration(
        borderRadius: TSRadius.lg,
        border: Border.all(color: TSColors.purpleDim(0.30)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1028),
            const Color(0xFF0F0A1A),
          ],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Text('TripSquad Passport', style: TSTextStyles.label(color: TSColors.purple)),
        const SizedBox(height: 6),
        Text(nickname, style: TSTextStyles.heading(size: 22)),
        const SizedBox(height: 16),

        // Stamp grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
          children: [
            ..._defaultStamps.map((s) => _Stamp(flag: s.flag, city: s.city)),
            _EmptyStamp(),
          ],
        ),

        const SizedBox(height: 10),
        Text(
          '${_defaultStamps.length} countries · The Explorer',
          style: TSTextStyles.body(size: 11, color: TSColors.muted2),
        ),
      ]),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.flag, required this.city});
  final String flag, city;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: TSRadius.sm,
        border: Border.all(color: TSColors.purpleDim(0.30)),
        color: TSColors.purpleDim(0.08),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(city, style: TSTextStyles.label(size: 7),
            textAlign: TextAlign.center, maxLines: 1,
            overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _EmptyStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: TSRadius.sm,
        border: Border.all(
          color: TSColors.border2,
          style: BorderStyle.solid,
        ),
        color: TSColors.s3,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.add_rounded, color: TSColors.muted, size: 18),
        Text('Next?', style: TSTextStyles.label()),
      ]),
    );
  }
}

class _SquadPassportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TSCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Alex's Squad 👥", style: TSTextStyles.title(size: 14)),
              Text('3 trips · The Adventurers', style: TSTextStyles.caption()),
            ],
          )),
          TSPill('3 stamps', variant: TSPillVariant.lime, small: true),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          ...['🇵🇹','🇯🇵','🇨🇴'].map((f) => Container(
            width: 42, height: 42,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: TSRadius.sm,
              color: TSColors.purpleDim(0.10),
              border: Border.all(color: TSColors.purpleDim(0.28)),
            ),
            alignment: Alignment.center,
            child: Text(f, style: const TextStyle(fontSize: 20)),
          )),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              borderRadius: TSRadius.sm,
              color: TSColors.s3,
              border: Border.all(color: TSColors.border2, style: BorderStyle.solid),
            ),
            alignment: Alignment.center,
            child: const Text('?', style: TextStyle(color: TSColors.muted, fontSize: 18)),
          ),
        ]),
      ],
    ));
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard(this.emoji, this.title, this.subtitle, this.color);
  final String emoji, title, subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: TSRadius.sm,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TSTextStyles.label(color: color, size: 10)),
            Text(subtitle, style: TSTextStyles.caption()),
          ],
        )),
      ]),
    );
  }
}
