import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

final supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

// ─────────────────────────────────────────────────────────────
//  AUTH SERVICE
// ─────────────────────────────────────────────────────────────
final authServiceProvider = Provider((ref) => AuthService(ref.read(supabaseProvider)));

class AuthService {
  AuthService(this._db);
  final SupabaseClient _db;

  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;
  User? get currentUser => _db.auth.currentUser;
  bool get isLoggedIn   => currentUser != null;

  /// Native Sign in with Apple — App Store compliant. Generates a
  /// cryptographic nonce, shows the native Apple sheet, and exchanges
  /// the resulting identity token with Supabase via [signInWithIdToken].
  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce =
        sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple did not return an identity token');
    }

    return _db.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// Native Google Sign In — shows the iOS-native Google sheet branded
  /// with TripSquad (not supabase.co). Gets an ID token from Google and
  /// exchanges it with Supabase via [signInWithIdToken]. Requires the
  /// iOS OAuth client ID from Google Cloud Console + the web Client ID
  /// that Supabase's Google provider was configured with.
  Future<AuthResponse> signInWithGoogle() async {
    const webClientId =
        '65690442383-363v4bpgm3q2njisj5cfvkr6btg1ahgi.apps.googleusercontent.com';
    const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

    final googleSignIn = GoogleSignIn(
      clientId: iosClientId.isEmpty ? null : iosClientId,
      serverClientId: webClientId,
    );
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if (idToken == null) {
      throw Exception('Google did not return an ID token');
    }

    return _db.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  String _generateNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      _db.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail(String email, String password) =>
      _db.auth.signUp(email: email, password: password);

  Future<void> signOut() => _db.auth.signOut(scope: SignOutScope.local);

  Future<AppUser?> fetchCurrentProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final data = await _db.from('profiles').select().eq('id', uid).maybeSingle();
    if (data == null) return null;
    return AppUser.fromJson(snakeToCamel(data));
  }

  // ── Update any profile fields ──────────────────────────────
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    fields['updated_at'] = DateTime.now().toIso8601String();
    await _db.from('profiles').update(fields).eq('id', uid);
  }

  // ── Check tag availability ────────────────────────────────
  Future<bool> checkTagAvailability(String tag) async {
    final uid = currentUser?.id;
    final data = await _db
        .from('profiles')
        .select('id')
        .eq('tag', tag.toLowerCase())
        .limit(1);
    final results = data as List;
    // Available if no results, or the only result is the current user
    return results.isEmpty || (results.length == 1 && results[0]['id'] == uid);
  }

  // ── Change tag handle (30-day rule) ───────────────────────
  Future<({bool success, String? error})> changeTag(String newTag) async {
    final uid = currentUser?.id;
    if (uid == null) return (success: false, error: 'not logged in');

    // Check 30-day restriction
    final profile = await _db.from('profiles')
        .select('tag, last_handle_change')
        .eq('id', uid)
        .single();

    final lastChange = profile['last_handle_change'] != null
        ? DateTime.parse(profile['last_handle_change'])
        : null;

    if (lastChange != null) {
      final daysSince = DateTime.now().difference(lastChange).inDays;
      if (daysSince < 30) {
        final daysLeft = 30 - daysSince;
        return (success: false, error: 'next change in $daysLeft days');
      }
    }

    // Check availability
    final available = await checkTagAvailability(newTag);
    if (!available) return (success: false, error: 'tag is taken');

    // Record history
    final oldTag = profile['tag'] as String?;
    if (oldTag != null && oldTag.isNotEmpty) {
      await _db.from('handle_history').insert({
        'user_id': uid,
        'old_handle': oldTag,
        'new_handle': newTag.toLowerCase(),
      });
    }

    // Update profile
    await _db.from('profiles').update({
      'tag': newTag.toLowerCase(),
      'last_handle_change': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);

    return (success: true, error: null);
  }

  // ── Update privacy level ──────────────────────────────────
  Future<void> updatePrivacy(String level) async {
    await updateProfile({'privacy_level': level});
  }

  Future<void> upsertProfile({required String nickname, required String emoji}) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _db.from('profiles').upsert({
      'id': uid,
      'nickname': nickname,
      'emoji': emoji,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  TRIP SERVICE
// ─────────────────────────────────────────────────────────────
final tripServiceProvider = Provider((ref) => TripService(ref.read(supabaseProvider)));

/// Convert snake_case database keys to camelCase for Freezed models
Map<String, dynamic> snakeToCamel(Map<String, dynamic> m) {
  return m.map((key, value) {
    final camel = key.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
    if (value is Map<String, dynamic>) return MapEntry(camel, snakeToCamel(value));
    if (value is List) {
      return MapEntry(camel, value.map((e) => e is Map<String, dynamic> ? snakeToCamel(e) : e).toList());
    }
    return MapEntry(camel, value);
  });
}

class TripService {
  TripService(this._db);
  final SupabaseClient _db;

  // ── Create ─────────────────────────────────────────────────
  Future<Trip> createTrip({
    required String name,
    required TripMode mode,
    required List<String> vibes,
    DateTime? startDate,
    DateTime? endDate,
    int? budgetPerPerson,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final token = _generateToken();

    final data = await _db.from('trips').insert({
      'host_id':      uid,
      'name':         name,
      'mode':         mode.name,
      'status':       TripStatus.collecting.name,
      'estimated_budget': budgetPerPerson,
      'vibes':        vibes,
      'invite_token': token,
      'start_date':   startDate?.toIso8601String(),
      'end_date':     endDate?.toIso8601String(),
    }).select().single();

    // Look up the host's actual nickname so other squad members see
    // a real name, not the literal placeholder "You (Host)" — that
    // string showed up as a second "you" on everyone else's screen
    // and as "You (Host) (you) · host" on the host's own screen.
    // The "(you)" suffix and "· host" tag are added at render time
    // by squad_tab.
    final hostProfile = await _db
        .from('profiles')
        .select('nickname, emoji')
        .eq('id', uid)
        .maybeSingle();
    final hostNickname =
        (hostProfile?['nickname'] as String?)?.trim().isNotEmpty == true
            ? hostProfile!['nickname'] as String
            : 'host';
    final hostEmoji = hostProfile?['emoji'] as String?;

    await _db.from('squad_members').insert({
      'trip_id':   data['id'],
      'user_id':   uid,
      'role':      MemberRole.host.name,
      'status':    MemberStatus.submitted.name,
      'nickname':  hostNickname,
      if (hostEmoji != null) 'emoji': hostEmoji,
    });

    return Trip.fromJson(snakeToCamel(data));
  }

  // ── Fetch all trips for current user ──────────────────────
  // Returns both trips the user hosts AND trips they were added to
  // as a squad member. Since createTrip() auto-inserts the host as
  // a squad_members row, one query via squad_members covers both.
  Future<List<Trip>> fetchMyTrips() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _db
        .from('squad_members')
        .select('trips!inner(*, squad_members(*), trip_options(*))')
        .eq('user_id', uid);

    final trips = <Trip>[];
    final seen = <String>{};
    for (final row in (data as List)) {
      final t = row['trips'] as Map<String, dynamic>?;
      if (t == null) continue;
      final id = t['id'] as String;
      if (seen.contains(id)) continue;
      seen.add(id);
      final camel = snakeToCamel(t);
      if (camel.containsKey('tripOptions')) {
        camel['options'] = camel.remove('tripOptions');
      }
      trips.add(Trip.fromJson(camel));
    }
    trips.sort((a, b) {
      final aT = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bT = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bT.compareTo(aT);
    });
    return trips;
  }

  // ── Fetch single trip with all relations ──────────────────
  Future<Trip> fetchTrip(String tripId) async {
    final data = await _db
        .from('trips')
        .select('*, squad_members(*), trip_options(*)')
        .eq('id', tripId)
        .single();
    final camel = snakeToCamel(data);
    // Remap Supabase relation names to model field names
    if (camel.containsKey('tripOptions')) {
      camel['options'] = camel.remove('tripOptions');
    }
    return Trip.fromJson(camel);
  }

  // ── Real-time trip stream ─────────────────────────────────
  Stream<Trip> watchTrip(String tripId) {
    return _db
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((rows) => Trip.fromJson(snakeToCamel(rows.first)));
  }

  // ── Real-time squad members ───────────────────────────────
  Stream<List<SquadMember>> watchSquad(String tripId) {
    return _db
        .from('squad_members')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .map((rows) => rows.map((e) => SquadMember.fromJson(snakeToCamel(e))).toList());
  }

  // ── Add destinations to shortlist ────────────────────────
  Future<void> updateDestinations(String tripId, List<String> destinations) async {
    await _db.from('trips').update({
      'destination_shortlist': destinations,
    }).eq('id', tripId);
  }

  /// Host-only date edit. Either bound can be null (e.g. a trip
  /// with no end date yet). The RLS policy on `trips` already
  /// restricts updates to the host.
  Future<void> updateDates({
    required String tripId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _db.from('trips').update({
      'start_date': startDate?.toIso8601String(),
      'end_date':   endDate?.toIso8601String(),
    }).eq('id', tripId);
  }

  /// Host-only name edit. Trims + rejects empty. RLS on `trips`
  /// already restricts updates to the host.
  Future<void> updateName({
    required String tripId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('name can\'t be empty');
    await _db.from('trips').update({
      'name': trimmed,
    }).eq('id', tripId);
  }

  /// Upload a host-chosen cover photo to the `avatars` bucket and
  /// save the public URL on the trip row. Returns the public URL.
  ///
  /// The path MUST start with the uploader's auth uid — the bucket's
  /// storage RLS policy only permits inserts where
  /// `(storage.foldername(name))[1] = auth.uid()::text`. We put the
  /// trip id in a subfolder so each host can have one cover per
  /// trip without colliding with their own avatar file.
  Future<String> uploadCoverPhoto({
    required String tripId,
    required String filePath,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');
    var ext = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : 'jpg';
    if (ext == 'jpeg') ext = 'jpg';
    final mime = switch (ext) {
      'png'  => 'image/png',
      'webp' => 'image/webp',
      _      => 'image/jpeg',
    };
    final objectPath = '$uid/trip_covers/$tripId.$ext';
    final bytes = await _readFile(filePath);
    await _db.storage.from('avatars').uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mime),
        );
    final url = _db.storage.from('avatars').getPublicUrl(objectPath);
    // Cache-bust so the trip card refreshes even when re-uploading.
    final busted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    await _db.from('trips').update({
      'cover_photo_url': busted,
    }).eq('id', tripId);
    return busted;
  }

  /// Clear the cover photo override so the trip falls back to the
  /// destination-hint image again.
  Future<void> clearCoverPhoto(String tripId) async {
    await _db.from('trips').update({
      'cover_photo_url': null,
    }).eq('id', tripId);
  }

  /// Reuse an existing public URL as the cover — e.g. a photo
  /// already uploaded to trip chat. Skips the upload step and
  /// cache-busts so trip cards refresh.
  Future<void> setCoverFromUrl({
    required String tripId,
    required String url,
  }) async {
    final busted =
        '$url${url.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';
    await _db.from('trips').update({
      'cover_photo_url': busted,
    }).eq('id', tripId);
  }

  Future<Uint8List> _readFile(String path) async {
    final f = File(path);
    return f.readAsBytes();
  }

  /// Host-only member removal. The `squad_members` RLS policy
  /// already restricts deletes to the trip host. Also clears any
  /// existing votes from that member on this trip so vote tallies
  /// stay honest.
  Future<void> removeMember({
    required String memberId,
    required String tripId,
    String? userId,
  }) async {
    if (userId != null) {
      await _db
          .from('votes')
          .delete()
          .eq('trip_id', tripId)
          .eq('user_id', userId);
    }
    await _db.from('squad_members').delete().eq('id', memberId);
  }

  // ── Submit squad form (called from web invite form) ───────
  Future<void> submitSquadForm({
    required String token,
    required String nickname,
    required String emoji,
    required List<String> vibes,
    required int budgetMin,
    required int budgetMax,
    required List<String> destinationPrefs,
  }) async {
    // Find trip by token
    final trip = await _db
        .from('trips')
        .select('id')
        .eq('invite_token', token)
        .single();

    await _db.from('squad_members').upsert({
      'trip_id':          trip['id'],
      'nickname':         nickname,
      'emoji':            emoji,
      'vibes':            vibes,
      'budget_min':       budgetMin,
      'budget_max':       budgetMax,
      'destination_prefs': destinationPrefs,
      'status':           MemberStatus.submitted.name,
      'responded_at':     DateTime.now().toIso8601String(),
    });
  }

  // ── Cast a vote ───────────────────────────────────────────
  Future<void> castVote({
    required String tripId,
    required String optionId,
  }) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('votes').upsert({
      'trip_id':   tripId,
      'option_id': optionId,
      'user_id':   uid,
    });
  }

  /// Returns the set of `trip_id`s the current user has already voted
  /// on. Used by `pendingVotesProvider` to derive which voting-status
  /// trips still need the user's vote (so Home can show a resume banner).
  Future<Set<String>> fetchMyVotedTripIds() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return <String>{};
    final rows = await _db
        .from('votes')
        .select('trip_id')
        .eq('user_id', uid);
    return (rows as List)
        .map((r) => r['trip_id'] as String)
        .toSet();
  }

  // ── Get vote counts for a trip ─────────────────────────────
  Future<({int total, int winner})> getVoteCounts(String tripId) async {
    final data = await _db
        .from('trip_options')
        .select('vote_count')
        .eq('trip_id', tripId)
        .order('vote_count', ascending: false);
    int total = 0;
    int winner = 0;
    for (var i = 0; i < (data as List).length; i++) {
      final count = data[i]['vote_count'] as int? ?? 0;
      total += count;
      if (i == 0) winner = count;
    }
    return (total: total, winner: winner);
  }

  // ── Delete trip ────────────────────────────────────────────
  Future<void> deleteTrip(String tripId) async {
    await _db.from('trips').delete().eq('id', tripId);
  }

  // ── Update trip status ────────────────────────────────────
  Future<void> updateStatus(String tripId, TripStatus status) async {
    await _db.from('trips').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tripId);
  }

  // ── Set revealed destination ──────────────────────────────
  Future<void> setWinner({
    required String tripId,
    required String destination,
    required String flag,
  }) async {
    await _db.from('trips').update({
      'selected_destination': destination,
      'selected_flag':        flag,
      'status':               TripStatus.revealed.name,
      'updated_at':           DateTime.now().toIso8601String(),
    }).eq('id', tripId);
  }

  /// Convert a solo trip into a group trip. One-way: a group trip
  /// can't go back to solo (the moment squadmates are added, "their
  /// preferences" is part of the trip's identity).
  ///
  /// All existing data is preserved — itinerary, dates, destination,
  /// packing, photos. The host effectively keeps planning, and now
  /// invited squadmates can join.
  ///
  /// Defensive: if invite_token is null on an old solo trip, we
  /// regenerate it here so the share-invite flow has something to
  /// hand out.
  Future<Trip> convertToGroup(String tripId) async {
    final existing = await _db
        .from('trips')
        .select('invite_token')
        .eq('id', tripId)
        .single();
    final hasToken =
        existing['invite_token'] != null &&
        (existing['invite_token'] as String).isNotEmpty;
    final updates = {
      'mode':       TripMode.group.name,
      'updated_at': DateTime.now().toIso8601String(),
      if (!hasToken) 'invite_token': _generateToken(),
    };
    final row = await _db
        .from('trips')
        .update(updates)
        .eq('id', tripId)
        .select()
        .single();
    return Trip.fromJson(row);
  }

  /// Host-only. Swap the trip's destination after voting / reveal.
  /// Clears the current itinerary so the host can regenerate fresh.
  /// Packing + squad + chat all stay intact.
  Future<void> changeDestination({
    required String tripId,
    required String destination,
    String? flag,
    String? country,
    bool clearItinerary = true,
  }) async {
    await _db.rpc('change_trip_destination', params: {
      '_trip_id': tripId,
      '_destination': destination,
      '_flag': flag,
      '_country': country,
      '_clear_itinerary': clearItinerary,
    });
  }

  // ── Public profile fetch (privacy-aware, via RPC) ─────────
  /// Uses `get_public_profile` SECURITY DEFINER RPC which respects
  /// privacy_level server-side and bypasses the restrictive SELECT
  /// policy on `profiles`.
  Future<Map<String, dynamic>?> fetchPublicProfile(String userId) async {
    final res = await _db.rpc(
      'get_public_profile',
      params: {'_user_id': userId},
    );
    final list = res as List?;
    if (list == null || list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first as Map);
  }

  // ── Clone a trip's squad into a fresh draft ────────────────
  /// Host-only "plan again" flow. Creates a new trip seeded from
  /// [source] (name · take N, same vibes, same mode) and re-invites
  /// every registered squad member so the vibe carries over.
  /// Returns the new Trip.
  Future<Trip> cloneTripWithSquad(Trip source) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');
    final next = await createTrip(
      name: '${source.name} · take 2',
      mode: source.mode,
      vibes: source.vibes ?? const [],
    );
    // Re-invite every registered squadmate except the host (already
    // added by createTrip).
    final squad = await _db
        .from('squad_members')
        .select('user_id, nickname, emoji')
        .eq('trip_id', source.id);
    final rows = <Map<String, dynamic>>[];
    for (final m in (squad as List)) {
      final other = (m as Map<String, dynamic>)['user_id'] as String?;
      if (other == null || other == uid) continue;
      rows.add({
        'trip_id':  next.id,
        'user_id':  other,
        'role':     MemberRole.member.name,
        'status':   MemberStatus.invited.name,
        'nickname': (m['nickname'] as String?) ?? 'friend',
        'emoji':    (m['emoji'] as String?) ?? '😎',
      });
    }
    if (rows.isNotEmpty) {
      await _db.from('squad_members').insert(rows);
    }
    return next;
  }

  // ── Search users by tag or name (via RPC) ─────────────────
  Future<List<Map<String, dynamic>>> searchByTag(String query) async {
    if (query.trim().length < 2) return [];
    final res = await _db.rpc('search_profiles', params: {'q': query});
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ── Add an existing @tag user to a trip's squad ───────────
  /// Inserts a squad_members row with status=invited. Idempotent: if
  /// the user is already in the squad (regardless of status), throws
  /// so the caller can show a friendly message.
  Future<void> addMemberByTag({
    required String tripId,
    required String userId,
    required String nickname,
    String emoji = '😎',
  }) async {
    final existing = await _db
        .from('squad_members')
        .select('id')
        .eq('trip_id', tripId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      throw Exception('already in the squad');
    }
    await _db.from('squad_members').insert({
      'trip_id':  tripId,
      'user_id':  userId,
      'role':     MemberRole.member.name,
      'status':   MemberStatus.invited.name,
      'nickname': nickname,
      'emoji':    emoji,
    });

    // DM the invitee with a trip-marker so their inbox/DM UI routes
    // taps straight into the trip instead of the DM thread. Non-fatal.
    try {
      final trip = await _db
          .from('trips')
          .select('name')
          .eq('id', tripId)
          .maybeSingle();
      final tripName = (trip?['name'] as String?) ?? 'a trip';
      final actor = _db.auth.currentUser?.id;
      if (actor != null) {
        await _db.from('direct_messages').insert({
          'from_user': actor,
          'to_user':   userId,
          'content':   buildInviteDmContent(
            tripName: tripName,
            tripId: tripId,
          ),
        });
      }
    } catch (_) {
      // Non-fatal — the squad membership is what actually matters.
    }
  }

  /// Returns the wire format used to embed a trip invite in a DM.
  /// The DM content ends with `«trip:{tripId}»` so the inbox/DM UI can
  /// detect an invite and route taps to the trip instead of the DM.
  static String buildInviteDmContent({
    required String tripName,
    required String tripId,
  }) =>
      'added you to $tripName — drop your prefs or cast your vote «trip:$tripId»';

  /// Extracts the trip_id if this DM is an invite; null otherwise.
  static String? tripIdFromDmContent(String? content) {
    if (content == null) return null;
    final m = RegExp(r'«trip:([a-f0-9-]+)»').firstMatch(content);
    return m?.group(1);
  }

  /// Strips the trip marker from invite DMs so the display text stays
  /// clean. Non-invite content passes through untouched.
  static String stripInviteMarker(String content) =>
      content.replaceAll(RegExp(r'\s*«trip:[a-f0-9-]+»\s*$'), '').trim();

  String _generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}

// ─────────────────────────────────────────────────────────────
//  AI SERVICE  — calls Supabase Edge Functions
// ─────────────────────────────────────────────────────────────
final aiServiceProvider = Provider((ref) => AIService(ref.read(supabaseProvider)));

class AIService {
  AIService(this._db);
  final SupabaseClient _db;

  // Generate 3 trip proposals from squad responses
  Future<List<TripOption>> generateTripOptions(String tripId) async {
    final res = await _db.functions.invoke(
      'generate_trip_options',
      body: {'trip_id': tripId},
    );
    if (res.status != 200) throw Exception('AI generation failed');
    final options = (res.data['options'] as List)
        .map((e) => TripOption.fromJson(snakeToCamel(e)))
        .toList();
    return options;
  }

  // Generate full day-by-day itinerary for winning destination
  Future<List<ItineraryDay>> generateItinerary(String tripId) async {
    final res = await _db.functions.invoke(
      'generate_itinerary',
      body: {'trip_id': tripId},
    );
    if (res.status != 200) throw Exception('Itinerary generation failed');
    final days = (res.data['days'] as List)
        .map((e) => ItineraryDay.fromJson(snakeToCamel(e)))
        .toList();
    return days;
  }

  // Generate packing list
  Future<List<PackingItem>> generatePackingList(String tripId) async {
    final res = await _db.functions.invoke(
      'generate_packing_list',
      body: {'trip_id': tripId},
    );
    if (res.status != 200) throw Exception('Packing list generation failed');
    final items = (res.data['items'] as List)
        .map((e) => PackingItem.fromJson(snakeToCamel(e)))
        .toList();
    return items;
  }

  // AI tiebreaker when vote is tied
  Future<TripOption> aiTiebreaker(String tripId) async {
    final res = await _db.functions.invoke(
      'ai_tiebreaker',
      body: {'trip_id': tripId},
    );
    if (res.status != 200) throw Exception('Tiebreaker failed');
    return TripOption.fromJson(snakeToCamel(res.data['winner']));
  }
}

// ─────────────────────────────────────────────────────────────
//  NOTIFICATIONS SERVICE  — per-user inbox + unread badge
// ─────────────────────────────────────────────────────────────
final notificationsServiceProvider =
    Provider((ref) => NotificationsService(ref.read(supabaseProvider)));

class NotificationsService {
  NotificationsService(this._db);
  final SupabaseClient _db;

  Stream<List<NotificationItem>> watchMine() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return Stream.value(<NotificationItem>[]);
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(100)
        .map((rows) =>
            rows.map((r) => NotificationItem.fromJson(snakeToCamel(r))).toList());
  }

  Future<void> markRead(String id) async {
    await _db.from('notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> markAllRead() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('user_id', uid).isFilter('read_at', null);
  }
}

// ─────────────────────────────────────────────────────────────
//  TRIP EVENTS SERVICE  — activity ticker + per-trip feed
// ─────────────────────────────────────────────────────────────
final tripEventsServiceProvider =
    Provider((ref) => TripEventsService(ref.read(supabaseProvider)));

class TripEventsService {
  TripEventsService(this._db);
  final SupabaseClient _db;

  /// Events for a single trip (Trip Space chat + status feed)
  Stream<List<TripEvent>> watchTripEvents(String tripId) {
    return _db
        .from('trip_events')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: false)
        .limit(200)
        .map((rows) =>
            rows.map((r) => TripEvent.fromJson(snakeToCamel(r))).toList());
  }

  /// Recent activity across every trip the user is linked to.
  /// Drives the horizontal ticker on Home.
  Future<List<TripEvent>> fetchMyRecentActivity({int limit = 30}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    // Get trip IDs I'm in (as host or squad member)
    final hostedRaw = await _db.from('trips').select('id').eq('host_id', uid);
    final joinedRaw = await _db
        .from('squad_members')
        .select('trip_id')
        .eq('user_id', uid);
    final tripIds = <String>{
      ...(hostedRaw as List).map((e) => e['id'] as String),
      ...(joinedRaw as List).map((e) => e['trip_id'] as String),
    };
    if (tripIds.isEmpty) return [];
    final data = await _db
        .from('trip_events')
        .select()
        .inFilter('trip_id', tripIds.toList())
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((r) => TripEvent.fromJson(snakeToCamel(r)))
        .toList();
  }

  /// Manually log an event (for cases not covered by DB triggers)
  Future<void> log({
    required String tripId,
    required String kind,
    Map<String, dynamic>? payload,
  }) async {
    final uid = _db.auth.currentUser?.id;
    await _db.from('trip_events').insert({
      'trip_id': tripId,
      'kind': kind,
      'actor_user_id': uid,
      'payload': payload,
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  DM SERVICE  — direct messages inbox + thread
// ─────────────────────────────────────────────────────────────
final dmServiceProvider = Provider((ref) => DmService(ref.read(supabaseProvider)));

class DmService {
  DmService(this._db);
  final SupabaseClient _db;

  Future<DirectMessage> send({
    required String toUser,
    required String content,
    String? replyToId,
    String? imageUrl,
    String? audioUrl,
    int? audioDurationMs,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final data = await _db.from('direct_messages').insert({
      'from_user': uid,
      'to_user': toUser,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (audioDurationMs != null) 'audio_duration_ms': audioDurationMs,
    }).select().single();
    return DirectMessage.fromJson(snakeToCamel(data));
  }

  /// Upload an audio file (voice memo) to the `avatars` bucket under
  /// `<uid>/voice/<uuid>.m4a`. Returns the public URL.
  Future<String> uploadDmAudio({
    required String otherUserId,
    required String filePath,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final ext = filePath.split('.').last;
    final key = '$uid/voice/'
        '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('avatars').upload(
          key,
          File(filePath),
          fileOptions: const FileOptions(contentType: 'audio/mp4'),
        );
    return _db.storage.from('avatars').getPublicUrl(key);
  }

  /// Upload a DM attachment to the `avatars` bucket under the
  /// sender's folder and return the public URL. Mirror of
  /// [ChatService.uploadChatImage].
  /// Delete a DM row. RLS restricts this to the original sender.
  Future<void> deleteMessage(String messageId) async {
    await _db.from('direct_messages').delete().eq('id', messageId);
  }

  /// Edit a DM. Writes `edited_at`. RLS restricts UPDATE to the
  /// original sender.
  Future<void> editMessage({
    required String messageId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) throw Exception('message can\'t be empty');
    await _db.from('direct_messages').update({
      'content': trimmed,
      'edited_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  /// File a moderation report against a DM. See 028_message_reports.
  /// Apple guideline 1.2 compliance.
  Future<void> reportMessage({
    required String messageId,
    required String reason,
    String? details,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');
    await _db.from('message_reports').insert({
      'reporter_id': uid,
      'dm_message_id': messageId,
      'reason': reason,
      'details': details,
    });
  }

  Future<String> uploadDmImage({
    required String otherUserId,
    required String filePath,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');
    var ext = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : 'jpg';
    if (ext == 'jpeg') ext = 'jpg';
    final mime = switch (ext) {
      'png'  => 'image/png',
      'webp' => 'image/webp',
      _      => 'image/jpeg',
    };
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = '$uid/dm/$otherUserId/$stamp.$ext';
    final bytes = await File(filePath).readAsBytes();
    await _db.storage.from('avatars').uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(upsert: false, contentType: mime),
        );
    return _db.storage.from('avatars').getPublicUrl(objectPath);
  }

  /// Toggle a reaction on a DM. Insert if absent; delete if already
  /// present (idempotent on repeated double-taps).
  Future<void> react({
    required String messageId,
    required String emoji,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    // Check existing
    final existing = await _db
        .from('direct_message_reactions')
        .select('id')
        .eq('message_id', messageId)
        .eq('user_id', uid)
        .eq('emoji', emoji)
        .maybeSingle();
    if (existing != null) {
      await _db
          .from('direct_message_reactions')
          .delete()
          .eq('id', existing['id']);
    } else {
      await _db.from('direct_message_reactions').insert({
        'message_id': messageId,
        'user_id': uid,
        'emoji': emoji,
      });
    }
  }

  /// Realtime stream of all reactions on DMs in the current user's
  /// thread with [otherUserId]. Filtered client-side because the
  /// reactions table doesn't know about the DM pair — only the
  /// message does.
  Stream<List<DmReaction>> watchThreadReactions(String otherUserId) {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return Stream.value(const <DmReaction>[]);
    // Subscribe to everything we have access to; filter happens
    // client-side by joining against the thread's message ids.
    return _db
        .from('direct_message_reactions')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .map((r) => DmReaction.fromJson(snakeToCamel(r)))
            .toList());
  }

  /// All DMs touching the current user (both directions). Grouped into
  /// conversations client-side.
  Stream<List<DirectMessage>> watchAllMine() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return Stream.value(<DirectMessage>[]);
    return _db
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(500)
        .map((rows) => rows
            .where((r) => r['from_user'] == uid || r['to_user'] == uid)
            .map((r) => DirectMessage.fromJson(snakeToCamel(r)))
            .toList());
  }

  Stream<List<DirectMessage>> watchThread(String otherUserId) {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return Stream.value(<DirectMessage>[]);
    return _db
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .limit(500)
        .map((rows) => rows
            .where((r) =>
                (r['from_user'] == uid && r['to_user'] == otherUserId) ||
                (r['from_user'] == otherUserId && r['to_user'] == uid))
            .map((r) => DirectMessage.fromJson(snakeToCamel(r)))
            .toList());
  }

  Future<void> markThreadRead(String otherUserId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db
        .from('direct_messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('from_user', otherUserId)
        .eq('to_user', uid)
        .isFilter('read_at', null);
  }

  /// Collapse a flat list of DMs into per-conversation summaries.
  List<DmConversation> collapseToConversations(
    List<DirectMessage> all,
    String currentUserId,
    Map<String, Map<String, dynamic>> profilesByUserId,
  ) {
    final byOther = <String, List<DirectMessage>>{};
    for (final m in all) {
      final other = m.fromUser == currentUserId ? m.toUser : m.fromUser;
      byOther.putIfAbsent(other, () => []).add(m);
    }
    final conversations = <DmConversation>[];
    byOther.forEach((otherId, msgs) {
      msgs.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      final last = msgs.first;
      final unread = msgs
          .where((m) => m.toUser == currentUserId && m.readAt == null)
          .length;
      final profile = profilesByUserId[otherId];
      conversations.add(DmConversation(
        otherUserId: otherId,
        otherNickname: profile?['nickname'] as String?,
        otherTag: profile?['tag'] as String?,
        otherEmoji: profile?['emoji'] as String?,
        otherAvatarUrl: profile?['avatar_url'] as String?,
        lastMessage: last.content,
        lastMessageAt: last.createdAt ?? DateTime.now(),
        unreadCount: unread,
      ));
    });
    conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return conversations;
  }

  Future<Map<String, Map<String, dynamic>>> fetchProfilesByIds(
      List<String> userIds) async {
    if (userIds.isEmpty) return {};
    // Uses get_public_profiles RPC so we bypass the restrictive
    // profiles SELECT policy (which limits to auth.uid() = id).
    final res = await _db.rpc(
      'get_public_profiles',
      params: {'_user_ids': userIds},
    );
    return {
      for (final row in (res as List))
        (row as Map<String, dynamic>)['id'] as String:
            Map<String, dynamic>.from(row),
    };
  }
}

// ─────────────────────────────────────────────────────────────
//  SCOUT SERVICE  — conversational AI (1:1 user ↔ Scout)
// ─────────────────────────────────────────────────────────────
final scoutServiceProvider =
    Provider((ref) => ScoutService(ref.read(supabaseProvider)));

String _fnError(FunctionResponse res, String tag) {
  final data = res.data;
  if (data is Map) {
    final msg = data['error'] ?? data['message'] ?? data['code'];
    if (msg != null) return '$tag failed [${res.status}]: $msg';
  }
  if (data is String && data.isNotEmpty) {
    return '$tag failed [${res.status}]: $data';
  }
  return '$tag failed [${res.status}]';
}

class ScoutService {
  ScoutService(this._db);
  final SupabaseClient _db;

  Stream<List<ScoutMessage>> watchHistory() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return Stream.value(<ScoutMessage>[]);
    return _db
        .from('scout_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: true)
        .limit(200)
        .map((rows) =>
            rows.map((r) => ScoutMessage.fromJson(snakeToCamel(r))).toList());
  }

  /// Send a user message and get Scout's reply. Both are persisted by
  /// the edge function so the stream above reflects them automatically.
  /// Delete a Scout message (user's own row). RLS on
  /// `scout_messages` already restricts CRUD to the owner.
  Future<void> deleteMessage(String messageId) async {
    await _db.from('scout_messages').delete().eq('id', messageId);
  }

  Future<String> ask(String content, {String? imageUrl}) async {
    final res = await _db.functions.invoke(
      'scout_chat',
      body: {
        'content': content,
        if (imageUrl != null) 'image_url': imageUrl,
      },
    );
    if (res.status != 200) {
      throw Exception(_fnError(res, 'scout chat'));
    }
    return (res.data['reply'] as String?) ?? '';
  }

  /// Upload a photo attached to a Scout 1:1 question. Stored under
  /// the sender's folder in the public avatars bucket.
  Future<String> uploadScoutImage(String filePath) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');
    var ext = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : 'jpg';
    if (ext == 'jpeg') ext = 'jpg';
    final mime = switch (ext) {
      'png'  => 'image/png',
      'webp' => 'image/webp',
      _      => 'image/jpeg',
    };
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = '$uid/scout/$stamp.$ext';
    final bytes = await File(filePath).readAsBytes();
    await _db.storage.from('avatars').uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(upsert: false, contentType: mime),
        );
    return _db.storage.from('avatars').getPublicUrl(objectPath);
  }

  /// In-trip Scout ping — posts Scout's reply as a chat_message so the
  /// whole squad sees it inline in Trip Chat. Pass [imageUrl] to let
  /// Scout analyse a photo the user just shared (public URL in the
  /// avatars bucket).
  Future<void> askInTrip({
    required String tripId,
    required String content,
    String? imageUrl,
  }) async {
    final res = await _db.functions.invoke(
      'scout_chat',
      body: {
        'content': content,
        'trip_id': tripId,
        if (imageUrl != null) 'image_url': imageUrl,
      },
    );
    if (res.status != 200) {
      throw Exception(_fnError(res, 'scout in-trip'));
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  DESTINATION RESOLVER — Scout-backed {valid, flag, country, canonical}
// ─────────────────────────────────────────────────────────────
class ResolvedDestination {
  const ResolvedDestination({
    required this.valid,
    this.canonical,
    this.country,
    this.flag,
    this.region,
  });
  final bool valid;
  final String? canonical;
  final String? country;
  final String? flag;
  final String? region;
}

final destinationResolverProvider =
    Provider((ref) => DestinationResolver(ref.read(supabaseProvider)));

class DestinationResolver {
  DestinationResolver(this._db);
  final SupabaseClient _db;

  Future<ResolvedDestination> resolve(String destination) async {
    final res = await _db.functions.invoke(
      'resolve_destination',
      body: {'destination': destination},
    );
    final data = res.data;
    if (data is! Map) return const ResolvedDestination(valid: false);
    return ResolvedDestination(
      valid: data['valid'] == true,
      canonical: data['canonical'] as String?,
      country: data['country'] as String?,
      flag: data['flag'] as String?,
      region: data['region'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PLACES SERVICE — canonical destination directory (Scout's Guide)
// ─────────────────────────────────────────────────────────────
final placesServiceProvider =
    Provider((ref) => PlacesService(ref.read(supabaseProvider)));

class PlacesService {
  PlacesService(this._db);
  final SupabaseClient _db;

  /// Destination-level summary — total places + counts by category + avg stars.
  Future<DestinationHub?> fetchDestination(String destination) async {
    final row = await _db.from('destination_hub').select()
        .eq('destination_key', destination.toLowerCase().trim())
        .maybeSingle();
    if (row == null) return null;
    return DestinationHub.fromJson(snakeToCamel(row));
  }

  /// Top-rated destinations (for Explore landing, future).
  Future<List<DestinationHub>> fetchTrendingDestinations({int limit = 12}) async {
    final rows = await _db.from('destination_hub').select()
        .order('place_count', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => DestinationHub.fromJson(snakeToCamel(r)))
        .toList();
  }

  /// Places in a destination filtered by category, ranked by squad count
  /// then approval %.
  Future<List<PlaceStats>> fetchPlacesForDestination(
    String destination, {
    String? category,
  }) async {
    var query = _db.from('place_stats').select()
        .ilike('destination', destination.trim());
    if (category != null) {
      query = query.eq('category', category);
    }
    final rows = await query
        .order('squads_count', ascending: false)
        .order('approval_pct', ascending: false)
        .limit(40);
    return (rows as List)
        .map((r) => PlaceStats.fromJson(snakeToCamel(r)))
        .toList();
  }

  Future<PlaceStats?> fetchPlace(String placeId) async {
    final row = await _db.from('place_stats').select()
        .eq('place_id', placeId)
        .maybeSingle();
    if (row == null) return null;
    return PlaceStats.fromJson(snakeToCamel(row));
  }

  /// Recent destination recaps for a destination's hub feed.
  Future<List<Map<String, dynamic>>> fetchDestinationRecapsFeed(
      String destination) async {
    final rows = await _db.rpc(
      'destination_recaps_feed',
      params: {'_destination': destination},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Ratings feed for a place — unions direct place_ratings with ratings
  /// on linked itinerary items, includes voter profile + notes.
  Future<List<Map<String, dynamic>>> fetchPlaceRatingsFeed(
      String placeId) async {
    final rows = await _db.rpc(
      'place_ratings_feed',
      params: {'_place_id': placeId},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Squad recaps that mention this place (by its canonical id).
  /// For now: grab the trip_id of itinerary_items linked to this place,
  /// then the destination recaps for those trips.
  Future<List<Map<String, dynamic>>> fetchPlaceRecaps(String placeId) async {
    final items = await _db.from('itinerary_items').select('trip_id')
        .eq('place_id', placeId);
    final tripIds = (items as List)
        .map((r) => r['trip_id'] as String)
        .toSet()
        .toList();
    if (tripIds.isEmpty) return [];
    final recaps = await _db.from('destination_recaps').select()
        .inFilter('trip_id', tripIds)
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(recaps as List);
  }

  /// Add this place to another trip the current user is a member of.
  /// Returns the id of the newly-created itinerary_item, or null if the
  /// user has no active trip to a matching destination.
  Future<String?> addToNextTrip({
    required Place place,
    required String targetTripId,
    int? dayNumber,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    // Pick day 1 if none specified
    final day = dayNumber ?? 1;
    final existing = await _db.from('itinerary_items')
        .select('order_index')
        .eq('trip_id', targetTripId)
        .eq('day_number', day)
        .order('order_index', ascending: false)
        .limit(1);
    final nextOrder = (existing as List).isEmpty
        ? 0
        : (((existing.first)['order_index'] as int? ?? 0) + 1);
    final row = await _db.from('itinerary_items').insert({
      'trip_id': targetTripId,
      'day_number': day,
      'title': place.name,
      'item_type': place.category,
      'location': place.address,
      'place_id': place.id,
      'order_index': nextOrder,
      'created_by': uid,
    }).select().single();
    return row['id'] as String?;
  }
}

// ─────────────────────────────────────────────────────────────
//  RATINGS SERVICE  — kudos, activity ratings, destination recaps
// ─────────────────────────────────────────────────────────────
final ratingsServiceProvider =
    Provider((ref) => RatingsService(ref.read(supabaseProvider)));

class RatingsService {
  RatingsService(this._db);
  final SupabaseClient _db;

  // ── Kudos ──
  Future<void> giveKudos({
    required String tripId,
    required String toUser,
    required String kind,
    String? note,
  }) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('kudos').upsert({
      'trip_id': tripId,
      'from_user': uid,
      'to_user': toUser,
      'kind': kind,
      'note': note,
    }, onConflict: 'trip_id,from_user,to_user,kind');
  }

  Future<void> removeKudos({
    required String tripId,
    required String toUser,
    required String kind,
  }) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('kudos').delete()
        .eq('trip_id', tripId)
        .eq('from_user', uid)
        .eq('to_user', toUser)
        .eq('kind', kind);
  }

  /// Kudos I gave this squad member on this trip — used to pre-select
  /// chips in the post-trip kudos flow.
  Future<Set<String>> myKudosFor({
    required String tripId,
    required String toUser,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return {};
    final rows = await _db.from('kudos').select('kind')
        .eq('trip_id', tripId)
        .eq('from_user', uid)
        .eq('to_user', toUser);
    return (rows as List).map((r) => r['kind'] as String).toSet();
  }

  /// Aggregate counts of kudos a user has received, grouped by kind.
  Future<Map<String, int>> kudosCountsFor(String userId) async {
    final rows = await _db.from('kudos_counts').select('kind, count')
        .eq('user_id', userId);
    return {
      for (final r in (rows as List))
        r['kind'] as String: r['count'] as int,
    };
  }

  // ── Itinerary item ratings ──
  Future<void> rateItem({
    required String itemId,
    required int thumb, // -1 or 1
    String? note,
  }) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('itinerary_ratings').upsert({
      'item_id': itemId,
      'user_id': uid,
      'thumb': thumb,
      'note': note,
    }, onConflict: 'item_id,user_id');
  }

  Future<void> removeItemRating(String itemId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('itinerary_ratings').delete()
        .eq('item_id', itemId)
        .eq('user_id', uid);
  }

  Future<int?> myItemThumb(String itemId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _db.from('itinerary_ratings').select('thumb')
        .eq('item_id', itemId).eq('user_id', uid).maybeSingle();
    return row?['thumb'] as int?;
  }

  Future<({int up, int down, int total, int approvalPct})> itemSummary(
      String itemId) async {
    final row = await _db.from('item_rating_summary').select()
        .eq('item_id', itemId).maybeSingle();
    if (row == null) return (up: 0, down: 0, total: 0, approvalPct: 0);
    return (
      up: (row['up_count'] as int?) ?? 0,
      down: (row['down_count'] as int?) ?? 0,
      total: (row['total'] as int?) ?? 0,
      approvalPct: (row['approval_pct'] as int?) ?? 0,
    );
  }

  // ── Place-level ratings (direct, not tied to itinerary item) ──
  Future<int?> myPlaceThumb(String placeId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _db.from('place_ratings').select('thumb')
        .eq('place_id', placeId).eq('user_id', uid).maybeSingle();
    return row?['thumb'] as int?;
  }

  Future<void> ratePlace({
    required String placeId,
    required int thumb,
    String? note,
  }) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('place_ratings').upsert({
      'place_id': placeId,
      'user_id': uid,
      'thumb': thumb,
      'note': note,
    }, onConflict: 'place_id,user_id');
  }

  Future<void> removePlaceRating(String placeId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('place_ratings').delete()
        .eq('place_id', placeId).eq('user_id', uid);
  }

  // ── Destination recap ──
  Future<DestinationRecap?> myRecap(String tripId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _db.from('destination_recaps').select()
        .eq('trip_id', tripId).eq('user_id', uid).maybeSingle();
    if (row == null) return null;
    return DestinationRecap.fromJson(snakeToCamel(row));
  }

  Future<void> submitRecap({
    required String tripId,
    required String destination,
    required int stars,
    required String wouldReturn,
    String? bestPart,
    String? photoUrl,
  }) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('destination_recaps').upsert({
      'trip_id': tripId,
      'user_id': uid,
      'destination': destination,
      'stars': stars,
      'would_return': wouldReturn,
      'best_part': bestPart,
      'photo_url': photoUrl,
    }, onConflict: 'trip_id,user_id');
  }

  Future<({double avgStars, int count, int wouldReturnCount})?>
      destinationSummary(String destination) async {
    final row = await _db.from('destination_summary').select()
        .eq('destination_key', destination.toLowerCase().trim())
        .maybeSingle();
    if (row == null) return null;
    return (
      avgStars: ((row['avg_stars'] as num?) ?? 0).toDouble(),
      count: (row['recap_count'] as int?) ?? 0,
      wouldReturnCount: (row['would_return_count'] as int?) ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ITINERARY SERVICE  — first-class realtime activities + notes
// ─────────────────────────────────────────────────────────────
final itineraryServiceProvider =
    Provider((ref) => ItineraryService(ref.read(supabaseProvider)));

class ItineraryService {
  ItineraryService(this._db);
  final SupabaseClient _db;

  Stream<List<ItineraryActivity>> watch(String tripId) {
    return _db
        .from('itinerary_items')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('day_number', ascending: true)
        .map((rows) {
      final list = rows
          .map((r) => ItineraryActivity.fromJson(snakeToCamel(r)))
          .toList();
      list.sort((a, b) {
        final dayCmp = a.dayNumber.compareTo(b.dayNumber);
        if (dayCmp != 0) return dayCmp;
        return a.orderIndex.compareTo(b.orderIndex);
      });
      return list;
    });
  }

  /// Flip the Today-tab check-off on an itinerary item. Uses the
  /// `toggle_itinerary_check` RPC (SECURITY DEFINER, membership-
  /// gated) so any squad member can tick items even though UPDATE
  /// RLS on itinerary_items is stricter. Returns the new
  /// `checked_off_at` (null when unchecked).
  Future<DateTime?> toggleCheck(String itemId) async {
    final result = await _db.rpc(
      'toggle_itinerary_check',
      params: {'_item_id': itemId},
    );
    if (result == null) return null;
    return DateTime.tryParse(result.toString());
  }

  Stream<List<ItineraryNote>> watchNotes(String itemId) {
    return _db
        .from('itinerary_notes')
        .stream(primaryKey: ['id'])
        .eq('item_id', itemId)
        .order('created_at', ascending: true)
        .map((rows) =>
            rows.map((r) => ItineraryNote.fromJson(snakeToCamel(r))).toList());
  }

  Future<ItineraryActivity> addActivity({
    required String tripId,
    required int dayNumber,
    required String title,
    String timeOfDay = 'morning',
    String itemType = 'activity',
    String? description,
    String? location,
    int? estimatedCostCents,
    String? bookingUrl,
    String? imageUrl,
  }) async {
    final uid = _db.auth.currentUser?.id;
    final existing = await _db
        .from('itinerary_items')
        .select('order_index')
        .eq('trip_id', tripId)
        .eq('day_number', dayNumber)
        .order('order_index', ascending: false)
        .limit(1);
    final nextOrder = (existing as List).isEmpty
        ? 0
        : ((existing.first['order_index'] as int? ?? 0) + 1);
    final data = await _db.from('itinerary_items').insert({
      'trip_id': tripId,
      'day_number': dayNumber,
      'time_of_day': timeOfDay,
      'item_type': itemType,
      'title': title,
      'description': description,
      'location': location,
      'estimated_cost_cents': estimatedCostCents,
      'booking_url': bookingUrl,
      'image_url': imageUrl,
      'order_index': nextOrder,
      'created_by': uid,
    }).select().single();
    return ItineraryActivity.fromJson(snakeToCamel(data));
  }

  Future<void> updateActivity({
    required String id,
    String? title,
    String? description,
    String? location,
    String? timeOfDay,
    int? estimatedCostCents,
    String? bookingUrl,
    String? imageUrl,
  }) async {
    final patch = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (estimatedCostCents != null) 'estimated_cost_cents': estimatedCostCents,
      if (bookingUrl != null) 'booking_url': bookingUrl,
      if (imageUrl != null) 'image_url': imageUrl,
    };
    if (patch.isEmpty) return;
    await _db.from('itinerary_items').update(patch).eq('id', id);
  }

  Future<void> deleteActivity(String id) async {
    await _db.from('itinerary_items').delete().eq('id', id);
  }

  Future<void> markBooked(String id, bool booked) async {
    await _db.from('itinerary_items').update({
      'booked_at': booked ? DateTime.now().toIso8601String() : null,
    }).eq('id', id);
  }

  /// Host-only. Approves a proposed activity so the whole squad sees it.
  Future<void> approveProposal(String itemId) async {
    await _db.rpc('approve_itinerary_item', params: {'_item_id': itemId});
  }

  /// Host-only. Rejects a proposed activity with an optional reason.
  Future<void> rejectProposal(String itemId, {String? reason}) async {
    await _db.rpc('reject_itinerary_item', params: {
      '_item_id': itemId,
      '_reason': reason,
    });
  }

  Future<void> addNote({
    required String itemId,
    required String content,
  }) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('itinerary_notes').insert({
      'item_id': itemId,
      'user_id': uid,
      'content': content,
    });
  }

  Future<void> deleteNote(String id) async {
    await _db.from('itinerary_notes').delete().eq('id', id);
  }

  Future<void> generateForTrip(String tripId,
      {bool regenerate = false}) async {
    final res = await _db.functions.invoke(
      'generate_itinerary',
      body: {'trip_id': tripId, 'regenerate': regenerate},
    );
    if (res.status != 200) {
      throw Exception(_fnError(res, 'itinerary generation'));
    }
  }

  /// Backfill photos on activities missing image_url. Pass overwrite=true
  /// to re-pull photos for every activity (costs more Unsplash requests).
  Future<({int updated, int attempted})> refreshPhotos(
    String tripId, {
    bool overwrite = false,
  }) async {
    final res = await _db.functions.invoke(
      'refresh_itinerary_photos',
      body: {'trip_id': tripId, 'overwrite': overwrite},
    );
    if (res.status != 200) {
      throw Exception(res.data?['error'] ?? 'photo refresh failed');
    }
    return (
      updated: (res.data['updated'] as int?) ?? 0,
      attempted: (res.data['attempted'] as int?) ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CHAT SERVICE  — realtime squad chat with reactions, replies,
//  mentions, typing, read receipts, pinning.
// ─────────────────────────────────────────────────────────────
final chatServiceProvider =
    Provider((ref) => ChatService(ref.read(supabaseProvider)));

class ChatService {
  ChatService(this._db);
  final SupabaseClient _db;

  ChatMessage _fromRow(Map<String, dynamic> r) {
    final camel = snakeToCamel(r);
    final seenByRaw = camel['seenBy'];
    final seenBy = <String>[];
    if (seenByRaw is List) {
      for (final v in seenByRaw) {
        if (v != null) seenBy.add(v.toString());
      }
    }
    final mentionsRaw = camel['mentions'];
    final mentions = <String>[];
    if (mentionsRaw is List) {
      for (final v in mentionsRaw) {
        if (v != null) mentions.add(v.toString());
      }
    }
    return ChatMessage(
      id: camel['id']?.toString() ?? '',
      tripId: camel['tripId']?.toString() ?? '',
      userId: camel['userId']?.toString(),
      nickname: camel['nickname']?.toString() ?? 'someone',
      emoji: camel['emoji']?.toString() ?? '😎',
      content: camel['content']?.toString() ?? '',
      isAi: camel['isAi'] as bool? ?? false,
      replyToId: camel['replyToId']?.toString(),
      imageUrl: camel['imageUrl']?.toString(),
      seenBy: seenBy,
      mentions: mentions,
      pinnedAt: camel['pinnedAt'] != null
          ? DateTime.tryParse(camel['pinnedAt'].toString())
          : null,
      editedAt: camel['editedAt'] != null
          ? DateTime.tryParse(camel['editedAt'].toString())
          : null,
      audioUrl: camel['audioUrl']?.toString(),
      audioDurationMs: camel['audioDurationMs'] is int
          ? camel['audioDurationMs'] as int
          : int.tryParse(camel['audioDurationMs']?.toString() ?? ''),
      createdAt: camel['createdAt'] != null
          ? DateTime.tryParse(camel['createdAt'].toString())
          : null,
    );
  }

  Stream<List<ChatMessage>> watchMessages(String tripId) {
    return _db
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: true)
        .limit(200)
        .map((rows) => rows.map(_fromRow).toList());
  }

  Stream<List<ChatReaction>> watchReactions(String tripId) {
    // Reactions aren't directly keyed by trip_id, so we fetch all
    // reactions whose message belongs to this trip. Simplest: filter client-side
    // based on message ids we already have. Here we just stream all reactions and
    // let the UI filter — small data volume early on.
    return _db
        .from('chat_reactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .limit(1000)
        .map((rows) => rows
            .map((r) => ChatReaction.fromJson(snakeToCamel(r)))
            .toList());
  }

  /// Delete a chat message. RLS restricts this to the author.
  Future<void> deleteMessage(String messageId) async {
    await _db.from('chat_messages').delete().eq('id', messageId);
  }

  /// Edit a chat message. Writes `edited_at` so the client can
  /// render an "edited" hint. RLS restricts UPDATE to the author.
  Future<void> editMessage({
    required String messageId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) throw Exception('message can\'t be empty');
    await _db.from('chat_messages').update({
      'content': trimmed,
      'edited_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  /// File a moderation report against a trip chat message. See
  /// 028_message_reports. Apple guideline 1.2 compliance.
  Future<void> reportMessage({
    required String messageId,
    required String reason,
    String? details,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');
    await _db.from('message_reports').insert({
      'reporter_id': uid,
      'chat_message_id': messageId,
      'reason': reason,
      'details': details,
    });
  }


  /// Upload a picked image to the `avatars` bucket under the user's
  /// own folder, returning the public URL to attach to a chat
  /// message. Storage RLS already restricts writes to the uploader's
  /// uid as the first folder segment.
  Future<String> uploadChatImage({
    required String tripId,
    required String filePath,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');
    var ext = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : 'jpg';
    if (ext == 'jpeg') ext = 'jpg';
    final mime = switch (ext) {
      'png'  => 'image/png',
      'webp' => 'image/webp',
      _      => 'image/jpeg',
    };
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = '$uid/trip_chat/$tripId/$stamp.$ext';
    final bytes = await File(filePath).readAsBytes();
    await _db.storage.from('avatars').uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(upsert: false, contentType: mime),
        );
    return _db.storage.from('avatars').getPublicUrl(objectPath);
  }

  Future<ChatMessage> send({
    required String tripId,
    required String content,
    String? replyToId,
    String? imageUrl,
    String? audioUrl,
    int? audioDurationMs,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final profile = await _db
        .from('profiles')
        .select('nickname, emoji')
        .eq('id', uid)
        .maybeSingle();
    final mentions = _extractMentions(content);
    final data = await _db.from('chat_messages').insert({
      'trip_id': tripId,
      'user_id': uid,
      'nickname': (profile?['nickname'] as String?) ?? 'you',
      'emoji': (profile?['emoji'] as String?) ?? '😎',
      'content': content,
      'reply_to_id': replyToId,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'audio_duration_ms': audioDurationMs,
      'mentions': mentions,
    }).select().single();
    // Fire-and-forget mention notifications
    if (mentions.isNotEmpty) {
      unawaited(_db.rpc('notify_mentions', params: {'_message_id': data['id']}));
    }
    return _fromRow(data);
  }

  /// Upload an audio file (voice memo) to the `avatars` bucket under
  /// the sender's `<uid>/voice/<uuid>.m4a` folder. Returns public URL.
  Future<String> uploadChatAudio({
    required String tripId,
    required String filePath,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final ext = filePath.split('.').last;
    final key = '$uid/voice/'
        '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('avatars').upload(
          key,
          File(filePath),
          fileOptions: const FileOptions(contentType: 'audio/mp4'),
        );
    return _db.storage.from('avatars').getPublicUrl(key);
  }

  Future<void> react({
    required String messageId,
    required String emoji,
  }) async {
    final uid = _db.auth.currentUser!.id;
    // Toggle: delete if exists, else insert
    final existing = await _db
        .from('chat_reactions')
        .select('id')
        .eq('message_id', messageId)
        .eq('user_id', uid)
        .eq('emoji', emoji)
        .maybeSingle();
    if (existing != null) {
      await _db.from('chat_reactions').delete().eq('id', existing['id']);
    } else {
      await _db.from('chat_reactions').insert({
        'message_id': messageId,
        'user_id': uid,
        'emoji': emoji,
      });
    }
  }

  Future<void> markSeen(String messageId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.rpc('mark_chat_seen', params: {
      '_message_id': messageId,
      '_user_id': uid,
    });
  }

  /// Toggle a pin on a message. Uses the `toggle_pin` RPC so the
  /// trip-host + one-pin-per-trip guarantees are enforced
  /// server-side.
  Future<void> togglePin(String messageId, {required bool pin}) async {
    await _db.rpc('toggle_pin', params: {
      '_message_id': messageId,
      '_pin': pin,
    });
  }

  List<String> _extractMentions(String content) {
    final re = RegExp(r'@([a-z0-9_]{2,30})');
    return re.allMatches(content).map((m) => m.group(1)!).toSet().toList();
  }
}

// Helper so fire-and-forget awaits don't trip on unused future warnings.
void unawaited(Future<void> future) {}

// ─────────────────────────────────────────────────────────────
//  PACKING SERVICE  — realtime squad packing list
// ─────────────────────────────────────────────────────────────
final packingServiceProvider =
    Provider((ref) => PackingService(ref.read(supabaseProvider)));

class PackingService {
  PackingService(this._db);
  final SupabaseClient _db;

  Stream<List<PackingEntry>> watchTrip(String tripId) {
    return _db
        .from('packing_items')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('order_index', ascending: true)
        .map((rows) => rows
            .map((r) {
              final camel = snakeToCamel(r);
              final packedByRaw = camel['packedBy'];
              final packedBy = <String>[];
              if (packedByRaw is List) {
                for (final v in packedByRaw) {
                  if (v != null) packedBy.add(v.toString());
                }
              }
              return PackingEntry(
                id: camel['id']?.toString() ?? '',
                tripId: camel['tripId']?.toString() ?? tripId,
                label: camel['label']?.toString() ?? '',
                category: camel['category']?.toString() ?? 'extras',
                emoji: camel['emoji']?.toString(),
                isShared: camel['isShared'] as bool? ?? false,
                addedBy: camel['addedBy']?.toString(),
                claimedBy: camel['claimedBy']?.toString(),
                packedBy: packedBy,
                orderIndex: camel['orderIndex'] as int? ?? 0,
                createdAt: camel['createdAt'] != null
                    ? DateTime.tryParse(camel['createdAt'].toString())
                    : null,
              );
            })
            .toList());
  }

  Future<void> togglePacked(String itemId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.rpc('toggle_packed', params: {
      '_item_id': itemId,
      '_user_id': uid,
    });
  }

  Future<void> addCustomItem({
    required String tripId,
    required String label,
    required String category,
    String? emoji,
  }) async {
    final uid = _db.auth.currentUser?.id;
    // Find max order_index for this category so the new item appears at the end
    final existing = await _db
        .from('packing_items')
        .select('order_index')
        .eq('trip_id', tripId)
        .eq('category', category)
        .order('order_index', ascending: false)
        .limit(1);
    final nextOrder = (existing as List).isEmpty
        ? 0
        : (((existing.first)['order_index'] as int? ?? 0) + 1);
    await _db.from('packing_items').insert({
      'trip_id': tripId,
      'label': label,
      'category': category,
      'emoji': emoji,
      'order_index': nextOrder,
      'added_by': uid,
    });
  }

  Future<void> deleteItem(String itemId) async {
    await _db.from('packing_items').delete().eq('id', itemId);
  }

  Future<void> generateForTrip(String tripId, {bool regenerate = false}) async {
    final res = await _db.functions.invoke(
      'generate_packing_list',
      body: {'trip_id': tripId, 'regenerate': regenerate},
    );
    if (res.status != 200) {
      throw Exception(_fnError(res, 'packing generation'));
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  PUSH TOKEN SERVICE  — registers device tokens for fan-out
//  (actual FCM/APNs wiring lives in lib/services/push_service.dart)
// ─────────────────────────────────────────────────────────────
final pushTokenServiceProvider =
    Provider((ref) => PushTokenService(ref.read(supabaseProvider)));

class PushTokenService {
  PushTokenService(this._db);
  final SupabaseClient _db;

  Future<void> register({required String token, required String platform}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('push_tokens').upsert({
      'user_id': uid,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,token');
  }

  Future<void> unregister(String token) async {
    await _db.from('push_tokens').delete().eq('token', token);
  }
}

// ─────────────────────────────────────────────────────────────
//  BLOCK SERVICE  — soft block (hides from search, blocks DMs)
// ─────────────────────────────────────────────────────────────
final blockServiceProvider =
    Provider((ref) => BlockService(ref.read(supabaseProvider)));

class BlockService {
  BlockService(this._db);
  final SupabaseClient _db;

  Future<void> block(String targetUserId) async {
    await _db.rpc('block_user', params: {'_target': targetUserId});
  }

  Future<void> unblock(String targetUserId) async {
    await _db.rpc('unblock_user', params: {'_target': targetUserId});
  }

  Future<List<Map<String, dynamic>>> fetchMyBlocks() async {
    final res = await _db.rpc('my_blocks');
    return List<Map<String, dynamic>>.from(res as List);
  }
}
