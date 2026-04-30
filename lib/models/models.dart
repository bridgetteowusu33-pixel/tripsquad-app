// ─────────────────────────────────────────────────────────────
//  TRIPSQUAD — Data Models
//  All models are plain Dart classes (Freezed-ready).
//  Run: flutter pub run build_runner build --delete-conflicting-outputs
// ─────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

// ── Trip ─────────────────────────────────────────────────────
@freezed
class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String hostId,
    required String name,
    @Default(TripMode.group) TripMode mode,
    @Default(TripStatus.draft) TripStatus status,
    String? inviteToken,
    List<String>? vibes,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    String? selectedDestination,
    String? selectedFlag,
    int? estimatedBudget,
    String? coverPhotoUrl,
    // v1.2 Phase 2.5 — host-designated squad accommodation pick
    String? squadPickAccommodationId,
    DateTime? squadPickSetAt,
    @Default([]) List<SquadMember> squadMembers,
    @Default([]) List<TripOption> options,
    ItineraryDay? itinerary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}

enum TripMode   { group, solo, match }
enum TripStatus { draft, collecting, voting, revealed, planning, live, completed }

/// Derives a trip's *effective* phase from its stored status + today's
/// date. The backend never auto-advances `planning → live` or
/// `live → completed` (no pg_cron yet — migration 020). This extension
/// lets the client behave as if it did, so users see the Today tab,
/// Scout's live-mode greeting, and the completed-trip recap at the
/// right real-world moment.
///
/// Rules:
/// - A stored status of `completed` is always respected.
/// - `draft | collecting | voting` are always respected (pre-reveal).
/// - `revealed | planning | live`: advance based on dates:
///   - today within [start, end] → live
///   - today > end               → completed
///   - otherwise                 → stored status
extension TripEffectiveStatus on Trip {
  TripStatus get effectiveStatus {
    if (status == TripStatus.completed) return TripStatus.completed;
    if (status == TripStatus.draft ||
        status == TripStatus.collecting ||
        status == TripStatus.voting) {
      return status;
    }
    if (startDate == null) return status;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
        startDate!.year, startDate!.month, startDate!.day);
    final end = endDate == null
        ? null
        : DateTime(endDate!.year, endDate!.month, endDate!.day);

    // Past the end date → completed.
    if (end != null && today.isAfter(end)) return TripStatus.completed;

    // Between start and end (inclusive) → live.
    if (!today.isBefore(start) &&
        (end == null || !today.isAfter(end))) {
      return TripStatus.live;
    }

    return status;
  }
}

// ── Squad Member ─────────────────────────────────────────────
@freezed
class SquadMember with _$SquadMember {
  const factory SquadMember({
    required String id,
    required String tripId,
    String? userId,
    required String nickname,
    String? emoji,
    @Default(MemberRole.member) MemberRole role,
    @Default(MemberStatus.invited) MemberStatus status,
    int? budgetMin,
    int? budgetMax,
    List<String>? vibes,
    List<String>? destinationPrefs,
    DateTime? respondedAt,
    DateTime? createdAt,
  }) = _SquadMember;

  factory SquadMember.fromJson(Map<String, dynamic> json) =>
      _$SquadMemberFromJson(json);
}

enum MemberRole   { host, member }
enum MemberStatus { invited, submitted, voted }

// ── Trip Option (AI-generated destination proposal) ──────────
@freezed
class TripOption with _$TripOption {
  const factory TripOption({
    required String id,
    required String tripId,
    required String destination,
    required String country,
    required String flag,
    required String tagline,
    String? description,
    int? estimatedCostPp,
    int? durationDays,
    List<String>? vibeMatch,
    double? compatibilityScore,
    @Default(0) int voteCount,
    bool? hasUserVoted,
    @Default([]) List<String> highlights,
    DateTime? createdAt,
  }) = _TripOption;

  factory TripOption.fromJson(Map<String, dynamic> json) =>
      _$TripOptionFromJson(json);
}

// ── Itinerary ────────────────────────────────────────────────
@freezed
class ItineraryDay with _$ItineraryDay {
  const factory ItineraryDay({
    required String id,
    required String tripId,
    required int dayNumber,
    required String title,
    @Default([]) List<ItineraryItem> items,
    @Default([]) @JsonKey(name: 'packing') List<PackingItem> packingList,
  }) = _ItineraryDay;

  factory ItineraryDay.fromJson(Map<String, dynamic> json) =>
      _$ItineraryDayFromJson(json);
}

@freezed
class ItineraryItem with _$ItineraryItem {
  const factory ItineraryItem({
    String? id,
    required String title,
    @Default('morning') String timeOfDay,    // morning, afternoon, evening, night
    String? description,
    String? location,
    String? estimatedCost,
    String? bookingUrl,
    bool? requiresBooking,
    String? soloTip,              // Only for Solo Explorer mode
  }) = _ItineraryItem;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) =>
      _$ItineraryItemFromJson(json);
}

@freezed
class PackingItem with _$PackingItem {
  const factory PackingItem({
    String? id,
    required String label,
    @Default('') String category,
    @Default(false) bool packed,
  }) = _PackingItem;

  factory PackingItem.fromJson(Map<String, dynamic> json) =>
      _$PackingItemFromJson(json);
}

// ── App User ─────────────────────────────────────────────────
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    String? email,
    String? nickname,
    String? emoji,
    String? avatarUrl,
    @Default(SubscriptionTier.free) SubscriptionTier tier,
    @Default([]) List<String> passportStamps,
    String? homeCity,
    String? homeAirport,
    String? travelStyle,
    @Default([]) List<String> passports,
    String? tag,
    @Default('private') String privacyLevel,
    @Default(false) bool profileComplete,
    @Default(0) int tripsCompleted,
    DateTime? lastHandleChange,
    DateTime? createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}

enum SubscriptionTier { free, tripPass, explorer }

// ── Trip Event (authoritative activity feed per trip) ────────
@freezed
class TripEvent with _$TripEvent {
  const factory TripEvent({
    required String id,
    required String tripId,
    required String kind,
    String? actorUserId,
    String? actorTag,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
  }) = _TripEvent;

  factory TripEvent.fromJson(Map<String, dynamic> json) =>
      _$TripEventFromJson(json);
}

// ── Notification (per-user inbox row) ────────────────────────
@freezed
class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    required String id,
    required String userId,
    String? tripId,
    String? eventId,
    required String kind,
    required String title,
    String? body,
    DateTime? readAt,
    DateTime? createdAt,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
}

// ── Direct Message ───────────────────────────────────────────
@freezed
class DirectMessage with _$DirectMessage {
  const factory DirectMessage({
    required String id,
    required String fromUser,
    required String toUser,
    required String content,
    String? replyToId,
    String? imageUrl,
    String? audioUrl,
    int? audioDurationMs,
    DateTime? readAt,
    DateTime? editedAt,
    DateTime? createdAt,
  }) = _DirectMessage;

  factory DirectMessage.fromJson(Map<String, dynamic> json) =>
      _$DirectMessageFromJson(json);
}

// ── DM reaction (migration 018) ──────────────────────────────
@freezed
class DmReaction with _$DmReaction {
  const factory DmReaction({
    required String id,
    required String messageId,
    required String userId,
    required String emoji,
    DateTime? createdAt,
  }) = _DmReaction;

  factory DmReaction.fromJson(Map<String, dynamic> json) =>
      _$DmReactionFromJson(json);
}

// ── Scout Message (1:1 user ↔ Scout chat history) ────────────
@freezed
class ScoutMessage with _$ScoutMessage {
  const factory ScoutMessage({
    required String id,
    required String userId,
    required String role, // 'user' | 'assistant'
    required String content,
    String? imageUrl,
    DateTime? createdAt,
  }) = _ScoutMessage;

  factory ScoutMessage.fromJson(Map<String, dynamic> json) =>
      _$ScoutMessageFromJson(json);
}

// ── Itinerary Activity (first-class, realtime-synced) ────────
@freezed
class ItineraryActivity with _$ItineraryActivity {
  const factory ItineraryActivity({
    required String id,
    required String tripId,
    required int dayNumber,
    @Default('morning') String timeOfDay,
    required String title,
    String? description,
    String? location,
    double? lat,
    double? lng,
    int? estimatedCostCents,
    String? bookingUrl,
    String? imageUrl,
    @Default(0) int orderIndex,
    String? createdBy,
    DateTime? bookedAt,
    @Default('approved') String status, // proposed | approved | rejected
    String? proposedBy,
    String? rejectedReason,
    DateTime? reviewedAt,
    String? reviewedBy,
    @Default('activity') String itemType, // activity | hotel | restaurant
    DateTime? checkedOffAt,
    String? checkedOffBy,
    DateTime? createdAt,
  }) = _ItineraryActivity;

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) =>
      _$ItineraryActivityFromJson(json);
}

// ── Itinerary Note (threaded squad comments per activity) ────
@freezed
class ItineraryNote with _$ItineraryNote {
  const factory ItineraryNote({
    required String id,
    required String itemId,
    required String userId,
    required String content,
    DateTime? createdAt,
  }) = _ItineraryNote;

  factory ItineraryNote.fromJson(Map<String, dynamic> json) =>
      _$ItineraryNoteFromJson(json);
}

// ── Chat Message (first-class) ───────────────────────────────
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String tripId,
    String? userId,
    required String nickname,
    @Default('😎') String emoji,
    required String content,
    @Default(false) bool isAi,
    String? replyToId,
    String? imageUrl,
    String? audioUrl,
    int? audioDurationMs,
    @Default([]) List<String> seenBy,
    @Default([]) List<String> mentions,
    DateTime? pinnedAt,
    DateTime? editedAt,
    DateTime? createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

// ── Chat Reaction ────────────────────────────────────────────
@freezed
class ChatReaction with _$ChatReaction {
  const factory ChatReaction({
    required String id,
    required String messageId,
    required String userId,
    required String emoji,
    DateTime? createdAt,
  }) = _ChatReaction;

  factory ChatReaction.fromJson(Map<String, dynamic> json) =>
      _$ChatReactionFromJson(json);
}

// ── Packing Item (first-class realtime-synced) ───────────────
@freezed
class PackingEntry with _$PackingEntry {
  const factory PackingEntry({
    required String id,
    required String tripId,
    required String label,
    @Default('extras') String category,
    String? emoji,
    @Default(false) bool isShared,
    String? addedBy,
    String? claimedBy,
    @Default([]) List<String> packedBy,
    @Default(0) int orderIndex,
    DateTime? createdAt,
  }) = _PackingEntry;

  factory PackingEntry.fromJson(Map<String, dynamic> json) =>
      _$PackingEntryFromJson(json);
}

// ── Kudos (positive-only squad reputation) ───────────────────
@freezed
class Kudos with _$Kudos {
  const factory Kudos({
    required String id,
    required String tripId,
    required String fromUser,
    required String toUser,
    required String kind,
    String? note,
    DateTime? createdAt,
  }) = _Kudos;

  factory Kudos.fromJson(Map<String, dynamic> json) => _$KudosFromJson(json);
}

/// The seven kudos kinds we support, with emoji + display label.
const kKudosKinds = <({String kind, String emoji, String label})>[
  (kind: 'great_traveler', emoji: '✈️', label: 'great traveler'),
  (kind: 'on_time',        emoji: '🎯', label: 'on time'),
  (kind: 'fair_splits',    emoji: '💸', label: 'fair with splits'),
  (kind: 'fun_energy',     emoji: '🎉', label: 'fun energy'),
  (kind: 'great_planner',  emoji: '🗺️', label: 'great planner'),
  (kind: 'photo_mvp',      emoji: '📸', label: 'photo mvp'),
  (kind: 'chill_roommate', emoji: '🛌', label: 'chill roommate'),
];

// ── Itinerary Rating (👍/👎 per item) ────────────────────────
@freezed
class ItineraryRating with _$ItineraryRating {
  const factory ItineraryRating({
    required String id,
    required String itemId,
    required String userId,
    required int thumb, // -1 or 1
    String? note,
    DateTime? createdAt,
  }) = _ItineraryRating;

  factory ItineraryRating.fromJson(Map<String, dynamic> json) =>
      _$ItineraryRatingFromJson(json);
}

// ── Destination Recap ────────────────────────────────────────
@freezed
class DestinationRecap with _$DestinationRecap {
  const factory DestinationRecap({
    required String id,
    required String tripId,
    required String userId,
    required String destination,
    required int stars,
    required String wouldReturn,
    String? bestPart,
    String? photoUrl,
    DateTime? createdAt,
  }) = _DestinationRecap;

  factory DestinationRecap.fromJson(Map<String, dynamic> json) =>
      _$DestinationRecapFromJson(json);
}

// ── Place (canonical destination entity for directory) ──────
@freezed
class Place with _$Place {
  const factory Place({
    required String id,
    required String category, // activity | hotel | restaurant
    required String name,
    required String destination,
    String? country,
    String? flag,
    String? address,
    double? lat,
    double? lng,
    String? photoUrl,
    String? googlePlaceId,
    @Default([]) List<String> aliases,
    DateTime? createdAt,
  }) = _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
}

// ── Place stats (aggregated view) ───────────────────────────
@freezed
class PlaceStats with _$PlaceStats {
  const factory PlaceStats({
    required String placeId,
    required String name,
    required String category,
    required String destination,
    String? country,
    String? flag,
    String? photoUrl,
    String? displayPhoto,
    @Default(0) int squadsCount,
    @Default(0) int ratingCount,
    @Default(0) int upCount,
    @Default(0) int downCount,
    @Default(0) int approvalPct,
  }) = _PlaceStats;

  factory PlaceStats.fromJson(Map<String, dynamic> json) =>
      _$PlaceStatsFromJson(json);
}

// ── Destination hub (aggregated per destination) ─────────────
@freezed
class DestinationHub with _$DestinationHub {
  const factory DestinationHub({
    required String destination,
    String? country,
    String? flag,
    @Default(0) int placeCount,
    @Default(0) int activityCount,
    @Default(0) int hotelCount,
    @Default(0) int restaurantCount,
    double? avgStars,
    @Default(0) int recapCount,
  }) = _DestinationHub;

  factory DestinationHub.fromJson(Map<String, dynamic> json) =>
      _$DestinationHubFromJson(json);
}

// ── DM Inbox Conversation (derived view) ─────────────────────
@freezed
class DmConversation with _$DmConversation {
  const factory DmConversation({
    required String otherUserId,
    String? otherNickname,
    String? otherTag,
    String? otherEmoji,
    String? otherAvatarUrl,
    required String lastMessage,
    required DateTime lastMessageAt,
    @Default(0) int unreadCount,
  }) = _DmConversation;

  factory DmConversation.fromJson(Map<String, dynamic> json) =>
      _$DmConversationFromJson(json);
}

// ── Solo Match Profile ────────────────────────────────────────
@freezed
class MatchProfile with _$MatchProfile {
  const factory MatchProfile({
    required String id,
    required String userId,
    required String destination,
    required String flag,
    required DateTime travelStart,
    required DateTime travelEnd,
    required List<String> vibes,
    String? bio,
    int? age,
    String? emoji,
    double? compatibilityScore,
    @Default(false) bool hasWaved,
    @Default(false) bool isMatch,
  }) = _MatchProfile;

  factory MatchProfile.fromJson(Map<String, dynamic> json) =>
      _$MatchProfileFromJson(json);
}

// ── Booking layer (v1.2) ─────────────────────────────────────
// Per-squad-member flight context. The "anchor" is the first booker
// — others' search queries pre-fill an arrival window matching the
// anchor's outbound_at. State machine drives the per-member card UI
// in book_tab.dart.
enum ArrivalPlanState { not_set, searching, booked, cancelled }

@freezed
class MemberArrivalPlan with _$MemberArrivalPlan {
  const factory MemberArrivalPlan({
    required String id,
    required String tripId,
    required String userId,
    String? departureCity,
    String? departureIata,        // 3-letter airport code
    String? arrivalIata,
    DateTime? outboundAt,         // locked when booked
    String? airline,
    String? flightNumber,
    String? bookingRef,
    @Default(ArrivalPlanState.not_set) ArrivalPlanState state,
    @Default(false) bool isAnchor,
    DateTime? bookedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MemberArrivalPlan;

  factory MemberArrivalPlan.fromJson(Map<String, dynamic> json) =>
      _$MemberArrivalPlanFromJson(json);
}

// Squad-self-reported "I booked this" log. Drives the lock-in counter
// and the "X of N booked into this hotel" indicator on accommodation
// cards. UNIQUE per (trip, user, kind) — re-confirming replaces.
enum BookingKind { flight, accommodation }

@freezed
class BookingConfirmation with _$BookingConfirmation {
  const factory BookingConfirmation({
    required String id,
    required String tripId,
    required String userId,
    required BookingKind kind,
    String? recommendationId,
    String? arrivalPlanId,
    int? totalCents,
    @Default('USD') String currency,
    String? notes,
    DateTime? confirmedAt,
  }) = _BookingConfirmation;

  factory BookingConfirmation.fromJson(Map<String, dynamic> json) =>
      _$BookingConfirmationFromJson(json);
}

// Host-set deadline per kind. Drives the countdown chip + push
// notifications at 24h / 8h / 2h before the deadline.
@freezed
class TripBookingDeadline with _$TripBookingDeadline {
  const factory TripBookingDeadline({
    required String tripId,
    required BookingKind kind,
    required DateTime deadlineAt,
    String? setBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TripBookingDeadline;

  factory TripBookingDeadline.fromJson(Map<String, dynamic> json) =>
      _$TripBookingDeadlineFromJson(json);
}

// Derived view — "3/6 squad locked in" math. Refreshed implicitly
// by Postgres when underlying tables change. flights_booked counts
// distinct users with a flight booking_confirmation; same for
// accommodation. Percentages are rounded ints.
@freezed
class TripLockinStatus with _$TripLockinStatus {
  const factory TripLockinStatus({
    required String tripId,
    @Default(0) int squadSize,
    @Default(0) int flightsBooked,
    @Default(0) int accommodationBooked,
    int? flightLockinPct,
    int? accommodationLockinPct,
    DateTime? flightDeadline,
    DateTime? accommodationDeadline,
  }) = _TripLockinStatus;

  factory TripLockinStatus.fromJson(Map<String, dynamic> json) =>
      _$TripLockinStatusFromJson(json);
}

// ── Trip Recommendation (Scout-picked stays + eats) ──────────
// One row per recommendation in `trip_recommendations`. Three
// kinds share the same shape: `area` is the "best area to stay"
// hero, `hotel` and `restaurant` are list items. Linked optionally
// to `places.id` when there's a community-directory match.
enum RecommendationKind { area, hotel, restaurant }

@freezed
class TripRecommendation with _$TripRecommendation {
  const factory TripRecommendation({
    required String id,
    required String tripId,
    required RecommendationKind kind,
    required int rank,
    required String name,
    String? neighborhood,
    String? priceBand,        // '$' .. '$$$$'
    String? cuisine,          // restaurants only
    @Default([]) List<String> vibeTags,
    String? reason,           // "why scout picked it" — 1-2 sentences
    int? dayAnchor,           // nearest itinerary day_number, nullable
    String? meal,             // breakfast | lunch | dinner | late-night | snack
    String? imageUrl,
    String? mapsUrl,          // Google Maps deep link, always populated by Edge Fn
    String? bookingUrl,       // hotels only — Booking.com search URL
    String? placeId,
    DateTime? createdAt,
  }) = _TripRecommendation;

  factory TripRecommendation.fromJson(Map<String, dynamic> json) =>
      _$TripRecommendationFromJson(json);
}
