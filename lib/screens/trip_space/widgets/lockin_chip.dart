import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';

/// Slim, persistent lock-in counter that lives in trip space between
/// the VibeStrip and the TabBar — visible across every tab so users
/// always know how close the squad is to fully booking. Tapping it
/// jumps to the `book` tab via the existing tripSpaceJumpProvider.
///
/// Hides when:
///   - trip status < revealed (no booking surface yet)
///   - squad_size == 0 (single-host trip, nothing to lock-in vs)
///   - stream errors / loading
///
/// At 100% lock-in the chip flips to a celebration state (lime fill +
/// "we're really going" copy). Pulses briefly when count advances.
class LockinChip extends ConsumerWidget {
  const LockinChip({super.key, required this.trip});
  final Trip trip;

  bool get _phaseHasBooking {
    final s = trip.effectiveStatus;
    return s == TripStatus.revealed ||
        s == TripStatus.planning ||
        s == TripStatus.live;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_phaseHasBooking) return const SizedBox.shrink();

    final asyncStatus = ref.watch(tripLockinStatusProvider(trip.id));
    return asyncStatus.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) {
        if (s == null || s.squadSize == 0) return const SizedBox.shrink();
        // Use the *higher* of flights vs accommodation as the headline
        // count — gives the user a "we're getting somewhere" signal
        // without overpromising. Both kinds visible on tap-through.
        final headlineBooked =
            s.flightsBooked > s.accommodationBooked
                ? s.flightsBooked
                : s.accommodationBooked;
        final fullyLocked = headlineBooked >= s.squadSize;
        return _Chip(
          booked: headlineBooked,
          total: s.squadSize,
          flightsBooked: s.flightsBooked,
          accommodationBooked: s.accommodationBooked,
          fullyLocked: fullyLocked,
          onTap: () {
            TSHaptics.light();
            // Jump to the book tab — uses the same tripSpaceJumpProvider
            // plumbing wired for cross-tab navigation in v1.1.
            final prev = ref.read(tripSpaceJumpProvider);
            ref.read(tripSpaceJumpProvider.notifier).state =
                TripSpaceJumpRequest(
              tabKey: 'book',
              seq: (prev?.seq ?? 0) + 1,
            );
          },
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.booked,
    required this.total,
    required this.flightsBooked,
    required this.accommodationBooked,
    required this.fullyLocked,
    required this.onTap,
  });
  final int booked;
  final int total;
  final int flightsBooked;
  final int accommodationBooked;
  final bool fullyLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: fullyLocked
                ? LinearGradient(
                    colors: [
                      TSColors.lime.withValues(alpha: 0.20),
                      TSColors.lime.withValues(alpha: 0.06),
                    ],
                  )
                : null,
            color: fullyLocked ? null : TSColors.s2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: fullyLocked
                  ? TSColors.lime
                  : TSColors.border,
              width: fullyLocked ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                fullyLocked ? '🎉' : '🔒',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                fullyLocked
                    ? "we're really going"
                    : '$booked / $total locked in',
                style: TSTextStyles.label(
                  color: fullyLocked ? TSColors.lime : TSColors.text,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              _MiniBar(
                label: '✈️',
                value: flightsBooked,
                total: total,
              ),
              const SizedBox(width: 6),
              _MiniBar(
                label: '🏨',
                value: accommodationBooked,
                total: total,
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: fullyLocked ? TSColors.lime : TSColors.muted,
              ),
            ],
          ),
        ).animate(
          // Pulse when the booked count advances. Triggers on every
          // build whose animated value differs — Flutter Animate
          // dedupes on `target` so reruns at the same value are
          // no-ops. Cheap polish; no state needed.
          target: booked.toDouble(),
        ).scaleXY(
          begin: 1.0,
          end: 1.04,
          duration: 200.ms,
          curve: Curves.easeOut,
        ).then().scaleXY(
          begin: 1.04,
          end: 1.0,
          duration: 250.ms,
          curve: Curves.easeIn,
        ),
      ),
    );
  }
}

/// Tiny inline progress bar: emoji + filled fraction. Used to show
/// the per-kind split (flights vs accommodation) inside the lock-in
/// chip without needing a second row.
class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.label,
    required this.value,
    required this.total,
  });
  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 3),
      SizedBox(
        width: 24,
        height: 4,
        child: Stack(children: [
          Container(
            decoration: BoxDecoration(
              color: TSColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: TSColors.lime,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}
