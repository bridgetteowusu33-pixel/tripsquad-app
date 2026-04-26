import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/effects.dart';
import '../../core/haptics.dart';
import '../../widgets/widgets.dart';
import '../../widgets/ts_scaffold.dart';

class _Slide {
  final String emoji;
  final String title;
  final String titleAccent;  // italic lime part
  final String body;
  final Color glow;

  const _Slide({
    required this.emoji,
    required this.title,
    required this.titleAccent,
    required this.body,
    required this.glow,
  });
}

const _slides = [
  _Slide(
    emoji: '🗳️',
    title: 'vote on where',
    titleAccent: "you're going",
    body: "everyone votes. most votes wins. no more 47-message group chats going nowhere 💀",
    glow: TSColors.lime,
  ),
  _Slide(
    emoji: '🧭',
    title: 'scout builds your',
    titleAccent: 'perfect trip',
    body: "with your squad — or solo. scout blends vibes, budgets, and preferences into tailored proposals ✨",
    glow: TSColors.purple,
  ),
  _Slide(
    emoji: '💰',
    title: 'save together,',
    titleAccent: 'go together',
    body: "track everyone's savings in one place. squad fund keeps the whole group accountable 💪",
    glow: TSColors.gold,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  void _next() {
    TSHaptics.medium();
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(duration: 400.ms, curve: Curves.easeInOut);
    } else {
      context.go('/auth');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TSScaffold(
      style: TSBackgroundStyle.hero,
      body: SafeArea(
        child: Column(children: [
          // Skip
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
              child: GestureDetector(
                onTap: () => context.go('/auth'),
                child: Text('skip', style: TSTextStyles.label(color: TSColors.muted)),
              ),
            ),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _slides.length,
              itemBuilder: (context, i) => _SlidePage(slide: _slides[i]),
            ),
          ),

          // Dots + CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(TSSpacing.lg, 0, TSSpacing.lg, TSSpacing.xxl),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) => AnimatedContainer(
                  duration: 250.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: TSRadius.full,
                    color: i == _page ? TSColors.lime : TSColors.s3,
                  ),
                )),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: TSRadius.md,
                  boxShadow: [
                    BoxShadow(
                      color: TSColors.lime.withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: TSButton(
                  label: _page < _slides.length - 1 ? 'next →' : "let's go 🙌",
                  onTap: _next,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glow + emoji
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  slide.glow.withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
            Text(slide.emoji, style: const TextStyle(fontSize: 72))
                .animate(key: ValueKey(slide.emoji))
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.7, 0.7)),
          ]),

          const SizedBox(height: 32),

          // Title
          Column(children: [
            Text(slide.title, style: TSTextStyles.heading(size: 28),
              textAlign: TextAlign.center),
            TSShimmerText(
              text: slide.titleAccent,
              style: TSTextStyles.heading(size: 28, color: slide.glow)
                  .copyWith(fontStyle: FontStyle.italic),
              shimmerColor: Colors.white,
              textAlign: TextAlign.center,
            ),
          ]).animate(key: ValueKey(slide.title)).fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          Text(
            slide.body,
            style: TSTextStyles.body(),
            textAlign: TextAlign.center,
          ).animate(key: ValueKey(slide.body)).fadeIn(delay: 250.ms),
        ],
      ),
    );
  }
}
