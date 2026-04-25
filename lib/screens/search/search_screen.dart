import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../services/supabase_service.dart';
import '../../widgets/tappable.dart';
import '../../widgets/widgets.dart';

/// Universal tag / name search. Tap a result → opens the public profile.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Autofocus the input as soon as the screen opens.
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
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(q));
  }

  Future<void> _run(String q) async {
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final data = await ref.read(tripServiceProvider).searchByTag(q.trim());
      if (!mounted) return;
      setState(() {
        _results = data;
        _searching = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = humanizeError(e);
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: const TSAppBar(title: 'search'),
      body: SafeArea(
        child: Column(children: [
          // Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: TSTextStyles.body(),
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'find by @tag or name',
                hintStyle: TSTextStyles.body(color: TSColors.muted),
                prefixIcon: const Icon(Icons.search, color: TSColors.muted),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: TSColors.muted),
                        onPressed: () {
                          _ctrl.clear();
                          _onChanged('');
                        },
                      ),
                filled: true,
                fillColor: TSColors.s2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildResults()),
        ]),
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: TSTextStyles.body(color: TSColors.coral)),
      );
    }
    if (_searching && _results.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: TSColors.lime));
    }
    if (_ctrl.text.trim().length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔎', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text('find travellers',
                style: TSTextStyles.heading(size: 18)),
            const SizedBox(height: 6),
            Text('type at least 2 letters of a @tag or name',
                style: TSTextStyles.body(color: TSColors.muted),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🤷', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text('no one with that tag yet',
                style: TSTextStyles.body(color: TSColors.muted)),
          ]),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          const Divider(color: TSColors.border, height: 1),
      itemBuilder: (_, i) => _ResultRow(profile: _results[i]),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final emoji = (profile['emoji'] as String?) ?? '😎';
    final nickname = (profile['nickname'] as String?) ?? 'someone';
    final tag = profile['tag'] as String?;
    final style = profile['travel_style'] as String?;
    final photoUrl = profile['avatar_url'] as String?;
    return TSTappable(
      onTap: () {
        TSHaptics.light();
        context.push('/user/${profile['id']}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(children: [
          TSAvatar(emoji: emoji, photoUrl: photoUrl, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(nickname,
                        style: TSTextStyles.body(weight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    if (tag != null)
                      Text('@$tag',
                          style:
                              TSTextStyles.caption(color: TSColors.lime)),
                  ]),
                  if (style != null) ...[
                    const SizedBox(height: 2),
                    Text(style,
                        style: TSTextStyles.caption(color: TSColors.muted)),
                  ],
                ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.muted, size: 14),
        ]),
      ),
    );
  }
}
