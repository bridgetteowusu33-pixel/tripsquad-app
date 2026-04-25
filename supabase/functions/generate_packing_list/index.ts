import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";
import { createClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

const CATEGORY_EMOJI: Record<string, string> = {
  "clothing": "👕",
  "documents": "📘",
  "tech": "📱",
  "toiletries": "🧴",
  "health": "💊",
  "extras": "🎒",
};

function emojiFor(category: string): string {
  return CATEGORY_EMOJI[category.toLowerCase()] ?? "🎒";
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
      .select("selected_destination, duration_days, start_date")
      .eq("id", trip_id)
      .single();

    if (!trip?.selected_destination) {
      return new Response(JSON.stringify({ error: "No destination" }), {
        status: 400,
      });
    }

    // Skip if packing already generated and not explicitly regenerating
    if (!regenerate) {
      const { count } = await supabase
        .from("packing_items")
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
      .eq("key", "generate_packing_list")
      .eq("active", true)
      .single();

    const season = trip.start_date
      ? getSeason(new Date(trip.start_date))
      : "summer";

    const prompt = (promptRow?.prompt ?? "")
      .replace("{{destination}}", trip.selected_destination)
      .replace("{{duration}}", String(trip.duration_days ?? 5))
      .replace("{{season}}", season);

    const message = await anthropic.messages.create({
      model: promptRow?.model ?? "claude-haiku-4-5-20251001",
      max_tokens: 1000,
      messages: [{ role: "user", content: prompt }],
    });

    const raw = (message.content[0] as { text: string }).text;
    const json = raw.replace(/```json\n?|\n?```/g, "").trim();
    const parsed = JSON.parse(json);

    // If regenerating, clear existing AI-generated (not user-added) items
    if (regenerate) {
      await supabase.from("packing_items")
        .delete()
        .eq("trip_id", trip_id)
        .is("added_by", null);
    }

    // Write each item as its own row, tagged with category emoji
    const rows = (parsed.items as Array<{ label: string; category: string }>)
      .map((item, i) => ({
        trip_id,
        label: item.label,
        category: (item.category ?? "extras").toLowerCase(),
        emoji: emojiFor(item.category ?? "extras"),
        order_index: i,
        added_by: null, // AI-generated, not attributed to a user
      }));

    const { error: insertErr } = await supabase
      .from("packing_items")
      .insert(rows);
    if (insertErr) throw insertErr;

    // Notify the whole squad that the packing list is ready.
    try {
      await supabase.from("trip_events").insert({
        trip_id,
        kind: "packing_ready",
        actor_user_id: null,
        payload: {
          title: `packing list ready for ${trip.selected_destination} 🎒`,
          body: "tap to see what scout packed",
        },
      });
    } catch (e) {
      console.warn("packing_ready event insert failed", e);
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
  const m = date.getMonth() + 1;
  if (m >= 3 && m <= 5) return "spring";
  if (m >= 6 && m <= 8) return "summer";
  if (m >= 9 && m <= 11) return "autumn";
  return "winter";
}
