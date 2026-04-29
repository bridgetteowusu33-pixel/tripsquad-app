import 'package:flutter/material.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';

/// Compact countdown chip used in the book tab above each pill
/// section. Reads a `TripBookingDeadline` and computes time-left at
/// render. Three visual states:
///
///   - normal (>24h):  gray bg, lime accent
///   - urgent (<24h):  red-ish accent, slightly bigger font weight
///   - passed:         muted gray, "deadline passed" copy
///
/// Tapping invokes `onTap` (host: edits the deadline; guest: nothing
/// or a tooltip). Phase 2 adds a 1min ticker for a truly live count;
/// Phase 1 re-renders on any rebuild which is fine for the surface
/// it lives on.
class DeadlineChip extends StatelessWidget {
  const DeadlineChip({
    super.key,
    required this.deadline,
    required this.canEdit,
    required this.onTap,
  });
  final TripBookingDeadline deadline;
  final bool canEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final delta = deadline.deadlineAt.difference(now);
    final passed = delta.isNegative;
    final urgent = !passed && delta.inHours < 24;
    final accent = passed
        ? TSColors.muted
        : (urgent ? const Color(0xFFFF6B6B) : TSColors.lime);

    return GestureDetector(
      onTap: () {
        if (canEdit) {
          TSHaptics.light();
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: passed
              ? TSColors.s2
              : (urgent
                  ? const Color(0xFFFF6B6B).withValues(alpha: 0.10)
                  : TSColors.s2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: urgent && !passed
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.4)
                : TSColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.history : Icons.timer_outlined,
              size: 12,
              color: accent,
            ),
            const SizedBox(width: 5),
            Text(
              passed ? 'deadline passed' : _formatRemaining(delta),
              style: TSTextStyles.label(color: accent, size: 11),
            ),
            if (canEdit) ...[
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, size: 11, color: accent),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inDays >= 1) {
      final days = d.inDays;
      final hours = d.inHours.remainder(24);
      return '${days}d ${hours}h';
    }
    if (d.inHours >= 1) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    }
    final minutes = d.inMinutes.clamp(0, 999);
    return '${minutes}m left';
  }
}

/// Compact "set deadline" stub for when no deadline exists yet and
/// the current user is the host. Tap → opens SetDeadlineSheet.
class SetDeadlineStub extends StatelessWidget {
  const SetDeadlineStub({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        TSHaptics.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: TSColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_alarm,
                size: 12, color: TSColors.text2),
            const SizedBox(width: 5),
            Text(label,
                style: TSTextStyles.label(
                    color: TSColors.text2, size: 11)),
          ],
        ),
      ),
    );
  }
}
