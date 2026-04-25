import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

/// Lists users the current user has blocked. Each row has an
/// "unblock" button. Soft-block semantics: blocked users can't
/// DM you and are hidden from search + each other's profile.
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() =>
      _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blocks = [];
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
      final rows =
          await ref.read(blockServiceProvider).fetchMyBlocks();
      if (!mounted) return;
      setState(() {
        _blocks = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = humanizeError(e);
        _loading = false;
      });
    }
  }

  Future<void> _unblock(Map<String, dynamic> row) async {
    final userId = row['user_id'] as String?;
    if (userId == null) return;
    TSHaptics.medium();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TSColors.s2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('unblock @${row['tag'] ?? 'user'}?',
            style: TSTextStyles.heading(size: 17)),
        content: Text(
          'they\'ll be able to find you in search and send you DMs again.',
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
            child: Text('unblock',
                style: TSTextStyles.title(color: TSColors.lime)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(blockServiceProvider).unblock(userId);
      if (!mounted) return;
      setState(() {
        _blocks.removeWhere((r) => r['user_id'] == userId);
      });
      TSHaptics.success();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: const TSAppBar(title: 'blocked users'),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: TSColors.lime));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: TSTextStyles.body(color: TSColors.muted)),
      );
    }
    if (_blocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌿', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('no blocks — your space is clear',
                  style: TSTextStyles.heading(size: 18)),
              const SizedBox(height: 6),
              Text(
                'when you block someone, they stop seeing you in search\nand can\'t message you.',
                textAlign: TextAlign.center,
                style: TSTextStyles.body(
                    size: 13, color: TSColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _blocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _BlockRow(
        row: _blocks[i],
        onUnblock: () => _unblock(_blocks[i]),
        onTap: () {
          final uid = _blocks[i]['user_id'] as String?;
          if (uid != null) context.push('/user/$uid');
        },
      ),
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({
    required this.row,
    required this.onUnblock,
    required this.onTap,
  });
  final Map<String, dynamic> row;
  final VoidCallback onUnblock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nickname = (row['nickname'] as String?) ?? 'Traveller';
    final tag = row['tag'] as String?;
    final emoji = (row['emoji'] as String?) ?? '😎';
    final avatar = row['avatar_url'] as String?;
    return TSCard(
      onTap: onTap,
      child: Row(children: [
        TSAvatar(emoji: emoji, photoUrl: avatar, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nickname, style: TSTextStyles.body(size: 15)),
              if (tag != null)
                Text('@$tag',
                    style:
                        TSTextStyles.caption(color: TSColors.muted)),
            ],
          ),
        ),
        TextButton(
          onPressed: onUnblock,
          style: TextButton.styleFrom(
            backgroundColor: TSColors.s2,
            foregroundColor: TSColors.lime,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
          ),
          child: Text('unblock',
              style: TSTextStyles.title(
                  size: 13, color: TSColors.lime)),
        ),
      ]),
    );
  }
}
