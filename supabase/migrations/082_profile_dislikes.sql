-- v1.2.0 — Scout memory layer
-- A `dislikes` array on profiles so Scout never recommends things the
-- user has explicitly opted out of (crowds, spicy food, long-haul
-- flights, casinos, all-inclusives, etc.). Filled organically over
-- time from chat ("i hate crowds" → scout adds "crowds" to dislikes)
-- and editable from settings (future v1.2.1 follow-up).
--
-- Default empty array so existing users aren't blocked by a NOT NULL.
-- RLS on profiles is already user-scoped (migration 001).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS dislikes text[] DEFAULT '{}';
