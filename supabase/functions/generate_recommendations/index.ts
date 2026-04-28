// v1.1 — Stays + Eats
// generate_recommendations: one LLM call per trip → area pick + hotel
// recs + restaurant recs, inserted into trip_recommendations.
// Mirrors generate_itinerary's shape (skip-if-exists, ai_prompts row,
// JSON parse with recovery, photo cache, trip_event fan-out).

import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });
const UNSPLASH_KEY = Deno.env.get("UNSPLASH_ACCESS_KEY"); // optional

function normalizeQuery(q: string): string {
  return q.toLowerCase().trim().replace(/\s+/g, " ");
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

function bookingUrlFor(name: string, destination: string): string {
  // Phase 1: search URL with no affiliate ID. Phase 3 swaps in &aid=...
  const q = `${name}, ${destination}`;
  return `https://www.booking.com/searchresults.html?ss=${encodeURIComponent(q)}`;
}

// Resolve the trip's selected_destination against destination_guides.
// Match by slug-like normalization OR by aliases array. Returns the
// full guide row (jsonb included) or null if no match.
async function findGuideSeed(
  supabase: SupabaseClient,
  destination: string,
): Promise<Record<string, unknown> | null> {
  const norm = destination.toLowerCase().trim();
  const slug = norm.replace(/[\s,]+/g, "-").replace(/[^a-z0-9-]/g, "");

  // Try slug first (cheap PK lookup).
  const { data: bySlug } = await supabase
    .from("destination_guides")
    .select("*")
    .eq("slug", slug)
    .maybeSingle();
  if (bySlug) return bySlug;

  // Fall back to aliases array contains.
  const { data: byAlias } = await supabase
    .from("destination_guides")
    .select("*")
    .contains("aliases", [norm])
    .maybeSingle();
  return byAlias ?? null;
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

    // Build rows + collect photo queries to fetch in parallel.
    const rows: Record<string, unknown>[] = [];
    const queryByKey = new Map<string, string>();

    // Area row (kind='area'), rank 0.
    if (parsed.area && parsed.area.name) {
      const key = `area:0`;
      const photoQuery = parsed.area.image_query
        ?? `${parsed.area.name} ${trip.selected_destination}`;
      queryByKey.set(key, photoQuery);
      rows.push({
        trip_id,
        kind: "area",
        rank: 0,
        name: parsed.area.name,
        neighborhood: parsed.area.name,
        reason: parsed.area.reason ?? null,
        vibe_tags: parsed.area.vibe_tags ?? [],
        maps_url: mapsUrlFor(parsed.area.name, trip.selected_destination),
      });
    }

    const hotels = Array.isArray(parsed.hotels) ? parsed.hotels : [];
    for (let i = 0; i < hotels.length; i++) {
      const h = hotels[i];
      if (!h?.name) continue;
      const key = `hotel:${i}`;
      const photoQuery = h.image_query ?? `${h.name} ${trip.selected_destination}`;
      queryByKey.set(key, photoQuery);
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
        maps_url: mapsUrlFor(h.name, trip.selected_destination),
        booking_url: bookingUrlFor(h.name, trip.selected_destination),
      });
    }

    const restaurants = Array.isArray(parsed.restaurants) ? parsed.restaurants : [];
    for (let i = 0; i < restaurants.length; i++) {
      const r = restaurants[i];
      if (!r?.name) continue;
      const key = `restaurant:${i}`;
      const photoQuery = r.image_query ?? `${r.name} ${trip.selected_destination}`;
      queryByKey.set(key, photoQuery);
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
        maps_url: mapsUrlFor(r.name, trip.selected_destination),
      });
    }

    // Fetch images in parallel (concurrency 3 — same as generate_itinerary).
    const queryEntries = Array.from(queryByKey.entries());
    const photoUrls = await mapWithLimit(
      queryEntries.map(([_, q]) => q),
      3,
      (q) => photoFor(supabase, q),
    );
    const photoByKey = new Map<string, string | null>();
    queryEntries.forEach(([key, _], i) => photoByKey.set(key, photoUrls[i]));

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
