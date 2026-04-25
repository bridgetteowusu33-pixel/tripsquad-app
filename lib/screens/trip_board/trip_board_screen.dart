import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

class TripBoardScreen extends ConsumerStatefulWidget {
  const TripBoardScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<TripBoardScreen> createState() => _TripBoardScreenState();
}

class _TripBoardScreenState extends ConsumerState<TripBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    final aiState   = ref.watch(aIGenerationProvider);

    return tripAsync.when(
      data: (trip) => Scaffold(
        backgroundColor: TSColors.bg,
        appBar: TSAppBar(
          title: trip.selectedDestination ?? trip.name,
          trailing: _modeBadge(trip.mode),
        ),
        body: Column(children: [
          // Tab bar
          Container(
            color: TSColors.bg,
            child: TabBar(
              controller: _tabs,
              indicatorColor: TSColors.lime,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TSTextStyles.label(size: 11),
              unselectedLabelColor: TSColors.muted,
              labelColor: TSColors.lime,
              tabs: const [
                Tab(text: 'itinerary'),
                Tab(text: 'tips'),
                Tab(text: 'packing'),
                Tab(text: 'chat'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ItineraryTab(trip: trip, aiState: aiState),
                _TipsTab(trip: trip),
                _PackingTab(trip: trip),
                _ChatTab(tripId: widget.tripId),
              ],
            ),
          ),
        ]),
      ),
      loading: () => const Scaffold(
        backgroundColor: TSColors.bg,
        body: Center(child: CircularProgressIndicator(color: TSColors.lime)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: TSColors.bg,
        body: Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _modeBadge(TripMode mode) {
    switch (mode) {
      case TripMode.group:  return const TSPill('👥 Group',  variant: TSPillVariant.lime,   small: true);
      case TripMode.solo:   return const TSPill('🧳 Solo',   variant: TSPillVariant.blue,   small: true);
      case TripMode.match:  return const TSPill('🤝 Match',  variant: TSPillVariant.purple, small: true);
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  ITINERARY TAB
// ─────────────────────────────────────────────────────────────
class _ItineraryTab extends ConsumerStatefulWidget {
  const _ItineraryTab({required this.trip, required this.aiState});
  final Trip trip;
  final AIGenState aiState;

  @override
  ConsumerState<_ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends ConsumerState<_ItineraryTab> {
  List<ItineraryDay> _dbDays = [];
  bool _loadingDb = false;

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    setState(() => _loadingDb = true);
    try {
      final data = await Supabase.instance.client
          .from('itinerary_days')
          .select()
          .eq('trip_id', widget.trip.id)
          .order('day_number', ascending: true);
      if (mounted) {
        final days = <ItineraryDay>[];
        for (final row in (data as List)) {
          try {
            final camel = snakeToCamel(row);
            // Parse items from JSONB safely
            final rawItems = camel['items'] as List? ?? [];
            final items = rawItems.map((item) {
              final m = item is Map<String, dynamic> ? item : <String, dynamic>{};
              return ItineraryItem(
                title: m['title']?.toString() ?? 'Activity',
                timeOfDay: m['timeOfDay']?.toString() ?? m['time_of_day']?.toString() ?? 'morning',
                description: m['description']?.toString(),
                location: m['location']?.toString(),
                estimatedCost: m['estimatedCost']?.toString() ?? m['estimated_cost']?.toString(),
                requiresBooking: m['requiresBooking'] as bool? ?? m['requires_booking'] as bool? ?? false,
                soloTip: m['soloTip']?.toString() ?? m['solo_tip']?.toString(),
              );
            }).toList();
            // Parse packing from JSONB safely
            final rawPacking = camel['packing'] as List? ?? [];
            final packing = rawPacking.map((p) {
              final m = p is Map<String, dynamic> ? p : <String, dynamic>{};
              return PackingItem(
                label: m['label']?.toString() ?? '',
                category: m['category']?.toString() ?? '',
              );
            }).toList();
            days.add(ItineraryDay(
              id: camel['id']?.toString() ?? '',
              tripId: camel['tripId']?.toString() ?? widget.trip.id,
              dayNumber: camel['dayNumber'] as int? ?? 0,
              title: camel['title']?.toString() ?? 'Day',
              items: items,
              packingList: packing,
            ));
          } catch (e) {
            debugPrint('SKIP DAY: $e');
          }
        }
        setState(() {
          _dbDays = days;
          _loadingDb = false;
        });
      }
    } catch (e) {
      debugPrint('ITINERARY LOAD ERROR: $e');
      if (mounted) setState(() => _loadingDb = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = widget.aiState;
    final trip = widget.trip;

    if (aiState.status == AIGenStatus.loading || _loadingDb) {
      return _buildGenerating();
    }

    final days = aiState.days.isNotEmpty ? aiState.days : _dbDays;
    if (days.isEmpty) {
      return _buildEmptyItinerary(ref);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(TSSpacing.md),
      itemCount: days.length + 1, // +1 for header card
      itemBuilder: (context, i) {
        if (i == 0) return _HeaderCard(trip: widget.trip);
        final day = days[i - 1];
        return _DaySection(day: day, isSolo: widget.trip.mode == TripMode.solo)
            .animate().fadeIn(delay: ((i - 1) * 80).ms);
      },
    );
  }

  Widget _buildGenerating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [TSColors.lime, TSColors.limeDim(0.2)],
              ),
              boxShadow: [BoxShadow(
                color: TSColors.limeDim(0.3), blurRadius: 32,
              )],
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1800.ms, color: TSColors.limeDim(0.4)),
          const SizedBox(height: 20),
          Text('scout is building your itinerary...',
            style: TSTextStyles.title(), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('scout is building your perfect day-by-day plan.',
            style: TSTextStyles.body(), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyItinerary(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('no itinerary yet', style: TSTextStyles.heading(size: 20)),
            const SizedBox(height: 8),
            Text('let scout build your day-by-day plan.',
              style: TSTextStyles.body(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TSButton(
              label: 'let scout plan it 🧭',
              onTap: () => ref.read(aIGenerationProvider.notifier)
                  .generateItinerary(widget.trip.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TSCard(
        borderColor: TSColors.limeDim(0.22),
        color: const Color(0xFF0F0F1C),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(trip.selectedFlag ?? '✈️', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            TextSpan(text: trip.selectedDestination ?? trip.name,
              style: TSTextStyles.heading(size: 20)),
            if (trip.selectedDestination != null)
              TextSpan(text: ', ', style: TSTextStyles.heading(size: 20)),
          ])),
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: [
            if (trip.durationDays != null)
              TSPill('🧳 ${trip.durationDays} days', variant: TSPillVariant.lime, small: true),
            if (trip.squadMembers.isNotEmpty)
              TSPill('👥 ${trip.squadMembers.length} people', variant: TSPillVariant.muted, small: true),
            if (trip.estimatedBudget != null)
              TSPill('~\$${trip.estimatedBudget}/pp', variant: TSPillVariant.lime, small: true),
          ]),
        ]),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.isSolo});
  final ItineraryDay day;
  final bool isSolo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Day header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            TSPill('Day ${day.dayNumber}',
              variant: isSolo ? TSPillVariant.blue : TSPillVariant.lime,
              small: true),
            const SizedBox(width: 10),
            Text(day.title, style: TSTextStyles.title(size: 14)),
            Expanded(child: Container(
              margin: const EdgeInsets.only(left: 10),
              height: 1,
              color: TSColors.border,
            )),
          ]),
        ),
        ...day.items.map((item) => _ActivityCard(item: item, isSolo: isSolo)),
      ]),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.isSolo});
  final ItineraryItem item;
  final bool isSolo;

  static const _timeColors = {
    'morning':   TSColors.gold,
    'afternoon': TSColors.lime,
    'evening':   TSColors.purple,
    'night':     TSColors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final tColor = _timeColors[item.timeOfDay.toLowerCase()] ?? TSColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TSCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              '${_timeEmoji(item.timeOfDay)} ${item.timeOfDay.toUpperCase()}',
              style: TSTextStyles.label(color: tColor),
            ),
            if (item.requiresBooking == true) ...[
              const Spacer(),
              TSPill('Book ahead →', variant: TSPillVariant.teal, small: true),
            ],
          ]),
          const SizedBox(height: 4),
          Text(item.title, style: TSTextStyles.title(size: 14)),
          if (item.description != null) ...[
            const SizedBox(height: 4),
            Text(item.description!, style: TSTextStyles.body(size: 12)),
          ],
          if (item.estimatedCost != null || item.soloTip != null) ...[
            const SizedBox(height: 8),
            if (item.estimatedCost != null)
              TSPill(item.estimatedCost!, variant: TSPillVariant.muted, small: true),
            if (item.soloTip != null && isSolo) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(TSSpacing.xs),
                decoration: BoxDecoration(
                  color: TSColors.blueDim(0.08),
                  borderRadius: TSRadius.xs,
                  border: Border(left: BorderSide(
                    color: TSColors.blue, width: 2)),
                ),
                child: Text(
                  '✦ Solo tip: ${item.soloTip}',
                  style: TSTextStyles.body(
                    color: TSColors.blue, size: 11, weight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ]),
      ),
    );
  }

  String _timeEmoji(String t) {
    switch (t.toLowerCase()) {
      case 'morning':   return '🌅';
      case 'afternoon': return '☀️';
      case 'evening':   return '🌆';
      case 'night':     return '🌙';
      default:          return '📍';
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  TIPS TAB
// ─────────────────────────────────────────────────────────────
class _TipsTab extends StatelessWidget {
  const _TipsTab({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TSSpacing.md),
      children: [
        _TipCard('💰', 'budget', 'Book accommodation at least 6 weeks ahead for best rates. ${trip.selectedDestination ?? "Your destination"} prices peak in summer.'),
        _TipCard('🛂', 'visa', 'Check visa requirements for all squad nationalities. Most EU destinations allow 90-day stays.'),
        _TipCard('📱', 'data', 'Get an eSIM before you land — it\'s cheaper than roaming. Airalo works great for Europe.'),
        _TipCard('🌡️', 'weather', 'Pack layers. Even summer evenings can be cool. Check weather 1 week before.'),
        _TipCard('🏥', 'health', 'Get travel insurance before you fly. EHIC cards cover EU residents in EU countries.'),
        _TipCard('💳', 'money', 'Wise or Revolut for spending — no fees. Notify your home bank before travelling.'),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard(this.emoji, this.title, this.body);
  final String emoji, title, body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TSCard(child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TSTextStyles.title(size: 13)),
              const SizedBox(height: 4),
              Text(body, style: TSTextStyles.body(size: 12)),
            ],
          )),
        ],
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PACKING TAB
// ─────────────────────────────────────────────────────────────
class _PackingTab extends ConsumerStatefulWidget {
  const _PackingTab({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_PackingTab> createState() => _PackingTabState();
}

class _PackingTabState extends ConsumerState<_PackingTab> {
  final Map<String, bool> _checked = {};

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aIGenerationProvider);
    final items = aiState.days.isNotEmpty
        ? aiState.days.first.packingList
        : <PackingItem>[];

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TSSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎒', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text('no packing list yet', style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 8),
              Text('generate your itinerary first, then the packing list auto-generates.',
                style: TSTextStyles.body(), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<PackingItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(TSSpacing.md),
      children: grouped.entries.map((e) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(e.key.toUpperCase(), style: TSTextStyles.label()),
          ),
          ...e.value.map((item) {
            final checked = _checked[item.id ?? item.label] ?? item.packed;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: GestureDetector(
                onTap: () => setState(() => _checked[item.id ?? item.label] = !checked),
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: checked ? TSColors.teal : Colors.transparent,
                    borderRadius: TSRadius.xs,
                    border: Border.all(
                      color: checked ? TSColors.teal : TSColors.border2,
                    ),
                  ),
                  child: checked
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              title: Text(
                item.label,
                style: TSTextStyles.body(
                  size: 14,
                  color: checked ? TSColors.muted : TSColors.text2,
                ).copyWith(
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            );
          }),
          const Divider(height: 1),
        ],
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CHAT TAB (placeholder — full realtime chat)
// ─────────────────────────────────────────────────────────────
class _ChatTab extends StatelessWidget {
  const _ChatTab({required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement full Supabase realtime chat
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('squad chat', style: TSTextStyles.heading(size: 22)),
            const SizedBox(height: 8),
            Text('realtime squad chat coming in v1.1 💬',
              style: TSTextStyles.body(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
