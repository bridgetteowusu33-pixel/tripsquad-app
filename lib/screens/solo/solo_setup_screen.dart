// ─────────────────────────────────────────────────────────────
//  SOLO SETUP SCREEN
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/widgets.dart';
import '../../core/constants.dart';

class SoloSetupScreen extends ConsumerStatefulWidget {
  const SoloSetupScreen({super.key});
  @override
  ConsumerState<SoloSetupScreen> createState() => _SoloSetupScreenState();
}

class _SoloSetupScreenState extends ConsumerState<SoloSetupScreen> {
  final List<String> _vibes = [];
  String? _destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: const TSAppBar(title: 'Solo Explorer'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Your solo", style: TSTextStyles.heading(size: 26)),
          Text("adventure",
            style: TSTextStyles.heading(size: 26, color: TSColors.blue)
                .copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),

          const SectionLabel(label: 'Destination'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: TSQuickDestinations.all.take(8).map((d) {
              final label = '${d.flag} ${d.city}';
              final sel = _destination == label;
              return GestureDetector(
                onTap: () => setState(() => _destination = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? TSColors.blueDim(0.12) : TSColors.s2,
                    borderRadius: TSRadius.full,
                    border: Border.all(
                        color: sel ? TSColors.blueDim(0.35) : TSColors.border),
                  ),
                  child: Text(label,
                    style: TSTextStyles.body(
                        size: 12,
                        color: sel ? TSColors.blue : TSColors.text2,
                        weight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          const SectionLabel(label: 'Your vibe (up to 3)'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 8,
              crossAxisSpacing: 8, childAspectRatio: 2.5,
            ),
            itemCount: TSVibes.all.length,
            itemBuilder: (_, i) {
              final v = TSVibes.all[i];
              final sel = _vibes.contains(v.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) _vibes.remove(v.id);
                    else if (_vibes.length < 3) _vibes.add(v.id);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? TSColors.blueDim(0.10) : TSColors.s2,
                    borderRadius: TSRadius.md,
                    border: Border.all(
                        color: sel ? TSColors.blueDim(0.35) : TSColors.border,
                        width: sel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Text(v.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(v.label, style: TSTextStyles.title(size: 12)),
                  ]),
                ),
              );
            },
          ),

          const SizedBox(height: 28),
          TSButton(
            label: 'let scout plan it 🧭',
            onTap: _destination == null || _vibes.isEmpty ? null : () {
              // TODO: create solo trip + generate itinerary
              context.push('/solo/new/board');
            },
          ),
        ]),
      ),
    );
  }
}

// ignore: must_be_immutable
class SoloBoardScreen extends StatelessWidget {
  const SoloBoardScreen({super.key, required this.tripId});
  final String tripId;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TSColors.bg,
    appBar: const TSAppBar(title: 'Solo Itinerary'),
    body: Center(child: Text('Solo board — trip $tripId', style: TSTextStyles.body())),
  );
}
