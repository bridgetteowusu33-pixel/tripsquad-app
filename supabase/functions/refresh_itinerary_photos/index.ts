import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

const UNSPLASH_KEY = Deno.env.get("UNSPLASH_ACCESS_KEY");

function normalizeQuery(q: string): string {
  return q.toLowerCase().trim().replace(/\s+/g, " ");
}

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
    if (!res.ok) {
      console.warn("unsplash", res.status, query);
      return null;
    }
    const data = await res.json();
    const found =
      (data?.results?.[0]?.urls?.regular as string | undefined) ?? null;
    await supabase.from("photo_cache").upsert({ query, url: found });
    return found;
  } catch (e) {
    console.warn("unsplash error", e);
    return null;
  }
}

Deno.serve(async (req) => {
  try {
    const { trip_id, overwrite } = await req.json();
    if (!trip_id) {
      return new Response(JSON.stringify({ error: "trip_id required" }), {
        status: 400,
      });
    }
    if (!UNSPLASH_KEY) {
      return new Response(
        JSON.stringify({ error: "UNSPLASH_ACCESS_KEY not configured" }),
        { status: 500 },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: trip } = await supabase
      .from("trips")
      .select("selected_destination")
      .eq("id", trip_id)
      .single();
    const destination = trip?.selected_destination ?? "";

    let query = supabase.from("itinerary_items")
      .select("id, title, location")
      .eq("trip_id", trip_id);
    if (!overwrite) query = query.is("image_url", null);
    const { data: items } = await query;

    if (!items || items.length === 0) {
      return new Response(JSON.stringify({ updated: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const capped = items.slice(0, 40);
    let updated = 0;
    // Sequential with 200ms spacing so we don't exceed Unsplash limits —
    // cached queries return instantly so real calls are already deduped.
    for (const item of capped) {
      const queryText = `${item.title} ${destination}`.trim();
      const photo = await photoFor(supabase, queryText);
      if (photo) {
        await supabase.from("itinerary_items")
          .update({ image_url: photo })
          .eq("id", item.id);
        updated++;
      }
      // Light throttle — cached hits skip this fine, but fresh ones stagger
      await new Promise((r) => setTimeout(r, 120));
    }

    return new Response(
      JSON.stringify({ updated, attempted: capped.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
