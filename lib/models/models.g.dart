// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TripImpl _$$TripImplFromJson(Map<String, dynamic> json) => _$TripImpl(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      name: json['name'] as String,
      mode: $enumDecodeNullable(_$TripModeEnumMap, json['mode']) ??
          TripMode.group,
      status: $enumDecodeNullable(_$TripStatusEnumMap, json['status']) ??
          TripStatus.draft,
      inviteToken: json['inviteToken'] as String?,
      vibes:
          (json['vibes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      durationDays: (json['durationDays'] as num?)?.toInt(),
      selectedDestination: json['selectedDestination'] as String?,
      selectedFlag: json['selectedFlag'] as String?,
      estimatedBudget: (json['estimatedBudget'] as num?)?.toInt(),
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      squadPickAccommodationId: json['squadPickAccommodationId'] as String?,
      squadPickSetAt: json['squadPickSetAt'] == null
          ? null
          : DateTime.parse(json['squadPickSetAt'] as String),
      squadMembers: (json['squadMembers'] as List<dynamic>?)
              ?.map((e) => SquadMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => TripOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      itinerary: json['itinerary'] == null
          ? null
          : ItineraryDay.fromJson(json['itinerary'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TripImplToJson(_$TripImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hostId': instance.hostId,
      'name': instance.name,
      'mode': _$TripModeEnumMap[instance.mode]!,
      'status': _$TripStatusEnumMap[instance.status]!,
      'inviteToken': instance.inviteToken,
      'vibes': instance.vibes,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'durationDays': instance.durationDays,
      'selectedDestination': instance.selectedDestination,
      'selectedFlag': instance.selectedFlag,
      'estimatedBudget': instance.estimatedBudget,
      'coverPhotoUrl': instance.coverPhotoUrl,
      'squadPickAccommodationId': instance.squadPickAccommodationId,
      'squadPickSetAt': instance.squadPickSetAt?.toIso8601String(),
      'squadMembers': instance.squadMembers,
      'options': instance.options,
      'itinerary': instance.itinerary,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$TripModeEnumMap = {
  TripMode.group: 'group',
  TripMode.solo: 'solo',
  TripMode.match: 'match',
};

const _$TripStatusEnumMap = {
  TripStatus.draft: 'draft',
  TripStatus.collecting: 'collecting',
  TripStatus.voting: 'voting',
  TripStatus.revealed: 'revealed',
  TripStatus.planning: 'planning',
  TripStatus.live: 'live',
  TripStatus.completed: 'completed',
};

_$SquadMemberImpl _$$SquadMemberImplFromJson(Map<String, dynamic> json) =>
    _$SquadMemberImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String?,
      nickname: json['nickname'] as String,
      emoji: json['emoji'] as String?,
      role: $enumDecodeNullable(_$MemberRoleEnumMap, json['role']) ??
          MemberRole.member,
      status: $enumDecodeNullable(_$MemberStatusEnumMap, json['status']) ??
          MemberStatus.invited,
      budgetMin: (json['budgetMin'] as num?)?.toInt(),
      budgetMax: (json['budgetMax'] as num?)?.toInt(),
      vibes:
          (json['vibes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      destinationPrefs: (json['destinationPrefs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$SquadMemberImplToJson(_$SquadMemberImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'userId': instance.userId,
      'nickname': instance.nickname,
      'emoji': instance.emoji,
      'role': _$MemberRoleEnumMap[instance.role]!,
      'status': _$MemberStatusEnumMap[instance.status]!,
      'budgetMin': instance.budgetMin,
      'budgetMax': instance.budgetMax,
      'vibes': instance.vibes,
      'destinationPrefs': instance.destinationPrefs,
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$MemberRoleEnumMap = {
  MemberRole.host: 'host',
  MemberRole.member: 'member',
};

const _$MemberStatusEnumMap = {
  MemberStatus.invited: 'invited',
  MemberStatus.submitted: 'submitted',
  MemberStatus.voted: 'voted',
};

_$TripOptionImpl _$$TripOptionImplFromJson(Map<String, dynamic> json) =>
    _$TripOptionImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      destination: json['destination'] as String,
      country: json['country'] as String,
      flag: json['flag'] as String,
      tagline: json['tagline'] as String,
      description: json['description'] as String?,
      estimatedCostPp: (json['estimatedCostPp'] as num?)?.toInt(),
      durationDays: (json['durationDays'] as num?)?.toInt(),
      vibeMatch: (json['vibeMatch'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      compatibilityScore: (json['compatibilityScore'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
      hasUserVoted: json['hasUserVoted'] as bool?,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TripOptionImplToJson(_$TripOptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'destination': instance.destination,
      'country': instance.country,
      'flag': instance.flag,
      'tagline': instance.tagline,
      'description': instance.description,
      'estimatedCostPp': instance.estimatedCostPp,
      'durationDays': instance.durationDays,
      'vibeMatch': instance.vibeMatch,
      'compatibilityScore': instance.compatibilityScore,
      'voteCount': instance.voteCount,
      'hasUserVoted': instance.hasUserVoted,
      'highlights': instance.highlights,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ItineraryDayImpl _$$ItineraryDayImplFromJson(Map<String, dynamic> json) =>
    _$ItineraryDayImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      dayNumber: (json['dayNumber'] as num).toInt(),
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      packingList: (json['packing'] as List<dynamic>?)
              ?.map((e) => PackingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ItineraryDayImplToJson(_$ItineraryDayImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'dayNumber': instance.dayNumber,
      'title': instance.title,
      'items': instance.items,
      'packing': instance.packingList,
    };

_$ItineraryItemImpl _$$ItineraryItemImplFromJson(Map<String, dynamic> json) =>
    _$ItineraryItemImpl(
      id: json['id'] as String?,
      title: json['title'] as String,
      timeOfDay: json['timeOfDay'] as String? ?? 'morning',
      description: json['description'] as String?,
      location: json['location'] as String?,
      estimatedCost: json['estimatedCost'] as String?,
      bookingUrl: json['bookingUrl'] as String?,
      requiresBooking: json['requiresBooking'] as bool?,
      soloTip: json['soloTip'] as String?,
    );

Map<String, dynamic> _$$ItineraryItemImplToJson(_$ItineraryItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'timeOfDay': instance.timeOfDay,
      'description': instance.description,
      'location': instance.location,
      'estimatedCost': instance.estimatedCost,
      'bookingUrl': instance.bookingUrl,
      'requiresBooking': instance.requiresBooking,
      'soloTip': instance.soloTip,
    };

_$PackingItemImpl _$$PackingItemImplFromJson(Map<String, dynamic> json) =>
    _$PackingItemImpl(
      id: json['id'] as String?,
      label: json['label'] as String,
      category: json['category'] as String? ?? '',
      packed: json['packed'] as bool? ?? false,
    );

Map<String, dynamic> _$$PackingItemImplToJson(_$PackingItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'category': instance.category,
      'packed': instance.packed,
    };

_$AppUserImpl _$$AppUserImplFromJson(Map<String, dynamic> json) =>
    _$AppUserImpl(
      id: json['id'] as String,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      emoji: json['emoji'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      tier: $enumDecodeNullable(_$SubscriptionTierEnumMap, json['tier']) ??
          SubscriptionTier.free,
      passportStamps: (json['passportStamps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      homeCity: json['homeCity'] as String?,
      homeAirport: json['homeAirport'] as String?,
      travelStyle: json['travelStyle'] as String?,
      passports: (json['passports'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tag: json['tag'] as String?,
      privacyLevel: json['privacyLevel'] as String? ?? 'private',
      profileComplete: json['profileComplete'] as bool? ?? false,
      tripsCompleted: (json['tripsCompleted'] as num?)?.toInt() ?? 0,
      lastHandleChange: json['lastHandleChange'] == null
          ? null
          : DateTime.parse(json['lastHandleChange'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AppUserImplToJson(_$AppUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'nickname': instance.nickname,
      'emoji': instance.emoji,
      'avatarUrl': instance.avatarUrl,
      'tier': _$SubscriptionTierEnumMap[instance.tier]!,
      'passportStamps': instance.passportStamps,
      'homeCity': instance.homeCity,
      'homeAirport': instance.homeAirport,
      'travelStyle': instance.travelStyle,
      'passports': instance.passports,
      'tag': instance.tag,
      'privacyLevel': instance.privacyLevel,
      'profileComplete': instance.profileComplete,
      'tripsCompleted': instance.tripsCompleted,
      'lastHandleChange': instance.lastHandleChange?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$SubscriptionTierEnumMap = {
  SubscriptionTier.free: 'free',
  SubscriptionTier.tripPass: 'tripPass',
  SubscriptionTier.explorer: 'explorer',
};

_$TripEventImpl _$$TripEventImplFromJson(Map<String, dynamic> json) =>
    _$TripEventImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      kind: json['kind'] as String,
      actorUserId: json['actorUserId'] as String?,
      actorTag: json['actorTag'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TripEventImplToJson(_$TripEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'kind': instance.kind,
      'actorUserId': instance.actorUserId,
      'actorTag': instance.actorTag,
      'payload': instance.payload,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$NotificationItemImpl _$$NotificationItemImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationItemImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tripId: json['tripId'] as String?,
      eventId: json['eventId'] as String?,
      kind: json['kind'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$NotificationItemImplToJson(
        _$NotificationItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'tripId': instance.tripId,
      'eventId': instance.eventId,
      'kind': instance.kind,
      'title': instance.title,
      'body': instance.body,
      'readAt': instance.readAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$DirectMessageImpl _$$DirectMessageImplFromJson(Map<String, dynamic> json) =>
    _$DirectMessageImpl(
      id: json['id'] as String,
      fromUser: json['fromUser'] as String,
      toUser: json['toUser'] as String,
      content: json['content'] as String,
      replyToId: json['replyToId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$DirectMessageImplToJson(_$DirectMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromUser': instance.fromUser,
      'toUser': instance.toUser,
      'content': instance.content,
      'replyToId': instance.replyToId,
      'imageUrl': instance.imageUrl,
      'audioUrl': instance.audioUrl,
      'audioDurationMs': instance.audioDurationMs,
      'readAt': instance.readAt?.toIso8601String(),
      'editedAt': instance.editedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$DmReactionImpl _$$DmReactionImplFromJson(Map<String, dynamic> json) =>
    _$DmReactionImpl(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      emoji: json['emoji'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$DmReactionImplToJson(_$DmReactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messageId': instance.messageId,
      'userId': instance.userId,
      'emoji': instance.emoji,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ScoutMessageImpl _$$ScoutMessageImplFromJson(Map<String, dynamic> json) =>
    _$ScoutMessageImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ScoutMessageImplToJson(_$ScoutMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'role': instance.role,
      'content': instance.content,
      'imageUrl': instance.imageUrl,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ItineraryActivityImpl _$$ItineraryActivityImplFromJson(
        Map<String, dynamic> json) =>
    _$ItineraryActivityImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      dayNumber: (json['dayNumber'] as num).toInt(),
      timeOfDay: json['timeOfDay'] as String? ?? 'morning',
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      estimatedCostCents: (json['estimatedCostCents'] as num?)?.toInt(),
      bookingUrl: json['bookingUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String?,
      bookedAt: json['bookedAt'] == null
          ? null
          : DateTime.parse(json['bookedAt'] as String),
      status: json['status'] as String? ?? 'approved',
      proposedBy: json['proposedBy'] as String?,
      rejectedReason: json['rejectedReason'] as String?,
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      reviewedBy: json['reviewedBy'] as String?,
      itemType: json['itemType'] as String? ?? 'activity',
      checkedOffAt: json['checkedOffAt'] == null
          ? null
          : DateTime.parse(json['checkedOffAt'] as String),
      checkedOffBy: json['checkedOffBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ItineraryActivityImplToJson(
        _$ItineraryActivityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'dayNumber': instance.dayNumber,
      'timeOfDay': instance.timeOfDay,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'lat': instance.lat,
      'lng': instance.lng,
      'estimatedCostCents': instance.estimatedCostCents,
      'bookingUrl': instance.bookingUrl,
      'imageUrl': instance.imageUrl,
      'orderIndex': instance.orderIndex,
      'createdBy': instance.createdBy,
      'bookedAt': instance.bookedAt?.toIso8601String(),
      'status': instance.status,
      'proposedBy': instance.proposedBy,
      'rejectedReason': instance.rejectedReason,
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'reviewedBy': instance.reviewedBy,
      'itemType': instance.itemType,
      'checkedOffAt': instance.checkedOffAt?.toIso8601String(),
      'checkedOffBy': instance.checkedOffBy,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ItineraryNoteImpl _$$ItineraryNoteImplFromJson(Map<String, dynamic> json) =>
    _$ItineraryNoteImpl(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ItineraryNoteImplToJson(_$ItineraryNoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'itemId': instance.itemId,
      'userId': instance.userId,
      'content': instance.content,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String?,
      nickname: json['nickname'] as String,
      emoji: json['emoji'] as String? ?? '😎',
      content: json['content'] as String,
      isAi: json['isAi'] as bool? ?? false,
      replyToId: json['replyToId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
      seenBy: (json['seenBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mentions: (json['mentions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      pinnedAt: json['pinnedAt'] == null
          ? null
          : DateTime.parse(json['pinnedAt'] as String),
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'userId': instance.userId,
      'nickname': instance.nickname,
      'emoji': instance.emoji,
      'content': instance.content,
      'isAi': instance.isAi,
      'replyToId': instance.replyToId,
      'imageUrl': instance.imageUrl,
      'audioUrl': instance.audioUrl,
      'audioDurationMs': instance.audioDurationMs,
      'seenBy': instance.seenBy,
      'mentions': instance.mentions,
      'pinnedAt': instance.pinnedAt?.toIso8601String(),
      'editedAt': instance.editedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ChatReactionImpl _$$ChatReactionImplFromJson(Map<String, dynamic> json) =>
    _$ChatReactionImpl(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      emoji: json['emoji'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ChatReactionImplToJson(_$ChatReactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messageId': instance.messageId,
      'userId': instance.userId,
      'emoji': instance.emoji,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$PackingEntryImpl _$$PackingEntryImplFromJson(Map<String, dynamic> json) =>
    _$PackingEntryImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      label: json['label'] as String,
      category: json['category'] as String? ?? 'extras',
      emoji: json['emoji'] as String?,
      isShared: json['isShared'] as bool? ?? false,
      addedBy: json['addedBy'] as String?,
      claimedBy: json['claimedBy'] as String?,
      packedBy: (json['packedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PackingEntryImplToJson(_$PackingEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'label': instance.label,
      'category': instance.category,
      'emoji': instance.emoji,
      'isShared': instance.isShared,
      'addedBy': instance.addedBy,
      'claimedBy': instance.claimedBy,
      'packedBy': instance.packedBy,
      'orderIndex': instance.orderIndex,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$KudosImpl _$$KudosImplFromJson(Map<String, dynamic> json) => _$KudosImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      fromUser: json['fromUser'] as String,
      toUser: json['toUser'] as String,
      kind: json['kind'] as String,
      note: json['note'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$KudosImplToJson(_$KudosImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'fromUser': instance.fromUser,
      'toUser': instance.toUser,
      'kind': instance.kind,
      'note': instance.note,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ItineraryRatingImpl _$$ItineraryRatingImplFromJson(
        Map<String, dynamic> json) =>
    _$ItineraryRatingImpl(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      userId: json['userId'] as String,
      thumb: (json['thumb'] as num).toInt(),
      note: json['note'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ItineraryRatingImplToJson(
        _$ItineraryRatingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'itemId': instance.itemId,
      'userId': instance.userId,
      'thumb': instance.thumb,
      'note': instance.note,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$DestinationRecapImpl _$$DestinationRecapImplFromJson(
        Map<String, dynamic> json) =>
    _$DestinationRecapImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      destination: json['destination'] as String,
      stars: (json['stars'] as num).toInt(),
      wouldReturn: json['wouldReturn'] as String,
      bestPart: json['bestPart'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$DestinationRecapImplToJson(
        _$DestinationRecapImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'userId': instance.userId,
      'destination': instance.destination,
      'stars': instance.stars,
      'wouldReturn': instance.wouldReturn,
      'bestPart': instance.bestPart,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$PlaceImpl _$$PlaceImplFromJson(Map<String, dynamic> json) => _$PlaceImpl(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      destination: json['destination'] as String,
      country: json['country'] as String?,
      flag: json['flag'] as String?,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      photoUrl: json['photoUrl'] as String?,
      googlePlaceId: json['googlePlaceId'] as String?,
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PlaceImplToJson(_$PlaceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'name': instance.name,
      'destination': instance.destination,
      'country': instance.country,
      'flag': instance.flag,
      'address': instance.address,
      'lat': instance.lat,
      'lng': instance.lng,
      'photoUrl': instance.photoUrl,
      'googlePlaceId': instance.googlePlaceId,
      'aliases': instance.aliases,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$PlaceStatsImpl _$$PlaceStatsImplFromJson(Map<String, dynamic> json) =>
    _$PlaceStatsImpl(
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      destination: json['destination'] as String,
      country: json['country'] as String?,
      flag: json['flag'] as String?,
      photoUrl: json['photoUrl'] as String?,
      displayPhoto: json['displayPhoto'] as String?,
      squadsCount: (json['squadsCount'] as num?)?.toInt() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      upCount: (json['upCount'] as num?)?.toInt() ?? 0,
      downCount: (json['downCount'] as num?)?.toInt() ?? 0,
      approvalPct: (json['approvalPct'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PlaceStatsImplToJson(_$PlaceStatsImpl instance) =>
    <String, dynamic>{
      'placeId': instance.placeId,
      'name': instance.name,
      'category': instance.category,
      'destination': instance.destination,
      'country': instance.country,
      'flag': instance.flag,
      'photoUrl': instance.photoUrl,
      'displayPhoto': instance.displayPhoto,
      'squadsCount': instance.squadsCount,
      'ratingCount': instance.ratingCount,
      'upCount': instance.upCount,
      'downCount': instance.downCount,
      'approvalPct': instance.approvalPct,
    };

_$DestinationHubImpl _$$DestinationHubImplFromJson(Map<String, dynamic> json) =>
    _$DestinationHubImpl(
      destination: json['destination'] as String,
      country: json['country'] as String?,
      flag: json['flag'] as String?,
      placeCount: (json['placeCount'] as num?)?.toInt() ?? 0,
      activityCount: (json['activityCount'] as num?)?.toInt() ?? 0,
      hotelCount: (json['hotelCount'] as num?)?.toInt() ?? 0,
      restaurantCount: (json['restaurantCount'] as num?)?.toInt() ?? 0,
      avgStars: (json['avgStars'] as num?)?.toDouble(),
      recapCount: (json['recapCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$DestinationHubImplToJson(
        _$DestinationHubImpl instance) =>
    <String, dynamic>{
      'destination': instance.destination,
      'country': instance.country,
      'flag': instance.flag,
      'placeCount': instance.placeCount,
      'activityCount': instance.activityCount,
      'hotelCount': instance.hotelCount,
      'restaurantCount': instance.restaurantCount,
      'avgStars': instance.avgStars,
      'recapCount': instance.recapCount,
    };

_$DmConversationImpl _$$DmConversationImplFromJson(Map<String, dynamic> json) =>
    _$DmConversationImpl(
      otherUserId: json['otherUserId'] as String,
      otherNickname: json['otherNickname'] as String?,
      otherTag: json['otherTag'] as String?,
      otherEmoji: json['otherEmoji'] as String?,
      otherAvatarUrl: json['otherAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$DmConversationImplToJson(
        _$DmConversationImpl instance) =>
    <String, dynamic>{
      'otherUserId': instance.otherUserId,
      'otherNickname': instance.otherNickname,
      'otherTag': instance.otherTag,
      'otherEmoji': instance.otherEmoji,
      'otherAvatarUrl': instance.otherAvatarUrl,
      'lastMessage': instance.lastMessage,
      'lastMessageAt': instance.lastMessageAt.toIso8601String(),
      'unreadCount': instance.unreadCount,
    };

_$MatchProfileImpl _$$MatchProfileImplFromJson(Map<String, dynamic> json) =>
    _$MatchProfileImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      destination: json['destination'] as String,
      flag: json['flag'] as String,
      travelStart: DateTime.parse(json['travelStart'] as String),
      travelEnd: DateTime.parse(json['travelEnd'] as String),
      vibes: (json['vibes'] as List<dynamic>).map((e) => e as String).toList(),
      bio: json['bio'] as String?,
      age: (json['age'] as num?)?.toInt(),
      emoji: json['emoji'] as String?,
      compatibilityScore: (json['compatibilityScore'] as num?)?.toDouble(),
      hasWaved: json['hasWaved'] as bool? ?? false,
      isMatch: json['isMatch'] as bool? ?? false,
    );

Map<String, dynamic> _$$MatchProfileImplToJson(_$MatchProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'destination': instance.destination,
      'flag': instance.flag,
      'travelStart': instance.travelStart.toIso8601String(),
      'travelEnd': instance.travelEnd.toIso8601String(),
      'vibes': instance.vibes,
      'bio': instance.bio,
      'age': instance.age,
      'emoji': instance.emoji,
      'compatibilityScore': instance.compatibilityScore,
      'hasWaved': instance.hasWaved,
      'isMatch': instance.isMatch,
    };

_$MemberArrivalPlanImpl _$$MemberArrivalPlanImplFromJson(
        Map<String, dynamic> json) =>
    _$MemberArrivalPlanImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      departureCity: json['departureCity'] as String?,
      departureIata: json['departureIata'] as String?,
      arrivalIata: json['arrivalIata'] as String?,
      outboundAt: json['outboundAt'] == null
          ? null
          : DateTime.parse(json['outboundAt'] as String),
      airline: json['airline'] as String?,
      flightNumber: json['flightNumber'] as String?,
      bookingRef: json['bookingRef'] as String?,
      state: $enumDecodeNullable(_$ArrivalPlanStateEnumMap, json['state']) ??
          ArrivalPlanState.not_set,
      isAnchor: json['isAnchor'] as bool? ?? false,
      bookedAt: json['bookedAt'] == null
          ? null
          : DateTime.parse(json['bookedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$MemberArrivalPlanImplToJson(
        _$MemberArrivalPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'userId': instance.userId,
      'departureCity': instance.departureCity,
      'departureIata': instance.departureIata,
      'arrivalIata': instance.arrivalIata,
      'outboundAt': instance.outboundAt?.toIso8601String(),
      'airline': instance.airline,
      'flightNumber': instance.flightNumber,
      'bookingRef': instance.bookingRef,
      'state': _$ArrivalPlanStateEnumMap[instance.state]!,
      'isAnchor': instance.isAnchor,
      'bookedAt': instance.bookedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$ArrivalPlanStateEnumMap = {
  ArrivalPlanState.not_set: 'not_set',
  ArrivalPlanState.searching: 'searching',
  ArrivalPlanState.booked: 'booked',
  ArrivalPlanState.cancelled: 'cancelled',
};

_$BookingConfirmationImpl _$$BookingConfirmationImplFromJson(
        Map<String, dynamic> json) =>
    _$BookingConfirmationImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      kind: $enumDecode(_$BookingKindEnumMap, json['kind']),
      recommendationId: json['recommendationId'] as String?,
      arrivalPlanId: json['arrivalPlanId'] as String?,
      totalCents: (json['totalCents'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
    );

Map<String, dynamic> _$$BookingConfirmationImplToJson(
        _$BookingConfirmationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'userId': instance.userId,
      'kind': _$BookingKindEnumMap[instance.kind]!,
      'recommendationId': instance.recommendationId,
      'arrivalPlanId': instance.arrivalPlanId,
      'totalCents': instance.totalCents,
      'currency': instance.currency,
      'notes': instance.notes,
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
    };

const _$BookingKindEnumMap = {
  BookingKind.flight: 'flight',
  BookingKind.accommodation: 'accommodation',
};

_$TripBookingDeadlineImpl _$$TripBookingDeadlineImplFromJson(
        Map<String, dynamic> json) =>
    _$TripBookingDeadlineImpl(
      tripId: json['tripId'] as String,
      kind: $enumDecode(_$BookingKindEnumMap, json['kind']),
      deadlineAt: DateTime.parse(json['deadlineAt'] as String),
      setBy: json['setBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TripBookingDeadlineImplToJson(
        _$TripBookingDeadlineImpl instance) =>
    <String, dynamic>{
      'tripId': instance.tripId,
      'kind': _$BookingKindEnumMap[instance.kind]!,
      'deadlineAt': instance.deadlineAt.toIso8601String(),
      'setBy': instance.setBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$TripLockinStatusImpl _$$TripLockinStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$TripLockinStatusImpl(
      tripId: json['tripId'] as String,
      squadSize: (json['squadSize'] as num?)?.toInt() ?? 0,
      flightsBooked: (json['flightsBooked'] as num?)?.toInt() ?? 0,
      accommodationBooked: (json['accommodationBooked'] as num?)?.toInt() ?? 0,
      flightLockinPct: (json['flightLockinPct'] as num?)?.toInt(),
      accommodationLockinPct: (json['accommodationLockinPct'] as num?)?.toInt(),
      flightDeadline: json['flightDeadline'] == null
          ? null
          : DateTime.parse(json['flightDeadline'] as String),
      accommodationDeadline: json['accommodationDeadline'] == null
          ? null
          : DateTime.parse(json['accommodationDeadline'] as String),
    );

Map<String, dynamic> _$$TripLockinStatusImplToJson(
        _$TripLockinStatusImpl instance) =>
    <String, dynamic>{
      'tripId': instance.tripId,
      'squadSize': instance.squadSize,
      'flightsBooked': instance.flightsBooked,
      'accommodationBooked': instance.accommodationBooked,
      'flightLockinPct': instance.flightLockinPct,
      'accommodationLockinPct': instance.accommodationLockinPct,
      'flightDeadline': instance.flightDeadline?.toIso8601String(),
      'accommodationDeadline':
          instance.accommodationDeadline?.toIso8601String(),
    };

_$TripRecommendationImpl _$$TripRecommendationImplFromJson(
        Map<String, dynamic> json) =>
    _$TripRecommendationImpl(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      kind: $enumDecode(_$RecommendationKindEnumMap, json['kind']),
      rank: (json['rank'] as num).toInt(),
      name: json['name'] as String,
      neighborhood: json['neighborhood'] as String?,
      priceBand: json['priceBand'] as String?,
      cuisine: json['cuisine'] as String?,
      vibeTags: (json['vibeTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      reason: json['reason'] as String?,
      dayAnchor: (json['dayAnchor'] as num?)?.toInt(),
      meal: json['meal'] as String?,
      imageUrl: json['imageUrl'] as String?,
      mapsUrl: json['mapsUrl'] as String?,
      bookingUrl: json['bookingUrl'] as String?,
      placeId: json['placeId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TripRecommendationImplToJson(
        _$TripRecommendationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'kind': _$RecommendationKindEnumMap[instance.kind]!,
      'rank': instance.rank,
      'name': instance.name,
      'neighborhood': instance.neighborhood,
      'priceBand': instance.priceBand,
      'cuisine': instance.cuisine,
      'vibeTags': instance.vibeTags,
      'reason': instance.reason,
      'dayAnchor': instance.dayAnchor,
      'meal': instance.meal,
      'imageUrl': instance.imageUrl,
      'mapsUrl': instance.mapsUrl,
      'bookingUrl': instance.bookingUrl,
      'placeId': instance.placeId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$RecommendationKindEnumMap = {
  RecommendationKind.area: 'area',
  RecommendationKind.hotel: 'hotel',
  RecommendationKind.restaurant: 'restaurant',
};
