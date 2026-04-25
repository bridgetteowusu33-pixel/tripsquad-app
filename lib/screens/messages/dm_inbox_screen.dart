import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';
import '../../widgets/tappable.dart';

// ─────────────────────────────────────────────────────────────
//  Archived DM threads — local-only (SharedPreferences).
//  Shared across "all" and "dms" tabs so archive hides a thread
//  from both feeds.
// ─────────────────────────────────────────────────────────────
const _archivedPrefsKey = 'archived_dm_threads';

class ArchivedDmsNotifier extends StateNotifier<Set<String>> {
  ArchivedDmsNotifier() : super(<String>{}) {
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_archivedPrefsKey) ?? const <String>[];
    state = list.toSet();
  }
  Future<void> setArchived(String uid, bool archive) async {
    final next = {...state};
    if (archive) {
      next.add(uid);
    } else {
      next.remove(uid);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_archivedPrefsKey, next.toList());
  }
}

final archivedDmsProvider =
    StateNotifierProvider<ArchivedDmsNotifier, Set<String>>(
  (ref) => ArchivedDmsNotifier(),
);

/// Unified inbox with three tabs:
///  · All      — merged stream of notifications + DMs, newest first
///  · DMs      — direct message conversations
///  · Updates  — trip events, mentions, votes, reveals
///
/// The ✉️ envelope badge on Home counts unread rows in `notifications`;
/// this screen is the one place where those notifications can be read
/// and marked seen.
class DmInboxScreen extends ConsumerStatefulWidget {
  const DmInboxScreen({super.key});

  @override
  ConsumerState<DmInboxScreen> createState() => _DmInboxScreenState();
}

class _DmInboxScreenState extends ConsumerState<DmInboxScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, Map<String, dynamic>> _profileCache = {};
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    if (q.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await ref.read(tripServiceProvider).searchByTag(q);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: TSAppBar(
        title: 'inbox',
        trailing: _MarkAllReadButton(),
      ),
      body: SafeArea(
        child: Column(children: [
          // Tag search row
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: TSTextStyles.body(),
              onChanged: _runSearch,
              decoration: InputDecoration(
                hintText: 'find by @tag or name',
                hintStyle: TSTextStyles.body(color: TSColors.muted),
                prefixIcon: const Icon(Icons.search, color: TSColors.muted),
                filled: true,
                fillColor: TSColors.s2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = _searchResults[i];
                  return TSTappable(
                    onTap: () {
                      TSHaptics.light();
                      context.push('/user/${p['id']}');
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TSColors.s1,
                        borderRadius: TSRadius.sm,
                        border: Border.all(color: TSColors.limeDim(0.25)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p['emoji'] ?? '😎',
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text('@${p['tag'] ?? '?'}',
                              style: TSTextStyles.caption(),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          TabBar(
            controller: _tabs,
            indicatorColor: TSColors.lime,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TSTextStyles.label(size: 11),
            unselectedLabelColor: TSColors.muted,
            labelColor: TSColors.lime,
            tabs: const [
              Tab(text: 'all'),
              Tab(text: 'dms'),
              Tab(text: 'updates'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CombinedTab(
                  profileCache: _profileCache,
                  onProfilesFetched: (m) =>
                      setState(() => _profileCache = m),
                ),
                _DmsTab(
                  profileCache: _profileCache,
                  onProfilesFetched: (m) =>
                      setState(() => _profileCache = m),
                ),
                const _UpdatesTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Mark-all-read ────────────────────────────────────────────
class _MarkAllReadButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'mark all read',
      icon: const Icon(Icons.done_all_rounded,
          color: TSColors.text2, size: 20),
      onPressed: () async {
        TSHaptics.light();
        await ref.read(notificationsServiceProvider).markAllRead();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ALL TAB — merged stream of DMs + notifications
// ─────────────────────────────────────────────────────────────
class _CombinedTab extends ConsumerWidget {
  const _CombinedTab({
    required this.profileCache,
    required this.onProfilesFetched,
  });
  final Map<String, Map<String, dynamic>> profileCache;
  final void Function(Map<String, Map<String, dynamic>>) onProfilesFetched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dmsAsync = ref.watch(myDmsProvider);
    final notifsAsync = ref.watch(myNotificationsProvider);
    final archived = ref.watch(archivedDmsProvider);
    final me = Supabase.instance.client.auth.currentUser?.id ?? '';

    return dmsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: TSColors.lime)),
      error: (e, _) => Center(child: Text(humanizeError(e))),
      data: (dms) {
        final notifs = notifsAsync.asData?.value ?? const <NotificationItem>[];

        final dmConvs = ref
            .read(dmServiceProvider)
            .collapseToConversations(dms, me, profileCache);
        // Archived threads are hidden from the combined feed; they
        // live in the DMs tab's "archived" view only.
        final visibleDmConvs = dmConvs
            .where((c) => !archived.contains(c.otherUserId))
            .toList();

        final entries = <_FeedEntry>[
          for (final c in visibleDmConvs)
            _FeedEntry.dm(conv: c, when: c.lastMessageAt),
          for (final n in notifs)
            if (n.kind != 'dm_received')
              _FeedEntry.notif(
                notif: n,
                when: n.createdAt ?? DateTime.now(),
              ),
        ]..sort((a, b) => b.when.compareTo(a.when));

        if (entries.isEmpty) {
          return const _Empty(
            emoji: '✨',
            title: 'you\'re all caught up',
            body: 'nothing new right now',
          );
        }

        _maybeFetchProfiles(ref, dmConvs);

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          separatorBuilder: (_, __) =>
              const Divider(color: TSColors.border, height: 1),
          itemBuilder: (_, i) {
            final e = entries[i];
            if (!e.isDm) return _NotifRow(notif: e.notif!);
            final conv = e.conv!;
            return Dismissible(
              key: ValueKey('all-dm-${conv.otherUserId}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: TSColors.s2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.archive_outlined,
                        color: TSColors.lime, size: 20),
                    SizedBox(width: 6),
                    Text('archive',
                        style: TextStyle(
                            color: TSColors.lime,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              onDismissed: (_) {
                TSHaptics.light();
                ref
                    .read(archivedDmsProvider.notifier)
                    .setArchived(conv.otherUserId, true);
              },
              child: _ConversationRow(conv: conv),
            );
          },
        );
      },
    );
  }

  void _maybeFetchProfiles(
      WidgetRef ref, List<DmConversation> convs) async {
    final missing = convs
        .map((c) => c.otherUserId)
        .toSet()
        .where((id) => !profileCache.containsKey(id))
        .toList();
    if (missing.isEmpty) return;
    final profiles =
        await ref.read(dmServiceProvider).fetchProfilesByIds(missing);
    if (profiles.isEmpty) return;
    onProfilesFetched({...profileCache, ...profiles});
  }
}

// ─────────────────────────────────────────────────────────────
//  DMs TAB
// ─────────────────────────────────────────────────────────────
class _DmsTab extends ConsumerStatefulWidget {
  const _DmsTab({
    required this.profileCache,
    required this.onProfilesFetched,
  });
  final Map<String, Map<String, dynamic>> profileCache;
  final void Function(Map<String, Map<String, dynamic>>) onProfilesFetched;

  @override
  ConsumerState<_DmsTab> createState() => _DmsTabState();
}

class _DmsTabState extends ConsumerState<_DmsTab> {
  bool _showArchived = false;

  Future<void> _setArchived(String uid, bool archive) async {
    TSHaptics.light();
    await ref
        .read(archivedDmsProvider.notifier)
        .setArchived(uid, archive);
  }

  @override
  Widget build(BuildContext context) {
    final dmsAsync = ref.watch(myDmsProvider);
    final archived = ref.watch(archivedDmsProvider);
    final me = Supabase.instance.client.auth.currentUser?.id ?? '';

    return RefreshIndicator(
      color: TSColors.lime,
      backgroundColor: TSColors.s1,
      onRefresh: () async {
        TSHaptics.light();
        ref.invalidate(myDmsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: dmsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: TSColors.lime)),
      error: (e, _) => Center(child: Text(humanizeError(e))),
      data: (messages) {
        if (messages.isEmpty) {
          return const _Empty(
            emoji: '✉️',
            title: 'no messages yet',
            body: 'search for a @tag to start a chat',
          );
        }
        final convs = ref
            .read(dmServiceProvider)
            .collapseToConversations(
                messages, me, widget.profileCache);
        _maybeFetchProfiles(convs);
        final archivedConvs = convs
            .where((c) => archived.contains(c.otherUserId))
            .toList();
        final activeConvs = convs
            .where((c) => !archived.contains(c.otherUserId))
            .toList();
        final visible = _showArchived ? archivedConvs : activeConvs;
        final hasArchived = archivedConvs.isNotEmpty;
        final showFooter =
            hasArchived && !_showArchived || _showArchived;
        if (visible.isEmpty && _showArchived) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('nothing archived',
                      style: TSTextStyles.body(color: TSColors.muted)),
                  const SizedBox(height: 12),
                  TSTappable(
                    onTap: () =>
                        setState(() => _showArchived = false),
                    child: Text('back to inbox',
                        style: TSTextStyles.label(color: TSColors.lime)),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: visible.length + (showFooter ? 1 : 0),
          separatorBuilder: (_, __) =>
              const Divider(color: TSColors.border, height: 1),
          itemBuilder: (_, i) {
            if (showFooter && i == visible.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: TSTappable(
                    onTap: () => setState(
                        () => _showArchived = !_showArchived),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showArchived
                              ? Icons.arrow_back_rounded
                              : Icons.archive_outlined,
                          color: TSColors.muted,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showArchived
                              ? 'back to inbox'
                              : 'archived · ${archivedConvs.length}',
                          style: TSTextStyles.label(
                              color: TSColors.muted, size: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final conv = visible[i];
            final isArchived = _showArchived;
            return Dismissible(
              key: ValueKey('dm-${conv.otherUserId}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: TSColors.s2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      color: TSColors.lime,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isArchived ? 'restore' : 'archive',
                      style: TSTextStyles.label(color: TSColors.lime),
                    ),
                  ],
                ),
              ),
              onDismissed: (_) =>
                  _setArchived(conv.otherUserId, !isArchived),
              child: _ConversationRow(conv: conv),
            );
          },
        );
      },
      ),
    );
  }

  void _maybeFetchProfiles(List<DmConversation> convs) async {
    final missing = convs
        .map((c) => c.otherUserId)
        .toSet()
        .where((id) => !widget.profileCache.containsKey(id))
        .toList();
    if (missing.isEmpty) return;
    final profiles =
        await ref.read(dmServiceProvider).fetchProfilesByIds(missing);
    if (profiles.isEmpty) return;
    widget.onProfilesFetched({...widget.profileCache, ...profiles});
  }
}

// ─────────────────────────────────────────────────────────────
//  UPDATES TAB — trip events, mentions, votes, reveals, etc.
// ─────────────────────────────────────────────────────────────
class _UpdatesTab extends ConsumerWidget {
  const _UpdatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(myNotificationsProvider);

    return notifsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: TSColors.lime)),
      error: (e, _) => Center(child: Text(humanizeError(e))),
      data: (notifs) {
        // Filter out dm_received — those belong in the DMs tab
        final updates = notifs.where((n) => n.kind != 'dm_received').toList();
        if (updates.isEmpty) {
          return const _Empty(
            emoji: '🔔',
            title: 'no updates',
            body: 'trip activity shows up here',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: updates.length,
          separatorBuilder: (_, __) =>
              const Divider(color: TSColors.border, height: 1),
          itemBuilder: (_, i) => _NotifRow(notif: updates[i]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared row widgets
// ─────────────────────────────────────────────────────────────

class _ConversationRow extends ConsumerWidget {
  const _ConversationRow({required this.conv});
  final DmConversation conv;

  Future<void> _showMuteSheet(
      BuildContext context, WidgetRef ref, bool isMuted) async {
    TSHaptics.medium();
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
              Text(conv.otherNickname ?? 'thread',
                  style: TSTextStyles.heading(size: 18)),
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  Navigator.of(sheet).pop();
                  final prefs = await SharedPreferences.getInstance();
                  final key = 'dm_muted_until_${conv.otherUserId}';
                  if (isMuted) {
                    await prefs.remove(key);
                  } else {
                    final until = DateTime.now()
                        .add(const Duration(days: 7));
                    await prefs.setString(
                        key, until.toIso8601String());
                  }
                  ref.invalidate(mutedDmUserIdsProvider);
                  TSHaptics.light();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Icon(
                      isMuted
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: TSColors.lime,
                      size: 18,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              isMuted
                                  ? 'unmute thread'
                                  : 'mute for 7 days',
                              style: TSTextStyles.title(
                                  size: 14, color: TSColors.text)),
                          const SizedBox(height: 2),
                          Text(
                            isMuted
                                ? 'bring this thread back to the inbox count'
                                : 'hide unread badge from this thread',
                            style: TSTextStyles.caption(
                                color: TSColors.muted2),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref
            .watch(mutedDmUserIdsProvider)
            .valueOrNull
            ?.contains(conv.otherUserId) ??
        false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showMuteSheet(context, ref, isMuted),
      child: TSTappable(
      onTap: () async {
        TSHaptics.light();
        // If the latest DM is a tag-invite (carries a trip marker),
        // route into the trip directly — not the DM thread.
        final inviteTripId =
            TripService.tripIdFromDmContent(conv.lastMessage);
        if (inviteTripId != null && context.mounted) {
          final route = await _inviteRouteFor(inviteTripId);
          if (context.mounted) context.push(route);
          return;
        }
        if (context.mounted) context.push('/messages/${conv.otherUserId}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              TSHaptics.light();
              context.push('/user/${conv.otherUserId}');
            },
            child: TSAvatar(
              emoji: conv.otherEmoji ?? '😎',
              photoUrl: conv.otherAvatarUrl,
              size: 44,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(conv.otherNickname ?? 'someone',
                        style: TSTextStyles.body(weight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    if (conv.otherTag != null)
                      Text('@${conv.otherTag}',
                          style: TSTextStyles.caption(color: TSColors.muted)),
                    if (isMuted) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.notifications_off_rounded,
                          color: TSColors.muted, size: 12),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                      TripService.stripInviteMarker(conv.lastMessage),
                      style: TSTextStyles.caption(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
          if (conv.unreadCount > 0 && !isMuted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: TSColors.lime,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${conv.unreadCount}',
                  style: TSTextStyles.label(color: TSColors.bg, size: 10),
                  textAlign: TextAlign.center),
            ),
        ]),
      ),
    ),
    );
  }
}

/// Returns the right in-app route for a trip notification.
/// - Invited member + collecting phase → fill prefs
/// - Packing-related kinds → trip space on pack tab
/// - Chat-related kinds → trip space on chat tab
/// - Everyone else → trip space (default tab)
Future<String> _inviteRouteFor(String tripId, {String? kind}) async {
  final defaultRoute = '/trip/$tripId/space';

  // Map notification kind → desired tab on trip space.
  String? tabParam() {
    switch (kind) {
      case 'packing_ready':
        return 'pack';
      case 'chat_message':
      case 'dm_sent':
      case 'mention':
        return 'chat';
      case 'itinerary_ready':
        return 'plan';
      case 'vote_cast':
      case 'options_generated':
        return 'vote';
      default:
        return null;
    }
  }

  final tabSuffix = tabParam() != null ? '?tab=${tabParam()}' : '';

  try {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return '$defaultRoute$tabSuffix';
    final trip = await db
        .from('trips')
        .select('status')
        .eq('id', tripId)
        .maybeSingle();
    final status = trip?['status'] as String?;
    if (status != 'collecting') return '$defaultRoute$tabSuffix';
    final member = await db
        .from('squad_members')
        .select('status')
        .eq('trip_id', tripId)
        .eq('user_id', uid)
        .maybeSingle();
    if (member?['status'] == 'invited') return '/trip/$tripId/fill';
    return '$defaultRoute$tabSuffix';
  } catch (_) {
    return '$defaultRoute$tabSuffix';
  }
}

class _NotifRow extends ConsumerWidget {
  const _NotifRow({required this.notif});
  final NotificationItem notif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = notif.readAt == null;
    return TSTappable(
      onTap: () async {
        TSHaptics.light();
        // Always mark read on tap — the dot disappears the next time
        // the inbox rebuilds (via the realtime stream).
        await ref.read(notificationsServiceProvider).markRead(notif.id);
        if (notif.tripId == null || !context.mounted) return;
        // Phase + kind-aware routing. For example:
        //   packing_ready → trip space on the pack tab
        //   chat_message  → trip space on the chat tab
        //   invite while still collecting → fill prefs form
        final route = await _inviteRouteFor(
          notif.tripId!,
          kind: notif.kind,
        );
        if (!context.mounted) return;
        context.push(route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(children: [
          Text(_emojiForKind(notif.kind),
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(notif.title,
                          style: TSTextStyles.body(
                            weight: unread ? FontWeight.w700 : FontWeight.w400,
                            color: unread ? TSColors.text : TSColors.text2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(_relativeTime(notif.createdAt),
                        style: TSTextStyles.label(
                            color: TSColors.muted2, size: 10)),
                  ]),
                  if (notif.body != null && notif.body!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notif.body!,
                        style: TSTextStyles.caption(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ]),
          ),
          if (unread)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: TSColors.lime,
                shape: BoxShape.circle,
              ),
            ),
        ]),
      ),
    );
  }

  /// Compact relative timestamp — "2m", "2h", "3d", then "Apr 14".
  String _relativeTime(DateTime? when) {
    if (when == null) return '';
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[when.month - 1]} ${when.day}';
  }

  String _emojiForKind(String kind) {
    switch (kind) {
      case 'mention':           return '💬';
      case 'vote_cast':         return '🗳️';
      case 'reveal':            return '🎉';
      case 'status_changed':    return '📍';
      case 'options_generated': return '🧭';
      case 'itinerary_ready':   return '🗺️';
      case 'member_joined':     return '👋';
      case 'invited_to_trip':   return '✈️';
      case 'packing_ready':     return '🎒';
      case 'chat_message':      return '💬';
      case 'dm_received':       return '✉️';
      case 'nudge_stale_invite':return '⏳';
      case 'nudge_countdown':   return '⏰';
      case 'nudge_live_today':  return '🌅';
      case 'nudge_recap':       return '💫';
      default:                  return '✨';
    }
  }
}

// Merged feed entry (either a DM conversation or a notification)
class _FeedEntry {
  _FeedEntry.dm({required this.conv, required this.when}) : notif = null;
  _FeedEntry.notif({required this.notif, required this.when}) : conv = null;
  final DmConversation? conv;
  final NotificationItem? notif;
  final DateTime when;
  bool get isDm => conv != null;
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.emoji,
    required this.title,
    required this.body,
  });
  final String emoji, title, body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(title, style: TSTextStyles.heading(size: 20)),
          const SizedBox(height: 6),
          Text(body,
              style: TSTextStyles.body(color: TSColors.muted),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
