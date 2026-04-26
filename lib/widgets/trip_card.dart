import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/haptics.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';
import 'motion.dart';
import 'weather_chip.dart';
import 'widgets.dart';

/// The new-design Trip Card.
///
/// Structure (redesign spec §5 Home Dashboard):
/// - Dark surface with destination photo at 20% opacity on the lower half.
/// - Flag + destination name in the upper-left.
/// - Phase-coloured status pill top-right.
/// - Response progress as dotted bar (filled = responded, empty = pending).
/// - Date context bottom-left.
/// - Tap → Trip Space.
class TripCard extends ConsumerWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.compactMargin = false,
  });
  final Trip trip;

  /// Set true when the card sits inside a grid cell (iPad home feed)
  /// — the card drops its own horizontal margin since grid spacing
  /// already separates cells.
  final bool compactMargin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadAsync = ref.watch(squadStreamProvider(trip.id));
    final members = squadAsync.maybeWhen(
      data: (m) => m,
      orElse: () => trip.squadMembers,
    );
    final responded =
        members.where((m) => m.status != MemberStatus.invited).length;
    final total = members.length;
    final avatars = ref.watch(squadAvatarsProvider).valueOrNull ??
        const <String, String?>{};

    final photoUrl = _hintPhotoFor(trip);

    // Does the current user still need to fill their preferences?
    // Only prompt when the trip is still collecting — if voting has
    // already started (or later), prefs are no longer useful; the
    // invitee should jump straight into the trip space to vote.
    final uid = ref.watch(supabaseProvider).auth.currentUser?.id;
    final myMember = uid == null
        ? null
        : members.where((m) => m.userId == uid).firstOrNull;
    final needsToFillPrefs =
        myMember?.status == MemberStatus.invited &&
            trip.status == TripStatus.collecting;
    // Late invitee during voting → skip prefs, just prompt them to vote.
    final needsToVote = myMember != null &&
        myMember.status != MemberStatus.voted &&
        trip.status == TripStatus.voting;

    final isMuted =
        ref.watch(mutedTripIdsProvider).valueOrNull?.contains(trip.id) ??
            false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TSHaptics.ctaTap();
        if (needsToFillPrefs) {
          context.push('/trip/${trip.id}/fill');
        } else {
          context.push('/trip/${trip.id}/space');
        }
      },
      onLongPress: () => _showTripMenu(context, ref, isMuted),
      child: Container(
        height: 160,
        margin: compactMargin
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(
                horizontal: TSSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: TSColors.s1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TSColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // Photo background at 20% opacity, bottom-aligned
          if (photoUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  placeholder: (_, __) => const SizedBox(),
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          // Legibility gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC0F0F1C),
                    Color(0x800F0F1C),
                    Color(0xE608080E),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: flag + destination + phase pill + unread dot
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (trip.selectedFlag != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        trip.selectedFlag!,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  Expanded(
                    child: Row(children: [
                      Flexible(
                        child: Text(
                          trip.selectedDestination ?? trip.name,
                          style: TSTextStyles.heading(size: 22),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ref
                          .watch(unreadTripIdsProvider)
                          .contains(trip.id)) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: TSColors.lime,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: TSColors.lime,
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isMuted) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.notifications_off_rounded,
                            color: TSColors.muted, size: 14),
                      ],
                    ]),
                  ),
                  if (trip.selectedDestination != null &&
                      trip.startDate != null) ...[
                    WeatherChip(
                        destination: trip.selectedDestination!,
                        date: trip.startDate!),
                    const SizedBox(width: 6),
                  ],
                  _PhasePill(status: trip.effectiveStatus),
                ]),

                const Spacer(),

                // Phase-aware CTA badge. Takes priority over the
                // response progress row so the action is unmistakable.
                if (needsToFillPrefs || needsToVote) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: TSColors.lime.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TSColors.lime),
                    ),
                    child: Text(
                      needsToFillPrefs
                          ? 'drop your vibes ✨'
                          : 'cast your vote 🗳️',
                      style: TSTextStyles.label(
                          color: TSColors.lime, size: 11),
                    ),
                  )
                      .animate(
                          onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          begin: 1.0,
                          end: 1.04,
                          duration: 900.ms,
                          curve: Curves.easeInOut),
                  const SizedBox(height: 8),
                ] else if (total > 0 && trip.mode != TripMode.solo) ...[
                  // The "X of Y responded" row only makes sense for
                  // group trips. On a solo trip it's always "1 of 1"
                  // which reads as filler — hide it.
                  Row(children: [
                    Text('$responded of $total',
                        style: TSTextStyles.caption(color: TSColors.text2)),
                    const SizedBox(width: 10),
                    ResponseDots(total: total, responded: responded),
                  ]),
                  const SizedBox(height: 8),
                ],

                // Bottom row: date context + avatar stack
                Row(children: [
                  Expanded(
                    child: Text(
                      _dateContext(trip),
                      style: TSTextStyles.caption(color: TSColors.muted),
                    ),
                  ),
                  if (members.isNotEmpty)
                    _AvatarStack(members: members, avatars: avatars),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _showTripMenu(
      BuildContext context, WidgetRef ref, bool isMuted) async {
    TSHaptics.medium();
    final name = trip.selectedDestination ?? trip.name;
    await showModalBottomSheet<void>(
      context: context,
      constraints: TSResponsive.modalConstraints,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(name, style: TSTextStyles.heading(size: 18)),
              const SizedBox(height: 12),
              _menuRow(
                icon: isMuted
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                label: isMuted ? 'unmute' : 'mute for 7 days',
                subtitle: isMuted
                    ? 'bring back unread dots + nav badge'
                    : 'hide unread dots + nav badge for a week',
                onTap: () async {
                  Navigator.of(sheet).pop();
                  await _toggleMute(ref, isMuted);
                },
              ),
              if (trip.startDate != null)
                _menuRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'add to calendar',
                  subtitle: 'pre-fills title, dates, destination',
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await _addToCalendar();
                  },
                ),
              if (trip.inviteToken != null)
                _menuRow(
                  icon: Icons.link_rounded,
                  label: 'copy invite link',
                  subtitle:
                      'gettripsquad.com/join/${trip.inviteToken}',
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    TSHaptics.light();
                    await Clipboard.setData(ClipboardData(
                        text:
                            'https://gettripsquad.com/join/${trip.inviteToken}'));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('invite link copied 📋',
                            style: TSTextStyles.body(
                                color: TSColors.bg, size: 13)),
                        backgroundColor: TSColors.lime,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              // Non-hosts can leave the trip.
              if (ref.read(supabaseProvider).auth.currentUser?.id !=
                  trip.hostId)
                _menuRow(
                  icon: Icons.logout_rounded,
                  label: 'leave trip',
                  subtitle: 'remove yourself from the squad',
                  destructive: true,
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await _leaveTrip(context, ref);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leaveTrip(BuildContext context, WidgetRef ref) async {
    TSHaptics.medium();
    // Bottom-sheet confirmation (same pattern as squad tab). AlertDialog
    // had rendering edge-cases on iOS that left a black screen.
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      constraints: TSResponsive.modalConstraints,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('leave ${trip.name}?',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'your votes + preferences will be removed. the host can add you back.',
                style: TSTextStyles.caption(color: TSColors.muted),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheet).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TSColors.s2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('stay',
                          style: TSTextStyles.title(
                              size: 13, color: TSColors.text)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheet).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TSColors.coral,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('leave',
                          style: TSTextStyles.title(
                              size: 13, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    // Capture the messenger BEFORE the delete so the snackbar still
    // fires after the trip card unmounts.
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(supabaseProvider);
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await db.from('votes')
          .delete().eq('trip_id', trip.id).eq('user_id', uid);
      await db.from('squad_members')
          .delete().eq('trip_id', trip.id).eq('user_id', uid);
      ref.invalidate(myTripsProvider);
      ref.invalidate(squadStreamProvider(trip.id));
      ref.invalidate(tripDetailProvider(trip.id));
      TSHaptics.ctaCommit();
      messenger.showSnackBar(
        SnackBar(
          content: Text('left ${trip.name} ✓',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('couldn\'t leave — $e',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Reuses the same Trip Space "add to calendar" path — all-day
  /// event, destination as location, invite link in description.
  Future<void> _addToCalendar() async {
    final start = trip.startDate;
    if (start == null) return;
    final endInclusive = trip.endDate ?? start;
    final endForNativeSheet = endInclusive.add(const Duration(days: 1));
    final event = a2c.Event(
      title:
          '${trip.selectedFlag ?? '✈️'} ${trip.selectedDestination ?? trip.name}',
      description: trip.inviteToken == null
          ? 'Planned with TripSquad'
          : 'Planned with TripSquad · https://gettripsquad.com/trip/${trip.inviteToken}',
      location: trip.selectedDestination,
      startDate: start,
      endDate: endForNativeSheet,
      allDay: true,
      iosParams: const a2c.IOSParams(reminder: Duration(days: 1)),
    );
    TSHaptics.ctaCommit();
    try {
      await a2c.Add2Calendar.addEvent2Cal(event);
    } catch (_) {/* silent */}
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final tint = destructive ? TSColors.coral : TSColors.lime;
    final labelColor = destructive ? TSColors.coral : TSColors.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, color: tint, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TSTextStyles.title(
                        size: 14, color: labelColor)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TSTextStyles.caption(
                        color: TSColors.muted2)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _toggleMute(WidgetRef ref, bool currentlyMuted) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'trip_muted_until_${trip.id}';
    if (currentlyMuted) {
      await prefs.remove(key);
    } else {
      final until = DateTime.now().add(const Duration(days: 7));
      await prefs.setString(key, until.toIso8601String());
    }
    ref.invalidate(mutedTripIdsProvider);
    TSHaptics.light();
  }

  String _dateContext(Trip t) {
    if (t.effectiveStatus == TripStatus.completed) {
      return 'completed';
    }
    if (t.startDate == null) return 'dates tbd';
    final days = t.startDate!
        .difference(DateTime.now())
        .inDays;
    if (days < 0) return 'on trip';
    if (days == 0) return 'today ✈️';
    if (days == 1) return 'tomorrow';
    if (days < 30) return 'starts in $days days';
    final months = (days / 30).floor();
    return 'starts in ~$months mo';
  }

  /// Photo for the card. Prefers a host-uploaded cover (stored on
  /// the trip row), else falls back to a lightweight Unsplash hint
  /// based on the destination. Returns null while the destination
  /// is still TBD.
  String? _hintPhotoFor(Trip t) {
    if (t.coverPhotoUrl != null && t.coverPhotoUrl!.isNotEmpty) {
      return t.coverPhotoUrl;
    }
    final dest = t.selectedDestination;
    if (dest == null || dest.isEmpty) return null;
    final q = Uri.encodeQueryComponent('$dest city');
    return 'https://source.unsplash.com/featured/640x320/?$q';
  }
}

/// Up to 4 overlapping squad avatars, with a "+N" bubble when there
/// are more. Photos come from `squadAvatarsProvider` (cached); falls
/// back to each member's emoji.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members, required this.avatars});
  final List<SquadMember> members;
  final Map<String, String?> avatars;

  static const _size = 22.0;
  static const _overlap = 14.0;

  @override
  Widget build(BuildContext context) {
    const maxShown = 4;
    final shown = members.take(maxShown).toList();
    final overflow = members.length - shown.length;
    final width = shown.length * (_size - _overlap) + _overlap +
        (overflow > 0 ? (_size - _overlap) : 0);
    return SizedBox(
      width: width,
      height: _size,
      child: Stack(children: [
        for (var i = 0; i < shown.length; i++)
          Positioned(
            left: i * (_size - _overlap),
            child: _avatar(shown[i]),
          ),
        if (overflow > 0)
          Positioned(
            left: shown.length * (_size - _overlap),
            child: Container(
              width: _size,
              height: _size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TSColors.s2,
                shape: BoxShape.circle,
                border: Border.all(color: TSColors.bg, width: 1.5),
              ),
              child: Text('+$overflow',
                  style:
                      TSTextStyles.label(color: TSColors.text, size: 8)),
            ),
          ),
      ]),
    );
  }

  Widget _avatar(SquadMember m) {
    final photoUrl = m.userId == null ? null : avatars[m.userId!];
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TSColors.bg, width: 1.5),
      ),
      child: ClipOval(
        child: TSAvatar(
          emoji: m.emoji ?? '😎',
          photoUrl: photoUrl,
          size: _size,
        ),
      ),
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    // Live gets a louder, breathing badge — it's the most important
    // state a user can be in and should pop off the card.
    if (status == TripStatus.live) {
      return const _LiveBadge();
    }
    final (label, variant) = switch (status) {
      TripStatus.collecting => ('collecting', TSPillVariant.gold),
      TripStatus.voting     => ('voting',     TSPillVariant.lime),
      TripStatus.revealed   => ('revealed',   TSPillVariant.purple),
      TripStatus.planning   => ('planning',   TSPillVariant.blue),
      TripStatus.live       => ('live ✈️',   TSPillVariant.lime),
      TripStatus.completed  => ('completed',  TSPillVariant.muted),
      TripStatus.draft      => ('draft',      TSPillVariant.muted),
    };
    return TSPill(label, variant: variant, small: true);
  }
}

/// Hero badge rendered when a trip is live. Bigger than the phase
/// pill, solid lime fill, a pulsing dot on the left, and a gentle
/// breathing shadow so the card feels "awake."
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TSColors.lime,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: TSColors.limeDim(0.55),
            blurRadius: 18,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        // Pulsing dot — flickers to signal "ongoing"
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: TSColors.bg,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .then()
            .fadeOut(duration: 600.ms, begin: 0.35),
        const SizedBox(width: 7),
        Text(
          'LIVE',
          style: TextStyle(
            fontFamily: 'Clash Display',
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.6,
            color: TSColors.bg,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 5),
        const Text('✈️', style: TextStyle(fontSize: 12)),
      ]),
    );

    // Gentle breathing — scale between 1.0 and 1.04 on a 1.6s cycle.
    // Just enough to suggest life without drawing constant attention.
    return badge
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.04, duration: 1600.ms, curve: Curves.easeInOut);
  }
}

