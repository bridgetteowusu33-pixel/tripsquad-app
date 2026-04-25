import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'passport_stamp.dart';
import 'widgets.dart';

/// Modal bottom sheet opened by tapping the Home avatar.
///
/// Replaces the Profile nav tab. Contains: identity header, experience
/// badge, Scout-knows-you score, kudos preview, privacy pill, and
/// routes to settings / edit profile / blocked users.
///
/// Usage:
/// ```dart
/// MeSheet.show(context);
/// ```
class MeSheet {
  MeSheet._();

  static Future<void> show(BuildContext context) {
    TSHaptics.ctaCommit();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => const _MeSheetContents(),
    );
  }
}

class _MeSheetContents extends ConsumerWidget {
  const _MeSheetContents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.92,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: TSColors.bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TSColors.border),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Grab handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: TSColors.border2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: TSColors.lime),
              ),
              error: (_, __) => Center(
                child: Text('couldn\'t load', style: TSTextStyles.body()),
              ),
              data: (user) => user == null
                  ? const SizedBox()
                  : _Body(user: user),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final knowsScore = _scoutKnowsScore(user);
    return ListView(
      padding: const EdgeInsets.fromLTRB(TSSpacing.md, 0, TSSpacing.md, 40),
      children: [
        // ── Identity ──────────────────────────────────────────
        Row(children: [
          TSAvatar(
            emoji: user.emoji ?? '😎',
            photoUrl: user.avatarUrl,
            size: 64,
            ringColor: TSColors.limeDim(0.35),
            ringWidth: 2,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname ?? 'traveller',
                  style: TSTextStyles.heading(size: 22),
                ),
                if (user.tag != null) ...[
                  const SizedBox(height: 2),
                  Text('@${user.tag}',
                      style: TSTextStyles.body(color: TSColors.lime)),
                ],
              ],
            ),
          ),
          _PrivacyPill(level: user.privacyLevel),
        ]),
        const SizedBox(height: 20),

        // ── Scout knows you ──────────────────────────────────
        MeScoutKnowsCard(percent: knowsScore, user: user),
        const SizedBox(height: 18),

        // ── Experience badge ─────────────────────────────────
        _ExperienceBadge(tripsCompleted: user.tripsCompleted),
        const SizedBox(height: 14),

        // ── Travel cred — countries · trips · squadmates ─────
        const MeTravelCredLine(),
        const SizedBox(height: 14),

        // ── Passport stamp shelf ─────────────────────────────
        const MeStampShelf(),
        const SizedBox(height: 24),

        // ── Menu ─────────────────────────────────────────────
        const SectionLabel(label: 'you'),
        const SizedBox(height: 10),
        _MeTile(
          icon: '✏️',
          label: 'edit profile',
          subtitle: 'name, tag, emoji, home, travel style',
          onTap: () {
            Navigator.pop(context);
            context.push('/settings/edit-profile');
          },
        ),
        _MeTile(
          icon: '🚫',
          label: 'blocked users',
          onTap: () {
            Navigator.pop(context);
            context.push('/settings/blocked');
          },
        ),
        _MeTile(
          icon: '⚙️',
          label: 'settings',
          subtitle: 'notifications, scout tone, legal',
          onTap: () {
            Navigator.pop(context);
            context.push('/settings');
          },
        ),
        const SizedBox(height: 10),
        // Escape hatch to full profile page for users who want the
        // classic view.
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/profile');
            },
            child: Text(
              'see full profile →',
              style: TSTextStyles.caption(color: TSColors.muted),
            ),
          ),
        ),
      ],
    );
  }

  /// Derived "Scout knows you" percentage. Delegates to the shared
  /// top-level [scoutKnowsScore] so Home + Me sheet stay in sync.
  int _scoutKnowsScore(AppUser u) => scoutKnowsScore(u);
}

/// "Scout knows you" percentage. A fully-filled profile alone
/// reaches **92%**; the last 7% comes from completed trips (Scout
/// learning your real behaviour). Capped at 99 — Scout is always
/// still learning. Shared so the Home pill and Me sheet card
/// render the exact same number.
int scoutKnowsScore(AppUser u) {
  int score = 25; // baseline for signing up
  if (u.nickname != null && u.nickname!.isNotEmpty) score += 8;
  if (u.tag != null && u.tag!.isNotEmpty) score += 10;
  if (u.avatarUrl != null && u.avatarUrl!.isNotEmpty) score += 12;
  if (u.homeCity != null && u.homeCity!.isNotEmpty) score += 10;
  if (u.homeAirport != null && u.homeAirport!.isNotEmpty) score += 5;
  if (u.travelStyle != null && u.travelStyle!.isNotEmpty) score += 12;
  if (u.passports.isNotEmpty) score += 10;
  if (u.passports.length >= 3) score += 3;
  score += u.tripsCompleted.clamp(0, 7);
  return score.clamp(0, 99);
}

// ─────────────────────────────────────────────────────────────

class MeScoutKnowsCard extends StatelessWidget {
  const MeScoutKnowsCard({required this.percent, required this.user});
  final int percent;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return TSCard(
      borderColor: TSColors.limeDim(0.22),
      onTap: () {
        TSHaptics.ctaTap();
        _showMissing(context, user, percent);
      },
      child: Row(children: [
        const Text('🧭', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('scout knows you $percent%',
                  style: TSTextStyles.title(color: TSColors.lime)),
              const SizedBox(height: 4),
              Text(
                percent >= 85
                    ? 'scout has enough to plan for you. tap to see what\'s left.'
                    : 'fill in more of your profile so scout can plan better.',
                style: TSTextStyles.caption(color: TSColors.muted),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded,
            color: TSColors.muted, size: 14),
      ]),
    );
  }
}

/// Shows Scout which profile fields are still missing and routes to
/// the edit screen. Tapping the Scout-knows-you card opens this.
void _showMissing(BuildContext context, AppUser u, int percent) {
  final missing = <({String emoji, String label})>[
    if (u.avatarUrl == null) (emoji: '📷', label: 'profile photo'),
    if (u.tag == null || u.tag!.isEmpty) (emoji: '@', label: '@tag'),
    if (u.homeCity == null) (emoji: '🏠', label: 'home city'),
    if (u.homeAirport == null) (emoji: '✈️', label: 'home airport'),
    if (u.travelStyle == null) (emoji: '💸', label: 'travel style'),
    if (u.passports.isEmpty) (emoji: '🛂', label: 'passports'),
    if (u.tripsCompleted < 5)
      (emoji: '🧭', label: 'complete more trips'),
  ];

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: TSColors.s1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TSColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('scout knows you $percent%',
                style: TSTextStyles.heading(size: 20, color: TSColors.lime)),
            const SizedBox(height: 6),
            Text(
              missing.isEmpty
                  ? 'profile\'s looking thorough. scout is working with a full picture.'
                  : 'here\'s what would help scout plan better for you.',
              style: TSTextStyles.body(size: 13, color: TSColors.text2),
            ),
            const SizedBox(height: 18),
            if (missing.isNotEmpty) ...[
              for (final m in missing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(m.label,
                        style: TSTextStyles.body(
                            size: 14.5, color: TSColors.text)),
                  ]),
                ),
              const SizedBox(height: 18),
              TSButton(
                label: 'complete your profile →',
                onTap: () {
                  Navigator.pop(sheet);
                  Navigator.pop(context); // close Me sheet too
                  context.push('/settings/edit-profile');
                },
              ),
            ] else ...[
              TSButton(
                label: 'edit profile anyway →',
                variant: TSButtonVariant.outline,
                onTap: () {
                  Navigator.pop(sheet);
                  Navigator.pop(context);
                  context.push('/settings/edit-profile');
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    final (emoji, label) = switch (level) {
      'public' => ('🌍', 'public'),
      'friends' || 'friends_only' => ('👥', 'friends'),
      _ => ('🔒', 'private'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TSColors.border2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: TSTextStyles.caption(color: TSColors.text2)),
      ]),
    );
  }
}

class _ExperienceBadge extends StatelessWidget {
  const _ExperienceBadge({required this.tripsCompleted});
  final int tripsCompleted;

  @override
  Widget build(BuildContext context) {
    final (badge, tier, nextLabel, needed) =
        _experienceInfo(tripsCompleted);
    return TSCard(
      borderColor: TSColors.limeDim(0.18),
      child: Row(children: [
        Text(badge, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tier, style: TSTextStyles.title()),
              if (nextLabel != null)
                Text('$needed more trips to $nextLabel',
                    style: TSTextStyles.caption(color: TSColors.muted)),
            ],
          ),
        ),
        Text('$tripsCompleted',
            style: TSTextStyles.heading(size: 22, color: TSColors.lime)),
      ]),
    );
  }

  (String, String, String?, int) _experienceInfo(int trips) {
    if (trips >= 20) return ('🏆', 'squad legend', null, 0);
    if (trips >= 10) return ('🌍', 'globetrotter', 'squad legend', 20 - trips);
    if (trips >= 5)  return ('✈️', 'wanderer', 'globetrotter', 10 - trips);
    return ('🌱', 'first timer', 'wanderer', 5 - trips);
  }
}

class _MeTile extends StatelessWidget {
  const _MeTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
  final String icon, label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TSHaptics.ctaTap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TSTextStyles.body(size: 15)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TSTextStyles.caption(color: TSColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: TSColors.muted, size: 14),
        ]),
      ),
    );
  }
}

/// Horizontal passport shelf on the Me sheet. Shows one stamp per
/// completed trip. Empty state invites the user to finish their
/// first trip.
/// One-line travel cred:
///   🌍 N countries · ✈️ M trips · 👥 K squadmates met
///
/// Derived from the user's completed trips — distinct flags count
/// as "countries" (flag emoji uniqueness stands in for country
/// until migration 022's Destination DNA table lands). Squadmates
/// met counts distinct non-self user_ids across all completed
/// trip squads.
class MeTravelCredLine extends ConsumerWidget {
  const MeTravelCredLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);
    return tripsAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (trips) {
        final completed = trips
            .where((t) => t.effectiveStatus == TripStatus.completed)
            .toList();
        if (completed.isEmpty) return const SizedBox();
        final flags = <String>{};
        final mates = <String>{};
        final meUid = Supabase.instance.client.auth.currentUser?.id;
        for (final t in completed) {
          final f = t.selectedFlag;
          if (f != null && f.isNotEmpty) flags.add(f);
          for (final m in t.squadMembers) {
            final uid = m.userId;
            if (uid != null && uid != meUid) mates.add(uid);
          }
        }
        return Row(children: [
          _Chip(emoji: '🌍', count: flags.length, label: 'countries'),
          const SizedBox(width: 10),
          _Chip(emoji: '✈️', count: completed.length, label: 'trips'),
          const SizedBox(width: 10),
          _Chip(emoji: '👥', count: mates.length, label: 'squadmates'),
        ]);
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.emoji,
    required this.count,
    required this.label,
  });
  final String emoji;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TSColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text('$count',
            style: TSTextStyles.title(
                size: 13, color: TSColors.text)),
        const SizedBox(width: 4),
        Text(label,
            style: TSTextStyles.caption(color: TSColors.muted2)),
      ]),
    );
  }
}

class MeStampShelf extends ConsumerWidget {
  const MeStampShelf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);
    return tripsAsync.when(
      loading: () => const SizedBox(height: 140),
      error: (_, __) => const SizedBox(),
      data: (trips) {
        // Uses effectiveStatus so a trip whose end_date has passed
        // shows its stamp even if the DB status is still `planning`.
        final completed = trips
            .where((t) => t.effectiveStatus == TripStatus.completed)
            .toList()
          ..sort((a, b) {
            final ad = a.endDate ?? a.createdAt ?? DateTime(2000);
            final bd = b.endDate ?? b.createdAt ?? DateTime(2000);
            return bd.compareTo(ad);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('PASSPORT',
                  style: TSTextStyles.label(
                      color: TSColors.muted, size: 10)),
              const SizedBox(width: 6),
              Text('·  ${completed.length}',
                  style: TSTextStyles.label(
                      color: TSColors.lime, size: 10)),
            ]),
            const SizedBox(height: 10),
            if (completed.isEmpty)
              _EmptyShelf()
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: completed.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    final t = completed[i];
                    final dest = t.selectedDestination ?? t.name;
                    return _StampThumb(trip: t, destination: dest);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StampThumb extends StatelessWidget {
  const _StampThumb({required this.trip, required this.destination});
  final Trip trip;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final flag = trip.selectedFlag ?? '🌍';
    final accent = stampAccentFor(destination);
    final year =
        (trip.endDate ?? trip.startDate ?? trip.createdAt ?? DateTime.now())
            .year
            .toString();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TSHaptics.ctaTap();
        Navigator.of(context).maybePop(); // close Me sheet
        // Route back to the trip's Stamp tab (Trip Space will pick
        // the `completed` tab set automatically).
        // Use GoRouter via context.push at the caller site would be
        // cleaner, but we're inside a modal — so fall back to the
        // trip's space URL.
        // We import go_router in me_sheet already.
        // Delay a hair so the sheet animation can finish.
        Future.delayed(const Duration(milliseconds: 240), () {
          // This is a no-op if context was unmounted.
          try {
            // ignore: use_build_context_synchronously
            GoRouter.of(context).push('/trip/${trip.id}/space');
          } catch (_) {}
        });
      },
      child: Column(children: [
        PassportStamp(
          destination: destination,
          flag: flag,
          dateLabel: year,
          serial: null,
          accent: accent,
          size: 104,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 104,
          child: Text(
            destination,
            style: TSTextStyles.caption(color: TSColors.text2),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TSColors.border2),
      ),
      child: Row(children: [
        const Text('📘', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('your passport is empty — for now',
                  style: TSTextStyles.body(size: 14)),
              Text('first stamp lands when your first trip wraps',
                  style: TSTextStyles.caption(color: TSColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}
