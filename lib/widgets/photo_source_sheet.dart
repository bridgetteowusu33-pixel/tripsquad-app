import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/haptics.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  PHOTO SOURCE SHEET
//
//  Tiny bottom sheet presenting a camera vs library choice before
//  invoking ImagePicker. Returns the picked XFile, or null on
//  cancel. Shared by trip chat, DMs, and Scout so the UX is
//  identical across surfaces.
// ─────────────────────────────────────────────────────────────

Future<XFile?> pickPhotoFromSheet(BuildContext context) async {
  TSHaptics.medium();
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: TSColors.s1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: TSColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SourceTile(
              emoji: '📸',
              label: 'take a photo',
              onTap: () =>
                  Navigator.of(sheet).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
            _SourceTile(
              emoji: '🖼️',
              label: 'from library',
              onTap: () =>
                  Navigator.of(sheet).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null) return null;
  final picker = ImagePicker();
  return picker.pickImage(
    source: source,
    maxWidth: 1800,
    imageQuality: 82,
    preferredCameraDevice: CameraDevice.rear,
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });
  final String emoji, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TSColors.border),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TSTextStyles.title(
                    size: 14, color: TSColors.text)),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.muted, size: 14),
        ]),
      ),
    );
  }
}
