import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

/// Per-squad-member flight card. State machine driven:
///
///  not_set    → "tell scout where you're flying from" CTA opens
///               SetDepartureSheet.
///  searching  → departure city set, no booking yet. Show "find
///               flights →" affiliate-redirect button + "I booked
///               this" check-off.
///  booked     → green check + airline / flight number / arrival.
///               First booker on the trip is rendered as the anchor.
///
/// All squad members can SEE other members' cards (RLS allows trip
/// member SELECT). Only the member themselves can edit their own
/// row (RLS WITH CHECK enforces user_id = auth.uid()).
class FlightCard extends StatelessWidget {
  const FlightCard({
    super.key,
    required this.plan,
    required this.member,
    required this.isMe,
    required this.searchUrl,
    required this.onSetDeparture,
    required this.onMarkBooked,
    this.anchorArrivalAt,
    this.anchorMemberName,
  });

  /// Nullable when the member has never set a departure (no row yet).
  /// We synthesize a placeholder for rendering in that case.
  final MemberArrivalPlan? plan;
  final SquadMember member;
  final bool isMe;
  final String? searchUrl;
  final VoidCallback onSetDeparture;
  final VoidCallback onMarkBooked;

  /// When the trip has an anchor (first booker) and THIS card is not
  /// the anchor, we surface a "match arrival ~Xpm" hint above the
  /// find-flights button. The user filters in Aviasales themselves —
  /// our value is telling them what arrival time to filter for.
  final DateTime? anchorArrivalAt;
  final String? anchorMemberName;

  ArrivalPlanState get _state =>
      plan?.state ?? ArrivalPlanState.not_set;

  Future<void> _launchSearch() async {
    if (searchUrl == null) return;
    TSHaptics.ctaTap();
    final uri = Uri.parse(searchUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = plan?.isAnchor == true
        ? TSColors.lime
        : (_state == ArrivalPlanState.booked ? TSColors.lime : TSColors.text2);

    return TSCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity row
          Row(children: [
            TSAvatar(
              emoji: member.emoji ?? '😎',
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      isMe ? 'you' : member.nickname,
                      style: TSTextStyles.heading(size: 15),
                    ),
                    const SizedBox(width: 6),
                    if (plan?.isAnchor == true) const _AnchorBadge(),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    _stateLabel(),
                    style: TSTextStyles.caption(color: headerColor),
                  ),
                ],
              ),
            ),
            if (_state == ArrivalPlanState.booked)
              const Icon(Icons.check_circle,
                  color: TSColors.lime, size: 22),
          ]),

          // Body — varies by state
          const SizedBox(height: 14),
          ..._bodyForState(),
        ],
      ),
    );
  }

  String _stateLabel() {
    switch (_state) {
      case ArrivalPlanState.not_set:
        return 'departure not set';
      case ArrivalPlanState.searching:
        return '${plan!.departureCity ?? plan!.departureIata} '
            '· ${plan!.departureIata ?? "??"} → ${plan!.arrivalIata ?? ""}';
      case ArrivalPlanState.booked:
        final airline = plan!.airline;
        final fn = plan!.flightNumber;
        if (airline != null && fn != null) return '$airline $fn · booked';
        return 'booked';
      case ArrivalPlanState.cancelled:
        return 'cancelled';
    }
  }

  List<Widget> _bodyForState() {
    switch (_state) {
      case ArrivalPlanState.not_set:
        return [
          Text(
            isMe
                ? "scout needs your departure airport to build your flight search."
                : "${member.nickname} hasn't set a departure airport yet.",
            style: TSTextStyles.body(size: 13, color: TSColors.text2),
          ),
          const SizedBox(height: 12),
          if (isMe)
            _PrimaryButton(
              label: 'set departure',
              icon: Icons.flight_takeoff,
              onTap: onSetDeparture,
            ),
        ];

      case ArrivalPlanState.searching:
        return [
          // Anchor-match hint — only when an anchor exists and THIS
          // card is not the anchor. Tells the user the arrival time
          // they should filter their flight search around.
          if (anchorArrivalAt != null &&
              plan?.isAnchor != true &&
              isMe) ...[
            _AnchorHint(
              anchorArrival: anchorArrivalAt!,
              anchorName: anchorMemberName,
            ),
            const SizedBox(height: 10),
          ],
          Row(children: [
            if (searchUrl != null)
              _PrimaryButton(
                label: 'find flights',
                icon: Icons.search,
                onTap: _launchSearch,
              ),
            const SizedBox(width: 8),
            if (isMe)
              _SecondaryButton(
                label: '✓ I booked',
                onTap: onMarkBooked,
              ),
          ]),
          if (isMe) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onSetDeparture,
              child: Text(
                'change departure airport',
                style: TSTextStyles.caption(color: TSColors.muted),
              ),
            ),
          ],
        ];

      case ArrivalPlanState.booked:
        final outbound = plan!.outboundAt;
        return [
          if (outbound != null)
            Text(
              'arrives ${_formatArrival(outbound)}',
              style: TSTextStyles.body(size: 13, color: TSColors.text2),
            ),
          if (plan?.bookingRef != null && plan!.bookingRef!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('confirmation · ${plan!.bookingRef!}',
                style: TSTextStyles.caption(color: TSColors.muted)),
          ],
        ];

      case ArrivalPlanState.cancelled:
        return [
          Text(
            'flight was cancelled.',
            style: TSTextStyles.body(size: 13, color: TSColors.text2),
          ),
        ];
    }
  }

  String _formatArrival(DateTime t) {
    final local = t.toLocal();
    final h = local.hour;
    final ampm = h >= 12 ? 'pm' : 'am';
    final hh = (h % 12 == 0 ? 12 : h % 12).toString();
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm$ampm';
  }
}

/// Anchor match hint. Shows the host/anchor's arrival time so the
/// non-anchor member can filter their flight search around it. The
/// signature TripSquad coordination moment — Aviasales doesn't know
/// about the anchor, but the user does, and they filter manually.
class _AnchorHint extends StatelessWidget {
  const _AnchorHint({required this.anchorArrival, this.anchorName});
  final DateTime anchorArrival;
  final String? anchorName;

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final h = local.hour;
    final ampm = h >= 12 ? 'pm' : 'am';
    final hh = (h % 12 == 0 ? 12 : h % 12).toString();
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm$ampm';
  }

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(anchorArrival);
    final who = anchorName ?? 'the anchor';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: TSColors.lime.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TSColors.lime.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Text('⚓', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TSTextStyles.body(size: 12, color: TSColors.text2),
              children: [
                TextSpan(
                  text: who,
                  style: TSTextStyles.body(
                    size: 12,
                    color: TSColors.lime,
                    weight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' lands around '),
                TextSpan(
                  text: time,
                  style: TSTextStyles.body(
                    size: 12,
                    color: TSColors.text,
                    weight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text: '. try to land within a few hours so the squad '
                      'can roll out together — not a hard rule.',
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _AnchorBadge extends StatelessWidget {
  const _AnchorBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: TSColors.lime.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TSColors.lime.withValues(alpha: 0.4)),
      ),
      child: Text('⚓ anchor',
          style: TSTextStyles.label(color: TSColors.lime, size: 9)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: TSColors.lime,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: TSColors.bg),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TSTextStyles.label(color: TSColors.bg, size: 12)),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: TSColors.border),
        ),
        child: Text(label,
            style: TSTextStyles.label(color: TSColors.text, size: 12)),
      ),
    );
  }
}
