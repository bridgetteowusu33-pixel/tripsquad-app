import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../services/supabase_service.dart';

/// Host-only modal sheet to set the booking deadline for a kind
/// (flight or accommodation). RLS enforces host-only writes; the
/// caller is responsible for not opening this sheet for non-hosts.
///
/// Common patterns we make easy via "quick" buttons:
///   - 1 week before trip start
///   - 2 weeks before trip start
///   - 1 month from now
///   - custom (full date/time picker)
class SetDeadlineSheet extends ConsumerStatefulWidget {
  const SetDeadlineSheet({
    super.key,
    required this.trip,
    required this.kind,
    this.existing,
  });
  final Trip trip;
  final BookingKind kind;
  final TripBookingDeadline? existing;

  @override
  ConsumerState<SetDeadlineSheet> createState() => _SetDeadlineSheetState();
}

class _SetDeadlineSheetState extends ConsumerState<SetDeadlineSheet> {
  late DateTime _picked;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _picked = widget.existing?.deadlineAt ??
        _defaultDeadline();
  }

  /// Default to 1 week before trip start, or 2 weeks from now if no
  /// trip start is set. Both are sane defaults — short enough to
  /// create urgency, long enough to be reasonable.
  DateTime _defaultDeadline() {
    final start = widget.trip.startDate;
    if (start != null) {
      final candidate = start.subtract(const Duration(days: 7));
      // If the trip is so close that 7 days back has already passed,
      // fall back to 24h from now so we don't suggest a past deadline.
      if (candidate.isAfter(DateTime.now())) return candidate;
    }
    return DateTime.now().add(const Duration(days: 14));
  }

  Future<void> _save() async {
    if (_picked.isBefore(DateTime.now())) {
      setState(() => _error = 'pick a date in the future');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(bookingServiceProvider).setDeadline(
            tripId: widget.trip.id,
            kind: widget.kind == BookingKind.flight
                ? 'flight'
                : 'accommodation',
            deadline: _picked,
          );
      if (mounted) {
        TSHaptics.success();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = humanizeError(e);
        });
      }
    }
  }

  void _quickPick(Duration before, {bool fromTripStart = false}) {
    final base = fromTripStart && widget.trip.startDate != null
        ? widget.trip.startDate!
        : DateTime.now();
    setState(() => _picked = base.subtract(before).add(
          fromTripStart ? Duration.zero : before * 2,
        ));
    // The expression above is awkward — `before` is interpreted as
    // "subtract this much from base" when fromTripStart, "add this
    // much from now" when not. Replace with explicit branches:
    setState(() {
      _picked = fromTripStart
          ? widget.trip.startDate!.subtract(before)
          : DateTime.now().add(before);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasStart = widget.trip.startDate != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: TSColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GrabHandle(),
            const SizedBox(height: 16),
            Text(
              widget.kind == BookingKind.flight
                  ? 'flight booking deadline'
                  : 'accommodation booking deadline',
              style: TSTextStyles.heading(size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              widget.kind == BookingKind.flight
                  ? "by when does the squad need to lock in their flights?"
                  : "by when does the squad need to lock in where they're staying?",
              style: TSTextStyles.body(color: TSColors.text2),
            ),
            const SizedBox(height: 18),

            // Quick-pick chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hasStart)
                  _QuickPick(
                    label: '1 week before trip',
                    selected: _isCloseTo(_picked,
                        widget.trip.startDate!
                            .subtract(const Duration(days: 7))),
                    onTap: () => _quickPick(const Duration(days: 7),
                        fromTripStart: true),
                  ),
                if (hasStart)
                  _QuickPick(
                    label: '2 weeks before',
                    selected: _isCloseTo(_picked,
                        widget.trip.startDate!
                            .subtract(const Duration(days: 14))),
                    onTap: () => _quickPick(const Duration(days: 14),
                        fromTripStart: true),
                  ),
                _QuickPick(
                  label: '2 weeks from now',
                  selected: _isCloseTo(_picked,
                      DateTime.now().add(const Duration(days: 14))),
                  onTap: () =>
                      _quickPick(const Duration(days: 14)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Date/time picker — Cupertino style for iOS feel
            Container(
              decoration: BoxDecoration(
                color: TSColors.s2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TSColors.border),
              ),
              height: 200,
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.dark,
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: _picked,
                  minimumDate: DateTime.now(),
                  maximumDate:
                      DateTime.now().add(const Duration(days: 365)),
                  use24hFormat: false,
                  onDateTimeChanged: (d) =>
                      setState(() => _picked = d),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: TSTextStyles.caption(color: Colors.redAccent)),
            ],

            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(
                    'cancel',
                    style: TSTextStyles.label(
                        color: TSColors.text2, size: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _saving ? null : _save,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: TSColors.lime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TSColors.bg,
                            ),
                          )
                        : Text(
                            widget.existing == null
                                ? 'set deadline'
                                : 'update deadline',
                            style: TSTextStyles.label(
                                color: TSColors.bg, size: 13),
                          ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  bool _isCloseTo(DateTime a, DateTime b) =>
      a.difference(b).inMinutes.abs() < 30;
}

class _QuickPick extends StatelessWidget {
  const _QuickPick({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        TSHaptics.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? TSColors.limeDim(0.14) : TSColors.s2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? TSColors.lime : TSColors.border,
          ),
        ),
        child: Text(
          label,
          style: TSTextStyles.label(
            color: selected ? TSColors.lime : TSColors.text,
            size: 12,
          ),
        ),
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: TSColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}
