import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/responsive.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/add_by_tag_sheet.dart';
import '../../../widgets/trip_photos_sheet.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/tappable.dart';

/// Squad member list. Tap a member who has a registered user account to
/// open their profile. Web-only invitees (no user_id yet) show a hint.
class SquadTab extends ConsumerStatefulWidget {
  const SquadTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<SquadTab> createState() => _SquadTabState();
}

class _SquadTabState extends ConsumerState<SquadTab> {
  /// Cache of profile rows keyed by user_id. Populated once we see the
  /// squad stream so we can surface avatar_urls on each row.
  Map<String, Map<String, dynamic>> _profiles = {};
  String _lastFetchedFor = '';

  /// Realtime presence subscription for this trip's channel.
  /// Mirrors `presence:trip:<tripId>` used by the chat tab, so
  /// anyone viewing chat or squad counts as "online" across both.
  RealtimeChannel? _presence;
  final Set<String> _online = {};

  @override
  void initState() {
    super.initState();
    _subscribePresence();
  }

  @override
  void dispose() {
    _presence?.unsubscribe();
    super.dispose();
  }

  void _subscribePresence() {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    _presence = db.channel('presence:trip:${widget.trip.id}',
        opts: const RealtimeChannelConfig(self: true))
      ..onPresenceSync((_) => _syncPresence())
      ..subscribe((status, _) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _presence?.track({
            'user_id': uid,
            'at': DateTime.now().toIso8601String(),
          });
        }
      });
  }

  void _syncPresence() {
    if (!mounted) return;
    final state = _presence?.presenceState() ?? [];
    final online = <String>{};
    for (final group in state) {
      for (final p in group.presences) {
        final uid = p.payload['user_id'] as String? ?? '';
        if (uid.isNotEmpty) online.add(uid);
      }
    }
    setState(() {
      _online
        ..clear()
        ..addAll(online);
    });
  }

  Future<void> _refreshProfiles(List<SquadMember> squad) async {
    final ids = squad
        .map((m) => m.userId)
        .whereType<String>()
        .toSet()
        .toList();
    final key = ids.toList()..sort();
    final cacheKey = key.join(',');
    if (cacheKey == _lastFetchedFor) return;
    _lastFetchedFor = cacheKey;
    if (ids.isEmpty) return;
    final next =
        await ref.read(dmServiceProvider).fetchProfilesByIds(ids);
    if (!mounted) return;
    setState(() => _profiles = next);
  }

  @override
  Widget build(BuildContext context) {
    // v1.1 — solo trips render this tab as "Settings": the place
    // to bring friends in (convert to group) and delete the trip.
    // No squad list, no invite-by-tag — those don't apply.
    if (widget.trip.mode == TripMode.solo) {
      return _SoloSettingsBody(trip: widget.trip);
    }
    final squadAsync = ref.watch(squadStreamProvider(widget.trip.id));
    return squadAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: TSColors.lime)),
      error: (e, _) => Center(child: Text(humanizeError(e))),
      data: (squad) {
        // Fire-and-forget profile fetch — runs once per unique member set.
        _refreshProfiles(squad);

        final meUid = Supabase.instance.client.auth.currentUser?.id;
        final sorted = [...squad]..sort((a, b) {
          final aIsMe = meUid != null && a.userId == meUid;
          final bIsMe = meUid != null && b.userId == meUid;
          if (aIsMe && !bIsMe) return -1;
          if (!aIsMe && bIsMe) return 1;
          final aIsHost = a.role == MemberRole.host;
          final bIsHost = b.role == MemberRole.host;
          if (aIsHost && !bIsHost) return -1;
          if (!aIsHost && bIsHost) return 1;
          return 0;
        });
        // Host-only affordance. Non-host members don't see "invite more"
        // because the invite token belongs to the host and invites open
        // in their name.
        final isHost = meUid != null && widget.trip.hostId == meUid;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${sorted.length} in the squad',
                style: TSTextStyles.heading(size: 20)),
            const SizedBox(height: 12),
            for (final m in sorted)
              _SquadRow(
                member: m,
                isMe: meUid != null && m.userId == meUid,
                isOnline:
                    m.userId != null && _online.contains(m.userId!),
                photoUrl: m.userId == null
                    ? null
                    : _profiles[m.userId!]?['avatar_url'] as String?,
                canNudge: isHost &&
                    m.userId != null &&
                    m.userId != meUid &&
                    m.status == MemberStatus.invited,
                canKick: isHost &&
                    m.role != MemberRole.host &&
                    m.userId != meUid,
                canLeave: !isHost &&
                    meUid != null &&
                    m.userId == meUid &&
                    m.role != MemberRole.host,
                tripName: widget.trip.selectedDestination ?? widget.trip.name,
              ),
            const SizedBox(height: 16),
            _PhotosGalleryRow(tripId: widget.trip.id),
            const SizedBox(height: 8),
            _ExportChatRow(trip: widget.trip),
            if (!isHost && meUid != null) ...[
              const SizedBox(height: 16),
              _LeaveTripRow(trip: widget.trip),
            ],
            if (isHost) ...[
              const SizedBox(height: 12),
              // Completed trips swap the "invite more" + "add by tag"
              // pair for a "plan again" CTA — the trip is done, no
              // new seats to fill.
              if (widget.trip.effectiveStatus == TripStatus.completed)
                _PlanAgainRow(trip: widget.trip)
              else ...[
                _InviteMoreRow(
                  tripId: widget.trip.id,
                  squadSize: sorted.length,
                ),
                const SizedBox(height: 8),
                _AddByTagRow(
                  tripId: widget.trip.id,
                  tripName: widget.trip.selectedDestination ??
                      widget.trip.name,
                  existingUserIds: sorted
                      .map((m) => m.userId)
                      .whereType<String>()
                      .toSet(),
                ),
                if (widget.trip.inviteToken != null) ...[
                  const SizedBox(height: 8),
                  _CopyLinkRow(token: widget.trip.inviteToken!),
                ],
                const SizedBox(height: 8),
                _ShareSummaryRow(trip: widget.trip, squad: sorted),
                const SizedBox(height: 8),
                _CoverPhotoRow(trip: widget.trip),
              ],
              const SizedBox(height: 24),
              DeleteTripRow(trip: widget.trip),
            ],
          ],
        );
      },
    );
  }
}

/// Host-only "+ invite more" tile at the end of the squad list.
/// Opens the existing Invite Ceremony (Boarding Pass + share flow) so
/// the invite experience is consistent whether you're inviting on trip
/// creation or adding someone later.
class _InviteMoreRow extends StatelessWidget {
  const _InviteMoreRow({
    required this.tripId,
    required this.squadSize,
  });

  final String tripId;
  final int squadSize;

  @override
  Widget build(BuildContext context) {
    return TSTappable(
      onTap: () {
        TSHaptics.ctaCommit();
        context.push('/trip/$tripId/invite');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: TSColors.limeDim(0.4),
            width: 1.2,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TSColors.limeDim(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: TSColors.lime,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('invite more',
                    style: TSTextStyles.title(
                        size: 15, color: TSColors.lime)),
                Text(
                  '$squadSize in the squad',
                  style: TSTextStyles.caption(color: TSColors.muted2),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: TSColors.lime,
            size: 14,
          ),
        ]),
      ),
    );
  }
}

/// "📤 export chat transcript" tile — dumps the whole trip chat
/// as plain text to the system share sheet so anyone can save /
/// forward it. Available to every squad member.
class _ExportChatRow extends ConsumerWidget {
  const _ExportChatRow({required this.trip});
  final Trip trip;

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    TSHaptics.light();
    try {
      final rows = await Supabase.instance.client
          .from('chat_messages')
          .select('nickname, content, created_at')
          .eq('trip_id', trip.id)
          .order('created_at', ascending: true);
      if ((rows as List).isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('no messages to export yet',
                style: TSTextStyles.body(color: TSColors.bg, size: 13)),
            backgroundColor: TSColors.lime,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      final lines = <String>[];
      lines.add('# ${trip.selectedDestination ?? trip.name} — chat transcript');
      lines.add('');
      for (final r in rows) {
        final m = r as Map<String, dynamic>;
        final nick = (m['nickname'] as String?) ?? 'someone';
        final content = (m['content'] as String?) ?? '';
        lines.add('$nick: $content');
      }
      lines.add('');
      lines.add('exported from tripsquad · https://gettripsquad.com');
      final text = lines.join('\n');
      Rect? origin;
      try {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          origin = box.localToGlobal(Offset.zero) & box.size;
        }
      } catch (_) {}
      await Share.share(text,
          subject: '${trip.selectedDestination ?? trip.name} chat',
          sharePositionOrigin: origin);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t export — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TSTappable(
      onTap: () => _export(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TSColors.border),
        ),
        child: Row(children: [
          const Text('📤', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('export chat transcript',
                    style: TSTextStyles.body(
                        size: 13, color: TSColors.text)),
                Text('copy / share everything posted in chat',
                    style: TSTextStyles.caption(color: TSColors.muted2)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.muted, size: 14),
        ]),
      ),
    );
  }
}

/// "📸 squad photos" tile — visible to every squad member. Opens
/// a grid of every image that's been dropped into the trip chat
/// so the crew can revisit the album from one place.
class _PhotosGalleryRow extends StatelessWidget {
  const _PhotosGalleryRow({required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return TSTappable(
      onTap: () {
        TSHaptics.light();
        TripPhotosSheet.show(context, tripId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TSColors.border),
        ),
        child: Row(children: [
          const Text('📸', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('squad photos',
                    style: TSTextStyles.body(
                        size: 13, color: TSColors.text)),
                Text('everything you\'ve dropped in chat',
                    style: TSTextStyles.caption(color: TSColors.muted2)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.muted, size: 14),
        ]),
      ),
    );
  }
}

/// Host-only "delete trip" tile — wipes the trip + all related
/// rows (RLS + CASCADE handle the cleanup). Sits at the very
/// bottom of the Squad tab so it's reachable but not
/// accidentally-tappable.
///
/// v1.1 — public so it can be reused on the Status tab (collecting
/// state, where the host might want to delete an unstarted trip
/// without committing to generate options).
class DeleteTripRow extends ConsumerWidget {
  const DeleteTripRow({super.key, required this.trip});
  final Trip trip;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    TSHaptics.medium();
    final name = trip.selectedDestination ?? trip.name;
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('delete $name?',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'this wipes the trip for everyone in the squad — chat, votes, plans, all of it. there\'s no undo.',
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
                      child: Text('keep it',
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
                      child: Text('delete',
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
    try {
      await ref.read(tripServiceProvider).deleteTrip(trip.id);
      ref.invalidate(myTripsProvider);
      if (!context.mounted) return;
      context.go('/trips');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t delete — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TSTappable(
      onTap: () => _confirmDelete(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TSColors.coral.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.delete_outline_rounded,
              color: TSColors.coral, size: 16),
          const SizedBox(width: 10),
          Text('delete trip',
              style:
                  TSTextStyles.title(size: 13, color: TSColors.coral)),
        ]),
      ),
    );
  }
}

/// Non-host "leave trip" tile — mirror of the host's kick flow
/// but for the current user. Finds the current user's own squad
/// row and delegates to the same removeMember service.
class _LeaveTripRow extends ConsumerWidget {
  const _LeaveTripRow({required this.trip});
  final Trip trip;

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    // Resolve the current user's own squad_member row.
    final squad = await ref
        .read(squadStreamProvider(trip.id).future)
        .catchError((_) => const <SquadMember>[]);
    final mine = squad.where((m) => m.userId == uid).toList();
    if (mine.isEmpty) return;
    final member = mine.first;
    if (!context.mounted) return;

    TSHaptics.medium();
    final name = trip.selectedDestination ?? trip.name;
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('leave $name?',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'you\'ll drop out of the squad and any votes you\'ve cast will disappear. the host can add you back.',
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
    try {
      await ref.read(tripServiceProvider).removeMember(
            memberId: member.id,
            tripId: trip.id,
            userId: uid,
          );
      if (!context.mounted) return;
      context.go('/trips');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t leave — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TSTappable(
      onTap: () => _confirmLeave(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TSColors.coral.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.logout_rounded,
              color: TSColors.coral, size: 16),
          const SizedBox(width: 10),
          Text('leave trip',
              style:
                  TSTextStyles.title(size: 13, color: TSColors.coral)),
        ]),
      ),
    );
  }
}

/// Host-only "📝 share summary" — produces a plain-text rollup of
/// the trip (destination · dates · squad · vibes · invite link)
/// and hands it to the share sheet. Useful for pasting into a
/// group chat, an email, or Notes.
class _ShareSummaryRow extends StatelessWidget {
  const _ShareSummaryRow({required this.trip, required this.squad});
  final Trip trip;
  final List<SquadMember> squad;

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _buildSummary() {
    final dest = trip.selectedDestination ?? trip.name;
    final flag = trip.selectedFlag ?? '✈️';
    final lines = <String>[];
    lines.add('$flag  $dest');
    if (trip.startDate != null) {
      final s = trip.startDate!;
      final e = trip.endDate;
      if (e != null) {
        if (s.year == e.year && s.month == e.month) {
          lines.add(
              '${_months[s.month]} ${s.day}–${e.day}, ${e.year}');
        } else {
          lines.add(
              '${_months[s.month]} ${s.day} – ${_months[e.month]} ${e.day}, ${e.year}');
        }
      } else {
        lines.add('${_months[s.month]} ${s.day}, ${s.year}');
      }
    }
    if (squad.isNotEmpty) {
      final names = squad.map((m) => m.nickname).join(', ');
      lines.add('squad: $names (${squad.length})');
    }
    final vibes = trip.vibes ?? const <String>[];
    if (vibes.isNotEmpty) {
      lines.add('vibe: ${vibes.join(', ')}');
    }
    if (trip.inviteToken != null) {
      lines.add('');
      lines.add('join: https://gettripsquad.com/join/${trip.inviteToken}');
    }
    lines.add('');
    lines.add('planned with tripsquad ✦');
    return lines.join('\n');
  }

  Future<void> _share(BuildContext context) async {
    TSHaptics.ctaTap();
    Rect? origin;
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}
    try {
      await Share.share(
        _buildSummary(),
        subject: 'trip · ${trip.selectedDestination ?? trip.name}',
        sharePositionOrigin: origin,
      );
    } catch (_) {/* silent */}
  }

  @override
  Widget build(BuildContext context) {
    return TSTappable(
      onTap: () => _share(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TSColors.border),
        ),
        child: Row(children: [
          const Text('📝', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('share trip summary',
                    style:
                        TSTextStyles.body(size: 13, color: TSColors.text)),
                Text('destination, dates, squad, vibes, invite link',
                    style: TSTextStyles.caption(color: TSColors.muted2)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.muted, size: 14),
        ]),
      ),
    );
  }
}

/// Host-only "🖼️ cover photo" — picks an image from the camera
/// roll and uploads it as the trip's cover. Overrides the default
/// Unsplash destination hint on trip cards. Long-press to remove.
class _CoverPhotoRow extends ConsumerStatefulWidget {
  const _CoverPhotoRow({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_CoverPhotoRow> createState() => _CoverPhotoRowState();
}

class _CoverPhotoRowState extends ConsumerState<_CoverPhotoRow> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _busy = true);
    TSHaptics.ctaCommit();
    try {
      await ref.read(tripServiceProvider).uploadCoverPhoto(
            tripId: widget.trip.id,
            filePath: file.path,
          );
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cover updated',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t upload — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    if (_busy) return;
    setState(() => _busy = true);
    TSHaptics.medium();
    try {
      await ref.read(tripServiceProvider).clearCoverPhoto(widget.trip.id);
      ref.invalidate(myTripsProvider);
    } catch (_) {/* silent */}
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = (widget.trip.coverPhotoUrl ?? '').isNotEmpty;
    return GestureDetector(
      onLongPress: hasCover ? _clear : null,
      child: TSTappable(
        onTap: _pick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: TSColors.s2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TSColors.border),
          ),
          child: Row(children: [
            if (_busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: TSColors.lime),
              )
            else
              const Text('🖼️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hasCover ? 'cover photo · set' : 'set a cover photo',
                      style: TSTextStyles.body(
                          size: 13, color: TSColors.text)),
                  Text(
                    hasCover
                        ? 'tap to change · long-press to remove'
                        : 'override the default destination image',
                    style: TSTextStyles.caption(color: TSColors.muted2),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: TSColors.muted, size: 14),
          ]),
        ),
      ),
    );
  }
}

/// Host-only "📋 copy invite link" — fastest path for inviting
/// when you just want to paste the URL into an existing chat. For
/// the full Stories-sized boarding pass share, hosts still use the
/// main "invite more" CTA above.
class _CopyLinkRow extends StatelessWidget {
  const _CopyLinkRow({required this.token});
  final String token;

  String get _url => 'https://gettripsquad.com/join/$token';

  Future<void> _copy(BuildContext context) async {
    TSHaptics.light();
    await Clipboard.setData(ClipboardData(text: _url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('invite link copied 📋',
            style: TSTextStyles.body(color: TSColors.bg, size: 13)),
        backgroundColor: TSColors.lime,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TSTappable(
      onTap: () => _copy(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TSColors.border),
        ),
        child: Row(children: [
          const Text('📋', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('copy invite link',
                style: TSTextStyles.body(size: 13, color: TSColors.text)),
          ),
          Text(
            _url.replaceFirst('https://', ''),
            style: TSTextStyles.caption(color: TSColors.muted2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}

/// Host-only "🔁 plan again with this squad" action for completed
/// trips. Creates a new draft trip seeded from the current one's
/// name + vibes and re-invites every registered squadmate, then
/// routes to the new trip's Trip Space.
class _PlanAgainRow extends ConsumerStatefulWidget {
  const _PlanAgainRow({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_PlanAgainRow> createState() => _PlanAgainRowState();
}

class _PlanAgainRowState extends ConsumerState<_PlanAgainRow> {
  bool _busy = false;

  Future<void> _clone() async {
    if (_busy) return;
    setState(() => _busy = true);
    TSHaptics.ctaCommit();
    try {
      final next = await ref
          .read(tripServiceProvider)
          .cloneTripWithSquad(widget.trip);
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      context.go('/trip/${next.id}/space');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t plan again — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TSTappable(
      onTap: _busy ? () {} : _clone,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TSColors.limeDim(0.4), width: 1.2),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TSColors.limeDim(0.12),
              shape: BoxShape.circle,
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: TSColors.lime),
                  )
                : const Text('🔁', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('plan another with this squad',
                    style: TSTextStyles.title(
                        size: 15, color: TSColors.lime)),
                Text('same vibe, new destination — we\'ll invite them for you',
                    style: TSTextStyles.caption(color: TSColors.muted2)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.lime, size: 14),
        ]),
      ),
    );
  }
}

/// Host-only "@ add by tag" tile. Opens the tag-search bottom sheet
/// and adds an existing TripSquad user to the squad directly (no
/// share link round-trip). Handy when the friend's already on the
/// app.
class _AddByTagRow extends StatelessWidget {
  const _AddByTagRow({
    required this.tripId,
    required this.tripName,
    required this.existingUserIds,
  });
  final String tripId;
  final String tripName;
  final Set<String> existingUserIds;

  @override
  Widget build(BuildContext context) {
    return TSTappable(
      onTap: () {
        TSHaptics.light();
        AddByTagSheet.show(
          context,
          tripId: tripId,
          tripName: tripName,
          existingUserIds: existingUserIds,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TSColors.border2),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: TSColors.s2,
              shape: BoxShape.circle,
            ),
            child: Text('@',
                style: TSTextStyles.heading(
                    size: 18, color: TSColors.lime)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('add by @tag',
                    style:
                        TSTextStyles.title(size: 15, color: TSColors.text)),
                Text('already on tripsquad? add them straight in',
                    style: TSTextStyles.caption(color: TSColors.muted2)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.muted, size: 14),
        ]),
      ),
    );
  }
}

class _SquadRow extends ConsumerWidget {
  const _SquadRow({
    required this.member,
    required this.isMe,
    required this.isOnline,
    required this.photoUrl,
    required this.canNudge,
    required this.canKick,
    required this.canLeave,
    required this.tripName,
  });
  final SquadMember member;
  final bool isMe;
  final bool isOnline;
  final String? photoUrl;
  final bool canNudge;
  final bool canKick;
  final bool canLeave;
  final String tripName;

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    TSHaptics.medium();
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('leave $tripName?',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'you\'ll drop out of the squad and any votes you\'ve cast will disappear. the host can add you back.',
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
    // Capture messenger + router BEFORE navigation so the snackbar
    // survives the widget unmount.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(tripServiceProvider).removeMember(
            memberId: member.id,
            tripId: member.tripId,
            userId: member.userId,
          );
      ref.invalidate(myTripsProvider);
      ref.invalidate(squadStreamProvider(member.tripId));
      router.go('/home');
      messenger.showSnackBar(
        SnackBar(
          content: Text('you\'ve left $tripName ✓',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('couldn\'t leave — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmKick(BuildContext context, WidgetRef ref) async {
    TSHaptics.medium();
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('remove ${member.nickname}?',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'they\'ll be pulled from the squad and any votes they\'ve cast will drop. you can always add them back.',
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
                      child: Text('cancel',
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
                      child: Text('remove',
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
    try {
      await ref.read(tripServiceProvider).removeMember(
            memberId: member.id,
            tripId: member.tripId,
            userId: member.userId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.nickname} removed',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t remove — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _nudge(BuildContext context, WidgetRef ref) async {
    final toUser = member.userId;
    if (toUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'nudged_${toUser}_on_${member.tripId}';
    final last = prefs.getString(key);
    final now = DateTime.now();
    if (last != null) {
      final lastAt = DateTime.tryParse(last);
      if (lastAt != null && now.difference(lastAt).inHours < 24) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('already nudged today — give them a minute',
                style: TSTextStyles.body(color: TSColors.bg, size: 13)),
            backgroundColor: TSColors.lime,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    TSHaptics.ctaCommit();
    try {
      await ref.read(dmServiceProvider).send(
            toUser: toUser,
            content: 'just nudging — still waiting on your prefs for $tripName 👀',
          );
      await prefs.setString(key, now.toIso8601String());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('nudged ${member.nickname} 🔔',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t send — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRegistered = member.userId != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: canKick
          ? () => _confirmKick(context, ref)
          : (canLeave ? () => _confirmLeave(context, ref) : null),
      child: TSTappable(
      onTap: () {
        if (isMe) {
          TSHaptics.light();
          context.go('/profile');
          return;
        }
        if (!isRegistered) {
          TSHaptics.light();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.nickname} hasn\'t joined the app yet',
                  style: TSTextStyles.body(color: TSColors.bg)),
              backgroundColor: TSColors.lime,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        TSHaptics.light();
        context.push('/user/${member.userId}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? TSColors.limeDim(0.08) : Colors.transparent,
          borderRadius: TSRadius.sm,
          border: isMe
              ? Border.all(color: TSColors.limeDim(0.35))
              : null,
        ),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            TSAvatar(
              emoji: member.emoji ?? '😎',
              photoUrl: photoUrl,
              size: 36,
            ),
            if (isMe)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: TSColors.lime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: TSColors.bg, size: 10),
                ),
              )
            else if (isOnline)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: TSColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: TSColors.bg, width: 2),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(member.nickname, style: TSTextStyles.body()),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text('(you)',
                          style:
                              TSTextStyles.caption(color: TSColors.lime)),
                    ],
                    if (member.role == MemberRole.host) ...[
                      const SizedBox(width: 6),
                      Text('· host',
                          style: TSTextStyles.caption(color: TSColors.lime)),
                    ],
                  ]),
                  if (!isRegistered && !isMe)
                    Text('joined via web link',
                        style: TSTextStyles.caption(color: TSColors.muted)),
                ]),
          ),
          TSPill(
            member.status.name,
            variant: isMe ? TSPillVariant.lime : TSPillVariant.muted,
            small: true,
          ),
          if (canNudge) ...[
            const SizedBox(width: 8),
            TSTappable(
              onTap: () => _nudge(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TSColors.limeDim(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TSColors.limeDim(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🔔', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text('nudge',
                      style: TSTextStyles.label(
                          color: TSColors.lime, size: 10)),
                ]),
              ),
            ),
          ],
          if (isRegistered && !isMe) ...[
            const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                TSHaptics.light();
                context.push('/messages/${member.userId}');
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    color: TSColors.text2, size: 18),
              ),
            ),
          ],
          if (isRegistered && !isMe && !canNudge) ...[
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: TSColors.muted, size: 14),
          ],
        ]),
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _SoloSettingsBody — what the "settings" tab renders for solo
// ─────────────────────────────────────────────────────────────
//
//  v1.1. Solo trips reuse this tab slot (originally "squad") for
//  trip-level settings: bring friends in (one-way conversion to
//  group) + delete trip. No squad list, no invite-by-tag — those
//  are group-only concepts.
//
class _SoloSettingsBody extends ConsumerStatefulWidget {
  const _SoloSettingsBody({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_SoloSettingsBody> createState() =>
      _SoloSettingsBodyState();
}

class _SoloSettingsBodyState extends ConsumerState<_SoloSettingsBody> {
  bool _converting = false;
  final _tagCtrl = TextEditingController();
  List<Map<String, dynamic>> _tagResults = [];
  bool _searching = false;
  bool _adding = false;

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchTag(String q) async {
    if (q.trim().length < 2) {
      setState(() => _tagResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(tripServiceProvider).searchByTag(q);
      if (mounted) {
        setState(() {
          _tagResults = results;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addByTag(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    final myUid = Supabase.instance.client.auth.currentUser?.id;

    // Guardrails BEFORE flipping mode. We don't want to half-convert
    // the trip to group when the add itself is going to fail.
    if (userId == myUid) {
      _toast("that's you — can't add yourself", isError: true);
      return;
    }
    final already = await Supabase.instance.client
        .from('squad_members')
        .select('id')
        .eq('trip_id', widget.trip.id)
        .eq('user_id', userId)
        .maybeSingle();
    if (already != null) {
      _toast('@${user['tag']} is already in this trip', isError: true);
      return;
    }

    setState(() => _adding = true);
    try {
      // Mode flip + member insert. Order matters: convert first so
      // the squad_member insert lands on a group trip, not a solo
      // trip's hidden squad list.
      await ref.read(tripServiceProvider).convertToGroup(widget.trip.id);
      await ref.read(tripServiceProvider).addMemberByTag(
            tripId: widget.trip.id,
            userId: userId,
            nickname: (user['nickname'] ?? user['tag']) as String,
            emoji: (user['emoji'] as String?) ?? '😎',
          );
      ref.invalidate(myTripsProvider);
      ref.invalidate(squadStreamProvider(widget.trip.id));
      TSHaptics.success();
      if (!mounted) return;
      _tagCtrl.clear();
      setState(() => _tagResults = []);
      _toast('@${user['tag']} added — trip is now a squad trip ✈');
    } catch (e) {
      if (!mounted) return;
      _toast(humanizeError(e), isError: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? TSColors.coral : TSColors.lime,
      behavior: SnackBarBehavior.floating,
      content: Text(message,
          style: TSTextStyles.body(color: TSColors.bg, size: 13)),
    ));
  }

  Future<void> _convert() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TSColors.s2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('bring friends in?',
            style: TSTextStyles.heading(size: 18)),
        content: Text(
          "this turns the trip into a squad trip. you'll get an "
          "invite link to share. everything you've planned so far "
          "stays. you can't switch back to solo after this.",
          style: TSTextStyles.body(color: TSColors.text2, size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('not yet',
                style: TSTextStyles.label(color: TSColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('yes, share invite',
                style: TSTextStyles.label(color: TSColors.lime)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _converting = true);
    try {
      await ref.read(tripServiceProvider).convertToGroup(widget.trip.id);
      ref.invalidate(myTripsProvider);
      TSHaptics.success();
      if (!mounted) return;
      context.push('/trip/${widget.trip.id}/invite');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: TSColors.coral,
        behavior: SnackBarBehavior.floating,
        content: Text("couldn't convert — try again",
            style: TSTextStyles.body(color: TSColors.bg, size: 13)),
      ));
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      children: [
        // "Solo trip" badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: TSColors.s2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TSColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🧳', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text('solo trip',
                style: TSTextStyles.label(color: TSColors.text2, size: 11)),
          ]),
        ),
        const SizedBox(height: 18),

        // Bring friends in — primary action
        GestureDetector(
          onTap: _converting ? null : _convert,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TSColors.limeDim(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TSColors.limeDim(0.28)),
            ),
            child: Row(children: [
              const Text('👥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('bring friends in',
                        style: TSTextStyles.title(size: 15)),
                    const SizedBox(height: 2),
                    Text(
                      "turn this into a squad trip — keep everything you've planned.",
                      style: TSTextStyles.caption(color: TSColors.muted),
                    ),
                  ],
                ),
              ),
              if (_converting)
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: TSColors.lime),
                )
              else
                Icon(Icons.chevron_right,
                    color: TSColors.muted, size: 20),
            ]),
          ),
        ),

        const SizedBox(height: 18),

        // Or — add by @tag inline. Skips the link-share ceremony
        // for users who already know who they want to invite.
        Text('or add by @tag',
            style: TSTextStyles.label(color: TSColors.muted, size: 11)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: TSColors.s2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TSColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text('@',
                style: TSTextStyles.body(color: TSColors.muted, size: 16)),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                onChanged: _searchTag,
                style: TSTextStyles.body(color: TSColors.text, size: 14),
                decoration: InputDecoration(
                  hintText: 'their tripsquad tag',
                  hintStyle: TSTextStyles.body(
                      color: TSColors.muted, size: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_searching)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: TSColors.lime),
              ),
          ]),
        ),
        if (_tagResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._tagResults.map((user) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: GestureDetector(
                  onTap: _adding ? null : () => _addByTag(user),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TSColors.s2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TSColors.border),
                    ),
                    child: Row(children: [
                      Text(user['emoji'] as String? ?? '😎',
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@${user['tag']}',
                                style: TSTextStyles.title(size: 13)),
                            if ((user['nickname'] as String?)?.isNotEmpty ?? false)
                              Text(user['nickname'] as String,
                                  style: TSTextStyles.caption(
                                      color: TSColors.muted)),
                          ],
                        ),
                      ),
                      if (_adding)
                        const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: TSColors.lime))
                      else
                        Icon(Icons.add_circle_outline,
                            color: TSColors.lime, size: 20),
                    ]),
                  ),
                ),
              )),
        ],

        const SizedBox(height: 32),

        // Danger zone — delete reuses the existing DeleteTripRow
        // higher up in this file (works for any trip mode).
        DeleteTripRow(trip: widget.trip),
      ],
    );
  }
}
