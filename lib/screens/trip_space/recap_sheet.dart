import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

/// One-screen post-trip recap. Stars 1-5, would-return yes/no/maybe,
/// best part free-text. Writes to `destination_recaps` and auto-bumps
/// the user's trips_completed count.
class RecapSheet extends ConsumerStatefulWidget {
  const RecapSheet({super.key, required this.trip});
  final Trip trip;

  static Future<void> show(BuildContext context, Trip trip) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RecapSheet(trip: trip),
    );
  }

  @override
  ConsumerState<RecapSheet> createState() => _RecapSheetState();
}

class _RecapSheetState extends ConsumerState<RecapSheet> {
  final _bestPart = TextEditingController();
  int _stars = 0;
  String? _wouldReturn; // yes | no | maybe
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final existing = await ref
          .read(ratingsServiceProvider)
          .myRecap(widget.trip.id);
      if (!mounted) return;
      if (existing != null) {
        _stars = existing.stars;
        _wouldReturn = existing.wouldReturn;
        _bestPart.text = existing.bestPart ?? '';
      }
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    // Tell the user WHY the button isn't doing anything, instead of
    // silently returning (the original behavior — which read as a
    // broken button).
    if (_stars == 0 || _wouldReturn == null) {
      TSHaptics.errorTick();
      final missing = <String>[];
      if (_stars == 0) missing.add('pick a star rating');
      if (_wouldReturn == null) missing.add('answer "would you go again?"');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(missing.join(' · ')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(ratingsServiceProvider).submitRecap(
            tripId: widget.trip.id,
            destination: widget.trip.selectedDestination ?? widget.trip.name,
            stars: _stars,
            wouldReturn: _wouldReturn!,
            bestPart: _bestPart.text.trim().isEmpty
                ? null
                : _bestPart.text.trim(),
          );
      TSHaptics.success();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('recap saved ✦',
                style: TSTextStyles.body(color: TSColors.bg)),
            backgroundColor: TSColors.lime,
          ),
        );
      }
      // If the user loved this trip (4+ stars) and iOS/Android
      // hasn't already shown the native prompt recently, ask for
      // an App Store rating. Apple caps to 3 prompts per 365 days
      // automatically, so we layer an extra local gate (once every
      // 120 days) so we don't burn through the system allowance.
      if (_stars >= 4) {
        await _maybeAskForReview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _maybeAskForReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRaw = prefs.getString('last_review_prompt_at');
      final last = lastRaw == null ? null : DateTime.tryParse(lastRaw);
      if (last != null &&
          DateTime.now().difference(last).inDays < 120) {
        return;
      }
      final reviewer = InAppReview.instance;
      if (await reviewer.isAvailable()) {
        await reviewer.requestReview();
        await prefs.setString('last_review_prompt_at',
            DateTime.now().toIso8601String());
      }
    } catch (_) {
      // Non-fatal — never block the recap save on a review prompt.
    }
  }

  @override
  void dispose() {
    _bestPart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _stars > 0 && _wouldReturn != null && !_saving;
    return GestureDetector(
      // Tap anywhere outside the text field to dismiss keyboard —
      // the recap sheet is taller than the free area once the
      // "best part" composer is focused.
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                  child: CircularProgressIndicator(color: TSColors.lime)),
            )
          : SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TSColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('${widget.trip.selectedFlag ?? '🌍'}  how was ${widget.trip.selectedDestination ?? 'the trip'}?',
                  style: TSTextStyles.heading(size: 20),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _stars;
                  return GestureDetector(
                    onTap: () {
                      TSHaptics.selection();
                      setState(() => _stars = i + 1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        filled ? '⭐' : '☆',
                        style: TextStyle(
                            fontSize: 34,
                            color: filled ? TSColors.gold : TSColors.muted),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              Text('would you go again?',
                  style: TSTextStyles.body(color: TSColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final opt in const [
                    (key: 'yes',   label: '✨ yes'),
                    (key: 'maybe', label: '🤔 maybe'),
                    (key: 'no',    label: '❌ nah'),
                  ])
                    _ChipBtn(
                      label: opt.label,
                      selected: _wouldReturn == opt.key,
                      onTap: () {
                        TSHaptics.selection();
                        setState(() => _wouldReturn = opt.key);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _bestPart,
                maxLines: 2,
                style: TSTextStyles.body(),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'best part? (optional)',
                  hintStyle: TSTextStyles.body(color: TSColors.muted),
                  filled: true,
                  fillColor: TSColors.s2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                // Visually fade the button when the form isn't ready
                // — but keep the tap live so _save can surface a
                // "what's missing" snackbar instead of going silent.
                child: Opacity(
                  opacity: canSave ? 1.0 : 0.5,
                  child: TSButton(
                    label: _saving ? 'saving…' : 'save recap ✦',
                    loading: _saving,
                    onTap: _save,
                  ),
                ),
              ),
            ])),
    ),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
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
        child: Text(label,
            style: TSTextStyles.body(
              size: 13,
              color: selected ? TSColors.lime : TSColors.text,
            )),
      ),
    );
  }
}
