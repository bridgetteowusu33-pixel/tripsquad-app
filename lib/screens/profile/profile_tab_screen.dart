import 'dart:io' show Platform;
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/effects.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/avatar_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';
import '../../widgets/ts_scaffold.dart';
import '../../widgets/me_sheet.dart' show MeScoutKnowsCard, MeTravelCredLine, MeStampShelf, scoutKnowsScore;

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return TSScaffold(
      style: TSBackgroundStyle.standard,
      appBar: const TSAppBar(title: 'profile'),
      body: SafeArea(
        child: profile.when(
          data: (user) => _ProfileContent(user: user, ref: ref),
          loading: () => const Center(
            child: CircularProgressIndicator(color: TSColors.lime),
          ),
          error: (_, __) => Center(
            child: Text('something went wrong', style: TSTextStyles.body()),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user, required this.ref});
  final AppUser? user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final p = user;
    if (p == null) {
      return Center(
        child: Text('no profile found', style: TSTextStyles.body()),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(TSSpacing.md),
      children: [
        const SizedBox(height: TSSpacing.sm),

        // ── 1. Identity header ──────────────────────────────
        _IdentityHeader(user: p),
        const SizedBox(height: TSSpacing.lg),

        // ── 2. Scout knows you ──────────────────────────────
        MeScoutKnowsCard(percent: scoutKnowsScore(p), user: p),
        const SizedBox(height: TSSpacing.md),

        // ── 3. Experience badge ─────────────────────────────
        _ExperienceBadge(tripsCompleted: p.tripsCompleted),
        const SizedBox(height: TSSpacing.sm),

        // ── 4. Travel cred — countries · trips · squadmates ─
        const MeTravelCredLine(),
        const SizedBox(height: TSSpacing.sm),

        // ── 5. Passport stamp shelf ─────────────────────────
        const MeStampShelf(),
        const SizedBox(height: TSSpacing.lg),

        // ── 6. Your details ─────────────────────────────────
        const SectionLabel(label: 'your details'),
        const SizedBox(height: TSSpacing.xs),
        _DetailRow(
          emoji: '✈️',
          label: 'home airport',
          value: p.homeCity != null
              ? '${p.homeCity} (${p.homeAirport ?? ''})'
              : 'not set',
        ),
        const SizedBox(height: TSSpacing.xs),
        _DetailRow(
          emoji: '💸',
          label: 'travel style',
          value: p.travelStyle ?? 'not set',
        ),
        const SizedBox(height: TSSpacing.xs),
        _DetailRow(
          emoji: '🛂',
          label: 'passports',
          value: p.passports.isNotEmpty
              ? '${p.passports.length} countries'
              : 'not set',
        ),
        const SizedBox(height: TSSpacing.lg),

        // ── 4. Stats row ────────────────────────────────────
        _StatsRow(user: p),
        const SizedBox(height: TSSpacing.lg),

        // ── 5. Single settings entry ────────────────────────
        _SettingsTile(
          icon: '⚙️',
          label: 'settings',
          onTap: () => context.push('/settings'),
        ),
        const SizedBox(height: TSSpacing.xxl),
      ],
    );
  }
}

// ── Identity Header ─────────────────────────────────────────────
class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar — photo with emoji fallback. Tappable to open upload sheet.
        _AvatarUploader(user: user),
        const SizedBox(height: 12),
        // Nickname
        Text(
          user.nickname ?? 'traveller',
          style: TSTextStyles.heading(size: 22),
        ),
        const SizedBox(height: 4),
        // Tag — tappable, routes to edit-profile so the user can
        // claim or change their @handle. Previously a bare Text with
        // no gesture handler, which made the "set your tag →" call
        // to action look interactive but do nothing.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            TSHaptics.light();
            context.push('/settings/edit-profile');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                user.tag != null ? '@${user.tag}' : 'set your tag',
                style: TSTextStyles.title(
                    size: 16, color: TSColors.lime),
              ),
              const SizedBox(width: 6),
              const Text('✏️', style: TextStyle(fontSize: 13)),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        // Privacy — inline tappable chooser
        _PrivacyInlineChooser(currentLevel: user.privacyLevel),
      ],
    );
  }
}

class _PrivacyInlineChooser extends ConsumerWidget {
  const _PrivacyInlineChooser({required this.currentLevel});
  final String currentLevel;

  static const _labels = {
    'private': ('🔒', 'private'),
    'friends_only': ('👥', 'friends only'),
    'public': ('🌍', 'public'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, label) = _labels[currentLevel] ?? _labels['private']!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showChooser(context, ref),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$icon $label',
            style: TSTextStyles.caption(color: TSColors.text2)),
        const SizedBox(width: 4),
        const Text('✏️', style: TextStyle(fontSize: 11)),
      ]),
    );
  }

  void _showChooser(BuildContext context, WidgetRef ref) {
    TSHaptics.light();
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
            Text('who can find you?',
                style: TSTextStyles.heading(size: 18)),
            const SizedBox(height: 4),
            Text('your @tag is always searchable. this controls profile details.',
                style: TSTextStyles.caption(color: TSColors.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _ChooserRow(
              icon: '🔒',
              label: 'private',
              description: 'only you see your profile details',
              selected: currentLevel == 'private',
              onTap: () {
                Navigator.pop(sheet);
                _set(ref, 'private');
              },
            ),
            const SizedBox(height: 6),
            _ChooserRow(
              icon: '👥',
              label: 'friends only',
              description: 'squad members can see your details',
              selected: currentLevel == 'friends_only',
              onTap: () {
                Navigator.pop(sheet);
                _set(ref, 'friends_only');
              },
            ),
            const SizedBox(height: 6),
            _ChooserRow(
              icon: '🌍',
              label: 'public',
              description: 'anyone can see your travel style + trip count',
              selected: currentLevel == 'public',
              onTap: () {
                Navigator.pop(sheet);
                _set(ref, 'public');
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _set(WidgetRef ref, String level) {
    TSHaptics.selection();
    ref.read(authServiceProvider).updatePrivacy(level);
    ref.invalidate(currentProfileProvider);
  }
}

class _ChooserRow extends StatelessWidget {
  const _ChooserRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });
  final String icon, label, description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TSColors.s2,
          borderRadius: TSRadius.sm,
          border: Border.all(
            color: selected ? TSColors.lime : TSColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TSTextStyles.body(size: 15)),
              Text(description,
                  style: TSTextStyles.caption(color: TSColors.muted)),
            ]),
          ),
          if (selected)
            const Icon(Icons.check_rounded,
                color: TSColors.lime, size: 20),
        ]),
      ),
    );
  }
}

// ── Experience Badge ────────────────────────────────────────────
class _ExperienceBadge extends StatelessWidget {
  const _ExperienceBadge({required this.tripsCompleted});
  final int tripsCompleted;

  @override
  Widget build(BuildContext context) {
    final (badge, nextLabel, needed) = _getBadgeInfo(tripsCompleted);

    return TSCard(
      borderColor: TSColors.limeDim(0.3),
      child: Row(
        children: [
          Text(badge, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getBadgeLabel(tripsCompleted),
                    style: TSTextStyles.title()),
                if (nextLabel != null)
                  Text('$needed more trips to $nextLabel',
                      style: TSTextStyles.caption()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String?, int) _getBadgeInfo(int trips) {
    if (trips >= 15) return ('⚡', null, 0);
    if (trips >= 7) return ('🌍', 'squad legend', 15 - trips);
    if (trips >= 3) return ('🗺️', 'globetrotter', 7 - trips);
    return ('✈️', 'explorer', 3 - trips);
  }

  String _getBadgeLabel(int trips) {
    if (trips >= 15) return 'squad legend';
    if (trips >= 7) return 'globetrotter';
    if (trips >= 3) return 'explorer';
    return 'first timer';
  }
}

// ── Detail Row ──────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.emoji,
    required this.label,
    required this.value,
  });
  final String emoji, label, value;

  @override
  Widget build(BuildContext context) {
    return TSCard(
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TSTextStyles.caption()),
                Text(value, style: TSTextStyles.body(size: 15)),
              ],
            ),
          ),
          Text('edit', style: TSTextStyles.caption(color: TSColors.muted)),
        ],
      ),
    );
  }
}

// ── Stats Row ───────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatColumn(value: '${user.tripsCompleted}', label: 'trips'),
        _StatColumn(
            value: '${user.passportStamps.length}', label: 'countries'),
        const _StatColumn(value: '0', label: 'squads'),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TSTextStyles.heading(size: 22)),
          const SizedBox(height: 2),
          Text(label, style: TSTextStyles.caption()),
        ],
      ),
    );
  }
}

// ── Settings Tile ───────────────────────────────────────────────
void _openLegalSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: TSColors.s1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TSSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: TSColors.border2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Text('📋', style: TextStyle(fontSize: 20)),
            title: Text('terms of service', style: TSTextStyles.body()),
            onTap: () {
              Navigator.pop(sheet);
              launchUrl(
                Uri.parse('https://gettripsquad.com/terms'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          const Divider(color: TSColors.border, height: 1),
          ListTile(
            leading: const Text('🔒', style: TextStyle(fontSize: 20)),
            title: Text('privacy policy', style: TSTextStyles.body()),
            onTap: () {
              Navigator.pop(sheet);
              launchUrl(
                Uri.parse('https://gettripsquad.com/privacy'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ]),
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final String icon, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: TSSpacing.md, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: TSColors.border)),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label, style: TSTextStyles.body(size: 15))),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: TSColors.muted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Avatar uploader — tap your avatar to change photo / emoji
// ─────────────────────────────────────────────────────────────
class _AvatarUploader extends ConsumerStatefulWidget {
  const _AvatarUploader({required this.user});
  final AppUser user;

  @override
  ConsumerState<_AvatarUploader> createState() =>
      _AvatarUploaderState();
}

class _AvatarUploaderState extends ConsumerState<_AvatarUploader> {
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(avatarServiceProvider)
          .pickAndUpload(source: source);
      if (url != null) {
        TSHaptics.success();
        ref.invalidate(currentProfileProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(avatarServiceProvider).remove();
      TSHaptics.medium();
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openSheet() {
    TSHaptics.light();
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
            Text('profile picture',
                style: TSTextStyles.heading(size: 18)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Text('📷', style: TextStyle(fontSize: 22)),
              title: Text('take photo', style: TSTextStyles.body()),
              onTap: () {
                Navigator.pop(sheet);
                _pick(ImageSource.camera);
              },
            ),
            const Divider(color: TSColors.border, height: 1),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 22)),
              title: Text('choose from library',
                  style: TSTextStyles.body()),
              onTap: () {
                Navigator.pop(sheet);
                _pick(ImageSource.gallery);
              },
            ),
            if (widget.user.avatarUrl != null &&
                widget.user.avatarUrl!.isNotEmpty) ...[
              const Divider(color: TSColors.border, height: 1),
              ListTile(
                leading: const Text('🗑️', style: TextStyle(fontSize: 22)),
                title: Text('remove photo',
                    style: TSTextStyles.body(color: TSColors.coral)),
                subtitle: Text('keep emoji only',
                    style: TSTextStyles.caption(color: TSColors.muted)),
                onTap: () {
                  Navigator.pop(sheet);
                  _remove();
                },
              ),
            ],
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _openSheet,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const TSGlowOrb(color: TSColors.lime, size: 100, opacity: 0.2),
          TSAvatar(
            emoji: widget.user.emoji ?? '😎',
            photoUrl: widget.user.avatarUrl,
            size: 80,
            ringColor: TSColors.limeDim(0.35),
            ringWidth: 2,
          ),
          // Tiny edit badge on the bottom-right
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TSColors.lime,
                shape: BoxShape.circle,
                border: Border.all(color: TSColors.bg, width: 2),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 10, height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: TSColors.bg,
                      ),
                    )
                  : const Icon(Icons.camera_alt_rounded,
                      color: TSColors.bg, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
