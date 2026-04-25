import 'dart:io';
import 'package:functions_client/functions_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Convert raw exceptions into short, lowercase, Gen-Z-flavoured messages
/// safe to show to end users. Preserves specificity for known errors
/// (duplicate tag, no network, auth failures) and falls back to a generic
/// "something broke" for unknowns.
String humanizeError(Object e) {
  // ── Supabase Edge Function failures ──────────────────────────
  // `functions_client` throws a FunctionException on any non-2xx.
  // Extract the real message from `details` so the snackbar is useful.
  if (e is FunctionException) {
    final d = e.details;
    String? msg;
    if (d is Map) {
      msg = (d['error'] ?? d['message'] ?? d['code'])?.toString();
    } else if (d is String && d.isNotEmpty) {
      msg = d;
    }
    if (e.status == 401 || e.status == 403) {
      return 'your session expired. sign in again.';
    }
    if (e.status == 429) {
      return 'rate limited. try again in a minute.';
    }
    if (msg != null && msg.isNotEmpty) return 'scout error: $msg';
    return 'scout error [${e.status}]';
  }

  // ── Supabase Postgrest (database constraint violations, etc.) ──
  if (e is PostgrestException) {
    switch (e.code) {
      case '23505': // unique_violation
        if (e.message.contains('profiles_tag_key')) {
          return 'that tag is taken. try another ✦';
        }
        if (e.message.contains('push_tokens')) {
          return 'device already registered';
        }
        return 'already exists';
      case '23503': // foreign_key_violation
        return "that trip or person doesn't exist anymore";
      case '23514': // check_violation
        return "that value isn't allowed";
      case '42501': // insufficient_privilege
        return "you don't have access to that";
      case 'PGRST116': // no rows returned when expected
        return "couldn't find that";
    }
    return "something went wrong on our end. try again.";
  }

  // ── Supabase Auth ──
  if (e is AuthException) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'email or password is off. try again.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'you already have an account. sign in instead.';
    }
    if (msg.contains('email not confirmed')) {
      return 'check your email and tap the confirmation link first.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'slow down — too many attempts. try again in a minute.';
    }
    if (msg.contains('invalid token') || msg.contains('jwt')) {
      return 'your session expired. sign in again.';
    }
    return 'sign in failed. try again.';
  }

  // ── Network / DNS / timeout ──
  if (e is SocketException || e is HttpException) {
    return 'no connection. check your wifi and try again.';
  }
  final msg = e.toString().toLowerCase();
  if (msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('no host specified') ||
      msg.contains('network is unreachable')) {
    return 'no connection. check your wifi and try again.';
  }
  if (msg.contains('timeout') || msg.contains('timed out')) {
    return 'that took too long. try again.';
  }

  // ── Apple / Sign in with Apple cancelled ──
  if (msg.contains('canceled') ||
      msg.contains('cancelled') ||
      msg.contains('authorization_canceled')) {
    return 'sign in cancelled.';
  }

  // ── Edge function errors we've tagged ourselves ──
  // Strings like "Exception: scout chat failed [500]: ...".
  // These are already user-readable; surface them verbatim (without the
  // Exception: prefix and the trailing stack-trace noise).
  final taggedFn = RegExp(
          r'(scout chat|scout in-trip|packing generation|itinerary generation|photo refresh) failed \[\d+\]:?\s*(.*)',
          caseSensitive: false)
      .firstMatch(e.toString());
  if (taggedFn != null) {
    final detail = taggedFn.group(2)?.trim() ?? '';
    final what = taggedFn.group(1)!.toLowerCase();
    if (detail.isEmpty) return '$what is unreachable.';
    return '$what: $detail';
  }

  return "something broke. try again in a sec.";
}
