import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/linkified_text.dart';
import '../../widgets/photo_lightbox.dart';
import '../../widgets/photo_source_sheet.dart';
import '../../widgets/ts_scaffold.dart';
import '../../widgets/scout_greeting.dart';
import '../../widgets/motion.dart';
import '../../widgets/saved_scout_tips.dart';

const _quickPrompts = [
  'where should i go next?',
  'best trips under \$1,000',
  'long weekend ideas',
  'hidden gems in europe',
  'solo-friendly destinations',
];

class ScoutTabScreen extends ConsumerStatefulWidget {
  const ScoutTabScreen({super.key});

  @override
  ConsumerState<ScoutTabScreen> createState() => _ScoutTabScreenState();
}

class _ScoutTabScreenState extends ConsumerState<ScoutTabScreen>
    with WidgetsBindingObserver {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _thinking = false;
  bool _showJumpBtn = false;
  bool _searchOpen = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  /// Last msgs.length we've seen. First render lands here as 0 so
  /// we force a *jump-to-bottom* for the initial frame (no fighting
  /// user scroll, no mid-thread landing). After that, we only
  /// auto-scroll when the count grows — so scrolling up stays
  /// honored.
  int _lastKnownCount = 0;

  bool _onScrollNotification(ScrollNotification n) {
    if (!_scroll.hasClients) return false;
    final distance =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    final show = distance > 200;
    if (show != _showJumpBtn) {
      setState(() => _showJumpBtn = show);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSeedWelcome());
  }

  /// Supabase realtime's iOS websocket closes during background and
  /// doesn't reliably replay messages that arrived while the tab was
  /// away. Re-invalidating `scoutHistoryProvider` on resume forces a
  /// fresh fetch so Scout's reply surfaces without the user having
  /// to force-close the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(scoutHistoryProvider);
    }
  }

  /// First-ever visit to Scout with an empty thread — seed one
  /// assistant message so the space isn't a silent void and the
  /// user has a hook to reply to. Guarded per-account by the
  /// `scout_welcomed_<uid>` SharedPreferences key so it never
  /// fires twice, even if the user later clears their history.
  Future<void> _maybeSeedWelcome() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'scout_welcomed_$uid';
    if (prefs.getBool(key) == true) return;
    // Wait for the first history snapshot; bail if the user already
    // has messages (e.g. daily-question card seeded one earlier).
    final history = ref.read(scoutHistoryProvider).valueOrNull;
    if (history != null && history.isNotEmpty) {
      await prefs.setBool(key, true);
      return;
    }
    try {
      await Supabase.instance.client.from('scout_messages').insert({
        'user_id': uid,
        'role': 'assistant',
        'content':
            'hey friend 👋 i\'m scout — your travel-obsessed sidekick. '
                'ask me anything: cheap flights, where to go in july, '
                'what to pack. i\'ll remember what you like.',
      });
      await prefs.setBool(key, true);
    } catch (_) {
      // Non-fatal — realtime will show the message next time.
    }
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _ctrl.text).trim();
    if (text.isEmpty || _thinking) return;
    setState(() => _thinking = true);
    _ctrl.clear();
    try {
      // Persist user message immediately so it appears in the stream
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await Supabase.instance.client.from('scout_messages').insert({
          'user_id': uid,
          'role': 'user',
          'content': text,
        });
      }
      TSHaptics.light();
      // Dismiss keyboard so the user can see Scout thinking + reply
      FocusManager.instance.primaryFocus?.unfocus();
      // Edge function generates + persists the assistant reply
      await ref.read(scoutServiceProvider).ask(text);
      TSHaptics.medium();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scout is unreachable — ${humanizeError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  /// Photo question. Pick → caption sheet → upload → insert the
  /// user row (with image_url + caption) → call the edge function
  /// with the URL so Claude sees the photo. Scout's reply lands in
  /// the thread as usual.
  Future<void> _attachPhoto() async {
    if (_thinking) return;
    final file = await pickPhotoFromSheet(context);
    if (file == null) return;
    if (!mounted) return;
    final caption = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScoutImageCaptionSheet(filePath: file.path),
    );
    if (caption == null) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _thinking = true);
    TSHaptics.ctaCommit();
    try {
      final url = await ref
          .read(scoutServiceProvider)
          .uploadScoutImage(file.path);
      final prompt = caption.trim().isEmpty
          ? 'what am i looking at?'
          : caption.trim();
      await Supabase.instance.client.from('scout_messages').insert({
        'user_id': uid,
        'role': 'user',
        'content': prompt,
        'image_url': url,
      });
      FocusManager.instance.primaryFocus?.unfocus();
      await ref
          .read(scoutServiceProvider)
          .ask(prompt, imageUrl: url);
      TSHaptics.medium();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scout couldn\'t see — ${humanizeError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  /// Animate to bottom — used for button taps + new-message auto-
  /// follow. Never called from build to avoid fighting user scroll.
  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(max);
      } else {
        _scroll.animateTo(max,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  /// Decide whether to auto-scroll on this rebuild. Only scrolls on:
  ///   - first render with any messages (jump, no animation)
  ///   - count grew since last build (animate, new message case)
  /// User-initiated scroll-ups are otherwise preserved.
  void _maybeAutoScroll(int count) {
    if (count == _lastKnownCount) return;
    final wasFirst = _lastKnownCount == 0 && count > 0;
    _lastKnownCount = count;
    _scrollToBottom(jump: wasFirst);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(scoutHistoryProvider);
    // On iPad / wide screens, bump every Scout text via TextScaler so
    // the chat reads comfortably at arm's-length tablet distance.
    final isWide = MediaQuery.of(context).size.width >= 700;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: isWide
            ? const TextScaler.linear(1.22)
            : MediaQuery.textScalerOf(context),
      ),
      child: TSScaffold(
      style: TSBackgroundStyle.ambient,
      accentColor: TSColors.purple,
      body: SafeArea(
        child: Column(children: [
          // Header — the "study" entry feeling. A lime Pulse + the
          // Scout wordmark. No subtitle; the feel does the explaining.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: ThePulse(size: 8),
                ),
                Text('scout',
                    style: TSTextStyles.heading(
                        size: 22, color: TSColors.lime)),
                const Spacer(),
                // Streak pill — earned at 2+ consecutive days with ≥1
                // Scout message. Drops below the "thinking…" pill
                // when Scout is working, to keep the header tight.
                if (!_thinking) const _ScoutStreakPill(),
                if (!_thinking) const SizedBox(width: 6),
                if (!_thinking) const _SavedTipsPill(),
                if (!_thinking) const SizedBox(width: 6),
                if (!_thinking)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      TSHaptics.light();
                      setState(() {
                        _searchOpen = !_searchOpen;
                        if (!_searchOpen) {
                          _search = '';
                          _searchCtrl.clear();
                          FocusManager.instance.primaryFocus
                              ?.unfocus();
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.search_rounded,
                          color: TSColors.muted, size: 18),
                    ),
                  ),
                if (!_thinking)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      TSHaptics.ctaTap();
                      context.push('/trip/create');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: TSColors.limeDim(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: TSColors.limeDim(0.45)),
                      ),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🗺️',
                                style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text('new trip',
                                style: TSTextStyles.label(
                                    color: TSColors.lime, size: 10)),
                          ]),
                    ),
                  ),
                // "thinking…" pill when Scout's working. Replaces the
                // old subtitle slot so the header never feels dead.
                if (_thinking)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TSColors.limeDim(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TSColors.limeDim(0.4)),
                    ),
                    child: Text('thinking…',
                        style: TSTextStyles.label(
                            color: TSColors.lime, size: 10)),
                  ),
              ],
            ),
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
                      hintText: 'search scout thread…',
                      hintStyle: TSTextStyles.body(
                          size: 14, color: TSColors.muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: TSColors.muted, size: 18),
                  onPressed: () => setState(() {
                    _searchOpen = false;
                    _search = '';
                    _searchCtrl.clear();
                    FocusManager.instance.primaryFocus?.unfocus();
                  }),
                  tooltip: 'close search',
                ),
              ]),
            ),
          Expanded(
            child: Stack(children: [
            history.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: TSColors.lime),
              ),
              error: (e, _) => Center(child: Text(humanizeError(e))),
              data: (rawMsgs) {
                if (rawMsgs.isEmpty) return _EmptyScout(onPrompt: _send);
                final q = _search.toLowerCase();
                final msgs = (!_searchOpen || q.isEmpty)
                    ? rawMsgs
                    : rawMsgs
                        .where((m) => m.content.toLowerCase().contains(q))
                        .toList();
                if (msgs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('no matches for "${_searchCtrl.text}"',
                          style: TSTextStyles.caption(
                              color: TSColors.muted)),
                    ),
                  );
                }
                _maybeAutoScroll(rawMsgs.length);
                final total = msgs.length + (_thinking ? 1 : 0);
                return NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: total,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemBuilder: (_, i) {
                      if (i == msgs.length) return const _ThinkingDots();
                      final prev = i == 0 ? null : msgs[i - 1];
                      final label = _scoutDayChangeLabel(
                          prev?.createdAt, msgs[i].createdAt);
                      final isLastAssistant = !_thinking &&
                          i == msgs.length - 1 &&
                          msgs[i].role == 'assistant';
                      Widget bubble = _ScoutBubble(msg: msgs[i]);
                      if (isLastAssistant) {
                        bubble = Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            bubble,
                            const SizedBox(height: 6),
                            _FollowUpChips(onPick: _send),
                          ],
                        );
                      }
                      if (label == null) return bubble;
                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          _ScoutDateSeparator(label: label),
                          bubble,
                        ],
                      );
                    },
                  ),
                ),
                );
              },
            ),
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
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.arrow_downward_rounded,
                            color: TSColors.bg, size: 14),
                        const SizedBox(width: 4),
                        Text('latest',
                            style: TSTextStyles.label(
                                color: TSColors.bg, size: 10)),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          // Quick prompts + input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => InkWell(
                  onTap: _thinking ? null : () => _send(_quickPrompts[i]),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: TSColors.s2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TSColors.limeDim(0.3)),
                    ),
                    child: Text(_quickPrompts[i], style: TSTextStyles.caption()),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              IconButton(
                tooltip: 'show scout a photo',
                icon: const Icon(Icons.photo_camera_outlined,
                    color: TSColors.lime, size: 22),
                onPressed: _thinking ? null : _attachPhoto,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: TSTextStyles.body(),
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'ask scout anything…',
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
              const SizedBox(width: 8),
              _GradientSend(
                onTap: _thinking ? null : _send,
                disabled: _thinking,
              ),
            ]),
          ),
        ]),
      ),
      ),
    );
  }
}

class _EmptyScout extends ConsumerWidget {
  const _EmptyScout({required this.onPrompt});
  final void Function(String) onPrompt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(scoutGreetingProvider) ??
        'what do you want to know?';
    final daily = scoutDailyQuestion();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 28),
        // Pulse + compass — "the study" entry feeling.
        const Center(child: ThePulse(size: 14, color: TSColors.lime)),
        const SizedBox(height: 20),
        const Center(child: Text('🧭', style: TextStyle(fontSize: 54))),
        const SizedBox(height: 20),

        // Contextual greeting with Scout's lime+purple margin.
        ScoutLine(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(greeting,
                style: TSTextStyles.body(size: 15, color: TSColors.text)),
          ),
        ),
        const SizedBox(height: 28),

        // Daily travel question — taps as a user message.
        InkWell(
          onTap: () => onPrompt(daily),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TSColors.s2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TSColors.border2),
            ),
            child: Row(children: [
              Text('today\'s question · ',
                  style: TSTextStyles.label(
                      color: TSColors.muted, size: 10)),
              Expanded(
                child: Text(daily,
                    style: TSTextStyles.body(size: 13.5)),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: TSColors.lime, size: 16),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        Text('quick prompts',
            style: TSTextStyles.label(
                color: TSColors.muted, size: 10),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _quickPrompts)
              InkWell(
                onTap: () => onPrompt(p),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: TSColors.s2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TSColors.limeDim(0.3)),
                  ),
                  child: Text(p, style: TSTextStyles.body(size: 13)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Per UX redesign §21:
/// - Scout's messages get the vertical purple→lime ScoutLine (margin
///   of presence, not a full bubble).
/// - User messages render right-aligned with a faint lime underline
///   stroke — "the only visual signal of 'this is you'." Removes
///   the iMessage/WhatsApp aesthetic in favour of a more intimate
///   reading layout.
///
/// Long-press on any message copies the text. Reply/react don't
/// apply in a 1-on-1 AI chat, so those gestures are intentionally
/// absent.
class _ScoutBubble extends ConsumerWidget {
  const _ScoutBubble({required this.msg});
  final ScoutMessage msg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = msg.role == 'user';
    final saved = ref
            .watch(savedScoutTipsProvider)
            .valueOrNull
            ?.any((t) => t.content == msg.content) ??
        false;
    final bubble = isMe
        ? _MyMessage(content: msg.content, imageUrl: msg.imageUrl)
        : _ScoutMessage(
            content: msg.content,
            isSaved: saved,
            onToggleSave: () async {
              final willSave =
                  await toggleSavedTip(ref, msg.content);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(willSave ? 'saved 🔖' : 'removed',
                      style: TSTextStyles.body(
                          color: TSColors.bg, size: 13)),
                  backgroundColor: TSColors.lime,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            onShare: () async {
              HapticFeedback.lightImpact();
              Rect? origin;
              try {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null && box.hasSize) {
                  origin = box.localToGlobal(Offset.zero) & box.size;
                }
              } catch (_) {}
              try {
                await Share.share(
                  '${msg.content}\n\n— scout, via tripsquad\n'
                  'get the app → https://gettripsquad.com',
                  subject: 'scout tip',
                  sharePositionOrigin: origin,
                );
              } catch (_) {/* silent */}
            },
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showActions(context, ref, isMe),
      child: bubble,
    );
  }

  Future<void> _showActions(
      BuildContext context, WidgetRef ref, bool isMe) async {
    HapticFeedback.mediumImpact();
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
              _action(
                emoji: '📋',
                label: 'copy',
                color: TSColors.text,
                onTap: () async {
                  Navigator.pop(sheet);
                  await Clipboard.setData(
                      ClipboardData(text: msg.content));
                  HapticFeedback.lightImpact();
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
              if (isMe) ...[
                const SizedBox(height: 8),
                _action(
                  emoji: '🗑️',
                  label: 'delete',
                  color: TSColors.coral,
                  onTap: () async {
                    Navigator.pop(sheet);
                    try {
                      await ref
                          .read(scoutServiceProvider)
                          .deleteMessage(msg.id);
                      ref.invalidate(scoutHistoryProvider);
                    } catch (_) {/* silent */}
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _action({
    required String emoji,
    required String label,
    required Color color,
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
          border: Border.all(
            color: color == TSColors.coral
                ? color.withValues(alpha: 0.4)
                : TSColors.border,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label,
              style: TSTextStyles.body(color: color, size: 14)),
        ]),
      ),
    );
  }
}

class _ScoutMessage extends StatelessWidget {
  const _ScoutMessage({
    required this.content,
    this.isSaved = false,
    this.onToggleSave,
    this.onShare,
  });
  final String content;
  final bool isSaved;
  final VoidCallback? onToggleSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The signature gradient margin — Scout's face.
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
                    const Text('🧭', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text('scout',
                        style: TSTextStyles.label(
                            color: TSColors.lime, size: 10)),
                    const Spacer(),
                    if (onShare != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onShare,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.ios_share_rounded,
                            color: TSColors.muted,
                            size: 15,
                          ),
                        ),
                      ),
                    if (onToggleSave != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggleSave,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isSaved
                                ? TSColors.lime
                                : TSColors.muted,
                            size: 16,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  LinkifiedText(
                      content: content,
                      color: TSColors.text,
                      size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyMessage extends StatelessWidget {
  const _MyMessage({required this.content, this.imageUrl});
  final String content;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openPhotoLightbox(context, imageUrl!),
                  child: Hero(
                    tag: imageUrl!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: 240, maxHeight: 240),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl!,
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
                const SizedBox(height: 6),
              ],
              // Lime-tinted transparent bubble — signals "this is you"
              // without the heavy iMessage-green-block aesthetic.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: TSColors.limeDim(0.10),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: TSColors.limeDim(0.28),
                    width: 1,
                  ),
                ),
                child: LinkifiedText(
                  content: content,
                  color: TSColors.text,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
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
    // Render inside the Scout thread as if it were a message Scout
    // is composing — same ScoutLine gradient margin as _ScoutMessage,
    // so the eye doesn't jump when the dots swap out for the reply.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => Row(
                  children: List.generate(3, (i) {
                    final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: TSColors.lime.withValues(
                              alpha: 0.25 + t * 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientSend extends StatelessWidget {
  const _GradientSend({required this.onTap, required this.disabled});
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
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
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Preview + caption sheet shown after picking a photo in Scout.
/// Returns the caption text (possibly empty) or null on cancel.
class _ScoutImageCaptionSheet extends StatefulWidget {
  const _ScoutImageCaptionSheet({required this.filePath});
  final String filePath;

  @override
  State<_ScoutImageCaptionSheet> createState() =>
      _ScoutImageCaptionSheetState();
}

class _ScoutImageCaptionSheetState
    extends State<_ScoutImageCaptionSheet> {
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
              hintText: 'ask scout about this photo…',
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
                onTap: () => Navigator.of(context).pop(_ctrl.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [TSColors.purple, TSColors.lime],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Text('ask ↑',
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

/// Mirror of the trip-chat / DM date-separator logic. Underscore-
/// scoped so it doesn't collide with the other chat's helper.
String? _scoutDayChangeLabel(DateTime? previous, DateTime? current) {
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

class _ScoutDateSeparator extends StatelessWidget {
  const _ScoutDateSeparator({required this.label});
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

/// Generic follow-up chips rendered below Scout's latest reply.
/// Tap → fires [onPick] with that prompt — same code path as
/// typing it manually. Static for v1; later versions could let
/// Scout propose context-aware follow-ups.
class _FollowUpChips extends StatelessWidget {
  const _FollowUpChips({required this.onPick});
  final void Function(String) onPick;

  static const _prompts = <String>[
    'tell me more',
    'cheaper options?',
    'best time to go?',
    'what about november?',
    'solo-friendly?',
    'hidden gems there?',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 4),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _prompts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              TSHaptics.light();
              onPick(_prompts[i]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TSColors.s2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TSColors.limeDim(0.3)),
              ),
              child: Text(_prompts[i],
                  style: TSTextStyles.caption(color: TSColors.text2)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔖 saved tips pill — hidden when the user hasn't saved
/// anything. Tap opens a sheet of all saved Scout replies.
class _SavedTipsPill extends ConsumerWidget {
  const _SavedTipsPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tips = ref.watch(savedScoutTipsProvider).valueOrNull ??
        const <SavedTip>[];
    if (tips.isEmpty) return const SizedBox();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TSHaptics.light();
        SavedTipsSheet.show(context);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: TSColors.limeDim(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TSColors.limeDim(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔖', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text('${tips.length}',
              style: TSTextStyles.label(
                  color: TSColors.lime, size: 10)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Streak pill — shown in the Scout tab header when the user has
//  messaged Scout on ≥2 consecutive days. Hidden below 2 so it
//  arrives as a reward rather than a zero state.
// ─────────────────────────────────────────────────────────────
class _ScoutStreakPill extends ConsumerWidget {
  const _ScoutStreakPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(scoutStreakProvider).valueOrNull ?? 0;
    if (streak < 2) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TSColors.limeDim(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TSColors.limeDim(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔥', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text('$streak-day streak',
            style: TSTextStyles.label(color: TSColors.lime, size: 10)),
      ]),
    );
  }
}
