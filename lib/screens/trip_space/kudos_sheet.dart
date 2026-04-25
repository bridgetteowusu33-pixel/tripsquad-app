import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

/// Post-trip kudos flow. You tap through each squad member and
/// multi-select the kudos chips that describe them. Positive-only.
/// Kind IDs persist so switching back to a member pre-selects what
/// you already gave them.
class KudosSheet extends ConsumerStatefulWidget {
  const KudosSheet({super.key, required this.trip});
  final Trip trip;

  static Future<void> show(BuildContext context, Trip trip) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => KudosSheet(trip: trip),
    );
  }

  @override
  ConsumerState<KudosSheet> createState() => _KudosSheetState();
}

class _KudosSheetState extends ConsumerState<KudosSheet> {
  int _index = 0;
  Set<String> _selected = {};
  bool _loadingMember = false;
  bool _saving = false;
  Map<String, String?> _avatarByUid = {};

  List<SquadMember> get _others {
    final me = Supabase.instance.client.auth.currentUser?.id;
    return widget.trip.squadMembers
        .where((m) => m.userId != null && m.userId != me)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    final uids = _others
        .map((m) => m.userId)
        .whereType<String>()
        .toList();
    if (uids.isEmpty) return;
    final profiles =
        await ref.read(dmServiceProvider).fetchProfilesByIds(uids);
    if (!mounted) return;
    setState(() {
      for (final e in profiles.entries) {
        _avatarByUid[e.key] = e.value['avatar_url'] as String?;
      }
    });
  }

  Future<void> _loadCurrentSelection() async {
    if (_others.isEmpty) return;
    setState(() => _loadingMember = true);
    final me = _others[_index];
    final current = await ref.read(ratingsServiceProvider).myKudosFor(
          tripId: widget.trip.id,
          toUser: me.userId!,
        );
    if (!mounted) return;
    setState(() {
      _selected = current;
      _loadingMember = false;
    });
  }

  Future<void> _toggle(String kind) async {
    final member = _others[_index];
    TSHaptics.selection();
    final willAdd = !_selected.contains(kind);
    setState(() {
      if (willAdd) {
        _selected.add(kind);
      } else {
        _selected.remove(kind);
      }
    });
    try {
      if (willAdd) {
        await ref.read(ratingsServiceProvider).giveKudos(
              tripId: widget.trip.id,
              toUser: member.userId!,
              kind: kind,
            );
      } else {
        await ref.read(ratingsServiceProvider).removeKudos(
              tripId: widget.trip.id,
              toUser: member.userId!,
              kind: kind,
            );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          if (willAdd) {
            _selected.remove(kind);
          } else {
            _selected.add(kind);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }

  Future<void> _next() async {
    if (_index < _others.length - 1) {
      setState(() {
        _index++;
        _selected = {};
      });
      _loadCurrentSelection();
    } else {
      TSHaptics.success();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final others = _others;
    if (others.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TSColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🏆', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('no squad to kudos',
                style: TSTextStyles.heading(size: 18)),
            const SizedBox(height: 6),
            Text('only app-registered members can receive kudos.',
                style: TSTextStyles.caption(color: TSColors.muted),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    final member = others[_index];
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: TSColors.border2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        // Progress dots
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < others.length; i++) ...[
            Container(
              width: i == _index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i <= _index ? TSColors.lime : TSColors.s3,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (i < others.length - 1) const SizedBox(width: 4),
          ],
        ]),
        const SizedBox(height: 20),
        Text('how was it with',
            style: TSTextStyles.caption(color: TSColors.muted)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TSAvatar(
            emoji: member.emoji ?? '😎',
            photoUrl: member.userId == null
                ? null
                : _avatarByUid[member.userId!],
            size: 36,
          ),
          const SizedBox(width: 10),
          Text(member.nickname,
              style: TSTextStyles.heading(size: 22, color: TSColors.lime)),
          const Text(' ?', style: TextStyle(fontSize: 22, color: TSColors.text)),
        ]),
        const SizedBox(height: 4),
        Text('tap all that apply · positive only',
            style: TSTextStyles.caption(color: TSColors.muted)),
        const SizedBox(height: 18),
        if (_loadingMember)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: CircularProgressIndicator(color: TSColors.lime),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final k in kKudosKinds)
                _KudosChip(
                  emoji: k.emoji,
                  label: k.label,
                  selected: _selected.contains(k.kind),
                  onTap: () => _toggle(k.kind),
                ),
            ],
          ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: TSButton(
              label: _index == others.length - 1 ? 'done ✦' : 'next →',
              onTap: _saving ? () {} : _next,
              loading: _saving,
            ),
          ),
        ]),
        if (_index < others.length - 1) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text('finish later',
                style: TSTextStyles.caption(color: TSColors.muted)),
          ),
        ],
      ]),
    );
  }
}

class _KudosChip extends StatelessWidget {
  const _KudosChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? TSColors.limeDim(0.15) : TSColors.s2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? TSColors.lime : TSColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(label,
              style: TSTextStyles.body(
                size: 13,
                color: selected ? TSColors.lime : TSColors.text,
              )),
        ]),
      ),
    );
  }
}
