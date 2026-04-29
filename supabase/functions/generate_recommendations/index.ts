// v1.1 — Stays + Eats
// generate_recommendations: one LLM call per trip → area pick + hotel
// recs + restaurant recs, inserted into trip_recommendations.
// Mirrors generate_itinerary's shape (skip-if-exists, ai_prompts row,
// JSON parse with recovery, photo cache, trip_event fan-out).

import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });
const UNSPLASH_KEY = Deno.env.get("UNSPLASH_ACCESS_KEY"); // optional
// Google Places API (New) — used as the *primary* photo source for
// hotel/restaurant cards. Real photos of the actual business uploaded
// by users + owners on Google Maps. Falls back to Unsplash + gradient
// placeholder. ~$0.039 per place lookup (text search + photo media)
// with a $200/mo free tier from Google.
const GOOGLE_PLACES_KEY = Deno.env.get("GOOGLE_PLACES_API_KEY");

function normalizeQuery(q: string): string {
  return q.toLowerCase().trim().replace(/\s+/g, " ");
}

// Strip leading flag emoji and other non-ASCII prefix from a
// destination string. Unsplash search returns nothing for queries
// like "🇲🇽 Mexico City" — the emoji bytes URL-encode oddly. Doing
// this on every photo query so we get actual photos back.
function stripLeadingNonAscii(s: string): string {
  let out = s;
  while (out.length > 0 && out.charCodeAt(0) > 127) {
    out = out.slice(1);
  }
  return out.trim();
}

// JSON recovery — same strategies as generate_itinerary.
function parseRecsJson(raw: string): any | null {
  let s = raw.replace(/```json\n?|\n?```/g, "").trim();
  try { return JSON.parse(s); } catch (_) { /* continue */ }

  const start = s.indexOf("{");
  const end = s.lastIndexOf("}");
  if (start !== -1 && end !== -1 && end > start) {
    const slice = s.slice(start, end + 1);
    try { return JSON.parse(slice); } catch (_) { s = slice; }
  }
  const cleaned = s.replace(/,(\s*[}\]])/g, "$1");
  try { return JSON.parse(cleaned); } catch (_) { /* continue */ }

  return null;
}

async function photoFor(
  supabase: SupabaseClient,
  rawQuery: string,
): Promise<string | null> {
  if (!UNSPLASH_KEY) return null;
  const query = normalizeQuery(rawQuery);
  if (query.length < 2) return null;

  const { data: cached } = await supabase
    .from("photo_cache")
    .select("url")
    .eq("query", query)
    .maybeSingle();
  if (cached) return (cached.url as string | null) ?? null;

  try {
    const url = new URL("https://api.unsplash.com/search/photos");
    url.searchParams.set("query", query);
    url.searchParams.set("per_page", "1");
    url.searchParams.set("orientation", "landscape");
    const res = await fetch(url.toString(), {
      headers: { Authorization: `Client-ID ${UNSPLASH_KEY}` },
    });
    if (!res.ok) return null;
    const data = await res.json();
    const found =
      (data?.results?.[0]?.urls?.regular as string | undefined) ?? null;
    await supabase.from("photo_cache").upsert({ query, url: found });
    return found;
  } catch (_) {
    return null;
  }
}

// Try a list of queries in order, returning the first non-null result.
// Used to gracefully degrade from specific (e.g. "Condesa Mexico City
// hotel") to broad (e.g. "Mexico City") when Unsplash has no match
// for the more specific phrasing. Most cities will have *some* photo
// at the broadest fallback.
async function photoForWithFallback(
  supabase: SupabaseClient,
  candidates: string[],
): Promise<string | null> {
  for (const q of candidates) {
    if (!q || q.trim().length < 2) continue;
    const found = await photoFor(supabase, q);
    if (found) return found;
  }
  return null;
}

/// Google Places API (New) — fetch a real photo of a specific
/// business. One text-search + one photo-media call per lookup.
/// Cached in photo_cache with a `gp:` prefix so the cache key
/// space doesn't collide with Unsplash entries.
async function googlePlacePhoto(
  supabase: SupabaseClient,
  rawQuery: string,
): Promise<string | null> {
  if (!GOOGLE_PLACES_KEY) return null;
  const norm = normalizeQuery(rawQuery);
  if (norm.length < 2) return null;
  const cacheKey = `gp:${norm}`;

  const { data: cached } = await supabase
    .from("photo_cache")
    .select("url")
    .eq("query", cacheKey)
    .maybeSingle();
  if (cached) return (cached.url as string | null) ?? null;

  try {
    // Text Search returns up to 1 result with the place id + photo refs.
    // FieldMask is required by the new API — omit it and the call fails.
    const searchRes = await fetch(
      "https://places.googleapis.com/v1/places:searchText",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": GOOGLE_PLACES_KEY,
          "X-Goog-FieldMask": "places.id,places.photos",
        },
        body: JSON.stringify({ textQuery: rawQuery, pageSize: 1 }),
      },
    );
    if (!searchRes.ok) {
      console.warn("places searchText", searchRes.status, rawQuery);
      // Cache null so we don't retry indefinitely on quota issues.
      await supabase.from("photo_cache")
        .upsert({ query: cacheKey, url: null });
      return null;
    }
    const searchData = await searchRes.json();
    const photoName: string | undefined =
      searchData?.places?.[0]?.photos?.[0]?.name;
    if (!photoName) {
      await supabase.from("photo_cache")
        .upsert({ query: cacheKey, url: null });
      return null;
    }

    // Photo Media with skipHttpRedirect=true returns the resolved
    // googleusercontent.com URL as JSON. That URL is publicly
    // cacheable for the photo's lifetime — clients fetch it
    // directly without our API key.
    const photoUrl =
      `https://places.googleapis.com/v1/${photoName}/media` +
      `?maxWidthPx=800&skipHttpRedirect=true&key=${GOOGLE_PLACES_KEY}`;
    const photoRes = await fetch(photoUrl);
    if (!photoRes.ok) {
      console.warn("places photo media", photoRes.status, photoName);
      await supabase.from("photo_cache")
        .upsert({ query: cacheKey, url: null });
      return null;
    }
    const photoData = await photoRes.json();
    const photoUri: string | null = photoData?.photoUri ?? null;
    await supabase.from("photo_cache")
      .upsert({ query: cacheKey, url: photoUri });
    return photoUri;
  } catch (e) {
    console.warn("google places photo error", e);
    return null;
  }
}

/// Composite photo fetch: try Google Places (real photo of the
/// specific business) first, then fall back to topical Unsplash
/// queries, then null (UI renders a gradient placeholder).
async function photoForRec(
  supabase: SupabaseClient,
  googleQuery: string | null,
  unsplashCandidates: string[],
): Promise<string | null> {
  if (googleQuery && googleQuery.trim().length > 1) {
    const found = await googlePlacePhoto(supabase, googleQuery);
    if (found) return found;
  }
  return await photoForWithFallback(supabase, unsplashCandidates);
}

async function mapWithLimit<T, R>(
  items: T[],
  limit: number,
  fn: (t: T) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let cursor = 0;
  async function worker() {
    while (cursor < items.length) {
      const i = cursor++;
      results[i] = await fn(items[i]);
    }
  }
  const workers = Array.from({ length: Math.min(limit, items.length) }, () =>
    worker(),
  );
  await Promise.all(workers);
  return results;
}

function mapsUrlFor(name: string, destination: string): string {
  const q = `${name}, ${destination}`;
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(q)}`;
}

// Build the booking deep link via our affiliate_redirect endpoint
// so every click is attributed and tracked. The redirect's smart
// `best_hotel` routing picks Booking.com (when its AID is set) or
// Hotellook via Travelpayouts (always available as marker is set).
// Trip + recommendation IDs land in affiliate_clickthroughs for
// per-trip conversion analytics.
function bookingUrlFor(
  name: string,
  destination: string,
  tripId: string,
  recRank: number,
  checkIn: string | null,
  checkOut: string | null,
  groupAdults: number,
): string {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const search: Record<string, string> = {
    ss: `${name}, ${destination}`,
    group_adults: String(groupAdults),
  };
  if (checkIn) search.checkin = checkIn;
  if (checkOut) search.checkout = checkOut;
  const qB64 = btoa(JSON.stringify(search));
  const u = new URL(`${supabaseUrl}/functions/v1/affiliate_redirect`);
  u.searchParams.set("partner", "best_hotel");
  u.searchParams.set("kind", "hotel");
  u.searchParams.set("trip", tripId);
  u.searchParams.set("target", `hotel:${recRank}`);
  u.searchParams.set("q", qB64);
  return u.toString();
}

// Resolve the trip's selected_destination against destination_guides.
// Real-world destinations come as "🇲🇽 Mexico City", "Mexico City,
// Mexico", or plain "Mexico City". We strip leading flag emoji, then
// try aliases-contains and slug PK against full + city-only forms.
async function findGuideSeed(
  supabase: SupabaseClient,
  destination: string,
): Promise<Record<string, unknown> | null> {
  // Strip non-ASCII prefix (flag emojis, joiners) until we hit a
  // letter.
  let stripped = destination;
  while (stripped.length > 0 && stripped.charCodeAt(0) > 127) {
    stripped = stripped.slice(1);
  }
  const norm = stripped.toLowerCase().trim();
  if (!norm) return null;

  const cityOnly = norm.split(",")[0].trim();
  const candidates = Array.from(new Set([norm, cityOnly]));

  for (const cand of candidates) {
    const { data: byAlias } = await supabase
      .from("destination_guides")
      .select("*")
      .contains("aliases", [cand])
      .maybeSingle();
    if (byAlias) return byAlias;
  }

  const slug = (s: string) =>
    s.replace(/[\s,]+/g, "-").replace(/[^a-z0-9-]/g, "");
  for (const cand of candidates) {
    const s = slug(cand);
    if (!s) continue;
    const { data: bySlug } = await supabase
      .from("destination_guides")
      .select("*")
      .eq("slug", s)
      .maybeSingle();
    if (bySlug) return bySlug;
  }
  return null;
}

function summarizeItinerary(items: any[]): string {
  if (!items || items.length === 0) return "(no itinerary yet)";
  const byDay = new Map<number, string[]>();
  for (const it of items) {
    const d = it.day_number ?? 1;
    const arr = byDay.get(d) ?? [];
    if (it.title) arr.push(`${it.title}${it.location ? ` (${it.location})` : ""}`);
    byDay.set(d, arr);
  }
  const dayLines = Array.from(byDay.entries())
    .sort((a, b) => a[0] - b[0])
    .map(([d, list]) => `day ${d}: ${list.slice(0, 4).join(", ")}`);
  return dayLines.join(" | ");
}

Deno.serve(async (req) => {
  try {
    const { trip_id, regenerate } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: trip } = await supabase
      .from("trips")
      .select("*, squad_members(*)")
      .eq("id", trip_id)
      .single();

    if (!trip || !trip.selected_destination) {
      return new Response(
        JSON.stringify({ error: "No destination set for this trip" }),
        { status: 400 },
      );
    }

    // Skip if recs already generated and not regenerating.
    if (!regenerate) {
      const { count } = await supabase
        .from("trip_recommendations")
        .select("*", { count: "exact", head: true })
        .eq("trip_id", trip_id);
      if ((count ?? 0) > 0) {
        return new Response(
          JSON.stringify({ skipped: true, existing: count }),
          { headers: { "Content-Type": "application/json" } },
        );
      }
    }

    // Pull supporting context: itinerary items, curated guide.
    const { data: itinItems } = await supabase
      .from("itinerary_items")
      .select("title, day_number, location, item_type")
      .eq("trip_id", trip_id)
      .order("day_number", { ascending: true });

    const guideSeed = await findGuideSeed(supabase, trip.selected_destination);

    // Fetch the active prompt template.
    const { data: promptRow } = await supabase
      .from("ai_prompts")
      .select("prompt, model")
      .eq("key", "generate_recommendations")
      .eq("active", true)
      .single();

    if (!promptRow) {
      return new Response(
        JSON.stringify({ error: "generate_recommendations prompt missing" }),
        { status: 500 },
      );
    }

    const squadSize = (trip.squad_members as any[])?.length ?? 1;
    const duration = trip.duration_days ?? 5;
    const totalBudget = trip.estimated_budget ?? 1200;
    const perPersonPerDay = Math.max(
      40,
      Math.round(totalBudget / Math.max(1, squadSize) / Math.max(1, duration)),
    );
    const tripDates = trip.start_date && trip.end_date
      ? `${trip.start_date} to ${trip.end_date}`
      : "(dates not set)";
    const country = guideSeed?.country
      ? String(guideSeed.country)
      : (trip.selected_flag ?? "");

    const prompt = (promptRow.prompt as string)
      .replace("{{destination}}", trip.selected_destination)
      .replace("{{country}}", country)
      .replace("{{duration}}", String(duration))
      .replace("{{trip_dates}}", tripDates)
      .replace("{{group_size}}", String(squadSize))
      .replace("{{mode}}", String(trip.mode ?? "group"))
      .replace("{{vibes}}", JSON.stringify(trip.vibes ?? []))
      .replace("{{budget_per_person_per_day}}", String(perPersonPerDay))
      .replace("{{itinerary_days_summary}}", summarizeItinerary(itinItems ?? []))
      .replace("{{guide_seed_json}}", guideSeed ? JSON.stringify(guideSeed) : "(no curated knowledge for this destination — be conservative)");

    const message = await anthropic.messages.create({
      model: promptRow.model ?? "claude-sonnet-4-20250514",
      max_tokens: 6000,
      messages: [{ role: "user", content: prompt }],
    });

    const raw = (message.content[0] as { text: string }).text;
    const parsed = parseRecsJson(raw);
    if (!parsed) {
      console.error("recommendations JSON parse failed. raw tail:",
        raw.slice(-400));
      return new Response(
        JSON.stringify({ error: "recommendations JSON parse failed" }),
        { status: 502 },
      );
    }

    // If regenerating, wipe prior rows.
    if (regenerate) {
      await supabase.from("trip_recommendations")
        .delete().eq("trip_id", trip_id);
    }

    // Photo strategy per card:
    //  1. Google Places API: text search "{name} {destClean}" for a
    //     real photo of the specific business (hotels, restaurants).
    //     Areas (which are neighborhoods, not businesses) skip Google.
    //  2. Topical Unsplash fallback when Places returns nothing.
    //  3. Designed gradient placeholder client-side when both fail.
    const rows: Record<string, unknown>[] = [];
    type Plan = { google: string | null; unsplash: string[] };
    const plansByKey = new Map<string, Plan>();
    const dest = trip.selected_destination;
    const destClean = stripLeadingNonAscii(dest);

    // Photo query strategy: prefer specific neighborhood matches
    // (Unsplash has some), fall back to cuisine/type-themed photos
    // ONLY when they're still topical to the card. Drop the
    // generic-city fallbacks (skyline, street, dest-only) — those
    // produce "unrelated photo" UX. Cards with no photo render as a
    // designed gradient placeholder; better than mismatched stock.
    function areaQueries(name: string): string[] {
      // Neighborhood photos are sometimes on Unsplash. If not, no fallback.
      return [`${name} ${destClean}`.trim()];
    }
    function hotelQueries(neighborhood: string | null): string[] {
      const out: string[] = [];
      if (neighborhood) out.push(`${neighborhood} ${destClean} hotel`);
      // No city-only fallback — would return a skyline that doesn't
      // represent the hotel. Empty card > misleading photo.
      return out;
    }
    function restaurantQueries(
      cuisine: string | null,
      neighborhood: string | null,
    ): string[] {
      const out: string[] = [];
      // Cuisine photos are abundant and TOPICAL — a taco photo on a
      // taco restaurant card is fine even if it's not the actual
      // restaurant. Keep these.
      if (cuisine) out.push(`${cuisine} food ${destClean}`);
      if (cuisine) out.push(`${cuisine} food`);
      if (neighborhood) out.push(`${neighborhood} ${destClean} restaurant`);
      // No city-only fallback (avoid unrelated city food shots).
      return out;
    }

    // Area row (kind='area'), rank 0.
    if (parsed.area && parsed.area.name) {
      const key = `area:0`;
      plansByKey.set(key, {
        // Areas are neighborhoods, not single businesses — Places
        // search rarely returns a useful photo. Stick to Unsplash.
        google: null,
        unsplash: areaQueries(parsed.area.name),
      });
      rows.push({
        trip_id,
        kind: "area",
        rank: 0,
        name: parsed.area.name,
        neighborhood: parsed.area.name,
        reason: parsed.area.reason ?? null,
        vibe_tags: parsed.area.vibe_tags ?? [],
        maps_url: mapsUrlFor(parsed.area.name, dest),
      });
    }

    const hotels = Array.isArray(parsed.hotels) ? parsed.hotels : [];
    for (let i = 0; i < hotels.length; i++) {
      const h = hotels[i];
      if (!h?.name) continue;
      const key = `hotel:${i}`;
      plansByKey.set(key, {
        google: `${h.name} ${destClean}`.trim(),
        unsplash: hotelQueries(h.neighborhood ?? null),
      });
      rows.push({
        trip_id,
        kind: "hotel",
        rank: i,
        name: h.name,
        neighborhood: h.neighborhood ?? null,
        price_band: h.price_band ?? null,
        vibe_tags: h.vibe_tags ?? [],
        reason: h.reason ?? null,
        day_anchor: typeof h.day_anchor === "number" ? h.day_anchor : null,
        maps_url: mapsUrlFor(h.name, dest),
        booking_url: bookingUrlFor(
          h.name,
          dest,
          trip_id,
          i,
          trip.start_date ?? null,
          trip.end_date ?? null,
          squadSize,
        ),
      });
    }

    const restaurants = Array.isArray(parsed.restaurants) ? parsed.restaurants : [];
    for (let i = 0; i < restaurants.length; i++) {
      const r = restaurants[i];
      if (!r?.name) continue;
      const key = `restaurant:${i}`;
      plansByKey.set(key, {
        google: `${r.name} ${destClean}`.trim(),
        unsplash: restaurantQueries(r.cuisine ?? null, r.neighborhood ?? null),
      });
      rows.push({
        trip_id,
        kind: "restaurant",
        rank: i,
        name: r.name,
        neighborhood: r.neighborhood ?? null,
        cuisine: r.cuisine ?? null,
        price_band: r.price_band ?? null,
        meal: r.meal ?? null,
        vibe_tags: r.vibe_tags ?? [],
        reason: r.reason ?? null,
        day_anchor: typeof r.day_anchor === "number" ? r.day_anchor : null,
        maps_url: mapsUrlFor(r.name, dest),
      });
    }

    // Fetch images in parallel (concurrency 3). Each plan tries
    // Google Places first, then Unsplash fallbacks. Null means
    // "render the gradient placeholder client-side".
    const planEntries = Array.from(plansByKey.entries());
    const photoUrls = await mapWithLimit(
      planEntries.map(([_, p]) => p),
      3,
      (p) => photoForRec(supabase, p.google, p.unsplash),
    );
    const photoByKey = new Map<string, string | null>();
    planEntries.forEach(([key, _], i) => photoByKey.set(key, photoUrls[i]));

    // Stitch image_url onto each row by reconstructing its key.
    let areaRowIdx = 0, hotelIdx = 0, restaurantIdx = 0;
    for (const row of rows) {
      let key = "";
      if (row.kind === "area") { key = `area:${areaRowIdx++}`; }
      else if (row.kind === "hotel") { key = `hotel:${hotelIdx++}`; }
      else if (row.kind === "restaurant") { key = `restaurant:${restaurantIdx++}`; }
      row.image_url = photoByKey.get(key) ?? null;
    }

    if (rows.length === 0) {
      return new Response(
        JSON.stringify({ error: "model returned no usable recommendations" }),
        { status: 502 },
      );
    }

    const { error: insertErr } = await supabase
      .from("trip_recommendations")
      .insert(rows);
    if (insertErr) {
      console.error("trip_recommendations insert", insertErr);
      return new Response(
        JSON.stringify({ error: insertErr.message }),
        { status: 500 },
      );
    }

    // Notify the squad (mirrors itinerary_ready). Fan-out trigger
    // creates one notification per squad member.
    try {
      await supabase.from("trip_events").insert({
        trip_id,
        kind: "recommendations_ready",
        actor_user_id: null,
        payload: {
          title: `scout picked your stays + eats for ${trip.selected_destination} 🏨`,
          body: "tap to see where to sleep and where to eat",
        },
      });
    } catch (e) {
      console.warn("recommendations_ready event insert failed", e);
    }

    return new Response(
      JSON.stringify({ created: rows.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
