import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/trip_space/recap_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  HOME — RATE YOUR TRIP
//
//  Surfaces a small CTA on Home when one of the user's trips has
//  just wrapped (effectiveStatus == completed, endDate ≤ 14 days
//  ago). Tap → opens the existing RecapSheet for that trip. X →
//  stashes `home_recap_dismissed_<tripId>` so the nudge doesn't
//  come back.
//
//  Quiet by default — no card when there's nothing to recap.
// ─────────────────────────────────────────────────────────────

class HomeRecapPrompt extends ConsumerStatefulWidget {
  const HomeRecapPrompt({super.key});

  @override
  ConsumerState<HomeRecapPrompt> createState() =>
      _HomeRecapPromptState();
}

class _HomeRecapPromptState extends ConsumerState<HomeRecapPrompt> {
  Set<String> _dismissed = {};
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String>{};
    for (final k in prefs.getKeys()) {
      if (!k.startsWith('home_recap_dismissed_')) continue;
      if (prefs.getBool(k) == true) {
        out.add(k.substring('home_recap_dismissed_'.length));
      }
    }
    if (!mounted) return;
    setState(() {
      _dismissed = out;
      _checked = true;
    });
  }

  Future<void> _dismiss(String tripId) async {
    TSHaptics.light();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_recap_dismissed_$tripId', true);
    if (!mounted) return;
    setState(() => _dismissed = {..._dismissed, tripId});
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SizedBox();
    final trips = ref.watch(myTripsProvider).valueOrNull;
    if (trips == null || trips.isEmpty) return const SizedBox();

    // Most-recently-wrapped eligible trip (within 14 days, not
    // dismissed). Only one card at a time — pick the freshest so
    // the user never has a pile of nudges.
    final now = DateTime.now();
    Trip? candidate;
    DateTime? candidateEnd;
    for (final t in trips) {
      if (t.effectiveStatus != TripStatus.completed) continue;
      if (_dismissed.contains(t.id)) continue;
      final end = t.endDate ?? t.startDate;
      if (end == null) continue;
      if (now.difference(end).inDays > 14) continue;
      if (now.difference(end).isNegative) continue;
      if (candidate == null ||
          (candidateEnd != null && end.isAfter(candidateEnd))) {
        candidate = t;
        candidateEnd = end;
      }
    }
    if (candidate == null) return const SizedBox();

    final trip = candidate;
    final dest = trip.selectedDestination ?? trip.name;
    final flag = trip.selectedFlag ?? '✈️';
    return Padding(
      padding: const EdgeInsets.fromLTRB(TSSpacing.md, 8, TSSpacing.md, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          TSHaptics.ctaTap();
          RecapSheet.show(context, trip);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: TSColors.s1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TSColors.gold.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            const Text('⭐', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('how was $flag $dest?',
                      style: TSTextStyles.title(
                          size: 13, color: TSColors.text)),
                  const SizedBox(height: 1),
                  Text('leave a quick recap — stars, best part, would-return',
                      style: TSTextStyles.caption(color: TSColors.muted2)),
                ],
              ),
            ),
            Text('rate →',
                style: TSTextStyles.label(
                    color: TSColors.gold, size: 10)),
            IconButton(
              onPressed: () => _dismiss(trip.id),
              icon: const Icon(Icons.close_rounded,
                  color: TSColors.muted, size: 14),
              visualDensity: VisualDensity.compact,
              tooltip: 'dismiss',
            ),
          ]),
        ),
      ),
    );
  }
}
