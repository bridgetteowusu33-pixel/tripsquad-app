import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

/// Card for a single hotel or restaurant recommendation. Same shell
/// for both — variants only differ in which outbound buttons render
/// (hotels get a Booking.com search button; restaurants don't).
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.rec});
  final TripRecommendation rec;

  bool get _isHotel => rec.kind == RecommendationKind.hotel;

  @override
  Widget build(BuildContext context) {
    return TSCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header — full-width, fixed aspect.
          if (rec.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: rec.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: TSColors.s2),
                  errorWidget: (_, __, ___) => Container(color: TSColors.s2),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: TSColors.s2,
                  alignment: Alignment.center,
                  child: Text(
                    _isHotel ? '🛏️' : '🍽️',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + price band
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rec.name,
                        style: TSTextStyles.heading(size: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rec.priceBand != null && rec.priceBand!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        rec.priceBand!,
                        style: TSTextStyles.body(
                          size: 13,
                          color: TSColors.lime,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),

                // Sub-line: cuisine · neighborhood · day anchor
                const SizedBox(height: 4),
                Text(
                  _subline(),
                  style: TSTextStyles.caption(color: TSColors.muted),
                ),

                // Vibe chips
                if (rec.vibeTags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in rec.vibeTags.take(4))
                        _MutedChip(label: tag),
                    ],
                  ),
                ],

                // "Why scout picked it"
                if (rec.reason != null && rec.reason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '"${rec.reason!}"',
                    style: TSTextStyles.body(
                      size: 13,
                      color: TSColors.text2,
                    ),
                  ),
                ],

                // Action row — Maps, Booking (hotels)
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (rec.mapsUrl != null && rec.mapsUrl!.isNotEmpty)
                      _ActionButton(
                        label: 'directions',
                        icon: Icons.map_outlined,
                        onTap: () => _launch(rec.mapsUrl!),
                      ),
                    if (_isHotel &&
                        rec.bookingUrl != null &&
                        rec.bookingUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'find rates',
                        icon: Icons.hotel_outlined,
                        onTap: () => _launch(rec.bookingUrl!),
                        primary: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subline() {
    final parts = <String>[];
    if (rec.cuisine != null && rec.cuisine!.isNotEmpty) parts.add(rec.cuisine!);
    if (rec.neighborhood != null && rec.neighborhood!.isNotEmpty) {
      parts.add(rec.neighborhood!);
    }
    if (rec.meal != null && rec.meal!.isNotEmpty) parts.add(rec.meal!);
    if (rec.dayAnchor != null) parts.add('near day ${rec.dayAnchor}');
    return parts.isEmpty ? ' ' : parts.join(' · ');
  }

  Future<void> _launch(String url) async {
    TSHaptics.ctaTap();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MutedChip extends StatelessWidget {
  const _MutedChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TSTextStyles.caption(color: TSColors.text2),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? TSColors.lime : TSColors.s2;
    final fg = primary ? TSColors.bg : TSColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: primary ? TSColors.lime : TSColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TSTextStyles.label(color: fg, size: 11),
            ),
          ],
        ),
      ),
    );
  }
}
