-- 020_chat_image.sql
--
-- Adds an `image_url` column to `chat_messages` so squadmates can
-- attach a photo to a trip chat message. Image blobs live in the
-- public `avatars` bucket under `<uid>/trip_chat/<trip_id>/<msg>.<ext>`
-- so the existing storage RLS policy (first folder = auth uid) keeps
-- working without a new bucket.

alter table public.chat_messages
  add column if not exists image_url text;

comment on column public.chat_messages.image_url is
  'Optional public URL for a photo attachment in avatars bucket.';
