import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors.dart';
import '../core/responsive.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart';
import 'widgets.dart';

// ─────────────────────────────────────────────────────────────
//  ADD BY @TAG — bottom sheet
//
//  Host searches for a user by tag/name, taps a result, and
//  that user is added to the squad with status=invited. The
//  user sees the trip in their Trips tab immediately thanks to
//  the existing realtime fan-out.
// ─────────────────────────────────────────────────────────────

class AddByTagSheet extends ConsumerStatefulWidget {
  const AddByTagSheet({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.existingUserIds,
  });

  final String tripId;
  final String tripName;
  final Set<String> existingUserIds;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required String tripName,
    required Set<String> existingUserIds,
  }) {
    return showModalBottomSheet(
      context: context,
      constraints: TSResponsive.modalConstraints,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddByTagSheet(
        tripId: tripId,
        tripName: tripName,
        existingUserIds: existingUserIds,
      ),
    );
  }

  @override
  ConsumerState<AddByTagSheet> createState() => _AddByTagSheetState();
}

class _AddByTagSheetState extends ConsumerState<AddByTagSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = const [];
  bool _searching = false;
  String _addingId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(q));
  }

  Future<void> _search(String q) async {
    final clean = q.trim().replaceAll('@', '');
    if (clean.length < 2) {
      if (mounted) setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final rows = await ref.read(tripServiceProvider).searchByTag(clean);
      if (!mounted) return;
      setState(() {
        _results = rows;
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _add(Map<String, dynamic> profile) async {
    final userId = profile['id'] as String?;
    if (userId == null) return;
    if (widget.existingUserIds.contains(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('already in the squad',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _addingId = userId);
    TSHaptics.ctaCommit();
    try {
      await ref.read(tripServiceProvider).addMemberByTag(
            tripId: widget.tripId,
            userId: userId,
            nickname: (profile['nickname'] as String?) ??
                (profile['tag'] as String?) ??
                'friend',
            emoji: (profile['emoji'] as String?) ?? '😎',
          );
      // addMemberByTag already inserts an 'invited_to_trip'
      // notification that deep-links into the trip.
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'added ${(profile['nickname'] as String?) ?? 'them'} to the squad',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _addingId = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t add — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: TSColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('add by @tag', style: TSTextStyles.heading(size: 20)),
          const SizedBox(height: 4),
          Text(
            'find your friend on TripSquad and add them straight in',
            style: TSTextStyles.caption(color: TSColors.muted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            onChanged: _onChanged,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            style: TSTextStyles.body(),
            decoration: InputDecoration(
              prefixText: '@',
              prefixStyle: TSTextStyles.body(color: TSColors.lime),
              hintText: 'search by tag or name',
              hintStyle: TSTextStyles.body(color: TSColors.muted),
              filled: true,
              fillColor: TSColors.s2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: _body(),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_searching) {
      return const Center(
          child: CircularProgressIndicator(color: TSColors.lime));
    }
    if (_ctrl.text.trim().length < 2) {
      return Center(
        child: Text('type at least 2 characters',
            style: TSTextStyles.caption(color: TSColors.muted)),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text('no matches for "${_ctrl.text}"',
            style: TSTextStyles.caption(color: TSColors.muted)),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final p = _results[i];
        final id = p['id'] as String? ?? '';
        final already = widget.existingUserIds.contains(id);
        final busy = _addingId == id;
        return _Row(
          nickname: (p['nickname'] as String?) ?? 'friend',
          tag: (p['tag'] as String?),
          emoji: (p['emoji'] as String?) ?? '😎',
          photoUrl: p['avatar_url'] as String?,
          already: already,
          busy: busy,
          onAdd: () => _add(p),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.nickname,
    required this.tag,
    required this.emoji,
    required this.photoUrl,
    required this.already,
    required this.busy,
    required this.onAdd,
  });

  final String nickname;
  final String? tag;
  final String emoji;
  final String? photoUrl;
  final bool already;
  final bool busy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        TSAvatar(emoji: emoji, photoUrl: photoUrl, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nickname, style: TSTextStyles.body()),
              if (tag != null && tag!.isNotEmpty)
                Text('@$tag',
                    style: TSTextStyles.caption(color: TSColors.muted)),
            ],
          ),
        ),
        if (already)
          Text('in squad',
              style: TSTextStyles.caption(color: TSColors.muted))
        else if (busy)
          const SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: TSColors.lime),
          )
        else
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: TSColors.limeDim(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TSColors.limeDim(0.5)),
              ),
              child: Text('add',
                  style:
                      TSTextStyles.label(color: TSColors.lime, size: 11)),
            ),
          ),
      ]),
    );
  }
}
