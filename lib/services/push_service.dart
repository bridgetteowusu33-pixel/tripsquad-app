import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push notifications wiring. Call [PushService.init] from main.dart
/// after Supabase and Firebase are initialised.
///
/// Firebase setup required (one-time, not code):
///   iOS:
///     1. Create Firebase project, add iOS app with bundle id
///        `com.afialabs.tripsquad`
///     2. Download `GoogleService-Info.plist` → `ios/Runner/`
///     3. Add Push Notifications capability in Xcode
///     4. Upload APNs auth key to Firebase (Project Settings → Cloud Messaging)
///   Android:
///     1. Add Android app in Firebase project
///     2. Download `google-services.json` → `android/app/`
///     3. Verify `android/build.gradle` has google services plugin
///
/// Edge function setup:
///   - Deploy `supabase/functions/send_push`
///   - Set env `FCM_SERVICE_ACCOUNT_JSON` to the stringified Firebase
///     service account JSON
///   - Add a Supabase Database Webhook: table `notifications`, event
///     INSERT, URL = deployed function URL
class PushService {
  PushService._();

  static bool _initialised = false;

  /// Last-known FCM token — held in-memory so we can re-register it
  /// when an auth session shows up AFTER init() has already run.
  /// Needed because init() runs before Supabase restores the session
  /// on cold launch; without this the token was silently dropped.
  static String? _pendingToken;

  /// Current iOS/Android push authorization state. Used by the
  /// Home-screen permission banner to decide whether to prompt.
  /// Returns `denied` when Firebase isn't configured — safe default.
  static Future<AuthorizationStatus> authorizationStatus() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (_) {
      return AuthorizationStatus.denied;
    }
  }

  /// Prompt for push permissions. Re-prompts fire the system sheet
  /// only on the first call — after a denial, iOS returns the same
  /// status without showing the UI. Callers should fall back to
  /// `app_settings` if the status stays `denied`.
  static Future<AuthorizationStatus> requestPermission() async {
    try {
      final settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.denied) {
        if (Platform.isIOS) {
          await FirebaseMessaging.instance.getAPNSToken();
        }
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await _registerToken(token);
      }
      return settings.authorizationStatus;
    } catch (_) {
      return AuthorizationStatus.denied;
    }
  }

  static Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase not yet configured (missing plist/json). Swallow so the
      // rest of the app still runs; realtime/Supabase still work.
      if (kDebugMode) debugPrint('Firebase init skipped: $e');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    if (Platform.isIOS) {
      // Ensure APNs token is available before we ask for the FCM token
      await messaging.getAPNSToken();
    }

    final token = await messaging.getToken();
    if (token != null) {
      _pendingToken = token;
      await _registerToken(token);
    }

    // Re-register on token refresh
    messaging.onTokenRefresh.listen((t) {
      _pendingToken = t;
      _registerToken(t);
    });

    // Re-register when the user signs in after init() has already run.
    // On cold launch, Supabase may not have hydrated the session by
    // the time we first call getToken() — so _registerToken bails
    // with uid == null. Listening for signedIn events flushes the
    // pending token to push_tokens as soon as we have a uid.
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.tokenRefreshed ||
          event.event == AuthChangeEvent.initialSession) {
        final t = _pendingToken ??
            await FirebaseMessaging.instance.getToken();
        if (t != null) {
          _pendingToken = t;
          await _registerToken(t);
        }
      }
    });

    // Foreground: notifications arrive while app is open. The in-app
    // realtime stream on `notifications` already updates the UI, so we
    // just let it happen — no extra handler needed here.
    FirebaseMessaging.onMessage.listen((_) {});

    // Background tap (user opens notification): we don't deep-link yet.
    // TODO: wire to router for trip_id / dm_user_id navigation.
    FirebaseMessaging.onMessageOpenedApp.listen((_) {});
  }

  static Future<void> _registerToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      // Ensure a profiles row exists (OAuth signups don't trigger
      // profile auto-creation, so the push_tokens FK would fail).
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
      }, onConflict: 'id', ignoreDuplicates: true);

      // Delegate to the SECURITY DEFINER RPC (migration 047). A
      // direct upsert is blocked by RLS when the globally-unique
      // token already exists under another user_id (same device,
      // different account) — the existing-row check uses
      // auth.uid() = user_id on the row being OVERWRITTEN, not the
      // new row. The RPC handles stale-row cleanup + ownership
      // transfer atomically as a trusted server-side operation.
      await Supabase.instance.client.rpc('register_push_token', params: {
        'p_token': token,
        'p_platform': platform,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('push token register failed: $e');
    }
  }
}
