/// Compile-time feature flags.
///
/// These are plain `static const bool` fields, not remote config —
/// flipping one requires a rebuild. That's deliberate: the flags
/// guard code paths that touch monetisation and App Store products,
/// where we don't want a runtime toggle silently changing what users
/// are offered on a given build.
///
/// When a flag graduates (e.g. Explorer ships in v1.1), leave the
/// constant in place until every branch that references it has been
/// fully removed or collapsed — then delete the flag and its comment
/// in one cleanup pass.
class FeatureFlags {
  FeatureFlags._();

  /// v1.0 launch posture: paywall off.
  ///
  /// The Trip Pass paywall UI, entitlement service, RC wrappers,
  /// providers, and migration 046 are all shipped — but we don't
  /// expose any of it in v1.0 because:
  ///   1. `tripsquad.trippass` IAP is not yet live in App Store
  ///      Connect (requires product creation + tax/banking).
  ///   2. `REVENUECAT_API_KEY` is not set in `.env`.
  ///   3. Sandbox testing hasn't run end-to-end.
  ///
  /// Flipping this to `true` without all three being done risks a
  /// 2.1 rejection (reviewer taps "get trip pass" → store error).
  ///
  /// When true:
  ///   - `gateAndOpenTripWizard` enforces `canCreateTrip` + opens
  ///     the paywall sheet on block.
  ///   - The trip-creation wizard reserves / consumes / releases a
  ///     pass when the user is over the free concurrent-trip slot.
  ///   - Settings renders the "Plan" section (pass count + restore).
  ///
  /// When false (v1.0 default):
  ///   - Every user gets unlimited free trips.
  ///   - The paywall sheet is unreachable.
  ///   - Settings hides the Plan section entirely.
  static const bool paywallEnabled = false;

  /// v1.1 — Explorer subscription tier (unlimited trips, $X/mo or
  /// $Y/yr). When true, the paywall sheet renders a second card
  /// below Trip Pass and `TSProducts.explorerMonthly` /
  /// `TSProducts.explorerAnnual` become the source of truth for
  /// "unlimited host" checks. Until then the paywall is single-tier
  /// and the entitlements audit table sits dormant (see migration
  /// 045_entitlements.sql).
  static const bool showExplorerTier = false;

  /// Team tier — not in scope for v1 or v1.1. Kept here so the
  /// constant name is reserved and nobody accidentally ships a
  /// partial Team UI. Flip to true only when the Team product is
  /// fully wired in App Store Connect + RevenueCat and the
  /// workspace / shared-expense surfaces exist in-app.
  static const bool showTeamTier = false;
}
