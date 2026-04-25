// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authStateHash() => r'806f459b72d715a5305aa534787e44e2aa87171e';

/// See also [authState].
@ProviderFor(authState)
final authStateProvider = AutoDisposeStreamProvider<AuthState>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthStateRef = AutoDisposeStreamProviderRef<AuthState>;
String _$currentProfileHash() => r'7568030aa8468e7fc7a235293c82f600314da2cd';

/// See also [currentProfile].
@ProviderFor(currentProfile)
final currentProfileProvider = AutoDisposeFutureProvider<AppUser?>.internal(
  currentProfile,
  name: r'currentProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentProfileRef = AutoDisposeFutureProviderRef<AppUser?>;
String _$myTripsHash() => r'6f54ed90c5018b233da594fd4555648d388242ac';

/// See also [myTrips].
@ProviderFor(myTrips)
final myTripsProvider = AutoDisposeFutureProvider<List<Trip>>.internal(
  myTrips,
  name: r'myTripsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myTripsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyTripsRef = AutoDisposeFutureProviderRef<List<Trip>>;
String _$tripDetailHash() => r'3f8823f6365431d6b26ead7c7530b17f96bb9656';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [tripDetail].
@ProviderFor(tripDetail)
const tripDetailProvider = TripDetailFamily();

/// See also [tripDetail].
class TripDetailFamily extends Family<AsyncValue<Trip>> {
  /// See also [tripDetail].
  const TripDetailFamily();

  /// See also [tripDetail].
  TripDetailProvider call(
    String tripId,
  ) {
    return TripDetailProvider(
      tripId,
    );
  }

  @override
  TripDetailProvider getProviderOverride(
    covariant TripDetailProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tripDetailProvider';
}

/// See also [tripDetail].
class TripDetailProvider extends AutoDisposeFutureProvider<Trip> {
  /// See also [tripDetail].
  TripDetailProvider(
    String tripId,
  ) : this._internal(
          (ref) => tripDetail(
            ref as TripDetailRef,
            tripId,
          ),
          from: tripDetailProvider,
          name: r'tripDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tripDetailHash,
          dependencies: TripDetailFamily._dependencies,
          allTransitiveDependencies:
              TripDetailFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  TripDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    FutureOr<Trip> Function(TripDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TripDetailProvider._internal(
        (ref) => create(ref as TripDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Trip> createElement() {
    return _TripDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TripDetailProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TripDetailRef on AutoDisposeFutureProviderRef<Trip> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _TripDetailProviderElement extends AutoDisposeFutureProviderElement<Trip>
    with TripDetailRef {
  _TripDetailProviderElement(super.provider);

  @override
  String get tripId => (origin as TripDetailProvider).tripId;
}

String _$tripStreamHash() => r'0ef0902004fa2fa7b1dca66e2bc741804ec555fc';

/// See also [tripStream].
@ProviderFor(tripStream)
const tripStreamProvider = TripStreamFamily();

/// See also [tripStream].
class TripStreamFamily extends Family<AsyncValue<Trip>> {
  /// See also [tripStream].
  const TripStreamFamily();

  /// See also [tripStream].
  TripStreamProvider call(
    String tripId,
  ) {
    return TripStreamProvider(
      tripId,
    );
  }

  @override
  TripStreamProvider getProviderOverride(
    covariant TripStreamProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tripStreamProvider';
}

/// See also [tripStream].
class TripStreamProvider extends AutoDisposeStreamProvider<Trip> {
  /// See also [tripStream].
  TripStreamProvider(
    String tripId,
  ) : this._internal(
          (ref) => tripStream(
            ref as TripStreamRef,
            tripId,
          ),
          from: tripStreamProvider,
          name: r'tripStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tripStreamHash,
          dependencies: TripStreamFamily._dependencies,
          allTransitiveDependencies:
              TripStreamFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  TripStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    Stream<Trip> Function(TripStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TripStreamProvider._internal(
        (ref) => create(ref as TripStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Trip> createElement() {
    return _TripStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TripStreamProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TripStreamRef on AutoDisposeStreamProviderRef<Trip> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _TripStreamProviderElement extends AutoDisposeStreamProviderElement<Trip>
    with TripStreamRef {
  _TripStreamProviderElement(super.provider);

  @override
  String get tripId => (origin as TripStreamProvider).tripId;
}

String _$squadStreamHash() => r'0337b51bec07df2693567d88ed56286af0d5352f';

/// See also [squadStream].
@ProviderFor(squadStream)
const squadStreamProvider = SquadStreamFamily();

/// See also [squadStream].
class SquadStreamFamily extends Family<AsyncValue<List<SquadMember>>> {
  /// See also [squadStream].
  const SquadStreamFamily();

  /// See also [squadStream].
  SquadStreamProvider call(
    String tripId,
  ) {
    return SquadStreamProvider(
      tripId,
    );
  }

  @override
  SquadStreamProvider getProviderOverride(
    covariant SquadStreamProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'squadStreamProvider';
}

/// See also [squadStream].
class SquadStreamProvider extends AutoDisposeStreamProvider<List<SquadMember>> {
  /// See also [squadStream].
  SquadStreamProvider(
    String tripId,
  ) : this._internal(
          (ref) => squadStream(
            ref as SquadStreamRef,
            tripId,
          ),
          from: squadStreamProvider,
          name: r'squadStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$squadStreamHash,
          dependencies: SquadStreamFamily._dependencies,
          allTransitiveDependencies:
              SquadStreamFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  SquadStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    Stream<List<SquadMember>> Function(SquadStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SquadStreamProvider._internal(
        (ref) => create(ref as SquadStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SquadMember>> createElement() {
    return _SquadStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SquadStreamProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SquadStreamRef on AutoDisposeStreamProviderRef<List<SquadMember>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _SquadStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<SquadMember>>
    with SquadStreamRef {
  _SquadStreamProviderElement(super.provider);

  @override
  String get tripId => (origin as SquadStreamProvider).tripId;
}

String _$myNotificationsHash() => r'53a255ccbbf3db476184ddf388700ead5fc12ef3';

/// See also [myNotifications].
@ProviderFor(myNotifications)
final myNotificationsProvider =
    AutoDisposeStreamProvider<List<NotificationItem>>.internal(
  myNotifications,
  name: r'myNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyNotificationsRef
    = AutoDisposeStreamProviderRef<List<NotificationItem>>;
String _$unreadNotifCountHash() => r'f0c1de9e2783e51cda4255d7c5423130f891686c';

/// See also [unreadNotifCount].
@ProviderFor(unreadNotifCount)
final unreadNotifCountProvider = AutoDisposeStreamProvider<int>.internal(
  unreadNotifCount,
  name: r'unreadNotifCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotifCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UnreadNotifCountRef = AutoDisposeStreamProviderRef<int>;
String _$tripEventsStreamHash() => r'7ccaa35f91426652651d609b4f62ec8b6e2053af';

/// See also [tripEventsStream].
@ProviderFor(tripEventsStream)
const tripEventsStreamProvider = TripEventsStreamFamily();

/// See also [tripEventsStream].
class TripEventsStreamFamily extends Family<AsyncValue<List<TripEvent>>> {
  /// See also [tripEventsStream].
  const TripEventsStreamFamily();

  /// See also [tripEventsStream].
  TripEventsStreamProvider call(
    String tripId,
  ) {
    return TripEventsStreamProvider(
      tripId,
    );
  }

  @override
  TripEventsStreamProvider getProviderOverride(
    covariant TripEventsStreamProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tripEventsStreamProvider';
}

/// See also [tripEventsStream].
class TripEventsStreamProvider
    extends AutoDisposeStreamProvider<List<TripEvent>> {
  /// See also [tripEventsStream].
  TripEventsStreamProvider(
    String tripId,
  ) : this._internal(
          (ref) => tripEventsStream(
            ref as TripEventsStreamRef,
            tripId,
          ),
          from: tripEventsStreamProvider,
          name: r'tripEventsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tripEventsStreamHash,
          dependencies: TripEventsStreamFamily._dependencies,
          allTransitiveDependencies:
              TripEventsStreamFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  TripEventsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    Stream<List<TripEvent>> Function(TripEventsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TripEventsStreamProvider._internal(
        (ref) => create(ref as TripEventsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<TripEvent>> createElement() {
    return _TripEventsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TripEventsStreamProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TripEventsStreamRef on AutoDisposeStreamProviderRef<List<TripEvent>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _TripEventsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<TripEvent>>
    with TripEventsStreamRef {
  _TripEventsStreamProviderElement(super.provider);

  @override
  String get tripId => (origin as TripEventsStreamProvider).tripId;
}

String _$myRecentActivityHash() => r'0d40e4916cd91423b579855f5c1da36dd0216ef1';

/// Activity ticker for Home — recent events across all of a user's trips.
///
/// Copied from [myRecentActivity].
@ProviderFor(myRecentActivity)
final myRecentActivityProvider =
    AutoDisposeFutureProvider<List<TripEvent>>.internal(
  myRecentActivity,
  name: r'myRecentActivityProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myRecentActivityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyRecentActivityRef = AutoDisposeFutureProviderRef<List<TripEvent>>;
String _$myDmsHash() => r'713f523c7fc247ec9dfa0d75dfbaf9e1d15f5304';

/// See also [myDms].
@ProviderFor(myDms)
final myDmsProvider = AutoDisposeStreamProvider<List<DirectMessage>>.internal(
  myDms,
  name: r'myDmsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myDmsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyDmsRef = AutoDisposeStreamProviderRef<List<DirectMessage>>;
String _$dmThreadHash() => r'4085ae7f804c3a7486923b85a5ccbb61394ec83e';

/// See also [dmThread].
@ProviderFor(dmThread)
const dmThreadProvider = DmThreadFamily();

/// See also [dmThread].
class DmThreadFamily extends Family<AsyncValue<List<DirectMessage>>> {
  /// See also [dmThread].
  const DmThreadFamily();

  /// See also [dmThread].
  DmThreadProvider call(
    String otherUserId,
  ) {
    return DmThreadProvider(
      otherUserId,
    );
  }

  @override
  DmThreadProvider getProviderOverride(
    covariant DmThreadProvider provider,
  ) {
    return call(
      provider.otherUserId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dmThreadProvider';
}

/// See also [dmThread].
class DmThreadProvider extends AutoDisposeStreamProvider<List<DirectMessage>> {
  /// See also [dmThread].
  DmThreadProvider(
    String otherUserId,
  ) : this._internal(
          (ref) => dmThread(
            ref as DmThreadRef,
            otherUserId,
          ),
          from: dmThreadProvider,
          name: r'dmThreadProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dmThreadHash,
          dependencies: DmThreadFamily._dependencies,
          allTransitiveDependencies: DmThreadFamily._allTransitiveDependencies,
          otherUserId: otherUserId,
        );

  DmThreadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherUserId,
  }) : super.internal();

  final String otherUserId;

  @override
  Override overrideWith(
    Stream<List<DirectMessage>> Function(DmThreadRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DmThreadProvider._internal(
        (ref) => create(ref as DmThreadRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherUserId: otherUserId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<DirectMessage>> createElement() {
    return _DmThreadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DmThreadProvider && other.otherUserId == otherUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DmThreadRef on AutoDisposeStreamProviderRef<List<DirectMessage>> {
  /// The parameter `otherUserId` of this provider.
  String get otherUserId;
}

class _DmThreadProviderElement
    extends AutoDisposeStreamProviderElement<List<DirectMessage>>
    with DmThreadRef {
  _DmThreadProviderElement(super.provider);

  @override
  String get otherUserId => (origin as DmThreadProvider).otherUserId;
}

String _$dmThreadReactionsHash() => r'32b4917ab6600ddd3b7926da1f239da7f1e6d060';

/// Reactions on DMs in the current user's thread with [otherUserId].
/// Returned flat; filter by message_id at render time. Migration 018.
///
/// Copied from [dmThreadReactions].
@ProviderFor(dmThreadReactions)
const dmThreadReactionsProvider = DmThreadReactionsFamily();

/// Reactions on DMs in the current user's thread with [otherUserId].
/// Returned flat; filter by message_id at render time. Migration 018.
///
/// Copied from [dmThreadReactions].
class DmThreadReactionsFamily extends Family<AsyncValue<List<DmReaction>>> {
  /// Reactions on DMs in the current user's thread with [otherUserId].
  /// Returned flat; filter by message_id at render time. Migration 018.
  ///
  /// Copied from [dmThreadReactions].
  const DmThreadReactionsFamily();

  /// Reactions on DMs in the current user's thread with [otherUserId].
  /// Returned flat; filter by message_id at render time. Migration 018.
  ///
  /// Copied from [dmThreadReactions].
  DmThreadReactionsProvider call(
    String otherUserId,
  ) {
    return DmThreadReactionsProvider(
      otherUserId,
    );
  }

  @override
  DmThreadReactionsProvider getProviderOverride(
    covariant DmThreadReactionsProvider provider,
  ) {
    return call(
      provider.otherUserId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dmThreadReactionsProvider';
}

/// Reactions on DMs in the current user's thread with [otherUserId].
/// Returned flat; filter by message_id at render time. Migration 018.
///
/// Copied from [dmThreadReactions].
class DmThreadReactionsProvider
    extends AutoDisposeStreamProvider<List<DmReaction>> {
  /// Reactions on DMs in the current user's thread with [otherUserId].
  /// Returned flat; filter by message_id at render time. Migration 018.
  ///
  /// Copied from [dmThreadReactions].
  DmThreadReactionsProvider(
    String otherUserId,
  ) : this._internal(
          (ref) => dmThreadReactions(
            ref as DmThreadReactionsRef,
            otherUserId,
          ),
          from: dmThreadReactionsProvider,
          name: r'dmThreadReactionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dmThreadReactionsHash,
          dependencies: DmThreadReactionsFamily._dependencies,
          allTransitiveDependencies:
              DmThreadReactionsFamily._allTransitiveDependencies,
          otherUserId: otherUserId,
        );

  DmThreadReactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherUserId,
  }) : super.internal();

  final String otherUserId;

  @override
  Override overrideWith(
    Stream<List<DmReaction>> Function(DmThreadReactionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DmThreadReactionsProvider._internal(
        (ref) => create(ref as DmThreadReactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherUserId: otherUserId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<DmReaction>> createElement() {
    return _DmThreadReactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DmThreadReactionsProvider &&
        other.otherUserId == otherUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DmThreadReactionsRef on AutoDisposeStreamProviderRef<List<DmReaction>> {
  /// The parameter `otherUserId` of this provider.
  String get otherUserId;
}

class _DmThreadReactionsProviderElement
    extends AutoDisposeStreamProviderElement<List<DmReaction>>
    with DmThreadReactionsRef {
  _DmThreadReactionsProviderElement(super.provider);

  @override
  String get otherUserId => (origin as DmThreadReactionsProvider).otherUserId;
}

String _$scoutHistoryHash() => r'bd0c34ade9344fca95c6a601a93230bf4b8bed84';

/// See also [scoutHistory].
@ProviderFor(scoutHistory)
final scoutHistoryProvider =
    AutoDisposeStreamProvider<List<ScoutMessage>>.internal(
  scoutHistory,
  name: r'scoutHistoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scoutHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ScoutHistoryRef = AutoDisposeStreamProviderRef<List<ScoutMessage>>;
String _$scoutStreakHash() => r'892f6a371a2483b9aea6c9e9ea8869ebec37ee85';

/// Consecutive-day streak of Scout engagement. Counts back from today
/// (or yesterday if today has no user message yet) — the streak is the
/// longest unbroken run of days on which the user sent ≥1 message to
/// Scout. Used to render a streak pill in the Scout tab header.
///
/// Copied from [scoutStreak].
@ProviderFor(scoutStreak)
final scoutStreakProvider = AutoDisposeFutureProvider<int>.internal(
  scoutStreak,
  name: r'scoutStreakProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scoutStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ScoutStreakRef = AutoDisposeFutureProviderRef<int>;
String _$squadAvatarsHash() => r'f1e5a5ca057513d26fcb8c13ca6aae381564cbcd';

/// Map of user_id → avatar_url for every squad member across my trips.
/// Cached until `myTrips` changes. Used to render photo avatars on trip
/// cards (Home + Trips tab).
///
/// Copied from [squadAvatars].
@ProviderFor(squadAvatars)
final squadAvatarsProvider =
    AutoDisposeFutureProvider<Map<String, String?>>.internal(
  squadAvatars,
  name: r'squadAvatarsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$squadAvatarsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SquadAvatarsRef = AutoDisposeFutureProviderRef<Map<String, String?>>;
String _$packingItemsHash() => r'5cd4b6e1ef0fa22a8fdcd6d07dad731e576f3804';

/// See also [packingItems].
@ProviderFor(packingItems)
const packingItemsProvider = PackingItemsFamily();

/// See also [packingItems].
class PackingItemsFamily extends Family<AsyncValue<List<PackingEntry>>> {
  /// See also [packingItems].
  const PackingItemsFamily();

  /// See also [packingItems].
  PackingItemsProvider call(
    String tripId,
  ) {
    return PackingItemsProvider(
      tripId,
    );
  }

  @override
  PackingItemsProvider getProviderOverride(
    covariant PackingItemsProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'packingItemsProvider';
}

/// See also [packingItems].
class PackingItemsProvider
    extends AutoDisposeStreamProvider<List<PackingEntry>> {
  /// See also [packingItems].
  PackingItemsProvider(
    String tripId,
  ) : this._internal(
          (ref) => packingItems(
            ref as PackingItemsRef,
            tripId,
          ),
          from: packingItemsProvider,
          name: r'packingItemsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$packingItemsHash,
          dependencies: PackingItemsFamily._dependencies,
          allTransitiveDependencies:
              PackingItemsFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  PackingItemsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    Stream<List<PackingEntry>> Function(PackingItemsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PackingItemsProvider._internal(
        (ref) => create(ref as PackingItemsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PackingEntry>> createElement() {
    return _PackingItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PackingItemsProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PackingItemsRef on AutoDisposeStreamProviderRef<List<PackingEntry>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _PackingItemsProviderElement
    extends AutoDisposeStreamProviderElement<List<PackingEntry>>
    with PackingItemsRef {
  _PackingItemsProviderElement(super.provider);

  @override
  String get tripId => (origin as PackingItemsProvider).tripId;
}

String _$chatMessagesHash() => r'96ac8210e2c836cad136a645b66ac817c7a51405';

/// See also [chatMessages].
@ProviderFor(chatMessages)
const chatMessagesProvider = ChatMessagesFamily();

/// See also [chatMessages].
class ChatMessagesFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [chatMessages].
  const ChatMessagesFamily();

  /// See also [chatMessages].
  ChatMessagesProvider call(
    String tripId,
  ) {
    return ChatMessagesProvider(
      tripId,
    );
  }

  @override
  ChatMessagesProvider getProviderOverride(
    covariant ChatMessagesProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatMessagesProvider';
}

/// See also [chatMessages].
class ChatMessagesProvider
    extends AutoDisposeStreamProvider<List<ChatMessage>> {
  /// See also [chatMessages].
  ChatMessagesProvider(
    String tripId,
  ) : this._internal(
          (ref) => chatMessages(
            ref as ChatMessagesRef,
            tripId,
          ),
          from: chatMessagesProvider,
          name: r'chatMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatMessagesHash,
          dependencies: ChatMessagesFamily._dependencies,
          allTransitiveDependencies:
              ChatMessagesFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  ChatMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    Stream<List<ChatMessage>> Function(ChatMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatMessagesProvider._internal(
        (ref) => create(ref as ChatMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ChatMessage>> createElement() {
    return _ChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChatMessagesRef on AutoDisposeStreamProviderRef<List<ChatMessage>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _ChatMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessage>>
    with ChatMessagesRef {
  _ChatMessagesProviderElement(super.provider);

  @override
  String get tripId => (origin as ChatMessagesProvider).tripId;
}

String _$chatReactionsHash() => r'c6f9f8ebbdcb586a398e42406309a11ad0ae6620';

/// See also [chatReactions].
@ProviderFor(chatReactions)
const chatReactionsProvider = ChatReactionsFamily();

/// See also [chatReactions].
class ChatReactionsFamily extends Family<AsyncValue<List<ChatReaction>>> {
  /// See also [chatReactions].
  const ChatReactionsFamily();

  /// See also [chatReactions].
  ChatReactionsProvider call(
    String tripId,
  ) {
    return ChatReactionsProvider(
      tripId,
    );
  }

  @override
  ChatReactionsProvider getProviderOverride(
    covariant ChatReactionsProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatReactionsProvider';
}

/// See also [chatReactions].
class ChatReactionsProvider
    extends AutoDisposeStreamProvider<List<ChatReaction>> {
  /// See also [chatReactions].
  ChatReactionsProvider(
    String tripId,
  ) : this._internal(
          (ref) => chatReactions(
            ref as ChatReactionsRef,
            tripId,
          ),
          from: chatReactionsProvider,
          name: r'chatReactionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatReactionsHash,
          dependencies: ChatReactionsFamily._dependencies,
          allTransitiveDependencies:
              ChatReactionsFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  ChatReactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    Stream<List<ChatReaction>> Function(ChatReactionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatReactionsProvider._internal(
        (ref) => create(ref as ChatReactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ChatReaction>> createElement() {
    return _ChatReactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatReactionsProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChatReactionsRef on AutoDisposeStreamProviderRef<List<ChatReaction>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _ChatReactionsProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatReaction>>
    with ChatReactionsRef {
  _ChatReactionsProviderElement(super.provider);

  @override
  String get tripId => (origin as ChatReactionsProvider).tripId;
}

String _$itineraryStreamHash() => r'a2eee1f937ade03d96fef101ae8ebce91136dd2f';

/// See also [itineraryStream].
@ProviderFor(itineraryStream)
const itineraryStreamProvider = ItineraryStreamFamily();

/// See also [itineraryStream].
class ItineraryStreamFamily
    extends Family<AsyncValue<List<ItineraryActivity>>> {
  /// See also [itineraryStream].
  const ItineraryStreamFamily();

  /// See also [itineraryStream].
  ItineraryStreamProvider call(
    String tripId,
  ) {
    return ItineraryStreamProvider(
      tripId,
    );
  }

  @override
  ItineraryStreamProvider getProviderOverride(
    covariant ItineraryStreamProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'itineraryStreamProvider';
}

/// See also [itineraryStream].
class ItineraryStreamProvider
    extends AutoDisposeStreamProvider<List<ItineraryActivity>> {
  /// See also [itineraryStream].
  ItineraryStreamProvider(
    String tripId,
  ) : this._internal(
          (ref) => itineraryStream(
            ref as ItineraryStreamRef,
            tripId,
          ),
          from: itineraryStreamProvider,
          name: r'itineraryStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$itineraryStreamHash,
          dependencies: ItineraryStreamFamily._dependencies,
          allTransitiveDependencies:
              ItineraryStreamFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  ItineraryStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    Stream<List<ItineraryActivity>> Function(ItineraryStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ItineraryStreamProvider._internal(
        (ref) => create(ref as ItineraryStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ItineraryActivity>> createElement() {
    return _ItineraryStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ItineraryStreamProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ItineraryStreamRef
    on AutoDisposeStreamProviderRef<List<ItineraryActivity>> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _ItineraryStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<ItineraryActivity>>
    with ItineraryStreamRef {
  _ItineraryStreamProviderElement(super.provider);

  @override
  String get tripId => (origin as ItineraryStreamProvider).tripId;
}

String _$itineraryNotesStreamHash() =>
    r'c1d86457a6043a4afdbb4c555cfb35651e7edf67';

/// See also [itineraryNotesStream].
@ProviderFor(itineraryNotesStream)
const itineraryNotesStreamProvider = ItineraryNotesStreamFamily();

/// See also [itineraryNotesStream].
class ItineraryNotesStreamFamily
    extends Family<AsyncValue<List<ItineraryNote>>> {
  /// See also [itineraryNotesStream].
  const ItineraryNotesStreamFamily();

  /// See also [itineraryNotesStream].
  ItineraryNotesStreamProvider call(
    String itemId,
  ) {
    return ItineraryNotesStreamProvider(
      itemId,
    );
  }

  @override
  ItineraryNotesStreamProvider getProviderOverride(
    covariant ItineraryNotesStreamProvider provider,
  ) {
    return call(
      provider.itemId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'itineraryNotesStreamProvider';
}

/// See also [itineraryNotesStream].
class ItineraryNotesStreamProvider
    extends AutoDisposeStreamProvider<List<ItineraryNote>> {
  /// See also [itineraryNotesStream].
  ItineraryNotesStreamProvider(
    String itemId,
  ) : this._internal(
          (ref) => itineraryNotesStream(
            ref as ItineraryNotesStreamRef,
            itemId,
          ),
          from: itineraryNotesStreamProvider,
          name: r'itineraryNotesStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$itineraryNotesStreamHash,
          dependencies: ItineraryNotesStreamFamily._dependencies,
          allTransitiveDependencies:
              ItineraryNotesStreamFamily._allTransitiveDependencies,
          itemId: itemId,
        );

  ItineraryNotesStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.itemId,
  }) : super.internal();

  final String itemId;

  @override
  Override overrideWith(
    Stream<List<ItineraryNote>> Function(ItineraryNotesStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ItineraryNotesStreamProvider._internal(
        (ref) => create(ref as ItineraryNotesStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        itemId: itemId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ItineraryNote>> createElement() {
    return _ItineraryNotesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ItineraryNotesStreamProvider && other.itemId == itemId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ItineraryNotesStreamRef
    on AutoDisposeStreamProviderRef<List<ItineraryNote>> {
  /// The parameter `itemId` of this provider.
  String get itemId;
}

class _ItineraryNotesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<ItineraryNote>>
    with ItineraryNotesStreamRef {
  _ItineraryNotesStreamProviderElement(super.provider);

  @override
  String get itemId => (origin as ItineraryNotesStreamProvider).itemId;
}

String _$tripCreationHash() => r'bdfe9343e9dde95de4431c21c0a85ff32704a548';

/// See also [TripCreation].
@ProviderFor(TripCreation)
final tripCreationProvider =
    AutoDisposeNotifierProvider<TripCreation, TripCreationState>.internal(
  TripCreation.new,
  name: r'tripCreationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tripCreationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TripCreation = AutoDisposeNotifier<TripCreationState>;
String _$aIGenerationHash() => r'28cee490df237849a91f60cf46a0e7792452a330';

/// See also [AIGeneration].
@ProviderFor(AIGeneration)
final aIGenerationProvider =
    NotifierProvider<AIGeneration, AIGenState>.internal(
  AIGeneration.new,
  name: r'aIGenerationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$aIGenerationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AIGeneration = Notifier<AIGenState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
