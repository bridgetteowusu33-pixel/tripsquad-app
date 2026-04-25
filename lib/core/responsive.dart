import 'package:flutter/material.dart';

/// Responsive layout primitives.
///
/// TripSquad is designed mobile-first. On iPad (and any wide display)
/// we keep the same UI but cap content width per screen *type* and
/// center it. Backgrounds still fill the full screen — only foreground
/// content is constrained.
///
/// Three semantic widths, picked per screen intent:
/// - [form]: narrowest (520). Forms, wizards, preference steps.
///   Wide forms look empty and are harder to read.
/// - [content]: medium (680). Trip space tabs, reveal screen,
///   long-form scroll content.
/// - [feed]: widest (880). Home feed + list-heavy screens. Above the
///   [isWide] breakpoint we also switch such screens to grid layouts.
class TSResponsive {
  TSResponsive._();

  // Width tiers.
  static const double formWidth    = 520;
  static const double contentWidth = 840;
  static const double feedWidth    = 960;

  /// Max width for modal bottom sheets + dialogs on large screens.
  static const double modalMaxWidth = 520;

  // ── Semantic wrappers ──────────────────────────────────────────

  /// Form / wizard content. Keep narrow so long input rows scan well.
  static Widget form(Widget child) => _wrap(child, formWidth);

  /// Trip space tabs, reveal, and long-form content.
  static Widget content(Widget child) => _wrap(child, contentWidth);

  /// Home feed + list screens.
  static Widget feed(Widget child) => _wrap(child, feedWidth);

  /// Legacy alias. Older call sites still use [page] — we keep it
  /// pointing at [form] so they don't need to churn all at once.
  static Widget page(Widget child, {double? maxWidth}) =>
      _wrap(child, maxWidth ?? formWidth);

  // ── Breakpoints ────────────────────────────────────────────────

  /// True when the screen is wide enough to benefit from grid
  /// layouts (iPad portrait ≈ 810pt, landscape phones ≈ 900pt).
  static bool isWide(BuildContext c) =>
      MediaQuery.of(c).size.width >= 700;

  // ── Modal ──────────────────────────────────────────────────────

  /// Pass as `constraints:` on [showModalBottomSheet] to cap width
  /// on iPad; no-op on iPhone (width < modalMaxWidth).
  static BoxConstraints get modalConstraints =>
      const BoxConstraints(maxWidth: modalMaxWidth);

  // ── Internal ───────────────────────────────────────────────────

  static Widget _wrap(Widget child, double maxW) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: child,
    ),
  );
}
