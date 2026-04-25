import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/revenuecat_service.dart';
import 'entitlement_providers.dart';

/// State of the current Trip Pass purchase / restore attempt.
///
/// Consumers read this to drive UI (spinners, error toasts) and the
/// notifier is the one-way-door for in-app purchase flow. Paywall
/// sheet still retains its own local "purchasing/error" state for
/// its motion effects (shake / bloom), but any other surface that
/// needs to kick off a purchase should go through here so the
/// unspent-pass count refreshes automatically on success.
final purchaseStateProvider = StateNotifierProvider<
    PurchaseStateNotifier, AsyncValue<CustomerInfo?>>(
  PurchaseStateNotifier.new,
);

class PurchaseStateNotifier
    extends StateNotifier<AsyncValue<CustomerInfo?>> {
  PurchaseStateNotifier(this._ref)
      : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Buy a Trip Pass end-to-end (store → supabase mirror → sync).
  /// Errors — including [TimeoutException] from the service's 15-sec
  /// ceiling — land as `AsyncValue.error` so callers can distinguish
  /// them via `state.error is TimeoutException`.
  Future<void> purchaseTripPass() async {
    state = const AsyncValue.loading();
    try {
      final info = await RevenueCatService.instance
          .purchaseAndRecordTripPass();
      state = AsyncValue.data(info);
      if (info != null) {
        // New pass row — refresh the settings count + anything else
        // that watches it.
        _ref.invalidate(unspentTripPassesProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Restore + mirror previously-bought passes. Same shape as
  /// [purchaseTripPass] — on success the unspent count is refreshed.
  Future<void> restoreTripPasses() async {
    state = const AsyncValue.loading();
    try {
      final info = await RevenueCatService.instance
          .restoreAndMirrorTripPasses();
      state = AsyncValue.data(info);
      if (info != null) {
        _ref.invalidate(unspentTripPassesProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
