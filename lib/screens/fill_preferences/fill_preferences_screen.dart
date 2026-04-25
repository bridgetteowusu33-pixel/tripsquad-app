import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../widgets/ts_scaffold.dart';

/// In-app preferences form for squad members added via @tag.
/// Mirrors the web invite form (vibes → budget → destinations) but
/// skipping nickname/emoji since the host already set those at add-time
/// (and the member can change them later from their profile).
///
/// On submit, upserts the existing squad_members row to
/// status='submitted' with vibes / budget / destination_prefs filled.
class FillPreferencesScreen extends ConsumerStatefulWidget {
  const FillPreferencesScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<FillPreferencesScreen> createState() =>
      _FillPreferencesScreenState();
}

class _FillPreferencesScreenState
    extends ConsumerState<FillPreferencesScreen> {
  int _step = 0;
  final _selectedVibes = <String>{};
  int _budgetMin = 500;
  int _budgetMax = 2000;
  final _selectedDests = <String>{};
  final _customDestCtrl = TextEditingController();
  bool _saving = false;
  String? _error;
  List<String> _hostShortlist = const [];

  @override
  void initState() {
    super.initState();
    _loadShortlist();
  }

  Future<void> _loadShortlist() async {
    try {
      final row = await Supabase.instance.client
          .from('trips')
          .select('destination_shortlist')
          .eq('id', widget.tripId)
          .maybeSingle();
      if (!mounted || row == null) return;
      final raw = row['destination_shortlist'];
      if (raw is List) {
        setState(() => _hostShortlist = raw.cast<String>());
      }
    } catch (_) {
      // Non-fatal — user can type their own.
    }
  }

  @override
  void dispose() {
    _customDestCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue {
    return switch (_step) {
      0 => _selectedVibes.isNotEmpty && _selectedVibes.length <= 3,
      1 => _budgetMin > 0 && _budgetMax >= _budgetMin,
      2 => _selectedDests.isNotEmpty,
      _ => false,
    };
  }

  Future<void> _submit() async {
    setState(() { _saving = true; _error = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('not signed in');

      // Update the existing squad_members row (created by host via tag)
      // to status=submitted with the user's preferences.
      await Supabase.instance.client
          .from('squad_members')
          .update({
            'status':            MemberStatus.submitted.name,
            'vibes':             _selectedVibes.toList(),
            'budget_min':        _budgetMin,
            'budget_max':        _budgetMax,
            'destination_prefs': _selectedDests.toList(),
            'responded_at':      DateTime.now().toIso8601String(),
          })
          .eq('trip_id', widget.tripId)
          .eq('user_id', uid);

      // Invalidate everything that can still be caching status=invited
      // so the trip card stops routing back here.
      ref.invalidate(myTripsProvider);
      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(squadStreamProvider(widget.tripId));
      TSHaptics.success();
      if (!mounted) return;
      // Land on home — the trip card now shows responded state and the
      // user sees the whole squad's progress. They can tap in whenever.
      context.go('/home');
    } catch (e) {
      setState(() { _error = humanizeError(e); _saving = false; });
      TSHaptics.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));

    return TSScaffold(
      body: SafeArea(
        child: tripAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: TSColors.lime)),
          error: (e, _) => Center(
            child: Text('couldn\'t load trip', style: TSTextStyles.body()),
          ),
          data: (trip) => TSResponsive.content(Column(children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  TSSpacing.md, TSSpacing.sm, TSSpacing.md, TSSpacing.sm),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: const Icon(Icons.close_rounded,
                      color: TSColors.text, size: 22),
                ),
                const Spacer(),
                Text('${_step + 1} of 3',
                    style: TSTextStyles.caption(color: TSColors.muted)),
              ]),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: TSSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('you\'re in ${trip.name} ✈️',
                      style: TSTextStyles.heading(size: 22)),
                  const SizedBox(height: 4),
                  Text(
                    'drop your prefs so the squad can plan something you\'ll actually love',
                    style: TSTextStyles.body(color: TSColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Step body ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _stepBody(),
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    TSSpacing.md, 0, TSSpacing.md, 8),
                child: Text(_error!,
                    style: TSTextStyles.caption(color: TSColors.coral)),
              ),

            // ── Footer ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  TSSpacing.md, 8, TSSpacing.md, TSSpacing.md),
              child: Row(children: [
                if (_step > 0)
                  Expanded(
                    child: TSButton(
                      label: 'back',
                      variant: TSButtonVariant.ghost,
                      onTap: () => setState(() => _step--),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TSButton(
                    label: _step == 2 ? 'submit ✦' : 'next →',
                    onTap: !_canContinue || _saving
                        ? null
                        : _step == 2
                            ? _submit
                            : () => setState(() => _step++),
                    loading: _saving,
                  ),
                ),
              ]),
            ),
          ])),
        ),
      ),
    );
  }

  Widget _stepBody() {
    return Padding(
      key: ValueKey(_step),
      padding: const EdgeInsets.symmetric(horizontal: TSSpacing.md),
      child: switch (_step) {
        0 => _vibesStep(),
        1 => _budgetStep(),
        _ => _destinationsStep(),
      },
    );
  }

  Widget _vibesStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('what\'s your vibe?',
              style: TSTextStyles.title(size: 16)),
          const SizedBox(height: 4),
          Text('pick up to 3',
              style: TSTextStyles.caption(color: TSColors.muted)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in TSVibes.all)
                _VibeChip(
                  label: v.label,
                  emoji: v.emoji,
                  selected: _selectedVibes.contains(v.id),
                  onTap: () {
                    TSHaptics.light();
                    setState(() {
                      if (_selectedVibes.contains(v.id)) {
                        _selectedVibes.remove(v.id);
                      } else if (_selectedVibes.length < 3) {
                        _selectedVibes.add(v.id);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _budgetStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('budget range?', style: TSTextStyles.title(size: 16)),
          const SizedBox(height: 4),
          Text('per person, total trip',
              style: TSTextStyles.caption(color: TSColors.muted)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _BudgetField(
                label: 'min',
                value: _budgetMin,
                onChanged: (v) => setState(() => _budgetMin = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BudgetField(
                label: 'max',
                value: _budgetMax,
                onChanged: (v) => setState(() => _budgetMax = v),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in const [
                (500, 1500),
                (1500, 3000),
                (3000, 6000),
                (6000, 12000),
              ])
                GestureDetector(
                  onTap: () {
                    TSHaptics.light();
                    setState(() {
                      _budgetMin = r.$1;
                      _budgetMax = r.$2;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_budgetMin == r.$1 && _budgetMax == r.$2)
                          ? TSColors.lime.withOpacity(0.15)
                          : TSColors.s2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (_budgetMin == r.$1 && _budgetMax == r.$2)
                            ? TSColors.lime
                            : TSColors.border,
                      ),
                    ),
                    child: Text('\$${r.$1}–\$${r.$2}',
                        style: TSTextStyles.label(size: 12)),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _destinationsStep() {
    final shortlist = _hostShortlist;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('which destinations speak to you?',
              style: TSTextStyles.title(size: 16)),
          const SizedBox(height: 4),
          Text('from the host\'s shortlist, pick any that interest you',
              style: TSTextStyles.caption(color: TSColors.muted)),
          const SizedBox(height: 14),
          if (shortlist.isEmpty)
            Text('the host hasn\'t added a shortlist yet — type one below',
                style: TSTextStyles.caption(color: TSColors.muted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in shortlist)
                  _DestChip(
                    label: d,
                    selected: _selectedDests.contains(d),
                    onTap: () {
                      TSHaptics.light();
                      setState(() {
                        if (_selectedDests.contains(d)) {
                          _selectedDests.remove(d);
                        } else {
                          _selectedDests.add(d);
                        }
                      });
                    },
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Text('or add your own',
              style: TSTextStyles.caption(color: TSColors.muted)),
          const SizedBox(height: 8),
          TSTextField(
            hint: 'e.g. Lisbon, Tokyo',
            controller: _customDestCtrl,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
            onSubmitted: (v) {
              final clean = v.trim();
              if (clean.isEmpty) return;
              setState(() {
                _selectedDests.add(clean);
                _customDestCtrl.clear();
              });
            },
          ),
          if (_selectedDests.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('your picks',
                style: TSTextStyles.caption(color: TSColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in _selectedDests)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: TSColors.lime.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TSColors.lime),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(d,
                          style: TSTextStyles.label(
                              color: TSColors.lime, size: 12)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDests.remove(d)),
                        child: const Icon(Icons.close_rounded,
                            color: TSColors.lime, size: 14),
                      ),
                    ]),
                  ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _VibeChip extends StatelessWidget {
  const _VibeChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? TSColors.lime.withOpacity(0.15) : TSColors.s2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? TSColors.lime : TSColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label,
              style: TSTextStyles.label(
                  color: selected ? TSColors.lime : TSColors.text,
                  size: 13)),
        ]),
      ),
    );
  }
}

class _DestChip extends StatelessWidget {
  const _DestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? TSColors.lime.withOpacity(0.15) : TSColors.s2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? TSColors.lime : TSColors.border),
        ),
        child: Text(label,
            style: TSTextStyles.label(
                color: selected ? TSColors.lime : TSColors.text, size: 13)),
      ),
    );
  }
}

class _BudgetField extends StatelessWidget {
  const _BudgetField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TSTextStyles.caption(color: TSColors.muted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: TSColors.s2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: TSColors.border),
          ),
          child: Row(children: [
            Text('\$', style: TSTextStyles.body(color: TSColors.muted)),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                controller:
                    TextEditingController(text: value.toString())
                      ..selection = TextSelection.collapsed(
                          offset: value.toString().length),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null) onChanged(n);
                },
                style: TSTextStyles.body(size: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
