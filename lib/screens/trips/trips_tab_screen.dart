import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../widgets/tappable.dart';
import '../paywall/create_trip_gate.dart';

class TripsTabScreen extends ConsumerStatefulWidget {
  const TripsTabScreen({super.key});

  @override
  ConsumerState<TripsTabScreen> createState() => _TripsTabScreenState();
}

class _TripsTabScreenState extends ConsumerState<TripsTabScreen> {
  bool _showCompleted = false;
  Set<String> _pinnedIds = {};

  static const _prefsKey = 'pinned_trips';

  @override
  void initState() {
    super.initState();
    _loadPinned();
  }

  Future<void> _loadPinned() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? const <String>[];
    if (!mounted) return;
    setState(() => _pinnedIds = list.toSet());
  }

  Future<void> _togglePin(String tripId) async {
    TSHaptics.light();
    setState(() {
      if (_pinnedIds.contains(tripId)) {
        _pinnedIds.remove(tripId);
      } else {
        _pinnedIds.add(tripId);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _pinnedIds.toList());
  }

  void _showPinSheet(Trip trip) {
    TSHaptics.medium();
    final isPinned = _pinnedIds.contains(trip.id);
    final token = trip.inviteToken ?? trip.id;
    final inviteLink = 'https://gettripsquad.com/join/?t=$token';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: TSColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            TSTappable(
              onTap: () async {
                Navigator.pop(sheet);
                await _togglePin(trip.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isPinned
                          ? TSColors.lime
                          : TSColors.border),
                ),
                child: Row(children: [
                  Icon(
                    isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    color: isPinned ? TSColors.lime : TSColors.text2,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPinned ? 'unpin trip' : 'pin to top',
                    style: TSTextStyles.body(
                        size: 14, color: TSColors.text),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            TSTappable(
              onTap: () async {
                Navigator.pop(sheet);
                TSHaptics.light();
                await Clipboard.setData(
                    ClipboardData(text: inviteLink));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('invite link copied',
                        style: TSTextStyles.body(
                            color: TSColors.bg, size: 13)),
                    backgroundColor: TSColors.lime,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TSColors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.link_rounded,
                      color: TSColors.text2, size: 18),
                  const SizedBox(width: 10),
                  Text('copy invite link',
                      style: TSTextStyles.body(
                          size: 14, color: TSColors.text)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            TSTappable(
              onTap: () async {
                Navigator.pop(sheet);
                TSHaptics.light();
                Rect? origin;
                try {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null && box.hasSize) {
                    origin = box.localToGlobal(Offset.zero) & box.size;
                  }
                } catch (_) {}
                try {
                  await Share.share(
                    'join my trip on tripsquad! 🌍✈️\n$inviteLink',
                    sharePositionOrigin: origin,
                  );
                } catch (_) {/* silent */}
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TSColors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.ios_share_rounded,
                      color: TSColors.text2, size: 18),
                  const SizedBox(width: 10),
                  Text('share invite',
                      style: TSTextStyles.body(
                          size: 14, color: TSColors.text)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myTrips = ref.watch(myTripsProvider);

    return Scaffold(
      backgroundColor: TSColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: TSColors.lime,
          backgroundColor: TSColors.s1,
          onRefresh: () async {
            TSHaptics.light();
            ref.invalidate(myTripsProvider);
            await ref.read(myTripsProvider.future);
          },
          child: myTrips.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: TSColors.lime),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: TSTextStyles.body(color: TSColors.coral, size: 12)),
          ),
          data: (trips) {
            // Use effectiveStatus so trips whose end_date has passed
            // migrate to completed automatically, even if the DB
            // status is still `planning`.
            final allCompleted = trips
                .where((t) => t.effectiveStatus == TripStatus.completed)
                .toList();
            final active = trips
                .where((t) => t.effectiveStatus != TripStatus.completed)
                .toList();
            // Split completed → recent vs archive (older than 90d).
            final archiveCutoff =
                DateTime.now().subtract(const Duration(days: 90));
            bool isArchived(Trip t) {
              final ref = t.endDate ?? t.startDate ?? t.createdAt;
              if (ref == null) return false;
              return ref.isBefore(archiveCutoff);
            }
            final completed =
                allCompleted.where((t) => !isArchived(t)).toList();
            final archive =
                allCompleted.where(isArchived).toList();
            final stamps = allCompleted
                .where((t) => t.selectedFlag != null)
                .map((t) => t.selectedFlag!)
                .toSet()
                .toList();
            final meUid =
                Supabase.instance.client.auth.currentUser?.id;
            final uniqueSquadmates = <String>{};
            for (final t in trips) {
              for (final m in t.squadMembers) {
                final uid = m.userId;
                if (uid == null || uid == meUid) continue;
                uniqueSquadmates.add(uid);
              }
            }
            final filtered = _showCompleted ? completed : active;
            // Stable partition: pinned trips float to the top of the
            // active list, preserving relative order otherwise.
            if (!_showCompleted && _pinnedIds.isNotEmpty) {
              filtered.sort((a, b) {
                final ap = _pinnedIds.contains(a.id);
                final bp = _pinnedIds.contains(b.id);
                if (ap == bp) return 0;
                return ap ? -1 : 1;
              });
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  TSSpacing.md, TSSpacing.sm, TSSpacing.md, TSSpacing.xxl),
              children: [
                // ── Header ──────────────────────────────────
                Text('your trips ✈️',
                    style: TSTextStyles.heading(size: 24))
                    .animate().fadeIn(),
                const SizedBox(height: TSSpacing.lg),

                // ── Stats row ───────────────────────────────
                Row(children: [
                  _StatColumn(
                    value: '${trips.length}',
                    label: 'trips',
                  ),
                  _StatColumn(
                    value: '${stamps.length}',
                    label: 'countries',
                  ),
                  _StatColumn(
                    value: '${uniqueSquadmates.length}',
                    label: 'squadmates',
                  ),
                ].map((w) => Expanded(child: w)).toList()),
                const SizedBox(height: TSSpacing.lg),

                // ── Passport stamps ─────────────────────────
                if (stamps.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: stamps.map((flag) {
                          // First completed trip carrying this flag —
                          // gives us a deterministic target for tap.
                          final trip = allCompleted.firstWhere(
                            (t) => t.selectedFlag == flag,
                            orElse: () => allCompleted.first,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                TSHaptics.light();
                                context.push('/trip/${trip.id}/space');
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: TSColors.s2,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(flag,
                                    style:
                                        const TextStyle(fontSize: 20)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                else
                  Text(
                    'no stamps yet. complete a trip to earn your first 🌍',
                    style: TSTextStyles.caption(),
                  ),
                const SizedBox(height: TSSpacing.lg),

                // ── Toggle ──────────────────────────────────
                Row(children: [
                  Expanded(
                    child: TSTappable(
                      onTap: () {
                        TSHaptics.selection();
                        setState(() => _showCompleted = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_showCompleted
                              ? TSColors.lime
                              : TSColors.s2,
                          borderRadius: TSRadius.full,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'active',
                          style: TSTextStyles.title(
                            size: 13,
                            color: !_showCompleted
                                ? TSColors.bg
                                : TSColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TSTappable(
                      onTap: () {
                        TSHaptics.selection();
                        setState(() => _showCompleted = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _showCompleted
                              ? TSColors.lime
                              : TSColors.s2,
                          borderRadius: TSRadius.full,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'completed',
                          style: TSTextStyles.title(
                            size: 13,
                            color: _showCompleted
                                ? TSColors.bg
                                : TSColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: TSSpacing.md),

                // ── Trip list ───────────────────────────────
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: TSSpacing.xxl),
                    child: Column(children: [
                      const Text('🌍', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        _showCompleted
                            ? 'no completed trips yet'
                            : 'no trips yet. your squad is waiting 🌍',
                        style: TSTextStyles.body(),
                        textAlign: TextAlign.center,
                      ),
                      if (!_showCompleted) ...[
                        const SizedBox(height: 20),
                        TSButton(
                          label: '+ plan a trip 🗺️',
                          onTap: () =>
                              gateAndOpenTripWizard(context, ref),
                        ),
                      ],
                    ]),
                  )
                else
                  ...filtered.asMap().entries.map((e) {
                    final i = e.key;
                    final trip = e.value;
                    final isPinned = _pinnedIds.contains(trip.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: _showCompleted
                            ? null
                            : () => _showPinSheet(trip),
                        child: _showCompleted
                            ? _CompletedTripCard(trip: trip)
                            : _ActiveTripCard(
                                trip: trip, pinned: isPinned),
                      ),
                    ).animate()
                        .fadeIn(delay: (i * 60).ms)
                        .slideY(begin: 0.1, delay: (i * 60).ms);
                  }),

                // ── Archive (completed > 90d) ─────────────────
                if (_showCompleted && archive.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ArchiveSection(archive: archive),
                ],
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

/// Collapsible list of completed trips older than 90 days.
/// Collapsed by default so the completed tab stays focused on
/// recent wins. Remembers its open/closed state for the session.
class _ArchiveSection extends StatefulWidget {
  const _ArchiveSection({required this.archive});
  final List<Trip> archive;

  @override
  State<_ArchiveSection> createState() => _ArchiveSectionState();
}

class _ArchiveSectionState extends State<_ArchiveSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TSTappable(
          onTap: () {
            TSHaptics.selection();
            setState(() => _open = !_open);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: TSColors.s1,
              borderRadius: TSRadius.sm,
              border: Border.all(color: TSColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.inventory_2_outlined,
                  color: TSColors.muted, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'archive · ${widget.archive.length}',
                  style: TSTextStyles.title(
                      size: 13, color: TSColors.text2),
                ),
              ),
              Icon(
                _open
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: TSColors.muted,
                size: 18,
              ),
            ]),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 10),
          ...widget.archive.asMap().entries.map((e) {
            final i = e.key;
            final trip = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CompletedTripCard(trip: trip),
            )
                .animate()
                .fadeIn(delay: (i * 40).ms)
                .slideY(begin: 0.06, delay: (i * 40).ms);
          }),
        ],
      ],
    );
  }
}

// ── Stat column ─────────────────────────────────────────────────
class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TSTextStyles.heading(size: 24)),
      const SizedBox(height: 2),
      Text(label, style: TSTextStyles.caption()),
    ]);
  }
}

// ── Active trip card ────────────────────────────────────────────
class _ActiveTripCard extends ConsumerWidget {
  const _ActiveTripCard({required this.trip, this.pinned = false});
  final Trip trip;
  final bool pinned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responded = trip.squadMembers
        .where((m) => m.status != MemberStatus.invited).length;
    final total = trip.squadMembers.length;
    final progress = total > 0 ? responded / total : 0.0;
    final hasUnread =
        ref.watch(unreadTripIdsProvider).contains(trip.id);

    return TSCard(
      borderColor: pinned
          ? TSColors.lime
          : TSColors.limeDim(0.22),
      onTap: () {
        TSHaptics.light();
        context.push('/trip/${trip.id}/space');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (pinned) ...[
              const Icon(Icons.push_pin, color: TSColors.lime, size: 14),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Row(children: [
                Flexible(
                  child: Text(
                    trip.selectedDestination ?? trip.name,
                    style: TSTextStyles.title(size: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: TSColors.lime,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ]),
            ),
            TSPill(_statusLabel(trip.effectiveStatus),
                variant: TSPillVariant.lime),
          ]),
          if (trip.startDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_fmtDate(trip.startDate!)} – ${_fmtDate(trip.endDate!)}',
              style: TSTextStyles.caption(),
            ),
          ],
          if (total > 1) ...[
            const SizedBox(height: 10),
            TSProgressBar(progress: progress),
            const SizedBox(height: 4),
            Text('$responded/$total squad responded',
                style: TSTextStyles.caption()),
          ],
          const SizedBox(height: 8),
          Consumer(builder: (_, r, __) {
            final avatars = r.watch(squadAvatarsProvider).valueOrNull ?? {};
            return SquadAvatarRow(
              emojis: trip.squadMembers.map((m) => m.emoji ?? '😎').toList(),
              photoUrls: trip.squadMembers
                  .map((m) => m.userId == null ? null : avatars[m.userId!])
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  String _statusLabel(TripStatus s) {
    switch (s) {
      case TripStatus.collecting: return 'Collecting';
      case TripStatus.voting:     return 'Voting open';
      case TripStatus.revealed:   return 'Revealed!';
      case TripStatus.planning:   return 'Planning';
      case TripStatus.live:       return '✈️ Live';
      default:                    return s.name;
    }
  }

  String _fmtDate(DateTime d) => '${_month(d.month)} ${d.day}';
  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}

// ── Completed trip card ─────────────────────────────────────────
class _CompletedTripCard extends StatelessWidget {
  const _CompletedTripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return TSCard(
      onTap: () {
        TSHaptics.light();
        context.push('/trip/${trip.id}/space');
      },
      child: Row(children: [
        Text(trip.selectedFlag ?? '✈️',
            style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.selectedDestination ?? trip.name,
                style: TSTextStyles.title(size: 16, color: TSColors.text2),
              ),
              if (trip.startDate != null)
                Text(
                  '${_fmtDate(trip.startDate!)} – ${_fmtDate(trip.endDate!)}',
                  style: TSTextStyles.caption(),
                ),
            ],
          ),
        ),
        Text(
          '${trip.squadMembers.length} people',
          style: TSTextStyles.caption(color: TSColors.muted),
        ),
      ]),
    );
  }

  String _fmtDate(DateTime d) => '${_month(d.month)} ${d.day}';
  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}
