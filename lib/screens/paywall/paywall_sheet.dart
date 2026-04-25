import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../services/revenuecat_service.dart';
import '../../widgets/motion.dart';

// TODO(v1.1): when FeatureFlags.showExplorerTier is true, render a
// second card below the Trip Pass card. Until then this sheet is
// single-tier by design.

/// Returned when the paywall dismisses. `purchased` is true if the
/// user bought a Trip Pass (or restored a previously-bought one that
/// hadn't been seen on this device) during the session.
class PaywallResult {
  const PaywallResult({required this.purchased});
  final bool purchased;
}

/// v1 paywall — single product, single card.
///
/// Shown from exactly one trigger: a host attempting to start a new
/// trip while another is still active. The caller passes
/// [activeTripCount] for future analytics / per-N messaging hooks;
/// v1 copy deliberately doesn't render a trip number (the counter
/// leaked the internal concurrency model and forced users to audit
/// their own history to parse the bullet).
class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet._({required this.activeTripCount});

  final int activeTripCount;

  static Future<PaywallResult> show(
    BuildContext context, {
    int activeTripCount = 1,
  }) async {
    TSHaptics.medium();
    final r = await showModalBottomSheet<PaywallResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TSColors.bg,
      constraints: TSResponsive.modalConstraints,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) =>
          PaywallSheet._(activeTripCount: activeTripCount),
    );
    return r ?? const PaywallResult(purchased: false);
  }

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  Package? _pkg;
  bool _purchasing = false;
  bool _restoring = false;
  bool _success = false;
  String? _error;
  int _shakeTick = 0;
  int _bloomTick = 0;

  /// Only used if RevenueCat returns no offering — keep in sync with
  /// the ASC price tier for `tripsquad.trippass`.
  static const _fallbackPrice = r'$4.99';

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  /// Price-label-only lookup. The actual purchase package is resolved
  /// inside `RevenueCatService.purchaseAndRecordTripPass()` at buy
  /// time — we don't pass the cached one in because offerings can
  /// refresh between mount and tap.
  Future<void> _loadOfferings() async {
    final offerings = await RevenueCatService.instance.fetchOfferings();
    if (!mounted) return;
    final current = offerings?.current;
    Package? pkg;
    if (current != null) {
      for (final p in current.availablePackages) {
        if (p.storeProduct.identifier == TSProducts.tripPass) {
          pkg = p;
          break;
        }
      }
    }
    setState(() => _pkg = pkg);
  }

  String get _priceLabel =>
      _pkg?.storeProduct.priceString ?? _fallbackPrice;

  // ── Actions ───────────────────────────────────────────────

  Future<void> _purchase() async {
    if (_purchasing || _success) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    TSHaptics.ctaCommit();

    try {
      final info =
          await RevenueCatService.instance.purchaseAndRecordTripPass();
      if (info == null) {
        // User cancelled the store sheet — silent reset.
        if (!mounted) return;
        setState(() => _purchasing = false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _success = true;
        _bloomTick++;
      });
      TSHaptics.ctaCommit();
      // Brief bloom beat (520ms — long enough to register the state
      // flip, short enough to stay snappy).
      await Future.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      Navigator.of(context)
          .pop(const PaywallResult(purchased: true));
    } on TimeoutException {
      _setError('no connection. check wifi and try again.');
    } catch (_) {
      _setError("couldn't process that. try again?");
    }
  }

  Future<void> _restore() async {
    if (_restoring || _purchasing) return;
    setState(() {
      _restoring = true;
      _error = null;
    });
    try {
      final info = await RevenueCatService.instance
          .restoreAndMirrorTripPasses();
      if (!mounted) return;
      final hasTripPassReceipt = info != null &&
          info.nonSubscriptionTransactions
              .any((t) => t.productIdentifier == TSProducts.tripPass);
      if (hasTripPassReceipt) {
        setState(() {
          _restoring = false;
          _success = true;
          _bloomTick++;
        });
        TSHaptics.ctaCommit();
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        Navigator.of(context)
            .pop(const PaywallResult(purchased: true));
        return;
      }
      setState(() => _restoring = false);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _restoring = false);
      _setError('no connection. check wifi and try again.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _restoring = false);
      _setError("couldn't restore. try again?");
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _purchasing = false;
      _error = message;
      _shakeTick++;
    });
    // Auto-clear so the CTA doesn't stay in an error state forever.
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _error = null);
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {/* silent */}
  }

  // ── Layout ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final reduceMotion = mq.disableAnimations;
    final height = mq.size.height * 0.92;

    return Container(
      height: height,
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: TSColors.bg,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(),
              const SizedBox(height: 32),
              _tripPassCard(reduceMotion),
              const SizedBox(height: 20),
              _ctaButton(reduceMotion),
              const SizedBox(height: 14),
              _restoreRow(),
              const SizedBox(height: 22),
              _legalFooter(),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Positioned(top: 12, right: 12, child: _closeButton()),
        if (_error != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: _errorToast(),
          ),
      ]),
    );
  }

  // ── Pieces ────────────────────────────────────────────────

  Widget _closeButton() {
    return Semantics(
      button: true,
      label: 'close',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          TSHaptics.light();
          Navigator.of(context)
              .pop(const PaywallResult(purchased: false));
        },
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: const Icon(
            Icons.close_rounded,
            color: TSColors.muted2,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline: 56pt is aggressive — FittedBox scales it down on
          // small phones (SE, mini) without clipping or wrapping.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: const [
                TextSpan(
                  text: "you've taken the squad ",
                  style: TextStyle(
                    fontFamily: 'Clash Display',
                    fontWeight: FontWeight.w800,
                    fontSize: 56,
                    height: 1.02,
                    letterSpacing: -1.96, // -0.035em @ 56pt
                    color: TSColors.text,
                  ),
                ),
                TextSpan(
                  text: 'somewhere.',
                  style: TextStyle(
                    fontFamily: 'Clash Display',
                    fontWeight: FontWeight.w800,
                    fontSize: 56,
                    height: 1.02,
                    letterSpacing: -1.96,
                    color: TSColors.lime,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '$_priceLabel one-time. no subscription.',
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w400,
              fontSize: 20,
              height: 1.4,
              color: TSColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripPassCard(bool reduceMotion) {
    final card = Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TSColors.lime, width: 2),
        boxShadow: [
          BoxShadow(
            color: TSColors.lime.withOpacity(0.15),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'trip pass',
                  style: TextStyle(
                    fontFamily: 'Clash Display',
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    height: 1,
                    color: TSColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _priceLabel,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Clash Display',
                        fontWeight: FontWeight.w800,
                        fontSize: 44,
                        height: 1,
                        color: TSColors.lime,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'one-time',
                    style: TSTextStyles.body(
                        color: TSColors.muted, size: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: TSColors.border),
          const SizedBox(height: 20),
          _bullet('start another squad trip right now'),
          const SizedBox(height: 14),
          _bullet('bring the whole crew'),
          const SizedBox(height: 14),
          _bullet('full trip space — plan, vote, pack, chat'),
        ],
      ),
    );

    // Quiet bloom when the purchase succeeds — makes the state flip
    // feel satisfying before the sheet dismisses.
    if (reduceMotion) return card;
    return TheBloom(trigger: _bloomTick, child: card);
  }

  Widget _bullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.check_rounded,
              color: TSColors.lime, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              fontSize: 18,
              height: 1.35,
              color: TSColors.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _ctaButton(bool reduceMotion) {
    final loading = _purchasing;
    final disabled = loading || _success;
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : _purchase,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TSColors.lime,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: TSColors.lime.withOpacity(0.32),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: TSColors.bg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('processing…',
                      style: _ctaTextStyle.copyWith(
                          color: TSColors.bg)),
                ],
              )
            : Text('get trip pass  →', style: _ctaTextStyle),
      ),
    );

    if (reduceMotion) return button;
    // Shake on error — `_shakeTick` increments each time we set an
    // error so flutter_animate replays the keyframe.
    return Animate(
      key: ValueKey(_shakeTick),
      effects: _shakeTick == 0
          ? []
          : [
              ShakeEffect(
                duration: 320.ms,
                hz: 8,
                offset: const Offset(10, 0),
              ),
            ],
      child: button,
    );
  }

  TextStyle get _ctaTextStyle => const TextStyle(
        fontFamily: 'Clash Display',
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.33, // -0.015em @ 22pt
        color: TSColors.bg,
      );

  Widget _restoreRow() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _restoring ? null : _restore,
        child: Text(
          _restoring ? 'restoring…' : 'restore purchases',
          style: TSTextStyles.body(
              color: TSColors.muted2, size: 14),
        ),
      ),
    );
  }

  Widget _legalFooter() {
    final style = const TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w300,
      fontSize: 11,
      height: 1.4,
      color: TSColors.muted,
    );
    final linkStyle =
        style.copyWith(decoration: TextDecoration.underline);
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: [
          TextSpan(
              text: 'no subscription. one-time purchase.\n',
              style: style),
          TextSpan(
            text: 'terms',
            style: linkStyle,
            recognizer: _tapRecognizer(
                () => _openUrl('https://gettripsquad.com/terms')),
          ),
          // Pipe with surrounding spaces, not U+00B7. On iPhones with
          // non-default fonts loaded the middle dot can fall back to
          // a period or a bullet; pipe is safe everywhere.
          TextSpan(text: '  |  ', style: style),
          TextSpan(
            text: 'privacy',
            style: linkStyle,
            recognizer: _tapRecognizer(
                () => _openUrl('https://gettripsquad.com/privacy')),
          ),
        ]),
      ),
    );
  }

  final List<TapGestureRecognizer> _recognizers = [];

  TapGestureRecognizer _tapRecognizer(VoidCallback onTap) {
    final r = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(r);
    return r;
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Widget _errorToast() {
    return IgnorePointer(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: TSColors.coral.withOpacity(0.94),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: TSColors.coral.withOpacity(0.28),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          _error ?? '',
          textAlign: TextAlign.center,
          style: TSTextStyles.body(
              color: Colors.white, size: 14, weight: FontWeight.w600),
        ),
      ),
    );
  }
}

