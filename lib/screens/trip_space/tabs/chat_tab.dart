import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/linkified_text.dart';
import '../../../widgets/photo_lightbox.dart';
import '../../../widgets/photo_source_sheet.dart';
import '../../../widgets/report_message_sheet.dart';
import '../../../widgets/voice_memo.dart';
import '../../../widgets/widgets.dart';

/// Realtime squad chat with reactions, reply threads, @mentions,
/// typing indicators, read receipts, Scout inline.
class ChatTab extends ConsumerStatefulWidget {
  const ChatTab({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> {
  static const _quickReactions = ['❤️', '🔥', '😂', '👀', '✈️'];

  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final Set<String> _online = {};
  final Map<String, String> _typingUsers = {};
  final Map<String, Map<String, dynamic>> _squadByTag = {};
  final Map<String, String?> _avatarByUid = {};
  RealtimeChannel? _presence;
  ChatMessage? _replyingTo;
  bool _sending = false;
  bool _scoutThinking = false;
  List<Map<String, dynamic>> _mentionSuggestions = [];
  int _mentionStart = -1;
  Timer? _typingDebounce;
  bool _isTyping = false;
  bool _showJumpBtn = false;
  int _lastKnownCount = 0;
  bool _searchOpen = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subscribePresence();
    _loadSquad();
  }

  Future<void> _loadSquad() async {
    final rows = await Supabase.instance.client
        .from('squad_members')
        .select('user_id, nickname, tag, emoji')
        .eq('trip_id', widget.tripId);
    if (!mounted) return;
    final map = <String, Map<String, dynamic>>{};
    final uids = <String>[];
    for (final r in (rows as List)) {
      final tag = (r as Map<String, dynamic>)['tag'];
      if (tag is String && tag.isNotEmpty) map[tag.toLowerCase()] = r;
      final uid = r['user_id'] as String?;
      if (uid != null) uids.add(uid);
    }
    setState(() => _squadByTag.addAll(map));
    // Fetch avatars for registered members via RPC (bypasses RLS).
    if (uids.isNotEmpty) {
      final profiles = await ref
          .read(dmServiceProvider)
          .fetchProfilesByIds(uids);
      if (!mounted) return;
      setState(() {
        for (final entry in profiles.entries) {
          _avatarByUid[entry.key] =
              entry.value['avatar_url'] as String?;
        }
      });
    }
  }

  void _subscribePresence() {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    _presence = db.channel('presence:trip:${widget.tripId}',
        opts: const RealtimeChannelConfig(self: true))
      ..onPresenceSync((_) => _syncPresence())
      ..subscribe((status, _) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _presence?.track({
            'user_id': uid,
            'nickname': _myNickname(),
            'typing': false,
            'at': DateTime.now().toIso8601String(),
          });
        }
      });
  }

  /// Best-available nickname for the current user. Prefers the
  /// profile's own nickname; falls back to the squad_members row if
  /// the profile hasn't loaded yet, then to a generic label.
  String _myNickname() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile?.nickname != null && profile!.nickname!.isNotEmpty) {
      return profile.nickname!;
    }
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      for (final row in _squadByTag.values) {
        if (row['user_id'] == uid) {
          final n = row['nickname'] as String?;
          if (n != null && n.isNotEmpty) return n;
        }
      }
    }
    return 'someone';
  }

  void _syncPresence() {
    if (!mounted) return;
    final state = _presence?.presenceState() ?? [];
    final online = <String>{};
    final typing = <String, String>{};
    final myUid = Supabase.instance.client.auth.currentUser?.id;
    for (final group in state) {
      for (final p in group.presences) {
        final uid = p.payload['user_id'] as String? ?? '';
        if (uid.isEmpty) continue;
        online.add(uid);
        final isTyping = p.payload['typing'] == true;
        final nickname =
            p.payload['nickname'] as String? ?? 'someone';
        if (isTyping && uid != myUid) typing[uid] = nickname;
      }
    }
    setState(() {
      _online
        ..clear()
        ..addAll(online);
      _typingUsers
        ..clear()
        ..addAll(typing);
    });
  }

  void _setTyping(bool typing) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _presence?.track({
      'user_id': uid,
      'nickname': _myNickname(),
      'typing': typing,
      'at': DateTime.now().toIso8601String(),
    });
  }

  // Synthetic Scout "member" entry for @-autocomplete
  static const _scoutSuggestion = <String, dynamic>{
    'tag': 'scout',
    'nickname': 'scout',
    'emoji': '🧭',
    'user_id': null,
  };

  void _onTextChanged(String text) {
    // Debounced typing broadcast
    if (!_isTyping) {
      _isTyping = true;
      _setTyping(true);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _setTyping(false);
    });

    // @mention autocomplete — include Scout as a virtual first entry
    final selection = _ctrl.selection;
    if (!selection.isValid) return;
    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;
    final before = text.substring(0, cursor);
    final match = RegExp(r'@([a-z0-9_]*)$').firstMatch(before);
    if (match != null) {
      final q = match.group(1) ?? '';
      final suggestions = <Map<String, dynamic>>[];
      if ('scout'.startsWith(q) || q.isEmpty) {
        suggestions.add(_scoutSuggestion);
      }
      suggestions.addAll(_squadByTag.entries
          .where((e) => e.key.startsWith(q))
          .map((e) => e.value));
      setState(() {
        _mentionStart = match.start;
        _mentionSuggestions = suggestions.take(6).toList();
      });
    } else {
      if (_mentionSuggestions.isNotEmpty || _mentionStart != -1) {
        setState(() {
          _mentionStart = -1;
          _mentionSuggestions = [];
        });
      }
    }
  }

  void _insertMention(Map<String, dynamic> user) {
    final tag = (user['tag'] as String?) ?? '';
    if (tag.isEmpty || _mentionStart < 0) return;
    final cursor = _ctrl.selection.baseOffset;
    final newText = _ctrl.text.replaceRange(
      _mentionStart,
      cursor,
      '@$tag ',
    );
    final newCursor = _mentionStart + tag.length + 2;
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    setState(() {
      _mentionStart = -1;
      _mentionSuggestions = [];
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatServiceProvider).send(
            tripId: widget.tripId,
            content: text,
            replyToId: _replyingTo?.id,
          );
      _ctrl.clear();
      _isTyping = false;
      _setTyping(false);
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _replyingTo = null);
      TSHaptics.light();
      _scrollToBottom();

      // If the message mentions @scout, invoke Scout — its reply posts
      // inline as an AI chat message visible to the whole squad.
      final scoutPattern = RegExp(r'@scout\b', caseSensitive: false);
      if (scoutPattern.hasMatch(text)) {
        // Strip the @scout token and send the remainder as the prompt
        final prompt = text.replaceAll(scoutPattern, '').trim();
        if (prompt.isNotEmpty) {
          setState(() => _scoutThinking = true);
          try {
            await ref.read(scoutServiceProvider).askInTrip(
                  tripId: widget.tripId,
                  content: prompt,
                );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    'scout couldn\'t respond — ${humanizeError(e)}')),
              );
            }
          } finally {
            if (mounted) setState(() => _scoutThinking = false);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Pick an image, open a preview sheet for the caption, then
  /// upload + post. Supports `@scout` in the caption (Scout
  /// replies to the caption text — it can't "see" the photo, so
  /// keep the question in words).
  Future<void> _attachPhoto() async {
    if (_sending) return;
    final file = await pickPhotoFromSheet(context);
    if (file == null) return;
    if (!mounted) return;
    final caption = await showModalBottomSheet<_ImageCaptionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ImageCaptionSheet(filePath: file.path),
    );
    if (caption == null || caption.cancelled) return;
    setState(() => _sending = true);
    TSHaptics.ctaCommit();
    try {
      final url = await ref.read(chatServiceProvider).uploadChatImage(
            tripId: widget.tripId,
            filePath: file.path,
          );
      final text = caption.text.trim();
      await ref.read(chatServiceProvider).send(
            tripId: widget.tripId,
            content: text.isEmpty ? '📷' : text,
            imageUrl: url,
            replyToId: _replyingTo?.id,
          );
      setState(() => _replyingTo = null);
      // If the caption mentions @scout, hand it off to Scout-in-
      // trip. Scout reads the photo directly via the public URL
      // (Claude Sonnet 4 vision) so "what is this place?" works
      // even without words describing it.
      final scoutPattern = RegExp(r'@scout\b', caseSensitive: false);
      if (scoutPattern.hasMatch(text)) {
        final prompt = text.replaceAll(scoutPattern, '').trim();
        setState(() => _scoutThinking = true);
        try {
          await ref.read(scoutServiceProvider).askInTrip(
                tripId: widget.tripId,
                content: prompt.isEmpty
                    ? 'what am i looking at?'
                    : prompt,
                imageUrl: url,
              );
        } finally {
          if (mounted) setState(() => _scoutThinking = false);
        }
      }
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

  /// Confirm + delete a chat message the user authored. RLS
  /// restricts the delete to the original sender; if it fails
  /// we surface a snackbar so the bug is visible.
  /// Estimate the scroll offset for a given message's row and
  /// animate there. Rows are variable-height so we approximate via
  /// average; good enough to land in the viewport.
  void _jumpToMessage(List<ChatMessage> messages, String messageId) {
    if (!_scroll.hasClients) return;
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    TSHaptics.light();
    // Very rough estimate: the TabBarView + ListView has variable
    // row heights. Assume ~96pt per row as a middle-ground guess,
    // then clamp to the actual extent.
    final target =
        (idx * 96.0).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  bool _isTripHost() {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final trip = ref.read(tripStreamProvider(widget.tripId)).valueOrNull;
    return me != null && trip?.hostId == me;
  }

  Future<void> _sendVoiceMemo(String filePath, Duration duration) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final url = await ref.read(chatServiceProvider).uploadChatAudio(
            tripId: widget.tripId,
            filePath: filePath,
          );
      await ref.read(chatServiceProvider).send(
            tripId: widget.tripId,
            content: '🎙️',
            audioUrl: url,
            audioDurationMs: duration.inMilliseconds,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('voice memo failed — ${humanizeError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reportChat(ChatMessage msg) async {
    final reason = await showReportReasonSheet(context);
    if (reason == null || !mounted) return;
    try {
      await ref.read(chatServiceProvider).reportMessage(
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

  Future<void> _editChat(ChatMessage msg) async {
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
      await ref.read(chatServiceProvider).editMessage(
            messageId: msg.id,
            content: trimmed,
          );
      ref.invalidate(chatMessagesProvider(widget.tripId));
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

  Future<void> _confirmDeleteChat(ChatMessage msg) async {
    TSHaptics.medium();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
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
                'removes it for everyone in the squad. reactions + replies disappear too.',
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
      await ref.read(chatServiceProvider).deleteMessage(msg.id);
      // Force-refresh the stream provider so the row disappears
      // without waiting for realtime's DELETE broadcast (which
      // can lag or skip depending on replica identity).
      ref.invalidate(chatMessagesProvider(widget.tripId));
      ref.invalidate(chatReactionsProvider(widget.tripId));
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

  /// Long-press on a chat photo — offers the host a shortcut to
  /// re-use the image as the trip's cover. Non-hosts get a quieter
  /// "copy image url" fallback so the gesture still does
  /// something useful.
  Future<void> _onChatPhotoLongPress(String url) async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final trip = ref.read(tripStreamProvider(widget.tripId)).valueOrNull;
    final isHost = me != null && trip?.hostId == me;
    TSHaptics.medium();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
              if (isHost)
                _photoMenuTile(
                  emoji: '🖼️',
                  label: 'use as trip cover',
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    try {
                      await ref
                          .read(tripServiceProvider)
                          .setCoverFromUrl(
                              tripId: widget.tripId, url: url);
                      ref.invalidate(myTripsProvider);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('cover updated',
                              style: TSTextStyles.body(
                                  color: TSColors.bg, size: 13)),
                          backgroundColor: TSColors.lime,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (_) {/* silent */}
                  },
                ),
              _photoMenuTile(
                emoji: '🔗',
                label: 'copy image link',
                onTap: () async {
                  Navigator.of(sheet).pop();
                  await Clipboard.setData(ClipboardData(text: url));
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoMenuTile({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TSTextStyles.title(
                    size: 14, color: TSColors.text)),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.muted, size: 14),
        ]),
      ),
    );
  }

  Future<void> _askScout() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _scoutThinking) return;
    setState(() => _scoutThinking = true);
    try {
      await ref.read(scoutServiceProvider).askInTrip(
            tripId: widget.tripId,
            content: text,
          );
      _ctrl.clear();
      TSHaptics.medium();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scout is unreachable — ${humanizeError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _scoutThinking = false);
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(max);
      } else {
        _scroll.animateTo(
          max,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Only follow along when new messages arrive; first render jumps
  /// straight to the bottom so we never land mid-thread. If the user
  /// has scrolled up to read history (jump button showing), leave
  /// them there — the button is how they opt back in.
  void _maybeAutoScroll(int count) {
    if (count == _lastKnownCount) return;
    final wasFirst = _lastKnownCount == 0 && count > 0;
    _lastKnownCount = count;
    if (wasFirst) {
      _scrollToBottom(jump: true);
      return;
    }
    if (_showJumpBtn) return;
    _scrollToBottom();
  }

  /// Show the floating "jump to latest" chip once the user has
  /// scrolled more than ~200px above the bottom. Called on every
  /// scroll notification — cheap boolean flip, no rebuild spam.
  bool _onScrollNotification(ScrollNotification n) {
    if (!_scroll.hasClients) return false;
    final distance = _scroll.position.maxScrollExtent -
        _scroll.position.pixels;
    final show = distance > 200;
    if (show != _showJumpBtn) {
      setState(() => _showJumpBtn = show);
    }
    return false;
  }

  @override
  void dispose() {
    _presence?.unsubscribe();
    _typingDebounce?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.tripId));
    final reactionsAsync = ref.watch(chatReactionsProvider(widget.tripId));
    final me = Supabase.instance.client.auth.currentUser?.id;

    // Pinned banner — shows the one pinned message for the trip
    // (if any). Updates live via the chatMessagesProvider stream.
    final pinned = messagesAsync.asData?.value.firstWhere(
          (m) => m.pinnedAt != null,
          orElse: () => ChatMessage(
            id: '',
            tripId: widget.tripId,
            nickname: '',
            content: '',
            seenBy: const [],
            mentions: const [],
          ),
        );
    final hasPin = pinned != null && pinned.id.isNotEmpty;

    return Column(children: [
      // Search + presence bar. Tap the 🔍 to reveal the field —
      // we keep it collapsed by default so the header stays tight.
      // Replaces the old standalone _PresenceStrip (absorbed here).
      _ChatHeaderBar(
        searchOpen: _searchOpen,
        searchCtrl: _searchCtrl,
        online: _online.length,
        typingUsers: _typingUsers.values.toList(),
        onToggleSearch: () {
          setState(() {
            _searchOpen = !_searchOpen;
            if (!_searchOpen) {
              _search = '';
              _searchCtrl.clear();
              FocusManager.instance.primaryFocus?.unfocus();
            }
          });
        },
        onSearchChanged: (v) => setState(() => _search = v.trim()),
      ),
      if (hasPin)
        _PinnedBanner(
          msg: pinned,
          isHost: _isTripHost(),
          onJump: () => _jumpToMessage(
              messagesAsync.asData?.value ?? const [], pinned.id),
        ),
      Expanded(
        child: Stack(children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: messagesAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: TSColors.lime)),
          error: (e, _) => Center(child: Text(humanizeError(e))),
          data: (rawMessages) {
            if (rawMessages.isEmpty) return const _EmptyChat();
            // Apply search filter if open and has a query.
            final q = _search.toLowerCase();
            final messages = (!_searchOpen || q.isEmpty)
                ? rawMessages
                : rawMessages
                    .where((m) => m.content.toLowerCase().contains(q))
                    .toList();
            if (messages.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('no messages match "${_searchCtrl.text}"',
                      style: TSTextStyles.caption(color: TSColors.muted)),
                ),
              );
            }
            final reactions =
                reactionsAsync.asData?.value ?? const <ChatReaction>[];
            // Build reaction index once
            final byMsg = <String, List<ChatReaction>>{};
            for (final r in reactions) {
              byMsg.putIfAbsent(r.messageId, () => []).add(r);
            }
            // Mark latest own message seen for read receipts
            final seenCandidates = messages.where((m) =>
                m.userId != me && (me == null || !m.seenBy.contains(me)));
            for (final m in seenCandidates.take(20)) {
              ref.read(chatServiceProvider).markSeen(m.id);
            }
            _maybeAutoScroll(rawMessages.length);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: messages.length,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemBuilder: (_, i) {
                  final prev = i == 0 ? null : messages[i - 1];
                  final dayLabel =
                      _dayChangeLabel(prev?.createdAt, messages[i].createdAt);
                  final row = _MessageRow(
                    msg: messages[i],
                    parent: messages[i].replyToId == null
                        ? null
                        : messages.firstWhere(
                            (m) => m.id == messages[i].replyToId,
                            orElse: () => messages[i],
                          ),
                    reactions: byMsg[messages[i].id] ?? const [],
                    meUid: me,
                    totalSquad:
                        _squadByTag.isNotEmpty ? _squadByTag.length : _online.length,
                    avatarByUid: _avatarByUid,
                    squadByTag: _squadByTag,
                    onReply: (m) => setState(() => _replyingTo = m),
                    onReact: (m) => _showReactionPicker(context, m),
                    // Double-tap → instant 🔥 react, no picker.
                    onQuickReact: (m) => _quickReact(m),
                    onPhotoLongPress: _onChatPhotoLongPress,
                    onJumpToParent: (id) =>
                        _jumpToMessage(rawMessages, id),
                  );
                  if (dayLabel == null) return row;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateSeparator(label: dayLabel),
                      row,
                    ],
                  );
                },
              ),
            );
          },
        ),
        ),
        // Floating "jump to latest" chip — shows when scrolled up
        // more than ~200px. Sits bottom-center above the composer.
        if (_showJumpBtn)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  TSHaptics.light();
                  _scrollToBottom();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: TSColors.lime,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_downward_rounded,
                          color: TSColors.bg, size: 14),
                      const SizedBox(width: 4),
                      Text('latest',
                          style: TSTextStyles.label(
                              color: TSColors.bg, size: 10)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
      if (_scoutThinking) const _ScoutThinking(),
      // Squad typing bubble — surfaces above the composer so it's
      // visible while you're typing a reply. Hidden when Scout is
      // thinking to avoid stacking two indicators.
      if (!_scoutThinking && _typingUsers.isNotEmpty)
        _TypingBubble(nicknames: _typingUsers.values.toList()),
      if (_mentionSuggestions.isNotEmpty) _MentionList(
        users: _mentionSuggestions,
        onPick: _insertMention,
      ),
      if (_replyingTo != null)
        _ReplyPreview(
          msg: _replyingTo!,
          onClear: () => setState(() => _replyingTo = null),
        ),
      _Composer(
        controller: _ctrl,
        sending: _sending,
        scoutThinking: _scoutThinking,
        onChanged: _onTextChanged,
        onSend: _send,
        onAskScout: _askScout,
        onAttachPhoto: _attachPhoto,
        onVoiceMemo: _sendVoiceMemo,
      ),
    ]);
  }

  /// Double-tap fast-path. Adds the default 🔥 reaction without
  /// opening the picker. Idempotent server-side — repeated double-
  /// taps either add or no-op (depending on the reactions RPC
  /// semantics; if it upserts, tapping again is a no-op).
  Future<void> _quickReact(ChatMessage msg) async {
    try {
      await ref.read(chatServiceProvider).react(
            messageId: msg.id,
            emoji: '🔥',
          );
    } catch (_) {
      // Silent — double-tap should never feel "error-y".
    }
  }

  void _showReactionPicker(BuildContext context, ChatMessage msg) {
    TSHaptics.medium();
    showModalBottomSheet(
      context: context,
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
                      onTap: () async {
                        Navigator.pop(sheet);
                        await ref.read(chatServiceProvider).react(
                              messageId: msg.id,
                              emoji: emoji,
                            );
                        TSHaptics.light();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
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
                if (!context.mounted) return;
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
                try {
                  await Share.share(
                    '${msg.nickname}: ${msg.content}\n\n'
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
            if (_isTripHost()) ...[
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  Navigator.pop(sheet);
                  try {
                    await ref.read(chatServiceProvider).togglePin(
                          msg.id,
                          pin: msg.pinnedAt == null,
                        );
                    ref.invalidate(
                        chatMessagesProvider(widget.tripId));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'couldn\'t pin — ${humanizeError(e)}'),
                      ),
                    );
                  }
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
                      Icon(
                        msg.pinnedAt == null
                            ? Icons.push_pin_outlined
                            : Icons.push_pin_rounded,
                        color: TSColors.lime,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                          msg.pinnedAt == null
                              ? 'pin for the squad'
                              : 'unpin',
                          style: TSTextStyles.body(
                              color: TSColors.lime, size: 14)),
                    ],
                  ),
                ),
              ),
            ],
            if (msg.userId != null &&
                msg.userId != Supabase.instance.client.auth.currentUser?.id) ...[
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  Navigator.pop(sheet);
                  await _reportChat(msg);
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
            if (msg.userId == Supabase.instance.client.auth.currentUser?.id) ...[
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  Navigator.pop(sheet);
                  await _editChat(msg);
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
                  await _confirmDeleteChat(msg);
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
}

/// Trip-chat pinned-message banner. Renders at the top of the
/// thread whenever any message has a non-null `pinned_at`. Host
/// sees an "unpin" affordance via long-press on the message
/// itself; this banner just surfaces the content.
class _PinnedBanner extends ConsumerWidget {
  const _PinnedBanner({
    required this.msg,
    required this.isHost,
    required this.onJump,
  });
  final ChatMessage msg;
  final bool isHost;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = msg.content.replaceAll('\n', ' ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onJump,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: TSColors.s2,
        border: Border(
          bottom: BorderSide(color: TSColors.border),
        ),
      ),
      child: Row(children: [
        const Icon(Icons.push_pin_rounded,
            color: TSColors.lime, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PINNED · ${msg.nickname} · tap to jump',
                  style: TSTextStyles.label(
                      color: TSColors.lime, size: 9)),
              const SizedBox(height: 1),
              Text(preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TSTextStyles.caption(color: TSColors.text)),
            ],
          ),
        ),
        if (isHost)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              TSHaptics.medium();
              try {
                await ref.read(chatServiceProvider).togglePin(
                      msg.id,
                      pin: false,
                    );
                ref.invalidate(chatMessagesProvider(msg.tripId));
              } catch (_) {/* silent */}
            },
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded,
                  color: TSColors.muted, size: 14),
            ),
          ),
      ]),
    ),
    );
  }
}

/// Combined search + online/typing bar at the top of trip chat.
/// The search field slides in when the user taps 🔍; closes with ×.
class _ChatHeaderBar extends StatelessWidget {
  const _ChatHeaderBar({
    required this.searchOpen,
    required this.searchCtrl,
    required this.online,
    required this.typingUsers,
    required this.onToggleSearch,
    required this.onSearchChanged,
  });
  final bool searchOpen;
  final TextEditingController searchCtrl;
  final int online;
  final List<String> typingUsers;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    String? typingLabel;
    if (typingUsers.isNotEmpty) {
      typingLabel = typingUsers.length == 1
          ? '${typingUsers.first} is typing…'
          : '${typingUsers.length} people typing…';
    }
    if (searchOpen) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        color: TSColors.s1,
        child: Row(children: [
          const Icon(Icons.search_rounded,
              color: TSColors.lime, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchCtrl,
              autofocus: true,
              onChanged: onSearchChanged,
              style: TSTextStyles.body(size: 14),
              decoration: InputDecoration(
                hintText: 'search chat…',
                hintStyle:
                    TSTextStyles.body(size: 14, color: TSColors.muted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: TSColors.muted, size: 18),
            onPressed: onToggleSearch,
            tooltip: 'close search',
          ),
        ]),
      );
    }
    if (online == 0 && typingLabel == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: TSColors.s1,
        child: Row(children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: TSColors.muted, size: 18),
            onPressed: onToggleSearch,
            tooltip: 'search chat',
            visualDensity: VisualDensity.compact,
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: TSColors.s1,
      child: Row(children: [
        if (online > 0) ...[
          const Icon(Icons.circle, color: TSColors.lime, size: 8),
          const SizedBox(width: 6),
          Text('$online online', style: TSTextStyles.caption()),
        ],
        if (typingLabel != null) ...[
          const SizedBox(width: 12),
          Text(typingLabel,
              style: TSTextStyles.caption(color: TSColors.lime)),
        ],
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.search_rounded,
              color: TSColors.muted, size: 18),
          onPressed: onToggleSearch,
          tooltip: 'search chat',
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }
}


class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.msg,
    required this.parent,
    required this.reactions,
    required this.meUid,
    required this.totalSquad,
    required this.avatarByUid,
    required this.squadByTag,
    required this.onReply,
    required this.onReact,
    required this.onQuickReact,
    required this.onPhotoLongPress,
    this.onJumpToParent,
  });
  final ChatMessage msg;
  final ChatMessage? parent;
  final List<ChatReaction> reactions;
  final String? meUid;
  final int totalSquad;
  final Map<String, String?> avatarByUid;
  final Map<String, Map<String, dynamic>> squadByTag;
  final void Function(ChatMessage) onReply;
  final void Function(ChatMessage) onReact;
  final void Function(ChatMessage) onQuickReact;
  final void Function(String url) onPhotoLongPress;
  final void Function(String messageId)? onJumpToParent;

  @override
  Widget build(BuildContext context) {
    if (msg.isAi) {
      return _ScoutBubble(
        msg: msg,
        reactions: reactions,
        onReact: () => onReact(msg),
        onQuickReact: () => onQuickReact(msg),
      );
    }
    final isMe = msg.userId == meUid;
    // Single wrapper handles both gestures. Child is the raw layout —
    // no nested GestureDetector (which was swallowing pointer events).
    return _MessageGestureWrapper(
      onLongPress: () => onReact(msg),
      onSwipeReply: () => onReply(msg),
      onDoubleTap: () => onQuickReact(msg),
      child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: msg.userId == null
                        ? null
                        : () {
                            TSHaptics.light();
                            context.push('/user/${msg.userId}');
                          },
                    child: TSAvatar(
                      emoji: msg.emoji,
                      photoUrl: msg.userId == null
                          ? null
                          : avatarByUid[msg.userId!],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(msg.nickname,
                              style: TSTextStyles.caption(color: TSColors.muted)),
                        if (parent != null)
                          _ParentQuote(
                            parent: parent!,
                            onTap: onJumpToParent == null
                                ? null
                                : () => onJumpToParent!(parent!.id),
                          ),
                        const SizedBox(height: 2),
                        if (msg.imageUrl != null &&
                            msg.imageUrl!.isNotEmpty) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => openPhotoLightbox(
                                context, msg.imageUrl!),
                            onLongPress: () =>
                                onPhotoLongPress(msg.imageUrl!),
                            child: Hero(
                              tag: msg.imageUrl!,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      maxWidth: 260, maxHeight: 260),
                                  child: CachedNetworkImage(
                                    imageUrl: msg.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: 200,
                                      height: 200,
                                      color: TSColors.s2,
                                    ),
                                    errorWidget: (_, __, ___) =>
                                        Container(
                                      width: 200,
                                      height: 120,
                                      color: TSColors.s2,
                                      alignment: Alignment.center,
                                      child: Text('📷',
                                          style: TSTextStyles.body(
                                              color: TSColors.muted)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (msg.audioUrl != null && msg.audioUrl!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? TSColors.lime : TSColors.s2,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isMe ? 14 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 14),
                              ),
                            ),
                            child: VoiceMemoPlayer(
                              url: msg.audioUrl!,
                              durationMs: msg.audioDurationMs,
                              onBubble: isMe,
                            ),
                          ),
                        if ((msg.content.trim() != '📷' ||
                                (msg.imageUrl ?? '').isEmpty) &&
                            (msg.content.trim() != '🎙️' ||
                                (msg.audioUrl ?? '').isEmpty))
                          Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? TSColors.lime : TSColors.s2,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(isMe ? 14 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 14),
                            ),
                          ),
                          child: _RichContent(
                            content: msg.content,
                            color: isMe ? TSColors.bg : TSColors.text,
                            onTagTap: (tag) {
                              if (tag.toLowerCase() == 'scout') return;
                              final member =
                                  squadByTag[tag.toLowerCase()];
                              final uid =
                                  member?['user_id'] as String?;
                              if (uid == null) return;
                              TSHaptics.light();
                              context.push('/user/$uid');
                            },
                          ),
                        ),
                        if (msg.editedAt != null)
                          Padding(
                            padding: EdgeInsets.only(
                                top: 2,
                                left: isMe ? 0 : 4,
                                right: isMe ? 4 : 0),
                            child: Text('edited',
                                style: TSTextStyles.label(
                                    color: TSColors.muted, size: 9)),
                          ),
                        if (reactions.isNotEmpty) _ReactionChips(reactions: reactions),
                        if (isMe) _ReadReceipt(
                          seenCount: msg.seenBy.length,
                          totalSquad: totalSquad,
                        ),
                      ]),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _ParentQuote extends StatelessWidget {
  const _ParentQuote({required this.parent, this.onTap});
  final ChatMessage parent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TSColors.s3,
          borderRadius: TSRadius.xs,
          border: const Border(
            left: BorderSide(color: TSColors.lime, width: 2),
          ),
        ),
        child: Text(
          '${parent.nickname}: ${parent.content}',
          style: TSTextStyles.caption(color: TSColors.muted),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Returns the human-readable label for a new day divider when
/// [current] falls on a different calendar day than [previous].
/// Mirrors the DM thread helper so the two surfaces stay
/// consistent.
String? _dayChangeLabel(DateTime? previous, DateTime? current) {
  if (current == null) return null;
  if (previous != null &&
      previous.year == current.year &&
      previous.month == current.month &&
      previous.day == current.day) {
    return null;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay =
      DateTime(current.year, current.month, current.day);
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

class _RichContent extends StatefulWidget {
  const _RichContent({
    required this.content,
    required this.color,
    this.onTagTap,
    this.size = 16,
  });
  final String content;
  final Color color;
  final void Function(String tag)? onTagTap;
  final double size;

  @override
  State<_RichContent> createState() => _RichContentState();
}

class _RichContentState extends State<_RichContent> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dispose previous recognizers on rebuild (content can change).
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    // Single regex matching either `@handle` OR a URL. The order
    // of alternatives matters — we want the longer URL match to
    // win if both would apply at a given cursor.
    final re = RegExp(
      r'(https?://[^\s<>]+)|@([a-z0-9_]{2,30})',
      caseSensitive: false,
    );
    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final m in re.allMatches(widget.content)) {
      if (m.start > cursor) {
        spans.add(TextSpan(
          text: widget.content.substring(cursor, m.start),
          style: TSTextStyles.body(color: widget.color, size: widget.size),
        ));
      }
      final urlMatch = m.group(1);
      if (urlMatch != null) {
        final tap = TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(urlMatch);
            if (uri == null) return;
            try {
              await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
            } catch (_) {/* silent */}
          };
        _recognizers.add(tap);
        spans.add(TextSpan(
          text: urlMatch,
          style: TSTextStyles.body(color: widget.color, size: widget.size).copyWith(
            decoration: TextDecoration.underline,
            color: widget.color == TSColors.bg
                ? TSColors.bg
                : TSColors.lime,
          ),
          recognizer: tap,
        ));
      } else {
        // @mention
        TapGestureRecognizer? tap;
        if (widget.onTagTap != null) {
          final tag = m.group(2)!;
          tap = TapGestureRecognizer()
            ..onTap = () => widget.onTagTap!(tag);
          _recognizers.add(tap);
        }
        spans.add(TextSpan(
          text: m.group(0),
          style: TSTextStyles.body(color: widget.color, size: widget.size).copyWith(
            fontWeight: FontWeight.w700,
            color: widget.color == TSColors.bg
                ? TSColors.bg
                : TSColors.lime,
          ),
          recognizer: tap,
        ));
      }
      cursor = m.end;
    }
    if (cursor < widget.content.length) {
      spans.add(TextSpan(
        text: widget.content.substring(cursor),
        style: TSTextStyles.body(color: widget.color),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _ReactionChips extends StatelessWidget {
  const _ReactionChips({required this.reactions});
  final List<ChatReaction> reactions;

  void _showWhoReacted(BuildContext context, String emoji) {
    final userIds = reactions
        .where((r) => r.emoji == emoji)
        .map((r) => r.userId)
        .toList();
    TSHaptics.light();
    showModalBottomSheet<void>(
      context: context,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TSColors.border),
                ),
                child: Text(
                  '${entry.key} ${entry.value}',
                  style: TSTextStyles.caption(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadReceipt extends StatelessWidget {
  const _ReadReceipt({required this.seenCount, required this.totalSquad});
  final int seenCount;
  final int totalSquad;

  @override
  Widget build(BuildContext context) {
    if (totalSquad <= 1) return const SizedBox();
    final allSeen = seenCount >= totalSquad - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 2),
      child: Icon(
        allSeen ? Icons.done_all_rounded : Icons.done_rounded,
        size: 14,
        color: allSeen ? TSColors.lime : TSColors.muted,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Message gesture wrapper
//
//  Uses a `Listener` for raw pointer events — bypasses the gesture
//  arena entirely so the horizontal drag never loses to the ListView
//  scroll or the Cupertino edge-swipe-back recognizer. Long-press
//  and double-tap stay on `GestureDetector` (they're stationary
//  gestures and don't compete with anything).
//
//  - Long-press         → full reaction picker
//  - Double-tap         → instant 🔥 react (the "fast lane")
//  - Horizontal drag →  right → reply (fires at 56px)
// ─────────────────────────────────────────────────────────────

class _MessageGestureWrapper extends StatefulWidget {
  const _MessageGestureWrapper({
    required this.child,
    required this.onLongPress,
    required this.onSwipeReply,
    required this.onDoubleTap,
  });
  final Widget child;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeReply;
  final VoidCallback onDoubleTap;

  @override
  State<_MessageGestureWrapper> createState() =>
      _MessageGestureWrapperState();
}

class _MessageGestureWrapperState extends State<_MessageGestureWrapper> {
  double _dx = 0;
  double _startX = 0;
  double _startY = 0;
  bool _didFire = false;
  bool _tracking = false;

  /// Min horizontal distance (px) to commit the reply.
  static const _commitPx = 56;

  /// How far finger must move horizontally *before* vertically for
  /// us to claim the gesture. Keeps ListView scroll responsive.
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
          // Claim only if horizontal movement dominates and we've
          // moved past the direction threshold — otherwise let the
          // ListView scroll vertically.
          if (dx.abs() < _directionThreshold &&
              dy.abs() < _directionThreshold) {
            return;
          }
          if (dx.abs() <= dy.abs()) return; // vertical-dominant
          if (dx < 0) return;                // only right-swipes
          _tracking = true;
        }

        final newDx = dx.clamp(0.0, 120.0);
        if (newDx != _dx) {
          setState(() => _dx = newDx);
        }
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
                    child: const Icon(
                      Icons.reply_rounded,
                      color: TSColors.lime,
                      size: 20,
                    ),
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

class _ScoutBubble extends ConsumerWidget {
  const _ScoutBubble({
    required this.msg,
    required this.reactions,
    this.onReact,
    this.onQuickReact,
  });
  final ChatMessage msg;
  final List<ChatReaction> reactions;
  final VoidCallback? onReact;
  final VoidCallback? onQuickReact;

  Future<void> _longPress(BuildContext context, WidgetRef ref) async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final trip = ref.read(tripStreamProvider(msg.tripId)).valueOrNull;
    final isHost = me != null && trip?.hostId == me;
    TSHaptics.medium();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
              if (onReact != null) ...[
                _bubbleAction(
                  emoji: '🔥',
                  label: 'react',
                  onTap: () {
                    Navigator.pop(sheet);
                    onReact!();
                  },
                ),
                const SizedBox(height: 8),
              ],
              _bubbleAction(
                emoji: '📋',
                label: 'copy reply',
                onTap: () async {
                  Navigator.pop(sheet);
                  await Clipboard.setData(
                      ClipboardData(text: msg.content));
                  TSHaptics.light();
                  if (!context.mounted) return;
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
              ),
              if (isHost) ...[
                const SizedBox(height: 8),
                _bubbleAction(
                  emoji: msg.pinnedAt == null ? '📌' : '📍',
                  label: msg.pinnedAt == null
                      ? 'pin for the squad'
                      : 'unpin',
                  onTap: () async {
                    Navigator.pop(sheet);
                    try {
                      await ref.read(chatServiceProvider).togglePin(
                            msg.id,
                            pin: msg.pinnedAt == null,
                          );
                      ref.invalidate(chatMessagesProvider(msg.tripId));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'couldn\'t pin — ${humanizeError(e)}'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubbleAction({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TSColors.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label,
              style:
                  TSTextStyles.body(color: TSColors.text, size: 14)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Redesign §21: Scout's messages get the vertical purple→lime
    // gradient line on the left — a "margin of presence" rather than
    // a full bubble. Never compete visually with human messages.
    //
    // Double-tap adds a 🔥 reaction (same as human messages) and
    // long-press opens the Scout action sheet (copy + host pin).
    // Swipe-to-reply is intentionally omitted — threading on a
    // Scout reply isn't meaningful without Scout following up.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _longPress(context, ref),
      onDoubleTap: onQuickReact,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The gradient margin — Scout's signature.
              Container(
                width: 3,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [TSColors.purple, TSColors.lime],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('🧭', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('scout',
                          style: TSTextStyles.label(
                              color: TSColors.lime, size: 10)),
                      if (msg.pinnedAt != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.push_pin_rounded,
                            color: TSColors.lime, size: 11),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    LinkifiedText(content: msg.content),
                    if (msg.editedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('edited',
                            style: TSTextStyles.label(
                                color: TSColors.muted, size: 9)),
                      ),
                    if (reactions.isNotEmpty)
                      _ReactionChips(reactions: reactions),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MentionList extends StatelessWidget {
  const _MentionList({required this.users, required this.onPick});
  final List<Map<String, dynamic>> users;
  final void Function(Map<String, dynamic>) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: TSColors.s1,
        border: Border.all(color: TSColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: users.length,
        separatorBuilder: (_, __) =>
            const Divider(color: TSColors.border, height: 1),
        itemBuilder: (_, i) {
          final u = users[i];
          return InkWell(
            onTap: () => onPick(u),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(children: [
                Text((u['emoji'] as String?) ?? '😎',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(
                  (u['nickname'] as String?) ?? 'someone',
                  style: TSTextStyles.body(),
                ),
                const SizedBox(width: 6),
                Text('@${u['tag']}',
                    style: TSTextStyles.caption(color: TSColors.lime)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.msg, required this.onClear});
  final ChatMessage msg;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    // Loud, lime-bordered bar so users can't miss that their swipe
    // landed. Cleared via the trailing X or by sending the reply.
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
              Text('replying to ${msg.nickname}',
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
          icon: const Icon(Icons.close_rounded, size: 18),
          color: TSColors.muted,
          onPressed: onClear,
        ),
      ]),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.scoutThinking,
    required this.onChanged,
    required this.onSend,
    required this.onAskScout,
    required this.onAttachPhoto,
    required this.onVoiceMemo,
  });
  final TextEditingController controller;
  final bool sending, scoutThinking;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend, onAskScout;
  final VoidCallback onAttachPhoto;
  final Future<void> Function(String filePath, Duration duration) onVoiceMemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: TSColors.s1,
        border: Border(top: BorderSide(color: TSColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          IconButton(
            tooltip: 'ask scout',
            icon: const Text('🧭', style: TextStyle(fontSize: 22)),
            onPressed: scoutThinking ? null : onAskScout,
          ),
          IconButton(
            tooltip: 'camera or library',
            icon: const Icon(Icons.photo_camera_outlined,
                color: TSColors.lime, size: 22),
            onPressed: sending ? null : onAttachPhoto,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: TSTextStyles.body(),
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'message the squad…',
                hintStyle: TSTextStyles.body(color: TSColors.muted),
                filled: true,
                fillColor: TSColors.s2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.trim().isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: HoldToRecordMic(
                    enabled: !sending,
                    onRecorded: onVoiceMemo,
                  ),
                );
              }
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: sending ? null : onSend,
                child: Opacity(
                  opacity: sending ? 0.4 : 1,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TSColors.purple, TSColors.lime],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

/// Preview sheet shown after picking an image. Lets the sender
/// write a caption (optionally @-mentioning Scout) before posting.
class _ImageCaptionResult {
  const _ImageCaptionResult({required this.text, required this.cancelled});
  final String text;
  final bool cancelled;
}

class _ImageCaptionSheet extends StatefulWidget {
  const _ImageCaptionSheet({required this.filePath});
  final String filePath;

  @override
  State<_ImageCaptionSheet> createState() => _ImageCaptionSheetState();
}

class _ImageCaptionSheetState extends State<_ImageCaptionSheet> {
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
              hintText: 'add a caption · @scout can see it + answer ✨',
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
                onTap: () => Navigator.of(context).pop(
                    const _ImageCaptionResult(text: '', cancelled: true)),
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
                onTap: () => Navigator.of(context).pop(
                    _ImageCaptionResult(
                        text: _ctrl.text, cancelled: false)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [TSColors.purple, TSColors.lime],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Text('send ↑',
                      style: TSTextStyles.title(
                          size: 13, color: Colors.white)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('💬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('say hi to the squad',
              style: TSTextStyles.body(color: TSColors.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('swipe → reply · double-tap 🔥 · long-press react / copy',
              style: TSTextStyles.caption(color: TSColors.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TSColors.limeDim(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TSColors.limeDim(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🧭', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'stuck? type @scout for travel help',
                  style: TSTextStyles.caption(color: TSColors.lime),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ScoutThinking extends StatefulWidget {
  const _ScoutThinking();

  @override
  State<_ScoutThinking> createState() => _ScoutThinkingState();
}

class _ScoutThinkingState extends State<_ScoutThinking>
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        const Text('🧭', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(
              children: List.generate(3, (i) {
            final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
            final opacity = 0.3 + (t * 0.7);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: TSColors.lime.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          })),
        ),
        const SizedBox(width: 8),
        Text('scout is thinking…',
            style: TSTextStyles.caption(color: TSColors.muted)),
      ]),
    );
  }
}

/// Squad-typing bubble. Mirrors the chat-bubble shape of other
/// incoming messages (muted `s2` fill, bottom-left asymmetric
/// radius) with 3 pulsing dots and a nickname label below.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.nicknames});
  final List<String> nicknames;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
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

  String _label() {
    final names = widget.nicknames;
    if (names.isEmpty) return 'someone is typing';
    if (names.length == 1) return '${names.first} is typing';
    if (names.length == 2) return '${names[0]} and ${names[1]} are typing';
    return '${names.first} and ${names.length - 1} others are typing';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: TSColors.s2,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
                    final opacity = 0.3 + (t * 0.7);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: TSColors.text2.withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _label(),
                style: TSTextStyles.caption(color: TSColors.muted2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
