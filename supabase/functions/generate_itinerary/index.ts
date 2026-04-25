import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });
const UNSPLASH_KEY = Deno.env.get("UNSPLASH_ACCESS_KEY"); // optional

function normalizeQuery(q: string): string {
  return q.toLowerCase().trim().replace(/\s+/g, " ");
}

/// Best-effort parse of the model's itinerary JSON. Claude occasionally
/// adds trailing prose, trailing commas, or truncates. We try a few
/// recovery strategies before giving up so the host doesn't see a 500
/// for a single stray comma.
function parseItineraryJson(raw: string): any | null {
  // Strip markdown fences.
  let s = raw.replace(/```json\n?|\n?```/g, "").trim();
  try { return JSON.parse(s); } catch (_) { /* continue */ }

  // Extract the largest balanced {...} block.
  const start = s.indexOf("{");
  const end = s.lastIndexOf("}");
  if (start !== -1 && end !== -1 && end > start) {
    const slice = s.slice(start, end + 1);
    try { return JSON.parse(slice); } catch (_) { s = slice; }
  }

  // Strip trailing commas before } or ]
  const cleaned = s.replace(/,(\s*[}\]])/g, "$1");
  try { return JSON.parse(cleaned); } catch (_) { /* continue */ }

  // Try truncating at the last complete "}," followed by a newline.
  const lastGoodClose = cleaned.lastIndexOf("}\n");
  if (lastGoodClose > 0) {
    const truncated = cleaned.slice(0, lastGoodClose + 1);
    // Close off the outer structure if needed.
    const closed = ensureBalanced(truncated);
    try { return JSON.parse(closed); } catch (_) { /* fallthrough */ }
  }

  return null;
}

function ensureBalanced(s: string): string {
  let open = 0, bracket = 0;
  for (const c of s) {
    if (c === "{") open++;
    else if (c === "}") open--;
    else if (c === "[") bracket++;
    else if (c === "]") bracket--;
  }
  return s + "]".repeat(Math.max(0, bracket)) + "}".repeat(Math.max(0, open));
}

// Cached, throttled Unsplash lookup. Reuses prior results (including null
// results) so we don't burn rate limit re-fetching things we already know.
async function photoFor(
  supabase: SupabaseClient,
  rawQuery: string,
): Promise<string | null> {
  if (!UNSPLASH_KEY) return null;
  const query = normalizeQuery(rawQuery);
  if (query.length < 2) return null;

  // Cache hit?
  const { data: cached } = await supabase
    .from("photo_cache")
    .select("url, fetched_at")
    .eq("query", query)
    .maybeSingle();
  if (cached) {
    return (cached.url as string | null) ?? null;
  }

  // Cache miss — fetch Unsplash
  try {
    const url = new URL("https://api.unsplash.com/search/photos");
    url.searchParams.set("query", query);
    url.searchParams.set("per_page", "1");
    url.searchParams.set("orientation", "landscape");
    const res = await fetch(url.toString(), {
      headers: { Authorization: `Client-ID ${UNSPLASH_KEY}` },
    });
    // On 429 (rate-limited) or any failure, do NOT cache negative —
    // let a future call retry.
    if (!res.ok) {
      console.warn("unsplash", res.status, query);
      return null;
    }
    const data = await res.json();
    const found =
      (data?.results?.[0]?.urls?.regular as string | undefined) ?? null;
    // Cache result (including null — no match exists for this query)
    await supabase.from("photo_cache").upsert({ query, url: found });
    return found;
  } catch (e) {
    console.warn("unsplash error", e);
    return null;
  }
}

// Run async tasks with bounded concurrency so we don't hammer Unsplash
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

    // Skip if itinerary already generated and not regenerating
    if (!regenerate) {
      const { count } = await supabase
        .from("itinerary_items")
        .select("*", { count: "exact", head: true })
        .eq("trip_id", trip_id);
      if ((count ?? 0) > 0) {
        return new Response(
          JSON.stringify({ skipped: true, existing: count }),
          { headers: { "Content-Type": "application/json" } },
        );
      }
    }

    const { data: promptRow } = await supabase
      .from("ai_prompts")
      .select("prompt, model")
      .eq("key", "generate_itinerary")
      .eq("active", true)
      .single();

    const season = trip.start_date
      ? getSeason(new Date(trip.start_date))
      : "summer";

    const prompt = (promptRow?.prompt ?? "")
      .replace("{{destination}}", trip.selected_destination)
      .replace("{{duration}}", String(trip.duration_days ?? 5))
      .replace("{{vibes}}", JSON.stringify(trip.vibes))
      .replace("{{group_size}}", String(trip.squad_members.length))
      .replace("{{budget}}", String(trip.estimated_budget ?? 1200))
      .replace("{{mode}}", trip.mode)
      .replace("{{season}}", season);

    const message = await anthropic.messages.create({
      model: promptRow?.model ?? "claude-sonnet-4-20250514",
      max_tokens: 8000,
      messages: [{ role: "user", content: prompt }],
    });

    const raw = (message.content[0] as { text: string }).text;
    const parsed = parseItineraryJson(raw);
    if (!parsed) {
      console.error("itinerary JSON parse failed. raw tail:",
        raw.slice(-400));
      return new Response(
        JSON.stringify({ error: "itinerary JSON parse failed" }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    // If regenerating, wipe prior items
    if (regenerate) {
      await supabase.from("itinerary_items")
        .delete().eq("trip_id", trip_id);
    }

    // Flatten days → activities. Build rows + a unique list of photo queries.
    const rows: Record<string, unknown>[] = [];
    const queryByKey = new Map<string, string>();
    for (const day of parsed.days ?? []) {
      const dayNum = day.day_number ?? 1;
      const items = day.items ?? [];
      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        const key = `${dayNum}:${i}`;
        const photoQuery = `${item.title} ${trip.selected_destination}`;
        queryByKey.set(key, photoQuery);
        const costCents = typeof item.estimatedCost === "number"
          ? Math.round(item.estimatedCost * 100)
          : typeof item.estimated_cost === "number"
            ? Math.round(item.estimated_cost * 100)
            : null;
        rows.push({
          trip_id,
          day_number: dayNum,
          time_of_day: (item.timeOfDay ?? item.time_of_day ?? "morning").toLowerCase(),
          title: item.title ?? "Activity",
          description: item.description ?? null,
          location: item.location ?? null,
          estimated_cost_cents: costCents,
          booking_url: item.bookingUrl ?? item.booking_url ?? null,
          order_index: i,
          _photo_key: key,
        });
      }
    }

    // Fetch photos with concurrency limit 3 + cache
    const keys = Array.from(queryByKey.keys());
    const photos = await mapWithLimit(keys, 3, async (key) => {
      const url = await photoFor(supabase, queryByKey.get(key)!);
      return { key, url };
    });
    const photoMap = new Map<string, string>();
    for (const p of photos) {
      if (p.url) photoMap.set(p.key, p.url);
    }
    for (const r of rows) {
      const key = r._photo_key as string;
      delete r._photo_key;
      const url = photoMap.get(key);
      if (url) r.image_url = url;
    }

    if (rows.length > 0) {
      const { error: insertErr } = await supabase
        .from("itinerary_items")
        .insert(rows);
      if (insertErr) throw insertErr;
    }

    // Also keep legacy itinerary_days for backward compat (Day headers)
    const daysToInsert = (parsed.days ?? []).map((day: any) => ({
      trip_id,
      day_number: day.day_number,
      title: day.title,
      items: [], // Empty — real items are in itinerary_items now
      packing: day.packing ?? [],
    }));
    if (daysToInsert.length > 0) {
      await supabase.from("itinerary_days").delete().eq("trip_id", trip_id);
      await supabase.from("itinerary_days").insert(daysToInsert);
    }

    // Flip trip to planning
    await supabase.from("trips")
      .update({ status: "planning" })
      .eq("id", trip_id);

    // Notify the whole squad that the itinerary is ready. Writes a
    // trip_event; the fan_out_trip_event trigger creates a
    // notifications row per squad member (the actor_user_id is null
    // so NO ONE is excluded — everyone sees it). Tapping the inbox
    // row routes to the trip's plan tab.
    try {
      await supabase.from("trip_events").insert({
        trip_id,
        kind: "itinerary_ready",
        actor_user_id: null,
        payload: {
          title: `itinerary ready for ${trip.selected_destination} 🗺️`,
          body: "tap to check out your day-by-day plan",
        },
      });
    } catch (e) {
      console.warn("itinerary_ready event insert failed", e);
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

function getSeason(date: Date): string {
  const month = date.getMonth() + 1;
  if (month >= 3 && month <= 5) return "spring";
  if (month >= 6 && month <= 8) return "summer";
  if (month >= 9 && month <= 11) return "autumn";
  return "winter";
}
