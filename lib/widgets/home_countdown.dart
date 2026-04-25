import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'weather_chip.dart';

// ─────────────────────────────────────────────────────────────
//  HOME COUNTDOWN
//
//  Appears on Home once a trip has a confirmed destination + a
//  start date within 60 days. Renders a large, live-updating
//  countdown — days · hours · minutes — beneath the destination
//  flag. Ticks once per minute (a minute resolution is the right
//  grain for a trip countdown; second-level would read as anxiety).
//
//  Disappears automatically once the trip becomes live or completes
//  (those phases own their own Home lines via HomeFocusLine).
// ─────────────────────────────────────────────────────────────

final homeCountdownTripProvider = Provider<Trip?>((ref) {
  final trips = ref.watch(myTripsProvider).valueOrNull ?? const <Trip>[];

  // Only the closest upcoming trip renders a countdown. Anything
  // more than 60 days away is still too distant to build tension
  // around.
  final candidates = trips
      .where((t) =>
          (t.effectiveStatus == TripStatus.revealed ||
              t.effectiveStatus == TripStatus.planning) &&
          t.startDate != null &&
          t.selectedDestination != null)
      .toList();

  if (candidates.isEmpty) return null;

  candidates.sort((a, b) => a.startDate!.compareTo(b.startDate!));
  final next = candidates.first;

  final now = DateTime.now();
  final diff = next.startDate!.difference(now);
  if (diff.inDays > 60) return null;
  if (diff.isNegative) return null;

  return next;
});

/// Large countdown card. Tap → Trip Space.
class HomeCountdown extends ConsumerStatefulWidget {
  const HomeCountdown({super.key});

  @override
  ConsumerState<HomeCountdown> createState() => _HomeCountdownState();
}

class _HomeCountdownState extends ConsumerState<HomeCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tick once per minute — sufficient for a multi-day countdown.
    // Aligns the first tick to the next minute boundary so users don't
    // see stale values right after open.
    final now = DateTime.now();
    final msToNextMinute =
        60000 - (now.second * 1000 + now.millisecond);
    Future.delayed(Duration(milliseconds: msToNextMinute), () {
      if (!mounted) return;
      setState(() {});
      _ticker = Timer.periodic(
        const Duration(minutes: 1),
        (_) => mounted ? setState(() {}) : null,
      );
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(homeCountdownTripProvider);
    if (trip == null) return const SizedBox();

    final dest = trip.selectedDestination ?? trip.name;
    final flag = trip.selectedFlag ?? '✈️';
    final now = DateTime.now();
    final diff = trip.startDate!.difference(now);
    if (diff.isNegative) return const SizedBox();

    final days = diff.inDays;
    final hours = diff.inHours - days * 24;
    final minutes = diff.inMinutes - diff.inHours * 60;

    final cover = trip.coverPhotoUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TSSpacing.md, 6, TSSpacing.md, 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          TSHaptics.ctaTap();
          context.push('/trip/${trip.id}/space');
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: TSColors.s1,
              border: Border.all(color: TSColors.limeDim(0.3)),
              boxShadow: [
                BoxShadow(
                  color: TSColors.lime.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(children: [
              // Host cover photo as a subtle backdrop. Falls back to
              // the plain s1 card when no cover is set.
              if (cover != null && cover.isNotEmpty)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.22,
                    child: CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(),
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              if (cover != null && cover.isNotEmpty)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xCC0F0F1C),
                          Color(0x990F0F1C),
                          Color(0xCC08080E),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dest,
                          style: TSTextStyles.title(
                              size: 15, color: TSColors.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      WeatherChip(
                          destination: dest, date: trip.startDate!),
                      const SizedBox(width: 6),
                      Text('COUNTDOWN',
                          style: TSTextStyles.label(
                              color: TSColors.lime, size: 9)),
                    ]),
                    const SizedBox(height: 10),
                    // Big tick
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Block(
                            value: days,
                            label: days == 1 ? 'day' : 'days'),
                        const SizedBox(width: 14),
                        _Divider(),
                        const SizedBox(width: 14),
                        _Block(
                            value: hours,
                            label: hours == 1 ? 'hr' : 'hrs'),
                        const SizedBox(width: 14),
                        _Divider(),
                        const SizedBox(width: 14),
                        _Block(
                            value: minutes,
                            label: minutes == 1 ? 'min' : 'mins'),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TSTextStyles.heading(size: 38, color: TSColors.lime)
              .copyWith(height: 1.0, letterSpacing: -1),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TSTextStyles.label(color: TSColors.muted, size: 10)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(':',
          style: TSTextStyles.heading(size: 32, color: TSColors.muted2)
              .copyWith(height: 1)),
    );
  }
}
