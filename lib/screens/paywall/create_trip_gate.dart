import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/feature_flags.dart';
import '../../services/entitlement_service.dart';
import 'paywall_sheet.dart';

/// Shared gate for every "+ plan a trip" CTA.
///
/// Flow (when [FeatureFlags.paywallEnabled] is true):
///   1. read `canCreateTrip(uid)` — true if the host has a free slot
///      or at least one unspent pass
///   2. if blocked, show the paywall
///   3. on purchase (or if they already had a slot), push the wizard
///
/// When [FeatureFlags.paywallEnabled] is false (v1.0 launch posture),
/// the gate is a no-op passthrough — every tap goes straight to the
/// wizard with no paywall, no reservation, no entitlement query.
Future<void> gateAndOpenTripWizard(
    BuildContext context, WidgetRef ref) async {
  if (!FeatureFlags.paywallEnabled) {
    context.push('/trip/create');
    return;
  }

  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;
  final svc = ref.read(entitlementServiceProvider);

  if (await svc.canCreateTrip(uid)) {
    if (!context.mounted) return;
    context.push('/trip/create');
    return;
  }

  final active = await svc.countActiveTripsAsHost(uid);
  if (!context.mounted) return;
  final r = await PaywallSheet.show(
    context,
    activeTripCount: active,
  );
  if (!r.purchased || !context.mounted) return;
  context.push('/trip/create');
}
