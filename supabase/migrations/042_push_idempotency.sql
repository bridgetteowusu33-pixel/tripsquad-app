-- ─────────────────────────────────────────────────────────────
-- 042 — Idempotency guard for push delivery
--
-- A duplicate webhook (or a retry) can cause `send_push` to run
-- multiple times for the same notification row. Each run issues an
-- FCM push, so the user sees N banners for one logical event.
--
-- We add a `pushed_at` column and the edge function "claims" a
-- notification atomically:
--   UPDATE notifications
--     SET pushed_at = now()
--     WHERE id = :id AND pushed_at IS NULL
--     RETURNING id;
-- If zero rows come back, another worker already sent this push;
-- the current invocation exits early.
-- ─────────────────────────────────────────────────────────────

alter table public.notifications
  add column if not exists pushed_at timestamptz;

create index if not exists idx_notifications_pushed_at
  on public.notifications(id) where pushed_at is null;
