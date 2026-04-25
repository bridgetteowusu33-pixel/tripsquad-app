import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';

/// Thin wrapper around RevenueCat. Handles init, offerings lookup,
/// purchase + restore flows, and tells the rest of the app which
/// entitlements are active.
///
/// Compiles without a configured SDK key — [init] returns false
/// silently in that case so TestFlight builds don't crash before the
/// App Store Connect IAP products are wired. Any method that requires
/// a live SDK returns a safe default when uninitialised.
class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  static bool _inited = false;
  static bool get isInitialised => _inited;

  /// Call from main() after Supabase.initialize. Safe to call when
  /// TSEnv.revenueCatKey is empty — just skips init.
  Future<bool> init({required String apiKey}) async {
    if (_inited) return true;
    if (apiKey.isEmpty || apiKey == 'placeholder') {
      if (kDebugMode) {
        debugPrint('[RC] skipping init — apiKey empty/placeholder');
      }
      return false;
    }
    try {
      await Purchases.setLogLevel(
          kDebugMode ? LogLevel.debug : LogLevel.warn);
      final config = PurchasesConfiguration(apiKey);
      final supabaseUid = Supabase.instance.client.auth.currentUser?.id;
      if (supabaseUid != null) config.appUserID = supabaseUid;
      await Purchases.configure(config);
      _inited = true;
      // Re-identify on sign-in events so entitlements track the user.
      Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
        final uid = event.session?.user.id;
        try {
          if (uid != null) {
            await Purchases.logIn(uid);
          } else {
            await Purchases.logOut();
          }
        } catch (_) {
          // Non-fatal — RC can recover on next purchase attempt.
        }
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[RC] init failed: $e');
      return false;
    }
  }

  /// Returns the available offerings (tier packages). Null when the
  /// SDK isn't initialised or the network call fails; caller should
  /// fall back to hardcoded price strings.
  Future<Offerings?> fetchOfferings() async {
    if (!_inited) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      if (kDebugMode) debugPrint('[RC] fetchOfferings failed: $e');
      return null;
    }
  }

  /// Purchases a given package. Returns the CustomerInfo on success,
  /// null on user cancellation, or throws [PurchasesErrorCode] for
  /// store-side failures.
  Future<CustomerInfo?> purchasePackage(Package pkg) async {
    if (!_inited) {
      throw StateError('RevenueCat not initialised');
    }
    try {
      final result = await Purchases.purchasePackage(pkg);
      return result;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return null;
      rethrow;
    }
  }

  /// Restore previous purchases (App Store account linked).
  Future<CustomerInfo?> restore() async {
    if (!_inited) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('[RC] restore failed: $e');
      return null;
    }
  }

  /// Snapshot of whether a given entitlement is currently active.
  Future<bool> hasActiveEntitlement(String entitlementId) async {
    if (!_inited) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      final ent = info.entitlements.active[entitlementId];
      return ent != null && ent.isActive;
    } catch (_) {
      return false;
    }
  }

  /// True when the user has Explorer OR Team — i.e. "unlimited trips"
  /// entitled. Used by [EntitlementService.canCreateTrip] etc.
  Future<bool> hasUnlimited() async {
    if (!_inited) return false;
    return await hasActiveEntitlement(TSProducts.entExplorer) ||
        await hasActiveEntitlement(TSProducts.entTeam);
  }

  /// Force a re-fetch from the server. Call after a successful
  /// purchase to make sure [hasActiveEntitlement] reflects it.
  Future<void> syncPurchases() async {
    if (!_inited) return;
    try {
      await Purchases.syncPurchases();
    } catch (_) {}
  }

  // ─── Trip Pass ────────────────────────────────────────────────
  //
  // Single entry point for the v1 paywall. The UI calls exactly one
  // method — `purchaseAndRecordTripPass()` — and the service owns the
  // store call, the Supabase mirror, the sync, and the timeout. This
  // keeps the "insert into trip_passes" logic next to the RevenueCat
  // call that produces the receipt, instead of leaking a direct DB
  // write into the widget layer where it's hard to test and easy to
  // drift from.

  /// Hard ceiling on the full purchase-and-record sequence. On a
  /// throttled / flaky network (Apple reviewers do this deliberately)
  /// spinning forever leads to a 2.1 rejection — so we fail fast with
  /// a [TimeoutException] that the caller can translate into a
  /// "check wifi and try again" message.
  static const _purchaseTimeout = Duration(seconds: 15);

  /// Purchase a Trip Pass and mirror the receipt into `trip_passes`.
  ///
  /// Returns:
  ///   - non-null [CustomerInfo] on a successful buy + mirror
  ///   - null if the user cancelled the store sheet
  ///
  /// Throws:
  ///   - [StateError] if RC is not initialised or no Trip Pass
  ///     offering is available
  ///   - [TimeoutException] if the full round-trip exceeds 15s —
  ///     caller should surface a distinct network message
  ///   - rethrows any [PurchasesErrorCode] other than user-cancel
  Future<CustomerInfo?> purchaseAndRecordTripPass() async {
    if (!_inited) throw StateError('RevenueCat not initialised');
    final pkg = await _tripPassPackage();
    if (pkg == null) {
      throw StateError('trip pass offering not configured');
    }
    return _runPurchase(pkg).timeout(_purchaseTimeout);
  }

  Future<CustomerInfo?> _runPurchase(Package pkg) async {
    final info = await purchasePackage(pkg);
    if (info == null) return null; // user cancelled
    await _insertTripPassRow(info, pkg);
    await syncPurchases();
    return info;
  }

  Future<Package?> _tripPassPackage() async {
    final offerings = await fetchOfferings();
    final current = offerings?.current;
    if (current == null) return null;
    for (final p in current.availablePackages) {
      if (p.storeProduct.identifier == TSProducts.tripPass) return p;
    }
    return null;
  }

  /// Insert the receipt into `trip_passes`. Idempotent via the
  /// UNIQUE(purchase_token) constraint — duplicates (e.g. from a
  /// later restore call that re-surfaces the same receipt) swallow
  /// the 23505 `unique_violation` silently. Any other Postgrest
  /// error rethrows so the caller can surface it.
  Future<void> _insertTripPassRow(
      CustomerInfo info, Package pkg) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final token = _tripPassTokenFor(info, uid);
    try {
      await Supabase.instance.client.from('trip_passes').insert({
        'user_id': uid,
        'purchase_token': token,
        'product_id': TSProducts.tripPass,
        'price_paid_cents': (pkg.storeProduct.price * 100).round(),
        'currency': pkg.storeProduct.currencyCode,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return; // duplicate receipt, no-op
      rethrow;
    }
  }

  /// Prefer the App Store receipt's `transactionIdentifier` so the
  /// UNIQUE constraint actually dedups across devices / restores.
  /// Fall back to a synthetic token only when no matching receipt is
  /// visible yet (first-buy edge where `nonSubscriptionTransactions`
  /// hasn't propagated into the cached CustomerInfo).
  String _tripPassTokenFor(CustomerInfo info, String uid) {
    final txns = info.nonSubscriptionTransactions
        .where((t) => t.productIdentifier == TSProducts.tripPass)
        .toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    if (txns.isNotEmpty) return txns.first.transactionIdentifier;
    return '${uid}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Restore purchases and mirror any previously-bought Trip Pass
  /// receipts into `trip_passes`. Idempotent — relies on the same
  /// unique constraint as the purchase path.
  ///
  /// Returns the [CustomerInfo] from RevenueCat, or null when the
  /// SDK is not initialised. Throws [TimeoutException] on a 15s
  /// round-trip exceedance.
  Future<CustomerInfo?> restoreAndMirrorTripPasses() async {
    if (!_inited) return null;
    return _runRestore().timeout(_purchaseTimeout);
  }

  Future<CustomerInfo?> _runRestore() async {
    final info = await restore();
    if (info == null) return null;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return info;
    final txns = info.nonSubscriptionTransactions
        .where((t) => t.productIdentifier == TSProducts.tripPass);
    for (final t in txns) {
      try {
        await Supabase.instance.client.from('trip_passes').insert({
          'user_id': uid,
          'purchase_token': t.transactionIdentifier,
          'product_id': TSProducts.tripPass,
        });
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
      }
    }
    return info;
  }
}
