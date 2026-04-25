import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final avatarServiceProvider =
    Provider((ref) => AvatarService(Supabase.instance.client));

/// Pick → compress → upload to `avatars/<uid>/...` → save URL to profile.
/// Emoji remains the fallback — photo is a cosmetic enhancement layer.
class AvatarService {
  AvatarService(this._db);
  final SupabaseClient _db;
  static const _bucket = 'avatars';
  static const _maxSide = 512;
  static const _jpegQuality = 80;

  /// Launch the image picker from the camera or library. Returns the
  /// public URL of the uploaded avatar. Caller is responsible for
  /// persisting the URL to `profiles.avatar_url` via `updateAvatar`.
  Future<String?> pickAndUpload({required ImageSource source}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;

    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xfile == null) return null;

    final bytes = await xfile.readAsBytes();
    final compressed = await compute(_compressIsolate, bytes);

    // Delete older avatars for this user (keep only the latest)
    await _clearOld(uid);

    final filename = '${const Uuid().v4()}.jpg';
    final path = '$uid/$filename';
    await _db.storage.from(_bucket).uploadBinary(
          path,
          compressed,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    final url = _db.storage.from(_bucket).getPublicUrl(path);
    await updateAvatar(url);
    return url;
  }

  Future<void> updateAvatar(String? url) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('profiles').update({
      'avatar_url': url,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }

  /// Remove avatar — sets column to null and deletes stored objects.
  Future<void> remove() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _clearOld(uid);
    await updateAvatar(null);
  }

  Future<void> _clearOld(String uid) async {
    try {
      final list = await _db.storage.from(_bucket).list(path: uid);
      if (list.isEmpty) return;
      final paths = list.map((f) => '$uid/${f.name}').toList();
      await _db.storage.from(_bucket).remove(paths);
    } catch (_) {
      // Swallow — clean-up is best-effort
    }
  }
}

// Runs in a background isolate so the UI stays smooth.
Uint8List _compressIsolate(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  // Fit inside _maxSide × _maxSide while preserving aspect ratio
  final resized = decoded.width > 512 || decoded.height > 512
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 512 : null,
          height: decoded.height > decoded.width ? 512 : null,
        )
      : decoded;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
}

