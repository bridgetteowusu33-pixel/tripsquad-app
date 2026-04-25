import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

/// Detail page for a canonical Place. Shows aggregate ratings, squad
/// recaps that mention the place, and an "add to next trip" action.
class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});
  final String placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() =>
      _PlaceDetailScreenState();
}

class _PlaceRatingRow extends ConsumerStatefulWidget {
  const _PlaceRatingRow({required this.placeId, required this.onRated});
  final String placeId;
  final Future<void> Function() onRated;

  @override
  ConsumerState<_PlaceRatingRow> createState() => _PlaceRatingRowState();
}

class _PlaceRatingRowState extends ConsumerState<_PlaceRatingRow> {
  final _noteCtrl = TextEditingController();
  int? _myThumb;
  bool _loading = true;
  bool _savingNote = false;
  bool _showNote = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final thumb = await ref
          .read(ratingsServiceProvider)
          .myPlaceThumb(widget.placeId);
      // Also pull my existing note if any
      final uid = Supabase.instance.client.auth.currentUser?.id;
      String? note;
      if (uid != null) {
        final row = await Supabase.instance.client
            .from('place_ratings')
            .select('note')
            .eq('place_id', widget.placeId)
            .eq('user_id', uid)
            .maybeSingle();
        note = row?['note'] as String?;
      }
      if (!mounted) return;
      setState(() {
        _myThumb = thumb;
        _noteCtrl.text = note ?? '';
        _showNote = (note != null && note.isNotEmpty);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _tap(int thumb) async {
    TSHaptics.selection();
    final wasMine = _myThumb;
    setState(() {
      _myThumb = wasMine == thumb ? null : thumb;
      _showNote = _myThumb != null;
    });
    try {
      if (_myThumb == null) {
        await ref
            .read(ratingsServiceProvider)
            .removePlaceRating(widget.placeId);
        _noteCtrl.clear();
      } else {
        await ref.read(ratingsServiceProvider).ratePlace(
              placeId: widget.placeId,
              thumb: _myThumb!,
              note: _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim(),
            );
      }
      await widget.onRated();
    } catch (e) {
      if (mounted) {
        setState(() => _myThumb = wasMine);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_myThumb == null) return;
    setState(() => _savingNote = true);
    try {
      await ref.read(ratingsServiceProvider).ratePlace(
            placeId: widget.placeId,
            thumb: _myThumb!,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      FocusManager.instance.primaryFocus?.unfocus();
      await widget.onRated();
      TSHaptics.light();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 42);
    return TSCard(
      child: Column(children: [
        Row(children: [
          const Text('been here?',
              style: TextStyle(fontSize: 14, color: TSColors.text)),
          const Spacer(),
          _thumb(1),
          const SizedBox(width: 8),
          _thumb(-1),
        ]),
        if (_myThumb != null) ...[
          const SizedBox(height: 10),
          if (_showNote)
            Column(children: [
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                maxLength: 240,
                style: TSTextStyles.body(size: 13),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'add a comment (optional)',
                  hintStyle: TSTextStyles.body(color: TSColors.muted, size: 13),
                  filled: true,
                  fillColor: TSColors.s2,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Spacer(),
                TextButton(
                  onPressed: _savingNote ? null : _saveNote,
                  child: Text(_savingNote ? 'saving…' : 'save comment',
                      style: TSTextStyles.label(color: TSColors.lime, size: 12)),
                ),
              ]),
            ])
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showNote = true),
                icon: const Icon(Icons.edit_rounded,
                    size: 13, color: TSColors.muted),
                label: Text('add a comment',
                    style: TSTextStyles.caption(color: TSColors.muted)),
              ),
            ),
        ],
      ]),
    );
  }

  Widget _thumb(int thumb) {
    final selected = _myThumb == thumb;
    final color = thumb == 1 ? TSColors.lime : TSColors.coral;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tap(thumb),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : TSColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(thumb == 1 ? '👍' : '👎',
            style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _RatingCommentRow extends StatelessWidget {
  const _RatingCommentRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final thumb = (row['thumb'] as int?) ?? 1;
    final note = row['note'] as String?;
    final nickname = (row['user_nickname'] as String?) ?? 'someone';
    final emoji = (row['user_emoji'] as String?) ?? '😎';
    final photoUrl = row['user_avatar_url'] as String?;
    // Skip rows with no comment — they're just thumb votes, already in stats
    if (note == null || note.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TSAvatar(emoji: emoji, photoUrl: photoUrl, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(nickname,
                          style: TSTextStyles.body(
                              size: 13, weight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text(thumb == 1 ? '👍' : '👎',
                          style: const TextStyle(fontSize: 12)),
                    ]),
                    const SizedBox(height: 2),
                    Text(note, style: TSTextStyles.body(size: 13)),
                  ]),
            ),
          ]),
    );
  }
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  PlaceStats? _stats;
  Place? _place;
  List<Map<String, dynamic>> _recaps = [];
  List<Map<String, dynamic>> _ratingsFeed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(placesServiceProvider);
    try {
      final stats = await svc.fetchPlace(widget.placeId);
      final raw = await Supabase.instance.client.from('places').select()
          .eq('id', widget.placeId).maybeSingle();
      final place = raw == null ? null : Place.fromJson(snakeToCamel(raw));
      final recaps = await svc.fetchPlaceRecaps(widget.placeId);
      final ratingsFeed = await svc.fetchPlaceRatingsFeed(widget.placeId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _place = place;
        _recaps = recaps;
        _ratingsFeed = ratingsFeed;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToNextTrip() async {
    if (_place == null) return;
    TSHaptics.light();
    final trips = await ref.read(tripServiceProvider).fetchMyTrips();
    final eligible = trips
        .where((t) =>
            t.status != TripStatus.completed &&
            t.selectedDestination != null &&
            t.selectedDestination!.toLowerCase().trim() ==
                _place!.destination.toLowerCase().trim())
        .toList();
    if (!mounted) return;
    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'no active trip to ${_place!.destination} — create one first'),
        ),
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
            Text('add to which trip?',
                style: TSTextStyles.heading(size: 18)),
            const SizedBox(height: 8),
            ...eligible.map((t) => ListTile(
                  leading: Text(t.selectedFlag ?? '✈️',
                      style: const TextStyle(fontSize: 20)),
                  title: Text(t.name, style: TSTextStyles.body()),
                  onTap: () async {
                    Navigator.pop(sheet);
                    try {
                      await ref.read(placesServiceProvider).addToNextTrip(
                            place: _place!,
                            targetTripId: t.id,
                          );
                      TSHaptics.success();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('added to ${t.name} ✦',
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
                  },
                )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: TSAppBar(
        title: _place?.name,
        subtitle: _place?.destination,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: TSColors.lime))
          : _place == null
              ? const Center(child: Text('place not found'))
              : SafeArea(child: _body()),
    );
  }

  Widget _body() {
    final stats = _stats;
    final place = _place!;
    final categoryEmoji = place.category == 'hotel'
        ? '🛏️'
        : place.category == 'restaurant'
            ? '🍽️'
            : '📍';
    final photo = stats?.displayPhoto ?? place.photoUrl;
    return ListView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
      if (photo != null)
        ClipRRect(
          borderRadius: TSRadius.md,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: photo,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: TSColors.s2),
              errorWidget: (_, __, ___) => Container(color: TSColors.s2),
            ),
          ),
        )
      else
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: TSColors.s2,
            borderRadius: TSRadius.md,
          ),
          alignment: Alignment.center,
          child: Text(categoryEmoji, style: const TextStyle(fontSize: 56)),
        ),
      const SizedBox(height: 16),
      Row(children: [
        Text('$categoryEmoji ${place.category.toUpperCase()}',
            style: TSTextStyles.label(color: TSColors.lime, size: 11)),
        const SizedBox(width: 10),
        if (place.flag != null)
          Text('${place.flag} ${place.destination}',
              style: TSTextStyles.caption(color: TSColors.muted)),
      ]),
      const SizedBox(height: 8),
      Text(place.name, style: TSTextStyles.heading(size: 22)),
      const SizedBox(height: 12),
      if (stats != null && stats.ratingCount > 0) ...[
        TSCard(
          borderColor: TSColors.limeDim(0.2),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${stats.approvalPct}% 👍',
                    style: TSTextStyles.heading(
                        size: 24, color: TSColors.lime)),
                Text(
                    '${stats.ratingCount} rating${stats.ratingCount == 1 ? '' : 's'} · ${stats.squadsCount} squad${stats.squadsCount == 1 ? '' : 's'}',
                    style: TSTextStyles.caption()),
                if (stats.ratingCount >= 3) ...[
                  const SizedBox(height: 6),
                  Text('✓ verified by real squads',
                      style: TSTextStyles.caption(color: TSColors.lime)),
                ],
              ]),
            ),
            Column(children: [
              Row(children: [
                const Text('👍', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('${stats.upCount}',
                    style: TSTextStyles.body()),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Text('👎', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('${stats.downCount}',
                    style: TSTextStyles.body()),
              ]),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
      ],
      // "Have you been here?" direct rating
      _PlaceRatingRow(placeId: place.id, onRated: _load),
      const SizedBox(height: 14),
      TSButton(
        label: '➕ add to next trip',
        onTap: _addToNextTrip,
      ),
      const SizedBox(height: 10),
      TSButton(
        label: '${place.flag ?? '🌍'} more in ${place.destination} →',
        variant: TSButtonVariant.outline,
        onTap: () {
          TSHaptics.light();
          final slug = Uri.encodeComponent(place.destination);
          context.push('/destination/$slug');
        },
      ),
      if (_ratingsFeed.isNotEmpty) ...[
        const SizedBox(height: 24),
        const SectionLabel(label: 'ratings + comments'),
        const SizedBox(height: 10),
        for (final r in _ratingsFeed)
          _RatingCommentRow(row: r),
      ],
      if (_recaps.isNotEmpty) ...[
        const SizedBox(height: 24),
        const SectionLabel(label: 'squad recaps mentioning this'),
        const SizedBox(height: 10),
        for (final r in _recaps)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TSCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('⭐' * ((r['stars'] as int?) ?? 0),
                          style: const TextStyle(fontSize: 13)),
                      if (r['would_return'] == 'yes') ...[
                        const SizedBox(width: 8),
                        Text('would return ✨',
                            style:
                                TSTextStyles.caption(color: TSColors.lime)),
                      ],
                    ]),
                    if ((r['best_part'] as String?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text('"${r['best_part']}"',
                          style: TSTextStyles.body(size: 13)),
                    ],
                  ]),
            ),
          ),
      ],
    ]);
  }
}
