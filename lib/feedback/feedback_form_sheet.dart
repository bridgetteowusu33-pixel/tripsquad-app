import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart';
import 'feedback_models.dart';

/// Shows the in-app feedback form. Default category + sentiment + empathy
/// flags come from the sentiment router based on which card the user
/// tapped (neutral or unhappy).
Future<void> showFeedbackForm(
  BuildContext context, {
  FeedbackCategory category = FeedbackCategory.general,
  FeedbackSentiment sentiment = FeedbackSentiment.neutral,
  bool empathy = false,
  String trigger = 'unknown',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeedbackFormSheet(
      initialCategory: category,
      sentiment: sentiment,
      empathy: empathy,
      trigger: trigger,
    ),
  );
}

class _FeedbackFormSheet extends ConsumerStatefulWidget {
  const _FeedbackFormSheet({
    required this.initialCategory,
    required this.sentiment,
    required this.empathy,
    required this.trigger,
  });

  final FeedbackCategory initialCategory;
  final FeedbackSentiment sentiment;
  final bool empathy;
  final String trigger;

  @override
  ConsumerState<_FeedbackFormSheet> createState() => _FeedbackFormSheetState();
}

class _FeedbackFormSheetState extends ConsumerState<_FeedbackFormSheet> {
  late FeedbackCategory _category;
  final _msg = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  String get _headerText => switch (_category) {
        FeedbackCategory.bug => widget.empathy
            ? "we hear you. tell us what's off."
            : "something's broken? spill it.",
        FeedbackCategory.featureRequest =>
          "what would make tripsquad chef's kiss?",
        FeedbackCategory.general => "got thoughts? we're all ears.",
      };

  Color get _accent => switch (_category) {
        FeedbackCategory.bug => TSColors.coral,
        FeedbackCategory.featureRequest => TSColors.lime,
        FeedbackCategory.general => TSColors.blue,
      };

  Future<void> _submit() async {
    final text = _msg.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(feedbackServiceProvider).submit(
            sentiment: widget.sentiment.dbValue,
            category: _category.dbValue,
            message: text,
            trigger: widget.trigger,
          );
      TSHaptics.success();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildThankYou();
    return _buildForm();
  }

  Widget _buildThankYou() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24, 28, 24, MediaQuery.of(context).padding.bottom + 28),
        decoration: const BoxDecoration(
          color: TSColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: TSColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.check_circle_rounded, size: 48, color: _accent),
            const SizedBox(height: 14),
            Text('noted. we gotchu.',
                style: TSTextStyles.heading(size: 20),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'we actually read every single one.',
              style: TSTextStyles.body(color: TSColors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final canSubmit = !_submitting && _msg.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: TSColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20, 18, 20, MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: TSColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(_headerText, style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final cat in FeedbackCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: cat.label,
                        active: _category == cat,
                        accent: _accentFor(cat),
                        onTap: () {
                          TSHaptics.selection();
                          setState(() => _category = cat);
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _msg,
                maxLines: 5,
                minLines: 4,
                maxLength: 1000,
                style: TSTextStyles.body(),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'type your thoughts…',
                  hintStyle: TSTextStyles.body(color: TSColors.muted),
                  filled: true,
                  fillColor: TSColors.s2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TSColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  counterStyle: TSTextStyles.caption(color: TSColors.muted),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    child: Text('cancel',
                        style: TSTextStyles.label(
                            color: TSColors.text2, size: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Opacity(
                    opacity: canSubmit ? 1.0 : 0.5,
                    child: InkWell(
                      onTap: canSubmit ? _submit : null,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 16, width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TSColors.bg,
                                ),
                              )
                            : Text('send it',
                                style: TSTextStyles.label(
                                    color: TSColors.bg, size: 13)),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentFor(FeedbackCategory c) => switch (c) {
        FeedbackCategory.bug => TSColors.coral,
        FeedbackCategory.featureRequest => TSColors.lime,
        FeedbackCategory.general => TSColors.blue,
      };
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.16) : TSColors.s2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? accent.withOpacity(0.45) : TSColors.border,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TSTextStyles.body(
            size: 13,
            color: active ? accent : TSColors.text2,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
