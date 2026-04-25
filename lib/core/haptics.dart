import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
//  TRIPSQUAD HAPTIC FEEDBACK SYSTEM
//
//  Two layers: primitives (lowest level — map to HapticFeedback)
//  and semantic vocabulary (named moments from the UX redesign
//  spec). Use the semantic helpers everywhere — primitives stay
//  available but shouldn't appear in new code.
//
//  Rule of thumb from the redesign: if two unrelated actions fire
//  the same haptic pattern, the app starts feeling generic. Keep
//  the vocabulary consistent across surfaces.
// ─────────────────────────────────────────────────────────────

class TSHaptics {
  TSHaptics._();

  // ── Primitives ──────────────────────────────────────────────
  static void light()     => HapticFeedback.lightImpact();
  static void medium()    => HapticFeedback.mediumImpact();
  static void heavy()     => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();

  // ── Semantic vocabulary (use these by name) ────────────────

  /// Tab switch in the bottom nav. One tick; never more.
  static void tabSwitch() => HapticFeedback.selectionClick();

  /// CTA pressed (tap down). Signals the button registered the touch.
  static void ctaTap() => HapticFeedback.lightImpact();

  /// CTA committed (action fired — save, submit, send, etc).
  static void ctaCommit() => HapticFeedback.mediumImpact();

  /// Vote committed. Medium + pause + light — feels like a stamp.
  static Future<void> voteCommit() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    HapticFeedback.lightImpact();
  }

  /// Any squad member just voted (the "bloom" moment on the tide strip).
  static void squadVoteBloom() => HapticFeedback.lightImpact();

  /// Reveal sequence per beat — intensity maps to sequence moment.
  /// 0 = pulse, 1 = line collapse, 2 = type character,
  /// 3 = flag arrival, 4 = completion.
  static void revealBeat(int intensity) {
    switch (intensity) {
      case 0: HapticFeedback.lightImpact(); break;
      case 1: HapticFeedback.mediumImpact(); break;
      case 2: HapticFeedback.selectionClick(); break;
      case 3: HapticFeedback.heavyImpact(); break;
      case 4: HapticFeedback.heavyImpact(); break;
    }
  }

  /// Error — two quick selection ticks, not a jarring heavy.
  static Future<void> errorTick() async {
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 60));
    HapticFeedback.selectionClick();
  }

  /// Success — heavy + light. Used for completed trip, full pack, etc.
  static Future<void> success() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  /// Memory Capsule unlock — a deliberate, slow heavy. Rare event.
  static void capsuleUnlock() => HapticFeedback.heavyImpact();

  /// Scout reply arriving — softest haptic in the palette.
  static void scoutArrival() => HapticFeedback.lightImpact();

  /// Packing 100% reached.
  static Future<void> packedFull() => success();

  /// Long-press to react (chat) — single medium with anticipation.
  static void longPressReact() => HapticFeedback.mediumImpact();

  /// Pull-to-refresh snap point reached.
  static void refreshTrigger() => HapticFeedback.mediumImpact();

  /// Drumroll — rapid light ticks (reveal suspense, legacy).
  static Future<void> drumroll({int beats = 8, int intervalMs = 150}) async {
    for (var i = 0; i < beats; i++) {
      HapticFeedback.lightImpact();
      await Future.delayed(Duration(milliseconds: intervalMs));
    }
  }

  // ── Deprecated name used in older code ─────────────────────
  /// @deprecated use [errorTick] instead.
  static Future<void> error() => errorTick();
}
