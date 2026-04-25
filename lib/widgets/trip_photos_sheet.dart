import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import 'photo_lightbox.dart';

// ─────────────────────────────────────────────────────────────
//  TRIP PHOTOS SHEET
//
//  Pull every image_url off this trip's chat_messages and show
//  them as a 3-col grid. Tap a thumbnail → photo lightbox.
//  Non-realtime (one-shot fetch) — good enough for a memories
//  lookback and avoids a second subscription per trip.
// ─────────────────────────────────────────────────────────────

class TripPhotosSheet extends ConsumerStatefulWidget {
  const TripPhotosSheet({super.key, required this.tripId});
  final String tripId;

  static Future<void> show(BuildContext context, String tripId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TripPhotosSheet(tripId: tripId),
    );
  }

  @override
  ConsumerState<TripPhotosSheet> createState() => _TripPhotosSheetState();
}

class _TripPhotosSheetState extends ConsumerState<TripPhotosSheet> {
  List<String> _urls = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client
          .from('chat_messages')
          .select('image_url')
          .eq('trip_id', widget.tripId)
          .not('image_url', 'is', null)
          .order('created_at', ascending: false)
          .limit(200);
      final urls = <String>[];
      for (final r in (rows as List)) {
        final url = (r as Map<String, dynamic>)['image_url'] as String?;
        if (url != null && url.isNotEmpty) urls.add(url);
      }
      if (!mounted) return;
      setState(() {
        _urls = urls;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scroll) => Column(children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          decoration: BoxDecoration(
            color: TSColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(children: [
            const Text('📸', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('squad photos',
                style: TSTextStyles.heading(size: 18)),
            const Spacer(),
            if (!_loading)
              Text(
                  _urls.isEmpty
                      ? 'none yet'
                      : '${_urls.length} photo${_urls.length == 1 ? '' : 's'}',
                  style: TSTextStyles.caption(color: TSColors.muted)),
          ]),
        ),
        Expanded(child: _body(scroll)),
      ]),
    );
  }

  Widget _body(ScrollController scroll) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: TSColors.lime));
    }
    if (_urls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'no photos yet · drop one in chat to start the album',
            style: TSTextStyles.caption(color: TSColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return GridView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: _urls.length,
      itemBuilder: (_, i) {
        final url = _urls[i];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            TSHaptics.light();
            openPhotoLightbox(context, url);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: url,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: TSColors.s2),
                errorWidget: (_, __, ___) =>
                    Container(color: TSColors.s2),
              ),
            ),
          ),
        );
      },
    );
  }
}
