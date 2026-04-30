import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../core/haptics.dart';
import '../core/theme.dart';
import 'feedback_form_sheet.dart';
import 'feedback_models.dart';
import 'thank_you_overlay.dart';

/// Shows the "how's tripsquad treating you?" sentiment router.
/// Three-card vote — happy goes straight to Apple's InAppReview prompt
/// (so App Store ratings still work), neutral/unhappy open the form.
Future<void> showSentimentRouter(
  BuildContext context, {
  String trigger = 'settings_rate_tile',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SentimentRouterSheet(trigger: trigger),
  );
}

class _SentimentRouterSheet extends StatelessWidget {
  const _SentimentRouterSheet({required this.trigger});
  final String trigger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 18,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: TSColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              "how's tripsquad treating you?",
              style: TSTextStyles.heading(size: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'tap one. we read every note.',
              style: TSTextStyles.body(color: TSColors.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _SentimentCard(
                    emoji: '✨',
                    label: 'loving it',
                    accent: TSColors.lime,
                    onTap: () => _onHappy(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SentimentCard(
                    emoji: '🤔',
                    label: "it's okay",
                    accent: TSColors.gold,
                    onTap: () => _onNeutral(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SentimentCard(
                    emoji: '😔',
                    label: 'not great',
                    accent: TSColors.purple,
                    onTap: () => _onUnhappy(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'maybe later',
                style: TSTextStyles.label(color: TSColors.muted, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onHappy(BuildContext context) async {
    TSHaptics.success();
    Navigator.pop(context);
    try {
      final reviewer = InAppReview.instance;
      if (await reviewer.isAvailable()) {
        await reviewer.requestReview();
      }
    } catch (_) { /* non-fatal — overlay still shows */ }
    if (context.mounted) showThankYouOverlay(context);
  }

  void _onNeutral(BuildContext context) {
    TSHaptics.selection();
    Navigator.pop(context);
    showFeedbackForm(
      context,
      sentiment: FeedbackSentiment.neutral,
      category: FeedbackCategory.featureRequest,
      trigger: trigger,
    );
  }

  void _onUnhappy(BuildContext context) {
    TSHaptics.selection();
    Navigator.pop(context);
    showFeedbackForm(
      context,
      sentiment: FeedbackSentiment.unhappy,
      category: FeedbackCategory.bug,
      empathy: true,
      trigger: trigger,
    );
  }
}

class _SentimentCard extends StatelessWidget {
  const _SentimentCard({
    required this.emoji,
    required this.label,
    required this.accent,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 6),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.20), width: 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TSTextStyles.label(color: TSColors.text, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}
