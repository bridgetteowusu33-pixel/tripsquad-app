import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/trip_wrap_overlay.dart';
import '../../widgets/widgets.dart';
import 'tabs/chat_tab.dart';
import 'tabs/status_tab.dart';
import 'tabs/vote_tab.dart';
import 'tabs/plan_tab.dart';
import 'tabs/pack_tab.dart';
import 'tabs/tips_tab.dart';
import 'tabs/squad_tab.dart';
import 'tabs/today_tab.dart';
import 'tabs/memories_tab.dart';
import 'tabs/stamp_tab.dart';

/// Phase-aware container for a trip. The tab set changes as
/// `trip.status` changes — streamed from Supabase so every
/// squad member sees phase transitions in realtime.
class TripSpaceScreen extends ConsumerWidget {
  const TripSpaceScreen({
    super.key,
    required this.tripId,
    this.preferredTab,
  });
  final String tripId;

  /// Tab key (e.g. "chat", "pack", "plan") to land on when the screen
  /// opens. Ignored if the current phase's tab list doesn't include it
  /// — e.g. "pack" during the collecting phase.
  final String? preferredTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripStreamProvider(tripId));

    return tripAsync.when(
      loading: () => const Scaffold(
        backgroundColor: TSColors.bg,
        body: Center(child: CircularProgressIndicator(color: TSColors.lime)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: TSColors.bg,
        body: Center(child: Text('$e', style: TSTextStyles.body())),
      ),
      data: (trip) =>
          _TripSpaceInner(trip: trip, preferredTab: preferredTab),
    );
  }
}

class _TripSpaceInner extends ConsumerStatefulWidget {
  const _TripSpaceInner({required this.trip, this.preferredTab});
  final Trip trip;
  final String? preferredTab;

  @override
  ConsumerState<_TripSpaceInner> createState() => _TripSpaceInnerState();
}

class _TripSpaceInnerState extends ConsumerState<_TripSpaceInner>
    with TickerProviderStateMixin {
  TabController? _tabs;
  TripStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _markSeen();
  }

  /// Stamp this trip as "seen now" so the Home unread dot clears.
  /// Invalidates the last-seen map so cards re-render immediately
  /// on return.
  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'last_seen_trip_${widget.trip.id}',
        DateTime.now().toIso8601String());
    if (!mounted) return;
    ref.invalidate(lastSeenTripMapProvider);
  }
  /// Tracks trips we've already played the reveal for in this app
  /// session (backed by SharedPreferences for persistence). Prevents
  /// the reveal from replaying on every open — only once per trip per
  /// device.
  static final Set<String> _seenReveals = <String>{};
  static final Set<String> _seenWraps = <String>{};
  bool _checkedPrefs = false;
  bool _checkedWrapPrefs = false;

  Future<void> _renameTrip() async {
    TSHaptics.medium();
    // Dialog owns its own controller lifecycle inside _RenameDialog.
    // Hoisting it to function scope (the previous version) tripped a
    // framework assertion (`_dependents.isEmpty: is not true`)
    // because the controller could be disposed while the dialog's
    // TextField was still mid-teardown.
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameTripDialog(initialName: widget.trip.name),
    );
    if (newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == widget.trip.name) return;
    try {
      await ref
          .read(tripServiceProvider)
          .updateName(tripId: widget.trip.id, name: trimmed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('renamed to "$trimmed"',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t save — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _maybePlayWrap(Trip trip) async {
    final id = trip.id;
    if (_seenWraps.contains(id)) return;
    if (!_checkedWrapPrefs) {
      _checkedWrapPrefs = true;
      final prefs = await SharedPreferences.getInstance();
      _seenWraps.addAll(prefs.getStringList('seen_wrap_ids') ?? const []);
      if (_seenWraps.contains(id)) return;
    }
    // Gate: need a destination to render the stamp/recap.
    if (trip.selectedDestination == null) return;

    _seenWraps.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('seen_wrap_ids', _seenWraps.toList());

    if (!mounted) return;
    await TripWrapOverlay.show(context, trip);
  }

  Future<void> _maybePlayReveal(Trip trip) async {
    final id = trip.id;
    if (_seenReveals.contains(id)) return;
    // Load persisted set once.
    if (!_checkedPrefs) {
      _checkedPrefs = true;
      final prefs = await SharedPreferences.getInstance();
      _seenReveals.addAll(prefs.getStringList('seen_reveal_ids') ?? const []);
      if (_seenReveals.contains(id)) return;
    }
    // Gate: only play once the destination is actually set.
    if (trip.selectedDestination == null) return;

    _seenReveals.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('seen_reveal_ids', _seenReveals.toList());

    if (!mounted) return;
    context.push('/trip/$id/reveal');
  }

  List<_TabDef> _tabsForStatus(TripStatus s) {
    switch (s) {
      case TripStatus.collecting:
        return const [
          _TabDef('status', 'status'),
          _TabDef('chat',   'chat'),
        ];
      case TripStatus.voting:
        return const [
          _TabDef('vote',    'vote'),
          _TabDef('chat',    'chat'),
        ];
      case TripStatus.revealed:
      case TripStatus.planning:
        return const [
          _TabDef('plan',  'plan'),
          _TabDef('chat',  'chat'),
          _TabDef('pack',  'pack'),
          _TabDef('tips',  'tips'),
          _TabDef('squad', 'squad'),
          // Preview what the Trip Wrapped card will look like when
          // the trip ends. Anticipation is a product feature.
          _TabDef('recap', 'recap'),
        ];
      case TripStatus.live:
        return const [
          _TabDef('today',  'today'),
          _TabDef('plan',   'plan'),
          _TabDef('chat',   'chat'),
          _TabDef('pack',   'pack'),
          _TabDef('tips',   'tips'),
          _TabDef('squad',  'squad'),
          _TabDef('recap',  'recap'),
        ];
      case TripStatus.completed:
        return const [
          _TabDef('memories', 'memories'),
          _TabDef('plan',     'plan'),
          _TabDef('chat',     'chat'),
          _TabDef('squad',    'squad'),
          _TabDef('stamp',    'stamp'),
        ];
      case TripStatus.draft:
        return const [
          _TabDef('status', 'status'),
          _TabDef('chat',   'chat'),
        ];
    }
  }

  void _rebuildControllerIfNeeded(TripStatus status) {
    if (_lastStatus == status && _tabs != null) return;
    final previous = _lastStatus;
    _tabs?.dispose();
    final tabDefs = _tabsForStatus(status);
    // Honour preferredTab on the FIRST controller build only. Once
    // the user is inside the screen they shouldn't be snapped around
    // by re-routes.
    var initial = 0;
    if (previous == null && widget.preferredTab != null) {
      final idx =
          tabDefs.indexWhere((d) => d.key == widget.preferredTab);
      if (idx >= 0) initial = idx;
    }
    _tabs = TabController(
      length: tabDefs.length,
      initialIndex: initial,
      vsync: this,
    );
    _lastStatus = status;

    // Detect the voting → revealed transition (or any transition into
    // revealed from a pre-revealed phase) and auto-play the reveal
    // cinematic. Deferred to post-frame so we don't push during build.
    final becameRevealed = status == TripStatus.revealed &&
        previous != TripStatus.revealed &&
        previous != TripStatus.planning &&
        previous != TripStatus.live &&
        previous != TripStatus.completed;
    if (becameRevealed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybePlayReveal(widget.trip);
      });
    }

    // Trip wrap celebration — fires when we enter `completed` from
    // anything else, OR on first-ever open of an already-completed
    // trip (previous == null handles that case for trips that were
    // completed before this device cached them).
    final becameCompleted = status == TripStatus.completed &&
        previous != TripStatus.completed;
    if (becameCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybePlayWrap(widget.trip);
      });
    }
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the *effective* status so the Today tab + Memories tab
    // appear the moment real-world dates cross the trip start/end
    // boundaries — no manual status bump needed.
    final phase = widget.trip.effectiveStatus;
    _rebuildControllerIfNeeded(phase);
    final tabDefs = _tabsForStatus(phase);

    // Re-watch auth state so host-only affordances (rename pencil,
    // date editor) recompute when a user signs in/out mid-screen.
    // Without this watch, _TripSpaceInner only rebuilt on trip
    // stream emissions — so a session restored AFTER the screen
    // mounted left the host hidden until something changed in the
    // trip row.
    ref.watch(authStateProvider);
    final meUid = Supabase.instance.client.auth.currentUser?.id;
    final isHost = meUid != null && widget.trip.hostId == meUid;

    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: TSAppBar(
        title: widget.trip.selectedDestination ?? widget.trip.name,
        trailing: _PhasePill(status: phase),
        onTitleLongPress: isHost ? _renameTrip : null,
      ),
      body: Column(children: [
        _CoverHero(trip: widget.trip),
        _VibeStrip(trip: widget.trip),
        // Tab bar aligned to the same content width as the tab body
        // below it. On iPad this spreads the tabs evenly instead of
        // clustering them against the left edge.
        Container(
          color: TSColors.bg,
          child: TSResponsive.content(TabBar(
            controller: _tabs,
            // Only scroll the tab bar on phones where >4 tabs can't
            // fit. On iPad the 840pt content column comfortably fits
            // all tabs, so let them spread with TabAlignment.fill.
            isScrollable: !TSResponsive.isWide(context) &&
                tabDefs.length > 4,
            tabAlignment: TSResponsive.isWide(context)
                ? TabAlignment.fill
                : (tabDefs.length > 4
                    ? TabAlignment.start
                    : TabAlignment.fill),
            indicatorColor: TSColors.lime,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TSTextStyles.label(size: 11),
            unselectedLabelColor: TSColors.muted,
            labelColor: TSColors.lime,
            tabs: [for (final d in tabDefs) Tab(text: d.label)],
          )),
        ),
        // Persistent "scout's cooking" banner — visible on every tab
        // while AI generation (options or itinerary) is in flight so
        // the user sees progress even after switching tabs.
        const _AiGenBanner(),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            // Disable horizontal page-swipe so per-bubble gestures
            // in the chat tab (swipe-right to reply) win the
            // gesture arena. Users still switch tabs via the
            // TabBar or by tapping a tab label.
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final d in tabDefs)
                TSResponsive.content(_buildTab(d.key)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTab(String key) {
    final trip = widget.trip;
    switch (key) {
      case 'status':   return StatusTab(trip: trip);
      case 'vote':     return VoteTab(trip: trip);
      case 'plan':     return PlanTab(trip: trip);
      case 'pack':     return PackTab(trip: trip);
      case 'tips':     return TipsTab(trip: trip);
      case 'squad':    return SquadTab(trip: trip);
      case 'today':    return TodayTab(trip: trip);
      case 'memories': return MemoriesTab(trip: trip);
      case 'stamp':    return StampTab(trip: trip);
      // Pre-trip preview of the Trip Wrapped card — same component as
      // the completed-trip Memories tab, so users see exactly what
      // they'll be able to share when they get back.
      case 'recap':    return MemoriesTab(trip: trip);
      case 'chat':     return ChatTab(tripId: trip.id);
      default:         return const SizedBox();
    }
  }
}

class _TabDef {
  const _TabDef(this.key, this.label);
  final String key;
  final String label;
}

/// Subtle hero strip under the app bar when the host has uploaded
/// a cover photo. Kept short (80pt) so the tab bar stays close to
/// the title and the vibe strip still reads as the primary subhead.
/// Hidden entirely when no cover is set so draft trips stay clean.
class _CoverHero extends StatelessWidget {
  const _CoverHero({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final url = trip.coverPhotoUrl;
    if (url == null || url.isEmpty) return const SizedBox();
    return Container(
      height: 88,
      margin: const EdgeInsets.fromLTRB(
          TSSpacing.md, 8, TSSpacing.md, 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: TSColors.s2,
      ),
      child: Stack(fit: StackFit.expand, children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(),
          errorWidget: (_, __, ___) => const SizedBox(),
        ),
        // Bottom-up fade so the vibe strip reads clean against it.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xBB08080E)],
              stops: [0.3, 1.0],
            ),
          ),
        ),
      ]),
    );
  }
}

/// Thin strip under the trip title: top 2 vibes (emoji + label),
/// squad size, and date range. Vibes come from the trip row; squad
/// size comes from the live squadStream (tripStream only carries
/// the trips row, so `trip.squadMembers` is empty there).
///
/// Dates are tappable for the host on any phase *except* live —
/// opens a date range picker that writes back through
/// `updateDates`. Hidden entirely when neither vibes nor dates are
/// set (draft with no context).
class _VibeStrip extends ConsumerWidget {
  const _VibeStrip({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vibes = trip.vibes ?? const <String>[];
    final labels =
        vibes.take(2).map(_vibeLabelFor).whereType<String>().toList();
    final vibeText = labels.isEmpty ? null : labels.join(' + ');

    final squadAsync = ref.watch(squadStreamProvider(trip.id));
    final squadCount = squadAsync.maybeWhen(
      data: (members) => members.length,
      orElse: () => 0,
    );
    final countText = squadCount <= 0
        ? null
        : squadCount == 1
            ? '1 squadmate'
            : '$squadCount squadmates';

    final dateText = _fmtDateRange(trip);

    // Host + not-live → dates are editable.
    final meUid = Supabase.instance.client.auth.currentUser?.id;
    final isHost = meUid != null && trip.hostId == meUid;
    final phase = trip.effectiveStatus;
    final canEditDates = isHost && phase != TripStatus.live;

    // Nothing to render — stay invisible.
    if (vibeText == null && countText == null && dateText == null) {
      return const SizedBox();
    }

    final separator = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3, height: 3,
        decoration: const BoxDecoration(
          color: TSColors.muted,
          shape: BoxShape.circle,
        ),
      ),
    );

    final parts = <Widget>[];
    if (vibeText != null) {
      parts.add(Text(vibeText,
          style: TSTextStyles.caption(color: TSColors.text)));
    }
    if (countText != null) {
      if (parts.isNotEmpty) parts.add(separator);
      parts.add(Text(countText,
          style: TSTextStyles.caption(color: TSColors.muted)));
    }
    if (dateText != null || canEditDates) {
      if (parts.isNotEmpty) parts.add(separator);
      parts.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canEditDates
              ? () => _editDates(context, ref)
              : null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              dateText ?? 'add dates',
              style: TSTextStyles.caption(
                  color: canEditDates
                      ? TSColors.lime
                      : TSColors.muted),
            ),
            if (canEditDates) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded,
                  color: TSColors.lime, size: 11),
            ],
          ]),
        ),
      );
    }
    // Only offer "add to calendar" once the trip has at least a
    // start date — no dates means nothing to sync.
    if (trip.startDate != null) {
      parts.add(const SizedBox(width: 8));
      parts.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _addToCalendar(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TSColors.s2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TSColors.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('📅', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Text('add to cal',
                  style: TSTextStyles.label(
                      color: TSColors.text2, size: 9)),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TSSpacing.md, 4, TSSpacing.md, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: parts),
      ),
    );
  }

  /// Opens the native Calendar "Add Event" screen with the trip
  /// pre-filled. Uses `add_2_calendar` (EventKit on iOS, Intent on
  /// Android) so users tap once to save — no share picker, no
  /// ambiguous .ics handoff.
  Future<void> _addToCalendar(BuildContext context) async {
    final start = trip.startDate;
    if (start == null) return;
    // All-day events: end needs to sit one day after the inclusive
    // last day so iOS/Android display the correct span.
    final endInclusive = trip.endDate ?? start;
    final endForNativeSheet = endInclusive.add(const Duration(days: 1));
    final event = a2c.Event(
      title:
          '${trip.selectedFlag ?? '✈️'} ${trip.selectedDestination ?? trip.name}',
      description: trip.inviteToken == null
          ? 'Planned with TripSquad'
          : 'Planned with TripSquad · https://gettripsquad.com/trip/${trip.inviteToken}',
      location: trip.selectedDestination,
      startDate: start,
      endDate: endForNativeSheet,
      allDay: true,
      iosParams: const a2c.IOSParams(reminder: Duration(days: 1)),
    );
    TSHaptics.ctaCommit();
    try {
      final ok = await a2c.Add2Calendar.addEvent2Cal(event);
      if (!context.mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('calendar couldn\'t open — try again',
                style: TSTextStyles.body(color: TSColors.bg, size: 13)),
            backgroundColor: TSColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t add — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editDates(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initial = (trip.startDate != null && trip.endDate != null)
        ? DateTimeRange(start: trip.startDate!, end: trip.endDate!)
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDateRange: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: TSColors.lime,
            onPrimary: TSColors.bg,
            surface: TSColors.s1,
            onSurface: TSColors.text,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: TSColors.s1),
        ),
        child: child ?? const SizedBox(),
      ),
    );
    if (picked == null) return;
    TSHaptics.ctaCommit();
    try {
      await ref.read(tripServiceProvider).updateDates(
            tripId: trip.id,
            startDate: picked.start,
            endDate: picked.end,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('dates updated',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t save — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _fmtDateRange(Trip t) {
    final s = t.startDate;
    final e = t.endDate;
    if (s == null && e == null) return null;
    const months = [
      '', 'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    if (s != null && e != null) {
      if (s.year == e.year && s.month == e.month) {
        return '${months[s.month]} ${s.day}–${e.day}';
      }
      return '${months[s.month]} ${s.day} – ${months[e.month]} ${e.day}';
    }
    final d = s ?? e!;
    return '${months[d.month]} ${d.day}';
  }

  String? _vibeLabelFor(String id) {
    for (final v in TSVibes.all) {
      if (v.id == id) return '${v.emoji} ${v.label.toLowerCase()}';
    }
    return null;
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (status) {
      TripStatus.collecting => ('collecting', TSPillVariant.gold),
      TripStatus.voting     => ('voting',     TSPillVariant.lime),
      TripStatus.revealed   => ('revealed',   TSPillVariant.purple),
      TripStatus.planning   => ('planning',   TSPillVariant.blue),
      TripStatus.live       => ('live ✈️',   TSPillVariant.lime),
      TripStatus.completed  => ('completed',  TSPillVariant.muted),
      TripStatus.draft      => ('draft',      TSPillVariant.muted),
    };
    return TSPill(label, variant: variant, small: true);
  }
}

/// Slim persistent strip that shows while AI generation is in flight.
/// Works across tab switches because AIGeneration is keepAlive.
class _AiGenBanner extends ConsumerWidget {
  const _AiGenBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(aIGenerationProvider);
    if (s.status != AIGenStatus.loading) return const SizedBox.shrink();
    const label = 'scout\'s cooking… ✨';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: TSColors.limeDim(0.12),
      child: Row(children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: TSColors.lime,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TSTextStyles.label(color: TSColors.lime, size: 12)),
        ),
        Text('…',
            style: TSTextStyles.label(color: TSColors.lime, size: 12))
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(duration: 600.ms)
            .then()
            .fadeOut(duration: 600.ms),
      ]),
    );
  }
}

/// Dialog body for the rename-trip flow. Owns its own
/// [TextEditingController] so the controller's lifecycle is bound
/// to the dialog State and disposed in the same pass as the
/// TextField it backs. Disposing the controller from the parent
/// function (which the previous inline implementation did) raced
/// the dialog's teardown and tripped a `_dependents.isEmpty`
/// framework assertion.
class _RenameTripDialog extends StatefulWidget {
  const _RenameTripDialog({required this.initialName});
  final String initialName;

  @override
  State<_RenameTripDialog> createState() => _RenameTripDialogState();
}

class _RenameTripDialogState extends State<_RenameTripDialog> {
  late final _ctrl = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TSColors.s1,
      title: Text('rename trip', style: TSTextStyles.title()),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        style: TSTextStyles.body(),
        decoration: InputDecoration(
          hintText: 'trip name',
          hintStyle: TSTextStyles.body(color: TSColors.muted),
          filled: true,
          fillColor: TSColors.s2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel',
              style: TSTextStyles.body(color: TSColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: Text('save',
              style: TSTextStyles.body(color: TSColors.lime)),
        ),
      ],
    );
  }
}
