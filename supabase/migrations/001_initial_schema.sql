-- ─────────────────────────────────────────────────────────────
--  TRIPSQUAD — Initial Schema
--  Run in Supabase SQL Editor or via supabase db push
-- ─────────────────────────────────────────────────────────────

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── PROFILES ─────────────────────────────────────────────────
create table public.profiles (
  id               uuid references auth.users on delete cascade primary key,
  nickname         text,
  emoji            text default '😎',
  tier             text not null default 'free'
                    check (tier in ('free', 'trip_pass', 'explorer')),
  passport_stamps  text[] default '{}',
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "Users can view own profile"
  on profiles for select using (auth.uid() = id);
create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);
create policy "Users can insert own profile"
  on profiles for insert with check (auth.uid() = id);

-- ── TRIPS ─────────────────────────────────────────────────────
create table public.trips (
  id                    uuid default uuid_generate_v4() primary key,
  host_id               uuid references public.profiles(id) on delete cascade not null,
  name                  text not null,
  mode                  text not null default 'group'
                          check (mode in ('group', 'solo', 'match')),
  status                text not null default 'collecting'
                          check (status in ('draft','collecting','voting','revealed','planning','live','completed')),
  invite_token          text unique,
  vibes                 text[] default '{}',
  destination_shortlist text[] default '{}',
  selected_destination  text,
  selected_flag         text,
  start_date            date,
  end_date              date,
  duration_days         int generated always as (
    case when end_date is not null and start_date is not null
    then (end_date - start_date) else null end
  ) stored,
  estimated_budget      int,
  created_at            timestamptz default now(),
  updated_at            timestamptz default now()
);
alter table public.trips enable row level security;

-- Host can do everything; squad members can read
create policy "Host full access"
  on trips for all using (auth.uid() = host_id);
create policy "Squad members can read trip"
  on trips for select using (
    exists (
      select 1 from squad_members
      where trip_id = trips.id and user_id = auth.uid()
    )
  );

-- ── SQUAD MEMBERS ─────────────────────────────────────────────
create table public.squad_members (
  id                uuid default uuid_generate_v4() primary key,
  trip_id           uuid references public.trips(id) on delete cascade not null,
  user_id           uuid references public.profiles(id) on delete set null,
  nickname          text not null,
  emoji             text default '😎',
  role              text not null default 'member'
                      check (role in ('host', 'member')),
  status            text not null default 'invited'
                      check (status in ('invited', 'submitted', 'voted')),
  budget_min        int,
  budget_max        int,
  vibes             text[] default '{}',
  destination_prefs text[] default '{}',
  responded_at      timestamptz,
  created_at        timestamptz default now()
);
alter table public.squad_members enable row level security;
create policy "Trip members can view squad"
  on squad_members for select using (
    exists (
      select 1 from trips where id = trip_id and host_id = auth.uid()
    ) or user_id = auth.uid()
  );
create policy "Host can manage squad"
  on squad_members for all using (
    exists (select 1 from trips where id = trip_id and host_id = auth.uid())
  );

-- ── TRIP OPTIONS (AI-generated proposals) ─────────────────────
create table public.trip_options (
  id                  uuid default uuid_generate_v4() primary key,
  trip_id             uuid references public.trips(id) on delete cascade not null,
  destination         text not null,
  country             text not null,
  flag                text not null,
  tagline             text not null,
  description         text,
  estimated_cost_pp   int,
  duration_days       int,
  vibe_match          text[] default '{}',
  compatibility_score decimal(3,2),
  vote_count          int default 0,
  highlights          text[] default '{}',
  created_at          timestamptz default now()
);
alter table public.trip_options enable row level security;
create policy "Trip members can view options"
  on trip_options for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

-- ── VOTES ─────────────────────────────────────────────────────
create table public.votes (
  id        uuid default uuid_generate_v4() primary key,
  trip_id   uuid references public.trips(id) on delete cascade not null,
  option_id uuid references public.trip_options(id) on delete cascade not null,
  user_id   uuid references public.profiles(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique (trip_id, user_id)  -- one vote per person per trip
);
alter table public.votes enable row level security;
create policy "Users can vote"
  on votes for insert with check (auth.uid() = user_id);
create policy "Users can view votes"
  on votes for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

-- Auto-increment vote count
create or replace function increment_vote_count()
returns trigger language plpgsql security definer as $$
begin
  update trip_options set vote_count = vote_count + 1
  where id = new.option_id;
  -- Update squad member status to voted
  update squad_members set status = 'voted'
  where trip_id = new.trip_id and user_id = new.user_id;
  return new;
end;
$$;
create trigger on_vote_insert
  after insert on votes
  for each row execute function increment_vote_count();

-- ── ITINERARY DAYS ────────────────────────────────────────────
create table public.itinerary_days (
  id         uuid default uuid_generate_v4() primary key,
  trip_id    uuid references public.trips(id) on delete cascade not null,
  day_number int not null,
  title      text not null,
  items      jsonb default '[]',
  packing    jsonb default '[]',
  created_at timestamptz default now()
);
alter table public.itinerary_days enable row level security;
create policy "Trip members can view itinerary"
  on itinerary_days for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );

-- ── CHAT MESSAGES ─────────────────────────────────────────────
create table public.chat_messages (
  id         uuid default uuid_generate_v4() primary key,
  trip_id    uuid references public.trips(id) on delete cascade not null,
  user_id    uuid references public.profiles(id) on delete set null,
  nickname   text not null,
  emoji      text default '😎',
  content    text not null,
  is_ai      boolean default false,
  created_at timestamptz default now()
);
alter table public.chat_messages enable row level security;
create policy "Squad can read chat"
  on chat_messages for select using (
    exists (
      select 1 from trips t
      left join squad_members sm on sm.trip_id = t.id
      where t.id = trip_id
        and (t.host_id = auth.uid() or sm.user_id = auth.uid())
    )
  );
create policy "Squad can send messages"
  on chat_messages for insert with check (auth.uid() = user_id);

-- ── SQUAD FUND ────────────────────────────────────────────────
create table public.fund_contributions (
  id         uuid default uuid_generate_v4() primary key,
  trip_id    uuid references public.trips(id) on delete cascade not null,
  member_id  uuid references public.squad_members(id) on delete cascade not null,
  amount     int not null,  -- in cents
  target     int not null,  -- in cents
  logged_at  timestamptz default now()
);

-- ── AI PROMPTS (hot-swappable) ────────────────────────────────
create table public.ai_prompts (
  id         uuid default uuid_generate_v4() primary key,
  key        text unique not null,  -- e.g. 'generate_trip_options'
  prompt     text not null,
  model      text default 'claude-sonnet-4-20250514',
  version    int default 1,
  active     boolean default true,
  updated_at timestamptz default now()
);

-- ── REALTIME ─────────────────────────────────────────────────
-- Enable realtime for live squad updates
alter publication supabase_realtime
  add table trips, squad_members, votes, chat_messages;

-- ── UPDATED AT TRIGGER ────────────────────────────────────────
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
create trigger trips_updated_at before update on trips
  for each row execute function update_updated_at();
create trigger profiles_updated_at before update on profiles
  for each row execute function update_updated_at();

-- ── SEED: Default AI prompts ──────────────────────────────────
insert into public.ai_prompts (key, prompt) values
(
  'generate_trip_options',
  'You are TripSquad AI, an expert group travel planner.

Given the squad data below, generate exactly 3 destination proposals that best match the group.

SQUAD DATA:
{{squad_data}}

DESTINATION SHORTLIST:
{{shortlist}}

For each proposal return:
- destination, country, flag
- tagline (max 8 words, punchy)
- description (2 sentences)
- estimated_cost_pp (USD integer)
- duration_days
- vibe_match (array of 2-3 vibes from the squad)
- compatibility_score (0-1 decimal, how well it fits ALL members)
- highlights (array of 3 specific things to do)

Rank by compatibility_score descending.
Return ONLY valid JSON: { "options": [...] }'
),
(
  'generate_itinerary',
  'You are TripSquad AI, an expert travel itinerary planner.

Generate a detailed day-by-day itinerary for:
DESTINATION: {{destination}}
DURATION: {{duration}} days
VIBES: {{vibes}}
GROUP SIZE: {{group_size}}
BUDGET: ~${{budget}} per person
MODE: {{mode}}

For each day include:
- day_number, title
- 3-4 items per day, each with: title, timeOfDay (morning/afternoon/evening/night), description, estimatedCost, requiresBooking
- If mode is "solo", add a soloTip for each item (a specific tip for solo travellers)
- packing: array of {label, category} items relevant to this destination

Return ONLY valid JSON: { "days": [...] }'
),
(
  'generate_packing_list',
  'Generate a packing list for a trip to {{destination}} for {{duration}} days in {{season}}.
Categories: Clothing, Documents, Tech, Toiletries, Health, Extras.
Return ONLY valid JSON: { "items": [{label, category}] }'
),
(
  'ai_tiebreaker',
  'There is a tie in the TripSquad vote.

Tied options: {{options}}
Squad preferences: {{squad_data}}

Pick the single best option considering ALL squad members equally.
Explain your reasoning in one sentence.
Return ONLY valid JSON: { "winner_id": "...", "reason": "..." }'
);
