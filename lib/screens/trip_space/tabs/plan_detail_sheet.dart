import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/widgets.dart';

/// Full detail view for an itinerary activity: photo, metadata, squad notes,
/// edit fields, booking CTA, delete action.
class PlanDetailSheet extends ConsumerStatefulWidget {
  const PlanDetailSheet({super.key, required this.activity, required this.trip});
  final ItineraryActivity activity;
  final Trip trip;

  @override
  ConsumerState<PlanDetailSheet> createState() => _PlanDetailSheetState();
}

class _PlanDetailSheetState extends ConsumerState<PlanDetailSheet> {
  late final TextEditingController _noteCtrl;
  bool _sendingNote = false;
  Map<String, Map<String, dynamic>> _profileCache = {};

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles(List<ItineraryNote> notes) async {
    final ids = notes.map((n) => n.userId).toSet().toList();
    final missing = ids.where((id) => !_profileCache.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final profiles =
        await ref.read(dmServiceProvider).fetchProfilesByIds(missing);
    if (!mounted) return;
    setState(() => _profileCache = {..._profileCache, ...profiles});
  }

  Future<void> _sendNote() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingNote = true);
    try {
      await ref.read(itineraryServiceProvider).addNote(
            itemId: widget.activity.id,
            content: text,
          );
      _noteCtrl.clear();
      TSHaptics.light();
    } finally {
      if (mounted) setState(() => _sendingNote = false);
    }
  }

  Future<void> _toggleBooked() async {
    final booked = widget.activity.bookedAt == null;
    await ref
        .read(itineraryServiceProvider)
        .markBooked(widget.activity.id, booked);
    TSHaptics.success();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: TSColors.s2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('remove activity?',
            style: TSTextStyles.heading(size: 18)),
        content: Text(
          '${widget.activity.title} will be removed from the trip.',
          style: TSTextStyles.body(color: TSColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc, false),
            child: Text('cancel',
                style: TSTextStyles.title(color: TSColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dc, true),
            child: Text('remove',
                style: TSTextStyles.title(color: TSColors.coral)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(itineraryServiceProvider).deleteActivity(widget.activity.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final notesAsync = ref.watch(itineraryNotesStreamProvider(a.id));
    final me = Supabase.instance.client.auth.currentUser?.id;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scroll) => GestureDetector(
        // Tap anywhere in the sheet that isn't the composer to
        // dismiss the keyboard — previously you could only lose
        // focus via the system keyboard's "done" button.
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
          // Lift content above the keyboard so the composer stays
          // visible when focused.
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: TSColors.border2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (a.imageUrl != null)
                ClipRRect(
                  borderRadius: TSRadius.md,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: a.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: TSColors.s2),
                      errorWidget: (_, __, ___) =>
                          Container(color: TSColors.s2),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Row(children: [
                TSPill('Day ${a.dayNumber}',
                    variant: TSPillVariant.lime, small: true),
                const SizedBox(width: 8),
                Text(a.timeOfDay,
                    style: TSTextStyles.caption(color: TSColors.muted)),
              ]),
              const SizedBox(height: 8),
              Text(a.title, style: TSTextStyles.heading(size: 22)),
              if (a.description != null) ...[
                const SizedBox(height: 8),
                Text(a.description!,
                    style: TSTextStyles.body(color: TSColors.text2)),
              ],
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (a.location != null)
                  _DetailChip(icon: '📍', text: a.location!),
                if (a.estimatedCostCents != null)
                  _DetailChip(
                      icon: '💸',
                      text:
                          '\$${(a.estimatedCostCents! / 100).toStringAsFixed(0)} /pp'),
                if (a.bookingUrl != null)
                  _DetailChip(icon: '🔗', text: 'booking link'),
              ]),
              const SizedBox(height: 20),
              if (a.bookingUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: TSButton(
                    label: a.bookedAt != null ? 'unmark booked' : 'book now →',
                    onTap: () async {
                      if (a.bookedAt != null) {
                        await _toggleBooked();
                      } else {
                        await launchUrl(Uri.parse(a.bookingUrl!),
                            mode: LaunchMode.externalApplication);
                        await _toggleBooked();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: TSButton(
                    label: a.bookedAt != null
                        ? '✓ booked'
                        : 'mark as booked',
                    variant: a.bookedAt != null
                        ? TSButtonVariant.outline
                        : TSButtonVariant.primary,
                    onTap: _toggleBooked,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('squad notes',
                  style: TSTextStyles.label(color: TSColors.muted)),
              const SizedBox(height: 10),
              notesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(color: TSColors.lime),
                ),
                error: (e, _) => Text(humanizeError(e),
                    style: TSTextStyles.caption(color: TSColors.coral)),
                data: (notes) {
                  _loadProfiles(notes);
                  if (notes.isEmpty) {
                    return Text(
                      'no notes yet. add the first one below.',
                      style: TSTextStyles.caption(color: TSColors.muted),
                    );
                  }
                  return Column(
                    children: [
                      for (final n in notes)
                        _NoteRow(
                          note: n,
                          profile: _profileCache[n.userId],
                          canDelete: n.userId == me,
                          onDelete: () => ref
                              .read(itineraryServiceProvider)
                              .deleteNote(n.id),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    style: TSTextStyles.body(),
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'add a note for the squad…',
                      hintStyle: TSTextStyles.body(color: TSColors.muted),
                      filled: true,
                      fillColor: TSColors.s2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded,
                      color: _sendingNote ? TSColors.muted : TSColors.lime),
                  onPressed: _sendingNote ? null : _sendNote,
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TSButton(
                  label: 'remove activity',
                  variant: TSButtonVariant.outline,
                  onTap: _delete,
                ),
              ),
            ],
          ),
        ),
      ]),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});
  final String icon, text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(text, style: TSTextStyles.caption(color: TSColors.text)),
      ]),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.note,
    required this.profile,
    required this.canDelete,
    required this.onDelete,
  });
  final ItineraryNote note;
  final Map<String, dynamic>? profile;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((profile?['emoji'] as String?) ?? '😎',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((profile?['nickname'] as String?) ?? 'someone',
                        style: TSTextStyles.caption(color: TSColors.muted)),
                    const SizedBox(height: 2),
                    Text(note.content, style: TSTextStyles.body(size: 14)),
                  ]),
            ),
            if (canDelete)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: TSColors.muted),
                onPressed: onDelete,
              ),
          ]),
    );
  }
}
