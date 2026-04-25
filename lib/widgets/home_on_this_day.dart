import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────
//  HOME — ON THIS DAY
//
//  If today is the anniversary (same month + day) of a completed
//  trip's start date, surface a tiny flashback card on Home:
//  "2 years ago today — tokyo 🇯🇵". Tap jumps into the trip's
//  Memories tab.
//
//  Quiet by default. Only renders when a match exists. No new
//  data — reads from myTrips.
// ─────────────────────────────────────────────────────────────

class HomeOnThisDay extends ConsumerWidget {
  const HomeOnThisDay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);
    final trips = tripsAsync.valueOrNull;
    if (trips == null || trips.isEmpty) return const SizedBox();

    final match = _findAnniversary(trips);
    if (match == null) return const SizedBox();

    final (trip, years) = match;
    final dest = trip.selectedDestination ?? trip.name;
    final flag = trip.selectedFlag ?? '📍';
    final yearsLabel = years == 1 ? '1 year ago today' : '$years years ago today';

    return Padding(
      padding: const EdgeInsets.fromLTRB(TSSpacing.md, 8, TSSpacing.md, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          TSHaptics.light();
          context.push('/trip/${trip.id}/space');
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: TSColors.s1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TSColors.border),
          ),
          child: Row(children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(yearsLabel.toUpperCase(),
                      style: TSTextStyles.label(
                          color: TSColors.gold, size: 10)),
                  const SizedBox(height: 3),
                  Text(
                    '$flag $dest',
                    style: TSTextStyles.title(size: 14, color: TSColors.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text('revisit →',
                style: TSTextStyles.title(size: 12, color: TSColors.gold)),
          ]),
        ),
      ),
    );
  }

  /// Returns the most recent completed trip whose start date's
  /// month + day matches today, along with how many whole years ago
  /// the trip began. Ignores trips with no start date. Ignores
  /// trips in the current year (0 years ago isn't a flashback).
  (Trip, int)? _findAnniversary(List<Trip> trips) {
    final now = DateTime.now();
    Trip? best;
    int bestYears = 0;
    for (final t in trips) {
      if (t.startDate == null) continue;
      if (t.effectiveStatus != TripStatus.completed) continue;
      final s = t.startDate!;
      if (s.month != now.month || s.day != now.day) continue;
      final years = now.year - s.year;
      if (years < 1) continue;
      if (best == null || years < bestYears) {
        best = t;
        bestYears = years;
      }
    }
    return best == null ? null : (best, bestYears);
  }
}
