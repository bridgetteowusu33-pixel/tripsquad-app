import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../core/responsive.dart';
import '../../core/constants.dart';
import '../../core/feature_flags.dart';
import '../../models/models.dart';
import '../../providers/entitlement_providers.dart';
import '../../providers/providers.dart';
import '../../services/entitlement_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
//  WIZARD SHELL
// ─────────────────────────────────────────────────────────────
class TripCreationWizard extends ConsumerStatefulWidget {
  const TripCreationWizard({super.key, this.preselectedDestination});
  final String? preselectedDestination;

  @override
  ConsumerState<TripCreationWizard> createState() =>
      _TripCreationWizardState();
}

class _TripCreationWizardState extends ConsumerState<TripCreationWizard> {
  @override
  void initState() {
    super.initState();
    final seed = widget.preselectedDestination;
    // Always start a fresh wizard (the provider is keep-alive and would
    // otherwise carry state from a previous cancel).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(tripCreationProvider.notifier);
      notifier.reset();
      if (seed != null && seed.isNotEmpty) {
        notifier.setDestinations([seed]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripCreationProvider);
    // v1.1 — solo trips still hit the final step (which is what
    // actually persists the trip), but the step is labeled "Create"
    // and skips the invite UI in favor of an immediate route to
    // the trip space.
    final isSolo = state.mode == TripMode.solo;
    final steps = isSolo
        ? const ['Mode', 'Name', 'Vibe', 'Destinations', 'Create']
        : const ['Mode', 'Name', 'Vibe', 'Destinations', 'Invite'];
    final pages = const <Widget>[
      _StepMode(),
      _StepNameDates(),
      _StepVibe(),
      _StepDestinations(),
      _StepInvite(),
    ];

    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: TSAppBar(
        title: 'plan a trip',
        subtitle: 'step ${state.currentStep + 1} of ${steps.length}',
        showBack: true,
        trailing: GestureDetector(
          onTap: () {
            ref.read(tripCreationProvider.notifier).reset();
            context.go('/home');
          },
          child: Text('cancel', style: TSTextStyles.caption(color: TSColors.muted)),
        ),
      ),
      body: SafeArea(
        child: TSResponsive.content(Column(children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                TSSpacing.md, TSSpacing.xs, TSSpacing.md, 0),
            child: TSProgressBar(
              progress: (state.currentStep + 1) / steps.length,
            ),
          ),
          // Pre-filled destination banner — always visible across steps
          if (widget.preselectedDestination != null &&
              state.destinations.contains(widget.preselectedDestination)) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: TSColors.limeDim(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TSColors.limeDim(0.3)),
                ),
                child: Row(children: [
                  Text(
                    TSQuickDestinations.flagFor(
                            widget.preselectedDestination!) ??
                        '🌍',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'destination locked in: ${widget.preselectedDestination}',
                      style: TSTextStyles.caption(color: TSColors.lime),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(state.currentStep),
                child: pages[state.currentStep],
              ),
            ),
          ),
        ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 0 — Mode (v1.1: solo or squad)
// ─────────────────────────────────────────────────────────────
//
//  The first decision: is this a group trip or a solo trip?
//  Defaults to group (matches existing behavior). Picking solo
//  trims the Invite step from the wizard further down the flow.
//
class _StepMode extends ConsumerWidget {
  const _StepMode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TSSpacing.md),
          Text("who's coming?",
              style: TSTextStyles.heading(size: 26)),
          const SizedBox(height: 6),
          Text('you can always add friends later.',
              style: TSTextStyles.body(color: TSColors.muted, size: 14)),
          const SizedBox(height: TSSpacing.lg),

          _ModeCard(
            title: 'with my squad',
            subtitle: 'invite friends, vote on the destination, plan together.',
            emoji: '👥',
            accent: TSColors.lime,
            selected: state.mode == TripMode.group,
            onTap: () => notifier.setMode(TripMode.group),
          ),
          const SizedBox(height: TSSpacing.sm),
          _ModeCard(
            title: 'just me',
            subtitle: "scout helps you plan. you can bring friends in any time.",
            emoji: '🧳',
            accent: TSColors.blue,
            selected: state.mode == TripMode.solo,
            onTap: () => notifier.setMode(TripMode.solo),
          ),
          const SizedBox(height: TSSpacing.xl),

          TSButton(
            label: 'next',
            onTap: () => notifier.nextStep(),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.accent,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { TSHaptics.selection(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.10) : TSColors.s2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : TSColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accent.withOpacity(0.18),
                  blurRadius: 18, spreadRadius: -4)]
              : null,
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TSTextStyles.title(size: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TSTextStyles.caption(color: TSColors.muted)),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle, color: accent, size: 22),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 1 — Name + Dates
// ─────────────────────────────────────────────────────────────
class _StepNameDates extends ConsumerStatefulWidget {
  const _StepNameDates();

  @override
  ConsumerState<_StepNameDates> createState() => _StepNameDatesState();
}

class _StepNameDatesState extends ConsumerState<_StepNameDates> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final current = ref.read(tripCreationProvider).name;
    _ctrl.text = current;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: TSSpacing.sm),
        Text("what's the", style: TSTextStyles.heading(size: 26)),
        Text("trip called?",
          style: TSTextStyles.heading(size: 26, color: TSColors.lime)
              .copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        Text("Give it a name your squad will recognise.",
          style: TSTextStyles.body(color: TSColors.muted)),

        const SizedBox(height: 28),

        TSTextField(
          hint: 'e.g. Lisbon Summer 2025',
          controller: _ctrl,
          autofocus: true,
          onChanged: notifier.setName,
        ),

        const SizedBox(height: 24),

        Text('Dates (optional)', style: TSTextStyles.label()),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: TSColors.lime,
                    surface: TSColors.s2,
                    onSurface: TSColors.text,
                  ),
                ),
                child: child!,
              ),
            );
            if (range != null) {
              notifier.setDates(range.start, range.end);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(TSSpacing.md),
            decoration: BoxDecoration(
              color: TSColors.s2,
              borderRadius: TSRadius.md,
              border: Border.all(
                color: state.startDate != null
                    ? TSColors.limeDim(0.35)
                    : TSColors.border,
              ),
            ),
            child: Row(children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                state.startDate == null
                    ? 'Select travel dates'
                    : '${_fmt(state.startDate!)} → ${_fmt(state.endDate!)}',
                style: TSTextStyles.body(
                  color: state.startDate != null ? TSColors.text : TSColors.muted,
                ),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 20),

        // Budget per person
        SectionLabel(label: 'your budget per person (optional)'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: TSSpacing.md),
          decoration: BoxDecoration(
            color: TSColors.s2,
            borderRadius: TSRadius.md,
            border: Border.all(color: TSColors.border),
          ),
          child: Row(children: [
            Text('\$', style: TSTextStyles.heading(size: 18, color: TSColors.muted)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                style: TSTextStyles.body(color: TSColors.text, size: 16),
                decoration: InputDecoration(
                  hintText: 'e.g. 1500',
                  hintStyle: TSTextStyles.body(color: TSColors.muted, size: 16),
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  final val = int.tryParse(v);
                  notifier.setBudget(val);
                },
              ),
            ),
            Text('per person', style: TSTextStyles.caption(color: TSColors.muted)),
          ]),
        ),

        const SizedBox(height: 32),

        TSButton(
          label: 'next: pick your vibe →',
          onTap: state.name.trim().isEmpty
              ? null
              : () => ref.read(tripCreationProvider.notifier).nextStep(),
        ),
      ]),
    );
  }

  String _fmt(DateTime d) => DateFormat('MMM d').format(d);
}

// ─────────────────────────────────────────────────────────────
//  STEP 2 — Vibe Picker
// ─────────────────────────────────────────────────────────────
class _StepVibe extends ConsumerWidget {
  const _StepVibe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(TSSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: TSSpacing.sm),
        Text("what's the", style: TSTextStyles.heading(size: 26)),
        Text("vibe?",
          style: TSTextStyles.heading(size: 26, color: TSColors.lime)
              .copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        Text('Pick up to 3. AI blends everyone\'s picks.',
          style: TSTextStyles.body(color: TSColors.muted)),

        const SizedBox(height: 20),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: TSVibes.all.length,
            itemBuilder: (_, i) {
              final v = TSVibes.all[i];
              final selected = state.vibes.contains(v.id);
              return GestureDetector(
                onTap: () {
                  TSHaptics.selection();
                  final vibes = List<String>.from(state.vibes);
                  if (selected) {
                    vibes.remove(v.id);
                  } else if (vibes.length < 3) {
                    vibes.add(v.id);
                  }
                  notifier.setVibes(vibes);
                },
                child: AnimatedContainer(
                  duration: 150.ms,
                  padding: const EdgeInsets.symmetric(
                      horizontal: TSSpacing.sm, vertical: TSSpacing.xs),
                  decoration: BoxDecoration(
                    color: selected ? TSColors.limeDim(0.10) : TSColors.s2,
                    borderRadius: TSRadius.md,
                    border: Border.all(
                      color: selected ? TSColors.limeDim(0.35) : TSColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Text(v.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(v.label, style: TSTextStyles.title(size: 12)),
                        Text(v.desc, style: TSTextStyles.caption(),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    )),
                  ]),
                ),
              );
            },
          ),
        ),

        if (state.vibes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TSColors.limeDim(0.08),
              borderRadius: TSRadius.sm,
              border: Border.all(color: TSColors.limeDim(0.25)),
            ),
            child: Row(children: [
              const Text('✓', style: TextStyle(color: TSColors.lime)),
              const SizedBox(width: 8),
              Text(
                '${state.vibes.length}/3 vibes selected',
                style: TSTextStyles.label(color: TSColors.lime),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 12),

        Row(children: [
          Expanded(
            child: TSButton(
              label: '← Back',
              variant: TSButtonVariant.ghost,
              onTap: () => ref.read(tripCreationProvider.notifier).prevStep(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TSButton(
              label: 'next: destinations →',
              onTap: state.vibes.isEmpty
                  ? null
                  : () => ref.read(tripCreationProvider.notifier).nextStep(),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 3 — Destination Shortlist
// ─────────────────────────────────────────────────────────────
class _StepDestinations extends ConsumerStatefulWidget {
  const _StepDestinations();

  @override
  ConsumerState<_StepDestinations> createState() =>
      _StepDestinationsState();
}

class _StepDestinationsState extends ConsumerState<_StepDestinations> {
  final _ctrl = TextEditingController();

  void _add(String dest) {
    if (dest.trim().isEmpty) return;
    final mode = ref.read(tripCreationProvider).mode;
    if (mode == TripMode.solo) {
      // Solo trips are single-destination: each pick REPLACES
      // the previous one. No shortlist accumulates.
      ref.read(tripCreationProvider.notifier).setDestinations([dest]);
      _ctrl.clear();
      return;
    }
    final dests = List<String>.from(
        ref.read(tripCreationProvider).destinations);
    if (!dests.contains(dest) && dests.length < 10) {
      dests.add(dest);
      ref.read(tripCreationProvider.notifier).setDestinations(dests);
    }
    _ctrl.clear();
  }

  void _remove(String dest) {
    final dests = List<String>.from(
        ref.read(tripCreationProvider).destinations);
    dests.remove(dest);
    ref.read(tripCreationProvider.notifier).setDestinations(dests);
  }

  // v1.1 — country chips only shown on solo trips. Surfaces the
  // "you can do a whole country, not just a city" affordance
  // without adding noise for group flows (where the user is
  // building a city-level shortlist for voting).
  static const _soloCountries = [
    ('🇯🇵', 'Japan'),
    ('🇮🇹', 'Italy'),
    ('🇵🇹', 'Portugal'),
    ('🇲🇦', 'Morocco'),
    ('🇲🇽', 'Mexico'),
    ('🇹🇭', 'Thailand'),
    ('🇮🇸', 'Iceland'),
    ('🇿🇦', 'South Africa'),
    ('🇬🇷', 'Greece'),
    ('🇨🇴', 'Colombia'),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripCreationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: TSSpacing.sm),
        if (state.mode == TripMode.solo) ...[
          Text("where are you", style: TSTextStyles.heading(size: 26)),
          Text("going?",
            style: TSTextStyles.heading(size: 26, color: TSColors.lime)
                .copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          Text('pick a destination. you can change it any time.',
            style: TSTextStyles.body(color: TSColors.muted)),
        ] else ...[
          Text("build your", style: TSTextStyles.heading(size: 26)),
          Text("shortlist",
            style: TSTextStyles.heading(size: 26, color: TSColors.lime)
                .copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          Text('3–10 destinations. Your squad votes on these.',
            style: TSTextStyles.body(color: TSColors.muted)),
        ],

        const SizedBox(height: 20),

        // v1.1 — solo trips also get a country chip row above the
        // cities so "do the whole country" is a one-tap option.
        if (state.mode == TripMode.solo) ...[
          const SectionLabel(label: 'Whole country'),
          Wrap(spacing: 8, runSpacing: 8,
            children: _soloCountries.map((c) {
              final label = '${c.$1} ${c.$2}';
              final selected = state.destinations.contains(label);
              return GestureDetector(
                onTap: () => _add(label),
                child: AnimatedContainer(
                  duration: 150.ms,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? TSColors.limeDim(0.12)
                        : TSColors.s2,
                    borderRadius: TSRadius.full,
                    border: Border.all(
                      color: selected
                          ? TSColors.limeDim(0.35)
                          : TSColors.border,
                    ),
                  ),
                  child: Text(label,
                    style: TSTextStyles.body(
                      size: 12,
                      color: selected ? TSColors.lime : TSColors.text2,
                      weight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Quick add chips — smart: if the trip name matches a country
        // or region, surface cities in that place; otherwise fall back
        // to the curated 13.
        () {
          final suggestion = TSQuickDestinations.suggestFor(state.name);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(
                label: suggestion.matched == null
                    ? 'Quick add'
                    : 'Quick add — ${suggestion.matched} ✨',
              ),
              Wrap(spacing: 8, runSpacing: 8,
                children: suggestion.cities.map((d) {
                  final label = '${d.flag} ${d.city}';
                  final added = state.destinations.contains(label);
                  return GestureDetector(
                    onTap: () => added ? _remove(label) : _add(label),
                    child: AnimatedContainer(
                      duration: 150.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: added ? TSColors.limeDim(0.12) : TSColors.s2,
                        borderRadius: TSRadius.full,
                        border: Border.all(
                          color: added ? TSColors.limeDim(0.35) : TSColors.border,
                        ),
                      ),
                      child: Text(label,
                        style: TSTextStyles.body(
                          size: 12,
                          color: added ? TSColors.lime : TSColors.text2,
                          weight: added ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }(),

        const SizedBox(height: 20),

        // Selected list
        if (state.destinations.isNotEmpty) ...[
          SectionLabel(
            label: state.mode == TripMode.solo
                ? 'Picked'
                : 'Shortlist',
            action: state.mode == TripMode.solo ? null : () {},
            actionLabel: state.mode == TripMode.solo
                ? null
                : '${state.destinations.length}/10',
          ),
          ...state.destinations.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: TSSpacing.md, vertical: 10),
              decoration: BoxDecoration(
                color: TSColors.limeDim(0.08),
                borderRadius: TSRadius.sm,
                border: Border.all(color: TSColors.limeDim(0.25)),
              ),
              child: Row(children: [
                // Solo trips don't render a position number — there's
                // only ever one pick, so "1" is filler.
                if (state.mode != TripMode.solo) ...[
                  Text(
                    '${e.key + 1}',
                    style: TSTextStyles.label(color: TSColors.lime, size: 11),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(e.value,
                  style: TSTextStyles.body(size: 13, weight: FontWeight.w500))),
                GestureDetector(
                  onTap: () => _remove(e.value),
                  child: const Icon(Icons.close_rounded,
                    color: TSColors.muted, size: 18),
                ),
              ]),
            ),
          )),
          const SizedBox(height: 8),
        ],

        // Custom input
        Row(children: [
          Expanded(
            child: TSTextField(
              hint: '+ Add a destination…',
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _add(_ctrl.text),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: TSColors.lime,
                borderRadius: TSRadius.sm,
              ),
              child: const Icon(Icons.add_rounded, color: TSColors.bg),
            ),
          ),
        ]),

        const SizedBox(height: 24),

        Row(children: [
          Expanded(
            child: TSButton(
              label: '← Back',
              variant: TSButtonVariant.ghost,
              onTap: () => ref.read(tripCreationProvider.notifier).prevStep(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TSButton(
              label: state.mode == TripMode.solo
                  ? 'create trip ✈'
                  : 'next: invite squad →',
              // Solo trips just need ONE destination (the one
              // they're going to). Group trips still need a 3-deep
              // shortlist so the squad has real options to vote on.
              onTap: state.destinations.length <
                      (state.mode == TripMode.solo ? 1 : 3)
                  ? null
                  : () => ref.read(tripCreationProvider.notifier).nextStep(),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STEP 4 — Invite (creates trip + shows link)
// ─────────────────────────────────────────────────────────────
class _StepInvite extends ConsumerStatefulWidget {
  const _StepInvite();

  @override
  ConsumerState<_StepInvite> createState() => _StepInviteState();
}

class _StepInviteState extends ConsumerState<_StepInvite> {
  Trip? _trip;
  bool _loading = false;
  String? _error;
  final _tagCtrl = TextEditingController();
  List<Map<String, dynamic>> _tagResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _createTrip();
  }

  /// Atomically reserves a Trip Pass when this will be a paid slot
  /// (host already has ≥1 active trip), creates the trip, then
  /// consumes the reservation. On any failure between reserve and
  /// consume, the reservation is released so the pass isn't lost.
  /// Abandoned reservations (e.g. crashed client) auto-release after
  /// 5 min via `release_stale_reservations` in the DB.
  Future<void> _createTrip() async {
    setState(() => _loading = true);
    final ent = ref.read(entitlementServiceProvider);
    final uid = Supabase.instance.client.auth.currentUser?.id;

    // Decide up-front whether this trip will consume a pass. The
    // gate already ran before the wizard opened, so at this point
    // the user either has a free slot OR an unspent pass. We only
    // reserve when they'll exceed the free slot.
    //
    // In v1.0 launch posture ([FeatureFlags.paywallEnabled] = false),
    // we skip the reserve path entirely — every trip is free.
    String? reservedPassId;
    if (FeatureFlags.paywallEnabled && uid != null) {
      final active = await ent.countActiveTripsAsHost(uid);
      if (active >= 1) {
        reservedPassId = await ent.reserveTripPass(uid);
        if (reservedPassId == null) {
          // Race: another device / tab consumed the pass between
          // gate check and here. Bail with a clear error.
          if (mounted) {
            setState(() {
              _loading = false;
              _error = 'no trip pass available';
            });
          }
          return;
        }
      }
    }

    try {
      final state = ref.read(tripCreationProvider);
      final trip = await ref.read(tripServiceProvider).createTrip(
        name:           state.name,
        mode:           state.mode,
        vibes:          state.vibes,
        startDate:      state.startDate,
        endDate:        state.endDate,
        budgetPerPerson: state.budgetPerPerson,
      );
      await ref.read(tripServiceProvider).updateDestinations(
        trip.id,
        state.destinations,
      );
      if (reservedPassId != null) {
        await ent.consumeReservedPass(reservedPassId, trip.id);
        ref.invalidate(unspentTripPassesProvider);
      }

      // v1.1 — solo trips skip voting entirely. Take the first
      // destination the user listed and set it as the winner so
      // the trip lands in 'revealed' state and the planning UI
      // is immediately useful. setWinner is idempotent.
      Trip finalTrip = trip;
      if (state.mode == TripMode.solo && state.destinations.isNotEmpty) {
        final pick = state.destinations.first;
        final flag = TSQuickDestinations.flagFor(pick) ?? '✈️';
        await ref.read(tripServiceProvider).setWinner(
              tripId: trip.id,
              destination: pick,
              flag: flag,
            );
        finalTrip = trip.copyWith(
          selectedDestination: pick,
          selectedFlag: flag,
          status: TripStatus.revealed,
        );
      }

      ref.invalidate(myTripsProvider);
      if (mounted) setState(() { _trip = finalTrip; _loading = false; });
    } catch (e) {
      if (reservedPassId != null) {
        await ent.releaseReservedPass(reservedPassId);
      }
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchTag(String query) async {
    if (query.length < 2) {
      setState(() => _tagResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(tripServiceProvider).searchByTag(query);
      if (mounted) setState(() { _tagResults = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addByTag(Map<String, dynamic> user) async {
    if (_trip == null) return;
    try {
      await ref.read(tripServiceProvider).addMemberByTag(
        tripId: _trip!.id,
        userId: user['id'] as String,
        nickname: user['nickname'] ?? 'friend',
        emoji: user['emoji'] ?? '😎',
      );
      // addMemberByTag already inserts an 'invited_to_trip'
      // notification pointing at the trip — no DM needed.
      ref.invalidate(myTripsProvider);
      setState(() {
        _tagResults.removeWhere((r) => r['id'] == user['id']);
        _tagCtrl.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('@${user['tag']} added to squad ✈️'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed to add — ${humanizeError(e)}')),
        );
      }
    }
  }

  String get _inviteLink =>
      'https://gettripsquad.com/join/?t=${_trip?.inviteToken ?? '…'}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: TSColors.lime));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TSTextStyles.body(color: TSColors.coral)));
    }

    // v1.1 — solo trips skip the invite UI entirely. Once the trip
    // is created, jump straight into the trip space.
    if (_trip != null && _trip!.mode == TripMode.solo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement('/trip/${_trip!.id}/space');
        }
      });
      return const Center(child: CircularProgressIndicator(color: TSColors.lime));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          const Text('🔗', style: TextStyle(fontSize: 52))
              .animate().fadeIn().scale(begin: const Offset(0.5, 0.5)),

          const SizedBox(height: 16),

          Text("trip's ready!", style: TSTextStyles.heading(size: 26),
            textAlign: TextAlign.center)
              .animate().fadeIn(delay: 150.ms),
          Text("invite your squad \u{1F517}",
            style: TSTextStyles.heading(size: 26, color: TSColors.lime)
                .copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center)
              .animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            'share this link. your squad fills it in on their browser — no app needed.',
            style: TSTextStyles.body(),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 24),

          // ── Tag search ──────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'know their tag? add them directly 👇',
              style: TSTextStyles.caption(color: TSColors.muted),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('@', style: TSTextStyles.heading(size: 20, color: TSColors.lime)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                style: TSTextStyles.body(color: TSColors.text, size: 15),
                decoration: InputDecoration(
                  hintText: 'search tag...',
                  hintStyle: TSTextStyles.body(color: TSColors.muted, size: 15),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: TSSpacing.sm, vertical: 10),
                ),
                cursorColor: TSColors.lime,
                onChanged: _searchTag,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(
                    color: TSColors.lime, strokeWidth: 2),
              ),
            ),
          ..._tagResults.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: TSSpacing.md, vertical: 10),
              decoration: BoxDecoration(
                color: TSColors.s2,
                borderRadius: TSRadius.sm,
                border: Border.all(color: TSColors.border),
              ),
              child: Row(children: [
                Text(r['emoji'] ?? '😎', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['nickname'] ?? '',
                          style: TSTextStyles.title(size: 13)),
                      Text('@${r['tag'] ?? ''}',
                          style: TSTextStyles.caption(color: TSColors.muted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _addByTag(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TSColors.limeDim(0.12),
                      borderRadius: TSRadius.sm,
                      border: Border.all(color: TSColors.limeDim(0.30)),
                    ),
                    child: Text('add',
                        style: TSTextStyles.label(color: TSColors.lime)),
                  ),
                ),
              ]),
            ),
          )),
          const SizedBox(height: 16),

          // Link card
          Container(
            padding: const EdgeInsets.all(TSSpacing.md),
            decoration: BoxDecoration(
              color: TSColors.s2,
              borderRadius: TSRadius.md,
              border: Border.all(color: TSColors.limeDim(0.30)),
            ),
            child: Row(children: [
              const Text('🌐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('invite link', style: TSTextStyles.label()),
                  Text(_inviteLink,
                    style: TSTextStyles.body(
                        color: TSColors.lime, size: 12, weight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                ],
              )),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _inviteLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 2)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TSColors.limeDim(0.12),
                    borderRadius: TSRadius.sm,
                    border: Border.all(color: TSColors.limeDim(0.30)),
                  ),
                  child: Text('Copy', style: TSTextStyles.label(color: TSColors.lime)),
                ),
              ),
            ]),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          // Share button — opens native share sheet
          Builder(builder: (ctx) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              TSHaptics.medium();
              final box = ctx.findRenderObject() as RenderBox?;
              final origin = box != null
                  ? box.localToGlobal(Offset.zero) & box.size
                  : null;
              await Share.share(
                'join my trip on TripSquad! 🌍✈️\n$_inviteLink',
                sharePositionOrigin: origin,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: TSColors.lime,
                borderRadius: TSRadius.full,
                boxShadow: [
                  BoxShadow(color: TSColors.limeDim(0.3), blurRadius: 16),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📤', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('share invite link',
                    style: TSTextStyles.title(color: TSColors.bg, size: 15)),
                ],
              ),
            ),
          )).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 8),

          Text('link expires in 7 days',
            style: TSTextStyles.caption(), textAlign: TextAlign.center),

          const SizedBox(height: 28),

          TSButton(
            label: '↗ invite your squad',
            onTap: () {
              ref.read(tripCreationProvider.notifier).reset();
              // pushReplacement keeps Home in the nav stack beneath,
              // so the chevron in Invite Ceremony can pop to Home.
              context.pushReplacement('/trip/${_trip!.id}/invite');
            },
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 10),

          TSButton(
            label: 'view trip →',
            variant: TSButtonVariant.outline,
            onTap: () {
              ref.read(tripCreationProvider.notifier).reset();
              context.pushReplacement('/trip/${_trip!.id}/space');
            },
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 12),

          TSButton(
            label: 'back to home',
            variant: TSButtonVariant.ghost,
            onTap: () {
              ref.read(tripCreationProvider.notifier).reset();
              context.go('/home');
            },
          ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }
}

class _ShareBtn extends StatelessWidget {
  const _ShareBtn(this.emoji, this.label, this.link);
  final String emoji;
  final String label;
  final String link;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Share.share(
      ('Join my trip on TripSquad! 🌍\n$link'),
    ),
    child: Container(
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: TSRadius.sm,
        border: Border.all(color: TSColors.border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(label, style: TSTextStyles.label(size: 11)),
      ]),
    ),
  );
}

// SectionLabel is defined in widgets.dart — use that one
