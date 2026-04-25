import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/haptics.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  PHOTO LIGHTBOX
//
//  Fullscreen overlay for a single image. Tap or swipe-down to
//  dismiss. Pinch to zoom (InteractiveViewer handles the gesture
//  + resets scale on double-tap).
// ─────────────────────────────────────────────────────────────

Future<void> openPhotoLightbox(BuildContext context, String url) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.96),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => _PhotoLightbox(url: url),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _PhotoLightbox extends StatelessWidget {
  const _PhotoLightbox({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        // Swipe anywhere to dismiss — matches the iOS Photos feel.
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0).abs() > 200) {
            Navigator.of(context).maybePop();
          }
        },
        child: SafeArea(
          child: Stack(children: [
            Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: Hero(
                  tag: url,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox(
                      height: 40,
                      width: 40,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: TSColors.lime),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 40),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => _share(context),
                  tooltip: 'share or save',
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'close',
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    TSHaptics.light();
    Rect? origin;
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}
    try {
      // Pull the image bytes so Share.shareXFiles can hand a real
      // file to the share sheet — enables "Save to Photos" and
      // forwarding to apps that don't accept URLs (WhatsApp, etc.).
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        throw Exception('fetch failed (${res.statusCode})');
      }
      final dir = await getTemporaryDirectory();
      final name = Uri.parse(url).pathSegments.isNotEmpty
          ? Uri.parse(url).pathSegments.last
          : 'tripsquad_photo.jpg';
      final safeName =
          name.contains('.') ? name : '$name.jpg';
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(res.bodyBytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/jpeg')],
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (!context.mounted) return;
      // Fall back to sharing just the URL.
      await Share.share(url, sharePositionOrigin: origin);
    }
  }
}
