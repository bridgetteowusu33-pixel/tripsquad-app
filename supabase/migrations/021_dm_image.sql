-- 021_dm_image.sql
--
-- Adds an `image_url` column to `direct_messages` so DMs can
-- carry a photo attachment — parity with trip chat. Blobs live in
-- the same public `avatars` bucket under
-- `<uid>/dm/<other_user_id>/<timestamp>.<ext>` so storage RLS
-- (first folder = auth uid) continues to hold.

alter table public.direct_messages
  add column if not exists image_url text;

comment on column public.direct_messages.image_url is
  'Optional public URL for a photo attached to a DM.';
