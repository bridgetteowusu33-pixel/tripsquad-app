import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

/// Privacy-aware public profile. What a user can see depends on the
/// viewed profile's `privacy_level`:
///   - public  → nickname, emoji, @tag, travel_style, home_city, passports,
///               trips_completed, join date
///   - friends → same as public only if viewer shares a trip with them
///   - private → minimal card ("this profile is private")
///
/// Actions available from any profile:
///   - 💬 DM
///   - ➕ invite to a trip you host
///   - 👋 wave (Match v1.1; placeholder for now)
class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(tripServiceProvider)
          .fetchPublicProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = humanizeError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final isMe = me == widget.userId;
    final isBlocked = _profile?['blocked'] == true;

    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: TSAppBar(
        title: 'profile',
        trailing: (!isMe && _profile != null)
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: TSColors.text),
                color: TSColors.s2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'block') _confirmBlock();
                  if (v == 'unblock') _unblock();
                  if (v == 'report') _reportUser();
                },
                itemBuilder: (_) => [
                  if (!isBlocked)
                    PopupMenuItem(
                      value: 'block',
                      child: Text('🚫  block user',
                          style: TSTextStyles.body(color: TSColors.coral)),
                    ),
                  if (isBlocked)
                    PopupMenuItem(
                      value: 'unblock',
                      child: Text('✅  unblock user',
                          style: TSTextStyles.body(color: TSColors.lime)),
                    ),
                  PopupMenuItem(
                    value: 'report',
                    child: Text('🚩  report user',
                        style: TSTextStyles.body()),
                  ),
                ],
              )
            : null,
      ),
      body: SafeArea(child: _body(isMe)),
    );
  }

  Widget _body(bool isMe) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: TSColors.lime));
    }
    if (_error != null) return Center(child: Text(_error!));
    final p = _profile;
    if (p == null) {
      return const Center(
          child: Text('profile not found', style: TextStyle(color: TSColors.muted)));
    }
    final privacy = (p['privacy_level'] as String?) ?? 'private';
    // Server-side `visible=true` means privacy checks allow full details.
    final hasDetails = p['visible'] == true;
    final isBlocked = p['blocked'] == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _Header(profile: p),
        const SizedBox(height: 20),

        // Blocked state — overrides everything else
        if (isBlocked && !isMe) ...[
          TSCard(
            borderColor: TSColors.coralDim(0.3),
            child: Row(children: [
              const Text('🚫', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'you\'ve blocked this user. they can\'t send you DMs or find you in search.',
                  style: TSTextStyles.body(
                      color: TSColors.text2, size: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          TSButton(
            label: '✅ unblock user',
            variant: TSButtonVariant.outline,
            onTap: _unblock,
          ),
        ] else ...[
          // Private-profile explainer
          if (!hasDetails && !isMe) ...[
            TSCard(
              borderColor: TSColors.border2,
              child: Row(children: [
                const Text('🔒', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    privacy == 'friends'
                        ? 'this profile is friends-only. take a trip together to see more.'
                        : 'this profile is private.',
                    style: TSTextStyles.body(color: TSColors.muted, size: 13),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Kudos strip (visible to anyone who can see the profile)
          if (hasDetails) ...[
            _KudosStrip(userId: widget.userId),
            const SizedBox(height: 20),
            const SectionLabel(label: 'details'),
            const SizedBox(height: 8),
            _Detail(
              emoji: '✈️',
              label: 'home airport',
              value: p['home_city'] != null
                  ? '${p['home_city']} (${p['home_airport'] ?? ''})'
                  : 'not set',
            ),
            _Detail(
              emoji: '💸',
              label: 'travel style',
              value: (p['travel_style'] as String?) ?? 'not set',
            ),
            _Detail(
              emoji: '🛂',
              label: 'passports',
              value: ((p['passports'] as List?)?.isNotEmpty ?? false)
                  ? '${(p['passports'] as List).length} countries'
                  : 'not set',
            ),
            _Detail(
              emoji: '🎯',
              label: 'trips completed',
              value: '${p['trips_completed'] ?? 0}',
            ),
            const SizedBox(height: 20),
          ],

          // Actions (disabled when viewing self)
          if (!isMe) ...[
            const SectionLabel(label: 'actions'),
            const SizedBox(height: 10),
            TSButton(
              label: '💬 send message',
              onTap: () {
                TSHaptics.light();
                context.push('/messages/${widget.userId}');
              },
            ),
            const SizedBox(height: 10),
            TSButton(
              label: '➕ invite to a trip',
              variant: TSButtonVariant.outline,
              onTap: () {
                TSHaptics.light();
                _showInviteSheet(context);
              },
            ),
            const SizedBox(height: 10),
            TSButton(
              label: '👋 wave (coming with match)',
              variant: TSButtonVariant.outline,
              onTap: () {
                TSHaptics.light();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('match is coming in v1.1 ✦'),
                  ),
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _confirmBlock() async {
    TSHaptics.medium();
    final tag = _profile?['tag'] as String?;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TSColors.s2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('block @${tag ?? 'user'}?',
            style: TSTextStyles.heading(size: 17, color: TSColors.coral)),
        content: Text(
          'they won\'t be able to message you, see you in search, or view your profile. you won\'t see theirs either. you\'ll stay in any shared trips — you can leave those separately.',
          style: TSTextStyles.body(size: 13, color: TSColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel',
                style: TSTextStyles.title(color: TSColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('block',
                style: TSTextStyles.title(color: TSColors.coral)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(blockServiceProvider).block(widget.userId);
      TSHaptics.success();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(e))),
      );
    }
  }

  Future<void> _unblock() async {
    TSHaptics.light();
    try {
      await ref.read(blockServiceProvider).unblock(widget.userId);
      TSHaptics.success();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(e))),
      );
    }
  }

  Future<void> _reportUser() async {
    TSHaptics.light();
    final tag = _profile?['tag'] as String? ?? widget.userId;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TSColors.s2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('report sent',
            style: TSTextStyles.heading(size: 17)),
        content: Text(
          'thanks for flagging @$tag — our team reviews every report. consider blocking them so they can\'t reach you in the meantime.',
          style: TSTextStyles.body(size: 13, color: TSColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('got it',
                style: TSTextStyles.title(color: TSColors.lime)),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteSheet(BuildContext context) async {
    final trips = await ref.read(tripServiceProvider).fetchMyTrips();
    final eligible = trips
        .where((t) =>
            t.status != TripStatus.completed &&
            t.status != TripStatus.live)
        .toList();
    if (!context.mounted) return;
    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no active trips to invite to')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TSColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('invite to which trip?',
                style: TSTextStyles.heading(size: 18)),
            const SizedBox(height: 8),
            ...eligible.map((t) => ListTile(
                  leading: Text(t.selectedFlag ?? '✈️',
                      style: const TextStyle(fontSize: 20)),
                  title: Text(
                      t.selectedDestination ?? t.name,
                      style: TSTextStyles.body()),
                  subtitle: Text(t.status.name,
                      style: TSTextStyles.caption(color: TSColors.muted)),
                  onTap: () async {
                    Navigator.pop(sheet);
                    await _inviteToTrip(t);
                  },
                )),
          ]),
        ),
      ),
    );
  }

  Future<void> _inviteToTrip(Trip trip) async {
    try {
      final p = _profile!;
      await Supabase.instance.client.from('squad_members').upsert({
        'trip_id': trip.id,
        'user_id': widget.userId,
        'nickname': (p['nickname'] as String?) ?? 'Traveller',
        'emoji': (p['emoji'] as String?) ?? '😎',
        'tag': p['tag'],
        'status': 'invited',
      });
      TSHaptics.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('invited @${p['tag'] ?? 'them'} to ${trip.name} ✦',
                style: TSTextStyles.body(color: TSColors.bg)),
            backgroundColor: TSColors.lime,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final emoji = (profile['emoji'] as String?) ?? '😎';
    final nickname = (profile['nickname'] as String?) ?? 'Traveller';
    final tag = profile['tag'] as String?;
    final avatarUrl = profile['avatar_url'] as String?;
    return Row(children: [
      TSAvatar(
        emoji: emoji,
        photoUrl: avatarUrl,
        size: 72,
        ringColor: TSColors.limeDim(0.3),
        ringWidth: 2,
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nickname, style: TSTextStyles.heading(size: 22)),
              if (tag != null) ...[
                const SizedBox(height: 2),
                Text('@$tag',
                    style: TSTextStyles.body(color: TSColors.lime)),
              ],
            ]),
      ),
    ]);
  }
}

class _KudosStrip extends ConsumerStatefulWidget {
  const _KudosStrip({required this.userId});
  final String userId;

  @override
  ConsumerState<_KudosStrip> createState() => _KudosStripState();
}

class _KudosStripState extends ConsumerState<_KudosStrip> {
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final counts = await ref
          .read(ratingsServiceProvider)
          .kudosCountsFor(widget.userId);
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 20);
    if (_counts.isEmpty) return const SizedBox();
    final total = _counts.values.fold<int>(0, (a, b) => a + b);
    final sorted = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    return TSCard(
      borderColor: TSColors.limeDim(0.2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🏆', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('$total kudos',
              style: TSTextStyles.heading(size: 16, color: TSColors.lime)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final entry in top) _kudosChip(entry),
        ]),
      ]),
    );
  }

  Widget _kudosChip(MapEntry<String, int> entry) {
    final k = kKudosKinds.firstWhere(
      (k) => k.kind == entry.key,
      orElse: () => (kind: entry.key, emoji: '🏆', label: entry.key),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TSColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(k.emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Text(k.label, style: TSTextStyles.caption(color: TSColors.text)),
        const SizedBox(width: 4),
        Text('${entry.value}',
            style: TSTextStyles.caption(color: TSColors.lime)),
      ]),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.emoji,
    required this.label,
    required this.value,
  });
  final String emoji, label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TSTextStyles.caption(color: TSColors.muted)),
                Text(value, style: TSTextStyles.body(size: 14)),
              ]),
        ),
      ]),
    );
  }
}
