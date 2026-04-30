import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/haptics.dart';
import '../core/theme.dart';

/// What's New half-sheet — fires once per user per release. The seen
/// flag is keyed by `_releaseTag` so future releases (v1.3, v1.4) just
/// need to bump the tag string and update the bullet content; users
/// who already saw the prior tag will get the new sheet on first open
/// of the new build.
const String _releaseTag = 'v1.2.0';
String get _seenKey => 'whats_new_seen_$_releaseTag';

/// Fire-and-forget. Call from any Stateful widget's first paint after
/// the user is signed in (e.g. HomeScreen.initState). Safe to call
/// multiple times — internal flag ensures it only opens once.
Future<void> maybeShowWhatsNew(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_seenKey) == true) return;
  if (!context.mounted) return;
  await prefs.setBool(_seenKey, true); // mark before showing so a
                                       // mid-show crash doesn't loop
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WhatsNewSheet(),
  );
}

class _WhatsNewSheet extends StatefulWidget {
  const _WhatsNewSheet();
  @override
  State<_WhatsNewSheet> createState() => _WhatsNewSheetState();
}

class _WhatsNewSheetState extends State<_WhatsNewSheet> {
  bool _expanded = false;

  static const _heroBullets = [
    ('🧭', 'solo explorer',  'plan trips for one. scout adapts.'),
    ('🏨', 'stays + eats',   "the where-we-stayin', where-we-eatin' answers, sorted."),
    ('✈️', 'book tab',       'flights + accommodation, squad-coordinated.'),
  ];

  static const _moreBullets = [
    ('📊', 'squad booking progress',         "see who's locked in vs. who's still ghosting."),
    ('⚓', 'anchor flight + group-stay',      'land at the same time. crash at the same place. no FOMO.'),
    ('⏳', 'deadlines, nudges, celebrations', 'scout nudges, big lock-in confetti.'),
    ('💬', 'feedback flow + realtime polish', 'vote with one tap · ghosts vanish in real time.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: TSColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 18, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text('your trip just got more real',
                  style: TSTextStyles.heading(size: 24)),
              const SizedBox(height: 6),
              Text("a glow-up, basically.",
                  style: TSTextStyles.body(color: TSColors.text2)),
              const SizedBox(height: 22),

              for (final (emoji, title, body) in _heroBullets)
                _Bullet(emoji: emoji, title: title, body: body),

              if (_expanded) ...[
                const SizedBox(height: 4),
                Container(height: 1, color: TSColors.border),
                const SizedBox(height: 14),
                for (final (emoji, title, body) in _moreBullets)
                  _Bullet(emoji: emoji, title: title, body: body),
              ] else ...[
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    TSHaptics.selection();
                    setState(() => _expanded = true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('everything new →',
                        style: TSTextStyles.label(
                            color: TSColors.lime, size: 12)),
                  ),
                ),
              ],

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: () {
                    TSHaptics.ctaTap();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TSColors.lime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('keep planning →',
                        style: TSTextStyles.label(
                            color: TSColors.bg, size: 13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.emoji, required this.title, required this.body});
  final String emoji, title, body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TSTextStyles.title(size: 15, color: TSColors.text)),
                const SizedBox(height: 2),
                Text(body, style: TSTextStyles.body(color: TSColors.text2, size: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
