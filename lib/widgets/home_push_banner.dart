import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/push_service.dart';

// ─────────────────────────────────────────────────────────────
//  HOME — PUSH PERMISSIONS BANNER
//
//  A small dismissible lime banner that nudges users to turn on
//  push when:
//    - push auth status is NOT authorized / provisional
//    - user has at least one active trip (something to alert on)
//    - user hasn't dismissed the banner in the last 7 days
//
//  Tap → requests permission. If iOS already denied it, the
//  second call returns `denied` immediately; we route to system
//  notification settings so the user can flip it manually.
// ─────────────────────────────────────────────────────────────

class HomePushBanner extends ConsumerStatefulWidget {
  const HomePushBanner({super.key});

  @override
  ConsumerState<HomePushBanner> createState() => _HomePushBannerState();
}

class _HomePushBannerState extends ConsumerState<HomePushBanner> {
  bool? _show;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedAt =
        DateTime.tryParse(prefs.getString('push_banner_dismissed_at') ?? '');
    if (dismissedAt != null &&
        DateTime.now().difference(dismissedAt).inDays < 7) {
      if (mounted) setState(() => _show = false);
      return;
    }
    final status = await PushService.authorizationStatus();
    final ok = status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
    if (!mounted) return;
    setState(() => _show = !ok);
  }

  Future<void> _enable() async {
    TSHaptics.ctaCommit();
    final status = await PushService.requestPermission();
    if (!mounted) return;
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      setState(() => _show = false);
      return;
    }
    // Second-call denials on iOS skip the system sheet — punt to
    // settings so the user can toggle it themselves.
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> _dismiss() async {
    TSHaptics.light();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'push_banner_dismissed_at', DateTime.now().toIso8601String());
    if (mounted) setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_show != true) return const SizedBox();
    final trips = ref.watch(myTripsProvider).valueOrNull ?? const <Trip>[];
    if (trips.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(TSSpacing.md, 8, TSSpacing.md, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: TSColors.limeDim(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TSColors.limeDim(0.35)),
        ),
        child: Row(children: [
          const Text('🔔', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('never miss the reveal',
                    style: TSTextStyles.title(
                        size: 13, color: TSColors.text)),
                const SizedBox(height: 1),
                Text('turn on push — votes, reveals, squad pings',
                    style: TSTextStyles.caption(color: TSColors.muted2)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _enable,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TSColors.lime,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('enable',
                  style: TSTextStyles.label(
                      color: TSColors.bg, size: 10)),
            ),
          ),
          IconButton(
            onPressed: _dismiss,
            icon: const Icon(Icons.close_rounded,
                color: TSColors.muted, size: 16),
            visualDensity: VisualDensity.compact,
            tooltip: 'dismiss',
          ),
        ]),
      ),
    );
  }
}
