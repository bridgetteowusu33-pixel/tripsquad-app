import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

part 'providers.g.dart';

// ── Auth state (stream) ───────────────────────────────────────
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return ref.read(authServiceProvider).authStateChanges;
}

// ── Current user profile ──────────────────────────────────────
@riverpod
Future<AppUser?> currentProfile(CurrentProfileRef ref) {
  // Rebuild whenever auth changes
  ref.watch(authStateProvider);
  return ref.read(authServiceProvider).fetchCurrentProfile();
}

// ─────────────────────────────────────────────────────────────
//  TRIP PROVIDERS
// ─────────────────────────────────────────────────────────────

// ── All trips for the current user ───────────────────────────
@riverpod
Future<List<Trip>> myTrips(MyTripsRef ref) {
  ref.watch(authStateProvider);
  return ref.read(tripServiceProvider).fetchMyTrips();
}

// ── Single trip (with full details) ──────────────────────────
@riverpod
Future<Trip> tripDetail(TripDetailRef ref, String tripId) {
  return ref.read(tripServiceProvider).fetchTrip(tripId);
}

// ── Real-time trip stream ─────────────────────────────────────
@riverpod
Stream<Trip> tripStream(TripStreamRef ref, String tripId) {
  return ref.read(tripServiceProvider).watchTrip(tripId);
}

// ── Real-time squad stream ────────────────────────────────────
@riverpod
Stream<List<SquadMember>> squadStream(SquadStreamRef ref, String tripId) {
  return ref.read(tripServiceProvider).watchSquad(tripId);
}

// ─────────────────────────────────────────────────────────────
//  NOTIFICATIONS / TRIP EVENTS / DMs / SCOUT PROVIDERS
//  Every user linked to a trip receives all updates through
//  these streams. Fan-out happens in Postgres triggers defined
//  in supabase/migrations/002_tags_events_notifications.sql.
// ─────────────────────────────────────────────────────────────

@riverpod
Stream<List<NotificationItem>> myNotifications(MyNotificationsRef ref) {
  ref.watch(authStateProvider);
  return ref.read(notificationsServiceProvider).watchMine();
}

@riverpod
Stream<int> unreadNotifCount(UnreadNotifCountRef ref) {
  ref.watch(authStateProvider);
  return ref
      .read(notificationsServiceProvider)
      .watchMine()
      .map((list) => list.where((n) => n.readAt == null).length);
}

@riverpod
Stream<List<TripEvent>> tripEventsStream(
    TripEventsStreamRef ref, String tripId) {
  return ref.read(tripEventsServiceProvider).watchTripEvents(tripId);
}

/// Activity ticker for Home — recent events across all of a user's trips.
@riverpod
Future<List<TripEvent>> myRecentActivity(MyRecentActivityRef ref) {
  ref.watch(authStateProvider);
  return ref.read(tripEventsServiceProvider).fetchMyRecentActivity();
}

@riverpod
Stream<List<DirectMessage>> myDms(MyDmsRef ref) {
  ref.watch(authStateProvider);
  return ref.read(dmServiceProvider).watchAllMine();
}

@riverpod
Stream<List<DirectMessage>> dmThread(DmThreadRef ref, String otherUserId) {
  return ref.read(dmServiceProvider).watchThread(otherUserId);
}

/// Reactions on DMs in the current user's thread with [otherUserId].
/// Returned flat; filter by message_id at render time. Migration 018.
@riverpod
Stream<List<DmReaction>> dmThreadReactions(
    DmThreadReactionsRef ref, String otherUserId) {
  return ref.read(dmServiceProvider).watchThreadReactions(otherUserId);
}

@riverpod
Stream<List<ScoutMessage>> scoutHistory(ScoutHistoryRef ref) {
  ref.watch(authStateProvider);
  return ref.read(scoutServiceProvider).watchHistory();
}

/// Trip-scoped Scout chat — only messages tagged with this trip_id.
/// Used by the in-trip Scout tab on solo trips. v1.1.
@riverpod
Stream<List<ScoutMessage>> scoutTripHistory(
    ScoutTripHistoryRef ref, String tripId) {
  ref.watch(authStateProvider);
  return ref.read(scoutServiceProvider).watchTripHistory(tripId);
}

/// Consecutive-day streak of Scout engagement. Counts back from today
/// (or yesterday if today has no user message yet) — the streak is the
/// longest unbroken run of days on which the user sent ≥1 message to
/// Scout. Used to render a streak pill in the Scout tab header.
@riverpod
Future<int> scoutStreak(ScoutStreakRef ref) async {
  ref.watch(authStateProvider);
  // Rebuild when the history stream ticks.
  ref.watch(scoutHistoryProvider);
  final msgs = await ref.read(scoutServiceProvider).watchHistory().first;
  final userDays = <String>{};
  for (final m in msgs) {
    if (m.role != 'user') continue;
    final ts = m.createdAt;
    if (ts == null) continue;
    final d = ts.toLocal();
    userDays.add('${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}');
  }
  if (userDays.isEmpty) return 0;
  String keyOf(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Allow grace: if today has no message, start counting from yesterday.
  var cursor = userDays.contains(keyOf(today))
      ? today
      : today.subtract(const Duration(days: 1));
  var streak = 0;
  while (userDays.contains(keyOf(cursor))) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Map of user_id → avatar_url for every squad member across my trips.
/// Cached until `myTrips` changes. Used to render photo avatars on trip
/// cards (Home + Trips tab).
@riverpod
Future<Map<String, String?>> squadAvatars(SquadAvatarsRef ref) async {
  final trips = await ref.watch(myTripsProvider.future);
  final uids = <String>{};
  for (final t in trips) {
    for (final m in t.squadMembers) {
      if (m.userId != null) uids.add(m.userId!);
    }
  }
  if (uids.isEmpty) return {};
  final profiles = await ref
      .read(dmServiceProvider)
      .fetchProfilesByIds(uids.toList());
  return {
    for (final e in profiles.entries)
      e.key: e.value['avatar_url'] as String?,
  };
}

// ── Packing list (realtime per trip) ─────────────────────────
@riverpod
Stream<List<PackingEntry>> packingItems(
    PackingItemsRef ref, String tripId) {
  return ref.read(packingServiceProvider).watchTrip(tripId);
}

// ── Chat messages (realtime per trip) ────────────────────────
@riverpod
Stream<List<ChatMessage>> chatMessages(
    ChatMessagesRef ref, String tripId) {
  return ref.read(chatServiceProvider).watchMessages(tripId);
}

@riverpod
Stream<List<ChatReaction>> chatReactions(
    ChatReactionsRef ref, String tripId) {
  return ref.read(chatServiceProvider).watchReactions(tripId);
}

// ── Itinerary (first-class activities + notes) ───────────────
@riverpod
Stream<List<ItineraryActivity>> itineraryStream(
    ItineraryStreamRef ref, String tripId) {
  return ref.read(itineraryServiceProvider).watch(tripId);
}

@riverpod
Stream<List<ItineraryNote>> itineraryNotesStream(
    ItineraryNotesStreamRef ref, String itemId) {
  return ref.read(itineraryServiceProvider).watchNotes(itemId);
}

// ── Stays + Eats recommendations ─────────────────────────────
// Realtime stream of Scout's hotel + restaurant + best-area picks
// for a trip. Powered by trip_recommendations + the
// generate_recommendations Edge Function. Auto-fires after the
// itinerary is generated, so by the time the user opens the
// Stays+Eats tab the recs are already there.
@riverpod
Stream<List<TripRecommendation>> tripRecommendations(
    TripRecommendationsRef ref, String tripId) {
  return ref.read(recommendationsServiceProvider).watch(tripId);
}

// ─────────────────────────────────────────────────────────────
//  TRIP CREATION STATE  (local wizard state)
// ─────────────────────────────────────────────────────────────
class TripCreationState {
  final String name;
  final List<String> vibes;
  final List<String> destinations;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? budgetPerPerson;
  final int currentStep;
  // v1.1 — solo vs group. Defaults to group so existing flows are
  // unchanged. Solo path skips the Invite step.
  final TripMode mode;

  const TripCreationState({
    this.name = '',
    this.vibes = const [],
    this.destinations = const [],
    this.startDate,
    this.endDate,
    this.budgetPerPerson,
    this.currentStep = 0,
    this.mode = TripMode.group,
  });

  TripCreationState copyWith({
    String? name,
    List<String>? vibes,
    List<String>? destinations,
    DateTime? startDate,
    DateTime? endDate,
    int? budgetPerPerson,
    int? currentStep,
    TripMode? mode,
  }) => TripCreationState(
    name:            name            ?? this.name,
    vibes:           vibes           ?? this.vibes,
    destinations:    destinations    ?? this.destinations,
    startDate:       startDate       ?? this.startDate,
    endDate:         endDate         ?? this.endDate,
    budgetPerPerson: budgetPerPerson ?? this.budgetPerPerson,
    currentStep:     currentStep     ?? this.currentStep,
    mode:            mode            ?? this.mode,
  );
}

@riverpod
class TripCreation extends _$TripCreation {
  @override
  TripCreationState build() => const TripCreationState();

  void setName(String v)             => state = state.copyWith(name: v);
  void setVibes(List<String> v)      => state = state.copyWith(vibes: v);
  void setDestinations(List<String> v) => state = state.copyWith(destinations: v);
  void setDates(DateTime? s, DateTime? e) =>
      state = state.copyWith(startDate: s, endDate: e);
  void setBudget(int? v)             => state = state.copyWith(budgetPerPerson: v);
  void setMode(TripMode v)           => state = state.copyWith(mode: v);
  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: state.currentStep - 1);
  void reset()    => state = const TripCreationState();

  bool get isValid =>
      state.name.isNotEmpty &&
      state.vibes.isNotEmpty &&
      state.destinations.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────
//  AI GENERATION STATE
// ─────────────────────────────────────────────────────────────
enum AIGenStatus { idle, loading, success, error }

class AIGenState {
  final AIGenStatus status;
  final List<TripOption> options;
  final List<ItineraryDay> days;
  final String? errorMessage;

  const AIGenState({
    this.status = AIGenStatus.idle,
    this.options = const [],
    this.days    = const [],
    this.errorMessage,
  });
}

// keepAlive so long-running AI generations (itinerary can take 20s+)
// keep updating state even if the user leaves the screen that kicked
// them off. Otherwise the provider disposes, the HTTP response lands
// on a dead notifier, and the in-flight UI is stranded.
@Riverpod(keepAlive: true)
class AIGeneration extends _$AIGeneration {
  @override
  AIGenState build() => const AIGenState();

  Future<void> generateOptions(String tripId) async {
    state = const AIGenState(status: AIGenStatus.loading);
    try {
      final options = await ref.read(aiServiceProvider).generateTripOptions(tripId);
      state = AIGenState(status: AIGenStatus.success, options: options);
    } catch (e) {
      state = AIGenState(status: AIGenStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> generateItinerary(String tripId,
      {bool regenerate = false}) async {
    state = AIGenState(status: AIGenStatus.loading, options: state.options);
    try {
      // The edge function writes itinerary_items directly; the
      // UI reads them via itineraryStreamProvider, so we don't need
      // to deserialise days here — just mark success and let the
      // realtime stream hydrate the plan tab.
      await ref
          .read(itineraryServiceProvider)
          .generateForTrip(tripId, regenerate: regenerate);
      state = AIGenState(
          status: AIGenStatus.success, options: state.options);
    } catch (e) {
      state = AIGenState(
        status: AIGenStatus.error,
        options: state.options,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> generatePackingList(String tripId,
      {bool regenerate = false}) async {
    state = AIGenState(status: AIGenStatus.loading, options: state.options);
    try {
      await ref
          .read(packingServiceProvider)
          .generateForTrip(tripId, regenerate: regenerate);
      state = AIGenState(
          status: AIGenStatus.success, options: state.options);
    } catch (e) {
      state = AIGenState(
        status: AIGenStatus.error,
        options: state.options,
        errorMessage: e.toString(),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  PENDING VOTES
//
//  Drives the "resume voting" banner on Home. Computes the set of
//  active trips that (a) are in voting status and (b) the current
//  user hasn't voted on yet.
//
//  Invalidated when the user casts a vote (see VotingScreen) or
//  when the trip list changes.
// ─────────────────────────────────────────────────────────────

final myVotedTripIdsProvider = FutureProvider<Set<String>>((ref) {
  ref.watch(authStateProvider);
  return ref.read(tripServiceProvider).fetchMyVotedTripIds();
});

final pendingVotesProvider = Provider<List<Trip>>((ref) {
  final trips = ref.watch(myTripsProvider).valueOrNull ?? const <Trip>[];
  final voted = ref.watch(myVotedTripIdsProvider).valueOrNull ?? <String>{};
  return trips
      .where((t) => t.status == TripStatus.voting && !voted.contains(t.id))
      .toList();
});

// ─────────────────────────────────────────────────────────────
//  LAST-SEEN MAP (per trip)
//
//  Populated each time the user opens a trip space — we write
//  `last_seen_trip_<tripId>` to SharedPreferences. This provider
//  loads the whole map for Home's trip cards to compute unread
//  state. Invalidate after writing so cards re-render.
// ─────────────────────────────────────────────────────────────
final lastSeenTripMapProvider =
    FutureProvider<Map<String, DateTime>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final out = <String, DateTime>{};
  for (final k in prefs.getKeys()) {
    if (!k.startsWith('last_seen_trip_')) continue;
    final tid = k.substring('last_seen_trip_'.length);
    final s = prefs.getString(k);
    if (s == null) continue;
    final d = DateTime.tryParse(s);
    if (d != null) out[tid] = d;
  }
  return out;
});

/// Set of trip IDs currently muted on this device. Writes are keyed
/// as `trip_muted_until_<tripId>` = ISO timestamp; a trip is muted
/// while that timestamp is in the future. Invalidate after
/// toggling so cards re-render.
final mutedTripIdsProvider = FutureProvider<Set<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final out = <String>{};
  for (final k in prefs.getKeys()) {
    if (!k.startsWith('trip_muted_until_')) continue;
    final tid = k.substring('trip_muted_until_'.length);
    final s = prefs.getString(k);
    if (s == null) continue;
    final d = DateTime.tryParse(s);
    if (d == null) continue;
    if (d.isAfter(now)) out.add(tid);
  }
  return out;
});

/// Set of DM other-user IDs whose thread is currently muted on this
/// device. Same mechanism as [mutedTripIdsProvider] but keyed by
/// the OTHER user's id (threads are pairwise).
final mutedDmUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final out = <String>{};
  for (final k in prefs.getKeys()) {
    if (!k.startsWith('dm_muted_until_')) continue;
    final uid = k.substring('dm_muted_until_'.length);
    final s = prefs.getString(k);
    if (s == null) continue;
    final d = DateTime.tryParse(s);
    if (d == null) continue;
    if (d.isAfter(now)) out.add(uid);
  }
  return out;
});

/// Set of trip IDs that have new activity since the user last
/// opened them. Derived from [myRecentActivityProvider] crossed
/// with [lastSeenTripMapProvider]. Muted trips are excluded so the
/// Home dot + nav badge respect [mutedTripIdsProvider].
final unreadTripIdsProvider = Provider<Set<String>>((ref) {
  final activity =
      ref.watch(myRecentActivityProvider).valueOrNull ?? const <TripEvent>[];
  final seen =
      ref.watch(lastSeenTripMapProvider).valueOrNull ?? const <String, DateTime>{};
  final muted =
      ref.watch(mutedTripIdsProvider).valueOrNull ?? const <String>{};
  final latestByTrip = <String, DateTime>{};
  for (final e in activity) {
    final t = e.createdAt;
    if (t == null) continue;
    final prev = latestByTrip[e.tripId];
    if (prev == null || t.isAfter(prev)) {
      latestByTrip[e.tripId] = t;
    }
  }
  final unread = <String>{};
  latestByTrip.forEach((tripId, latest) {
    if (muted.contains(tripId)) return;
    final last = seen[tripId];
    if (last == null || latest.isAfter(last)) {
      unread.add(tripId);
    }
  });
  return unread;
});
