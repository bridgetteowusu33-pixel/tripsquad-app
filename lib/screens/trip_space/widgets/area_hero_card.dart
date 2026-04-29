import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

/// "Best area to stay" hero card. Sits at the top of the Stays + Eats
/// tab. The same TripRecommendation shape as hotels/restaurants — but
/// rendered larger, no price band, no booking action. Just *the area*
/// + scout's reasoning + a few vibe tags.
class AreaHeroCard extends StatelessWidget {
  const AreaHeroCard({super.key, required this.area});
  final TripRecommendation area;

  @override
  Widget build(BuildContext context) {
    return TSCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: area.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: area.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _areaGradient(),
                      errorWidget: (_, __, ___) => _areaGradient(),
                    )
                  : _areaGradient(label: area.name),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'where to stay',
                    style: TSTextStyles.label(
                      size: 11,
                      color: TSColors.lime,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    area.name,
                    style: TSTextStyles.heading(size: 22),
                  ),
                  if (area.reason != null && area.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      area.reason!,
                      style: TSTextStyles.body(
                        size: 14,
                        color: TSColors.text2,
                      ),
                    ),
                  ],
                  if (area.vibeTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in area.vibeTags)
                          _VibeChip(label: tag),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Designed placeholder for the area hero when no photo is found.
/// Lime-tinted gradient + the neighborhood label so the card still
/// reads "this is the area where you'll stay" without a misleading
/// city skyline shot.
Widget _areaGradient({String? label}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TSColors.lime.withValues(alpha: 0.16),
          TSColors.s2,
        ],
      ),
    ),
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏘️', style: TextStyle(fontSize: 56)),
        if (label != null && label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: TSTextStyles.label(color: TSColors.text2, size: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
  );
}

class _VibeChip extends StatelessWidget {
  const _VibeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TSColors.lime.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TSTextStyles.label(color: TSColors.lime, size: 11),
      ),
    );
  }
}
