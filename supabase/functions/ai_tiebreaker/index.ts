import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";
import { createClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

Deno.serve(async (req) => {
  try {
    const { trip_id } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: trip } = await supabase
      .from("trips")
      .select("*, squad_members(*), trip_options(*)")
      .eq("id", trip_id)
      .single();

    if (!trip) {
      return new Response(JSON.stringify({ error: "Trip not found" }), {
        status: 404,
      });
    }

    const { data: promptRow } = await supabase
      .from("ai_prompts")
      .select("prompt, model")
      .eq("key", "ai_tiebreaker")
      .eq("active", true)
      .single();

    const squadSummary = trip.squad_members.map((m: any) => ({
      vibes: m.vibes,
      budget_max: m.budget_max,
      destination_prefs: m.destination_prefs,
    }));

    const optionsSummary = trip.trip_options.map((o: any) => ({
      id: o.id,
      destination: o.destination,
      vote_count: o.vote_count,
      compatibility_score: o.compatibility_score,
      estimated_cost_pp: o.estimated_cost_pp,
    }));

    const prompt = (promptRow?.prompt ?? "")
      .replace("{{options}}", JSON.stringify(optionsSummary, null, 2))
      .replace("{{squad_data}}", JSON.stringify(squadSummary, null, 2));

    const message = await anthropic.messages.create({
      model: promptRow?.model ?? "claude-sonnet-4-20250514",
      max_tokens: 500,
      messages: [{ role: "user", content: prompt }],
    });

    const raw = (message.content[0] as { text: string }).text;
    const json = raw.replace(/```json\n?|\n?```/g, "").trim();
    const { winner_id, reason } = JSON.parse(json);

    // Find full winner option
    const winner = trip.trip_options.find((o: any) => o.id === winner_id);

    if (!winner) {
      return new Response(JSON.stringify({ error: "Winner not found" }), {
        status: 400,
      });
    }

    // Set winner on trip
    await supabase.from("trips").update({
      selected_destination: winner.destination,
      selected_flag: winner.flag,
      status: "revealed",
    }).eq("id", trip_id);

    // Post AI message in chat
    await supabase.from("chat_messages").insert({
      trip_id,
      nickname: "TripSquad AI",
      emoji: "🤖",
      content: `🎯 AI picked **${winner.destination}** — ${reason}`,
      is_ai: true,
    });

    return new Response(
      JSON.stringify({ winner, reason }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
