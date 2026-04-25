import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final entitlementServiceProvider =
    Provider<EntitlementService>((_) => EntitlementService._());

/// v1 entitlement model.
///
/// Free tier: a host may have exactly one active trip at a time.
/// "Active" means `status ∈ {draft, collecting, voting, revealed,
/// planning, live}`. Completed trips don't count.
///
/// Beyond one active trip the host needs an unconsumed Trip Pass. The
/// pass is a one-time consumable; each pass burns on exactly one new
/// trip and does not expire.
///
/// Slot-assignment: the gate [canCreateTrip] tells you whether a new
/// trip is *allowed*, but it doesn't hold a slot. When a paid slot is
/// used the caller MUST:
///
///   final passId = await reserveTripPass(userId);
///   if (passId == null) { /* show paywall, then retry */ }
///   try {
///     final trip = await createTrip(...);
///     await consumeReservedPass(passId, trip.id);
///   } catch (_) {
///     await releaseReservedPass(passId);
///     rethrow;
///   }
///
/// Reservations auto-release after 5 min via `release_stale_reservations`
/// so a crashed client doesn't permanently burn the pass.
class EntitlementService {
  EntitlementService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ── Read-only queries ─────────────────────────────────────

  /// Pre-paywall gate: can this user start a trip right now without
  /// paying? This does NOT reserve anything — the caller still has to
  /// call [reserveTripPass] when they're ready to commit a paid slot.
  Future<bool> canCreateTrip(String userId) async {
    final active = await countActiveTripsAsHost(userId);
    if (active == 0) return true;
    final unspent = await unspentTripPassCount(userId);
    return unspent > 0;
  }

  Future<int> countActiveTripsAsHost(String userId) async {
    try {
      final r = await _db.rpc(
        'count_active_trips_as_host',
        params: {'p_user_id': userId},
      );
      return (r as int?) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Entitlement] countActiveTripsAsHost: $e');
      }
      // Fail open — the paywall will re-check and the reserve RPC is
      // the real gate against paid-slot creation.
      return 0;
    }
  }

  Future<int> unspentTripPassCount(String userId) async {
    try {
      final r = await _db.rpc(
        'count_unspent_trip_passes',
        params: {'p_user_id': userId},
      );
      return (r as int?) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Entitlement] unspentTripPassCount: $e');
      }
      return 0;
    }
  }

  // ── Reserve / consume / release ───────────────────────────

  /// Atomically reserve one unspent pass for this user. Returns the
  /// reserved pass id, or null when the user has none available.
  ///
  /// The underlying RPC uses `FOR UPDATE SKIP LOCKED`, so two parallel
  /// reserve calls for the same user will each claim a distinct row
  /// (or the second call returns null if only one pass exists).
  Future<String?> reserveTripPass(String userId) async {
    try {
      final r = await _db.rpc(
        'reserve_trip_pass',
        params: {'p_user_id': userId},
      );
      return r as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('[Entitlement] reserveTripPass: $e');
      return null;
    }
  }

  /// Bind a reserved pass to the created trip. Idempotent — safe to
  /// call twice if the caller retries on a flaky network.
  Future<void> consumeReservedPass(String passId, String tripId) async {
    try {
      await _db.rpc(
        'consume_reserved_pass',
        params: {'p_pass_id': passId, 'p_trip_id': tripId},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Entitlement] consumeReservedPass: $e');
      }
    }
  }

  /// Release a reservation without consuming — wizard cancel, trip
  /// create failed, etc. Safe to call on an already-consumed or
  /// already-released pass (no-op).
  Future<void> releaseReservedPass(String passId) async {
    try {
      await _db.rpc(
        'release_reserved_pass',
        params: {'p_pass_id': passId},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Entitlement] releaseReservedPass: $e');
      }
    }
  }
}
