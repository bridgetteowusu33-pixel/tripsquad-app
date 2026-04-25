import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/responsive.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'services/push_service.dart';
import 'services/revenuecat_service.dart';

/// App-wide messenger key so any code path can surface a SnackBar —
/// including flows that navigate away before the toast fires (e.g.
/// account deletion signs out, pushes to `/auth`, then toasts
/// "account deleted" on the destination screen's scaffold).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: TSColors.bg,
    ),
  );

  // Supabase. Using implicit flow instead of PKCE because our
  // password-reset email links open on a different device/browser
  // than the one that initiated the reset — PKCE would require the
  // code_verifier to travel cross-device, which isn't supported.
  // Implicit flow puts the access_token in the URL hash so the web
  // reset page can consume it directly.
  await Supabase.initialize(
    url: TSEnv.supabaseUrl,
    anonKey: TSEnv.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );

  // Push notifications (Firebase — no-op if plist/json not configured yet)
  await PushService.init();

  // RevenueCat (no-ops if REVENUECAT_API_KEY is empty — TestFlight-safe).
  await RevenueCatService.instance.init(apiKey: TSEnv.revenueCatKey);

  runApp(const ProviderScope(child: TripSquadApp()));
}

class TripSquadApp extends ConsumerWidget {
  const TripSquadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TripSquad',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: buildTheme(),
      routerConfig: router,
      builder: (context, child) {
        // Text scaling:
        // - Phones: respect the user's OS setting but clamp to
        //   0.8–1.2 so extreme sizes don't break layouts.
        // - iPad (wide screens): bump the baseline by 1.15 so body
        //   text and CTAs don't look microscopic on a 13" screen,
        //   while still honouring the user's OS preference on top.
        final mq = MediaQuery.of(context);
        final base = TSResponsive.isWide(context) ? 1.35 : 1.0;
        final scaled = mq.textScaler.scale(base).clamp(0.8, 1.6);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scaled)),
          child: child!,
        );
      },
    );
  }
}
