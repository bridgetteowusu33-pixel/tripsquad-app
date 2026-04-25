import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/effects.dart';

/// The Dart splash is designed to be **visually continuous** with the
/// iOS launch storyboard. The launch image (a 240×64 wordmark centered
/// on a `#08080E` canvas) is positioned at the exact same screen
/// center as this splash's wordmark — so the wordmark appears to "stay
/// put" as iOS hands control to Flutter, and the icon + tagline fade
/// in around it.
///
/// Don't add an entry animation on the wordmark. That's the whole
/// point — it's already drawn by the time Flutter takes over.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _opacity = 1.0;

  // Geometry — kept in sync with the launch storyboard's centered
  // wordmark. These values are used to place the icon (above) and
  // tagline (below) relative to the fixed wordmark anchor.
  static const double _wordmarkFontSize = 36; // matches launch PNG
  static const double _wordmarkVisualHeight = 44;
  static const double _iconSize = 96;
  static const double _iconToWordmarkGap = 28;
  static const double _wordmarkToTaglineGap = 14;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    // Hold long enough for the icon + tagline to animate in around
    // the static wordmark, then fade out and route. Total to first
    // route ≈ 1.4s — same budget as before the continuity rewrite.
    await Future.delayed(1100.ms);
    if (!mounted) return;

    setState(() => _opacity = 0.0);
    await Future.delayed(250.ms);
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    if (isLoggedIn) {
      try {
        final uid = Supabase.instance.client.auth.currentUser!.id;
        await Supabase.instance.client.from('profiles').upsert(
          {'id': uid},
          onConflict: 'id',
        );
      } catch (_) {}
    }

    if (!mounted) return;
    if (!seen) {
      await prefs.setBool('onboarding_seen', true);
      context.go('/onboarding');
    } else if (isLoggedIn) {
      try {
        final uid = Supabase.instance.client.auth.currentUser!.id;
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('profile_complete')
            .eq('id', uid)
            .maybeSingle();
        final complete = profile?['profile_complete'] == true;
        if (!mounted) return;
        if (!complete) {
          context.go('/profile-setup');
        } else {
          context.go('/home');
        }
      } catch (_) {
        if (mounted) context.go('/home');
      }
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fixed offsets from screen centerY. Positive = below, negative =
    // above. Kept as pixel values (not fractional) so the layout is
    // stable across device sizes.
    //
    //   iconCenter    = centerY - (wordmark/2 + gap + icon/2)
    //   taglineCenter = centerY + (wordmark/2 + gap + tagline/2)
    final iconOffset = -(_wordmarkVisualHeight / 2 +
        _iconToWordmarkGap +
        _iconSize / 2);
    final taglineOffset = (_wordmarkVisualHeight / 2 +
        _wordmarkToTaglineGap +
        12); // ~half tagline visual height

    return Scaffold(
      backgroundColor: TSColors.bg,
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: 300.ms,
        child: Stack(children: [
          // Background atmosphere (unchanged)
          const Positioned.fill(
            child: TSMorphGradient(
              color1: TSColors.lime,
              color2: TSColors.purple,
              opacity: 0.05,
            ),
          ),
          const Positioned.fill(
            child: TSParticleField(
              color: TSColors.lime,
              count: 25,
              opacity: 0.08,
            ),
          ),
          Center(
            child: TSGlowOrb(
              color: TSColors.lime,
              size: 280,
              opacity: 0.12,
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms),

          // ── Wordmark — fixed at screen center, no entry animation
          //
          // The iOS launch storyboard draws the same wordmark at the
          // same coordinates. When Flutter takes over, this renders on
          // top at full opacity — so from the user's POV the wordmark
          // never moved or appeared; it was always there.
          const Center(child: _Wordmark()),

          // ── Icon above the wordmark
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, iconOffset),
              child: const _AppIcon(size: _iconSize),
            ),
          ),

          // ── Tagline below the wordmark
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, taglineOffset),
              child: Text(
                'where to next? 🌍',
                style: TSTextStyles.body(color: TSColors.muted),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 700.ms)
                  .slideY(
                    begin: 0.3,
                    delay: 700.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The fixed wordmark. Rendered in Clash Display Bold at 36pt,
/// matching the launch storyboard image exactly (same font, same
/// size, same colors, same kerning, **same non-italic squad**). No
/// animation — it inherits the pixels from the native launch screen.
///
/// Note: we intentionally drop the italic "squad" brand signature on
/// this surface only. The italic is synthesized by Flutter via an
/// affine skew, while the launch PNG is pre-rendered upright — the
/// transition between them would be a visible glyph-slant flash. The
/// italic signature is preserved on every other surface (home nav,
/// hero titles, empty states, etc.).
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Clash Display',
      fontWeight: FontWeight.w700,
      fontSize: 36,
      height: 1.0,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('Trip', style: style.copyWith(color: TSColors.text)),
        Text('squad', style: style.copyWith(color: TSColors.lime)),
      ],
    );
  }
}

/// App icon with fade + scale entry. Sits above the wordmark.
class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: TSRadius.icon,
        boxShadow: [
          BoxShadow(
            color: TSColors.limeDim(0.35),
            blurRadius: 48,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: TSRadius.icon,
        child: Image.asset(
          'assets/images/icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: TSColors.s2,
            child: const Center(
              child: Text('✈️', style: TextStyle(fontSize: 48)),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 350.ms, curve: Curves.easeOutCubic)
        .scale(
          begin: const Offset(0.6, 0.6),
          delay: 350.ms,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
