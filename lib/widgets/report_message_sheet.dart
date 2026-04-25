import 'package:flutter/material.dart';
import '../core/haptics.dart';
import '../core/theme.dart';

/// Apple guideline 1.2 compliant reasons. Returned value is stored
/// as the `reason` column in `message_reports`. Keep labels short;
/// the moderation UI (external) reads these verbatim.
const reportReasons = <String>[
  'spam',
  'harassment',
  'hate speech',
  'violence',
  'nudity',
  'self-harm',
  'something else',
];

/// Bottom sheet of reason chips. Returns the picked reason, or null
/// if the user bailed. The caller is responsible for submitting.
Future<String?> showReportReasonSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: TSColors.s1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: TSColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('report this message',
                style: TSTextStyles.heading(size: 20)),
            const SizedBox(height: 6),
            Text(
              'tell us why. we\'ll review and take action if needed.',
              style: TSTextStyles.caption(color: TSColors.muted),
            ),
            const SizedBox(height: 14),
            for (final r in reportReasons) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  TSHaptics.light();
                  Navigator.of(sheet).pop(r);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: TSColors.s2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TSColors.border),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(r,
                          style: TSTextStyles.body(
                              size: 14, color: TSColors.text)),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: TSColors.muted, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}
