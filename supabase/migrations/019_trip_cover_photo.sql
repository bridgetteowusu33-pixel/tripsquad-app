-- 019_trip_cover_photo.sql
--
-- Adds `cover_photo_url` to the `trips` table so hosts can override
-- the Unsplash destination-hint fallback with a photo of their own.
-- Stored as the public URL of an uploaded object in the `avatars`
-- bucket (same bucket we already allow for user avatars).

alter table public.trips
  add column if not exists cover_photo_url text;

comment on column public.trips.cover_photo_url is
  'Host-uploaded cover photo (public URL in avatars bucket). Null => fall back to destination Unsplash hint.';
