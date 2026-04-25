import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/entitlement_service.dart';

/// How many unspent Trip Passes the signed-in user holds. Used by the
/// settings Plan row and by reactive refresh after a successful
/// purchase (purchaseStateProvider invalidates this).
///
/// Returns 0 when unauthenticated — calling screens don't need to
/// branch on auth state.
final unspentTripPassesProvider = FutureProvider.autoDispose<int>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return 0;
  return ref.read(entitlementServiceProvider).unspentTripPassCount(uid);
});

/// How many of the user's trips are currently "active" (status in
/// {draft, collecting, voting, revealed, planning, live}). Drives the
/// dynamic "unlock trip #N" copy in the paywall sheet.
final activeTripCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return 0;
  return ref.read(entitlementServiceProvider).countActiveTripsAsHost(uid);
});
