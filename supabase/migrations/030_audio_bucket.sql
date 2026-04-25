-- 030_audio_bucket.sql
--
-- Expand the `avatars` bucket to accept voice memos. The bucket is
-- already publicly readable and enforces per-user folder RLS, so
-- we just widen the MIME whitelist and bump the size limit from
-- 2 MB → 10 MB so longer memos (up to 90s at 64kbps ≈ 720KB, with
-- headroom for future settings).

update storage.buckets
set file_size_limit = 10485760,
    allowed_mime_types = array[
      'image/jpeg', 'image/png', 'image/webp',
      'audio/mp4', 'audio/aac', 'audio/x-m4a', 'audio/mpeg'
    ]
where id = 'avatars';
