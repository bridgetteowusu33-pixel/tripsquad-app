import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../widgets/widgets.dart';

class _Mode {
  final String emoji;
  final String title;
  final String desc;
  final Color accent;
  final String route;
  final String? badge;
  const _Mode({
    required this.emoji, required this.title, required this.desc,
    required this.accent, required this.route, this.badge,
  });
}

const _modes = [
  _Mode(
    emoji: '👥', title: 'Group Trip',
    desc: 'Squad-first AI planning with democratic voting. The full TripSquad experience.',
    accent: TSColors.lime, route: '/trip/create', badge: 'Most popular',
  ),
  _Mode(
    emoji: '🧳', title: 'Solo Explorer',
    desc: 'AI builds a tailored personal itinerary based purely on your preferences.',
    accent: TSColors.blue, route: '/solo/setup',
  ),
  _Mode(
    emoji: '🤝', title: 'Solo Match',
    desc: 'Find a travel companion headed to the same destination. Anonymous until you both wave.',
    accent: TSColors.purple, route: '/match', badge: '✦ New',
  ),
];

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: TSSpacing.sm),

              Text('How are you', style: TSTextStyles.heading(size: 28)),
              Text(
                'traveling?',
                style: TSTextStyles.heading(size: 28, color: TSColors.lime)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your mode — switch any time.',
                style: TSTextStyles.body(color: TSColors.muted),
              ),

              const SizedBox(height: 28),

              ...List.generate(_modes.length, (i) {
                final m = _modes[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ModeCard(mode: m, selected: i == 0)
                      .animate()
                      .fadeIn(delay: (200 + i * 100).ms)
                      .slideY(begin: 0.15, delay: (200 + i * 100).ms),
                );
              }),

              const Spacer(),

              Text(
                'You can switch modes at any time from Settings.',
                style: TSTextStyles.caption(),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.selected});
  final _Mode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(mode.route),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(TSSpacing.md),
        decoration: BoxDecoration(
          color: selected ? mode.accent.withOpacity(0.08) : TSColors.s1,
          borderRadius: TSRadius.lg,
          border: Border.all(
            color: selected ? mode.accent.withOpacity(0.35) : TSColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Text(mode.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: TSSpacing.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(mode.title, style: TSTextStyles.title()),
                if (mode.badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: mode.accent.withOpacity(0.12),
                      borderRadius: TSRadius.full,
                      border: Border.all(color: mode.accent.withOpacity(0.30)),
                    ),
                    child: Text(mode.badge!, style: TSTextStyles.label(color: mode.accent, size: 9)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text(mode.desc, style: TSTextStyles.body(size: 12)),
            ],
          )),
          if (selected)
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: mode.accent, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: TSColors.bg, size: 14),
            ),
        ]),
      ),
    );
  }
}
