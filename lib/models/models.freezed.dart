// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Trip _$TripFromJson(Map<String, dynamic> json) {
  return _Trip.fromJson(json);
}

/// @nodoc
mixin _$Trip {
  String get id => throw _privateConstructorUsedError;
  String get hostId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  TripMode get mode => throw _privateConstructorUsedError;
  TripStatus get status => throw _privateConstructorUsedError;
  String? get inviteToken => throw _privateConstructorUsedError;
  List<String>? get vibes => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  int? get durationDays => throw _privateConstructorUsedError;
  String? get selectedDestination => throw _privateConstructorUsedError;
  String? get selectedFlag => throw _privateConstructorUsedError;
  int? get estimatedBudget => throw _privateConstructorUsedError;
  String? get coverPhotoUrl => throw _privateConstructorUsedError;
  List<SquadMember> get squadMembers => throw _privateConstructorUsedError;
  List<TripOption> get options => throw _privateConstructorUsedError;
  ItineraryDay? get itinerary => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TripCopyWith<Trip> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripCopyWith<$Res> {
  factory $TripCopyWith(Trip value, $Res Function(Trip) then) =
      _$TripCopyWithImpl<$Res, Trip>;
  @useResult
  $Res call(
      {String id,
      String hostId,
      String name,
      TripMode mode,
      TripStatus status,
      String? inviteToken,
      List<String>? vibes,
      DateTime? startDate,
      DateTime? endDate,
      int? durationDays,
      String? selectedDestination,
      String? selectedFlag,
      int? estimatedBudget,
      String? coverPhotoUrl,
      List<SquadMember> squadMembers,
      List<TripOption> options,
      ItineraryDay? itinerary,
      DateTime? createdAt,
      DateTime? updatedAt});

  $ItineraryDayCopyWith<$Res>? get itinerary;
}

/// @nodoc
class _$TripCopyWithImpl<$Res, $Val extends Trip>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hostId = null,
    Object? name = null,
    Object? mode = null,
    Object? status = null,
    Object? inviteToken = freezed,
    Object? vibes = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? durationDays = freezed,
    Object? selectedDestination = freezed,
    Object? selectedFlag = freezed,
    Object? estimatedBudget = freezed,
    Object? coverPhotoUrl = freezed,
    Object? squadMembers = null,
    Object? options = null,
    Object? itinerary = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      hostId: null == hostId
          ? _value.hostId
          : hostId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as TripMode,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TripStatus,
      inviteToken: freezed == inviteToken
          ? _value.inviteToken
          : inviteToken // ignore: cast_nullable_to_non_nullable
              as String?,
      vibes: freezed == vibes
          ? _value.vibes
          : vibes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      durationDays: freezed == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int?,
      selectedDestination: freezed == selectedDestination
          ? _value.selectedDestination
          : selectedDestination // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedFlag: freezed == selectedFlag
          ? _value.selectedFlag
          : selectedFlag // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedBudget: freezed == estimatedBudget
          ? _value.estimatedBudget
          : estimatedBudget // ignore: cast_nullable_to_non_nullable
              as int?,
      coverPhotoUrl: freezed == coverPhotoUrl
          ? _value.coverPhotoUrl
          : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      squadMembers: null == squadMembers
          ? _value.squadMembers
          : squadMembers // ignore: cast_nullable_to_non_nullable
              as List<SquadMember>,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<TripOption>,
      itinerary: freezed == itinerary
          ? _value.itinerary
          : itinerary // ignore: cast_nullable_to_non_nullable
              as ItineraryDay?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ItineraryDayCopyWith<$Res>? get itinerary {
    if (_value.itinerary == null) {
      return null;
    }

    return $ItineraryDayCopyWith<$Res>(_value.itinerary!, (value) {
      return _then(_value.copyWith(itinerary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TripImplCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$$TripImplCopyWith(
          _$TripImpl value, $Res Function(_$TripImpl) then) =
      __$$TripImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String hostId,
      String name,
      TripMode mode,
      TripStatus status,
      String? inviteToken,
      List<String>? vibes,
      DateTime? startDate,
      DateTime? endDate,
      int? durationDays,
      String? selectedDestination,
      String? selectedFlag,
      int? estimatedBudget,
      String? coverPhotoUrl,
      List<SquadMember> squadMembers,
      List<TripOption> options,
      ItineraryDay? itinerary,
      DateTime? createdAt,
      DateTime? updatedAt});

  @override
  $ItineraryDayCopyWith<$Res>? get itinerary;
}

/// @nodoc
class __$$TripImplCopyWithImpl<$Res>
    extends _$TripCopyWithImpl<$Res, _$TripImpl>
    implements _$$TripImplCopyWith<$Res> {
  __$$TripImplCopyWithImpl(_$TripImpl _value, $Res Function(_$TripImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hostId = null,
    Object? name = null,
    Object? mode = null,
    Object? status = null,
    Object? inviteToken = freezed,
    Object? vibes = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? durationDays = freezed,
    Object? selectedDestination = freezed,
    Object? selectedFlag = freezed,
    Object? estimatedBudget = freezed,
    Object? coverPhotoUrl = freezed,
    Object? squadMembers = null,
    Object? options = null,
    Object? itinerary = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$TripImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      hostId: null == hostId
          ? _value.hostId
          : hostId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as TripMode,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TripStatus,
      inviteToken: freezed == inviteToken
          ? _value.inviteToken
          : inviteToken // ignore: cast_nullable_to_non_nullable
              as String?,
      vibes: freezed == vibes
          ? _value._vibes
          : vibes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      durationDays: freezed == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int?,
      selectedDestination: freezed == selectedDestination
          ? _value.selectedDestination
          : selectedDestination // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedFlag: freezed == selectedFlag
          ? _value.selectedFlag
          : selectedFlag // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedBudget: freezed == estimatedBudget
          ? _value.estimatedBudget
          : estimatedBudget // ignore: cast_nullable_to_non_nullable
              as int?,
      coverPhotoUrl: freezed == coverPhotoUrl
          ? _value.coverPhotoUrl
          : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      squadMembers: null == squadMembers
          ? _value._squadMembers
          : squadMembers // ignore: cast_nullable_to_non_nullable
              as List<SquadMember>,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<TripOption>,
      itinerary: freezed == itinerary
          ? _value.itinerary
          : itinerary // ignore: cast_nullable_to_non_nullable
              as ItineraryDay?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TripImpl implements _Trip {
  const _$TripImpl(
      {required this.id,
      required this.hostId,
      required this.name,
      this.mode = TripMode.group,
      this.status = TripStatus.draft,
      this.inviteToken,
      final List<String>? vibes,
      this.startDate,
      this.endDate,
      this.durationDays,
      this.selectedDestination,
      this.selectedFlag,
      this.estimatedBudget,
      this.coverPhotoUrl,
      final List<SquadMember> squadMembers = const [],
      final List<TripOption> options = const [],
      this.itinerary,
      this.createdAt,
      this.updatedAt})
      : _vibes = vibes,
        _squadMembers = squadMembers,
        _options = options;

  factory _$TripImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripImplFromJson(json);

  @override
  final String id;
  @override
  final String hostId;
  @override
  final String name;
  @override
  @JsonKey()
  final TripMode mode;
  @override
  @JsonKey()
  final TripStatus status;
  @override
  final String? inviteToken;
  final List<String>? _vibes;
  @override
  List<String>? get vibes {
    final value = _vibes;
    if (value == null) return null;
    if (_vibes is EqualUnmodifiableListView) return _vibes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final int? durationDays;
  @override
  final String? selectedDestination;
  @override
  final String? selectedFlag;
  @override
  final int? estimatedBudget;
  @override
  final String? coverPhotoUrl;
  final List<SquadMember> _squadMembers;
  @override
  @JsonKey()
  List<SquadMember> get squadMembers {
    if (_squadMembers is EqualUnmodifiableListView) return _squadMembers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_squadMembers);
  }

  final List<TripOption> _options;
  @override
  @JsonKey()
  List<TripOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  final ItineraryDay? itinerary;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Trip(id: $id, hostId: $hostId, name: $name, mode: $mode, status: $status, inviteToken: $inviteToken, vibes: $vibes, startDate: $startDate, endDate: $endDate, durationDays: $durationDays, selectedDestination: $selectedDestination, selectedFlag: $selectedFlag, estimatedBudget: $estimatedBudget, coverPhotoUrl: $coverPhotoUrl, squadMembers: $squadMembers, options: $options, itinerary: $itinerary, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.hostId, hostId) || other.hostId == hostId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.inviteToken, inviteToken) ||
                other.inviteToken == inviteToken) &&
            const DeepCollectionEquality().equals(other._vibes, _vibes) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.selectedDestination, selectedDestination) ||
                other.selectedDestination == selectedDestination) &&
            (identical(other.selectedFlag, selectedFlag) ||
                other.selectedFlag == selectedFlag) &&
            (identical(other.estimatedBudget, estimatedBudget) ||
                other.estimatedBudget == estimatedBudget) &&
            (identical(other.coverPhotoUrl, coverPhotoUrl) ||
                other.coverPhotoUrl == coverPhotoUrl) &&
            const DeepCollectionEquality()
                .equals(other._squadMembers, _squadMembers) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.itinerary, itinerary) ||
                other.itinerary == itinerary) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        hostId,
        name,
        mode,
        status,
        inviteToken,
        const DeepCollectionEquality().hash(_vibes),
        startDate,
        endDate,
        durationDays,
        selectedDestination,
        selectedFlag,
        estimatedBudget,
        coverPhotoUrl,
        const DeepCollectionEquality().hash(_squadMembers),
        const DeepCollectionEquality().hash(_options),
        itinerary,
        createdAt,
        updatedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      __$$TripImplCopyWithImpl<_$TripImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripImplToJson(
      this,
    );
  }
}

abstract class _Trip implements Trip {
  const factory _Trip(
      {required final String id,
      required final String hostId,
      required final String name,
      final TripMode mode,
      final TripStatus status,
      final String? inviteToken,
      final List<String>? vibes,
      final DateTime? startDate,
      final DateTime? endDate,
      final int? durationDays,
      final String? selectedDestination,
      final String? selectedFlag,
      final int? estimatedBudget,
      final String? coverPhotoUrl,
      final List<SquadMember> squadMembers,
      final List<TripOption> options,
      final ItineraryDay? itinerary,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$TripImpl;

  factory _Trip.fromJson(Map<String, dynamic> json) = _$TripImpl.fromJson;

  @override
  String get id;
  @override
  String get hostId;
  @override
  String get name;
  @override
  TripMode get mode;
  @override
  TripStatus get status;
  @override
  String? get inviteToken;
  @override
  List<String>? get vibes;
  @override
  DateTime? get startDate;
  @override
  DateTime? get endDate;
  @override
  int? get durationDays;
  @override
  String? get selectedDestination;
  @override
  String? get selectedFlag;
  @override
  int? get estimatedBudget;
  @override
  String? get coverPhotoUrl;
  @override
  List<SquadMember> get squadMembers;
  @override
  List<TripOption> get options;
  @override
  ItineraryDay? get itinerary;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SquadMember _$SquadMemberFromJson(Map<String, dynamic> json) {
  return _SquadMember.fromJson(json);
}

/// @nodoc
mixin _$SquadMember {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;
  String get nickname => throw _privateConstructorUsedError;
  String? get emoji => throw _privateConstructorUsedError;
  MemberRole get role => throw _privateConstructorUsedError;
  MemberStatus get status => throw _privateConstructorUsedError;
  int? get budgetMin => throw _privateConstructorUsedError;
  int? get budgetMax => throw _privateConstructorUsedError;
  List<String>? get vibes => throw _privateConstructorUsedError;
  List<String>? get destinationPrefs => throw _privateConstructorUsedError;
  DateTime? get respondedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SquadMemberCopyWith<SquadMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SquadMemberCopyWith<$Res> {
  factory $SquadMemberCopyWith(
          SquadMember value, $Res Function(SquadMember) then) =
      _$SquadMemberCopyWithImpl<$Res, SquadMember>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? userId,
      String nickname,
      String? emoji,
      MemberRole role,
      MemberStatus status,
      int? budgetMin,
      int? budgetMax,
      List<String>? vibes,
      List<String>? destinationPrefs,
      DateTime? respondedAt,
      DateTime? createdAt});
}

/// @nodoc
class _$SquadMemberCopyWithImpl<$Res, $Val extends SquadMember>
    implements $SquadMemberCopyWith<$Res> {
  _$SquadMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = freezed,
    Object? nickname = null,
    Object? emoji = freezed,
    Object? role = null,
    Object? status = null,
    Object? budgetMin = freezed,
    Object? budgetMax = freezed,
    Object? vibes = freezed,
    Object? destinationPrefs = freezed,
    Object? respondedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: freezed == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MemberRole,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MemberStatus,
      budgetMin: freezed == budgetMin
          ? _value.budgetMin
          : budgetMin // ignore: cast_nullable_to_non_nullable
              as int?,
      budgetMax: freezed == budgetMax
          ? _value.budgetMax
          : budgetMax // ignore: cast_nullable_to_non_nullable
              as int?,
      vibes: freezed == vibes
          ? _value.vibes
          : vibes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      destinationPrefs: freezed == destinationPrefs
          ? _value.destinationPrefs
          : destinationPrefs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      respondedAt: freezed == respondedAt
          ? _value.respondedAt
          : respondedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SquadMemberImplCopyWith<$Res>
    implements $SquadMemberCopyWith<$Res> {
  factory _$$SquadMemberImplCopyWith(
          _$SquadMemberImpl value, $Res Function(_$SquadMemberImpl) then) =
      __$$SquadMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? userId,
      String nickname,
      String? emoji,
      MemberRole role,
      MemberStatus status,
      int? budgetMin,
      int? budgetMax,
      List<String>? vibes,
      List<String>? destinationPrefs,
      DateTime? respondedAt,
      DateTime? createdAt});
}

/// @nodoc
class __$$SquadMemberImplCopyWithImpl<$Res>
    extends _$SquadMemberCopyWithImpl<$Res, _$SquadMemberImpl>
    implements _$$SquadMemberImplCopyWith<$Res> {
  __$$SquadMemberImplCopyWithImpl(
      _$SquadMemberImpl _value, $Res Function(_$SquadMemberImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = freezed,
    Object? nickname = null,
    Object? emoji = freezed,
    Object? role = null,
    Object? status = null,
    Object? budgetMin = freezed,
    Object? budgetMax = freezed,
    Object? vibes = freezed,
    Object? destinationPrefs = freezed,
    Object? respondedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$SquadMemberImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: freezed == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MemberRole,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MemberStatus,
      budgetMin: freezed == budgetMin
          ? _value.budgetMin
          : budgetMin // ignore: cast_nullable_to_non_nullable
              as int?,
      budgetMax: freezed == budgetMax
          ? _value.budgetMax
          : budgetMax // ignore: cast_nullable_to_non_nullable
              as int?,
      vibes: freezed == vibes
          ? _value._vibes
          : vibes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      destinationPrefs: freezed == destinationPrefs
          ? _value._destinationPrefs
          : destinationPrefs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      respondedAt: freezed == respondedAt
          ? _value.respondedAt
          : respondedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SquadMemberImpl implements _SquadMember {
  const _$SquadMemberImpl(
      {required this.id,
      required this.tripId,
      this.userId,
      required this.nickname,
      this.emoji,
      this.role = MemberRole.member,
      this.status = MemberStatus.invited,
      this.budgetMin,
      this.budgetMax,
      final List<String>? vibes,
      final List<String>? destinationPrefs,
      this.respondedAt,
      this.createdAt})
      : _vibes = vibes,
        _destinationPrefs = destinationPrefs;

  factory _$SquadMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$SquadMemberImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String? userId;
  @override
  final String nickname;
  @override
  final String? emoji;
  @override
  @JsonKey()
  final MemberRole role;
  @override
  @JsonKey()
  final MemberStatus status;
  @override
  final int? budgetMin;
  @override
  final int? budgetMax;
  final List<String>? _vibes;
  @override
  List<String>? get vibes {
    final value = _vibes;
    if (value == null) return null;
    if (_vibes is EqualUnmodifiableListView) return _vibes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _destinationPrefs;
  @override
  List<String>? get destinationPrefs {
    final value = _destinationPrefs;
    if (value == null) return null;
    if (_destinationPrefs is EqualUnmodifiableListView)
      return _destinationPrefs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? respondedAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'SquadMember(id: $id, tripId: $tripId, userId: $userId, nickname: $nickname, emoji: $emoji, role: $role, status: $status, budgetMin: $budgetMin, budgetMax: $budgetMax, vibes: $vibes, destinationPrefs: $destinationPrefs, respondedAt: $respondedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SquadMemberImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.budgetMin, budgetMin) ||
                other.budgetMin == budgetMin) &&
            (identical(other.budgetMax, budgetMax) ||
                other.budgetMax == budgetMax) &&
            const DeepCollectionEquality().equals(other._vibes, _vibes) &&
            const DeepCollectionEquality()
                .equals(other._destinationPrefs, _destinationPrefs) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      userId,
      nickname,
      emoji,
      role,
      status,
      budgetMin,
      budgetMax,
      const DeepCollectionEquality().hash(_vibes),
      const DeepCollectionEquality().hash(_destinationPrefs),
      respondedAt,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SquadMemberImplCopyWith<_$SquadMemberImpl> get copyWith =>
      __$$SquadMemberImplCopyWithImpl<_$SquadMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SquadMemberImplToJson(
      this,
    );
  }
}

abstract class _SquadMember implements SquadMember {
  const factory _SquadMember(
      {required final String id,
      required final String tripId,
      final String? userId,
      required final String nickname,
      final String? emoji,
      final MemberRole role,
      final MemberStatus status,
      final int? budgetMin,
      final int? budgetMax,
      final List<String>? vibes,
      final List<String>? destinationPrefs,
      final DateTime? respondedAt,
      final DateTime? createdAt}) = _$SquadMemberImpl;

  factory _SquadMember.fromJson(Map<String, dynamic> json) =
      _$SquadMemberImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String? get userId;
  @override
  String get nickname;
  @override
  String? get emoji;
  @override
  MemberRole get role;
  @override
  MemberStatus get status;
  @override
  int? get budgetMin;
  @override
  int? get budgetMax;
  @override
  List<String>? get vibes;
  @override
  List<String>? get destinationPrefs;
  @override
  DateTime? get respondedAt;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$SquadMemberImplCopyWith<_$SquadMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TripOption _$TripOptionFromJson(Map<String, dynamic> json) {
  return _TripOption.fromJson(json);
}

/// @nodoc
mixin _$TripOption {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  String get flag => throw _privateConstructorUsedError;
  String get tagline => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int? get estimatedCostPp => throw _privateConstructorUsedError;
  int? get durationDays => throw _privateConstructorUsedError;
  List<String>? get vibeMatch => throw _privateConstructorUsedError;
  double? get compatibilityScore => throw _privateConstructorUsedError;
  int get voteCount => throw _privateConstructorUsedError;
  bool? get hasUserVoted => throw _privateConstructorUsedError;
  List<String> get highlights => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TripOptionCopyWith<TripOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripOptionCopyWith<$Res> {
  factory $TripOptionCopyWith(
          TripOption value, $Res Function(TripOption) then) =
      _$TripOptionCopyWithImpl<$Res, TripOption>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String destination,
      String country,
      String flag,
      String tagline,
      String? description,
      int? estimatedCostPp,
      int? durationDays,
      List<String>? vibeMatch,
      double? compatibilityScore,
      int voteCount,
      bool? hasUserVoted,
      List<String> highlights,
      DateTime? createdAt});
}

/// @nodoc
class _$TripOptionCopyWithImpl<$Res, $Val extends TripOption>
    implements $TripOptionCopyWith<$Res> {
  _$TripOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? destination = null,
    Object? country = null,
    Object? flag = null,
    Object? tagline = null,
    Object? description = freezed,
    Object? estimatedCostPp = freezed,
    Object? durationDays = freezed,
    Object? vibeMatch = freezed,
    Object? compatibilityScore = freezed,
    Object? voteCount = null,
    Object? hasUserVoted = freezed,
    Object? highlights = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      flag: null == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String,
      tagline: null == tagline
          ? _value.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedCostPp: freezed == estimatedCostPp
          ? _value.estimatedCostPp
          : estimatedCostPp // ignore: cast_nullable_to_non_nullable
              as int?,
      durationDays: freezed == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int?,
      vibeMatch: freezed == vibeMatch
          ? _value.vibeMatch
          : vibeMatch // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      compatibilityScore: freezed == compatibilityScore
          ? _value.compatibilityScore
          : compatibilityScore // ignore: cast_nullable_to_non_nullable
              as double?,
      voteCount: null == voteCount
          ? _value.voteCount
          : voteCount // ignore: cast_nullable_to_non_nullable
              as int,
      hasUserVoted: freezed == hasUserVoted
          ? _value.hasUserVoted
          : hasUserVoted // ignore: cast_nullable_to_non_nullable
              as bool?,
      highlights: null == highlights
          ? _value.highlights
          : highlights // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripOptionImplCopyWith<$Res>
    implements $TripOptionCopyWith<$Res> {
  factory _$$TripOptionImplCopyWith(
          _$TripOptionImpl value, $Res Function(_$TripOptionImpl) then) =
      __$$TripOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String destination,
      String country,
      String flag,
      String tagline,
      String? description,
      int? estimatedCostPp,
      int? durationDays,
      List<String>? vibeMatch,
      double? compatibilityScore,
      int voteCount,
      bool? hasUserVoted,
      List<String> highlights,
      DateTime? createdAt});
}

/// @nodoc
class __$$TripOptionImplCopyWithImpl<$Res>
    extends _$TripOptionCopyWithImpl<$Res, _$TripOptionImpl>
    implements _$$TripOptionImplCopyWith<$Res> {
  __$$TripOptionImplCopyWithImpl(
      _$TripOptionImpl _value, $Res Function(_$TripOptionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? destination = null,
    Object? country = null,
    Object? flag = null,
    Object? tagline = null,
    Object? description = freezed,
    Object? estimatedCostPp = freezed,
    Object? durationDays = freezed,
    Object? vibeMatch = freezed,
    Object? compatibilityScore = freezed,
    Object? voteCount = null,
    Object? hasUserVoted = freezed,
    Object? highlights = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$TripOptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      flag: null == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String,
      tagline: null == tagline
          ? _value.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedCostPp: freezed == estimatedCostPp
          ? _value.estimatedCostPp
          : estimatedCostPp // ignore: cast_nullable_to_non_nullable
              as int?,
      durationDays: freezed == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int?,
      vibeMatch: freezed == vibeMatch
          ? _value._vibeMatch
          : vibeMatch // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      compatibilityScore: freezed == compatibilityScore
          ? _value.compatibilityScore
          : compatibilityScore // ignore: cast_nullable_to_non_nullable
              as double?,
      voteCount: null == voteCount
          ? _value.voteCount
          : voteCount // ignore: cast_nullable_to_non_nullable
              as int,
      hasUserVoted: freezed == hasUserVoted
          ? _value.hasUserVoted
          : hasUserVoted // ignore: cast_nullable_to_non_nullable
              as bool?,
      highlights: null == highlights
          ? _value._highlights
          : highlights // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TripOptionImpl implements _TripOption {
  const _$TripOptionImpl(
      {required this.id,
      required this.tripId,
      required this.destination,
      required this.country,
      required this.flag,
      required this.tagline,
      this.description,
      this.estimatedCostPp,
      this.durationDays,
      final List<String>? vibeMatch,
      this.compatibilityScore,
      this.voteCount = 0,
      this.hasUserVoted,
      final List<String> highlights = const [],
      this.createdAt})
      : _vibeMatch = vibeMatch,
        _highlights = highlights;

  factory _$TripOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripOptionImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String destination;
  @override
  final String country;
  @override
  final String flag;
  @override
  final String tagline;
  @override
  final String? description;
  @override
  final int? estimatedCostPp;
  @override
  final int? durationDays;
  final List<String>? _vibeMatch;
  @override
  List<String>? get vibeMatch {
    final value = _vibeMatch;
    if (value == null) return null;
    if (_vibeMatch is EqualUnmodifiableListView) return _vibeMatch;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final double? compatibilityScore;
  @override
  @JsonKey()
  final int voteCount;
  @override
  final bool? hasUserVoted;
  final List<String> _highlights;
  @override
  @JsonKey()
  List<String> get highlights {
    if (_highlights is EqualUnmodifiableListView) return _highlights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_highlights);
  }

  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'TripOption(id: $id, tripId: $tripId, destination: $destination, country: $country, flag: $flag, tagline: $tagline, description: $description, estimatedCostPp: $estimatedCostPp, durationDays: $durationDays, vibeMatch: $vibeMatch, compatibilityScore: $compatibilityScore, voteCount: $voteCount, hasUserVoted: $hasUserVoted, highlights: $highlights, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripOptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.tagline, tagline) || other.tagline == tagline) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.estimatedCostPp, estimatedCostPp) ||
                other.estimatedCostPp == estimatedCostPp) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            const DeepCollectionEquality()
                .equals(other._vibeMatch, _vibeMatch) &&
            (identical(other.compatibilityScore, compatibilityScore) ||
                other.compatibilityScore == compatibilityScore) &&
            (identical(other.voteCount, voteCount) ||
                other.voteCount == voteCount) &&
            (identical(other.hasUserVoted, hasUserVoted) ||
                other.hasUserVoted == hasUserVoted) &&
            const DeepCollectionEquality()
                .equals(other._highlights, _highlights) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      destination,
      country,
      flag,
      tagline,
      description,
      estimatedCostPp,
      durationDays,
      const DeepCollectionEquality().hash(_vibeMatch),
      compatibilityScore,
      voteCount,
      hasUserVoted,
      const DeepCollectionEquality().hash(_highlights),
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripOptionImplCopyWith<_$TripOptionImpl> get copyWith =>
      __$$TripOptionImplCopyWithImpl<_$TripOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripOptionImplToJson(
      this,
    );
  }
}

abstract class _TripOption implements TripOption {
  const factory _TripOption(
      {required final String id,
      required final String tripId,
      required final String destination,
      required final String country,
      required final String flag,
      required final String tagline,
      final String? description,
      final int? estimatedCostPp,
      final int? durationDays,
      final List<String>? vibeMatch,
      final double? compatibilityScore,
      final int voteCount,
      final bool? hasUserVoted,
      final List<String> highlights,
      final DateTime? createdAt}) = _$TripOptionImpl;

  factory _TripOption.fromJson(Map<String, dynamic> json) =
      _$TripOptionImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String get destination;
  @override
  String get country;
  @override
  String get flag;
  @override
  String get tagline;
  @override
  String? get description;
  @override
  int? get estimatedCostPp;
  @override
  int? get durationDays;
  @override
  List<String>? get vibeMatch;
  @override
  double? get compatibilityScore;
  @override
  int get voteCount;
  @override
  bool? get hasUserVoted;
  @override
  List<String> get highlights;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$TripOptionImplCopyWith<_$TripOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItineraryDay _$ItineraryDayFromJson(Map<String, dynamic> json) {
  return _ItineraryDay.fromJson(json);
}

/// @nodoc
mixin _$ItineraryDay {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  int get dayNumber => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<ItineraryItem> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'packing')
  List<PackingItem> get packingList => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItineraryDayCopyWith<ItineraryDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryDayCopyWith<$Res> {
  factory $ItineraryDayCopyWith(
          ItineraryDay value, $Res Function(ItineraryDay) then) =
      _$ItineraryDayCopyWithImpl<$Res, ItineraryDay>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      int dayNumber,
      String title,
      List<ItineraryItem> items,
      @JsonKey(name: 'packing') List<PackingItem> packingList});
}

/// @nodoc
class _$ItineraryDayCopyWithImpl<$Res, $Val extends ItineraryDay>
    implements $ItineraryDayCopyWith<$Res> {
  _$ItineraryDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? dayNumber = null,
    Object? title = null,
    Object? items = null,
    Object? packingList = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItineraryItem>,
      packingList: null == packingList
          ? _value.packingList
          : packingList // ignore: cast_nullable_to_non_nullable
              as List<PackingItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryDayImplCopyWith<$Res>
    implements $ItineraryDayCopyWith<$Res> {
  factory _$$ItineraryDayImplCopyWith(
          _$ItineraryDayImpl value, $Res Function(_$ItineraryDayImpl) then) =
      __$$ItineraryDayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      int dayNumber,
      String title,
      List<ItineraryItem> items,
      @JsonKey(name: 'packing') List<PackingItem> packingList});
}

/// @nodoc
class __$$ItineraryDayImplCopyWithImpl<$Res>
    extends _$ItineraryDayCopyWithImpl<$Res, _$ItineraryDayImpl>
    implements _$$ItineraryDayImplCopyWith<$Res> {
  __$$ItineraryDayImplCopyWithImpl(
      _$ItineraryDayImpl _value, $Res Function(_$ItineraryDayImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? dayNumber = null,
    Object? title = null,
    Object? items = null,
    Object? packingList = null,
  }) {
    return _then(_$ItineraryDayImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItineraryItem>,
      packingList: null == packingList
          ? _value._packingList
          : packingList // ignore: cast_nullable_to_non_nullable
              as List<PackingItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryDayImpl implements _ItineraryDay {
  const _$ItineraryDayImpl(
      {required this.id,
      required this.tripId,
      required this.dayNumber,
      required this.title,
      final List<ItineraryItem> items = const [],
      @JsonKey(name: 'packing') final List<PackingItem> packingList = const []})
      : _items = items,
        _packingList = packingList;

  factory _$ItineraryDayImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryDayImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final int dayNumber;
  @override
  final String title;
  final List<ItineraryItem> _items;
  @override
  @JsonKey()
  List<ItineraryItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<PackingItem> _packingList;
  @override
  @JsonKey(name: 'packing')
  List<PackingItem> get packingList {
    if (_packingList is EqualUnmodifiableListView) return _packingList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_packingList);
  }

  @override
  String toString() {
    return 'ItineraryDay(id: $id, tripId: $tripId, dayNumber: $dayNumber, title: $title, items: $items, packingList: $packingList)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryDayImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality()
                .equals(other._packingList, _packingList));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      dayNumber,
      title,
      const DeepCollectionEquality().hash(_items),
      const DeepCollectionEquality().hash(_packingList));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryDayImplCopyWith<_$ItineraryDayImpl> get copyWith =>
      __$$ItineraryDayImplCopyWithImpl<_$ItineraryDayImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryDayImplToJson(
      this,
    );
  }
}

abstract class _ItineraryDay implements ItineraryDay {
  const factory _ItineraryDay(
          {required final String id,
          required final String tripId,
          required final int dayNumber,
          required final String title,
          final List<ItineraryItem> items,
          @JsonKey(name: 'packing') final List<PackingItem> packingList}) =
      _$ItineraryDayImpl;

  factory _ItineraryDay.fromJson(Map<String, dynamic> json) =
      _$ItineraryDayImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  int get dayNumber;
  @override
  String get title;
  @override
  List<ItineraryItem> get items;
  @override
  @JsonKey(name: 'packing')
  List<PackingItem> get packingList;
  @override
  @JsonKey(ignore: true)
  _$$ItineraryDayImplCopyWith<_$ItineraryDayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItineraryItem _$ItineraryItemFromJson(Map<String, dynamic> json) {
  return _ItineraryItem.fromJson(json);
}

/// @nodoc
mixin _$ItineraryItem {
  String? get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get timeOfDay =>
      throw _privateConstructorUsedError; // morning, afternoon, evening, night
  String? get description => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  String? get estimatedCost => throw _privateConstructorUsedError;
  String? get bookingUrl => throw _privateConstructorUsedError;
  bool? get requiresBooking => throw _privateConstructorUsedError;
  String? get soloTip => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItineraryItemCopyWith<ItineraryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryItemCopyWith<$Res> {
  factory $ItineraryItemCopyWith(
          ItineraryItem value, $Res Function(ItineraryItem) then) =
      _$ItineraryItemCopyWithImpl<$Res, ItineraryItem>;
  @useResult
  $Res call(
      {String? id,
      String title,
      String timeOfDay,
      String? description,
      String? location,
      String? estimatedCost,
      String? bookingUrl,
      bool? requiresBooking,
      String? soloTip});
}

/// @nodoc
class _$ItineraryItemCopyWithImpl<$Res, $Val extends ItineraryItem>
    implements $ItineraryItemCopyWith<$Res> {
  _$ItineraryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? timeOfDay = null,
    Object? description = freezed,
    Object? location = freezed,
    Object? estimatedCost = freezed,
    Object? bookingUrl = freezed,
    Object? requiresBooking = freezed,
    Object? soloTip = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      timeOfDay: null == timeOfDay
          ? _value.timeOfDay
          : timeOfDay // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedCost: freezed == estimatedCost
          ? _value.estimatedCost
          : estimatedCost // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingUrl: freezed == bookingUrl
          ? _value.bookingUrl
          : bookingUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresBooking: freezed == requiresBooking
          ? _value.requiresBooking
          : requiresBooking // ignore: cast_nullable_to_non_nullable
              as bool?,
      soloTip: freezed == soloTip
          ? _value.soloTip
          : soloTip // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryItemImplCopyWith<$Res>
    implements $ItineraryItemCopyWith<$Res> {
  factory _$$ItineraryItemImplCopyWith(
          _$ItineraryItemImpl value, $Res Function(_$ItineraryItemImpl) then) =
      __$$ItineraryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String title,
      String timeOfDay,
      String? description,
      String? location,
      String? estimatedCost,
      String? bookingUrl,
      bool? requiresBooking,
      String? soloTip});
}

/// @nodoc
class __$$ItineraryItemImplCopyWithImpl<$Res>
    extends _$ItineraryItemCopyWithImpl<$Res, _$ItineraryItemImpl>
    implements _$$ItineraryItemImplCopyWith<$Res> {
  __$$ItineraryItemImplCopyWithImpl(
      _$ItineraryItemImpl _value, $Res Function(_$ItineraryItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? timeOfDay = null,
    Object? description = freezed,
    Object? location = freezed,
    Object? estimatedCost = freezed,
    Object? bookingUrl = freezed,
    Object? requiresBooking = freezed,
    Object? soloTip = freezed,
  }) {
    return _then(_$ItineraryItemImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      timeOfDay: null == timeOfDay
          ? _value.timeOfDay
          : timeOfDay // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedCost: freezed == estimatedCost
          ? _value.estimatedCost
          : estimatedCost // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingUrl: freezed == bookingUrl
          ? _value.bookingUrl
          : bookingUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresBooking: freezed == requiresBooking
          ? _value.requiresBooking
          : requiresBooking // ignore: cast_nullable_to_non_nullable
              as bool?,
      soloTip: freezed == soloTip
          ? _value.soloTip
          : soloTip // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryItemImpl implements _ItineraryItem {
  const _$ItineraryItemImpl(
      {this.id,
      required this.title,
      this.timeOfDay = 'morning',
      this.description,
      this.location,
      this.estimatedCost,
      this.bookingUrl,
      this.requiresBooking,
      this.soloTip});

  factory _$ItineraryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryItemImplFromJson(json);

  @override
  final String? id;
  @override
  final String title;
  @override
  @JsonKey()
  final String timeOfDay;
// morning, afternoon, evening, night
  @override
  final String? description;
  @override
  final String? location;
  @override
  final String? estimatedCost;
  @override
  final String? bookingUrl;
  @override
  final bool? requiresBooking;
  @override
  final String? soloTip;

  @override
  String toString() {
    return 'ItineraryItem(id: $id, title: $title, timeOfDay: $timeOfDay, description: $description, location: $location, estimatedCost: $estimatedCost, bookingUrl: $bookingUrl, requiresBooking: $requiresBooking, soloTip: $soloTip)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.timeOfDay, timeOfDay) ||
                other.timeOfDay == timeOfDay) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.estimatedCost, estimatedCost) ||
                other.estimatedCost == estimatedCost) &&
            (identical(other.bookingUrl, bookingUrl) ||
                other.bookingUrl == bookingUrl) &&
            (identical(other.requiresBooking, requiresBooking) ||
                other.requiresBooking == requiresBooking) &&
            (identical(other.soloTip, soloTip) || other.soloTip == soloTip));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      timeOfDay,
      description,
      location,
      estimatedCost,
      bookingUrl,
      requiresBooking,
      soloTip);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryItemImplCopyWith<_$ItineraryItemImpl> get copyWith =>
      __$$ItineraryItemImplCopyWithImpl<_$ItineraryItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryItemImplToJson(
      this,
    );
  }
}

abstract class _ItineraryItem implements ItineraryItem {
  const factory _ItineraryItem(
      {final String? id,
      required final String title,
      final String timeOfDay,
      final String? description,
      final String? location,
      final String? estimatedCost,
      final String? bookingUrl,
      final bool? requiresBooking,
      final String? soloTip}) = _$ItineraryItemImpl;

  factory _ItineraryItem.fromJson(Map<String, dynamic> json) =
      _$ItineraryItemImpl.fromJson;

  @override
  String? get id;
  @override
  String get title;
  @override
  String get timeOfDay;
  @override // morning, afternoon, evening, night
  String? get description;
  @override
  String? get location;
  @override
  String? get estimatedCost;
  @override
  String? get bookingUrl;
  @override
  bool? get requiresBooking;
  @override
  String? get soloTip;
  @override
  @JsonKey(ignore: true)
  _$$ItineraryItemImplCopyWith<_$ItineraryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PackingItem _$PackingItemFromJson(Map<String, dynamic> json) {
  return _PackingItem.fromJson(json);
}

/// @nodoc
mixin _$PackingItem {
  String? get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  bool get packed => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PackingItemCopyWith<PackingItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PackingItemCopyWith<$Res> {
  factory $PackingItemCopyWith(
          PackingItem value, $Res Function(PackingItem) then) =
      _$PackingItemCopyWithImpl<$Res, PackingItem>;
  @useResult
  $Res call({String? id, String label, String category, bool packed});
}

/// @nodoc
class _$PackingItemCopyWithImpl<$Res, $Val extends PackingItem>
    implements $PackingItemCopyWith<$Res> {
  _$PackingItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? label = null,
    Object? category = null,
    Object? packed = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      packed: null == packed
          ? _value.packed
          : packed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PackingItemImplCopyWith<$Res>
    implements $PackingItemCopyWith<$Res> {
  factory _$$PackingItemImplCopyWith(
          _$PackingItemImpl value, $Res Function(_$PackingItemImpl) then) =
      __$$PackingItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? id, String label, String category, bool packed});
}

/// @nodoc
class __$$PackingItemImplCopyWithImpl<$Res>
    extends _$PackingItemCopyWithImpl<$Res, _$PackingItemImpl>
    implements _$$PackingItemImplCopyWith<$Res> {
  __$$PackingItemImplCopyWithImpl(
      _$PackingItemImpl _value, $Res Function(_$PackingItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? label = null,
    Object? category = null,
    Object? packed = null,
  }) {
    return _then(_$PackingItemImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      packed: null == packed
          ? _value.packed
          : packed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PackingItemImpl implements _PackingItem {
  const _$PackingItemImpl(
      {this.id, required this.label, this.category = '', this.packed = false});

  factory _$PackingItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PackingItemImplFromJson(json);

  @override
  final String? id;
  @override
  final String label;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey()
  final bool packed;

  @override
  String toString() {
    return 'PackingItem(id: $id, label: $label, category: $category, packed: $packed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.packed, packed) || other.packed == packed));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, label, category, packed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingItemImplCopyWith<_$PackingItemImpl> get copyWith =>
      __$$PackingItemImplCopyWithImpl<_$PackingItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PackingItemImplToJson(
      this,
    );
  }
}

abstract class _PackingItem implements PackingItem {
  const factory _PackingItem(
      {final String? id,
      required final String label,
      final String category,
      final bool packed}) = _$PackingItemImpl;

  factory _PackingItem.fromJson(Map<String, dynamic> json) =
      _$PackingItemImpl.fromJson;

  @override
  String? get id;
  @override
  String get label;
  @override
  String get category;
  @override
  bool get packed;
  @override
  @JsonKey(ignore: true)
  _$$PackingItemImplCopyWith<_$PackingItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppUser _$AppUserFromJson(Map<String, dynamic> json) {
  return _AppUser.fromJson(json);
}

/// @nodoc
mixin _$AppUser {
  String get id => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get nickname => throw _privateConstructorUsedError;
  String? get emoji => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  SubscriptionTier get tier => throw _privateConstructorUsedError;
  List<String> get passportStamps => throw _privateConstructorUsedError;
  String? get homeCity => throw _privateConstructorUsedError;
  String? get homeAirport => throw _privateConstructorUsedError;
  String? get travelStyle => throw _privateConstructorUsedError;
  List<String> get passports => throw _privateConstructorUsedError;
  String? get tag => throw _privateConstructorUsedError;
  String get privacyLevel => throw _privateConstructorUsedError;
  bool get profileComplete => throw _privateConstructorUsedError;
  int get tripsCompleted => throw _privateConstructorUsedError;
  DateTime? get lastHandleChange => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppUserCopyWith<AppUser> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppUserCopyWith<$Res> {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) then) =
      _$AppUserCopyWithImpl<$Res, AppUser>;
  @useResult
  $Res call(
      {String id,
      String? email,
      String? nickname,
      String? emoji,
      String? avatarUrl,
      SubscriptionTier tier,
      List<String> passportStamps,
      String? homeCity,
      String? homeAirport,
      String? travelStyle,
      List<String> passports,
      String? tag,
      String privacyLevel,
      bool profileComplete,
      int tripsCompleted,
      DateTime? lastHandleChange,
      DateTime? createdAt});
}

/// @nodoc
class _$AppUserCopyWithImpl<$Res, $Val extends AppUser>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = freezed,
    Object? nickname = freezed,
    Object? emoji = freezed,
    Object? avatarUrl = freezed,
    Object? tier = null,
    Object? passportStamps = null,
    Object? homeCity = freezed,
    Object? homeAirport = freezed,
    Object? travelStyle = freezed,
    Object? passports = null,
    Object? tag = freezed,
    Object? privacyLevel = null,
    Object? profileComplete = null,
    Object? tripsCompleted = null,
    Object? lastHandleChange = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      emoji: freezed == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as SubscriptionTier,
      passportStamps: null == passportStamps
          ? _value.passportStamps
          : passportStamps // ignore: cast_nullable_to_non_nullable
              as List<String>,
      homeCity: freezed == homeCity
          ? _value.homeCity
          : homeCity // ignore: cast_nullable_to_non_nullable
              as String?,
      homeAirport: freezed == homeAirport
          ? _value.homeAirport
          : homeAirport // ignore: cast_nullable_to_non_nullable
              as String?,
      travelStyle: freezed == travelStyle
          ? _value.travelStyle
          : travelStyle // ignore: cast_nullable_to_non_nullable
              as String?,
      passports: null == passports
          ? _value.passports
          : passports // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tag: freezed == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as String?,
      privacyLevel: null == privacyLevel
          ? _value.privacyLevel
          : privacyLevel // ignore: cast_nullable_to_non_nullable
              as String,
      profileComplete: null == profileComplete
          ? _value.profileComplete
          : profileComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      tripsCompleted: null == tripsCompleted
          ? _value.tripsCompleted
          : tripsCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      lastHandleChange: freezed == lastHandleChange
          ? _value.lastHandleChange
          : lastHandleChange // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppUserImplCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$$AppUserImplCopyWith(
          _$AppUserImpl value, $Res Function(_$AppUserImpl) then) =
      __$$AppUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? email,
      String? nickname,
      String? emoji,
      String? avatarUrl,
      SubscriptionTier tier,
      List<String> passportStamps,
      String? homeCity,
      String? homeAirport,
      String? travelStyle,
      List<String> passports,
      String? tag,
      String privacyLevel,
      bool profileComplete,
      int tripsCompleted,
      DateTime? lastHandleChange,
      DateTime? createdAt});
}

/// @nodoc
class __$$AppUserImplCopyWithImpl<$Res>
    extends _$AppUserCopyWithImpl<$Res, _$AppUserImpl>
    implements _$$AppUserImplCopyWith<$Res> {
  __$$AppUserImplCopyWithImpl(
      _$AppUserImpl _value, $Res Function(_$AppUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = freezed,
    Object? nickname = freezed,
    Object? emoji = freezed,
    Object? avatarUrl = freezed,
    Object? tier = null,
    Object? passportStamps = null,
    Object? homeCity = freezed,
    Object? homeAirport = freezed,
    Object? travelStyle = freezed,
    Object? passports = null,
    Object? tag = freezed,
    Object? privacyLevel = null,
    Object? profileComplete = null,
    Object? tripsCompleted = null,
    Object? lastHandleChange = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$AppUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      emoji: freezed == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as SubscriptionTier,
      passportStamps: null == passportStamps
          ? _value._passportStamps
          : passportStamps // ignore: cast_nullable_to_non_nullable
              as List<String>,
      homeCity: freezed == homeCity
          ? _value.homeCity
          : homeCity // ignore: cast_nullable_to_non_nullable
              as String?,
      homeAirport: freezed == homeAirport
          ? _value.homeAirport
          : homeAirport // ignore: cast_nullable_to_non_nullable
              as String?,
      travelStyle: freezed == travelStyle
          ? _value.travelStyle
          : travelStyle // ignore: cast_nullable_to_non_nullable
              as String?,
      passports: null == passports
          ? _value._passports
          : passports // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tag: freezed == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as String?,
      privacyLevel: null == privacyLevel
          ? _value.privacyLevel
          : privacyLevel // ignore: cast_nullable_to_non_nullable
              as String,
      profileComplete: null == profileComplete
          ? _value.profileComplete
          : profileComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      tripsCompleted: null == tripsCompleted
          ? _value.tripsCompleted
          : tripsCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      lastHandleChange: freezed == lastHandleChange
          ? _value.lastHandleChange
          : lastHandleChange // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppUserImpl implements _AppUser {
  const _$AppUserImpl(
      {required this.id,
      this.email,
      this.nickname,
      this.emoji,
      this.avatarUrl,
      this.tier = SubscriptionTier.free,
      final List<String> passportStamps = const [],
      this.homeCity,
      this.homeAirport,
      this.travelStyle,
      final List<String> passports = const [],
      this.tag,
      this.privacyLevel = 'private',
      this.profileComplete = false,
      this.tripsCompleted = 0,
      this.lastHandleChange,
      this.createdAt})
      : _passportStamps = passportStamps,
        _passports = passports;

  factory _$AppUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppUserImplFromJson(json);

  @override
  final String id;
  @override
  final String? email;
  @override
  final String? nickname;
  @override
  final String? emoji;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final SubscriptionTier tier;
  final List<String> _passportStamps;
  @override
  @JsonKey()
  List<String> get passportStamps {
    if (_passportStamps is EqualUnmodifiableListView) return _passportStamps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_passportStamps);
  }

  @override
  final String? homeCity;
  @override
  final String? homeAirport;
  @override
  final String? travelStyle;
  final List<String> _passports;
  @override
  @JsonKey()
  List<String> get passports {
    if (_passports is EqualUnmodifiableListView) return _passports;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_passports);
  }

  @override
  final String? tag;
  @override
  @JsonKey()
  final String privacyLevel;
  @override
  @JsonKey()
  final bool profileComplete;
  @override
  @JsonKey()
  final int tripsCompleted;
  @override
  final DateTime? lastHandleChange;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, nickname: $nickname, emoji: $emoji, avatarUrl: $avatarUrl, tier: $tier, passportStamps: $passportStamps, homeCity: $homeCity, homeAirport: $homeAirport, travelStyle: $travelStyle, passports: $passports, tag: $tag, privacyLevel: $privacyLevel, profileComplete: $profileComplete, tripsCompleted: $tripsCompleted, lastHandleChange: $lastHandleChange, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            const DeepCollectionEquality()
                .equals(other._passportStamps, _passportStamps) &&
            (identical(other.homeCity, homeCity) ||
                other.homeCity == homeCity) &&
            (identical(other.homeAirport, homeAirport) ||
                other.homeAirport == homeAirport) &&
            (identical(other.travelStyle, travelStyle) ||
                other.travelStyle == travelStyle) &&
            const DeepCollectionEquality()
                .equals(other._passports, _passports) &&
            (identical(other.tag, tag) || other.tag == tag) &&
            (identical(other.privacyLevel, privacyLevel) ||
                other.privacyLevel == privacyLevel) &&
            (identical(other.profileComplete, profileComplete) ||
                other.profileComplete == profileComplete) &&
            (identical(other.tripsCompleted, tripsCompleted) ||
                other.tripsCompleted == tripsCompleted) &&
            (identical(other.lastHandleChange, lastHandleChange) ||
                other.lastHandleChange == lastHandleChange) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      nickname,
      emoji,
      avatarUrl,
      tier,
      const DeepCollectionEquality().hash(_passportStamps),
      homeCity,
      homeAirport,
      travelStyle,
      const DeepCollectionEquality().hash(_passports),
      tag,
      privacyLevel,
      profileComplete,
      tripsCompleted,
      lastHandleChange,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppUserImplCopyWith<_$AppUserImpl> get copyWith =>
      __$$AppUserImplCopyWithImpl<_$AppUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppUserImplToJson(
      this,
    );
  }
}

abstract class _AppUser implements AppUser {
  const factory _AppUser(
      {required final String id,
      final String? email,
      final String? nickname,
      final String? emoji,
      final String? avatarUrl,
      final SubscriptionTier tier,
      final List<String> passportStamps,
      final String? homeCity,
      final String? homeAirport,
      final String? travelStyle,
      final List<String> passports,
      final String? tag,
      final String privacyLevel,
      final bool profileComplete,
      final int tripsCompleted,
      final DateTime? lastHandleChange,
      final DateTime? createdAt}) = _$AppUserImpl;

  factory _AppUser.fromJson(Map<String, dynamic> json) = _$AppUserImpl.fromJson;

  @override
  String get id;
  @override
  String? get email;
  @override
  String? get nickname;
  @override
  String? get emoji;
  @override
  String? get avatarUrl;
  @override
  SubscriptionTier get tier;
  @override
  List<String> get passportStamps;
  @override
  String? get homeCity;
  @override
  String? get homeAirport;
  @override
  String? get travelStyle;
  @override
  List<String> get passports;
  @override
  String? get tag;
  @override
  String get privacyLevel;
  @override
  bool get profileComplete;
  @override
  int get tripsCompleted;
  @override
  DateTime? get lastHandleChange;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$AppUserImplCopyWith<_$AppUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TripEvent _$TripEventFromJson(Map<String, dynamic> json) {
  return _TripEvent.fromJson(json);
}

/// @nodoc
mixin _$TripEvent {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String? get actorUserId => throw _privateConstructorUsedError;
  String? get actorTag => throw _privateConstructorUsedError;
  Map<String, dynamic>? get payload => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TripEventCopyWith<TripEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripEventCopyWith<$Res> {
  factory $TripEventCopyWith(TripEvent value, $Res Function(TripEvent) then) =
      _$TripEventCopyWithImpl<$Res, TripEvent>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String kind,
      String? actorUserId,
      String? actorTag,
      Map<String, dynamic>? payload,
      DateTime? createdAt});
}

/// @nodoc
class _$TripEventCopyWithImpl<$Res, $Val extends TripEvent>
    implements $TripEventCopyWith<$Res> {
  _$TripEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? kind = null,
    Object? actorUserId = freezed,
    Object? actorTag = freezed,
    Object? payload = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      actorUserId: freezed == actorUserId
          ? _value.actorUserId
          : actorUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      actorTag: freezed == actorTag
          ? _value.actorTag
          : actorTag // ignore: cast_nullable_to_non_nullable
              as String?,
      payload: freezed == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripEventImplCopyWith<$Res>
    implements $TripEventCopyWith<$Res> {
  factory _$$TripEventImplCopyWith(
          _$TripEventImpl value, $Res Function(_$TripEventImpl) then) =
      __$$TripEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String kind,
      String? actorUserId,
      String? actorTag,
      Map<String, dynamic>? payload,
      DateTime? createdAt});
}

/// @nodoc
class __$$TripEventImplCopyWithImpl<$Res>
    extends _$TripEventCopyWithImpl<$Res, _$TripEventImpl>
    implements _$$TripEventImplCopyWith<$Res> {
  __$$TripEventImplCopyWithImpl(
      _$TripEventImpl _value, $Res Function(_$TripEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? kind = null,
    Object? actorUserId = freezed,
    Object? actorTag = freezed,
    Object? payload = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$TripEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      actorUserId: freezed == actorUserId
          ? _value.actorUserId
          : actorUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      actorTag: freezed == actorTag
          ? _value.actorTag
          : actorTag // ignore: cast_nullable_to_non_nullable
              as String?,
      payload: freezed == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TripEventImpl implements _TripEvent {
  const _$TripEventImpl(
      {required this.id,
      required this.tripId,
      required this.kind,
      this.actorUserId,
      this.actorTag,
      final Map<String, dynamic>? payload,
      this.createdAt})
      : _payload = payload;

  factory _$TripEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripEventImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String kind;
  @override
  final String? actorUserId;
  @override
  final String? actorTag;
  final Map<String, dynamic>? _payload;
  @override
  Map<String, dynamic>? get payload {
    final value = _payload;
    if (value == null) return null;
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'TripEvent(id: $id, tripId: $tripId, kind: $kind, actorUserId: $actorUserId, actorTag: $actorTag, payload: $payload, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.actorUserId, actorUserId) ||
                other.actorUserId == actorUserId) &&
            (identical(other.actorTag, actorTag) ||
                other.actorTag == actorTag) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, tripId, kind, actorUserId,
      actorTag, const DeepCollectionEquality().hash(_payload), createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripEventImplCopyWith<_$TripEventImpl> get copyWith =>
      __$$TripEventImplCopyWithImpl<_$TripEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripEventImplToJson(
      this,
    );
  }
}

abstract class _TripEvent implements TripEvent {
  const factory _TripEvent(
      {required final String id,
      required final String tripId,
      required final String kind,
      final String? actorUserId,
      final String? actorTag,
      final Map<String, dynamic>? payload,
      final DateTime? createdAt}) = _$TripEventImpl;

  factory _TripEvent.fromJson(Map<String, dynamic> json) =
      _$TripEventImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String get kind;
  @override
  String? get actorUserId;
  @override
  String? get actorTag;
  @override
  Map<String, dynamic>? get payload;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$TripEventImplCopyWith<_$TripEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) {
  return _NotificationItem.fromJson(json);
}

/// @nodoc
mixin _$NotificationItem {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get tripId => throw _privateConstructorUsedError;
  String? get eventId => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get body => throw _privateConstructorUsedError;
  DateTime? get readAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationItemCopyWith<NotificationItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationItemCopyWith<$Res> {
  factory $NotificationItemCopyWith(
          NotificationItem value, $Res Function(NotificationItem) then) =
      _$NotificationItemCopyWithImpl<$Res, NotificationItem>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String? tripId,
      String? eventId,
      String kind,
      String title,
      String? body,
      DateTime? readAt,
      DateTime? createdAt});
}

/// @nodoc
class _$NotificationItemCopyWithImpl<$Res, $Val extends NotificationItem>
    implements $NotificationItemCopyWith<$Res> {
  _$NotificationItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? tripId = freezed,
    Object? eventId = freezed,
    Object? kind = null,
    Object? title = null,
    Object? body = freezed,
    Object? readAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: freezed == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String?,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationItemImplCopyWith<$Res>
    implements $NotificationItemCopyWith<$Res> {
  factory _$$NotificationItemImplCopyWith(_$NotificationItemImpl value,
          $Res Function(_$NotificationItemImpl) then) =
      __$$NotificationItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String? tripId,
      String? eventId,
      String kind,
      String title,
      String? body,
      DateTime? readAt,
      DateTime? createdAt});
}

/// @nodoc
class __$$NotificationItemImplCopyWithImpl<$Res>
    extends _$NotificationItemCopyWithImpl<$Res, _$NotificationItemImpl>
    implements _$$NotificationItemImplCopyWith<$Res> {
  __$$NotificationItemImplCopyWithImpl(_$NotificationItemImpl _value,
      $Res Function(_$NotificationItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? tripId = freezed,
    Object? eventId = freezed,
    Object? kind = null,
    Object? title = null,
    Object? body = freezed,
    Object? readAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$NotificationItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: freezed == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String?,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationItemImpl implements _NotificationItem {
  const _$NotificationItemImpl(
      {required this.id,
      required this.userId,
      this.tripId,
      this.eventId,
      required this.kind,
      required this.title,
      this.body,
      this.readAt,
      this.createdAt});

  factory _$NotificationItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationItemImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? tripId;
  @override
  final String? eventId;
  @override
  final String kind;
  @override
  final String title;
  @override
  final String? body;
  @override
  final DateTime? readAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'NotificationItem(id: $id, userId: $userId, tripId: $tripId, eventId: $eventId, kind: $kind, title: $title, body: $body, readAt: $readAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, tripId, eventId,
      kind, title, body, readAt, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationItemImplCopyWith<_$NotificationItemImpl> get copyWith =>
      __$$NotificationItemImplCopyWithImpl<_$NotificationItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationItemImplToJson(
      this,
    );
  }
}

abstract class _NotificationItem implements NotificationItem {
  const factory _NotificationItem(
      {required final String id,
      required final String userId,
      final String? tripId,
      final String? eventId,
      required final String kind,
      required final String title,
      final String? body,
      final DateTime? readAt,
      final DateTime? createdAt}) = _$NotificationItemImpl;

  factory _NotificationItem.fromJson(Map<String, dynamic> json) =
      _$NotificationItemImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get tripId;
  @override
  String? get eventId;
  @override
  String get kind;
  @override
  String get title;
  @override
  String? get body;
  @override
  DateTime? get readAt;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$NotificationItemImplCopyWith<_$NotificationItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DirectMessage _$DirectMessageFromJson(Map<String, dynamic> json) {
  return _DirectMessage.fromJson(json);
}

/// @nodoc
mixin _$DirectMessage {
  String get id => throw _privateConstructorUsedError;
  String get fromUser => throw _privateConstructorUsedError;
  String get toUser => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String? get replyToId => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get audioUrl => throw _privateConstructorUsedError;
  int? get audioDurationMs => throw _privateConstructorUsedError;
  DateTime? get readAt => throw _privateConstructorUsedError;
  DateTime? get editedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DirectMessageCopyWith<DirectMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DirectMessageCopyWith<$Res> {
  factory $DirectMessageCopyWith(
          DirectMessage value, $Res Function(DirectMessage) then) =
      _$DirectMessageCopyWithImpl<$Res, DirectMessage>;
  @useResult
  $Res call(
      {String id,
      String fromUser,
      String toUser,
      String content,
      String? replyToId,
      String? imageUrl,
      String? audioUrl,
      int? audioDurationMs,
      DateTime? readAt,
      DateTime? editedAt,
      DateTime? createdAt});
}

/// @nodoc
class _$DirectMessageCopyWithImpl<$Res, $Val extends DirectMessage>
    implements $DirectMessageCopyWith<$Res> {
  _$DirectMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUser = null,
    Object? toUser = null,
    Object? content = null,
    Object? replyToId = freezed,
    Object? imageUrl = freezed,
    Object? audioUrl = freezed,
    Object? audioDurationMs = freezed,
    Object? readAt = freezed,
    Object? editedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fromUser: null == fromUser
          ? _value.fromUser
          : fromUser // ignore: cast_nullable_to_non_nullable
              as String,
      toUser: null == toUser
          ? _value.toUser
          : toUser // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      replyToId: freezed == replyToId
          ? _value.replyToId
          : replyToId // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioDurationMs: freezed == audioDurationMs
          ? _value.audioDurationMs
          : audioDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      editedAt: freezed == editedAt
          ? _value.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DirectMessageImplCopyWith<$Res>
    implements $DirectMessageCopyWith<$Res> {
  factory _$$DirectMessageImplCopyWith(
          _$DirectMessageImpl value, $Res Function(_$DirectMessageImpl) then) =
      __$$DirectMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String fromUser,
      String toUser,
      String content,
      String? replyToId,
      String? imageUrl,
      String? audioUrl,
      int? audioDurationMs,
      DateTime? readAt,
      DateTime? editedAt,
      DateTime? createdAt});
}

/// @nodoc
class __$$DirectMessageImplCopyWithImpl<$Res>
    extends _$DirectMessageCopyWithImpl<$Res, _$DirectMessageImpl>
    implements _$$DirectMessageImplCopyWith<$Res> {
  __$$DirectMessageImplCopyWithImpl(
      _$DirectMessageImpl _value, $Res Function(_$DirectMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUser = null,
    Object? toUser = null,
    Object? content = null,
    Object? replyToId = freezed,
    Object? imageUrl = freezed,
    Object? audioUrl = freezed,
    Object? audioDurationMs = freezed,
    Object? readAt = freezed,
    Object? editedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$DirectMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fromUser: null == fromUser
          ? _value.fromUser
          : fromUser // ignore: cast_nullable_to_non_nullable
              as String,
      toUser: null == toUser
          ? _value.toUser
          : toUser // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      replyToId: freezed == replyToId
          ? _value.replyToId
          : replyToId // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioDurationMs: freezed == audioDurationMs
          ? _value.audioDurationMs
          : audioDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      editedAt: freezed == editedAt
          ? _value.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DirectMessageImpl implements _DirectMessage {
  const _$DirectMessageImpl(
      {required this.id,
      required this.fromUser,
      required this.toUser,
      required this.content,
      this.replyToId,
      this.imageUrl,
      this.audioUrl,
      this.audioDurationMs,
      this.readAt,
      this.editedAt,
      this.createdAt});

  factory _$DirectMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$DirectMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String fromUser;
  @override
  final String toUser;
  @override
  final String content;
  @override
  final String? replyToId;
  @override
  final String? imageUrl;
  @override
  final String? audioUrl;
  @override
  final int? audioDurationMs;
  @override
  final DateTime? readAt;
  @override
  final DateTime? editedAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'DirectMessage(id: $id, fromUser: $fromUser, toUser: $toUser, content: $content, replyToId: $replyToId, imageUrl: $imageUrl, audioUrl: $audioUrl, audioDurationMs: $audioDurationMs, readAt: $readAt, editedAt: $editedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DirectMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromUser, fromUser) ||
                other.fromUser == fromUser) &&
            (identical(other.toUser, toUser) || other.toUser == toUser) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.replyToId, replyToId) ||
                other.replyToId == replyToId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.audioDurationMs, audioDurationMs) ||
                other.audioDurationMs == audioDurationMs) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      fromUser,
      toUser,
      content,
      replyToId,
      imageUrl,
      audioUrl,
      audioDurationMs,
      readAt,
      editedAt,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DirectMessageImplCopyWith<_$DirectMessageImpl> get copyWith =>
      __$$DirectMessageImplCopyWithImpl<_$DirectMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DirectMessageImplToJson(
      this,
    );
  }
}

abstract class _DirectMessage implements DirectMessage {
  const factory _DirectMessage(
      {required final String id,
      required final String fromUser,
      required final String toUser,
      required final String content,
      final String? replyToId,
      final String? imageUrl,
      final String? audioUrl,
      final int? audioDurationMs,
      final DateTime? readAt,
      final DateTime? editedAt,
      final DateTime? createdAt}) = _$DirectMessageImpl;

  factory _DirectMessage.fromJson(Map<String, dynamic> json) =
      _$DirectMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get fromUser;
  @override
  String get toUser;
  @override
  String get content;
  @override
  String? get replyToId;
  @override
  String? get imageUrl;
  @override
  String? get audioUrl;
  @override
  int? get audioDurationMs;
  @override
  DateTime? get readAt;
  @override
  DateTime? get editedAt;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$DirectMessageImplCopyWith<_$DirectMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DmReaction _$DmReactionFromJson(Map<String, dynamic> json) {
  return _DmReaction.fromJson(json);
}

/// @nodoc
mixin _$DmReaction {
  String get id => throw _privateConstructorUsedError;
  String get messageId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get emoji => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DmReactionCopyWith<DmReaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DmReactionCopyWith<$Res> {
  factory $DmReactionCopyWith(
          DmReaction value, $Res Function(DmReaction) then) =
      _$DmReactionCopyWithImpl<$Res, DmReaction>;
  @useResult
  $Res call(
      {String id,
      String messageId,
      String userId,
      String emoji,
      DateTime? createdAt});
}

/// @nodoc
class _$DmReactionCopyWithImpl<$Res, $Val extends DmReaction>
    implements $DmReactionCopyWith<$Res> {
  _$DmReactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? userId = null,
    Object? emoji = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DmReactionImplCopyWith<$Res>
    implements $DmReactionCopyWith<$Res> {
  factory _$$DmReactionImplCopyWith(
          _$DmReactionImpl value, $Res Function(_$DmReactionImpl) then) =
      __$$DmReactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String messageId,
      String userId,
      String emoji,
      DateTime? createdAt});
}

/// @nodoc
class __$$DmReactionImplCopyWithImpl<$Res>
    extends _$DmReactionCopyWithImpl<$Res, _$DmReactionImpl>
    implements _$$DmReactionImplCopyWith<$Res> {
  __$$DmReactionImplCopyWithImpl(
      _$DmReactionImpl _value, $Res Function(_$DmReactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? userId = null,
    Object? emoji = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$DmReactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DmReactionImpl implements _DmReaction {
  const _$DmReactionImpl(
      {required this.id,
      required this.messageId,
      required this.userId,
      required this.emoji,
      this.createdAt});

  factory _$DmReactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DmReactionImplFromJson(json);

  @override
  final String id;
  @override
  final String messageId;
  @override
  final String userId;
  @override
  final String emoji;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'DmReaction(id: $id, messageId: $messageId, userId: $userId, emoji: $emoji, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DmReactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, messageId, userId, emoji, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DmReactionImplCopyWith<_$DmReactionImpl> get copyWith =>
      __$$DmReactionImplCopyWithImpl<_$DmReactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DmReactionImplToJson(
      this,
    );
  }
}

abstract class _DmReaction implements DmReaction {
  const factory _DmReaction(
      {required final String id,
      required final String messageId,
      required final String userId,
      required final String emoji,
      final DateTime? createdAt}) = _$DmReactionImpl;

  factory _DmReaction.fromJson(Map<String, dynamic> json) =
      _$DmReactionImpl.fromJson;

  @override
  String get id;
  @override
  String get messageId;
  @override
  String get userId;
  @override
  String get emoji;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$DmReactionImplCopyWith<_$DmReactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScoutMessage _$ScoutMessageFromJson(Map<String, dynamic> json) {
  return _ScoutMessage.fromJson(json);
}

/// @nodoc
mixin _$ScoutMessage {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError; // 'user' | 'assistant'
  String get content => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScoutMessageCopyWith<ScoutMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScoutMessageCopyWith<$Res> {
  factory $ScoutMessageCopyWith(
          ScoutMessage value, $Res Function(ScoutMessage) then) =
      _$ScoutMessageCopyWithImpl<$Res, ScoutMessage>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String role,
      String content,
      String? imageUrl,
      DateTime? createdAt});
}

/// @nodoc
class _$ScoutMessageCopyWithImpl<$Res, $Val extends ScoutMessage>
    implements $ScoutMessageCopyWith<$Res> {
  _$ScoutMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? role = null,
    Object? content = null,
    Object? imageUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScoutMessageImplCopyWith<$Res>
    implements $ScoutMessageCopyWith<$Res> {
  factory _$$ScoutMessageImplCopyWith(
          _$ScoutMessageImpl value, $Res Function(_$ScoutMessageImpl) then) =
      __$$ScoutMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String role,
      String content,
      String? imageUrl,
      DateTime? createdAt});
}

/// @nodoc
class __$$ScoutMessageImplCopyWithImpl<$Res>
    extends _$ScoutMessageCopyWithImpl<$Res, _$ScoutMessageImpl>
    implements _$$ScoutMessageImplCopyWith<$Res> {
  __$$ScoutMessageImplCopyWithImpl(
      _$ScoutMessageImpl _value, $Res Function(_$ScoutMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? role = null,
    Object? content = null,
    Object? imageUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ScoutMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScoutMessageImpl implements _ScoutMessage {
  const _$ScoutMessageImpl(
      {required this.id,
      required this.userId,
      required this.role,
      required this.content,
      this.imageUrl,
      this.createdAt});

  factory _$ScoutMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScoutMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String role;
// 'user' | 'assistant'
  @override
  final String content;
  @override
  final String? imageUrl;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ScoutMessage(id: $id, userId: $userId, role: $role, content: $content, imageUrl: $imageUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScoutMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, userId, role, content, imageUrl, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScoutMessageImplCopyWith<_$ScoutMessageImpl> get copyWith =>
      __$$ScoutMessageImplCopyWithImpl<_$ScoutMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScoutMessageImplToJson(
      this,
    );
  }
}

abstract class _ScoutMessage implements ScoutMessage {
  const factory _ScoutMessage(
      {required final String id,
      required final String userId,
      required final String role,
      required final String content,
      final String? imageUrl,
      final DateTime? createdAt}) = _$ScoutMessageImpl;

  factory _ScoutMessage.fromJson(Map<String, dynamic> json) =
      _$ScoutMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get role;
  @override // 'user' | 'assistant'
  String get content;
  @override
  String? get imageUrl;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ScoutMessageImplCopyWith<_$ScoutMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItineraryActivity _$ItineraryActivityFromJson(Map<String, dynamic> json) {
  return _ItineraryActivity.fromJson(json);
}

/// @nodoc
mixin _$ItineraryActivity {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  int get dayNumber => throw _privateConstructorUsedError;
  String get timeOfDay => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  double? get lat => throw _privateConstructorUsedError;
  double? get lng => throw _privateConstructorUsedError;
  int? get estimatedCostCents => throw _privateConstructorUsedError;
  String? get bookingUrl => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  DateTime? get bookedAt => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // proposed | approved | rejected
  String? get proposedBy => throw _privateConstructorUsedError;
  String? get rejectedReason => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;
  String? get reviewedBy => throw _privateConstructorUsedError;
  String get itemType =>
      throw _privateConstructorUsedError; // activity | hotel | restaurant
  DateTime? get checkedOffAt => throw _privateConstructorUsedError;
  String? get checkedOffBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItineraryActivityCopyWith<ItineraryActivity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryActivityCopyWith<$Res> {
  factory $ItineraryActivityCopyWith(
          ItineraryActivity value, $Res Function(ItineraryActivity) then) =
      _$ItineraryActivityCopyWithImpl<$Res, ItineraryActivity>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      int dayNumber,
      String timeOfDay,
      String title,
      String? description,
      String? location,
      double? lat,
      double? lng,
      int? estimatedCostCents,
      String? bookingUrl,
      String? imageUrl,
      int orderIndex,
      String? createdBy,
      DateTime? bookedAt,
      String status,
      String? proposedBy,
      String? rejectedReason,
      DateTime? reviewedAt,
      String? reviewedBy,
      String itemType,
      DateTime? checkedOffAt,
      String? checkedOffBy,
      DateTime? createdAt});
}

/// @nodoc
class _$ItineraryActivityCopyWithImpl<$Res, $Val extends ItineraryActivity>
    implements $ItineraryActivityCopyWith<$Res> {
  _$ItineraryActivityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? dayNumber = null,
    Object? timeOfDay = null,
    Object? title = null,
    Object? description = freezed,
    Object? location = freezed,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? estimatedCostCents = freezed,
    Object? bookingUrl = freezed,
    Object? imageUrl = freezed,
    Object? orderIndex = null,
    Object? createdBy = freezed,
    Object? bookedAt = freezed,
    Object? status = null,
    Object? proposedBy = freezed,
    Object? rejectedReason = freezed,
    Object? reviewedAt = freezed,
    Object? reviewedBy = freezed,
    Object? itemType = null,
    Object? checkedOffAt = freezed,
    Object? checkedOffBy = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      timeOfDay: null == timeOfDay
          ? _value.timeOfDay
          : timeOfDay // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      lat: freezed == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double?,
      lng: freezed == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double?,
      estimatedCostCents: freezed == estimatedCostCents
          ? _value.estimatedCostCents
          : estimatedCostCents // ignore: cast_nullable_to_non_nullable
              as int?,
      bookingUrl: freezed == bookingUrl
          ? _value.bookingUrl
          : bookingUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      bookedAt: freezed == bookedAt
          ? _value.bookedAt
          : bookedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      proposedBy: freezed == proposedBy
          ? _value.proposedBy
          : proposedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectedReason: freezed == rejectedReason
          ? _value.rejectedReason
          : rejectedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewedAt: freezed == reviewedAt
          ? _value.reviewedAt
          : reviewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reviewedBy: freezed == reviewedBy
          ? _value.reviewedBy
          : reviewedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      checkedOffAt: freezed == checkedOffAt
          ? _value.checkedOffAt
          : checkedOffAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkedOffBy: freezed == checkedOffBy
          ? _value.checkedOffBy
          : checkedOffBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryActivityImplCopyWith<$Res>
    implements $ItineraryActivityCopyWith<$Res> {
  factory _$$ItineraryActivityImplCopyWith(_$ItineraryActivityImpl value,
          $Res Function(_$ItineraryActivityImpl) then) =
      __$$ItineraryActivityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      int dayNumber,
      String timeOfDay,
      String title,
      String? description,
      String? location,
      double? lat,
      double? lng,
      int? estimatedCostCents,
      String? bookingUrl,
      String? imageUrl,
      int orderIndex,
      String? createdBy,
      DateTime? bookedAt,
      String status,
      String? proposedBy,
      String? rejectedReason,
      DateTime? reviewedAt,
      String? reviewedBy,
      String itemType,
      DateTime? checkedOffAt,
      String? checkedOffBy,
      DateTime? createdAt});
}

/// @nodoc
class __$$ItineraryActivityImplCopyWithImpl<$Res>
    extends _$ItineraryActivityCopyWithImpl<$Res, _$ItineraryActivityImpl>
    implements _$$ItineraryActivityImplCopyWith<$Res> {
  __$$ItineraryActivityImplCopyWithImpl(_$ItineraryActivityImpl _value,
      $Res Function(_$ItineraryActivityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? dayNumber = null,
    Object? timeOfDay = null,
    Object? title = null,
    Object? description = freezed,
    Object? location = freezed,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? estimatedCostCents = freezed,
    Object? bookingUrl = freezed,
    Object? imageUrl = freezed,
    Object? orderIndex = null,
    Object? createdBy = freezed,
    Object? bookedAt = freezed,
    Object? status = null,
    Object? proposedBy = freezed,
    Object? rejectedReason = freezed,
    Object? reviewedAt = freezed,
    Object? reviewedBy = freezed,
    Object? itemType = null,
    Object? checkedOffAt = freezed,
    Object? checkedOffBy = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ItineraryActivityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      timeOfDay: null == timeOfDay
          ? _value.timeOfDay
          : timeOfDay // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      lat: freezed == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double?,
      lng: freezed == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double?,
      estimatedCostCents: freezed == estimatedCostCents
          ? _value.estimatedCostCents
          : estimatedCostCents // ignore: cast_nullable_to_non_nullable
              as int?,
      bookingUrl: freezed == bookingUrl
          ? _value.bookingUrl
          : bookingUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      bookedAt: freezed == bookedAt
          ? _value.bookedAt
          : bookedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      proposedBy: freezed == proposedBy
          ? _value.proposedBy
          : proposedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectedReason: freezed == rejectedReason
          ? _value.rejectedReason
          : rejectedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewedAt: freezed == reviewedAt
          ? _value.reviewedAt
          : reviewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reviewedBy: freezed == reviewedBy
          ? _value.reviewedBy
          : reviewedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      checkedOffAt: freezed == checkedOffAt
          ? _value.checkedOffAt
          : checkedOffAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkedOffBy: freezed == checkedOffBy
          ? _value.checkedOffBy
          : checkedOffBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryActivityImpl implements _ItineraryActivity {
  const _$ItineraryActivityImpl(
      {required this.id,
      required this.tripId,
      required this.dayNumber,
      this.timeOfDay = 'morning',
      required this.title,
      this.description,
      this.location,
      this.lat,
      this.lng,
      this.estimatedCostCents,
      this.bookingUrl,
      this.imageUrl,
      this.orderIndex = 0,
      this.createdBy,
      this.bookedAt,
      this.status = 'approved',
      this.proposedBy,
      this.rejectedReason,
      this.reviewedAt,
      this.reviewedBy,
      this.itemType = 'activity',
      this.checkedOffAt,
      this.checkedOffBy,
      this.createdAt});

  factory _$ItineraryActivityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryActivityImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final int dayNumber;
  @override
  @JsonKey()
  final String timeOfDay;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? location;
  @override
  final double? lat;
  @override
  final double? lng;
  @override
  final int? estimatedCostCents;
  @override
  final String? bookingUrl;
  @override
  final String? imageUrl;
  @override
  @JsonKey()
  final int orderIndex;
  @override
  final String? createdBy;
  @override
  final DateTime? bookedAt;
  @override
  @JsonKey()
  final String status;
// proposed | approved | rejected
  @override
  final String? proposedBy;
  @override
  final String? rejectedReason;
  @override
  final DateTime? reviewedAt;
  @override
  final String? reviewedBy;
  @override
  @JsonKey()
  final String itemType;
// activity | hotel | restaurant
  @override
  final DateTime? checkedOffAt;
  @override
  final String? checkedOffBy;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ItineraryActivity(id: $id, tripId: $tripId, dayNumber: $dayNumber, timeOfDay: $timeOfDay, title: $title, description: $description, location: $location, lat: $lat, lng: $lng, estimatedCostCents: $estimatedCostCents, bookingUrl: $bookingUrl, imageUrl: $imageUrl, orderIndex: $orderIndex, createdBy: $createdBy, bookedAt: $bookedAt, status: $status, proposedBy: $proposedBy, rejectedReason: $rejectedReason, reviewedAt: $reviewedAt, reviewedBy: $reviewedBy, itemType: $itemType, checkedOffAt: $checkedOffAt, checkedOffBy: $checkedOffBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryActivityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            (identical(other.timeOfDay, timeOfDay) ||
                other.timeOfDay == timeOfDay) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.estimatedCostCents, estimatedCostCents) ||
                other.estimatedCostCents == estimatedCostCents) &&
            (identical(other.bookingUrl, bookingUrl) ||
                other.bookingUrl == bookingUrl) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.bookedAt, bookedAt) ||
                other.bookedAt == bookedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.proposedBy, proposedBy) ||
                other.proposedBy == proposedBy) &&
            (identical(other.rejectedReason, rejectedReason) ||
                other.rejectedReason == rejectedReason) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.reviewedBy, reviewedBy) ||
                other.reviewedBy == reviewedBy) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.checkedOffAt, checkedOffAt) ||
                other.checkedOffAt == checkedOffAt) &&
            (identical(other.checkedOffBy, checkedOffBy) ||
                other.checkedOffBy == checkedOffBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        tripId,
        dayNumber,
        timeOfDay,
        title,
        description,
        location,
        lat,
        lng,
        estimatedCostCents,
        bookingUrl,
        imageUrl,
        orderIndex,
        createdBy,
        bookedAt,
        status,
        proposedBy,
        rejectedReason,
        reviewedAt,
        reviewedBy,
        itemType,
        checkedOffAt,
        checkedOffBy,
        createdAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryActivityImplCopyWith<_$ItineraryActivityImpl> get copyWith =>
      __$$ItineraryActivityImplCopyWithImpl<_$ItineraryActivityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryActivityImplToJson(
      this,
    );
  }
}

abstract class _ItineraryActivity implements ItineraryActivity {
  const factory _ItineraryActivity(
      {required final String id,
      required final String tripId,
      required final int dayNumber,
      final String timeOfDay,
      required final String title,
      final String? description,
      final String? location,
      final double? lat,
      final double? lng,
      final int? estimatedCostCents,
      final String? bookingUrl,
      final String? imageUrl,
      final int orderIndex,
      final String? createdBy,
      final DateTime? bookedAt,
      final String status,
      final String? proposedBy,
      final String? rejectedReason,
      final DateTime? reviewedAt,
      final String? reviewedBy,
      final String itemType,
      final DateTime? checkedOffAt,
      final String? checkedOffBy,
      final DateTime? createdAt}) = _$ItineraryActivityImpl;

  factory _ItineraryActivity.fromJson(Map<String, dynamic> json) =
      _$ItineraryActivityImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  int get dayNumber;
  @override
  String get timeOfDay;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get location;
  @override
  double? get lat;
  @override
  double? get lng;
  @override
  int? get estimatedCostCents;
  @override
  String? get bookingUrl;
  @override
  String? get imageUrl;
  @override
  int get orderIndex;
  @override
  String? get createdBy;
  @override
  DateTime? get bookedAt;
  @override
  String get status;
  @override // proposed | approved | rejected
  String? get proposedBy;
  @override
  String? get rejectedReason;
  @override
  DateTime? get reviewedAt;
  @override
  String? get reviewedBy;
  @override
  String get itemType;
  @override // activity | hotel | restaurant
  DateTime? get checkedOffAt;
  @override
  String? get checkedOffBy;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ItineraryActivityImplCopyWith<_$ItineraryActivityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItineraryNote _$ItineraryNoteFromJson(Map<String, dynamic> json) {
  return _ItineraryNote.fromJson(json);
}

/// @nodoc
mixin _$ItineraryNote {
  String get id => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItineraryNoteCopyWith<ItineraryNote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryNoteCopyWith<$Res> {
  factory $ItineraryNoteCopyWith(
          ItineraryNote value, $Res Function(ItineraryNote) then) =
      _$ItineraryNoteCopyWithImpl<$Res, ItineraryNote>;
  @useResult
  $Res call(
      {String id,
      String itemId,
      String userId,
      String content,
      DateTime? createdAt});
}

/// @nodoc
class _$ItineraryNoteCopyWithImpl<$Res, $Val extends ItineraryNote>
    implements $ItineraryNoteCopyWith<$Res> {
  _$ItineraryNoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? userId = null,
    Object? content = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryNoteImplCopyWith<$Res>
    implements $ItineraryNoteCopyWith<$Res> {
  factory _$$ItineraryNoteImplCopyWith(
          _$ItineraryNoteImpl value, $Res Function(_$ItineraryNoteImpl) then) =
      __$$ItineraryNoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String itemId,
      String userId,
      String content,
      DateTime? createdAt});
}

/// @nodoc
class __$$ItineraryNoteImplCopyWithImpl<$Res>
    extends _$ItineraryNoteCopyWithImpl<$Res, _$ItineraryNoteImpl>
    implements _$$ItineraryNoteImplCopyWith<$Res> {
  __$$ItineraryNoteImplCopyWithImpl(
      _$ItineraryNoteImpl _value, $Res Function(_$ItineraryNoteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? userId = null,
    Object? content = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$ItineraryNoteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryNoteImpl implements _ItineraryNote {
  const _$ItineraryNoteImpl(
      {required this.id,
      required this.itemId,
      required this.userId,
      required this.content,
      this.createdAt});

  factory _$ItineraryNoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryNoteImplFromJson(json);

  @override
  final String id;
  @override
  final String itemId;
  @override
  final String userId;
  @override
  final String content;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ItineraryNote(id: $id, itemId: $itemId, userId: $userId, content: $content, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryNoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, itemId, userId, content, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryNoteImplCopyWith<_$ItineraryNoteImpl> get copyWith =>
      __$$ItineraryNoteImplCopyWithImpl<_$ItineraryNoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryNoteImplToJson(
      this,
    );
  }
}

abstract class _ItineraryNote implements ItineraryNote {
  const factory _ItineraryNote(
      {required final String id,
      required final String itemId,
      required final String userId,
      required final String content,
      final DateTime? createdAt}) = _$ItineraryNoteImpl;

  factory _ItineraryNote.fromJson(Map<String, dynamic> json) =
      _$ItineraryNoteImpl.fromJson;

  @override
  String get id;
  @override
  String get itemId;
  @override
  String get userId;
  @override
  String get content;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ItineraryNoteImplCopyWith<_$ItineraryNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;
  String get nickname => throw _privateConstructorUsedError;
  String get emoji => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  bool get isAi => throw _privateConstructorUsedError;
  String? get replyToId => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get audioUrl => throw _privateConstructorUsedError;
  int? get audioDurationMs => throw _privateConstructorUsedError;
  List<String> get seenBy => throw _privateConstructorUsedError;
  List<String> get mentions => throw _privateConstructorUsedError;
  DateTime? get pinnedAt => throw _privateConstructorUsedError;
  DateTime? get editedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? userId,
      String nickname,
      String emoji,
      String content,
      bool isAi,
      String? replyToId,
      String? imageUrl,
      String? audioUrl,
      int? audioDurationMs,
      List<String> seenBy,
      List<String> mentions,
      DateTime? pinnedAt,
      DateTime? editedAt,
      DateTime? createdAt});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = freezed,
    Object? nickname = null,
    Object? emoji = null,
    Object? content = null,
    Object? isAi = null,
    Object? replyToId = freezed,
    Object? imageUrl = freezed,
    Object? audioUrl = freezed,
    Object? audioDurationMs = freezed,
    Object? seenBy = null,
    Object? mentions = null,
    Object? pinnedAt = freezed,
    Object? editedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      isAi: null == isAi
          ? _value.isAi
          : isAi // ignore: cast_nullable_to_non_nullable
              as bool,
      replyToId: freezed == replyToId
          ? _value.replyToId
          : replyToId // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioDurationMs: freezed == audioDurationMs
          ? _value.audioDurationMs
          : audioDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      seenBy: null == seenBy
          ? _value.seenBy
          : seenBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mentions: null == mentions
          ? _value.mentions
          : mentions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      pinnedAt: freezed == pinnedAt
          ? _value.pinnedAt
          : pinnedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      editedAt: freezed == editedAt
          ? _value.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String? userId,
      String nickname,
      String emoji,
      String content,
      bool isAi,
      String? replyToId,
      String? imageUrl,
      String? audioUrl,
      int? audioDurationMs,
      List<String> seenBy,
      List<String> mentions,
      DateTime? pinnedAt,
      DateTime? editedAt,
      DateTime? createdAt});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = freezed,
    Object? nickname = null,
    Object? emoji = null,
    Object? content = null,
    Object? isAi = null,
    Object? replyToId = freezed,
    Object? imageUrl = freezed,
    Object? audioUrl = freezed,
    Object? audioDurationMs = freezed,
    Object? seenBy = null,
    Object? mentions = null,
    Object? pinnedAt = freezed,
    Object? editedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      isAi: null == isAi
          ? _value.isAi
          : isAi // ignore: cast_nullable_to_non_nullable
              as bool,
      replyToId: freezed == replyToId
          ? _value.replyToId
          : replyToId // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioDurationMs: freezed == audioDurationMs
          ? _value.audioDurationMs
          : audioDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      seenBy: null == seenBy
          ? _value._seenBy
          : seenBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mentions: null == mentions
          ? _value._mentions
          : mentions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      pinnedAt: freezed == pinnedAt
          ? _value.pinnedAt
          : pinnedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      editedAt: freezed == editedAt
          ? _value.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl(
      {required this.id,
      required this.tripId,
      this.userId,
      required this.nickname,
      this.emoji = '😎',
      required this.content,
      this.isAi = false,
      this.replyToId,
      this.imageUrl,
      this.audioUrl,
      this.audioDurationMs,
      final List<String> seenBy = const [],
      final List<String> mentions = const [],
      this.pinnedAt,
      this.editedAt,
      this.createdAt})
      : _seenBy = seenBy,
        _mentions = mentions;

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String? userId;
  @override
  final String nickname;
  @override
  @JsonKey()
  final String emoji;
  @override
  final String content;
  @override
  @JsonKey()
  final bool isAi;
  @override
  final String? replyToId;
  @override
  final String? imageUrl;
  @override
  final String? audioUrl;
  @override
  final int? audioDurationMs;
  final List<String> _seenBy;
  @override
  @JsonKey()
  List<String> get seenBy {
    if (_seenBy is EqualUnmodifiableListView) return _seenBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_seenBy);
  }

  final List<String> _mentions;
  @override
  @JsonKey()
  List<String> get mentions {
    if (_mentions is EqualUnmodifiableListView) return _mentions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mentions);
  }

  @override
  final DateTime? pinnedAt;
  @override
  final DateTime? editedAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ChatMessage(id: $id, tripId: $tripId, userId: $userId, nickname: $nickname, emoji: $emoji, content: $content, isAi: $isAi, replyToId: $replyToId, imageUrl: $imageUrl, audioUrl: $audioUrl, audioDurationMs: $audioDurationMs, seenBy: $seenBy, mentions: $mentions, pinnedAt: $pinnedAt, editedAt: $editedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.isAi, isAi) || other.isAi == isAi) &&
            (identical(other.replyToId, replyToId) ||
                other.replyToId == replyToId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.audioDurationMs, audioDurationMs) ||
                other.audioDurationMs == audioDurationMs) &&
            const DeepCollectionEquality().equals(other._seenBy, _seenBy) &&
            const DeepCollectionEquality().equals(other._mentions, _mentions) &&
            (identical(other.pinnedAt, pinnedAt) ||
                other.pinnedAt == pinnedAt) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      userId,
      nickname,
      emoji,
      content,
      isAi,
      replyToId,
      imageUrl,
      audioUrl,
      audioDurationMs,
      const DeepCollectionEquality().hash(_seenBy),
      const DeepCollectionEquality().hash(_mentions),
      pinnedAt,
      editedAt,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String tripId,
      final String? userId,
      required final String nickname,
      final String emoji,
      required final String content,
      final bool isAi,
      final String? replyToId,
      final String? imageUrl,
      final String? audioUrl,
      final int? audioDurationMs,
      final List<String> seenBy,
      final List<String> mentions,
      final DateTime? pinnedAt,
      final DateTime? editedAt,
      final DateTime? createdAt}) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String? get userId;
  @override
  String get nickname;
  @override
  String get emoji;
  @override
  String get content;
  @override
  bool get isAi;
  @override
  String? get replyToId;
  @override
  String? get imageUrl;
  @override
  String? get audioUrl;
  @override
  int? get audioDurationMs;
  @override
  List<String> get seenBy;
  @override
  List<String> get mentions;
  @override
  DateTime? get pinnedAt;
  @override
  DateTime? get editedAt;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatReaction _$ChatReactionFromJson(Map<String, dynamic> json) {
  return _ChatReaction.fromJson(json);
}

/// @nodoc
mixin _$ChatReaction {
  String get id => throw _privateConstructorUsedError;
  String get messageId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get emoji => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatReactionCopyWith<ChatReaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatReactionCopyWith<$Res> {
  factory $ChatReactionCopyWith(
          ChatReaction value, $Res Function(ChatReaction) then) =
      _$ChatReactionCopyWithImpl<$Res, ChatReaction>;
  @useResult
  $Res call(
      {String id,
      String messageId,
      String userId,
      String emoji,
      DateTime? createdAt});
}

/// @nodoc
class _$ChatReactionCopyWithImpl<$Res, $Val extends ChatReaction>
    implements $ChatReactionCopyWith<$Res> {
  _$ChatReactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? userId = null,
    Object? emoji = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatReactionImplCopyWith<$Res>
    implements $ChatReactionCopyWith<$Res> {
  factory _$$ChatReactionImplCopyWith(
          _$ChatReactionImpl value, $Res Function(_$ChatReactionImpl) then) =
      __$$ChatReactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String messageId,
      String userId,
      String emoji,
      DateTime? createdAt});
}

/// @nodoc
class __$$ChatReactionImplCopyWithImpl<$Res>
    extends _$ChatReactionCopyWithImpl<$Res, _$ChatReactionImpl>
    implements _$$ChatReactionImplCopyWith<$Res> {
  __$$ChatReactionImplCopyWithImpl(
      _$ChatReactionImpl _value, $Res Function(_$ChatReactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? userId = null,
    Object? emoji = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$ChatReactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatReactionImpl implements _ChatReaction {
  const _$ChatReactionImpl(
      {required this.id,
      required this.messageId,
      required this.userId,
      required this.emoji,
      this.createdAt});

  factory _$ChatReactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatReactionImplFromJson(json);

  @override
  final String id;
  @override
  final String messageId;
  @override
  final String userId;
  @override
  final String emoji;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ChatReaction(id: $id, messageId: $messageId, userId: $userId, emoji: $emoji, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatReactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, messageId, userId, emoji, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatReactionImplCopyWith<_$ChatReactionImpl> get copyWith =>
      __$$ChatReactionImplCopyWithImpl<_$ChatReactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatReactionImplToJson(
      this,
    );
  }
}

abstract class _ChatReaction implements ChatReaction {
  const factory _ChatReaction(
      {required final String id,
      required final String messageId,
      required final String userId,
      required final String emoji,
      final DateTime? createdAt}) = _$ChatReactionImpl;

  factory _ChatReaction.fromJson(Map<String, dynamic> json) =
      _$ChatReactionImpl.fromJson;

  @override
  String get id;
  @override
  String get messageId;
  @override
  String get userId;
  @override
  String get emoji;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ChatReactionImplCopyWith<_$ChatReactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PackingEntry _$PackingEntryFromJson(Map<String, dynamic> json) {
  return _PackingEntry.fromJson(json);
}

/// @nodoc
mixin _$PackingEntry {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String? get emoji => throw _privateConstructorUsedError;
  bool get isShared => throw _privateConstructorUsedError;
  String? get addedBy => throw _privateConstructorUsedError;
  String? get claimedBy => throw _privateConstructorUsedError;
  List<String> get packedBy => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PackingEntryCopyWith<PackingEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PackingEntryCopyWith<$Res> {
  factory $PackingEntryCopyWith(
          PackingEntry value, $Res Function(PackingEntry) then) =
      _$PackingEntryCopyWithImpl<$Res, PackingEntry>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String label,
      String category,
      String? emoji,
      bool isShared,
      String? addedBy,
      String? claimedBy,
      List<String> packedBy,
      int orderIndex,
      DateTime? createdAt});
}

/// @nodoc
class _$PackingEntryCopyWithImpl<$Res, $Val extends PackingEntry>
    implements $PackingEntryCopyWith<$Res> {
  _$PackingEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? label = null,
    Object? category = null,
    Object? emoji = freezed,
    Object? isShared = null,
    Object? addedBy = freezed,
    Object? claimedBy = freezed,
    Object? packedBy = null,
    Object? orderIndex = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: freezed == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String?,
      isShared: null == isShared
          ? _value.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      addedBy: freezed == addedBy
          ? _value.addedBy
          : addedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      claimedBy: freezed == claimedBy
          ? _value.claimedBy
          : claimedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      packedBy: null == packedBy
          ? _value.packedBy
          : packedBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PackingEntryImplCopyWith<$Res>
    implements $PackingEntryCopyWith<$Res> {
  factory _$$PackingEntryImplCopyWith(
          _$PackingEntryImpl value, $Res Function(_$PackingEntryImpl) then) =
      __$$PackingEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String label,
      String category,
      String? emoji,
      bool isShared,
      String? addedBy,
      String? claimedBy,
      List<String> packedBy,
      int orderIndex,
      DateTime? createdAt});
}

/// @nodoc
class __$$PackingEntryImplCopyWithImpl<$Res>
    extends _$PackingEntryCopyWithImpl<$Res, _$PackingEntryImpl>
    implements _$$PackingEntryImplCopyWith<$Res> {
  __$$PackingEntryImplCopyWithImpl(
      _$PackingEntryImpl _value, $Res Function(_$PackingEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? label = null,
    Object? category = null,
    Object? emoji = freezed,
    Object? isShared = null,
    Object? addedBy = freezed,
    Object? claimedBy = freezed,
    Object? packedBy = null,
    Object? orderIndex = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$PackingEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: freezed == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String?,
      isShared: null == isShared
          ? _value.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      addedBy: freezed == addedBy
          ? _value.addedBy
          : addedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      claimedBy: freezed == claimedBy
          ? _value.claimedBy
          : claimedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      packedBy: null == packedBy
          ? _value._packedBy
          : packedBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PackingEntryImpl implements _PackingEntry {
  const _$PackingEntryImpl(
      {required this.id,
      required this.tripId,
      required this.label,
      this.category = 'extras',
      this.emoji,
      this.isShared = false,
      this.addedBy,
      this.claimedBy,
      final List<String> packedBy = const [],
      this.orderIndex = 0,
      this.createdAt})
      : _packedBy = packedBy;

  factory _$PackingEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PackingEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String label;
  @override
  @JsonKey()
  final String category;
  @override
  final String? emoji;
  @override
  @JsonKey()
  final bool isShared;
  @override
  final String? addedBy;
  @override
  final String? claimedBy;
  final List<String> _packedBy;
  @override
  @JsonKey()
  List<String> get packedBy {
    if (_packedBy is EqualUnmodifiableListView) return _packedBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_packedBy);
  }

  @override
  @JsonKey()
  final int orderIndex;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'PackingEntry(id: $id, tripId: $tripId, label: $label, category: $category, emoji: $emoji, isShared: $isShared, addedBy: $addedBy, claimedBy: $claimedBy, packedBy: $packedBy, orderIndex: $orderIndex, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.addedBy, addedBy) || other.addedBy == addedBy) &&
            (identical(other.claimedBy, claimedBy) ||
                other.claimedBy == claimedBy) &&
            const DeepCollectionEquality().equals(other._packedBy, _packedBy) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      label,
      category,
      emoji,
      isShared,
      addedBy,
      claimedBy,
      const DeepCollectionEquality().hash(_packedBy),
      orderIndex,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingEntryImplCopyWith<_$PackingEntryImpl> get copyWith =>
      __$$PackingEntryImplCopyWithImpl<_$PackingEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PackingEntryImplToJson(
      this,
    );
  }
}

abstract class _PackingEntry implements PackingEntry {
  const factory _PackingEntry(
      {required final String id,
      required final String tripId,
      required final String label,
      final String category,
      final String? emoji,
      final bool isShared,
      final String? addedBy,
      final String? claimedBy,
      final List<String> packedBy,
      final int orderIndex,
      final DateTime? createdAt}) = _$PackingEntryImpl;

  factory _PackingEntry.fromJson(Map<String, dynamic> json) =
      _$PackingEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String get label;
  @override
  String get category;
  @override
  String? get emoji;
  @override
  bool get isShared;
  @override
  String? get addedBy;
  @override
  String? get claimedBy;
  @override
  List<String> get packedBy;
  @override
  int get orderIndex;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$PackingEntryImplCopyWith<_$PackingEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Kudos _$KudosFromJson(Map<String, dynamic> json) {
  return _Kudos.fromJson(json);
}

/// @nodoc
mixin _$Kudos {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String get fromUser => throw _privateConstructorUsedError;
  String get toUser => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $KudosCopyWith<Kudos> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KudosCopyWith<$Res> {
  factory $KudosCopyWith(Kudos value, $Res Function(Kudos) then) =
      _$KudosCopyWithImpl<$Res, Kudos>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String fromUser,
      String toUser,
      String kind,
      String? note,
      DateTime? createdAt});
}

/// @nodoc
class _$KudosCopyWithImpl<$Res, $Val extends Kudos>
    implements $KudosCopyWith<$Res> {
  _$KudosCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? fromUser = null,
    Object? toUser = null,
    Object? kind = null,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      fromUser: null == fromUser
          ? _value.fromUser
          : fromUser // ignore: cast_nullable_to_non_nullable
              as String,
      toUser: null == toUser
          ? _value.toUser
          : toUser // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$KudosImplCopyWith<$Res> implements $KudosCopyWith<$Res> {
  factory _$$KudosImplCopyWith(
          _$KudosImpl value, $Res Function(_$KudosImpl) then) =
      __$$KudosImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String fromUser,
      String toUser,
      String kind,
      String? note,
      DateTime? createdAt});
}

/// @nodoc
class __$$KudosImplCopyWithImpl<$Res>
    extends _$KudosCopyWithImpl<$Res, _$KudosImpl>
    implements _$$KudosImplCopyWith<$Res> {
  __$$KudosImplCopyWithImpl(
      _$KudosImpl _value, $Res Function(_$KudosImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? fromUser = null,
    Object? toUser = null,
    Object? kind = null,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$KudosImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      fromUser: null == fromUser
          ? _value.fromUser
          : fromUser // ignore: cast_nullable_to_non_nullable
              as String,
      toUser: null == toUser
          ? _value.toUser
          : toUser // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KudosImpl implements _Kudos {
  const _$KudosImpl(
      {required this.id,
      required this.tripId,
      required this.fromUser,
      required this.toUser,
      required this.kind,
      this.note,
      this.createdAt});

  factory _$KudosImpl.fromJson(Map<String, dynamic> json) =>
      _$$KudosImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String fromUser;
  @override
  final String toUser;
  @override
  final String kind;
  @override
  final String? note;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Kudos(id: $id, tripId: $tripId, fromUser: $fromUser, toUser: $toUser, kind: $kind, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KudosImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.fromUser, fromUser) ||
                other.fromUser == fromUser) &&
            (identical(other.toUser, toUser) || other.toUser == toUser) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, tripId, fromUser, toUser, kind, note, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$KudosImplCopyWith<_$KudosImpl> get copyWith =>
      __$$KudosImplCopyWithImpl<_$KudosImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KudosImplToJson(
      this,
    );
  }
}

abstract class _Kudos implements Kudos {
  const factory _Kudos(
      {required final String id,
      required final String tripId,
      required final String fromUser,
      required final String toUser,
      required final String kind,
      final String? note,
      final DateTime? createdAt}) = _$KudosImpl;

  factory _Kudos.fromJson(Map<String, dynamic> json) = _$KudosImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String get fromUser;
  @override
  String get toUser;
  @override
  String get kind;
  @override
  String? get note;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$KudosImplCopyWith<_$KudosImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItineraryRating _$ItineraryRatingFromJson(Map<String, dynamic> json) {
  return _ItineraryRating.fromJson(json);
}

/// @nodoc
mixin _$ItineraryRating {
  String get id => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get thumb => throw _privateConstructorUsedError; // -1 or 1
  String? get note => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItineraryRatingCopyWith<ItineraryRating> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryRatingCopyWith<$Res> {
  factory $ItineraryRatingCopyWith(
          ItineraryRating value, $Res Function(ItineraryRating) then) =
      _$ItineraryRatingCopyWithImpl<$Res, ItineraryRating>;
  @useResult
  $Res call(
      {String id,
      String itemId,
      String userId,
      int thumb,
      String? note,
      DateTime? createdAt});
}

/// @nodoc
class _$ItineraryRatingCopyWithImpl<$Res, $Val extends ItineraryRating>
    implements $ItineraryRatingCopyWith<$Res> {
  _$ItineraryRatingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? userId = null,
    Object? thumb = null,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      thumb: null == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryRatingImplCopyWith<$Res>
    implements $ItineraryRatingCopyWith<$Res> {
  factory _$$ItineraryRatingImplCopyWith(_$ItineraryRatingImpl value,
          $Res Function(_$ItineraryRatingImpl) then) =
      __$$ItineraryRatingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String itemId,
      String userId,
      int thumb,
      String? note,
      DateTime? createdAt});
}

/// @nodoc
class __$$ItineraryRatingImplCopyWithImpl<$Res>
    extends _$ItineraryRatingCopyWithImpl<$Res, _$ItineraryRatingImpl>
    implements _$$ItineraryRatingImplCopyWith<$Res> {
  __$$ItineraryRatingImplCopyWithImpl(
      _$ItineraryRatingImpl _value, $Res Function(_$ItineraryRatingImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? userId = null,
    Object? thumb = null,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ItineraryRatingImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      thumb: null == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryRatingImpl implements _ItineraryRating {
  const _$ItineraryRatingImpl(
      {required this.id,
      required this.itemId,
      required this.userId,
      required this.thumb,
      this.note,
      this.createdAt});

  factory _$ItineraryRatingImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryRatingImplFromJson(json);

  @override
  final String id;
  @override
  final String itemId;
  @override
  final String userId;
  @override
  final int thumb;
// -1 or 1
  @override
  final String? note;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ItineraryRating(id: $id, itemId: $itemId, userId: $userId, thumb: $thumb, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryRatingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, itemId, userId, thumb, note, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryRatingImplCopyWith<_$ItineraryRatingImpl> get copyWith =>
      __$$ItineraryRatingImplCopyWithImpl<_$ItineraryRatingImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryRatingImplToJson(
      this,
    );
  }
}

abstract class _ItineraryRating implements ItineraryRating {
  const factory _ItineraryRating(
      {required final String id,
      required final String itemId,
      required final String userId,
      required final int thumb,
      final String? note,
      final DateTime? createdAt}) = _$ItineraryRatingImpl;

  factory _ItineraryRating.fromJson(Map<String, dynamic> json) =
      _$ItineraryRatingImpl.fromJson;

  @override
  String get id;
  @override
  String get itemId;
  @override
  String get userId;
  @override
  int get thumb;
  @override // -1 or 1
  String? get note;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ItineraryRatingImplCopyWith<_$ItineraryRatingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DestinationRecap _$DestinationRecapFromJson(Map<String, dynamic> json) {
  return _DestinationRecap.fromJson(json);
}

/// @nodoc
mixin _$DestinationRecap {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  int get stars => throw _privateConstructorUsedError;
  String get wouldReturn => throw _privateConstructorUsedError;
  String? get bestPart => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DestinationRecapCopyWith<DestinationRecap> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DestinationRecapCopyWith<$Res> {
  factory $DestinationRecapCopyWith(
          DestinationRecap value, $Res Function(DestinationRecap) then) =
      _$DestinationRecapCopyWithImpl<$Res, DestinationRecap>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String userId,
      String destination,
      int stars,
      String wouldReturn,
      String? bestPart,
      String? photoUrl,
      DateTime? createdAt});
}

/// @nodoc
class _$DestinationRecapCopyWithImpl<$Res, $Val extends DestinationRecap>
    implements $DestinationRecapCopyWith<$Res> {
  _$DestinationRecapCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = null,
    Object? destination = null,
    Object? stars = null,
    Object? wouldReturn = null,
    Object? bestPart = freezed,
    Object? photoUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      stars: null == stars
          ? _value.stars
          : stars // ignore: cast_nullable_to_non_nullable
              as int,
      wouldReturn: null == wouldReturn
          ? _value.wouldReturn
          : wouldReturn // ignore: cast_nullable_to_non_nullable
              as String,
      bestPart: freezed == bestPart
          ? _value.bestPart
          : bestPart // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DestinationRecapImplCopyWith<$Res>
    implements $DestinationRecapCopyWith<$Res> {
  factory _$$DestinationRecapImplCopyWith(_$DestinationRecapImpl value,
          $Res Function(_$DestinationRecapImpl) then) =
      __$$DestinationRecapImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String userId,
      String destination,
      int stars,
      String wouldReturn,
      String? bestPart,
      String? photoUrl,
      DateTime? createdAt});
}

/// @nodoc
class __$$DestinationRecapImplCopyWithImpl<$Res>
    extends _$DestinationRecapCopyWithImpl<$Res, _$DestinationRecapImpl>
    implements _$$DestinationRecapImplCopyWith<$Res> {
  __$$DestinationRecapImplCopyWithImpl(_$DestinationRecapImpl _value,
      $Res Function(_$DestinationRecapImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = null,
    Object? destination = null,
    Object? stars = null,
    Object? wouldReturn = null,
    Object? bestPart = freezed,
    Object? photoUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$DestinationRecapImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      stars: null == stars
          ? _value.stars
          : stars // ignore: cast_nullable_to_non_nullable
              as int,
      wouldReturn: null == wouldReturn
          ? _value.wouldReturn
          : wouldReturn // ignore: cast_nullable_to_non_nullable
              as String,
      bestPart: freezed == bestPart
          ? _value.bestPart
          : bestPart // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DestinationRecapImpl implements _DestinationRecap {
  const _$DestinationRecapImpl(
      {required this.id,
      required this.tripId,
      required this.userId,
      required this.destination,
      required this.stars,
      required this.wouldReturn,
      this.bestPart,
      this.photoUrl,
      this.createdAt});

  factory _$DestinationRecapImpl.fromJson(Map<String, dynamic> json) =>
      _$$DestinationRecapImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String userId;
  @override
  final String destination;
  @override
  final int stars;
  @override
  final String wouldReturn;
  @override
  final String? bestPart;
  @override
  final String? photoUrl;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'DestinationRecap(id: $id, tripId: $tripId, userId: $userId, destination: $destination, stars: $stars, wouldReturn: $wouldReturn, bestPart: $bestPart, photoUrl: $photoUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DestinationRecapImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.stars, stars) || other.stars == stars) &&
            (identical(other.wouldReturn, wouldReturn) ||
                other.wouldReturn == wouldReturn) &&
            (identical(other.bestPart, bestPart) ||
                other.bestPart == bestPart) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, tripId, userId, destination,
      stars, wouldReturn, bestPart, photoUrl, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DestinationRecapImplCopyWith<_$DestinationRecapImpl> get copyWith =>
      __$$DestinationRecapImplCopyWithImpl<_$DestinationRecapImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DestinationRecapImplToJson(
      this,
    );
  }
}

abstract class _DestinationRecap implements DestinationRecap {
  const factory _DestinationRecap(
      {required final String id,
      required final String tripId,
      required final String userId,
      required final String destination,
      required final int stars,
      required final String wouldReturn,
      final String? bestPart,
      final String? photoUrl,
      final DateTime? createdAt}) = _$DestinationRecapImpl;

  factory _DestinationRecap.fromJson(Map<String, dynamic> json) =
      _$DestinationRecapImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String get userId;
  @override
  String get destination;
  @override
  int get stars;
  @override
  String get wouldReturn;
  @override
  String? get bestPart;
  @override
  String? get photoUrl;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$DestinationRecapImplCopyWith<_$DestinationRecapImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Place _$PlaceFromJson(Map<String, dynamic> json) {
  return _Place.fromJson(json);
}

/// @nodoc
mixin _$Place {
  String get id => throw _privateConstructorUsedError;
  String get category =>
      throw _privateConstructorUsedError; // activity | hotel | restaurant
  String get name => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get flag => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  double? get lat => throw _privateConstructorUsedError;
  double? get lng => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get googlePlaceId => throw _privateConstructorUsedError;
  List<String> get aliases => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlaceCopyWith<Place> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaceCopyWith<$Res> {
  factory $PlaceCopyWith(Place value, $Res Function(Place) then) =
      _$PlaceCopyWithImpl<$Res, Place>;
  @useResult
  $Res call(
      {String id,
      String category,
      String name,
      String destination,
      String? country,
      String? flag,
      String? address,
      double? lat,
      double? lng,
      String? photoUrl,
      String? googlePlaceId,
      List<String> aliases,
      DateTime? createdAt});
}

/// @nodoc
class _$PlaceCopyWithImpl<$Res, $Val extends Place>
    implements $PlaceCopyWith<$Res> {
  _$PlaceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? category = null,
    Object? name = null,
    Object? destination = null,
    Object? country = freezed,
    Object? flag = freezed,
    Object? address = freezed,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? photoUrl = freezed,
    Object? googlePlaceId = freezed,
    Object? aliases = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      flag: freezed == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      lat: freezed == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double?,
      lng: freezed == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      googlePlaceId: freezed == googlePlaceId
          ? _value.googlePlaceId
          : googlePlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      aliases: null == aliases
          ? _value.aliases
          : aliases // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlaceImplCopyWith<$Res> implements $PlaceCopyWith<$Res> {
  factory _$$PlaceImplCopyWith(
          _$PlaceImpl value, $Res Function(_$PlaceImpl) then) =
      __$$PlaceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String category,
      String name,
      String destination,
      String? country,
      String? flag,
      String? address,
      double? lat,
      double? lng,
      String? photoUrl,
      String? googlePlaceId,
      List<String> aliases,
      DateTime? createdAt});
}

/// @nodoc
class __$$PlaceImplCopyWithImpl<$Res>
    extends _$PlaceCopyWithImpl<$Res, _$PlaceImpl>
    implements _$$PlaceImplCopyWith<$Res> {
  __$$PlaceImplCopyWithImpl(
      _$PlaceImpl _value, $Res Function(_$PlaceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? category = null,
    Object? name = null,
    Object? destination = null,
    Object? country = freezed,
    Object? flag = freezed,
    Object? address = freezed,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? photoUrl = freezed,
    Object? googlePlaceId = freezed,
    Object? aliases = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$PlaceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      flag: freezed == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      lat: freezed == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double?,
      lng: freezed == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      googlePlaceId: freezed == googlePlaceId
          ? _value.googlePlaceId
          : googlePlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      aliases: null == aliases
          ? _value._aliases
          : aliases // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaceImpl implements _Place {
  const _$PlaceImpl(
      {required this.id,
      required this.category,
      required this.name,
      required this.destination,
      this.country,
      this.flag,
      this.address,
      this.lat,
      this.lng,
      this.photoUrl,
      this.googlePlaceId,
      final List<String> aliases = const [],
      this.createdAt})
      : _aliases = aliases;

  factory _$PlaceImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaceImplFromJson(json);

  @override
  final String id;
  @override
  final String category;
// activity | hotel | restaurant
  @override
  final String name;
  @override
  final String destination;
  @override
  final String? country;
  @override
  final String? flag;
  @override
  final String? address;
  @override
  final double? lat;
  @override
  final double? lng;
  @override
  final String? photoUrl;
  @override
  final String? googlePlaceId;
  final List<String> _aliases;
  @override
  @JsonKey()
  List<String> get aliases {
    if (_aliases is EqualUnmodifiableListView) return _aliases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_aliases);
  }

  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Place(id: $id, category: $category, name: $name, destination: $destination, country: $country, flag: $flag, address: $address, lat: $lat, lng: $lng, photoUrl: $photoUrl, googlePlaceId: $googlePlaceId, aliases: $aliases, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.googlePlaceId, googlePlaceId) ||
                other.googlePlaceId == googlePlaceId) &&
            const DeepCollectionEquality().equals(other._aliases, _aliases) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      category,
      name,
      destination,
      country,
      flag,
      address,
      lat,
      lng,
      photoUrl,
      googlePlaceId,
      const DeepCollectionEquality().hash(_aliases),
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaceImplCopyWith<_$PlaceImpl> get copyWith =>
      __$$PlaceImplCopyWithImpl<_$PlaceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaceImplToJson(
      this,
    );
  }
}

abstract class _Place implements Place {
  const factory _Place(
      {required final String id,
      required final String category,
      required final String name,
      required final String destination,
      final String? country,
      final String? flag,
      final String? address,
      final double? lat,
      final double? lng,
      final String? photoUrl,
      final String? googlePlaceId,
      final List<String> aliases,
      final DateTime? createdAt}) = _$PlaceImpl;

  factory _Place.fromJson(Map<String, dynamic> json) = _$PlaceImpl.fromJson;

  @override
  String get id;
  @override
  String get category;
  @override // activity | hotel | restaurant
  String get name;
  @override
  String get destination;
  @override
  String? get country;
  @override
  String? get flag;
  @override
  String? get address;
  @override
  double? get lat;
  @override
  double? get lng;
  @override
  String? get photoUrl;
  @override
  String? get googlePlaceId;
  @override
  List<String> get aliases;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$PlaceImplCopyWith<_$PlaceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaceStats _$PlaceStatsFromJson(Map<String, dynamic> json) {
  return _PlaceStats.fromJson(json);
}

/// @nodoc
mixin _$PlaceStats {
  String get placeId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get flag => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get displayPhoto => throw _privateConstructorUsedError;
  int get squadsCount => throw _privateConstructorUsedError;
  int get ratingCount => throw _privateConstructorUsedError;
  int get upCount => throw _privateConstructorUsedError;
  int get downCount => throw _privateConstructorUsedError;
  int get approvalPct => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlaceStatsCopyWith<PlaceStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaceStatsCopyWith<$Res> {
  factory $PlaceStatsCopyWith(
          PlaceStats value, $Res Function(PlaceStats) then) =
      _$PlaceStatsCopyWithImpl<$Res, PlaceStats>;
  @useResult
  $Res call(
      {String placeId,
      String name,
      String category,
      String destination,
      String? country,
      String? flag,
      String? photoUrl,
      String? displayPhoto,
      int squadsCount,
      int ratingCount,
      int upCount,
      int downCount,
      int approvalPct});
}

/// @nodoc
class _$PlaceStatsCopyWithImpl<$Res, $Val extends PlaceStats>
    implements $PlaceStatsCopyWith<$Res> {
  _$PlaceStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? placeId = null,
    Object? name = null,
    Object? category = null,
    Object? destination = null,
    Object? country = freezed,
    Object? flag = freezed,
    Object? photoUrl = freezed,
    Object? displayPhoto = freezed,
    Object? squadsCount = null,
    Object? ratingCount = null,
    Object? upCount = null,
    Object? downCount = null,
    Object? approvalPct = null,
  }) {
    return _then(_value.copyWith(
      placeId: null == placeId
          ? _value.placeId
          : placeId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      flag: freezed == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      displayPhoto: freezed == displayPhoto
          ? _value.displayPhoto
          : displayPhoto // ignore: cast_nullable_to_non_nullable
              as String?,
      squadsCount: null == squadsCount
          ? _value.squadsCount
          : squadsCount // ignore: cast_nullable_to_non_nullable
              as int,
      ratingCount: null == ratingCount
          ? _value.ratingCount
          : ratingCount // ignore: cast_nullable_to_non_nullable
              as int,
      upCount: null == upCount
          ? _value.upCount
          : upCount // ignore: cast_nullable_to_non_nullable
              as int,
      downCount: null == downCount
          ? _value.downCount
          : downCount // ignore: cast_nullable_to_non_nullable
              as int,
      approvalPct: null == approvalPct
          ? _value.approvalPct
          : approvalPct // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlaceStatsImplCopyWith<$Res>
    implements $PlaceStatsCopyWith<$Res> {
  factory _$$PlaceStatsImplCopyWith(
          _$PlaceStatsImpl value, $Res Function(_$PlaceStatsImpl) then) =
      __$$PlaceStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String placeId,
      String name,
      String category,
      String destination,
      String? country,
      String? flag,
      String? photoUrl,
      String? displayPhoto,
      int squadsCount,
      int ratingCount,
      int upCount,
      int downCount,
      int approvalPct});
}

/// @nodoc
class __$$PlaceStatsImplCopyWithImpl<$Res>
    extends _$PlaceStatsCopyWithImpl<$Res, _$PlaceStatsImpl>
    implements _$$PlaceStatsImplCopyWith<$Res> {
  __$$PlaceStatsImplCopyWithImpl(
      _$PlaceStatsImpl _value, $Res Function(_$PlaceStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? placeId = null,
    Object? name = null,
    Object? category = null,
    Object? destination = null,
    Object? country = freezed,
    Object? flag = freezed,
    Object? photoUrl = freezed,
    Object? displayPhoto = freezed,
    Object? squadsCount = null,
    Object? ratingCount = null,
    Object? upCount = null,
    Object? downCount = null,
    Object? approvalPct = null,
  }) {
    return _then(_$PlaceStatsImpl(
      placeId: null == placeId
          ? _value.placeId
          : placeId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      flag: freezed == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      displayPhoto: freezed == displayPhoto
          ? _value.displayPhoto
          : displayPhoto // ignore: cast_nullable_to_non_nullable
              as String?,
      squadsCount: null == squadsCount
          ? _value.squadsCount
          : squadsCount // ignore: cast_nullable_to_non_nullable
              as int,
      ratingCount: null == ratingCount
          ? _value.ratingCount
          : ratingCount // ignore: cast_nullable_to_non_nullable
              as int,
      upCount: null == upCount
          ? _value.upCount
          : upCount // ignore: cast_nullable_to_non_nullable
              as int,
      downCount: null == downCount
          ? _value.downCount
          : downCount // ignore: cast_nullable_to_non_nullable
              as int,
      approvalPct: null == approvalPct
          ? _value.approvalPct
          : approvalPct // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaceStatsImpl implements _PlaceStats {
  const _$PlaceStatsImpl(
      {required this.placeId,
      required this.name,
      required this.category,
      required this.destination,
      this.country,
      this.flag,
      this.photoUrl,
      this.displayPhoto,
      this.squadsCount = 0,
      this.ratingCount = 0,
      this.upCount = 0,
      this.downCount = 0,
      this.approvalPct = 0});

  factory _$PlaceStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaceStatsImplFromJson(json);

  @override
  final String placeId;
  @override
  final String name;
  @override
  final String category;
  @override
  final String destination;
  @override
  final String? country;
  @override
  final String? flag;
  @override
  final String? photoUrl;
  @override
  final String? displayPhoto;
  @override
  @JsonKey()
  final int squadsCount;
  @override
  @JsonKey()
  final int ratingCount;
  @override
  @JsonKey()
  final int upCount;
  @override
  @JsonKey()
  final int downCount;
  @override
  @JsonKey()
  final int approvalPct;

  @override
  String toString() {
    return 'PlaceStats(placeId: $placeId, name: $name, category: $category, destination: $destination, country: $country, flag: $flag, photoUrl: $photoUrl, displayPhoto: $displayPhoto, squadsCount: $squadsCount, ratingCount: $ratingCount, upCount: $upCount, downCount: $downCount, approvalPct: $approvalPct)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaceStatsImpl &&
            (identical(other.placeId, placeId) || other.placeId == placeId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.displayPhoto, displayPhoto) ||
                other.displayPhoto == displayPhoto) &&
            (identical(other.squadsCount, squadsCount) ||
                other.squadsCount == squadsCount) &&
            (identical(other.ratingCount, ratingCount) ||
                other.ratingCount == ratingCount) &&
            (identical(other.upCount, upCount) || other.upCount == upCount) &&
            (identical(other.downCount, downCount) ||
                other.downCount == downCount) &&
            (identical(other.approvalPct, approvalPct) ||
                other.approvalPct == approvalPct));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      placeId,
      name,
      category,
      destination,
      country,
      flag,
      photoUrl,
      displayPhoto,
      squadsCount,
      ratingCount,
      upCount,
      downCount,
      approvalPct);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaceStatsImplCopyWith<_$PlaceStatsImpl> get copyWith =>
      __$$PlaceStatsImplCopyWithImpl<_$PlaceStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaceStatsImplToJson(
      this,
    );
  }
}

abstract class _PlaceStats implements PlaceStats {
  const factory _PlaceStats(
      {required final String placeId,
      required final String name,
      required final String category,
      required final String destination,
      final String? country,
      final String? flag,
      final String? photoUrl,
      final String? displayPhoto,
      final int squadsCount,
      final int ratingCount,
      final int upCount,
      final int downCount,
      final int approvalPct}) = _$PlaceStatsImpl;

  factory _PlaceStats.fromJson(Map<String, dynamic> json) =
      _$PlaceStatsImpl.fromJson;

  @override
  String get placeId;
  @override
  String get name;
  @override
  String get category;
  @override
  String get destination;
  @override
  String? get country;
  @override
  String? get flag;
  @override
  String? get photoUrl;
  @override
  String? get displayPhoto;
  @override
  int get squadsCount;
  @override
  int get ratingCount;
  @override
  int get upCount;
  @override
  int get downCount;
  @override
  int get approvalPct;
  @override
  @JsonKey(ignore: true)
  _$$PlaceStatsImplCopyWith<_$PlaceStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DestinationHub _$DestinationHubFromJson(Map<String, dynamic> json) {
  return _DestinationHub.fromJson(json);
}

/// @nodoc
mixin _$DestinationHub {
  String get destination => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get flag => throw _privateConstructorUsedError;
  int get placeCount => throw _privateConstructorUsedError;
  int get activityCount => throw _privateConstructorUsedError;
  int get hotelCount => throw _privateConstructorUsedError;
  int get restaurantCount => throw _privateConstructorUsedError;
  double? get avgStars => throw _privateConstructorUsedError;
  int get recapCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DestinationHubCopyWith<DestinationHub> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DestinationHubCopyWith<$Res> {
  factory $DestinationHubCopyWith(
          DestinationHub value, $Res Function(DestinationHub) then) =
      _$DestinationHubCopyWithImpl<$Res, DestinationHub>;
  @useResult
  $Res call(
      {String destination,
      String? country,
      String? flag,
      int placeCount,
      int activityCount,
      int hotelCount,
      int restaurantCount,
      double? avgStars,
      int recapCount});
}

/// @nodoc
class _$DestinationHubCopyWithImpl<$Res, $Val extends DestinationHub>
    implements $DestinationHubCopyWith<$Res> {
  _$DestinationHubCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? destination = null,
    Object? country = freezed,
    Object? flag = freezed,
    Object? placeCount = null,
    Object? activityCount = null,
    Object? hotelCount = null,
    Object? restaurantCount = null,
    Object? avgStars = freezed,
    Object? recapCount = null,
  }) {
    return _then(_value.copyWith(
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      flag: freezed == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String?,
      placeCount: null == placeCount
          ? _value.placeCount
          : placeCount // ignore: cast_nullable_to_non_nullable
              as int,
      activityCount: null == activityCount
          ? _value.activityCount
          : activityCount // ignore: cast_nullable_to_non_nullable
              as int,
      hotelCount: null == hotelCount
          ? _value.hotelCount
          : hotelCount // ignore: cast_nullable_to_non_nullable
              as int,
      restaurantCount: null == restaurantCount
          ? _value.restaurantCount
          : restaurantCount // ignore: cast_nullable_to_non_nullable
              as int,
      avgStars: freezed == avgStars
          ? _value.avgStars
          : avgStars // ignore: cast_nullable_to_non_nullable
              as double?,
      recapCount: null == recapCount
          ? _value.recapCount
          : recapCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DestinationHubImplCopyWith<$Res>
    implements $DestinationHubCopyWith<$Res> {
  factory _$$DestinationHubImplCopyWith(_$DestinationHubImpl value,
          $Res Function(_$DestinationHubImpl) then) =
      __$$DestinationHubImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String destination,
      String? country,
      String? flag,
      int placeCount,
      int activityCount,
      int hotelCount,
      int restaurantCount,
      double? avgStars,
      int recapCount});
}

/// @nodoc
class __$$DestinationHubImplCopyWithImpl<$Res>
    extends _$DestinationHubCopyWithImpl<$Res, _$DestinationHubImpl>
    implements _$$DestinationHubImplCopyWith<$Res> {
  __$$DestinationHubImplCopyWithImpl(
      _$DestinationHubImpl _value, $Res Function(_$DestinationHubImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? destination = null,
    Object? country = freezed,
    Object? flag = freezed,
    Object? placeCount = null,
    Object? activityCount = null,
    Object? hotelCount = null,
    Object? restaurantCount = null,
    Object? avgStars = freezed,
    Object? recapCount = null,
  }) {
    return _then(_$DestinationHubImpl(
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      flag: freezed == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String?,
      placeCount: null == placeCount
          ? _value.placeCount
          : placeCount // ignore: cast_nullable_to_non_nullable
              as int,
      activityCount: null == activityCount
          ? _value.activityCount
          : activityCount // ignore: cast_nullable_to_non_nullable
              as int,
      hotelCount: null == hotelCount
          ? _value.hotelCount
          : hotelCount // ignore: cast_nullable_to_non_nullable
              as int,
      restaurantCount: null == restaurantCount
          ? _value.restaurantCount
          : restaurantCount // ignore: cast_nullable_to_non_nullable
              as int,
      avgStars: freezed == avgStars
          ? _value.avgStars
          : avgStars // ignore: cast_nullable_to_non_nullable
              as double?,
      recapCount: null == recapCount
          ? _value.recapCount
          : recapCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DestinationHubImpl implements _DestinationHub {
  const _$DestinationHubImpl(
      {required this.destination,
      this.country,
      this.flag,
      this.placeCount = 0,
      this.activityCount = 0,
      this.hotelCount = 0,
      this.restaurantCount = 0,
      this.avgStars,
      this.recapCount = 0});

  factory _$DestinationHubImpl.fromJson(Map<String, dynamic> json) =>
      _$$DestinationHubImplFromJson(json);

  @override
  final String destination;
  @override
  final String? country;
  @override
  final String? flag;
  @override
  @JsonKey()
  final int placeCount;
  @override
  @JsonKey()
  final int activityCount;
  @override
  @JsonKey()
  final int hotelCount;
  @override
  @JsonKey()
  final int restaurantCount;
  @override
  final double? avgStars;
  @override
  @JsonKey()
  final int recapCount;

  @override
  String toString() {
    return 'DestinationHub(destination: $destination, country: $country, flag: $flag, placeCount: $placeCount, activityCount: $activityCount, hotelCount: $hotelCount, restaurantCount: $restaurantCount, avgStars: $avgStars, recapCount: $recapCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DestinationHubImpl &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.placeCount, placeCount) ||
                other.placeCount == placeCount) &&
            (identical(other.activityCount, activityCount) ||
                other.activityCount == activityCount) &&
            (identical(other.hotelCount, hotelCount) ||
                other.hotelCount == hotelCount) &&
            (identical(other.restaurantCount, restaurantCount) ||
                other.restaurantCount == restaurantCount) &&
            (identical(other.avgStars, avgStars) ||
                other.avgStars == avgStars) &&
            (identical(other.recapCount, recapCount) ||
                other.recapCount == recapCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      destination,
      country,
      flag,
      placeCount,
      activityCount,
      hotelCount,
      restaurantCount,
      avgStars,
      recapCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DestinationHubImplCopyWith<_$DestinationHubImpl> get copyWith =>
      __$$DestinationHubImplCopyWithImpl<_$DestinationHubImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DestinationHubImplToJson(
      this,
    );
  }
}

abstract class _DestinationHub implements DestinationHub {
  const factory _DestinationHub(
      {required final String destination,
      final String? country,
      final String? flag,
      final int placeCount,
      final int activityCount,
      final int hotelCount,
      final int restaurantCount,
      final double? avgStars,
      final int recapCount}) = _$DestinationHubImpl;

  factory _DestinationHub.fromJson(Map<String, dynamic> json) =
      _$DestinationHubImpl.fromJson;

  @override
  String get destination;
  @override
  String? get country;
  @override
  String? get flag;
  @override
  int get placeCount;
  @override
  int get activityCount;
  @override
  int get hotelCount;
  @override
  int get restaurantCount;
  @override
  double? get avgStars;
  @override
  int get recapCount;
  @override
  @JsonKey(ignore: true)
  _$$DestinationHubImplCopyWith<_$DestinationHubImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DmConversation _$DmConversationFromJson(Map<String, dynamic> json) {
  return _DmConversation.fromJson(json);
}

/// @nodoc
mixin _$DmConversation {
  String get otherUserId => throw _privateConstructorUsedError;
  String? get otherNickname => throw _privateConstructorUsedError;
  String? get otherTag => throw _privateConstructorUsedError;
  String? get otherEmoji => throw _privateConstructorUsedError;
  String? get otherAvatarUrl => throw _privateConstructorUsedError;
  String get lastMessage => throw _privateConstructorUsedError;
  DateTime get lastMessageAt => throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DmConversationCopyWith<DmConversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DmConversationCopyWith<$Res> {
  factory $DmConversationCopyWith(
          DmConversation value, $Res Function(DmConversation) then) =
      _$DmConversationCopyWithImpl<$Res, DmConversation>;
  @useResult
  $Res call(
      {String otherUserId,
      String? otherNickname,
      String? otherTag,
      String? otherEmoji,
      String? otherAvatarUrl,
      String lastMessage,
      DateTime lastMessageAt,
      int unreadCount});
}

/// @nodoc
class _$DmConversationCopyWithImpl<$Res, $Val extends DmConversation>
    implements $DmConversationCopyWith<$Res> {
  _$DmConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? otherUserId = null,
    Object? otherNickname = freezed,
    Object? otherTag = freezed,
    Object? otherEmoji = freezed,
    Object? otherAvatarUrl = freezed,
    Object? lastMessage = null,
    Object? lastMessageAt = null,
    Object? unreadCount = null,
  }) {
    return _then(_value.copyWith(
      otherUserId: null == otherUserId
          ? _value.otherUserId
          : otherUserId // ignore: cast_nullable_to_non_nullable
              as String,
      otherNickname: freezed == otherNickname
          ? _value.otherNickname
          : otherNickname // ignore: cast_nullable_to_non_nullable
              as String?,
      otherTag: freezed == otherTag
          ? _value.otherTag
          : otherTag // ignore: cast_nullable_to_non_nullable
              as String?,
      otherEmoji: freezed == otherEmoji
          ? _value.otherEmoji
          : otherEmoji // ignore: cast_nullable_to_non_nullable
              as String?,
      otherAvatarUrl: freezed == otherAvatarUrl
          ? _value.otherAvatarUrl
          : otherAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessage: null == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String,
      lastMessageAt: null == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DmConversationImplCopyWith<$Res>
    implements $DmConversationCopyWith<$Res> {
  factory _$$DmConversationImplCopyWith(_$DmConversationImpl value,
          $Res Function(_$DmConversationImpl) then) =
      __$$DmConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String otherUserId,
      String? otherNickname,
      String? otherTag,
      String? otherEmoji,
      String? otherAvatarUrl,
      String lastMessage,
      DateTime lastMessageAt,
      int unreadCount});
}

/// @nodoc
class __$$DmConversationImplCopyWithImpl<$Res>
    extends _$DmConversationCopyWithImpl<$Res, _$DmConversationImpl>
    implements _$$DmConversationImplCopyWith<$Res> {
  __$$DmConversationImplCopyWithImpl(
      _$DmConversationImpl _value, $Res Function(_$DmConversationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? otherUserId = null,
    Object? otherNickname = freezed,
    Object? otherTag = freezed,
    Object? otherEmoji = freezed,
    Object? otherAvatarUrl = freezed,
    Object? lastMessage = null,
    Object? lastMessageAt = null,
    Object? unreadCount = null,
  }) {
    return _then(_$DmConversationImpl(
      otherUserId: null == otherUserId
          ? _value.otherUserId
          : otherUserId // ignore: cast_nullable_to_non_nullable
              as String,
      otherNickname: freezed == otherNickname
          ? _value.otherNickname
          : otherNickname // ignore: cast_nullable_to_non_nullable
              as String?,
      otherTag: freezed == otherTag
          ? _value.otherTag
          : otherTag // ignore: cast_nullable_to_non_nullable
              as String?,
      otherEmoji: freezed == otherEmoji
          ? _value.otherEmoji
          : otherEmoji // ignore: cast_nullable_to_non_nullable
              as String?,
      otherAvatarUrl: freezed == otherAvatarUrl
          ? _value.otherAvatarUrl
          : otherAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessage: null == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String,
      lastMessageAt: null == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DmConversationImpl implements _DmConversation {
  const _$DmConversationImpl(
      {required this.otherUserId,
      this.otherNickname,
      this.otherTag,
      this.otherEmoji,
      this.otherAvatarUrl,
      required this.lastMessage,
      required this.lastMessageAt,
      this.unreadCount = 0});

  factory _$DmConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$DmConversationImplFromJson(json);

  @override
  final String otherUserId;
  @override
  final String? otherNickname;
  @override
  final String? otherTag;
  @override
  final String? otherEmoji;
  @override
  final String? otherAvatarUrl;
  @override
  final String lastMessage;
  @override
  final DateTime lastMessageAt;
  @override
  @JsonKey()
  final int unreadCount;

  @override
  String toString() {
    return 'DmConversation(otherUserId: $otherUserId, otherNickname: $otherNickname, otherTag: $otherTag, otherEmoji: $otherEmoji, otherAvatarUrl: $otherAvatarUrl, lastMessage: $lastMessage, lastMessageAt: $lastMessageAt, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DmConversationImpl &&
            (identical(other.otherUserId, otherUserId) ||
                other.otherUserId == otherUserId) &&
            (identical(other.otherNickname, otherNickname) ||
                other.otherNickname == otherNickname) &&
            (identical(other.otherTag, otherTag) ||
                other.otherTag == otherTag) &&
            (identical(other.otherEmoji, otherEmoji) ||
                other.otherEmoji == otherEmoji) &&
            (identical(other.otherAvatarUrl, otherAvatarUrl) ||
                other.otherAvatarUrl == otherAvatarUrl) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      otherUserId,
      otherNickname,
      otherTag,
      otherEmoji,
      otherAvatarUrl,
      lastMessage,
      lastMessageAt,
      unreadCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DmConversationImplCopyWith<_$DmConversationImpl> get copyWith =>
      __$$DmConversationImplCopyWithImpl<_$DmConversationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DmConversationImplToJson(
      this,
    );
  }
}

abstract class _DmConversation implements DmConversation {
  const factory _DmConversation(
      {required final String otherUserId,
      final String? otherNickname,
      final String? otherTag,
      final String? otherEmoji,
      final String? otherAvatarUrl,
      required final String lastMessage,
      required final DateTime lastMessageAt,
      final int unreadCount}) = _$DmConversationImpl;

  factory _DmConversation.fromJson(Map<String, dynamic> json) =
      _$DmConversationImpl.fromJson;

  @override
  String get otherUserId;
  @override
  String? get otherNickname;
  @override
  String? get otherTag;
  @override
  String? get otherEmoji;
  @override
  String? get otherAvatarUrl;
  @override
  String get lastMessage;
  @override
  DateTime get lastMessageAt;
  @override
  int get unreadCount;
  @override
  @JsonKey(ignore: true)
  _$$DmConversationImplCopyWith<_$DmConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatchProfile _$MatchProfileFromJson(Map<String, dynamic> json) {
  return _MatchProfile.fromJson(json);
}

/// @nodoc
mixin _$MatchProfile {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  String get flag => throw _privateConstructorUsedError;
  DateTime get travelStart => throw _privateConstructorUsedError;
  DateTime get travelEnd => throw _privateConstructorUsedError;
  List<String> get vibes => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  int? get age => throw _privateConstructorUsedError;
  String? get emoji => throw _privateConstructorUsedError;
  double? get compatibilityScore => throw _privateConstructorUsedError;
  bool get hasWaved => throw _privateConstructorUsedError;
  bool get isMatch => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MatchProfileCopyWith<MatchProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchProfileCopyWith<$Res> {
  factory $MatchProfileCopyWith(
          MatchProfile value, $Res Function(MatchProfile) then) =
      _$MatchProfileCopyWithImpl<$Res, MatchProfile>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String destination,
      String flag,
      DateTime travelStart,
      DateTime travelEnd,
      List<String> vibes,
      String? bio,
      int? age,
      String? emoji,
      double? compatibilityScore,
      bool hasWaved,
      bool isMatch});
}

/// @nodoc
class _$MatchProfileCopyWithImpl<$Res, $Val extends MatchProfile>
    implements $MatchProfileCopyWith<$Res> {
  _$MatchProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? destination = null,
    Object? flag = null,
    Object? travelStart = null,
    Object? travelEnd = null,
    Object? vibes = null,
    Object? bio = freezed,
    Object? age = freezed,
    Object? emoji = freezed,
    Object? compatibilityScore = freezed,
    Object? hasWaved = null,
    Object? isMatch = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      flag: null == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String,
      travelStart: null == travelStart
          ? _value.travelStart
          : travelStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      travelEnd: null == travelEnd
          ? _value.travelEnd
          : travelEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      vibes: null == vibes
          ? _value.vibes
          : vibes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      age: freezed == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int?,
      emoji: freezed == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String?,
      compatibilityScore: freezed == compatibilityScore
          ? _value.compatibilityScore
          : compatibilityScore // ignore: cast_nullable_to_non_nullable
              as double?,
      hasWaved: null == hasWaved
          ? _value.hasWaved
          : hasWaved // ignore: cast_nullable_to_non_nullable
              as bool,
      isMatch: null == isMatch
          ? _value.isMatch
          : isMatch // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchProfileImplCopyWith<$Res>
    implements $MatchProfileCopyWith<$Res> {
  factory _$$MatchProfileImplCopyWith(
          _$MatchProfileImpl value, $Res Function(_$MatchProfileImpl) then) =
      __$$MatchProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String destination,
      String flag,
      DateTime travelStart,
      DateTime travelEnd,
      List<String> vibes,
      String? bio,
      int? age,
      String? emoji,
      double? compatibilityScore,
      bool hasWaved,
      bool isMatch});
}

/// @nodoc
class __$$MatchProfileImplCopyWithImpl<$Res>
    extends _$MatchProfileCopyWithImpl<$Res, _$MatchProfileImpl>
    implements _$$MatchProfileImplCopyWith<$Res> {
  __$$MatchProfileImplCopyWithImpl(
      _$MatchProfileImpl _value, $Res Function(_$MatchProfileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? destination = null,
    Object? flag = null,
    Object? travelStart = null,
    Object? travelEnd = null,
    Object? vibes = null,
    Object? bio = freezed,
    Object? age = freezed,
    Object? emoji = freezed,
    Object? compatibilityScore = freezed,
    Object? hasWaved = null,
    Object? isMatch = null,
  }) {
    return _then(_$MatchProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      flag: null == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String,
      travelStart: null == travelStart
          ? _value.travelStart
          : travelStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      travelEnd: null == travelEnd
          ? _value.travelEnd
          : travelEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      vibes: null == vibes
          ? _value._vibes
          : vibes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      age: freezed == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int?,
      emoji: freezed == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String?,
      compatibilityScore: freezed == compatibilityScore
          ? _value.compatibilityScore
          : compatibilityScore // ignore: cast_nullable_to_non_nullable
              as double?,
      hasWaved: null == hasWaved
          ? _value.hasWaved
          : hasWaved // ignore: cast_nullable_to_non_nullable
              as bool,
      isMatch: null == isMatch
          ? _value.isMatch
          : isMatch // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchProfileImpl implements _MatchProfile {
  const _$MatchProfileImpl(
      {required this.id,
      required this.userId,
      required this.destination,
      required this.flag,
      required this.travelStart,
      required this.travelEnd,
      required final List<String> vibes,
      this.bio,
      this.age,
      this.emoji,
      this.compatibilityScore,
      this.hasWaved = false,
      this.isMatch = false})
      : _vibes = vibes;

  factory _$MatchProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String destination;
  @override
  final String flag;
  @override
  final DateTime travelStart;
  @override
  final DateTime travelEnd;
  final List<String> _vibes;
  @override
  List<String> get vibes {
    if (_vibes is EqualUnmodifiableListView) return _vibes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_vibes);
  }

  @override
  final String? bio;
  @override
  final int? age;
  @override
  final String? emoji;
  @override
  final double? compatibilityScore;
  @override
  @JsonKey()
  final bool hasWaved;
  @override
  @JsonKey()
  final bool isMatch;

  @override
  String toString() {
    return 'MatchProfile(id: $id, userId: $userId, destination: $destination, flag: $flag, travelStart: $travelStart, travelEnd: $travelEnd, vibes: $vibes, bio: $bio, age: $age, emoji: $emoji, compatibilityScore: $compatibilityScore, hasWaved: $hasWaved, isMatch: $isMatch)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.travelStart, travelStart) ||
                other.travelStart == travelStart) &&
            (identical(other.travelEnd, travelEnd) ||
                other.travelEnd == travelEnd) &&
            const DeepCollectionEquality().equals(other._vibes, _vibes) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.compatibilityScore, compatibilityScore) ||
                other.compatibilityScore == compatibilityScore) &&
            (identical(other.hasWaved, hasWaved) ||
                other.hasWaved == hasWaved) &&
            (identical(other.isMatch, isMatch) || other.isMatch == isMatch));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      destination,
      flag,
      travelStart,
      travelEnd,
      const DeepCollectionEquality().hash(_vibes),
      bio,
      age,
      emoji,
      compatibilityScore,
      hasWaved,
      isMatch);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchProfileImplCopyWith<_$MatchProfileImpl> get copyWith =>
      __$$MatchProfileImplCopyWithImpl<_$MatchProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchProfileImplToJson(
      this,
    );
  }
}

abstract class _MatchProfile implements MatchProfile {
  const factory _MatchProfile(
      {required final String id,
      required final String userId,
      required final String destination,
      required final String flag,
      required final DateTime travelStart,
      required final DateTime travelEnd,
      required final List<String> vibes,
      final String? bio,
      final int? age,
      final String? emoji,
      final double? compatibilityScore,
      final bool hasWaved,
      final bool isMatch}) = _$MatchProfileImpl;

  factory _MatchProfile.fromJson(Map<String, dynamic> json) =
      _$MatchProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get destination;
  @override
  String get flag;
  @override
  DateTime get travelStart;
  @override
  DateTime get travelEnd;
  @override
  List<String> get vibes;
  @override
  String? get bio;
  @override
  int? get age;
  @override
  String? get emoji;
  @override
  double? get compatibilityScore;
  @override
  bool get hasWaved;
  @override
  bool get isMatch;
  @override
  @JsonKey(ignore: true)
  _$$MatchProfileImplCopyWith<_$MatchProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemberArrivalPlan _$MemberArrivalPlanFromJson(Map<String, dynamic> json) {
  return _MemberArrivalPlan.fromJson(json);
}

/// @nodoc
mixin _$MemberArrivalPlan {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get departureCity => throw _privateConstructorUsedError;
  String? get departureIata =>
      throw _privateConstructorUsedError; // 3-letter airport code
  String? get arrivalIata => throw _privateConstructorUsedError;
  DateTime? get outboundAt =>
      throw _privateConstructorUsedError; // locked when booked
  String? get airline => throw _privateConstructorUsedError;
  String? get flightNumber => throw _privateConstructorUsedError;
  String? get bookingRef => throw _privateConstructorUsedError;
  ArrivalPlanState get state => throw _privateConstructorUsedError;
  bool get isAnchor => throw _privateConstructorUsedError;
  DateTime? get bookedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemberArrivalPlanCopyWith<MemberArrivalPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemberArrivalPlanCopyWith<$Res> {
  factory $MemberArrivalPlanCopyWith(
          MemberArrivalPlan value, $Res Function(MemberArrivalPlan) then) =
      _$MemberArrivalPlanCopyWithImpl<$Res, MemberArrivalPlan>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String userId,
      String? departureCity,
      String? departureIata,
      String? arrivalIata,
      DateTime? outboundAt,
      String? airline,
      String? flightNumber,
      String? bookingRef,
      ArrivalPlanState state,
      bool isAnchor,
      DateTime? bookedAt,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$MemberArrivalPlanCopyWithImpl<$Res, $Val extends MemberArrivalPlan>
    implements $MemberArrivalPlanCopyWith<$Res> {
  _$MemberArrivalPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = null,
    Object? departureCity = freezed,
    Object? departureIata = freezed,
    Object? arrivalIata = freezed,
    Object? outboundAt = freezed,
    Object? airline = freezed,
    Object? flightNumber = freezed,
    Object? bookingRef = freezed,
    Object? state = null,
    Object? isAnchor = null,
    Object? bookedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      departureCity: freezed == departureCity
          ? _value.departureCity
          : departureCity // ignore: cast_nullable_to_non_nullable
              as String?,
      departureIata: freezed == departureIata
          ? _value.departureIata
          : departureIata // ignore: cast_nullable_to_non_nullable
              as String?,
      arrivalIata: freezed == arrivalIata
          ? _value.arrivalIata
          : arrivalIata // ignore: cast_nullable_to_non_nullable
              as String?,
      outboundAt: freezed == outboundAt
          ? _value.outboundAt
          : outboundAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      airline: freezed == airline
          ? _value.airline
          : airline // ignore: cast_nullable_to_non_nullable
              as String?,
      flightNumber: freezed == flightNumber
          ? _value.flightNumber
          : flightNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingRef: freezed == bookingRef
          ? _value.bookingRef
          : bookingRef // ignore: cast_nullable_to_non_nullable
              as String?,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as ArrivalPlanState,
      isAnchor: null == isAnchor
          ? _value.isAnchor
          : isAnchor // ignore: cast_nullable_to_non_nullable
              as bool,
      bookedAt: freezed == bookedAt
          ? _value.bookedAt
          : bookedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemberArrivalPlanImplCopyWith<$Res>
    implements $MemberArrivalPlanCopyWith<$Res> {
  factory _$$MemberArrivalPlanImplCopyWith(_$MemberArrivalPlanImpl value,
          $Res Function(_$MemberArrivalPlanImpl) then) =
      __$$MemberArrivalPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String userId,
      String? departureCity,
      String? departureIata,
      String? arrivalIata,
      DateTime? outboundAt,
      String? airline,
      String? flightNumber,
      String? bookingRef,
      ArrivalPlanState state,
      bool isAnchor,
      DateTime? bookedAt,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$MemberArrivalPlanImplCopyWithImpl<$Res>
    extends _$MemberArrivalPlanCopyWithImpl<$Res, _$MemberArrivalPlanImpl>
    implements _$$MemberArrivalPlanImplCopyWith<$Res> {
  __$$MemberArrivalPlanImplCopyWithImpl(_$MemberArrivalPlanImpl _value,
      $Res Function(_$MemberArrivalPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = null,
    Object? departureCity = freezed,
    Object? departureIata = freezed,
    Object? arrivalIata = freezed,
    Object? outboundAt = freezed,
    Object? airline = freezed,
    Object? flightNumber = freezed,
    Object? bookingRef = freezed,
    Object? state = null,
    Object? isAnchor = null,
    Object? bookedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$MemberArrivalPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      departureCity: freezed == departureCity
          ? _value.departureCity
          : departureCity // ignore: cast_nullable_to_non_nullable
              as String?,
      departureIata: freezed == departureIata
          ? _value.departureIata
          : departureIata // ignore: cast_nullable_to_non_nullable
              as String?,
      arrivalIata: freezed == arrivalIata
          ? _value.arrivalIata
          : arrivalIata // ignore: cast_nullable_to_non_nullable
              as String?,
      outboundAt: freezed == outboundAt
          ? _value.outboundAt
          : outboundAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      airline: freezed == airline
          ? _value.airline
          : airline // ignore: cast_nullable_to_non_nullable
              as String?,
      flightNumber: freezed == flightNumber
          ? _value.flightNumber
          : flightNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingRef: freezed == bookingRef
          ? _value.bookingRef
          : bookingRef // ignore: cast_nullable_to_non_nullable
              as String?,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as ArrivalPlanState,
      isAnchor: null == isAnchor
          ? _value.isAnchor
          : isAnchor // ignore: cast_nullable_to_non_nullable
              as bool,
      bookedAt: freezed == bookedAt
          ? _value.bookedAt
          : bookedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemberArrivalPlanImpl implements _MemberArrivalPlan {
  const _$MemberArrivalPlanImpl(
      {required this.id,
      required this.tripId,
      required this.userId,
      this.departureCity,
      this.departureIata,
      this.arrivalIata,
      this.outboundAt,
      this.airline,
      this.flightNumber,
      this.bookingRef,
      this.state = ArrivalPlanState.not_set,
      this.isAnchor = false,
      this.bookedAt,
      this.createdAt,
      this.updatedAt});

  factory _$MemberArrivalPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemberArrivalPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String userId;
  @override
  final String? departureCity;
  @override
  final String? departureIata;
// 3-letter airport code
  @override
  final String? arrivalIata;
  @override
  final DateTime? outboundAt;
// locked when booked
  @override
  final String? airline;
  @override
  final String? flightNumber;
  @override
  final String? bookingRef;
  @override
  @JsonKey()
  final ArrivalPlanState state;
  @override
  @JsonKey()
  final bool isAnchor;
  @override
  final DateTime? bookedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'MemberArrivalPlan(id: $id, tripId: $tripId, userId: $userId, departureCity: $departureCity, departureIata: $departureIata, arrivalIata: $arrivalIata, outboundAt: $outboundAt, airline: $airline, flightNumber: $flightNumber, bookingRef: $bookingRef, state: $state, isAnchor: $isAnchor, bookedAt: $bookedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemberArrivalPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.departureCity, departureCity) ||
                other.departureCity == departureCity) &&
            (identical(other.departureIata, departureIata) ||
                other.departureIata == departureIata) &&
            (identical(other.arrivalIata, arrivalIata) ||
                other.arrivalIata == arrivalIata) &&
            (identical(other.outboundAt, outboundAt) ||
                other.outboundAt == outboundAt) &&
            (identical(other.airline, airline) || other.airline == airline) &&
            (identical(other.flightNumber, flightNumber) ||
                other.flightNumber == flightNumber) &&
            (identical(other.bookingRef, bookingRef) ||
                other.bookingRef == bookingRef) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.isAnchor, isAnchor) ||
                other.isAnchor == isAnchor) &&
            (identical(other.bookedAt, bookedAt) ||
                other.bookedAt == bookedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      userId,
      departureCity,
      departureIata,
      arrivalIata,
      outboundAt,
      airline,
      flightNumber,
      bookingRef,
      state,
      isAnchor,
      bookedAt,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemberArrivalPlanImplCopyWith<_$MemberArrivalPlanImpl> get copyWith =>
      __$$MemberArrivalPlanImplCopyWithImpl<_$MemberArrivalPlanImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemberArrivalPlanImplToJson(
      this,
    );
  }
}

abstract class _MemberArrivalPlan implements MemberArrivalPlan {
  const factory _MemberArrivalPlan(
      {required final String id,
      required final String tripId,
      required final String userId,
      final String? departureCity,
      final String? departureIata,
      final String? arrivalIata,
      final DateTime? outboundAt,
      final String? airline,
      final String? flightNumber,
      final String? bookingRef,
      final ArrivalPlanState state,
      final bool isAnchor,
      final DateTime? bookedAt,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$MemberArrivalPlanImpl;

  factory _MemberArrivalPlan.fromJson(Map<String, dynamic> json) =
      _$MemberArrivalPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String get userId;
  @override
  String? get departureCity;
  @override
  String? get departureIata;
  @override // 3-letter airport code
  String? get arrivalIata;
  @override
  DateTime? get outboundAt;
  @override // locked when booked
  String? get airline;
  @override
  String? get flightNumber;
  @override
  String? get bookingRef;
  @override
  ArrivalPlanState get state;
  @override
  bool get isAnchor;
  @override
  DateTime? get bookedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$MemberArrivalPlanImplCopyWith<_$MemberArrivalPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BookingConfirmation _$BookingConfirmationFromJson(Map<String, dynamic> json) {
  return _BookingConfirmation.fromJson(json);
}

/// @nodoc
mixin _$BookingConfirmation {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  BookingKind get kind => throw _privateConstructorUsedError;
  String? get recommendationId => throw _privateConstructorUsedError;
  String? get arrivalPlanId => throw _privateConstructorUsedError;
  int? get totalCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime? get confirmedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BookingConfirmationCopyWith<BookingConfirmation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingConfirmationCopyWith<$Res> {
  factory $BookingConfirmationCopyWith(
          BookingConfirmation value, $Res Function(BookingConfirmation) then) =
      _$BookingConfirmationCopyWithImpl<$Res, BookingConfirmation>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      String userId,
      BookingKind kind,
      String? recommendationId,
      String? arrivalPlanId,
      int? totalCents,
      String currency,
      String? notes,
      DateTime? confirmedAt});
}

/// @nodoc
class _$BookingConfirmationCopyWithImpl<$Res, $Val extends BookingConfirmation>
    implements $BookingConfirmationCopyWith<$Res> {
  _$BookingConfirmationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = null,
    Object? kind = null,
    Object? recommendationId = freezed,
    Object? arrivalPlanId = freezed,
    Object? totalCents = freezed,
    Object? currency = null,
    Object? notes = freezed,
    Object? confirmedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as BookingKind,
      recommendationId: freezed == recommendationId
          ? _value.recommendationId
          : recommendationId // ignore: cast_nullable_to_non_nullable
              as String?,
      arrivalPlanId: freezed == arrivalPlanId
          ? _value.arrivalPlanId
          : arrivalPlanId // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCents: freezed == totalCents
          ? _value.totalCents
          : totalCents // ignore: cast_nullable_to_non_nullable
              as int?,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmedAt: freezed == confirmedAt
          ? _value.confirmedAt
          : confirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BookingConfirmationImplCopyWith<$Res>
    implements $BookingConfirmationCopyWith<$Res> {
  factory _$$BookingConfirmationImplCopyWith(_$BookingConfirmationImpl value,
          $Res Function(_$BookingConfirmationImpl) then) =
      __$$BookingConfirmationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      String userId,
      BookingKind kind,
      String? recommendationId,
      String? arrivalPlanId,
      int? totalCents,
      String currency,
      String? notes,
      DateTime? confirmedAt});
}

/// @nodoc
class __$$BookingConfirmationImplCopyWithImpl<$Res>
    extends _$BookingConfirmationCopyWithImpl<$Res, _$BookingConfirmationImpl>
    implements _$$BookingConfirmationImplCopyWith<$Res> {
  __$$BookingConfirmationImplCopyWithImpl(_$BookingConfirmationImpl _value,
      $Res Function(_$BookingConfirmationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? userId = null,
    Object? kind = null,
    Object? recommendationId = freezed,
    Object? arrivalPlanId = freezed,
    Object? totalCents = freezed,
    Object? currency = null,
    Object? notes = freezed,
    Object? confirmedAt = freezed,
  }) {
    return _then(_$BookingConfirmationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as BookingKind,
      recommendationId: freezed == recommendationId
          ? _value.recommendationId
          : recommendationId // ignore: cast_nullable_to_non_nullable
              as String?,
      arrivalPlanId: freezed == arrivalPlanId
          ? _value.arrivalPlanId
          : arrivalPlanId // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCents: freezed == totalCents
          ? _value.totalCents
          : totalCents // ignore: cast_nullable_to_non_nullable
              as int?,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmedAt: freezed == confirmedAt
          ? _value.confirmedAt
          : confirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingConfirmationImpl implements _BookingConfirmation {
  const _$BookingConfirmationImpl(
      {required this.id,
      required this.tripId,
      required this.userId,
      required this.kind,
      this.recommendationId,
      this.arrivalPlanId,
      this.totalCents,
      this.currency = 'USD',
      this.notes,
      this.confirmedAt});

  factory _$BookingConfirmationImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingConfirmationImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String userId;
  @override
  final BookingKind kind;
  @override
  final String? recommendationId;
  @override
  final String? arrivalPlanId;
  @override
  final int? totalCents;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? notes;
  @override
  final DateTime? confirmedAt;

  @override
  String toString() {
    return 'BookingConfirmation(id: $id, tripId: $tripId, userId: $userId, kind: $kind, recommendationId: $recommendationId, arrivalPlanId: $arrivalPlanId, totalCents: $totalCents, currency: $currency, notes: $notes, confirmedAt: $confirmedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingConfirmationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.recommendationId, recommendationId) ||
                other.recommendationId == recommendationId) &&
            (identical(other.arrivalPlanId, arrivalPlanId) ||
                other.arrivalPlanId == arrivalPlanId) &&
            (identical(other.totalCents, totalCents) ||
                other.totalCents == totalCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      userId,
      kind,
      recommendationId,
      arrivalPlanId,
      totalCents,
      currency,
      notes,
      confirmedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingConfirmationImplCopyWith<_$BookingConfirmationImpl> get copyWith =>
      __$$BookingConfirmationImplCopyWithImpl<_$BookingConfirmationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingConfirmationImplToJson(
      this,
    );
  }
}

abstract class _BookingConfirmation implements BookingConfirmation {
  const factory _BookingConfirmation(
      {required final String id,
      required final String tripId,
      required final String userId,
      required final BookingKind kind,
      final String? recommendationId,
      final String? arrivalPlanId,
      final int? totalCents,
      final String currency,
      final String? notes,
      final DateTime? confirmedAt}) = _$BookingConfirmationImpl;

  factory _BookingConfirmation.fromJson(Map<String, dynamic> json) =
      _$BookingConfirmationImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String get userId;
  @override
  BookingKind get kind;
  @override
  String? get recommendationId;
  @override
  String? get arrivalPlanId;
  @override
  int? get totalCents;
  @override
  String get currency;
  @override
  String? get notes;
  @override
  DateTime? get confirmedAt;
  @override
  @JsonKey(ignore: true)
  _$$BookingConfirmationImplCopyWith<_$BookingConfirmationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TripBookingDeadline _$TripBookingDeadlineFromJson(Map<String, dynamic> json) {
  return _TripBookingDeadline.fromJson(json);
}

/// @nodoc
mixin _$TripBookingDeadline {
  String get tripId => throw _privateConstructorUsedError;
  BookingKind get kind => throw _privateConstructorUsedError;
  DateTime get deadlineAt => throw _privateConstructorUsedError;
  String? get setBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TripBookingDeadlineCopyWith<TripBookingDeadline> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripBookingDeadlineCopyWith<$Res> {
  factory $TripBookingDeadlineCopyWith(
          TripBookingDeadline value, $Res Function(TripBookingDeadline) then) =
      _$TripBookingDeadlineCopyWithImpl<$Res, TripBookingDeadline>;
  @useResult
  $Res call(
      {String tripId,
      BookingKind kind,
      DateTime deadlineAt,
      String? setBy,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$TripBookingDeadlineCopyWithImpl<$Res, $Val extends TripBookingDeadline>
    implements $TripBookingDeadlineCopyWith<$Res> {
  _$TripBookingDeadlineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? kind = null,
    Object? deadlineAt = null,
    Object? setBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as BookingKind,
      deadlineAt: null == deadlineAt
          ? _value.deadlineAt
          : deadlineAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      setBy: freezed == setBy
          ? _value.setBy
          : setBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripBookingDeadlineImplCopyWith<$Res>
    implements $TripBookingDeadlineCopyWith<$Res> {
  factory _$$TripBookingDeadlineImplCopyWith(_$TripBookingDeadlineImpl value,
          $Res Function(_$TripBookingDeadlineImpl) then) =
      __$$TripBookingDeadlineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      BookingKind kind,
      DateTime deadlineAt,
      String? setBy,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$TripBookingDeadlineImplCopyWithImpl<$Res>
    extends _$TripBookingDeadlineCopyWithImpl<$Res, _$TripBookingDeadlineImpl>
    implements _$$TripBookingDeadlineImplCopyWith<$Res> {
  __$$TripBookingDeadlineImplCopyWithImpl(_$TripBookingDeadlineImpl _value,
      $Res Function(_$TripBookingDeadlineImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? kind = null,
    Object? deadlineAt = null,
    Object? setBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$TripBookingDeadlineImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as BookingKind,
      deadlineAt: null == deadlineAt
          ? _value.deadlineAt
          : deadlineAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      setBy: freezed == setBy
          ? _value.setBy
          : setBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TripBookingDeadlineImpl implements _TripBookingDeadline {
  const _$TripBookingDeadlineImpl(
      {required this.tripId,
      required this.kind,
      required this.deadlineAt,
      this.setBy,
      this.createdAt,
      this.updatedAt});

  factory _$TripBookingDeadlineImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripBookingDeadlineImplFromJson(json);

  @override
  final String tripId;
  @override
  final BookingKind kind;
  @override
  final DateTime deadlineAt;
  @override
  final String? setBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'TripBookingDeadline(tripId: $tripId, kind: $kind, deadlineAt: $deadlineAt, setBy: $setBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripBookingDeadlineImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.deadlineAt, deadlineAt) ||
                other.deadlineAt == deadlineAt) &&
            (identical(other.setBy, setBy) || other.setBy == setBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, tripId, kind, deadlineAt, setBy, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripBookingDeadlineImplCopyWith<_$TripBookingDeadlineImpl> get copyWith =>
      __$$TripBookingDeadlineImplCopyWithImpl<_$TripBookingDeadlineImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripBookingDeadlineImplToJson(
      this,
    );
  }
}

abstract class _TripBookingDeadline implements TripBookingDeadline {
  const factory _TripBookingDeadline(
      {required final String tripId,
      required final BookingKind kind,
      required final DateTime deadlineAt,
      final String? setBy,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$TripBookingDeadlineImpl;

  factory _TripBookingDeadline.fromJson(Map<String, dynamic> json) =
      _$TripBookingDeadlineImpl.fromJson;

  @override
  String get tripId;
  @override
  BookingKind get kind;
  @override
  DateTime get deadlineAt;
  @override
  String? get setBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$TripBookingDeadlineImplCopyWith<_$TripBookingDeadlineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TripLockinStatus _$TripLockinStatusFromJson(Map<String, dynamic> json) {
  return _TripLockinStatus.fromJson(json);
}

/// @nodoc
mixin _$TripLockinStatus {
  String get tripId => throw _privateConstructorUsedError;
  int get squadSize => throw _privateConstructorUsedError;
  int get flightsBooked => throw _privateConstructorUsedError;
  int get accommodationBooked => throw _privateConstructorUsedError;
  int? get flightLockinPct => throw _privateConstructorUsedError;
  int? get accommodationLockinPct => throw _privateConstructorUsedError;
  DateTime? get flightDeadline => throw _privateConstructorUsedError;
  DateTime? get accommodationDeadline => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TripLockinStatusCopyWith<TripLockinStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripLockinStatusCopyWith<$Res> {
  factory $TripLockinStatusCopyWith(
          TripLockinStatus value, $Res Function(TripLockinStatus) then) =
      _$TripLockinStatusCopyWithImpl<$Res, TripLockinStatus>;
  @useResult
  $Res call(
      {String tripId,
      int squadSize,
      int flightsBooked,
      int accommodationBooked,
      int? flightLockinPct,
      int? accommodationLockinPct,
      DateTime? flightDeadline,
      DateTime? accommodationDeadline});
}

/// @nodoc
class _$TripLockinStatusCopyWithImpl<$Res, $Val extends TripLockinStatus>
    implements $TripLockinStatusCopyWith<$Res> {
  _$TripLockinStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? squadSize = null,
    Object? flightsBooked = null,
    Object? accommodationBooked = null,
    Object? flightLockinPct = freezed,
    Object? accommodationLockinPct = freezed,
    Object? flightDeadline = freezed,
    Object? accommodationDeadline = freezed,
  }) {
    return _then(_value.copyWith(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      squadSize: null == squadSize
          ? _value.squadSize
          : squadSize // ignore: cast_nullable_to_non_nullable
              as int,
      flightsBooked: null == flightsBooked
          ? _value.flightsBooked
          : flightsBooked // ignore: cast_nullable_to_non_nullable
              as int,
      accommodationBooked: null == accommodationBooked
          ? _value.accommodationBooked
          : accommodationBooked // ignore: cast_nullable_to_non_nullable
              as int,
      flightLockinPct: freezed == flightLockinPct
          ? _value.flightLockinPct
          : flightLockinPct // ignore: cast_nullable_to_non_nullable
              as int?,
      accommodationLockinPct: freezed == accommodationLockinPct
          ? _value.accommodationLockinPct
          : accommodationLockinPct // ignore: cast_nullable_to_non_nullable
              as int?,
      flightDeadline: freezed == flightDeadline
          ? _value.flightDeadline
          : flightDeadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      accommodationDeadline: freezed == accommodationDeadline
          ? _value.accommodationDeadline
          : accommodationDeadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripLockinStatusImplCopyWith<$Res>
    implements $TripLockinStatusCopyWith<$Res> {
  factory _$$TripLockinStatusImplCopyWith(_$TripLockinStatusImpl value,
          $Res Function(_$TripLockinStatusImpl) then) =
      __$$TripLockinStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      int squadSize,
      int flightsBooked,
      int accommodationBooked,
      int? flightLockinPct,
      int? accommodationLockinPct,
      DateTime? flightDeadline,
      DateTime? accommodationDeadline});
}

/// @nodoc
class __$$TripLockinStatusImplCopyWithImpl<$Res>
    extends _$TripLockinStatusCopyWithImpl<$Res, _$TripLockinStatusImpl>
    implements _$$TripLockinStatusImplCopyWith<$Res> {
  __$$TripLockinStatusImplCopyWithImpl(_$TripLockinStatusImpl _value,
      $Res Function(_$TripLockinStatusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? squadSize = null,
    Object? flightsBooked = null,
    Object? accommodationBooked = null,
    Object? flightLockinPct = freezed,
    Object? accommodationLockinPct = freezed,
    Object? flightDeadline = freezed,
    Object? accommodationDeadline = freezed,
  }) {
    return _then(_$TripLockinStatusImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      squadSize: null == squadSize
          ? _value.squadSize
          : squadSize // ignore: cast_nullable_to_non_nullable
              as int,
      flightsBooked: null == flightsBooked
          ? _value.flightsBooked
          : flightsBooked // ignore: cast_nullable_to_non_nullable
              as int,
      accommodationBooked: null == accommodationBooked
          ? _value.accommodationBooked
          : accommodationBooked // ignore: cast_nullable_to_non_nullable
              as int,
      flightLockinPct: freezed == flightLockinPct
          ? _value.flightLockinPct
          : flightLockinPct // ignore: cast_nullable_to_non_nullable
              as int?,
      accommodationLockinPct: freezed == accommodationLockinPct
          ? _value.accommodationLockinPct
          : accommodationLockinPct // ignore: cast_nullable_to_non_nullable
              as int?,
      flightDeadline: freezed == flightDeadline
          ? _value.flightDeadline
          : flightDeadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      accommodationDeadline: freezed == accommodationDeadline
          ? _value.accommodationDeadline
          : accommodationDeadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TripLockinStatusImpl implements _TripLockinStatus {
  const _$TripLockinStatusImpl(
      {required this.tripId,
      this.squadSize = 0,
      this.flightsBooked = 0,
      this.accommodationBooked = 0,
      this.flightLockinPct,
      this.accommodationLockinPct,
      this.flightDeadline,
      this.accommodationDeadline});

  factory _$TripLockinStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripLockinStatusImplFromJson(json);

  @override
  final String tripId;
  @override
  @JsonKey()
  final int squadSize;
  @override
  @JsonKey()
  final int flightsBooked;
  @override
  @JsonKey()
  final int accommodationBooked;
  @override
  final int? flightLockinPct;
  @override
  final int? accommodationLockinPct;
  @override
  final DateTime? flightDeadline;
  @override
  final DateTime? accommodationDeadline;

  @override
  String toString() {
    return 'TripLockinStatus(tripId: $tripId, squadSize: $squadSize, flightsBooked: $flightsBooked, accommodationBooked: $accommodationBooked, flightLockinPct: $flightLockinPct, accommodationLockinPct: $accommodationLockinPct, flightDeadline: $flightDeadline, accommodationDeadline: $accommodationDeadline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripLockinStatusImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.squadSize, squadSize) ||
                other.squadSize == squadSize) &&
            (identical(other.flightsBooked, flightsBooked) ||
                other.flightsBooked == flightsBooked) &&
            (identical(other.accommodationBooked, accommodationBooked) ||
                other.accommodationBooked == accommodationBooked) &&
            (identical(other.flightLockinPct, flightLockinPct) ||
                other.flightLockinPct == flightLockinPct) &&
            (identical(other.accommodationLockinPct, accommodationLockinPct) ||
                other.accommodationLockinPct == accommodationLockinPct) &&
            (identical(other.flightDeadline, flightDeadline) ||
                other.flightDeadline == flightDeadline) &&
            (identical(other.accommodationDeadline, accommodationDeadline) ||
                other.accommodationDeadline == accommodationDeadline));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      tripId,
      squadSize,
      flightsBooked,
      accommodationBooked,
      flightLockinPct,
      accommodationLockinPct,
      flightDeadline,
      accommodationDeadline);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripLockinStatusImplCopyWith<_$TripLockinStatusImpl> get copyWith =>
      __$$TripLockinStatusImplCopyWithImpl<_$TripLockinStatusImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripLockinStatusImplToJson(
      this,
    );
  }
}

abstract class _TripLockinStatus implements TripLockinStatus {
  const factory _TripLockinStatus(
      {required final String tripId,
      final int squadSize,
      final int flightsBooked,
      final int accommodationBooked,
      final int? flightLockinPct,
      final int? accommodationLockinPct,
      final DateTime? flightDeadline,
      final DateTime? accommodationDeadline}) = _$TripLockinStatusImpl;

  factory _TripLockinStatus.fromJson(Map<String, dynamic> json) =
      _$TripLockinStatusImpl.fromJson;

  @override
  String get tripId;
  @override
  int get squadSize;
  @override
  int get flightsBooked;
  @override
  int get accommodationBooked;
  @override
  int? get flightLockinPct;
  @override
  int? get accommodationLockinPct;
  @override
  DateTime? get flightDeadline;
  @override
  DateTime? get accommodationDeadline;
  @override
  @JsonKey(ignore: true)
  _$$TripLockinStatusImplCopyWith<_$TripLockinStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TripRecommendation _$TripRecommendationFromJson(Map<String, dynamic> json) {
  return _TripRecommendation.fromJson(json);
}

/// @nodoc
mixin _$TripRecommendation {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  RecommendationKind get kind => throw _privateConstructorUsedError;
  int get rank => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get neighborhood => throw _privateConstructorUsedError;
  String? get priceBand => throw _privateConstructorUsedError; // '$' .. '$$$$'
  String? get cuisine => throw _privateConstructorUsedError; // restaurants only
  List<String> get vibeTags => throw _privateConstructorUsedError;
  String? get reason =>
      throw _privateConstructorUsedError; // "why scout picked it" — 1-2 sentences
  int? get dayAnchor =>
      throw _privateConstructorUsedError; // nearest itinerary day_number, nullable
  String? get meal =>
      throw _privateConstructorUsedError; // breakfast | lunch | dinner | late-night | snack
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get mapsUrl =>
      throw _privateConstructorUsedError; // Google Maps deep link, always populated by Edge Fn
  String? get bookingUrl =>
      throw _privateConstructorUsedError; // hotels only — Booking.com search URL
  String? get placeId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TripRecommendationCopyWith<TripRecommendation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripRecommendationCopyWith<$Res> {
  factory $TripRecommendationCopyWith(
          TripRecommendation value, $Res Function(TripRecommendation) then) =
      _$TripRecommendationCopyWithImpl<$Res, TripRecommendation>;
  @useResult
  $Res call(
      {String id,
      String tripId,
      RecommendationKind kind,
      int rank,
      String name,
      String? neighborhood,
      String? priceBand,
      String? cuisine,
      List<String> vibeTags,
      String? reason,
      int? dayAnchor,
      String? meal,
      String? imageUrl,
      String? mapsUrl,
      String? bookingUrl,
      String? placeId,
      DateTime? createdAt});
}

/// @nodoc
class _$TripRecommendationCopyWithImpl<$Res, $Val extends TripRecommendation>
    implements $TripRecommendationCopyWith<$Res> {
  _$TripRecommendationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? kind = null,
    Object? rank = null,
    Object? name = null,
    Object? neighborhood = freezed,
    Object? priceBand = freezed,
    Object? cuisine = freezed,
    Object? vibeTags = null,
    Object? reason = freezed,
    Object? dayAnchor = freezed,
    Object? meal = freezed,
    Object? imageUrl = freezed,
    Object? mapsUrl = freezed,
    Object? bookingUrl = freezed,
    Object? placeId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as RecommendationKind,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      neighborhood: freezed == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      priceBand: freezed == priceBand
          ? _value.priceBand
          : priceBand // ignore: cast_nullable_to_non_nullable
              as String?,
      cuisine: freezed == cuisine
          ? _value.cuisine
          : cuisine // ignore: cast_nullable_to_non_nullable
              as String?,
      vibeTags: null == vibeTags
          ? _value.vibeTags
          : vibeTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      dayAnchor: freezed == dayAnchor
          ? _value.dayAnchor
          : dayAnchor // ignore: cast_nullable_to_non_nullable
              as int?,
      meal: freezed == meal
          ? _value.meal
          : meal // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      mapsUrl: freezed == mapsUrl
          ? _value.mapsUrl
          : mapsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingUrl: freezed == bookingUrl
          ? _value.bookingUrl
          : bookingUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      placeId: freezed == placeId
          ? _value.placeId
          : placeId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripRecommendationImplCopyWith<$Res>
    implements $TripRecommendationCopyWith<$Res> {
  factory _$$TripRecommendationImplCopyWith(_$TripRecommendationImpl value,
          $Res Function(_$TripRecommendationImpl) then) =
      __$$TripRecommendationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tripId,
      RecommendationKind kind,
      int rank,
      String name,
      String? neighborhood,
      String? priceBand,
      String? cuisine,
      List<String> vibeTags,
      String? reason,
      int? dayAnchor,
      String? meal,
      String? imageUrl,
      String? mapsUrl,
      String? bookingUrl,
      String? placeId,
      DateTime? createdAt});
}

/// @nodoc
class __$$TripRecommendationImplCopyWithImpl<$Res>
    extends _$TripRecommendationCopyWithImpl<$Res, _$TripRecommendationImpl>
    implements _$$TripRecommendationImplCopyWith<$Res> {
  __$$TripRecommendationImplCopyWithImpl(_$TripRecommendationImpl _value,
      $Res Function(_$TripRecommendationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? kind = null,
    Object? rank = null,
    Object? name = null,
    Object? neighborhood = freezed,
    Object? priceBand = freezed,
    Object? cuisine = freezed,
    Object? vibeTags = null,
    Object? reason = freezed,
    Object? dayAnchor = freezed,
    Object? meal = freezed,
    Object? imageUrl = freezed,
    Object? mapsUrl = freezed,
    Object? bookingUrl = freezed,
    Object? placeId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$TripRecommendationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as RecommendationKind,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      neighborhood: freezed == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      priceBand: freezed == priceBand
          ? _value.priceBand
          : priceBand // ignore: cast_nullable_to_non_nullable
              as String?,
      cuisine: freezed == cuisine
          ? _value.cuisine
          : cuisine // ignore: cast_nullable_to_non_nullable
              as String?,
      vibeTags: null == vibeTags
          ? _value._vibeTags
          : vibeTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      dayAnchor: freezed == dayAnchor
          ? _value.dayAnchor
          : dayAnchor // ignore: cast_nullable_to_non_nullable
              as int?,
      meal: freezed == meal
          ? _value.meal
          : meal // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      mapsUrl: freezed == mapsUrl
          ? _value.mapsUrl
          : mapsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingUrl: freezed == bookingUrl
          ? _value.bookingUrl
          : bookingUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      placeId: freezed == placeId
          ? _value.placeId
          : placeId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TripRecommendationImpl implements _TripRecommendation {
  const _$TripRecommendationImpl(
      {required this.id,
      required this.tripId,
      required this.kind,
      required this.rank,
      required this.name,
      this.neighborhood,
      this.priceBand,
      this.cuisine,
      final List<String> vibeTags = const [],
      this.reason,
      this.dayAnchor,
      this.meal,
      this.imageUrl,
      this.mapsUrl,
      this.bookingUrl,
      this.placeId,
      this.createdAt})
      : _vibeTags = vibeTags;

  factory _$TripRecommendationImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripRecommendationImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final RecommendationKind kind;
  @override
  final int rank;
  @override
  final String name;
  @override
  final String? neighborhood;
  @override
  final String? priceBand;
// '$' .. '$$$$'
  @override
  final String? cuisine;
// restaurants only
  final List<String> _vibeTags;
// restaurants only
  @override
  @JsonKey()
  List<String> get vibeTags {
    if (_vibeTags is EqualUnmodifiableListView) return _vibeTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_vibeTags);
  }

  @override
  final String? reason;
// "why scout picked it" — 1-2 sentences
  @override
  final int? dayAnchor;
// nearest itinerary day_number, nullable
  @override
  final String? meal;
// breakfast | lunch | dinner | late-night | snack
  @override
  final String? imageUrl;
  @override
  final String? mapsUrl;
// Google Maps deep link, always populated by Edge Fn
  @override
  final String? bookingUrl;
// hotels only — Booking.com search URL
  @override
  final String? placeId;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'TripRecommendation(id: $id, tripId: $tripId, kind: $kind, rank: $rank, name: $name, neighborhood: $neighborhood, priceBand: $priceBand, cuisine: $cuisine, vibeTags: $vibeTags, reason: $reason, dayAnchor: $dayAnchor, meal: $meal, imageUrl: $imageUrl, mapsUrl: $mapsUrl, bookingUrl: $bookingUrl, placeId: $placeId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripRecommendationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.neighborhood, neighborhood) ||
                other.neighborhood == neighborhood) &&
            (identical(other.priceBand, priceBand) ||
                other.priceBand == priceBand) &&
            (identical(other.cuisine, cuisine) || other.cuisine == cuisine) &&
            const DeepCollectionEquality().equals(other._vibeTags, _vibeTags) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.dayAnchor, dayAnchor) ||
                other.dayAnchor == dayAnchor) &&
            (identical(other.meal, meal) || other.meal == meal) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.mapsUrl, mapsUrl) || other.mapsUrl == mapsUrl) &&
            (identical(other.bookingUrl, bookingUrl) ||
                other.bookingUrl == bookingUrl) &&
            (identical(other.placeId, placeId) || other.placeId == placeId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tripId,
      kind,
      rank,
      name,
      neighborhood,
      priceBand,
      cuisine,
      const DeepCollectionEquality().hash(_vibeTags),
      reason,
      dayAnchor,
      meal,
      imageUrl,
      mapsUrl,
      bookingUrl,
      placeId,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripRecommendationImplCopyWith<_$TripRecommendationImpl> get copyWith =>
      __$$TripRecommendationImplCopyWithImpl<_$TripRecommendationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripRecommendationImplToJson(
      this,
    );
  }
}

abstract class _TripRecommendation implements TripRecommendation {
  const factory _TripRecommendation(
      {required final String id,
      required final String tripId,
      required final RecommendationKind kind,
      required final int rank,
      required final String name,
      final String? neighborhood,
      final String? priceBand,
      final String? cuisine,
      final List<String> vibeTags,
      final String? reason,
      final int? dayAnchor,
      final String? meal,
      final String? imageUrl,
      final String? mapsUrl,
      final String? bookingUrl,
      final String? placeId,
      final DateTime? createdAt}) = _$TripRecommendationImpl;

  factory _TripRecommendation.fromJson(Map<String, dynamic> json) =
      _$TripRecommendationImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  RecommendationKind get kind;
  @override
  int get rank;
  @override
  String get name;
  @override
  String? get neighborhood;
  @override
  String? get priceBand;
  @override // '$' .. '$$$$'
  String? get cuisine;
  @override // restaurants only
  List<String> get vibeTags;
  @override
  String? get reason;
  @override // "why scout picked it" — 1-2 sentences
  int? get dayAnchor;
  @override // nearest itinerary day_number, nullable
  String? get meal;
  @override // breakfast | lunch | dinner | late-night | snack
  String? get imageUrl;
  @override
  String? get mapsUrl;
  @override // Google Maps deep link, always populated by Edge Fn
  String? get bookingUrl;
  @override // hotels only — Booking.com search URL
  String? get placeId;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$TripRecommendationImplCopyWith<_$TripRecommendationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
