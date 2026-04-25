import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

/// Destination-aware tips. Inline cards covering money, visa, data,
/// weather, health, safety. Later: AI-personalize per destination.
class TipsTab extends ConsumerWidget {
  const TipsTab({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dest = trip.selectedDestination;
    final tips = _tipsFor(dest);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        if (dest != null) ...[
          Text('tips for $dest ${trip.selectedFlag ?? ''}',
              style: TSTextStyles.heading(size: 18)),
          const SizedBox(height: 4),
          Text('what to know before you go',
              style: TSTextStyles.caption(color: TSColors.muted)),
          const SizedBox(height: 16),
        ],
        for (int i = 0; i < tips.length; i++)
          _TipCard(tip: tips[i]).animate().fadeIn(delay: (i * 60).ms),
      ],
    );
  }
}

class _Tip {
  const _Tip(this.emoji, this.title, this.body);
  final String emoji, title, body;
}

List<_Tip> _tipsFor(String? destination) {
  // Universal starter set. Destination-aware AI version is v1.1.
  final d = destination ?? 'your destination';
  return [
    _Tip('💰', 'budget',
        'book flights + accommodation 6 weeks ahead for best rates. $d prices peak in summer and around holidays.'),
    _Tip('🛂', 'visa + passport',
        'check visa requirements for every passport in your squad. passport should have 6+ months validity. photocopy your passport and store it separately from the original.'),
    _Tip('📱', 'data + roaming',
        "grab an eSIM before you land — way cheaper than roaming. airalo, holafly, or ubigi work in most countries. download offline maps in google maps or maps.me."),
    _Tip('💳', 'money + cards',
        'wise or revolut cards = no fees on spending abroad. notify your bank before you fly. carry a small amount of local currency for taxis + tips on arrival.'),
    _Tip('🌡️', 'weather',
        "check the forecast one week out and re-pack. even summer evenings can get cold. layers > a single heavy jacket."),
    _Tip('🏥', 'health + insurance',
        'get travel insurance before you fly (safetywing, world nomads). bring prescriptions in original bottles. check if any vaccinations are recommended.'),
    _Tip('🔒', 'safety',
        'share your itinerary with someone back home. avoid flashing expensive tech in crowds. register with your country\'s embassy for overseas alerts.'),
    _Tip('🎒', 'pro tip',
        "leave space in your luggage for souvenirs. a 2-1-1 rule works for most trips: 2 pants · 1 jacket · 1 'dressy' outfit."),
  ];
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final _Tip tip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TSCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tip.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tip.title, style: TSTextStyles.title(size: 14)),
              const SizedBox(height: 4),
              Text(tip.body, style: TSTextStyles.body(size: 13)),
            ]),
          ),
        ]),
      ),
    );
  }
}
