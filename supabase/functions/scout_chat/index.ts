import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";
import { createClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

const SCOUT_SYSTEM = `you are scout — tripsquad's ai travel companion.

voice: gen z, lowercase, punchy, fragments ok. emoji as punctuation not decoration.
never use corporate phrases like "i'd be happy to help" or "certainly!".
never ask follow-up clarifying questions longer than one sentence.
be specific with destinations, prices, seasons. give real answers, not hedges.
if you don't know, say so — don't make up flights or prices.

terms of address: default to "friend" if you need one, or just skip it and
lead with the answer. do NOT call anyone babe, bae, bestie, hon, love,
sweetie, or any romantic / pet term by default. only use those if the user
has explicitly told you "call me [term]" in this conversation.

if a photo is attached: describe what you see in one short line, then answer
the user's question. identify landmarks, cuisine type, city vibes, or signs
when you can. if unsure where it is, say what you notice and guess a region.`;

Deno.serve(async (req) => {
  try {
    // `private` = true means this is a solo-trip in-space Scout chat:
    // the assistant reply gets persisted to scout_messages with
    // trip_id set, NOT broadcast to the trip's group chat. v1.1.
    const { content, trip_id, image_url, private: isPrivate } = await req.json();
    if (!content || typeof content !== "string") {
      return new Response(JSON.stringify({ error: "content is required" }), {
        status: 400,
      });
    }

    // Extract caller's user_id from the forwarded JWT
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData } = await userClient.auth.getUser();
    const userId = userData?.user?.id;
    if (!userId) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
      });
    }

    const service = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Gather context: either a trip's squad data, or the user's recent history
    let context = "";
    if (trip_id) {
      const { data: trip } = await service
        .from("trips")
        .select("name, selected_destination, start_date, end_date, vibes, squad_members(nickname,vibes,budget_min,budget_max)")
        .eq("id", trip_id)
        .single();
      if (trip) context = `TRIP CONTEXT:\n${JSON.stringify(trip, null, 2)}\n\n`;
    } else {
      const { data: recent } = await service
        .from("scout_messages")
        .select("role, content")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(10);
      if (recent?.length) {
        const history = recent.reverse()
          .map((m: any) => `${m.role}: ${m.content}`)
          .join("\n");
        context = `RECENT CHAT:\n${history}\n\n`;
      }
    }

    // Build user content — switch to multi-block format when the
    // caller attached an image. Claude Sonnet 4 reads images from
    // public URLs directly (the TripSquad avatars bucket is public).
    const userContent: any = image_url && typeof image_url === "string"
      ? [
          { type: "image", source: { type: "url", url: image_url } },
          { type: "text", text: `${context}user: ${content}` },
        ]
      : `${context}user: ${content}`;

    const message = await anthropic.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: SCOUT_SYSTEM,
      messages: [{ role: "user", content: userContent }],
    });

    const reply = (message.content[0] as { text: string }).text.trim();

    // Persist
    if (trip_id && isPrivate) {
      // Solo trip in-space Scout — private 1:1 chat scoped to the trip.
      await service.from("scout_messages").insert({
        user_id: userId,
        role: "assistant",
        content: reply,
        trip_id,
      });
    } else if (trip_id) {
      // @scout tagged in a group chat — broadcast to the squad inline.
      await service.from("chat_messages").insert({
        trip_id,
        user_id: null,
        nickname: "scout",
        emoji: "🧭",
        content: reply,
        is_ai: true,
      });
    } else {
      // Global 1:1 Scout history (bottom-nav Scout tab).
      await service.from("scout_messages").insert({
        user_id: userId,
        role: "assistant",
        content: reply,
      });
    }

    return new Response(
      JSON.stringify({ reply }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
