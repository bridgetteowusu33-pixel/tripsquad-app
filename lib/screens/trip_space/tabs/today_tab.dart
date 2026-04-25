import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/motion.dart';

// ─────────────────────────────────────────────────────────────
//  TODAY TAB  (Live Trip Mode)
//
//  The "trip is happening right now" view. Shows today's itinerary
//  with check-off, a NOW pulse on the current activity, and a
//  Scout celebration when the day wraps.
//
//  Check-offs are SERVER-SIDE (itinerary_items.checked_off_at, via
//  the toggle_itinerary_check RPC — see migration 031). Squad
//  members see each other's progress in real time via the itinerary
//  stream's realtime subscription.
// ─────────────────────────────────────────────────────────────

class TodayTab extends ConsumerStatefulWidget {
  const TodayTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends ConsumerState<TodayTab> {
  /// Optimistic-toggle set — items the user just tapped, held only
  /// until the server-side state catches up via the realtime stream.
  /// Prevents UI flicker on laggy connections.
  final Set<String> _inflight = {};

  Future<void> _toggle(ItineraryActivity item) async {
    if (_inflight.contains(item.id)) return;
    TSHaptics.ctaCommit();
    setState(() => _inflight.add(item.id));
    try {
      await ref.read(itineraryServiceProvider).toggleCheck(item.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("couldn't sync — ${humanizeError(e)}",
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _inflight.remove(item.id));
    }
  }

  bool _isDone(ItineraryActivity item) => item.checkedOffAt != null;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final day = _currentDayNumber(trip);
    final stream = ref.watch(itineraryStreamProvider(trip.id));

    return stream.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: TSColors.lime),
      ),
      error: (e, _) => Center(
        child: Text('$e', style: TSTextStyles.body(color: TSColors.muted)),
      ),
      data: (all) {
        if (day == null) return _PreTripEmpty(trip: trip);

        final todays = all
            .where((i) =>
                i.dayNumber == day && i.status == 'approved')
            .toList()
          ..sort((a, b) {
            final slot = _slotOrder[a.timeOfDay]!
                .compareTo(_slotOrder[b.timeOfDay]!);
            if (slot != 0) return slot;
            return a.orderIndex.compareTo(b.orderIndex);
          });

        if (todays.isEmpty) {
          return _EmptyDay(day: day, trip: trip);
        }

        final done = todays.where(_isDone).length;
        final total = todays.length;
        final allDone = total > 0 && done == total;

        ItineraryActivity? currentActivity;
        for (final i in todays) {
          if (!_isDone(i)) {
            currentActivity = i;
            break;
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _Header(
              day: day,
              totalDays: trip.durationDays,
              done: done,
              total: total,
            ),
            const SizedBox(height: 18),

            if (allDone) ...[
              _DayWrapped(trip: trip, day: day),
              const SizedBox(height: 20),
            ],

            for (final item in todays)
              _TodayRow(
                item: item,
                isNow: item.id == currentActivity?.id,
                isDone: _isDone(item),
                onToggle: () => _toggle(item),
              ),

            const SizedBox(height: 24),
            _ScoutNudge(
              done: done,
              total: total,
              trip: trip,
            ),
          ],
        );
      },
    );
  }

  int? _currentDayNumber(Trip t) {
    if (t.startDate == null) return null;
    final now = DateTime.now();
    final start = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(start).inDays + 1;
    if (days < 1) return null;
    if (t.durationDays != null && days > t.durationDays!) return null;
    return days;
  }
}

const _slotOrder = {'morning': 0, 'afternoon': 1, 'evening': 2, 'night': 3};

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.day,
    required this.totalDays,
    required this.done,
    required this.total,
  });
  final int day;
  final int? totalDays;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdayName(DateTime.now().weekday);
    final progress = total == 0 ? 0.0 : done / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TODAY',
          style: TSTextStyles.label(color: TSColors.lime, size: 10)),
      const SizedBox(height: 6),
      Text(
        totalDays != null
            ? 'day $day · $weekday'
            : 'day $day',
        style: TSTextStyles.heading(size: 26),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TheTide(progress: progress, height: 5)),
        const SizedBox(width: 10),
        Text('$done / $total',
            style: TSTextStyles.title(size: 13, color: TSColors.lime)),
      ]),
    ]);
  }

  String _weekdayName(int weekday) {
    const names = [
      '', 'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday'
    ];
    return names[weekday];
  }
}

// ─────────────────────────────────────────────────────────────
//  ACTIVITY ROW
// ─────────────────────────────────────────────────────────────

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.item,
    required this.isNow,
    required this.isDone,
    required this.onToggle,
  });
  final ItineraryActivity item;
  final bool isNow;
  final bool isDone;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final slotLabel = switch (item.timeOfDay) {
      'morning' => 'MORNING',
      'afternoon' => 'AFTERNOON',
      'evening' => 'EVENING',
      'night' => 'NIGHT',
      _ => item.timeOfDay.toUpperCase(),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: isDone ? TSColors.s1 : TSColors.s2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNow ? TSColors.lime : TSColors.border,
            width: isNow ? 1.5 : 1,
          ),
          boxShadow: [
            if (isNow)
              BoxShadow(
                color: TSColors.limeDim(0.25),
                blurRadius: 18,
                spreadRadius: -4,
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check / pulse
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: SizedBox(
                width: 36,
                height: 36,
                child: isDone
                    ? Container(
                        decoration: const BoxDecoration(
                          color: TSColors.lime,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: TSColors.bg, size: 22),
                      )
                    : isNow
                        ? const Center(child: ThePulse(size: 10))
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: TSColors.border2, width: 1.4),
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(slotLabel,
                        style: TSTextStyles.label(
                            color: isNow
                                ? TSColors.lime
                                : TSColors.muted,
                            size: 10)),
                    if (isNow) ...[
                      const SizedBox(width: 6),
                      Text('· now',
                          style: TSTextStyles.label(
                              color: TSColors.lime, size: 10)),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: TSTextStyles.title(
                      size: 15,
                      color: isDone ? TSColors.muted2 : TSColors.text,
                    ).copyWith(
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      decorationColor: TSColors.muted,
                    ),
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: TSTextStyles.caption(
                        color: isDone ? TSColors.muted : TSColors.text2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.location != null &&
                      item.location!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('📍 ${item.location!}',
                        style:
                            TSTextStyles.caption(color: TSColors.muted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DAY WRAPPED CELEBRATION
// ─────────────────────────────────────────────────────────────

class _DayWrapped extends StatelessWidget {
  const _DayWrapped({required this.trip, required this.day});
  final Trip trip;
  final int day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TSColors.limeDim(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TSColors.lime, width: 1.4),
      ),
      child: Row(children: [
        const Text('✨', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('day $day · wrapped',
                    style: TSTextStyles.title(
                        size: 15, color: TSColors.lime)),
                const SizedBox(height: 4),
                Text(
                  _nextDayTeaser(trip, day),
                  style: TSTextStyles.caption(color: TSColors.text2),
                ),
              ]),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  String _nextDayTeaser(Trip t, int today) {
    final remaining = (t.durationDays ?? today) - today;
    if (remaining <= 0) {
      return 'last day down. scout\'s already writing the recap 🧭';
    }
    if (remaining == 1) {
      return 'one more day. the squad\'s actually doing it.';
    }
    return '$remaining days to go. eat · walk · repeat.';
  }
}

// ─────────────────────────────────────────────────────────────
//  SCOUT NUDGE (bottom hint)
// ─────────────────────────────────────────────────────────────

class _ScoutNudge extends StatelessWidget {
  const _ScoutNudge({
    required this.done,
    required this.total,
    required this.trip,
  });
  final int done, total;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    String line;
    if (done == 0) {
      line = 'tap the circle to check off. scout will clock it.';
    } else if (done == total) {
      line = 'everything\'s done. chef\'s kiss 🤌';
    } else if (done / total >= 0.66) {
      line = 'stretch run. ${total - done} to go.';
    } else if (done >= 2) {
      line = 'nice rhythm. keep moving.';
    } else {
      line = 'momentum. eat something, drink water.';
    }

    return Row(children: [
      const Text('🧭', style: TextStyle(fontSize: 14)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(line,
            style: TSTextStyles.caption(color: TSColors.muted2)),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATES
// ─────────────────────────────────────────────────────────────

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day, required this.trip});
  final int day;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('day $day is open',
              style: TSTextStyles.heading(size: 20)),
          const SizedBox(height: 6),
          Text(
            'no plans for today. let the day breathe — or open the plan tab and add something.',
            textAlign: TextAlign.center,
            style: TSTextStyles.body(color: TSColors.muted, size: 13.5),
          ),
        ]),
      ),
    );
  }
}

class _PreTripEmpty extends StatelessWidget {
  const _PreTripEmpty({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final daysAway = _daysUntil(trip.startDate);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⏳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            daysAway == null
                ? 'not trip day yet'
                : daysAway == 1
                    ? 'tomorrow 🚀'
                    : daysAway > 1
                        ? 'trip day in $daysAway days'
                        : 'trip has wrapped',
            style: TSTextStyles.heading(size: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'this tab wakes up on day 1. until then — plan · pack · hype.',
            textAlign: TextAlign.center,
            style: TSTextStyles.body(color: TSColors.muted, size: 13.5),
          ),
        ]),
      ),
    );
  }

  int? _daysUntil(DateTime? d) {
    if (d == null) return null;
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }
}
