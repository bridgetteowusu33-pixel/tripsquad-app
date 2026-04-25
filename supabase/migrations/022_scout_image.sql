-- 022_scout_image.sql
--
-- Adds `image_url` to `scout_messages` so Scout's 1:1 thread can
-- carry user-attached photos. Storage path mirrors the other two
-- chat surfaces: `<uid>/scout/<timestamp>.<ext>` in the public
-- avatars bucket.

alter table public.scout_messages
  add column if not exists image_url text;

comment on column public.scout_messages.image_url is
  'Optional public URL for a photo attached to a Scout 1:1 message.';
