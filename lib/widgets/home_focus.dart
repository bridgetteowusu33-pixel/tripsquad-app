import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────
//  HOME FOCUS LINE
//
//  One line. One specific question. One CTA.
//
//  Derives its text + route from the user's most-urgent trip-state
//  need. Replaces the old greeting + profile nudge + "needs
//  attention" label. Every session opens with a specific ask, not
//  a generic welcome.
//
//  Priority order (first match wins):
//   1. trip in revealed/planning without user decision   — "open your plan"
//   2. trip in voting where user hasn't voted            — "vote on X"
//   3. trip in collecting with any squad missing         — "nudge the squad"
//   4. trip in live status                               — "today's plan"
//   5. trip completed in last 48h without recap          — "your recap is ready"
//   6. no active trip → the opening question
// ─────────────────────────────────────────────────────────────

class HomeFocus {
  const HomeFocus({
    required this.prefix,
    required this.ask,
    required this.cta,
    required this.route,
  });

  /// Greeting prefix, e.g. "good evening, bridgette."
  final String prefix;

  /// The specific question / need, e.g. "your squad needs your vote on lisbon."
  final String ask;

  /// Micro-CTA rendered next to the ask, e.g. "vote →".
  final String cta;

  /// Route to push when tapped.
  final String route;
}

({String text, Color color}) _greeting(String? name) {
  final h = DateTime.now().hour;
  final who = name == null ? '' : ', $name';
  if (h < 5)  return (text: 'up late again$who',     color: TSColors.blue);
  if (h < 12) return (text: 'good morning$who',      color: TSColors.gold);
  if (h < 17) return (text: 'afternoon$who',         color: TSColors.lime);
  if (h < 21) return (text: 'good evening$who',      color: TSColors.purple);
  return (text: 'late night plans$who',              color: TSColors.blue);
}

final homeFocusProvider = Provider<AsyncValue<HomeFocus?>>((ref) {
  final profile = ref.watch(currentProfileProvider);
  final trips = ref.watch(myTripsProvider);

  return profile.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (user) => trips.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (list) {
        final g = _greeting(user?.nickname?.toLowerCase());
        // Filter using the effective status so trips whose dates have
        // rolled into the live/completed phase drop out (or light up)
        // without any server-side advance.
        final active = list
            .where((t) => t.effectiveStatus != TripStatus.completed)
            .toList();

        if (active.isEmpty) {
          return AsyncValue.data(HomeFocus(
            prefix: g.text,
            ask: 'where are you trying to go that you haven\'t gone yet?',
            cta: 'start →',
            route: '/trip/create',
          ));
        }

        // Priority 1 — voting phase
        final voting = active.firstWhereOrNull(
          (t) => t.effectiveStatus == TripStatus.voting,
        );
        if (voting != null) {
          final dest = voting.selectedDestination ?? voting.name;
          return AsyncValue.data(HomeFocus(
            prefix: g.text,
            ask: 'your squad needs your vote on $dest.',
            cta: 'vote →',
            route: '/trip/${voting.id}/space',
          ));
        }

        // Priority 2 — revealed (options chosen, plan not yet seen)
        final revealed = active.firstWhereOrNull(
          (t) => t.effectiveStatus == TripStatus.revealed,
        );
        if (revealed != null) {
          final dest = revealed.selectedDestination ?? revealed.name;
          return AsyncValue.data(HomeFocus(
            prefix: g.text,
            ask: 'everyone voted. $dest is in.',
            cta: 'open →',
            route: '/trip/${revealed.id}/space',
          ));
        }

        // Priority 3 — live trip
        final live = active.firstWhereOrNull(
          (t) => t.effectiveStatus == TripStatus.live,
        );
        if (live != null) {
          final dest = live.selectedDestination ?? live.name;
          return AsyncValue.data(HomeFocus(
            prefix: g.text,
            ask: 'you\'re in $dest. scout has today\'s plan.',
            cta: 'today →',
            route: '/trip/${live.id}/space',
          ));
        }

        // Priority 4 — planning / countdown
        final planning = active.firstWhereOrNull(
          (t) => t.effectiveStatus == TripStatus.planning,
        );
        if (planning != null) {
          final days = _daysUntil(planning.startDate);
          final dest = planning.selectedDestination ?? planning.name;
          final ask = days == null
              ? '$dest is taking shape.'
              : days <= 0
                  ? '$dest is today. 🚀'
                  : days == 1
                      ? '$dest starts tomorrow. packed?'
                      : '$dest in $days days.';
          return AsyncValue.data(HomeFocus(
            prefix: g.text,
            ask: ask,
            cta: 'open →',
            route: '/trip/${planning.id}/space',
          ));
        }

        // Priority 5 — collecting (any trip waiting on the squad)
        final collecting = active.firstWhereOrNull(
          (t) => t.effectiveStatus == TripStatus.collecting,
        );
        if (collecting != null) {
          return AsyncValue.data(HomeFocus(
            prefix: g.text,
            ask: 'the squad is gathering for ${collecting.name}.',
            cta: 'see →',
            route: '/trip/${collecting.id}/space',
          ));
        }

        // Fallback
        return AsyncValue.data(HomeFocus(
          prefix: g.text,
          ask: 'all quiet. plan something next?',
          cta: 'start →',
          route: '/trip/create',
        ));
      },
    ),
  );
});

int? _daysUntil(DateTime? date) {
  if (date == null) return null;
  final now = DateTime.now();
  return date.difference(DateTime(now.year, now.month, now.day)).inDays;
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────

/// The focus-line widget rendered at the top of Home. Tap jumps
/// to the relevant route. Long-press does nothing (no secondary
/// action — single focus).
class HomeFocusLine extends ConsumerWidget {
  const HomeFocusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(homeFocusProvider);
    return focus.when(
      loading: () => const SizedBox(height: 72),
      error: (_, __) => const SizedBox(height: 72),
      data: (f) {
        if (f == null) return const SizedBox();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            TSHaptics.ctaTap();
            context.push(f.route);
          },
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(TSSpacing.md, 20, TSSpacing.md, 8),
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '${f.prefix}. ',
                  style: TSTextStyles.body(
                    size: 17,
                    color: TSColors.text2,
                    weight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: f.ask,
                  style: TSTextStyles.body(
                    size: 17,
                    color: TSColors.text,
                    weight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '  '),
                TextSpan(
                  text: f.cta,
                  style: TSTextStyles.title(
                    size: 14,
                    color: TSColors.lime,
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
