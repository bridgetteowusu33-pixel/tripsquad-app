import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/widgets.dart';

/// Realtime squad packing list. Every squad member's tap fans out
/// through the `packing_items` table; everyone sees updates live.
class PackTab extends ConsumerStatefulWidget {
  const PackTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<PackTab> createState() => _PackTabState();
}

class _PackTabState extends ConsumerState<PackTab> {
  static const _categoryOrder = <String>[
    'clothing', 'documents', 'tech', 'toiletries', 'health', 'extras',
  ];

  static const _categoryEmoji = <String, String>{
    'clothing': '👕',
    'documents': '📘',
    'tech': '📱',
    'toiletries': '🧴',
    'health': '💊',
    'extras': '🎒',
  };

  bool _generating = false;
  final Map<String, Map<String, dynamic>> _profileCache = {};

  Future<void> _ensureProfilesLoaded(List<PackingEntry> items) async {
    final ids = <String>{};
    for (final i in items) {
      for (final uid in i.packedBy) {
        if (!_profileCache.containsKey(uid)) ids.add(uid);
      }
    }
    if (ids.isEmpty) return;
    final profiles =
        await ref.read(dmServiceProvider).fetchProfilesByIds(ids.toList());
    if (!mounted) return;
    setState(() => _profileCache.addAll(profiles));
  }

  Future<void> _generate({bool regenerate = false}) async {
    setState(() => _generating = true);
    try {
      // Go through the global provider so the persistent
      // "scout's cooking" banner in TripSpace shows across tab switches.
      await ref
          .read(aIGenerationProvider.notifier)
          .generatePackingList(widget.trip.id, regenerate: regenerate);
      final genState = ref.read(aIGenerationProvider);
      if (genState.status == AIGenStatus.error) {
        throw Exception(genState.errorMessage ?? 'generation failed');
      }
      TSHaptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Seeds a minimal "start from scratch" item so the list renders and
  /// the user can add more items via the existing add-item flow.
  Future<void> _startFromScratch() async {
    try {
      await ref
          .read(packingServiceProvider)
          .addCustomItem(
            tripId: widget.trip.id,
            label: 'passport',
            category: 'essentials',
            emoji: '🛂',
          );
      TSHaptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(packingItemsProvider(widget.trip.id));
    final me = Supabase.instance.client.auth.currentUser?.id;

    return itemsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: TSColors.lime)),
      error: (e, _) => Center(child: Text(humanizeError(e))),
      data: (items) {
        if (items.isEmpty) {
          return _Empty(
            onGenerate: _generate,
            onStartFromScratch: _startFromScratch,
            generating: _generating,
          );
        }

        _ensureProfilesLoaded(items);

        // Group by category and sort category order
        final grouped = <String, List<PackingEntry>>{};
        for (final item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }
        final orderedCategories = [
          ..._categoryOrder.where(grouped.containsKey),
          ...grouped.keys.where((c) => !_categoryOrder.contains(c)),
        ];

        // Progress header stats
        final myPacked =
            items.where((i) => me != null && i.packedBy.contains(me)).length;
        final squadMemberCount = widget.trip.squadMembers.length;
        final totalPacksPossible = items.length *
            (squadMemberCount == 0 ? 1 : squadMemberCount);
        final totalPacksNow =
            items.fold<int>(0, (acc, i) => acc + i.packedBy.length);
        final squadPct = totalPacksPossible == 0
            ? 0.0
            : totalPacksNow / totalPacksPossible;
        final myPct = items.isEmpty ? 0.0 : myPacked / items.length;

        // Scout has helped once at least one item is scout-generated
        // (added_by IS NULL on insert). Hide the "let scout help" pill
        // in that case so the CTA doesn't linger after it's done its job.
        final scoutHasHelped = items.any((i) => i.addedBy == null);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            _ProgressHeader(
              myPacked: myPacked,
              total: items.length,
              myPct: myPct,
              squadPct: squadPct,
              onRegenerate: (scoutHasHelped || _generating)
                  ? null
                  : () => _generate(regenerate: true),
            ),
            const SizedBox(height: 16),
            for (final cat in orderedCategories)
              _CategorySection(
                category: cat,
                emoji: _categoryEmoji[cat] ?? '🎒',
                items: grouped[cat]!,
                tripId: widget.trip.id,
                meUid: me,
                profileCache: _profileCache,
              ),
          ],
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.myPacked,
    required this.total,
    required this.myPct,
    required this.squadPct,
    required this.onRegenerate,
  });
  final int myPacked, total;
  final double myPct, squadPct;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return TSCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🎒', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text('you: $myPacked / $total',
              style: TSTextStyles.heading(size: 18, color: TSColors.lime)),
          const Spacer(),
          if (onRegenerate != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRegenerate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: TSColors.limeDim(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TSColors.limeDim(0.4)),
                ),
                child: Row(children: [
                  const Text('🧭', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text('let scout help',
                      style: TSTextStyles.label(
                          color: TSColors.lime, size: 11)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        TSProgressBar(progress: myPct),
        const SizedBox(height: 12),
        Text('squad progress',
            style: TSTextStyles.caption(color: TSColors.muted)),
        const SizedBox(height: 4),
        TSProgressBar(progress: squadPct),
      ]),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.category,
    required this.emoji,
    required this.items,
    required this.tripId,
    required this.meUid,
    required this.profileCache,
  });
  final String category, emoji, tripId;
  final List<PackingEntry> items;
  final String? meUid;
  final Map<String, Map<String, dynamic>> profileCache;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...items]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(category.toUpperCase(),
              style: TSTextStyles.label(color: TSColors.muted, size: 11)),
        ]),
        const SizedBox(height: 8),
        for (final item in sorted)
          _ItemRow(
            item: item,
            meUid: meUid,
            profileCache: profileCache,
          ).animate().fadeIn(duration: 180.ms),
        _AddItemRow(tripId: tripId, category: category, emoji: emoji),
      ]),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.item,
    required this.meUid,
    required this.profileCache,
  });
  final PackingEntry item;
  final String? meUid;
  final Map<String, Map<String, dynamic>> profileCache;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPackedByMe = meUid != null && item.packedBy.contains(meUid);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        TSHaptics.light();
        await ref.read(packingServiceProvider).togglePacked(item.id);
      },
      onLongPress: () => _showItemOptions(context, ref, item),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TSColors.border)),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: 180.ms,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isPackedByMe ? TSColors.lime : Colors.transparent,
              borderRadius: TSRadius.xs,
              border: Border.all(
                color: isPackedByMe ? TSColors.lime : TSColors.border2,
                width: 1.5,
              ),
            ),
            child: isPackedByMe
                ? const Icon(Icons.check_rounded,
                    color: TSColors.bg, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(children: [
              Flexible(
                child: Text(
                  item.label,
                  style: TSTextStyles.body(
                    size: 14,
                    color: isPackedByMe ? TSColors.muted : TSColors.text,
                  ).copyWith(
                    decoration:
                        isPackedByMe ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Personal items (user-added) show a subtle lock so the
              // owner knows it's private — squad members never see
              // these rows at all thanks to RLS, but in the owner's
              // view the distinction from shared items is useful.
              if (item.addedBy != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.lock_outline_rounded,
                    size: 11, color: TSColors.muted2),
              ],
            ]),
          ),
          // Only show the "who packed" avatars for shared items; for
          // personal items it's always just the owner, no point.
          if (item.addedBy == null)
            _AvatarStack(userIds: item.packedBy, profileCache: profileCache),
        ]),
      ),
    );
  }

  void _showItemOptions(BuildContext context, WidgetRef ref, PackingEntry item) {
    TSHaptics.medium();
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
            const SizedBox(height: 20),
            Text(item.label, style: TSTextStyles.heading(size: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🗑️', style: TextStyle(fontSize: 20)),
              title: Text('remove item',
                  style: TSTextStyles.body(color: TSColors.coral)),
              onTap: () async {
                Navigator.pop(sheet);
                await ref.read(packingServiceProvider).deleteItem(item.id);
                TSHaptics.medium();
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.userIds, required this.profileCache});
  final List<String> userIds;
  final Map<String, Map<String, dynamic>> profileCache;

  @override
  Widget build(BuildContext context) {
    if (userIds.isEmpty) return const SizedBox();
    final shown = userIds.take(3).toList();
    return SizedBox(
      height: 22,
      width: 22.0 + (shown.length - 1) * 14,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  shape: BoxShape.circle,
                  border: Border.all(color: TSColors.bg, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  (profileCache[shown[i]]?['emoji'] as String?) ?? '😎',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          if (userIds.length > shown.length)
            Positioned(
              left: shown.length * 14.0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  shape: BoxShape.circle,
                  border: Border.all(color: TSColors.bg, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+${userIds.length - shown.length}',
                  style: TSTextStyles.label(color: TSColors.lime, size: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddItemRow extends ConsumerStatefulWidget {
  const _AddItemRow({
    required this.tripId,
    required this.category,
    required this.emoji,
  });
  final String tripId, category, emoji;

  @override
  ConsumerState<_AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends ConsumerState<_AddItemRow> {
  final _ctrl = TextEditingController();
  bool _active = false;
  bool _saving = false;

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _active = false);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(packingServiceProvider).addCustomItem(
            tripId: widget.tripId,
            label: text,
            category: widget.category,
            emoji: widget.emoji,
          );
      _ctrl.clear();
      TSHaptics.light();
    } finally {
      if (mounted) setState(() {
        _saving = false;
        _active = false;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _active = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            const Icon(Icons.add_rounded, size: 18, color: TSColors.muted),
            const SizedBox(width: 10),
            Text('add item',
                style: TSTextStyles.caption(color: TSColors.muted)),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Icon(Icons.add_rounded, size: 18, color: TSColors.lime),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            style: TSTextStyles.body(size: 14),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'what else?',
            ),
            onSubmitted: (_) => _save(),
          ),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text('add',
              style: TSTextStyles.label(color: TSColors.lime, size: 12)),
        ),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.onGenerate,
    required this.onStartFromScratch,
    required this.generating,
  });
  final VoidCallback onGenerate;
  final VoidCallback onStartFromScratch;
  final bool generating;

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return const TSScoutLoading(
        messages: TSScoutLoading.packingMessages,
        subtitle: 'scout is building your packing list',
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('no packing list yet',
              style: TSTextStyles.heading(size: 20)),
          const SizedBox(height: 8),
          Text('how do you want to start?',
              style: TSTextStyles.body(color: TSColors.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TSButton(
            label: 'generate with scout 🧭',
            onTap: onGenerate,
          ),
          const SizedBox(height: 10),
          TSButton(
            label: 'start my own list ✍️',
            variant: TSButtonVariant.outline,
            onTap: onStartFromScratch,
          ),
        ]),
      ),
    );
  }
}
