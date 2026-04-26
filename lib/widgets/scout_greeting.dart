import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';

/// Derives Scout's contextual greeting line for the Scout tab.
///
/// From the UX redesign (§H Scout Experience System):
/// - First open ever → intro
/// - Returning, no active trip → nostalgic check-in on last trip
/// - Returning, mid-trip planning → specific nudge
/// - Mid-trip (live mode) → day-specific hello
/// - Post-trip → memory prompt
/// - After long absence (>90 days) → re-engagement
///
/// Returns a ready-to-render string. Null while loading.
///
/// v1.1 — when called from inside a specific trip's Scout tab,
/// the calling widget should use [scoutTripGreetingProvider(tripId)]
/// so the greeting reflects THIS trip rather than whichever trip
/// happens to be live across the user's account.
final scoutGreetingProvider = Provider<String?>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  final trips = ref.watch(myTripsProvider).valueOrNull;
  final scoutHistory = ref.watch(scoutHistoryProvider).valueOrNull;

  if (profile == null) return null;

  final name = profile.nickname?.toLowerCase();
  final active = (trips ?? const <Trip>[])
      .where((t) => t.effectiveStatus != TripStatus.completed)
      .toList();
  final completed = (trips ?? const <Trip>[])
      .where((t) => t.effectiveStatus == TripStatus.completed)
      .toList();

  // Priority 1 — live trip
  final live = active.firstWhereOrNull(
    (t) => t.effectiveStatus == TripStatus.live,
  );
  if (live != null) {
    final dest = live.selectedDestination ?? live.name;
    return 'good morning. day in $dest. weather\'s clear, don\'t forget water.';
  }

  // Priority 2 — mid-trip planning waiting on someone
  final voting = active.firstWhereOrNull(
    (t) => t.effectiveStatus == TripStatus.voting,
  );
  if (voting != null) {
    return 'voting\'s open on ${voting.selectedDestination ?? voting.name}. want a hot take?';
  }

  final planning = active.firstWhereOrNull(
    (t) => t.effectiveStatus == TripStatus.revealed ||
        t.effectiveStatus == TripStatus.planning,
  );
  if (planning != null) {
    final dest = planning.selectedDestination ?? planning.name;
    return '$dest is locked in. ask me anything about it.';
  }

  final collecting = active.firstWhereOrNull(
    (t) => t.effectiveStatus == TripStatus.collecting,
  );
  if (collecting != null) {
    return 'your squad is filling prefs for ${collecting.name}. need help nudging?';
  }

  // Priority 3 — post-trip (within 14 days)
  if (completed.isNotEmpty) {
    final last = _mostRecent(completed);
    if (last != null) {
      final daysAgo = _daysSince(last.endDate ?? last.createdAt);
      final dest = last.selectedDestination ?? last.name;
      if (daysAgo != null && daysAgo <= 14) {
        return 'hope $dest delivered. drop a moment in the capsule?';
      }
      if (daysAgo != null && daysAgo > 90) {
        return 'been a minute since $dest. where\'s the next one?';
      }
    }
  }

  // Priority 4 — first-ever open (profile + no scout history)
  final hasHistory = (scoutHistory ?? const <ScoutMessage>[]).isNotEmpty;
  if (!hasHistory && completed.isEmpty && active.isEmpty) {
    final hi = name == null ? 'hey' : 'hey $name';
    return '$hi. i\'m scout — think of me as your travel-obsessed friend who never sleeps. where are you going next?';
  }

  // Fallback — contextual but quiet
  if (name != null) {
    return 'hey $name. what do you want to know?';
  }
  return 'what do you want to know?';
});

Trip? _mostRecent(List<Trip> trips) {
  if (trips.isEmpty) return null;
  trips.sort((a, b) {
    final ad = a.endDate ?? a.createdAt ?? DateTime(2000);
    final bd = b.endDate ?? b.createdAt ?? DateTime(2000);
    return bd.compareTo(ad);
  });
  return trips.first;
}

int? _daysSince(DateTime? date) {
  if (date == null) return null;
  return DateTime.now().difference(date).inDays;
}

/// One daily question, stable per calendar day. Rotates from a seed set.
/// Feeds Scout's memory when the user answers.
String scoutDailyQuestion() {
  const seeds = [
    'if you could leave tomorrow, where?',
    'what\'s the best trip you\'ve never told anyone about?',
    'one country you\'d move to for a year. go.',
    'coldest city you\'ve actually enjoyed?',
    'best meal you\'ve had on a trip?',
    'if you had £500 for a weekend, where?',
    'what\'s your unpopular travel opinion?',
    'one place that exceeded the hype?',
    'who\'s the person you\'ve been promising a trip to?',
    'which city gave you a story you still tell?',
    'a destination you rule out for no good reason?',
    'perfect sunday in a city — walk me through it.',
    'best solo trip destination in the world.',
    'underrated european city. go.',
    'most slept-on part of your own country?',
  ];
  final dayOfYear = DateTime.now().difference(DateTime(2020, 1, 1)).inDays;
  return seeds[dayOfYear % seeds.length];
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

/// v1.1 — trip-scoped Scout greeting. Used by the in-trip Scout
/// tab so the greeting reflects THIS trip's state, not whichever
/// trip is live across the user's account.
final scoutTripGreetingProvider =
    Provider.family<String?, String>((ref, tripId) {
  final trips = ref.watch(myTripsProvider).valueOrNull;
  if (trips == null) return null;
  final trip = trips.firstWhereOrNull((t) => t.id == tripId);
  if (trip == null) return null;
  final dest = trip.selectedDestination ?? trip.name;
  switch (trip.effectiveStatus) {
    case TripStatus.live:
      return "good morning. day in $dest. ask me anything for today.";
    case TripStatus.revealed:
    case TripStatus.planning:
      return '$dest is locked in. ask me anything about it.';
    case TripStatus.voting:
      return "voting's open on $dest. want a hot take?";
    case TripStatus.completed:
      return "$dest wrapped. anything you want to remember?";
    case TripStatus.collecting:
    case TripStatus.draft:
      return "tell me what kind of trip you want and i'll help shape it.";
  }
});
