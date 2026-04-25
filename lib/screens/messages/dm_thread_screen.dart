import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/linkified_text.dart';
import '../../widgets/photo_lightbox.dart';
import '../../widgets/photo_source_sheet.dart';
import '../../widgets/report_message_sheet.dart';
import '../../widgets/voice_memo.dart';
import '../../widgets/widgets.dart';

/// 1-on-1 DM thread. Parity with trip chat gestures:
/// - swipe right → reply (fires at 56px)
/// - double-tap  → quick 🔥 react
/// - long-press  → full reaction picker
///
/// Built on migration 018: `direct_messages.reply_to_id` +
/// `direct_message_reactions` table with realtime publication.
class DmThreadScreen extends ConsumerStatefulWidget {
  const DmThreadScreen({super.key, required this.otherUserId});
  final String otherUserId;

  @override
  ConsumerState<DmThreadScreen> createState() => _DmThreadScreenState();
}

class _DmThreadScreenState extends ConsumerState<DmThreadScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  Map<String, dynamic>? _otherProfile;
  bool _sending = false;

  /// Local reply state — mirrors the chat_tab pattern.
  DirectMessage? _replyingTo;

  /// Realtime Presence for the 1:1 thread — drives the typing
  /// indicator. Channel key is deterministic (sorted user pair) so
  /// both sides land on the same channel regardless of who opened
  /// first.
  RealtimeChannel? _presence;
  bool _otherTyping = false;
  Timer? _typingDebounce;
  bool _isTyping = false;
  bool _searchOpen = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  /// Shows the lime ↓ button once the user scrolls up far enough
  /// that the latest message is off-screen.
  bool _showJumpBtn = false;

  static const _quickReactions = ['🔥', '😂', '❤️', '👀', '💀', '👏'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _markRead();
    _subscribePresence();
    _ctrl.addListener(_onTextChanged);
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final atBottom =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 300;
    final shouldShow = !atBottom;
    if (shouldShow != _showJumpBtn) {
      setState(() => _showJumpBtn = shouldShow);
    }
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    TSHaptics.light();
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadProfile() async {
    final profiles = await ref
        .read(dmServiceProvider)
        .fetchProfilesByIds([widget.otherUserId]);
    if (!mounted) return;
    setState(() => _otherProfile = profiles[widget.otherUserId]);
  }

  Future<void> _markRead() async {
    await ref.read(dmServiceProvider).markThreadRead(widget.otherUserId);
  }

  String _channelKey() {
    final me = Supabase.instance.client.auth.currentUser?.id ?? '';
    final pair = [me, widget.otherUserId]..sort();
    return 'presence:dm:${pair[0]}:${pair[1]}';
  }

  void _subscribePresence() {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    _presence = db.channel(_channelKey(),
        opts: const RealtimeChannelConfig(self: true))
      ..onPresenceSync((_) => _syncPresence())
      ..subscribe((status, _) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _presence?.track({
            'user_id': uid,
            'typing': false,
            'at': DateTime.now().toIso8601String(),
          });
        }
      });
  }

  void _syncPresence() {
    if (!mounted) return;
    final state = _presence?.presenceState() ?? [];
    final myUid = Supabase.instance.client.auth.currentUser?.id;
    bool other = false;
    for (final group in state) {
      for (final p in group.presences) {
        final uid = p.payload['user_id'] as String? ?? '';
        if (uid.isEmpty || uid == myUid) continue;
        if (p.payload['typing'] == true) other = true;
      }
    }
    if (other != _otherTyping) {
      setState(() => _otherTyping = other);
    }
  }

  void _broadcastTyping(bool typing) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _presence?.track({
      'user_id': uid,
      'typing': typing,
      'at': DateTime.now().toIso8601String(),
    });
  }

  void _onTextChanged() {
    final hasText = _ctrl.text.isNotEmpty;
    if (hasText && !_isTyping) {
      _isTyping = true;
      _broadcastTyping(true);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _isTyping = false;
      _broadcastTyping(false);
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(dmServiceProvider).send(
            toUser: widget.otherUserId,
            content: text,
            replyToId: _replyingTo?.id,
          );
      _ctrl.clear();
      setState(() => _replyingTo = null);
      FocusManager.instance.primaryFocus?.unfocus();
      TSHaptics.light();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Pick → preview sheet for caption → upload + send as DM with
  /// an image_url. Mirrors the trip chat flow.
  Future<void> _attachPhoto() async {
    if (_sending) return;
    final file = await pickPhotoFromSheet(context);
    if (file == null) return;
    if (!mounted) return;
    final caption = await showModalBottomSheet<String?>(
      context: context,
      constraints: TSResponsive.modalConstraints,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DmImageCaptionSheet(filePath: file.path),
    );
    if (caption == null) return;
    setState(() => _sending = true);
    TSHaptics.ctaCommit();
    try {
      final url = await ref.read(dmServiceProvider).uploadDmImage(
            otherUserId: widget.otherUserId,
            filePath: file.path,
          );
      final text = caption.trim();
      await ref.read(dmServiceProvider).send(
            toUser: widget.otherUserId,
            content: text.isEmpty ? '📷' : text,
            imageUrl: url,
            replyToId: _replyingTo?.id,
          );
      if (!mounted) return;
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendVoiceMemo(String filePath, Duration duration) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final url = await ref.read(dmServiceProvider).uploadDmAudio(
            otherUserId: widget.otherUserId,
            filePath: filePath,
          );
      await ref.read(dmServiceProvider).send(
            toUser: widget.otherUserId,
            content: '🎙️',
            audioUrl: url,
            audioDurationMs: duration.inMilliseconds,
            replyToId: _replyingTo?.id,
          );
      if (!mounted) return;
      setState(() => _replyingTo = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('voice memo failed — ${humanizeError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reportDm(DirectMessage msg) async {
    final reason = await showReportReasonSheet(context);
    if (reason == null || !mounted) return;
    try {
      await ref.read(dmServiceProvider).reportMessage(
            messageId: msg.id,
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('thanks — we\'ll review this message',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t report — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editDm(DirectMessage msg) async {
    final ctrl = TextEditingController(text: msg.content);
    TSHaptics.light();
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TSColors.s1,
        title: Text('edit message', style: TSTextStyles.title()),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          style: TSTextStyles.body(),
          decoration: InputDecoration(
            hintText: 'message',
            hintStyle: TSTextStyles.body(color: TSColors.muted),
            filled: true,
            fillColor: TSColors.s2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel',
                style: TSTextStyles.body(color: TSColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: Text('save',
                style: TSTextStyles.body(color: TSColors.lime)),
          ),
        ],
      ),
    );
    if (newContent == null) return;
    final trimmed = newContent.trim();
    if (trimmed.isEmpty || trimmed == msg.content) return;
    try {
      await ref.read(dmServiceProvider).editMessage(
            messageId: msg.id,
            content: trimmed,
          );
      ref.invalidate(dmThreadProvider(widget.otherUserId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t save — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteDm(DirectMessage msg) async {
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
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('delete this message?',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'removes it for both of you. reactions disappear too.',
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
                      child: Text('keep',
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
      await ref.read(dmServiceProvider).deleteMessage(msg.id);
      // Force-refresh so the row clears even if realtime DELETE
      // events lag for this thread.
      ref.invalidate(dmThreadProvider(widget.otherUserId));
      ref.invalidate(dmThreadReactionsProvider(widget.otherUserId));
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _quickReact(DirectMessage msg) async {
    try {
      await ref
          .read(dmServiceProvider)
          .react(messageId: msg.id, emoji: '🔥');
    } catch (_) {/* silent */}
  }

  void _showReactionPicker(DirectMessage msg) {
    TSHaptics.medium();
    showModalBottomSheet<void>(
      context: context,
      constraints: TSResponsive.modalConstraints,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Emoji row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TSColors.s1,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: TSColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final emoji in _quickReactions)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        Navigator.pop(sheet);
                        await ref.read(dmServiceProvider).react(
                              messageId: msg.id,
                              emoji: emoji,
                            );
                        TSHaptics.light();
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Copy row — separated so it reads as a distinct action.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                Navigator.pop(sheet);
                await Clipboard.setData(
                    ClipboardData(text: msg.content));
                TSHaptics.light();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('copied',
                        style: TSTextStyles.body(
                            color: TSColors.bg, size: 13)),
                    backgroundColor: TSColors.lime,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: TSColors.s1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TSColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy_rounded,
                        color: TSColors.text2, size: 18),
                    const SizedBox(width: 8),
                    Text('copy message',
                        style: TSTextStyles.body(
                            color: TSColors.text2, size: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                Navigator.pop(sheet);
                TSHaptics.light();
                Rect? origin;
                try {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null && box.hasSize) {
                    origin = box.localToGlobal(Offset.zero) & box.size;
                  }
                } catch (_) {}
                final senderName = msg.fromUser ==
                        Supabase.instance.client.auth.currentUser?.id
                    ? 'me'
                    : (_otherProfile?['nickname'] as String?) ??
                        'someone';
                try {
                  await Share.share(
                    '$senderName: ${msg.content}\n\n'
                    'shared from tripsquad · https://gettripsquad.com',
                    sharePositionOrigin: origin,
                  );
                } catch (_) {/* silent */}
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: TSColors.s1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TSColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.ios_share_rounded,
                        color: TSColors.text2, size: 18),
                    const SizedBox(width: 8),
                    Text('forward',
                        style: TSTextStyles.body(
                            color: TSColors.text2, size: 14)),
                  ],
                ),
              ),
            ),
            if (msg.fromUser !=
                Supabase.instance.client.auth.currentUser?.id) ...[
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  Navigator.pop(sheet);
                  await _reportDm(msg);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: TSColors.s1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: TSColors.coral.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flag_outlined,
                          color: TSColors.coral, size: 18),
                      const SizedBox(width: 8),
                      Text('report',
                          style: TSTextStyles.body(
                              color: TSColors.coral, size: 14)),
                    ],
                  ),
                ),
              ),
            ],
            if (msg.fromUser ==
                Supabase.instance.client.auth.currentUser?.id) ...[
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  Navigator.pop(sheet);
                  await _editDm(msg);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: TSColors.s1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TSColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_rounded,
                          color: TSColors.text2, size: 18),
                      const SizedBox(width: 8),
                      Text('edit',
                          style: TSTextStyles.body(
                              color: TSColors.text2, size: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  Navigator.pop(sheet);
                  await _confirmDeleteDm(msg);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: TSColors.s1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: TSColors.coral.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: TSColors.coral, size: 18),
                      const SizedBox(width: 8),
                      Text('delete',
                          style: TSTextStyles.body(
                              color: TSColors.coral, size: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _ctrl.removeListener(_onTextChanged);
    _scroll.removeListener(_onScroll);
    _presence?.unsubscribe();
    _ctrl.dispose();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id ?? '';
    final threadAsync = ref.watch(dmThreadProvider(widget.otherUserId));
    final reactionsAsync =
        ref.watch(dmThreadReactionsProvider(widget.otherUserId));
    final nickname = _otherProfile?['nickname'] as String? ?? 'someone';
    final tag = _otherProfile?['tag'] as String?;

    // Group reactions by message_id for O(1) lookup per bubble.
    final reactionsByMsg = <String, List<DmReaction>>{};
    for (final r
        in (reactionsAsync.valueOrNull ?? const <DmReaction>[])) {
      reactionsByMsg.putIfAbsent(r.messageId, () => []).add(r);
    }

    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: TSAppBar(
        title: nickname,
        subtitle: tag != null ? '@$tag (tap to view profile)' : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'search thread',
            icon: Icon(
                _searchOpen
                    ? Icons.close_rounded
                    : Icons.search_rounded,
                color: TSColors.text2,
                size: 20),
            onPressed: () => setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) {
                _search = '';
                _searchCtrl.clear();
                FocusManager.instance.primaryFocus?.unfocus();
              }
            }),
          ),
          IconButton(
            tooltip: 'view profile',
            icon: const Icon(Icons.person_outline_rounded,
                color: TSColors.text2, size: 22),
            onPressed: () =>
                context.push('/user/${widget.otherUserId}'),
          ),
        ]),
      ),
      body: SafeArea(
        child: Column(children: [
          // Scout assist banner
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TSColors.s1,
              borderRadius: TSRadius.sm,
              border: Border.all(color: TSColors.limeDim(0.3)),
            ),
            child: Row(children: [
              const Text('🧭', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('planning a trip? scout can help',
                    style: TSTextStyles.caption(color: TSColors.text)),
              ),
              TextButton(
                onPressed: () {
                  // TODO: create shared trip with both users auto-added
                },
                child: Text('plan together →',
                    style: TSTextStyles.label(color: TSColors.lime)),
              ),
            ]),
          ),
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 6, 8),
              child: Row(children: [
                const Icon(Icons.search_rounded,
                    color: TSColors.lime, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) =>
                        setState(() => _search = v.trim()),
                    style: TSTextStyles.body(size: 14),
                    decoration: InputDecoration(
                      hintText: 'search this thread…',
                      hintStyle: TSTextStyles.body(
                          size: 14, color: TSColors.muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ]),
            ),
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: threadAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: TSColors.lime),
              ),
              error: (e, _) => Center(child: Text(humanizeError(e))),
              data: (rawMessages) {
                final q = _search.toLowerCase();
                final messages = (!_searchOpen || q.isEmpty)
                    ? rawMessages
                    : rawMessages
                        .where((m) =>
                            m.content.toLowerCase().contains(q))
                        .toList();
                if (messages.isEmpty && _searchOpen && q.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          'no matches for "${_searchCtrl.text}"',
                          style: TSTextStyles.caption(
                              color: TSColors.muted)),
                    ),
                  );
                }
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('say hi 👋',
                            style: TSTextStyles.body(
                                color: TSColors.muted)),
                        const SizedBox(height: 6),
                        Text(
                          'swipe → reply · double-tap 🔥 · long-press react / copy',
                          style: TSTextStyles.caption(
                              color: TSColors.muted),
                        ),
                      ],
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });
                final byId = {for (final m in messages) m.id: m};
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  child: Builder(builder: (_) {
                    // iMessage-style seen receipt: only the last
                    // message I sent shows "seen" — and only if
                    // the other user has marked it read.
                    String? lastSeenMineId;
                    for (var i = messages.length - 1; i >= 0; i--) {
                      final m = messages[i];
                      if (m.fromUser != me) continue;
                      if (m.readAt != null) lastSeenMineId = m.id;
                      break;
                    }
                    return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: messages.length,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final parent = msg.replyToId == null
                          ? null
                          : byId[msg.replyToId!];
                      // Insert a date separator whenever this
                      // message is on a different calendar day
                      // than the previous one.
                      final prev = i == 0 ? null : messages[i - 1];
                      final separator = _dayChangeLabel(
                          prev?.createdAt, msg.createdAt);
                      final row = _DmMessageRow(
                        msg: msg,
                        parent: parent,
                        reactions:
                            reactionsByMsg[msg.id] ?? const [],
                        isMe: msg.fromUser == me,
                        showSeen: msg.id == lastSeenMineId,
                        onReply: (m) =>
                            setState(() => _replyingTo = m),
                        onReact: _showReactionPicker,
                        onQuickReact: _quickReact,
                      );
                      if (separator == null) return row;
                      return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _DateSeparator(label: separator),
                            row,
                          ]);
                    },
                    );
                  }),
                );
              },
            )),
            if (_showJumpBtn)
              Positioned(
                right: 14,
                bottom: 14,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _jumpToLatest,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TSColors.lime,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: TSColors.bg.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_downward_rounded,
                        color: TSColors.bg, size: 20),
                  ),
                ),
              ),
            ]),
          ),
          if (_otherTyping)
            _TypingRow(nickname: nickname),
          if (_replyingTo != null)
            _ReplyPreview(
              msg: _replyingTo!,
              onClear: () => setState(() => _replyingTo = null),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: TSColors.s1,
              border: Border(top: BorderSide(color: TSColors.border)),
            ),
            child: Row(children: [
              IconButton(
                tooltip: 'camera or library',
                icon: const Icon(Icons.photo_camera_outlined,
                    color: TSColors.lime, size: 22),
                onPressed: _sending ? null : _attachPhoto,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: TSTextStyles.body(),
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _replyingTo != null
                        ? 'replying…'
                        : 'message…',
                    hintStyle: TSTextStyles.body(color: TSColors.muted),
                    filled: true,
                    fillColor: TSColors.s2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _ctrl,
                builder: (_, value, __) {
                  if (value.text.trim().isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: HoldToRecordMic(
                        enabled: !_sending,
                        onRecorded: _sendVoiceMemo,
                      ),
                    );
                  }
                  return IconButton(
                    icon: Icon(Icons.send_rounded,
                        color: _sending ? TSColors.muted : TSColors.lime),
                    onPressed: _sending ? null : _send,
                  );
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Returns the human-readable label for a new day divider when
/// [current] falls on a different calendar day than [previous].
/// Returns null when both are on the same day, or when the first
/// message has no timestamp (let the list render without a lead-in
/// separator — the thread already has its app-bar context).
String? _dayChangeLabel(DateTime? previous, DateTime? current) {
  if (current == null) return null;
  if (previous != null &&
      previous.year == current.year &&
      previous.month == current.month &&
      previous.day == current.day) {
    return null;
  }
  // Separator at the start of the list OR on any day change.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(current.year, current.month, current.day);
  final delta = today.difference(msgDay).inDays;
  if (delta == 0) return 'today';
  if (delta == 1) return 'yesterday';
  if (delta < 7) {
    const weekdays = [
      'monday', 'tuesday', 'wednesday',
      'thursday', 'friday', 'saturday', 'sunday'
    ];
    return weekdays[current.weekday - 1];
  }
  const months = [
    '', 'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
  ];
  if (current.year == now.year) {
    return '${months[current.month]} ${current.day}';
  }
  return '${months[current.month]} ${current.day}, ${current.year}';
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Expanded(
          child: Container(height: 0.5, color: TSColors.border),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: TSTextStyles.label(
                  color: TSColors.muted, size: 10)),
        ),
        Expanded(
          child: Container(height: 0.5, color: TSColors.border),
        ),
      ]),
    );
  }
}

/// DM-specific image caption sheet — mirror of the trip-chat one
/// but returns just the caption string (simpler model — DMs don't
/// route to Scout).
class _DmImageCaptionSheet extends StatefulWidget {
  const _DmImageCaptionSheet({required this.filePath});
  final String filePath;

  @override
  State<_DmImageCaptionSheet> createState() =>
      _DmImageCaptionSheetState();
}

class _DmImageCaptionSheetState extends State<_DmImageCaptionSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: TSColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Image.file(
                File(widget.filePath),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: TSTextStyles.body(),
            decoration: InputDecoration(
              hintText: 'add a caption (optional)',
              hintStyle: TSTextStyles.body(color: TSColors.muted),
              filled: true,
              fillColor: TSColors.s2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(null),
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
              flex: 2,
              child: GestureDetector(
                onTap: () =>
                    Navigator.of(context).pop(_ctrl.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TSColors.lime,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('send ↑',
                      style: TSTextStyles.title(
                          size: 13, color: TSColors.bg)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Typing indicator — mirrors the trip-chat treatment: three
//  softly-animated lime dots next to the other user's nickname.
// ─────────────────────────────────────────────────────────────
class _TypingRow extends StatefulWidget {
  const _TypingRow({required this.nickname});
  final String nickname;

  @override
  State<_TypingRow> createState() => _TypingRowState();
}

class _TypingRowState extends State<_TypingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
      child: Row(children: [
        Text('${widget.nickname} is typing',
            style: TSTextStyles.caption(color: TSColors.muted)),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(
            children: List.generate(3, (i) {
              final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TSColors.lime
                        .withValues(alpha: 0.3 + t * 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Message row with gesture wrapper
// ─────────────────────────────────────────────────────────────

class _DmMessageRow extends StatelessWidget {
  const _DmMessageRow({
    required this.msg,
    required this.parent,
    required this.reactions,
    required this.isMe,
    required this.showSeen,
    required this.onReply,
    required this.onReact,
    required this.onQuickReact,
  });
  final DirectMessage msg;
  final DirectMessage? parent;
  final List<DmReaction> reactions;
  final bool isMe;
  final bool showSeen;
  final void Function(DirectMessage) onReply;
  final void Function(DirectMessage) onReact;
  final void Function(DirectMessage) onQuickReact;

  @override
  Widget build(BuildContext context) {
    return _DmGestureWrapper(
      onLongPress: () => onReact(msg),
      onSwipeReply: () => onReply(msg),
      onDoubleTap: () => onQuickReact(msg),
      onLongPressCopy: () async {
        HapticFeedback.mediumImpact();
        await Clipboard.setData(ClipboardData(text: msg.content));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('copied',
                style:
                    TSTextStyles.body(color: TSColors.bg, size: 13)),
            backgroundColor: TSColors.lime,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (parent != null)
                  _ParentQuote(parent: parent!, isMe: isMe),
                if (msg.audioUrl != null && msg.audioUrl!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? TSColors.lime : TSColors.s2,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                    ),
                    child: VoiceMemoPlayer(
                      url: msg.audioUrl!,
                      durationMs: msg.audioDurationMs,
                      onBubble: isMe,
                    ),
                  ),
                if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        openPhotoLightbox(context, msg.imageUrl!),
                    child: Hero(
                      tag: msg.imageUrl!,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 240, maxHeight: 240),
                          child: CachedNetworkImage(
                            imageUrl: msg.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                width: 180,
                                height: 180,
                                color: TSColors.s2),
                            errorWidget: (_, __, ___) => Container(
                                width: 180,
                                height: 120,
                                color: TSColors.s2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if ((msg.content.trim() != '📷' ||
                        (msg.imageUrl ?? '').isEmpty) &&
                    (msg.content.trim() != '🎙️' ||
                        (msg.audioUrl ?? '').isEmpty))
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? TSColors.lime : TSColors.s2,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                    ),
                    child: LinkifiedText(
                      content: TripService.stripInviteMarker(msg.content),
                      color: isMe ? TSColors.bg : TSColors.text,
                    ),
                  ),
                if (msg.editedAt != null)
                  Padding(
                    padding: EdgeInsets.only(
                        top: 2, left: isMe ? 0 : 4, right: isMe ? 4 : 0),
                    child: Text('edited',
                        style: TSTextStyles.label(
                            color: TSColors.muted, size: 9)),
                  ),
                if (reactions.isNotEmpty)
                  _ReactionRow(reactions: reactions),
                if (showSeen)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: Text('seen',
                        style: TSTextStyles.label(
                            color: TSColors.muted, size: 9)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Gesture wrapper — mirror of chat_tab.dart's _MessageGestureWrapper.
//  Listener for the horizontal drag so it wins the arena against
//  iOS edge-swipe-back + ListView scroll. GestureDetector for
//  long-press + double-tap.
// ─────────────────────────────────────────────────────────────

class _DmGestureWrapper extends StatefulWidget {
  const _DmGestureWrapper({
    required this.child,
    required this.onLongPress,
    required this.onSwipeReply,
    required this.onDoubleTap,
    required this.onLongPressCopy,
  });
  final Widget child;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeReply;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPressCopy;

  @override
  State<_DmGestureWrapper> createState() => _DmGestureWrapperState();
}

class _DmGestureWrapperState extends State<_DmGestureWrapper> {
  double _dx = 0;
  double _startX = 0;
  double _startY = 0;
  bool _didFire = false;
  bool _tracking = false;

  static const _commitPx = 56;
  static const _directionThreshold = 8;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _startX = e.position.dx;
        _startY = e.position.dy;
        _tracking = false;
        _didFire = false;
        _dx = 0;
      },
      onPointerMove: (e) {
        final dx = e.position.dx - _startX;
        final dy = e.position.dy - _startY;
        if (!_tracking) {
          if (dx.abs() < _directionThreshold &&
              dy.abs() < _directionThreshold) return;
          if (dx.abs() <= dy.abs()) return;
          if (dx < 0) return;
          _tracking = true;
        }
        final newDx = dx.clamp(0.0, 120.0);
        if (newDx != _dx) setState(() => _dx = newDx);
        if (!_didFire && _dx >= _commitPx) {
          _didFire = true;
          HapticFeedback.mediumImpact();
          widget.onSwipeReply();
        }
      },
      onPointerUp: (_) {
        _tracking = false;
        if (_dx != 0) setState(() => _dx = 0);
      },
      onPointerCancel: (_) {
        _tracking = false;
        if (_dx != 0) setState(() => _dx = 0);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress();
        },
        onDoubleTap: () {
          HapticFeedback.lightImpact();
          widget.onDoubleTap();
        },
        child: Stack(
          children: [
            if (_dx > 8)
              Positioned(
                left: (_dx * 0.4).clamp(0.0, 24.0),
                top: 0,
                bottom: 0,
                child: Center(
                  child: Opacity(
                    opacity: (_dx / _commitPx).clamp(0.0, 1.0),
                    child: const Icon(Icons.reply_rounded,
                        color: TSColors.lime, size: 20),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dx, 0, 0),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Reply quote + preview
// ─────────────────────────────────────────────────────────────

class _ParentQuote extends StatelessWidget {
  const _ParentQuote({required this.parent, required this.isMe});
  final DirectMessage parent;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TSColors.s3,
        borderRadius: TSRadius.xs,
        border: const Border(
          left: BorderSide(color: TSColors.lime, width: 2),
        ),
      ),
      child: Text(
        parent.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TSTextStyles.caption(color: TSColors.muted),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.msg, required this.onClear});
  final DirectMessage msg;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: TSColors.limeDim(0.08),
        border: const Border(
          top: BorderSide(color: TSColors.lime, width: 1.2),
        ),
      ),
      child: Row(children: [
        const Icon(Icons.reply_rounded, color: TSColors.lime, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('replying',
                  style: TSTextStyles.label(
                      color: TSColors.lime, size: 10)),
              const SizedBox(height: 2),
              Text(msg.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TSTextStyles.caption(color: TSColors.text2)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded,
              color: TSColors.muted, size: 18),
          onPressed: onClear,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Reaction chips
// ─────────────────────────────────────────────────────────────

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({required this.reactions});
  final List<DmReaction> reactions;

  void _showWhoReacted(BuildContext context, String emoji) {
    final userIds = reactions
        .where((r) => r.emoji == emoji)
        .map((r) => r.userId)
        .toList();
    TSHaptics.light();
    showModalBottomSheet<void>(
      context: context,
      constraints: TSResponsive.modalConstraints,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => Consumer(builder: (_, ref, __) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                Row(children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                      '${userIds.length} reaction${userIds.length == 1 ? '' : 's'}',
                      style: TSTextStyles.heading(size: 18)),
                ]),
                const SizedBox(height: 14),
                FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: ref
                      .read(dmServiceProvider)
                      .fetchProfilesByIds(userIds),
                  builder: (_, snap) {
                    final profiles = snap.data ?? {};
                    return Column(
                      children: [
                        for (final uid in userIds)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4),
                            child: Row(children: [
                              TSAvatar(
                                emoji: (profiles[uid]
                                        ?['emoji'] as String?) ??
                                    '😎',
                                photoUrl: profiles[uid]
                                    ?['avatar_url'] as String?,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                  (profiles[uid]
                                          ?['nickname'] as String?) ??
                                      '…',
                                  style: TSTextStyles.body(size: 14)),
                            ]),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aggregate by emoji.
    final counts = <String, int>{};
    for (final r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: [
          for (final entry in counts.entries)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showWhoReacted(context, entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TSColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(entry.key, style: const TextStyle(fontSize: 13)),
                  if (entry.value > 1) ...[
                    const SizedBox(width: 4),
                    Text('${entry.value}',
                        style: TSTextStyles.caption(
                            color: TSColors.text2)),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
