import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/haptics.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  REVEAL CINEMATIC
//
//  The 4-second film that plays when a trip transitions from
//  voting → revealed. From the UX redesign (§17):
//
//    0.0s  fade to black, hide UI
//    0.4s  small lime dot pulses at centre
//    0.8s  "your squad has decided." appears above the dot
//    1.2s  dot stretches into a short lime vertical line
//    1.6s  destination name kinetic-types in, character by char
//    2.4s  flag emoji rises from below, floats into place
//    2.8s  destination photo crossfades in behind the type
//    3.2s  dates appear in muted text
//    3.4s  lime glow pulses once around the screen edges
//    3.6s  squad avatars rise from below in a curved arc
//    3.9s  (handoff — host screen now ready)
//
//  This widget is pure play-and-finish. It calls [onFinished] at
//  4.1s so the host screen can slide in the share / itinerary UI.
// ─────────────────────────────────────────────────────────────

class RevealCinematic extends StatefulWidget {
  const RevealCinematic({
    super.key,
    required this.destination,
    required this.flag,
    required this.dates,
    required this.squadEmojis,
    this.photoUrl,
    this.onFinished,
  });

  final String destination;
  final String flag;
  final String dates;
  final List<String> squadEmojis;
  final String? photoUrl;
  final VoidCallback? onFinished;

  @override
  State<RevealCinematic> createState() => _RevealCinematicState();
}

class _RevealCinematicState extends State<RevealCinematic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // Haptic beats fired at specific times; flags prevent re-fire.
  final Set<String> _firedBeats = {};
  int _lastCharTyped = -1;

  static const _totalMs = 4100;

  // Beat timings (ms from start)
  static const _pulseAtMs = 400;
  static const _lineAtMs = 1200;
  static const _typeStartMs = 1600;
  static const _typeCharIntervalMs = 45;
  static const _flagAtMs = 2400;
  static const _datesAtMs = 3200;
  static const _arcStartMs = 3600;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )
      ..addListener(_onTick)
      ..forward();

    // Completion handler
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished?.call();
      }
    });
  }

  void _onTick() {
    final nowMs = (_c.value * _totalMs).round();

    // Haptic ladder — fire once per beat.
    void beat(String id, int at, void Function() action) {
      if (nowMs >= at && !_firedBeats.contains(id)) {
        _firedBeats.add(id);
        action();
      }
    }

    beat('pulse', _pulseAtMs, () => TSHaptics.revealBeat(0));
    beat('line', _lineAtMs, () => TSHaptics.revealBeat(1));
    beat('flag', _flagAtMs, () => TSHaptics.revealBeat(3));
    beat('arc', _arcStartMs + 200, () => TSHaptics.revealBeat(4));

    // Kinetic type: one selection tick per character.
    if (nowMs >= _typeStartMs) {
      final total = widget.destination.length;
      final typed = ((nowMs - _typeStartMs) / _typeCharIntervalMs)
          .floor()
          .clamp(0, total);
      if (typed > _lastCharTyped && typed <= total) {
        _lastCharTyped = typed;
        if (typed > 0 && typed < total) TSHaptics.revealBeat(2);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => _frame(context),
    );
  }

  Widget _frame(BuildContext context) {
    final nowMs = (_c.value * _totalMs).round();

    // Ambient background photo crossfade (2.8s → 3.4s). Kept low-sat
    // via colour filter + opacity so it backs the text, not competes.
    final photoT = _window(nowMs, 2800, 3400);
    // Edge glow at 3.4s
    final glowT = _bell(nowMs, 3400, 3800);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: TSColors.bg),

        if (widget.photoUrl != null && photoT > 0)
          Opacity(
            opacity: (0.32 * photoT).clamp(0.0, 1.0),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF080814),
                BlendMode.saturation,
              ),
              child: CachedNetworkImage(
                imageUrl: widget.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(),
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

        // Legibility gradient over the photo
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC08080E),
                  Color(0x8008080E),
                  Color(0xE608080E),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Edge glow
        if (glowT > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: TSColors.lime.withOpacity(0.22 * glowT),
                      blurRadius: 80 * glowT,
                      spreadRadius: -40 + 20 * glowT,
                    ),
                  ],
                ),
              ),
            ),
          ),

        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _topCaption(nowMs),
              const SizedBox(height: 18),
              _dotAndLineAndType(nowMs),
              const SizedBox(height: 12),
              _flagAndDates(nowMs),
              const Spacer(),
              _squadArc(nowMs),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }

  // "your squad has decided." (fades in 0.8s, holds)
  Widget _topCaption(int nowMs) {
    final t = _window(nowMs, 800, 1200);
    return Opacity(
      opacity: t,
      child: Text(
        'your squad has decided',
        style: TSTextStyles.label(color: TSColors.muted2, size: 11),
      ),
    );
  }

  // Pulse → line → kinetic-typed destination. Three phases drawn
  // in the same slot so transitions feel like one motion.
  Widget _dotAndLineAndType(int nowMs) {
    // Pulse (0.4s → 1.2s) — dot grows then gathers.
    final pulseT = _window(nowMs, 400, 900);
    final pulseFadeOut = 1 - _window(nowMs, 1100, 1300);

    // Line (1.2s → 1.6s) — vertical line forms.
    final lineT = _window(nowMs, 1200, 1600);
    final lineFadeOut = 1 - _window(nowMs, 1500, 1700);

    // Type (1.6s onward)
    final typeT = _clamp(
        (nowMs - _typeStartMs) / (widget.destination.length * _typeCharIntervalMs)
            .clamp(1, double.infinity),
        0.0,
        1.0);
    final typedChars =
        (typeT * widget.destination.length).floor();
    final typedText =
        widget.destination.substring(0, typedChars.clamp(0, widget.destination.length));

    return SizedBox(
      height: 110,
      child: Stack(alignment: Alignment.center, children: [
        // Dot
        if (pulseFadeOut > 0)
          Opacity(
            opacity: pulseFadeOut.clamp(0.0, 1.0),
            child: Container(
              width: 8 + pulseT * 12,
              height: 8 + pulseT * 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TSColors.lime,
                boxShadow: [
                  BoxShadow(
                    color: TSColors.lime.withOpacity(0.55 * pulseT),
                    blurRadius: 24 * pulseT,
                    spreadRadius: 2 + 4 * pulseT,
                  ),
                ],
              ),
            ),
          ),

        // Line (vertical stretch of the dot)
        if (lineT > 0 && lineFadeOut > 0)
          Opacity(
            opacity: lineFadeOut.clamp(0.0, 1.0),
            child: Container(
              width: 4,
              height: 60 * lineT,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TSColors.purple, TSColors.lime],
                ),
              ),
            ),
          ),

        // Destination name kinetic-typed
        if (nowMs >= _typeStartMs)
          Text(
            typedText,
            style: TSTextStyles.displayHero(
              size: _sizeForLength(widget.destination.length),
              color: TSColors.text,
            ),
            textAlign: TextAlign.center,
          ),
      ]),
    );
  }

  double _sizeForLength(int n) {
    if (n <= 6) return 64;
    if (n <= 10) return 52;
    if (n <= 14) return 42;
    return 34;
  }

  // Flag rises from below (2.4s → 2.8s). Dates fade in at 3.2s.
  Widget _flagAndDates(int nowMs) {
    final flagT = _window(nowMs, _flagAtMs, _flagAtMs + 400);
    final datesT = _window(nowMs, _datesAtMs, _datesAtMs + 400);
    return Column(children: [
      Opacity(
        opacity: flagT,
        child: Transform.translate(
          offset: Offset(0, (1 - flagT) * 30),
          child: Text(
            widget.flag,
            style: const TextStyle(fontSize: 44, height: 1),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Opacity(
        opacity: datesT,
        child: Text(
          widget.dates,
          style: TSTextStyles.body(color: TSColors.text2, size: 14),
        ),
      ),
    ]);
  }

  // Squad avatars rise in a curved arc (3.6s → 3.9s+).
  Widget _squadArc(int nowMs) {
    if (widget.squadEmojis.isEmpty) return const SizedBox();
    final startMs = _arcStartMs;
    final all = widget.squadEmojis;
    // Each avatar has a 200ms stagger
    return SizedBox(
      height: 60,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final n = all.length;
        final spread = (w * 0.72).clamp(80.0, 320.0);
        final step = n > 1 ? spread / (n - 1) : 0;
        final baseLeft = (w - (step * (n - 1))) / 2;

        return Stack(clipBehavior: Clip.none, children: [
          for (var i = 0; i < n; i++) ...[
            Builder(builder: (_) {
              final iStart = startMs + i * 90;
              final t = _window(nowMs, iStart, iStart + 420);
              if (t <= 0) return const SizedBox();
              // Arc: x fixed, y rises from 30 → 0 with easeOut, +arc curve
              final centre = (n - 1) / 2;
              final offAxis = (i - centre).abs();
              final arcY = -math.sin((1 - t) * math.pi * 0.5) * 14 * offAxis;
              return Positioned(
                left: baseLeft + i * step - 18,
                top: 30 * (1 - t) + arcY,
                child: Opacity(
                  opacity: t,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TSColors.s2,
                      border: Border.all(
                          color: TSColors.limeDim(0.6), width: 1.2),
                    ),
                    child: Text(all[i],
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            }),
          ],
        ]);
      }),
    );
  }

  // Linear ramp 0→1 between start/end ms, clamped.
  double _window(int now, int start, int end) {
    if (end <= start) return now >= end ? 1.0 : 0.0;
    final t = (now - start) / (end - start);
    return _clamp(t, 0.0, 1.0);
  }

  // Bell — 0 → 1 → 0 over a window. Used for the edge glow pulse.
  double _bell(int now, int start, int end) {
    final t = _window(now, start, end);
    return math.sin(t * math.pi);
  }

  double _clamp(num v, double lo, double hi) =>
      v < lo ? lo : v > hi ? hi : v.toDouble();
}
