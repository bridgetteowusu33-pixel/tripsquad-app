import 'dart:io' show Platform;
import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../feedback/sentiment_router_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/feature_flags.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/saved_scout_tips.dart';
import '../../providers/entitlement_providers.dart';
import '../../providers/paywall_providers.dart';
import '../../services/push_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/weather_chip.dart';
import '../../widgets/widgets.dart';
import '../../main.dart' show rootScaffoldMessengerKey;

/// Full Settings screen. Opened from Profile tab → ⚙️ settings.
/// Sections: Account · Notifications · App · Support · Legal · Danger.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _info = i);
    });
    // Re-log push permission status whenever settings opens. Catches
    // the user-flipped-it-in-iOS case without needing a global app
    // lifecycle observer. Fire-and-forget — never blocks the UI.
    PushService.logCurrentStatus();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: const TSAppBar(title: 'settings'),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: TSColors.lime)),
          error: (e, _) => Center(child: Text(humanizeError(e))),
          data: (user) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section('account'),
              _Tile(
                icon: '✏️',
                label: 'edit profile',
                subtitle: 'name, tag, emoji, home, travel style',
                onTap: () => context.push('/settings/edit-profile'),
              ),
              _Tile(
                icon: '🔒',
                label: 'privacy',
                subtitle: _privacyLabel(user?.privacyLevel),
                onTap: () => _showPrivacySheet(context, user?.privacyLevel),
              ),
              _Tile(
                icon: '🚫',
                label: 'blocked users',
                subtitle: 'people you\'ve blocked from DMs + search',
                onTap: () => context.push('/settings/blocked'),
              ),

              // Plan section is only rendered when the paywall is live
              // (v1.1+). v1.0 ships without monetization surfaces —
              // users never see "trip passes: 0" or an orphaned restore
              // row.
              if (FeatureFlags.paywallEnabled) ...[
                _section('plan'),
                const _PlanSection(),
              ],

              _section('security'),
              _Tile(
                icon: '🔑',
                label: 'change password',
                subtitle: 'update your password',
                onTap: () => _showChangePasswordSheet(context),
              ),
              _Tile(
                icon: '✉️',
                label: 'change email',
                subtitle: 'update the email on your account',
                onTap: () => _showChangeEmailSheet(context),
              ),

              _section('notifications'),
              _NotificationToggles(user: user),
              _Tile(
                icon: '📱',
                label: 'system settings',
                subtitle: 'permission + sound',
                onTap: () =>
                    AppSettings.openAppSettings(type: AppSettingsType.notification),
              ),
              // Diagnostic tool — debug builds only. Real users in
              // TestFlight + App Store don't see this. If a user
              // reports push issues, ask them to install a debug
              // build OR dispatch the same diagnostic from a hidden
              // long-press elsewhere (future polish).
              if (kDebugMode)
                _Tile(
                  icon: '🔧',
                  label: 'diagnose push',
                  subtitle: 'run the full token-register flow + show result',
                  onTap: () => _diagnosePush(context),
                ),

              _section('units'),
              const _TempUnitRow(),

              _section('scout'),
              const _ScoutToneRow(),
              const SizedBox(height: 16),
              const _DislikesRow(),
              const _ExportScoutRow(),
              const _ClearScoutRow(),

              _section('app'),
              _Tile(
                icon: '📤',
                label: 'share with friends',
                subtitle: 'invite others to join',
                onTap: () async {
                  TSHaptics.light();
                  final suffix =
                      user?.tag != null ? ' — @${user!.tag}' : '';
                  final box = context.findRenderObject() as RenderBox?;
                  final origin = box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null;
                  try {
                    await Share.share(
                      'check out tripsquad — group travel that actually happens ✈️$suffix\nhttps://gettripsquad.com',
                      subject: 'tripsquad',
                      sharePositionOrigin: origin,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(humanizeError(e))),
                      );
                    }
                  }
                },
              ),
              _Tile(
                icon: '⭐',
                label: 'rate tripsquad',
                subtitle: "tell us how we're doing",
                onTap: () async {
                  TSHaptics.ctaTap();
                  // 3-card sentiment vote: happy → Apple's InAppReview
                  // prompt + confetti; neutral/unhappy → category-aware
                  // feedback form that lands in app_feedback for triage.
                  await showSentimentRouter(context, trigger: 'settings_rate_tile');
                },
              ),

              _section('support'),
              _Tile(
                icon: '💬',
                label: 'contact support',
                subtitle: 'support@afialabs.com',
                onTap: () => launchUrl(Uri.parse(
                    'mailto:support@afialabs.com?subject=tripsquad%20support')),
              ),
              _Tile(
                icon: '🐛',
                label: 'report a bug',
                subtitle: 'tell us what broke',
                onTap: () => launchUrl(Uri.parse(
                    'mailto:support@afialabs.com?subject=tripsquad%20bug')),
              ),

              _section('legal'),
              _Tile(
                icon: '📋',
                label: 'terms of service',
                onTap: () => launchUrl(
                  Uri.parse('https://gettripsquad.com/terms'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _Tile(
                icon: '🔐',
                label: 'privacy policy',
                onTap: () => launchUrl(
                  Uri.parse('https://gettripsquad.com/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
              ),

              const SizedBox(height: 24),
              _section('danger zone'),
              _Tile(
                icon: '🚪',
                label: 'sign out',
                danger: false,
                onTap: () => _signOut(context),
              ),
              _Tile(
                icon: '💀',
                label: 'delete my account',
                subtitle: 'permanently removes your trips, chats, everything',
                danger: true,
                onTap: () => _confirmDelete(context),
              ),

              const SizedBox(height: 28),
              Center(
                child: Text(
                  'tripsquad${_info == null ? '' : ' v${_info!.version}'}',
                  style: TSTextStyles.caption(color: TSColors.muted),
                ),
              ),
              Center(
                child: Text(
                  'made by afia labs',
                  style: TSTextStyles.caption(color: TSColors.muted),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _privacyLabel(String? level) {
    switch (level) {
      case 'public': return '🌍 public — anyone can find you';
      case 'friends_only': return '👥 friends only';
      default: return '🔒 private — only you see details';
    }
  }

  Future<void> _diagnosePush(BuildContext context) async {
    TSHaptics.light();
    final steps = <String>[];

    // Step 1: Firebase init
    try {
      await Firebase.initializeApp();
      steps.add('✅ firebase initialized');
    } catch (e) {
      steps.add('❌ firebase init failed: $e');
      _showDiagSheet(context, steps);
      return;
    }

    final messaging = FirebaseMessaging.instance;

    // Step 2: permission
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    steps.add('📲 permission: ${settings.authorizationStatus.name}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _showDiagSheet(context, steps);
      return;
    }

    // Step 3: APNs token (iOS only)
    if (Platform.isIOS) {
      try {
        final apns = await messaging.getAPNSToken();
        steps.add(apns == null
            ? '❌ APNs token: null (APNs key missing in Firebase?)'
            : '✅ APNs token: ${apns.substring(0, 16)}…');
        if (apns == null) {
          _showDiagSheet(context, steps);
          return;
        }
      } catch (e) {
        steps.add('❌ APNs token error: $e');
        _showDiagSheet(context, steps);
        return;
      }
    }

    // Step 4: FCM token
    String? fcm;
    try {
      fcm = await messaging.getToken();
      steps.add(fcm == null
          ? '❌ FCM token: null'
          : '✅ FCM token: ${fcm.substring(0, 16)}…');
      if (fcm == null) {
        _showDiagSheet(context, steps);
        return;
      }
    } catch (e) {
      steps.add('❌ FCM token error: $e');
      _showDiagSheet(context, steps);
      return;
    }

    // Step 5: auth uid
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      steps.add('❌ no auth uid — sign in first');
      _showDiagSheet(context, steps);
      return;
    }
    steps.add('✅ uid: ${uid.substring(0, 8)}…');

    // Step 6: upsert into push_tokens
    try {
      await Supabase.instance.client.from('push_tokens').upsert({
        'user_id': uid,
        'token': fcm,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
      steps.add('✅ token saved to push_tokens');
    } catch (e) {
      steps.add('❌ push_tokens upsert failed: $e');
    }

    _showDiagSheet(context, steps);
  }

  void _showDiagSheet(BuildContext context, List<String> steps) {
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('push diagnostic',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 10),
              for (final s in steps) ...[
                Text(s, style: TSTextStyles.body(size: 13)),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: steps.join('\n')));
                  ScaffoldMessenger.of(sheet).showSnackBar(
                    SnackBar(
                      content: Text('copied',
                          style: TSTextStyles.body(
                              color: TSColors.bg, size: 13)),
                      backgroundColor: TSColors.lime,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TSColors.s2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('copy output',
                      style:
                          TSTextStyles.title(size: 13, color: TSColors.text)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordSheet(BuildContext context) async {
    TSHaptics.light();
    final result = await showModalBottomSheet<({String newPw})?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
    if (result == null || !mounted) return;
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: result.newPw));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('password updated',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("couldn't update — ${humanizeError(e)}",
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showChangeEmailSheet(BuildContext context) async {
    TSHaptics.light();
    final newEmail = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ChangeEmailSheet(),
    );
    if (newEmail == null || !mounted) return;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: newEmail),
        emailRedirectTo: 'https://gettripsquad.com/auth/callback',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('check $newEmail — confirm the change',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("couldn't update — ${humanizeError(e)}",
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPrivacySheet(BuildContext context, String? current) async {
    TSHaptics.light();
    final level = current ?? 'private';
    await showModalBottomSheet<void>(
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
            Text(
              'your @tag is always searchable. this controls what else people see.',
              textAlign: TextAlign.center,
              style: TSTextStyles.caption(color: TSColors.muted),
            ),
            const SizedBox(height: 20),
            _PrivacyRow(
              icon: '🔒', label: 'private',
              description: 'only you see your profile details',
              selected: level == 'private',
              onTap: () { Navigator.pop(sheet); _setPrivacy('private'); },
            ),
            const SizedBox(height: 6),
            _PrivacyRow(
              icon: '👥', label: 'friends only',
              description: 'squad members can see your details',
              selected: level == 'friends_only',
              onTap: () { Navigator.pop(sheet); _setPrivacy('friends_only'); },
            ),
            const SizedBox(height: 6),
            _PrivacyRow(
              icon: '🌍', label: 'public',
              description: 'anyone can see your travel style + trip count',
              selected: level == 'public',
              onTap: () { Navigator.pop(sheet); _setPrivacy('public'); },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _setPrivacy(String level) async {
    TSHaptics.selection();
    try {
      await ref.read(authServiceProvider).updatePrivacy(level);
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(
          label.toUpperCase(),
          style: TSTextStyles.label(color: TSColors.muted, size: 10),
        ),
      );

  Future<void> _signOut(BuildContext context) async {
    TSHaptics.medium();
    if (context.mounted) context.go('/auth');
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (_) {}
    ref.invalidate(currentProfileProvider);
    ref.invalidate(myTripsProvider);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    TSHaptics.heavy();
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TSColors.s2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('delete your account?',
            style: TSTextStyles.heading(size: 18, color: TSColors.coral)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'this permanently removes your profile, trips you host, chats, ratings, kudos, and everything else. this cannot be undone.',
            style: TSTextStyles.body(size: 13, color: TSColors.text2),
          ),
          const SizedBox(height: 14),
          Text('type delete to confirm',
              style: TSTextStyles.caption(color: TSColors.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-z]')),
            ],
            decoration: InputDecoration(
              hintText: 'delete',
              filled: true,
              fillColor: TSColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel',
                style: TSTextStyles.title(color: TSColors.muted)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().toLowerCase() == 'delete') {
                Navigator.pop(ctx, true);
              }
            },
            child: Text('delete account',
                style: TSTextStyles.title(color: TSColors.coral)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    try {
      await Supabase.instance.client.rpc('delete_account');
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/auth');
      // Surface a confirmation on the auth screen so reviewers (and
      // users) get explicit feedback that the account was removed.
      // Uses the root messenger key because this screen's context
      // tears down the moment go_router navigates away.
      rootScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'account deleted. you\'ve been signed out.',
              style: TSTextStyles.body(
                  color: TSColors.bg, size: 13,
                  weight: FontWeight.w600),
            ),
            backgroundColor: TSColors.coral,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
          ),
        );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }
}

// ── Tile ─────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.danger = false,
    required this.onTap,
  });
  final String icon, label;
  final String? subtitle;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TSTextStyles.body(
                    size: 15,
                    color: danger ? TSColors.coral : TSColors.text,
                  ),
                ),
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

// ── Notification toggles ─────────────────────────────────────
class _NotificationToggles extends ConsumerStatefulWidget {
  const _NotificationToggles({required this.user});
  final AppUser? user;

  @override
  ConsumerState<_NotificationToggles> createState() =>
      _NotificationTogglesState();
}

class _NotificationTogglesState
    extends ConsumerState<_NotificationToggles> {
  Map<String, bool> _prefs = {};
  bool _loaded = false;

  static const _items = <({String key, String emoji, String label, String sub})>[
    (key: 'trip_invites',      emoji: '✈️', label: 'trip invites',      sub: 'when someone adds you to a trip'),
    (key: 'chat_messages',     emoji: '💬', label: 'squad chat',         sub: 'messages in your trip chats'),
    (key: 'mentions',          emoji: '@',  label: '@mentions',          sub: 'when someone @tags you'),
    (key: 'dm_received',       emoji: '✉️', label: 'direct messages',    sub: 'new DMs'),
    (key: 'trip_updates',      emoji: '📍', label: 'trip updates',       sub: 'reveals, voting, itinerary ready'),
    (key: 'kudos_received',    emoji: '🏆', label: 'kudos received',     sub: 'when a squad member shouts you out'),
    (key: 'scout_suggestions', emoji: '🧭', label: 'scout suggestions',  sub: 'proactive tips from scout'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final row = await Supabase.instance.client
        .from('profiles')
        .select('notification_prefs')
        .eq('id', uid)
        .maybeSingle();
    final raw = row?['notification_prefs'];
    if (raw is Map) {
      _prefs = {
        for (final e in raw.entries)
          e.key.toString(): e.value == true,
      };
    }
    // Ensure defaults for any missing keys
    for (final i in _items) {
      _prefs.putIfAbsent(i.key, () => true);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _toggle(String key, bool v) async {
    TSHaptics.selection();
    setState(() => _prefs[key] = v);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.from('profiles')
          .update({'notification_prefs': _prefs})
          .eq('id', uid);
    } catch (e) {
      if (mounted) {
        setState(() => _prefs[key] = !v);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 40);
    return Column(children: [
      for (final i in _items)
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          dense: true,
          activeThumbColor: TSColors.lime,
          title: Row(children: [
            Text(i.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(i.label, style: TSTextStyles.body(size: 14)),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: Text(i.sub,
                style: TSTextStyles.caption(color: TSColors.muted)),
          ),
          value: _prefs[i.key] ?? true,
          onChanged: (v) => _toggle(i.key, v),
        ),
    ]);
  }
}

// ── Scout tone (standard / chill / terse) ─────────────────────
// From the UX redesign (§H Scout Experience System):
// - standard: default genz/millennial voice (lock in, vibes, no FOMO)
// - chill:    longer answers ok, lower urgency, no "do this now" CTAs
// - terse:    1-3 sentences max, no preamble, ship the answer dip
//
// Persisted in SharedPreferences under `scout_tone`. SupabaseService
// reads it on every scout_chat invoke and forwards as `tone` in the
// request body; scout_chat layers a per-tone instruction block on the
// base system prompt so each option produces audibly different output.

enum ScoutTone { standard, chill, terse }

final scoutToneProvider =
    StateNotifierProvider<_ScoutToneNotifier, ScoutTone>((ref) {
  return _ScoutToneNotifier();
});

class _ScoutToneNotifier extends StateNotifier<ScoutTone> {
  _ScoutToneNotifier() : super(ScoutTone.standard) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('scout_tone') ?? 'standard';
    state = ScoutTone.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ScoutTone.standard,
    );
  }

  Future<void> set(ScoutTone tone) async {
    final from = state.name;
    state = tone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scout_tone', tone.name);
    // Mirror to server so we can measure tone usage + change frequency
    // in scout_tone_distribution / scout_tone_engagement views and
    // analyze "did switching tones correlate with retention?" The
    // tone_changes log captures the from→to transition for finer
    // analysis (was the user a standard→chill switcher who stuck
    // around vs. a one-time toggler).
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await db.from('profiles').update({
        'scout_tone': tone.name,
        'scout_tone_set_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
      if (from != tone.name) {
        await db.from('scout_tone_changes').insert({
          'user_id':   uid,
          'from_tone': from,
          'to_tone':   tone.name,
        });
      }
    } catch (_) { /* non-fatal — local state is the source of truth */ }
  }
}

/// Temperature unit toggle (°C ↔ °F) — drives the weather chip on
/// the Home countdown card. Default is Celsius.
class _TempUnitRow extends ConsumerWidget {
  const _TempUnitRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(temperatureUnitProvider);
    Widget pill(TempUnit unit, String label) {
      final selected = current == unit;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          TSHaptics.selection();
          ref.read(temperatureUnitProvider.notifier).set(unit);
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? TSColors.lime : TSColors.s2,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(label,
              style: TSTextStyles.title(
                  size: 13,
                  color:
                      selected ? TSColors.bg : TSColors.text2)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(children: [
        const Text('🌡️', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('temperature',
                  style: TSTextStyles.body(
                      size: 14, color: TSColors.text)),
              Text('drives the weather chip on trip cards',
                  style: TSTextStyles.caption(color: TSColors.muted)),
            ],
          ),
        ),
        pill(TempUnit.celsius, '°C'),
        const SizedBox(width: 6),
        pill(TempUnit.fahrenheit, '°F'),
      ]),
    );
  }
}

/// Copies the user's entire Scout thread to the clipboard as
/// plain text. Useful for stashing travel tips somewhere
/// permanent before running "clear scout history".
class _ExportScoutRow extends ConsumerWidget {
  const _ExportScoutRow();

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    TSHaptics.light();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('scout_messages')
          .select('role, content, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: true);
      if ((rows as List).isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('nothing in your scout thread yet',
                style: TSTextStyles.body(color: TSColors.bg, size: 13)),
            backgroundColor: TSColors.lime,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      final lines = <String>[];
      lines.add('# my scout chat');
      lines.add('');
      for (final r in rows) {
        final m = r as Map<String, dynamic>;
        final role = m['role'] == 'assistant' ? 'scout' : 'me';
        final content = (m['content'] as String?) ?? '';
        lines.add('$role: $content');
        lines.add('');
      }
      await Clipboard.setData(
          ClipboardData(text: lines.join('\n').trim()));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${rows.length} messages copied — paste anywhere',
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
          content: Text('couldn\'t export — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Tile(
      icon: '📤',
      label: 'export scout chat',
      subtitle: 'copy the whole thread as text',
      onTap: () => _export(context, ref),
    );
  }
}

/// Wipes every row in `scout_messages` for the signed-in user,
/// plus any local SharedPreferences tied to the Scout thread
/// (welcome seed flag, daily question posted-at, saved tips). Use
/// with care — the Scout thread is a full restart after this.
class _ClearScoutRow extends ConsumerWidget {
  const _ClearScoutRow();

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    TSHaptics.medium();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('clear scout history?',
                  style: TSTextStyles.heading(size: 20)),
              const SizedBox(height: 6),
              Text(
                'wipes every message in your scout thread and resets saved tips. your profile + trips stay untouched.',
                style: TSTextStyles.caption(color: TSColors.muted),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheet).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TSColors.s2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('keep it',
                          style: TSTextStyles.title(
                              size: 13, color: TSColors.text)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheet).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TSColors.coral,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('clear',
                          style: TSTextStyles.title(
                              size: 13, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    int deleted = -1;
    try {
      // `.select()` on a delete returns the removed rows so we can
      // confirm the RLS policy let the operation through.
      final removed = await Supabase.instance.client
          .from('scout_messages')
          .delete()
          .eq('user_id', uid)
          .select();
      deleted = (removed as List).length;
      final prefs = await SharedPreferences.getInstance();
      // Reset the thread-level flags so the welcome seed re-posts
      // and the daily question is fresh again.
      await prefs.remove('scout_welcomed_$uid');
      await prefs.remove('scout_daily_posted_at');
      await prefs.remove('saved_scout_tips');
      // Force the stream provider to reopen so the Scout tab
      // reflects the empty thread even if realtime delete events
      // didn't propagate (replica-identity DEFAULT doesn't always
      // push deletes to the client cache).
      ref.invalidate(scoutHistoryProvider);
      ref.invalidate(savedScoutTipsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              deleted == 0
                  ? 'nothing to clear — thread was already empty'
                  : 'scout history cleared · $deleted message${deleted == 1 ? '' : 's'}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('scout clear failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('couldn\'t clear — ${humanizeError(e)}',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Tile(
      icon: '🧹',
      label: 'clear scout history',
      subtitle: 'wipe the thread + saved tips — starts fresh',
      onTap: () => _confirm(context, ref),
    );
  }
}

class _ScoutToneRow extends ConsumerWidget {
  const _ScoutToneRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(scoutToneProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('scout\'s tone',
              style: TSTextStyles.body(size: 14, color: TSColors.text)),
          const SizedBox(height: 2),
          Text(
            'how chatty scout is. terse = only the important stuff.',
            style: TSTextStyles.caption(color: TSColors.muted),
          ),
          const SizedBox(height: 10),
          Row(children: [
            for (final t in ScoutTone.values) ...[
              _ToneChip(
                label: t.name,
                selected: t == current,
                onTap: () {
                  TSHaptics.selection();
                  ref.read(scoutToneProvider.notifier).set(t);
                },
              ),
              if (t != ScoutTone.values.last) const SizedBox(width: 8),
            ],
          ]),
        ],
      ),
    );
  }
}

class _ToneChip extends StatelessWidget {
  const _ToneChip({
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? TSColors.limeDim(0.12) : TSColors.s2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? TSColors.lime : TSColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TSTextStyles.body(
            size: 13,
            color: selected ? TSColors.lime : TSColors.text2,
          ),
        ),
      ),
    );
  }
}

// ── Dislikes — things scout won't suggest ─────────────────────
// Two-way sync with `profiles.dislikes`:
//   - Reads: pulled fresh each time the settings screen renders
//     (FutureProvider.autoDispose so it refreshes on re-entry).
//   - Writes from chat: scout_chat's Haiku extractor silently appends
//     when the user mentions hating something travel-related.
//   - Writes from this UI: tap × to remove, type + tap "add" to add.

final _myDislikesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.read(authServiceProvider).fetchDislikes();
});

class _DislikesRow extends ConsumerStatefulWidget {
  const _DislikesRow();

  @override
  ConsumerState<_DislikesRow> createState() => _DislikesRowState();
}

class _DislikesRowState extends ConsumerState<_DislikesRow> {
  final _addCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _writeAndRefresh(List<String> next) async {
    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).setDislikes(next);
      ref.invalidate(_myDislikesProvider);
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

  Future<void> _remove(List<String> current, String item) async {
    TSHaptics.selection();
    final next = current.where((d) => d != item).toList();
    await _writeAndRefresh(next);
  }

  Future<void> _add(List<String> current) async {
    final raw = _addCtrl.text.trim().toLowerCase();
    if (raw.isEmpty) return;
    if (raw.length > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('keep it short — 40 chars max')),
      );
      return;
    }
    if (current.contains(raw)) {
      _addCtrl.clear();
      return;
    }
    TSHaptics.success();
    await _writeAndRefresh([...current, raw]);
    _addCtrl.clear();
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_myDislikesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("things scout won't suggest",
              style: TSTextStyles.body(size: 14, color: TSColors.text)),
          const SizedBox(height: 2),
          Text(
            "scout learns these from chat. tap × to remove. or add your own.",
            style: TSTextStyles.caption(color: TSColors.muted),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: SizedBox(
                height: 14, width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: TSColors.lime),
              ),
            ),
            error: (_, __) => Text(
              "couldn't load — pull settings down to retry.",
              style: TSTextStyles.caption(color: TSColors.coral),
            ),
            data: (dislikes) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dislikes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "nothing yet. tell scout 'i hate crowds' or add one below.",
                        style: TSTextStyles.caption(color: TSColors.muted2),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: [
                        for (final d in dislikes)
                          _DislikeChip(
                            label: d,
                            onRemove: _saving ? null : () => _remove(dislikes, d),
                          ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _addCtrl,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(dislikes),
                        style: TSTextStyles.body(size: 14),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "add something (e.g. 'casinos')",
                          hintStyle: TSTextStyles.body(
                              size: 13, color: TSColors.muted),
                          filled: true,
                          fillColor: TSColors.s2,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: TSColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: TSColors.lime, width: 1.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _saving ? null : () => _add(dislikes),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: TSColors.lime,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('add',
                            style: TSTextStyles.label(
                                color: TSColors.bg, size: 12)),
                      ),
                    ),
                  ]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DislikeChip extends StatelessWidget {
  const _DislikeChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TSColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TSTextStyles.body(size: 12, color: TSColors.text2)),
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              alignment: Alignment.center,
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: onRemove == null ? TSColors.muted : TSColors.muted2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TSTextStyles.body(size: 15)),
                Text(description,
                    style: TSTextStyles.caption(color: TSColors.muted)),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_rounded,
                color: TSColors.lime, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Security — change password + change email bottom sheets.
// ─────────────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final n = _newCtrl.text;
    final c = _confirmCtrl.text;
    if (n.length < 6) {
      setState(() => _error = 'password must be at least 6 characters');
      return;
    }
    if (n != c) {
      setState(() => _error = "passwords don't match");
      return;
    }
    Navigator.of(context).pop((newPw: n));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: TSColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('change password', style: TSTextStyles.heading(size: 20)),
        ),
        const SizedBox(height: 14),
        _PwField(
          controller: _newCtrl,
          hint: 'new password',
          obscure: _obscureNew,
          onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 10),
        _PwField(
          controller: _confirmCtrl,
          hint: 'confirm new password',
          obscure: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: TSTextStyles.caption(color: TSColors.coral)),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('cancel',
                    style: TSTextStyles.title(
                        size: 13, color: TSColors.text)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TSColors.lime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('save',
                    style: TSTextStyles.title(
                        size: 13, color: TSColors.bg)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ChangeEmailSheet extends StatefulWidget {
  const _ChangeEmailSheet();

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _valid(String s) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(s.trim());
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (!_valid(v)) {
      setState(() => _error = 'enter a valid email');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: TSColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('change email', style: TSTextStyles.heading(size: 20)),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "we'll email a link to the new address to confirm.",
            style: TSTextStyles.caption(color: TSColors.muted),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          style: TSTextStyles.body(),
          decoration: InputDecoration(
            hintText: 'new@example.com',
            hintStyle: TSTextStyles.body(color: TSColors.muted),
            filled: true,
            fillColor: TSColors.s2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: TSTextStyles.caption(color: TSColors.coral)),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('cancel',
                    style: TSTextStyles.title(
                        size: 13, color: TSColors.text)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TSColors.lime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('send link',
                    style: TSTextStyles.title(
                        size: 13, color: TSColors.bg)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _PwField extends StatelessWidget {
  const _PwField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggleObscure,
  });
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      style: TSTextStyles.body(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TSTextStyles.body(color: TSColors.muted),
        filled: true,
        fillColor: TSColors.s2,
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: TSColors.muted,
            size: 18,
          ),
          onPressed: onToggleObscure,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

/// v1 Plan section — just the unspent Trip Pass count + restore.
///
/// Trip Pass is a consumable, not a subscription, so there's no
/// "manage plan" row. The count row is watchable via
/// [unspentTripPassesProvider] so a purchase made elsewhere (e.g.
/// the paywall sheet) updates this view automatically.
class _PlanSection extends ConsumerWidget {
  const _PlanSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unspent = ref.watch(unspentTripPassesProvider);
    final purchaseState = ref.watch(purchaseStateProvider);
    final restoring = purchaseState.isLoading;

    final count = unspent.valueOrNull ?? 0;
    final countLabel = count == 0
        ? 'no trip passes yet'
        : (count == 1 ? '1 trip pass' : '$count trip passes');

    Future<void> onRestore() async {
      TSHaptics.light();
      await ref.read(purchaseStateProvider.notifier).restoreTripPasses();
      if (!context.mounted) return;
      final err = ref.read(purchaseStateProvider).error;
      final restoredCount =
          ref.read(unspentTripPassesProvider).valueOrNull ?? 0;
      final msg = err != null
          ? "couldn't restore. try again?"
          : (restoredCount > 0
              ? 'purchases restored'
              : 'nothing to restore');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor:
              err != null ? TSColors.coral : TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TSColors.s1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: count > 0
                  ? TSColors.limeDim(0.4)
                  : TSColors.border,
            ),
          ),
          child: Row(children: [
            const Text('🎟️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(countLabel,
                      style: TSTextStyles.body(
                          size: 15, color: TSColors.text)),
                  Text(
                    count > 0
                        ? 'use on your next trip'
                        : 'buy one the next time you plan a trip',
                    style: TSTextStyles.caption(color: TSColors.muted),
                  ),
                ],
              ),
            ),
          ]),
        ),
        _Tile(
          icon: '♻️',
          label: restoring ? 'restoring…' : 'restore purchases',
          subtitle: 'for a previous purchase on this apple id',
          onTap: restoring ? () {} : onRestore,
        ),
      ],
    );
  }
}
