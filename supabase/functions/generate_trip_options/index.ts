import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";
import { createClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

Deno.serve(async (req) => {
  try {
    const { trip_id } = await req.json();

    // Init Supabase with service role (bypasses RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Fetch trip + squad data
    const { data: trip } = await supabase
      .from("trips")
      .select("*, squad_members(*)")
      .eq("id", trip_id)
      .single();

    if (!trip) {
      return new Response(JSON.stringify({ error: "Trip not found" }), {
        status: 404,
      });
    }

    // Get prompt from DB (hot-swappable)
    const { data: promptRow } = await supabase
      .from("ai_prompts")
      .select("prompt, model")
      .eq("key", "generate_trip_options")
      .eq("active", true)
      .single();

    const squadSummary = trip.squad_members
      .filter((m: any) => m.status !== "invited")
      .map((m: any) => ({
        nickname: m.nickname,
        vibes: m.vibes,
        budget_min: m.budget_min,
        budget_max: m.budget_max,
        destination_prefs: m.destination_prefs,
      }));

    // Merge host shortlist + squad member suggestions into one list
    const allDests = new Set<string>(trip.destination_shortlist || []);
    for (const m of squadSummary) {
      for (const d of (m.destination_prefs || [])) {
        allDests.add(d);
      }
    }
    const mergedShortlist = Array.from(allDests);

    const prompt = (promptRow?.prompt ?? "")
      .replace("{{squad_data}}", JSON.stringify(squadSummary, null, 2))
      .replace(
        "{{shortlist}}",
        JSON.stringify(mergedShortlist, null, 2),
      );

    // Call Claude
    const message = await anthropic.messages.create({
      model: promptRow?.model ?? "claude-sonnet-4-20250514",
      max_tokens: 4000,
      messages: [{ role: "user", content: prompt }],
    });

    const raw = (message.content[0] as { text: string }).text;

    // Strip markdown fences if present
    const json = raw.replace(/```json\n?|\n?```/g, "").trim();
    const parsed = JSON.parse(json);

    // Persist options to DB
    const optionsToInsert = parsed.options.map((opt: any) => ({
      trip_id,
      destination: opt.destination,
      country: opt.country,
      flag: opt.flag,
      tagline: opt.tagline,
      description: opt.description,
      estimated_cost_pp: opt.estimated_cost_pp,
      duration_days: opt.duration_days,
      vibe_match: opt.vibe_match,
      compatibility_score: opt.compatibility_score,
      highlights: opt.highlights,
    }));

    const { data: insertedOptions } = await supabase
      .from("trip_options")
      .insert(optionsToInsert)
      .select();

    // Update trip status → voting
    await supabase
      .from("trips")
      .update({ status: "voting" })
      .eq("id", trip_id);

    return new Response(
      JSON.stringify({ options: insertedOptions }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
