import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/widgets.dart';
import 'plan_detail_sheet.dart';

/// Day-by-day itinerary timeline with realtime activity rows, tap-to-detail
/// sheet, squad notes per card, photo thumbnails, add-activity per day.
class PlanTab extends ConsumerStatefulWidget {
  const PlanTab({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends ConsumerState<PlanTab> {
  bool _generating = false;
  String _typeFilter = 'all'; // all | activity | hotel | restaurant

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      // Go through the global aIGenerationProvider so the persistent
      // "scout's cooking" banner in TripSpace shows across tab switches.
      await ref
          .read(aIGenerationProvider.notifier)
          .generateItinerary(widget.trip.id);
      final genState = ref.read(aIGenerationProvider);
      if (genState.status == AIGenStatus.error) {
        throw Exception(genState.errorMessage ?? 'generation failed');
      }
      TSHaptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itineraryStreamProvider(widget.trip.id));

    return itemsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: TSColors.lime)),
      error: (e, _) => Center(child: Text(humanizeError(e))),
      data: (items) {
        if (items.isEmpty) {
          return _Empty(onGenerate: _generate, generating: _generating);
        }

        final me = Supabase.instance.client.auth.currentUser?.id;
        final isHost = me != null && me == widget.trip.hostId;
        // Trip status OR past-start-date gates rating UI — so someone who
        // forgot to flip to `live` can still rate once the trip has begun.
        final startDate = widget.trip.startDate;
        final hasStarted = startDate != null &&
            !startDate.isAfter(DateTime.now());
        final canRate = widget.trip.status == TripStatus.live ||
            widget.trip.status == TripStatus.completed ||
            hasStarted;
        final nonRejected =
            items.where((a) => a.status != 'rejected').toList();
        final visibleItems = _typeFilter == 'all'
            ? nonRejected
            : nonRejected.where((a) => a.itemType == _typeFilter).toList();

        // Counts per type for the filter chips
        final typeCounts = <String, int>{
          'activity': 0,
          'hotel': 0,
          'restaurant': 0,
        };
        for (final a in nonRejected) {
          typeCounts[a.itemType] = (typeCounts[a.itemType] ?? 0) + 1;
        }

        // Group by day
        final byDay = <int, List<ItineraryActivity>>{};
        for (final a in visibleItems) {
          byDay.putIfAbsent(a.dayNumber, () => []).add(a);
        }
        final dayNumbers = byDay.keys.toList()..sort();

        // Running totals — only approved counts toward cost
        int tripTotalCents = 0;
        for (final a in visibleItems) {
          if (a.status == 'approved') {
            tripTotalCents += (a.estimatedCostCents ?? 0);
          }
        }
        final pendingCount =
            visibleItems.where((a) => a.status == 'proposed').length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            _TripHeader(trip: widget.trip, tripTotalCents: tripTotalCents),
            if (pendingCount > 0) ...[
              const SizedBox(height: 10),
              _PendingBanner(count: pendingCount, isHost: isHost),
            ],
            const SizedBox(height: 10),
            _AskScoutRow(trip: widget.trip),
            const SizedBox(height: 12),
            _TypeFilterRow(
              current: _typeFilter,
              counts: typeCounts,
              onChange: (t) => setState(() => _typeFilter = t),
            ),
            const SizedBox(height: 16),
            if (dayNumbers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    _typeFilter == 'hotel'
                        ? 'no hotels yet — add one below ✦'
                        : _typeFilter == 'restaurant'
                            ? 'no restaurants yet — add one below ✦'
                            : 'nothing here yet',
                    style: TSTextStyles.body(color: TSColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            for (final day in dayNumbers) ...[
              _DayHeader(
                day: day,
                tripStartDate: widget.trip.startDate,
                activities: byDay[day]!,
              ),
              for (int i = 0; i < byDay[day]!.length; i++)
                _ActivityCard(
                  activity: byDay[day]![i],
                  trip: widget.trip,
                  isHost: isHost,
                  meUid: me,
                  canRate: canRate,
                ).animate().fadeIn(delay: (i * 60).ms),
              _AddActivityButton(
                tripId: widget.trip.id,
                dayNumber: day,
                isHost: isHost,
                defaultType: _typeFilter == 'all' ? 'activity' : _typeFilter,
              ),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
    );
  }
}

class _TripHeader extends ConsumerStatefulWidget {
  const _TripHeader({required this.trip, required this.tripTotalCents});
  final Trip trip;
  final int tripTotalCents;

  @override
  ConsumerState<_TripHeader> createState() => _TripHeaderState();
}

class _TripHeaderState extends ConsumerState<_TripHeader> {
  bool _refreshing = false;

  Future<void> _refreshPhotos({bool overwrite = false}) async {
    setState(() => _refreshing = true);
    TSHaptics.medium();
    try {
      final result = await ref
          .read(itineraryServiceProvider)
          .refreshPhotos(widget.trip.id, overwrite: overwrite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.updated > 0
                ? 'refreshed ${result.updated} photos ✦'
                : 'no photos to refresh'),
            backgroundColor: TSColors.lime,
          ),
        );
      }
      TSHaptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _openChangeDestinationSheet() async {
    // Pull the original trip options so host can re-pick from them
    final options = await Supabase.instance.client
        .from('trip_options')
        .select('id, destination, country, flag')
        .eq('trip_id', widget.trip.id)
        .order('compatibility_score', ascending: false);
    if (!mounted) return;
    final current = widget.trip.selectedDestination;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChangeDestinationSheet(
        tripId: widget.trip.id,
        currentDestination: current,
        voteOptions: List<Map<String, dynamic>>.from(options as List),
        onChanged: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('destination changed ✦ squad notified',
                  style: TSTextStyles.body(color: TSColors.bg)),
              backgroundColor: TSColors.lime,
            ),
          );
        },
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TSColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 20)),
              title: Text('fill missing photos',
                  style: TSTextStyles.body()),
              subtitle: Text('backfill activities without a photo',
                  style: TSTextStyles.caption(color: TSColors.muted)),
              onTap: () {
                Navigator.pop(sheet);
                _refreshPhotos();
              },
            ),
            const Divider(color: TSColors.border, height: 1),
            ListTile(
              leading: const Text('🔄', style: TextStyle(fontSize: 20)),
              title:
                  Text('refresh all photos', style: TSTextStyles.body()),
              subtitle: Text('pull new photos for every activity',
                  style: TSTextStyles.caption(color: TSColors.muted)),
              onTap: () {
                Navigator.pop(sheet);
                _refreshPhotos(overwrite: true);
              },
            ),
            const Divider(color: TSColors.border, height: 1),
            // Host-only: change destination after voting/reveal
            if (Supabase.instance.client.auth.currentUser?.id ==
                widget.trip.hostId)
              ListTile(
                leading: const Text('📍', style: TextStyle(fontSize: 20)),
                title: Text('change destination',
                    style: TSTextStyles.body(color: TSColors.gold)),
                subtitle: Text('swap the trip — clears current itinerary',
                    style: TSTextStyles.caption(color: TSColors.muted)),
                onTap: () {
                  Navigator.pop(sheet);
                  _openChangeDestinationSheet();
                },
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TSCard(
      borderColor: TSColors.limeDim(0.25),
      child: Row(children: [
        Text(widget.trip.selectedFlag ?? '🌍',
            style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.trip.selectedDestination == null
                  ? null
                  : () {
                      TSHaptics.light();
                      final slug = Uri.encodeComponent(
                          widget.trip.selectedDestination!);
                      context.push('/destination/$slug');
                    },
              child: Row(children: [
                Flexible(
                  child: Text(
                    widget.trip.selectedDestination ?? widget.trip.name,
                    style: TSTextStyles.heading(size: 20),
                  ),
                ),
                if (widget.trip.selectedDestination != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.north_east_rounded,
                      size: 16, color: TSColors.lime),
                ],
              ]),
            ),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [
              if (widget.trip.durationDays != null)
                TSPill('${widget.trip.durationDays} days',
                    variant: TSPillVariant.muted, small: true),
              if (widget.tripTotalCents > 0)
                TSPill(
                    '~\$${(widget.tripTotalCents / 100).toStringAsFixed(0)}/pp',
                    variant: TSPillVariant.lime, small: true),
            ]),
          ]),
        ),
        IconButton(
          icon: _refreshing
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: TSColors.lime,
                  ),
                )
              : const Icon(Icons.more_horiz_rounded, color: TSColors.muted),
          onPressed: _refreshing ? null : _showMenu,
        ),
      ]),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.tripStartDate,
    required this.activities,
  });
  final int day;
  final DateTime? tripStartDate;
  final List<ItineraryActivity> activities;

  @override
  Widget build(BuildContext context) {
    final date = tripStartDate?.add(Duration(days: day - 1));
    final dayTotal = activities.fold<int>(
        0, (acc, a) => acc + (a.estimatedCostCents ?? 0));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        TSPill('Day $day', variant: TSPillVariant.lime, small: true),
        const SizedBox(width: 10),
        if (date != null)
          Text(_fmtDate(date), style: TSTextStyles.title(size: 14)),
        const Spacer(),
        if (dayTotal > 0)
          Text('\$${(dayTotal / 100).toStringAsFixed(0)}',
              style: TSTextStyles.caption(color: TSColors.muted)),
      ]),
    );
  }

  String _fmtDate(DateTime d) {
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[d.weekday - 1]} · ${months[d.month - 1]} ${d.day}';
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({
    required this.activity,
    required this.trip,
    required this.isHost,
    required this.meUid,
    required this.canRate,
  });
  final ItineraryActivity activity;
  final Trip trip;
  final bool isHost;
  final String? meUid;
  final bool canRate;

  static const _typeEmoji = {
    'activity': '📍',
    'hotel': '🛏️',
    'restaurant': '🍽️',
  };

  static const _timeEmoji = {
    'morning': '🌅',
    'afternoon': '☀️',
    'evening': '🌆',
    'night': '🌙',
  };

  static const _timeColors = {
    'morning': TSColors.gold,
    'afternoon': TSColors.lime,
    'evening': TSColors.purple,
    'night': TSColors.blue,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tColor = _timeColors[activity.timeOfDay] ?? TSColors.muted;
    final isProposed = activity.status == 'proposed';
    final isMine = meUid != null && activity.proposedBy == meUid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          TSHaptics.light();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: TSColors.s1,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => PlanDetailSheet(
              activity: activity,
              trip: trip,
            ),
          );
        },
        child: TSCard(
          padding: EdgeInsets.zero,
          borderColor: isProposed
              ? TSColors.goldDim(0.5)
              : null,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: activity.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: TSColors.s2),
                        errorWidget: (_, __, ___) =>
                            Container(color: TSColors.s2),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            '${_typeEmoji[activity.itemType] ?? '📍'} ${activity.itemType.toUpperCase()}',
                            style: TSTextStyles.label(
                                color: _typeColor(activity.itemType), size: 10),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_timeEmoji[activity.timeOfDay] ?? ''} ${activity.timeOfDay}',
                            style: TSTextStyles.label(color: tColor, size: 10),
                          ),
                          const Spacer(),
                          if (isProposed)
                            TSPill('⏳ proposed',
                                variant: TSPillVariant.gold, small: true)
                          else if (activity.bookedAt != null)
                            TSPill('booked ✓',
                                variant: TSPillVariant.lime, small: true)
                          else if (activity.bookingUrl != null)
                            TSPill('book ahead',
                                variant: TSPillVariant.teal, small: true),
                        ]),
                        const SizedBox(height: 6),
                        Text(activity.title,
                            style: TSTextStyles.heading(size: 16)),
                        if (activity.description != null) ...[
                          const SizedBox(height: 4),
                          Text(activity.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TSTextStyles.body(
                                  size: 13, color: TSColors.text2)),
                        ],
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          if (activity.location != null)
                            _Chip(icon: '📍', text: activity.location!),
                          if (activity.estimatedCostCents != null)
                            _Chip(
                                icon: '💸',
                                text:
                                    '\$${(activity.estimatedCostCents! / 100).toStringAsFixed(0)}'),
                        ]),
                        // Host review controls on proposed items
                        if (isProposed && isHost) ...[
                          const SizedBox(height: 12),
                          const Divider(color: TSColors.border, height: 1),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: _ReviewBtn(
                                label: '✓ approve',
                                color: TSColors.lime,
                                onTap: () async {
                                  TSHaptics.success();
                                  await ref
                                      .read(itineraryServiceProvider)
                                      .approveProposal(activity.id);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ReviewBtn(
                                label: '✕ reject',
                                color: TSColors.coral,
                                onTap: () async {
                                  TSHaptics.medium();
                                  await ref
                                      .read(itineraryServiceProvider)
                                      .rejectProposal(activity.id);
                                },
                              ),
                            ),
                          ]),
                        ],
                        // Rate row — only once trip is live / completed
                        if (canRate && !isProposed) ...[
                          const SizedBox(height: 10),
                          _RateRow(itemId: activity.id, meUid: meUid),
                        ],
                        // Proposer can withdraw their own pending item
                        if (isProposed && isMine && !isHost) ...[
                          const SizedBox(height: 10),
                          Row(mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                            TextButton.icon(
                              onPressed: () async {
                                TSHaptics.medium();
                                await ref
                                    .read(itineraryServiceProvider)
                                    .deleteActivity(activity.id);
                              },
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 14, color: TSColors.muted),
                              label: Text('withdraw',
                                  style: TSTextStyles.caption(
                                      color: TSColors.muted)),
                            ),
                          ]),
                        ],
                      ]),
                ),
              ]),
        ),
      ),
    );
  }
}

/// Quick-ask Scout row — preset prompts tailored to the current
/// trip. Tap → Scout answers inline in trip chat via the existing
/// `askInTrip` path. Keeps the whole squad in sync instead of
/// each person asking Scout separately.
class _AskScoutRow extends ConsumerStatefulWidget {
  const _AskScoutRow({required this.trip});
  final Trip trip;

  @override
  ConsumerState<_AskScoutRow> createState() => _AskScoutRowState();
}

class _AskScoutRowState extends ConsumerState<_AskScoutRow> {
  bool _busy = false;

  Future<void> _ask(String prompt) async {
    if (_busy) return;
    setState(() => _busy = true);
    TSHaptics.ctaTap();
    try {
      await ref.read(scoutServiceProvider).askInTrip(
            tripId: widget.trip.id,
            content: prompt,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('scout replied in chat 🧭',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.trip.selectedDestination ?? widget.trip.name;
    final prompts = [
      ('🍽️', 'top 5 restaurants in $dest'),
      ('🏛️', 'must-see things in $dest'),
      ('🌃', 'best nightlife in $dest'),
      ('💰', 'budget tips for $dest'),
      ('🎒', 'what should we pack for $dest?'),
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Align(
              alignment: Alignment.center,
              child: Text('ask scout →',
                  style: TSTextStyles.label(
                      color: TSColors.muted, size: 10)),
            );
          }
          final (emoji, prompt) = prompts[i - 1];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _busy ? null : () => _ask(prompt),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TSColors.s2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TSColors.limeDim(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(prompt.split('in').first.trim(),
                    style: TSTextStyles.caption(color: TSColors.text)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final String icon, text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text(text,
            style: TSTextStyles.caption(color: TSColors.text2)),
      ]),
    );
  }
}

Color _typeColor(String type) {
  switch (type) {
    case 'hotel':      return TSColors.blue;
    case 'restaurant': return TSColors.gold;
    default:           return TSColors.lime;
  }
}

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({
    required this.current,
    required this.counts,
    required this.onChange,
  });
  final String current;
  final Map<String, int> counts;
  final void Function(String) onChange;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _chip('all', '✨', total),
        const SizedBox(width: 6),
        _chip('activity', '📍', counts['activity'] ?? 0),
        const SizedBox(width: 6),
        _chip('hotel', '🛏️', counts['hotel'] ?? 0),
        const SizedBox(width: 6),
        _chip('restaurant', '🍽️', counts['restaurant'] ?? 0),
      ]),
    );
  }

  Widget _chip(String type, String emoji, int count) {
    final selected = current == type;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TSHaptics.light();
        onChange(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? TSColors.limeDim(0.12) : TSColors.s2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? TSColors.lime : TSColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(type == 'all' ? 'all' : type,
              style: TSTextStyles.caption(
                  color: selected ? TSColors.lime : TSColors.text)),
          const SizedBox(width: 5),
          Text('$count',
              style: TSTextStyles.caption(color: TSColors.muted)),
        ]),
      ),
    );
  }
}

class _RateRow extends ConsumerStatefulWidget {
  const _RateRow({required this.itemId, required this.meUid});
  final String itemId;
  final String? meUid;

  @override
  ConsumerState<_RateRow> createState() => _RateRowState();
}

class _RateRowState extends ConsumerState<_RateRow> {
  int? _myThumb;
  int _up = 0, _down = 0, _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await ref
          .read(ratingsServiceProvider)
          .myItemThumb(widget.itemId);
      final summary = await ref
          .read(ratingsServiceProvider)
          .itemSummary(widget.itemId);
      if (!mounted) return;
      setState(() {
        _myThumb = mine;
        _up = summary.up;
        _down = summary.down;
        _total = summary.total;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rate(int thumb) async {
    TSHaptics.selection();
    final wasMine = _myThumb;
    // Optimistic update
    setState(() {
      if (_myThumb == thumb) {
        _myThumb = null;
        if (thumb == 1) _up--;
        if (thumb == -1) _down--;
        _total = (_total - 1).clamp(0, 9999);
      } else {
        if (wasMine == 1) _up--;
        if (wasMine == -1) _down--;
        _myThumb = thumb;
        if (thumb == 1) _up++;
        if (thumb == -1) _down++;
        if (wasMine == null) _total++;
      }
    });
    try {
      if (_myThumb == null) {
        await ref
            .read(ratingsServiceProvider)
            .removeItemRating(widget.itemId);
      } else {
        await ref
            .read(ratingsServiceProvider)
            .rateItem(itemId: widget.itemId, thumb: _myThumb!);
      }
    } catch (e) {
      // revert
      if (mounted) {
        setState(() => _load());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 24);
    final approval = _total > 0 ? (_up * 100 ~/ _total) : 0;
    return Row(children: [
      _thumb(1),
      const SizedBox(width: 8),
      _thumb(-1),
      const Spacer(),
      if (_total >= 3)
        Text('$approval% 👍 · $_total',
            style: TSTextStyles.caption(color: TSColors.muted))
      else if (_total > 0)
        Text('$_total rating${_total == 1 ? '' : 's'}',
            style: TSTextStyles.caption(color: TSColors.muted)),
    ]);
  }

  Widget _thumb(int thumb) {
    final selected = _myThumb == thumb;
    final color = thumb == 1 ? TSColors.lime : TSColors.coral;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _rate(thumb),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : TSColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          thumb == 1 ? '👍' : '👎',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _AddActivityButton extends StatelessWidget {
  const _AddActivityButton({
    required this.tripId,
    required this.dayNumber,
    required this.isHost,
    required this.defaultType,
  });
  final String tripId;
  final int dayNumber;
  final bool isHost;
  final String defaultType;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TSHaptics.light();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: TSColors.s1,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _AddActivitySheet(
            tripId: tripId,
            dayNumber: dayNumber,
            defaultType: defaultType,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: TSRadius.md,
          border: Border.all(
            color: TSColors.border2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_rounded, size: 18, color: TSColors.muted),
          const SizedBox(width: 6),
          Text(
              isHost
                  ? 'add activity to day $dayNumber'
                  : 'propose an activity for day $dayNumber',
              style: TSTextStyles.caption(color: TSColors.muted)),
        ]),
      ),
    );
  }
}

class _AddActivitySheet extends ConsumerStatefulWidget {
  const _AddActivitySheet({
    required this.tripId,
    required this.dayNumber,
    required this.defaultType,
  });
  final String tripId;
  final int dayNumber;
  final String defaultType;

  @override
  ConsumerState<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends ConsumerState<_AddActivitySheet> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  String _timeOfDay = 'morning';
  late String _itemType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _itemType = widget.defaultType;
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(itineraryServiceProvider).addActivity(
            tripId: widget.tripId,
            dayNumber: widget.dayNumber,
            title: title,
            timeOfDay: _timeOfDay,
            itemType: _itemType,
            location: _locationCtrl.text.trim().isEmpty
                ? null
                : _locationCtrl.text.trim(),
            estimatedCostCents: int.tryParse(_costCtrl.text.trim()) != null
                ? int.parse(_costCtrl.text.trim()) * 100
                : null,
          );
      TSHaptics.success();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: TSColors.border2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text('add to day ${widget.dayNumber}',
            style: TSTextStyles.heading(size: 18)),
        const SizedBox(height: 12),
        // Type picker
        Wrap(spacing: 6, children: [
          for (final t in const [
            (kind: 'activity',   emoji: '📍', label: 'activity'),
            (kind: 'hotel',      emoji: '🛏️', label: 'hotel'),
            (kind: 'restaurant', emoji: '🍽️', label: 'restaurant'),
          ])
            ChoiceChip(
              label: Text('${t.emoji} ${t.label}',
                  style: TSTextStyles.label()),
              selected: _itemType == t.kind,
              onSelected: (_) => setState(() => _itemType = t.kind),
              selectedColor: TSColors.lime,
              backgroundColor: TSColors.s2,
            ),
        ]),
        const SizedBox(height: 12),
        _Input(
          controller: _titleCtrl,
          hint: _itemType == 'hotel'
              ? 'hotel name'
              : _itemType == 'restaurant'
                  ? 'restaurant name'
                  : 'what are you doing?',
        ),
        const SizedBox(height: 10),
        _Input(controller: _locationCtrl, hint: 'location (optional)'),
        const SizedBox(height: 10),
        _Input(
          controller: _costCtrl,
          hint: 'estimated cost per person \$ (optional)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Text('time of day',
              style: TSTextStyles.caption(color: TSColors.muted)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          for (final t in ['morning', 'afternoon', 'evening', 'night'])
            ChoiceChip(
              label: Text(t, style: TSTextStyles.label()),
              selected: _timeOfDay == t,
              onSelected: (_) => setState(() => _timeOfDay = t),
              selectedColor: TSColors.lime,
              backgroundColor: TSColors.s2,
            ),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: TSButton(
            label: _saving ? 'adding…' : 'add ✦',
            loading: _saving,
            onTap: _saving ? () {} : _save,
          ),
        ),
      ]),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TSTextStyles.body(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TSTextStyles.body(color: TSColors.muted),
        filled: true,
        fillColor: TSColors.s2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onGenerate, required this.generating});
  final VoidCallback onGenerate;
  final bool generating;

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return const TSScoutLoading(
        messages: TSScoutLoading.itineraryMessages,
        subtitle: 'scout is building your day-by-day plan',
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🗺️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('no itinerary yet', style: TSTextStyles.heading(size: 20)),
          const SizedBox(height: 8),
          Text('let scout build your day-by-day plan ✦',
              style: TSTextStyles.body(color: TSColors.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TSButton(
            label: 'generate with scout 🧭',
            onTap: onGenerate,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Change destination sheet (host only)
// ─────────────────────────────────────────────────────────────
class _ChangeDestinationSheet extends ConsumerStatefulWidget {
  const _ChangeDestinationSheet({
    required this.tripId,
    required this.currentDestination,
    required this.voteOptions,
    required this.onChanged,
  });
  final String tripId;
  final String? currentDestination;
  final List<Map<String, dynamic>> voteOptions;
  final VoidCallback onChanged;

  @override
  ConsumerState<_ChangeDestinationSheet> createState() =>
      _ChangeDestinationSheetState();
}

class _ChangeDestinationSheetState
    extends ConsumerState<_ChangeDestinationSheet> {
  final _customCtrl = TextEditingController();
  final _flagCtrl = TextEditingController();
  bool _saving = false;
  Timer? _resolveDebounce;
  ResolvedDestination? _resolved;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _customCtrl.addListener(_onCustomChanged);
  }

  void _onCustomChanged() {
    final text = _customCtrl.text.trim();
    _resolveDebounce?.cancel();
    if (text.length < 2) {
      if (_resolved != null) setState(() => _resolved = null);
      return;
    }
    _resolveDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _resolving = true);
      try {
        final r = await ref
            .read(destinationResolverProvider)
            .resolve(text);
        if (!mounted) return;
        setState(() {
          _resolved = r;
          _resolving = false;
          // Pre-fill flag if user hasn't typed one
          if (r.valid && r.flag != null && _flagCtrl.text.trim().isEmpty) {
            _flagCtrl.text = r.flag!;
          }
        });
      } catch (_) {
        if (mounted) setState(() => _resolving = false);
      }
    });
  }

  Future<void> _confirm({
    required String destination,
    String? flag,
    String? country,
  }) async {
    if (destination.trim().isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TSColors.s2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('change to $destination?',
            style: TSTextStyles.heading(size: 18)),
        content: Text(
          'this will clear your current itinerary. packing list, chat, and squad stay the same.',
          style: TSTextStyles.body(color: TSColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel',
                style: TSTextStyles.title(color: TSColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('change destination',
                style: TSTextStyles.title(color: TSColors.lime)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(tripServiceProvider).changeDestination(
            tripId: widget.tripId,
            destination: destination.trim(),
            flag: flag,
            country: country,
            clearItinerary: true,
          );
      TSHaptics.success();
      if (mounted) Navigator.pop(context);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _resolveDebounce?.cancel();
    _customCtrl.removeListener(_onCustomChanged);
    _customCtrl.dispose();
    _flagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherOptions = widget.voteOptions
        .where((o) =>
            (o['destination'] as String?)?.toLowerCase() !=
            widget.currentDestination?.toLowerCase())
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: TSColors.border2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text('change destination',
            style: TSTextStyles.heading(size: 20)),
        const SizedBox(height: 4),
        Text(
          'currently: ${widget.currentDestination ?? "none"}',
          style: TSTextStyles.caption(color: TSColors.muted),
        ),
        const SizedBox(height: 20),

        if (otherOptions.isNotEmpty) ...[
          const SectionLabel(label: 'other options from your vote'),
          const SizedBox(height: 8),
          for (final o in otherOptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _saving
                    ? null
                    : () {
                        final dest = o['destination'] as String;
                        final raw = o['flag'] as String?;
                        final resolvedFlag = (raw != null && raw.trim().isNotEmpty)
                            ? raw
                            : (TSQuickDestinations.flagFor(dest) ?? '🌍');
                        _confirm(
                          destination: dest,
                          flag: resolvedFlag,
                          country: o['country'] as String?,
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TSColors.s2,
                    borderRadius: TSRadius.sm,
                    border: Border.all(color: TSColors.border),
                  ),
                  child: Row(children: [
                    Text((o['flag'] as String?) ?? '🌍',
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o['destination'] as String,
                                style: TSTextStyles.body(size: 15)),
                            if (o['country'] != null)
                              Text(o['country'] as String,
                                  style: TSTextStyles.caption(
                                      color: TSColors.muted)),
                          ]),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: TSColors.muted, size: 14),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],

        const SectionLabel(label: 'or pick something new'),
        const SizedBox(height: 8),
        _Input(controller: _customCtrl, hint: 'destination (e.g. Lisbon)'),
        // Resolver preview — shown after debounce
        if (_resolving)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: TSColors.lime),
              ),
              const SizedBox(width: 8),
              Text('scout is resolving…',
                  style: TSTextStyles.caption(color: TSColors.muted)),
            ]),
          )
        else if (_resolved != null) ...[
          const SizedBox(height: 6),
          if (_resolved!.valid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TSColors.limeDim(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TSColors.limeDim(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_resolved!.flag ?? '🌍',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${_resolved!.canonical ?? ""}, ${_resolved!.country ?? ""}',
                    style: TSTextStyles.caption(color: TSColors.lime),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TSColors.coralDim(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TSColors.coralDim(0.3)),
              ),
              child: Text(
                '⚠️ scout doesn\'t recognize that one — double-check the spelling',
                style: TSTextStyles.caption(color: TSColors.coral),
              ),
            ),
        ],
        const SizedBox(height: 8),
        _Input(controller: _flagCtrl, hint: 'flag emoji (optional) 🇵🇹'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TSButton(
            label: _saving ? 'changing…' : 'change to custom ✦',
            loading: _saving,
            onTap: _saving
                ? () {}
                : () {
                    final typedFlag = _flagCtrl.text.trim();
                    // Prefer typed flag; otherwise look up from destination
                    // name; fall back to 🌍 globe.
                    final resolvedFlag = typedFlag.isNotEmpty
                        ? typedFlag
                        : (TSQuickDestinations.flagFor(_customCtrl.text) ??
                            '🌍');
                    _confirm(
                      destination: _customCtrl.text,
                      flag: resolvedFlag,
                    );
                  },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Pending proposals banner
// ─────────────────────────────────────────────────────────────
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count, required this.isHost});
  final int count;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TSColors.goldDim(0.1),
        borderRadius: TSRadius.sm,
        border: Border.all(color: TSColors.goldDim(0.4)),
      ),
      child: Row(children: [
        const Text('⏳', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isHost
                ? '$count ${count == 1 ? 'proposal' : 'proposals'} waiting for your review'
                : '$count ${count == 1 ? 'proposal' : 'proposals'} pending host review',
            style: TSTextStyles.body(color: TSColors.gold, size: 13),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Host approve / reject buttons
// ─────────────────────────────────────────────────────────────
class _ReviewBtn extends StatelessWidget {
  const _ReviewBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: TSRadius.sm,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TSTextStyles.label(color: color, size: 11)),
      ),
    );
  }
}
