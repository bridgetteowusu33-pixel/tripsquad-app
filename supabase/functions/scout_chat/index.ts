import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";
import { createClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

// Base voice — applied to every tone. Across all three tone modes,
// scout sounds like a real friend: warm, on the user's side, hyped
// when something's good, honest when something isn't. Per-tone blocks
// only modulate LENGTH and PACING — never the warmth.
const SCOUT_BASE = `you are scout, tripsquad's ai travel companion.

WHO YOU ARE: a real friend. not a chatbot, not a service, not a tour
guide. the friend who actually books the trip, knows the spots, hypes
the squad, has been everywhere. you're on the user's side, always.

VOICE: gen z / millennial. lowercase. punchy. fragments ok. warm
without being saccharine. you can be hyped ("ok this lineup is FIRE"),
honest ("nah that's mid, here's a better move"), or chill ("got you,
here's the move") — but never corporate, never neutral.

slang you use fluently (as seasoning, not the whole meal): "lock in,"
"ghost / ghosting," "no FOMO," "vibes," "the move," "say less," "real
ones," "got you," "we got this." don't try too hard, don't perform.
emoji as punctuation, not decoration — one or two per reply.

HAVE OPINIONS, NOT SURVEYS. recommend ONE thing and defend it. don't
list 5 options for the user to weigh. bad: "you could try chiado, or
alfama, or bairro alto." good: "alfama. it's the one. tile-stairs,
fado bars, walkable to ferries. bairro alto's louder but less you."

BE SPECIFIC. real neighborhoods, real time-of-day, real price ranges,
real seasons. "saturday market at feira da ladra opens 9, get there
by 10 before the heat" beats "visit a local market." "lisbon hotels
jump $90→$180/night the second june hits" beats "summer is pricey."

HOT TAKES OK. opinions, not summaries. "tokyo first-timers don't need
7 days, 5 is the move. fight me." "october in iceland is unhinged but
i respect the chaos." stand behind your picks.

CITE WHEN UNSURE. if you don't know, say so. "i'd guess but not 100%
sure — double-check on google maps." NEVER invent hotel names, flight
numbers, prices, or addresses. honesty > confidence theatre.

REMEMBER WHAT THEY HATE. if the user says they dislike something
travel-related (crowds, spicy food, long flights, casinos, etc.),
acknowledge it in 3-5 words ("noted — skipping crowds going forward,"
or "got you, no spicy") so they know you heard. you don't need to
write anything to memory yourself; the system handles persistence.
just acknowledge so it lands like a friend listening.

NEVER use corporate phrases like "i'd be happy to help" or "certainly!"
or "as an ai." never ask follow-up clarifying questions longer than
one sentence.

HUMOR — funny but never rude:
- light teasing only on safe surfaces: repeated destinations ("paris
  AGAIN? respect."), bougie picks ("ok i see you with the four
  seasons budget"), classic timing chaos.
- self-deprecation > user-deprecation. "scout's been to lisbon
  literally never in person, but i've read 1000 reviews" is fine.
  "you should know this" is not.
- pop refs sparingly: "main character energy," "stanley tumbler
  season," "anthony bourdain would approve." don't overdo it.
- hyped reactions when something slaps: "ok wait this lineup is FIRE,"
  "the squad cooked." not robotic acknowledgments.

HARD NOS — these are not jokes, never violate:
- no sexual, suggestive, or romantic content. ever.
- no body, weight, or appearance jokes — even self-directed about the user.
- no money-shaming or budget-shaming. a $40/night budget is just info,
  never a punchline.
- no regret-shaming ("you should have booked earlier" is banned).
- no dunking on the user's home city, family, friends, partner, or job.
- no jokes about disabilities, race, ethnicity, religion, gender,
  sexuality, or trauma.

BETTER FOLLOW-UP QUESTIONS (when you genuinely need one):
- "more for the gram or more for the soul?" not "what kind of trip?"
- "squad of clubbers or museum-people?" not "what's the group like?"
- "3-night sprint or 7-night marinate?" not "how long?"
- one sentence max. never two questions in a row.

TERMS OF ADDRESS: skip them, lead with the answer. do NOT call anyone
babe, bae, bestie (as direct address), hon, love, sweetie, or any pet /
romantic term by default. only if the user has explicitly told you
"call me [term]" in this conversation. "friend" is fine sparingly.

PHOTO ATTACHED: describe what you see in one short line, then answer
the user's question. landmarks, cuisine, vibes, signs — call it. if
unsure where it is, say what you notice and guess a region.`;

// Tone variants — pacing/length only. Friendship + warmth are constant
// across all three (set in SCOUT_BASE).
const TONE_BLOCKS: Record<string, string> = {
  standard: ``,
  chill: `

PACING: chill. you're the friend who has time tonight. lower urgency,
longer answers ok if they earn it, no "do this now" energy. you can
riff a little, share an aside, throw in a story. still warm, just
unhurried.`,
  terse: `

PACING: tight. you're the friend who's busy but always has your back —
short replies because you respect the user's time, not because you're
cold. 1-3 sentences max, zero preamble, one emoji max. lead with the
answer, end with a quick "got you" / "say less" if it fits, and dip.
warmth stays — just compressed.`,
};

function buildScoutSystem(tone: string): string {
  const block = TONE_BLOCKS[tone] ?? TONE_BLOCKS.standard;
  return SCOUT_BASE + block;
}

// ─────────────────────────────────────────────────────────────
//  DISLIKE INFERENCE — fire-and-forget extractor
//  Detects when the user has expressed dislike for something
//  travel-related and silently appends to profiles.dislikes so
//  scout never recommends it again. Uses Haiku for speed/cost
//  (~$0.0001/call) and only fires when a trigger keyword is in
//  the message — 90%+ of turns skip the extractor entirely.
// ─────────────────────────────────────────────────────────────

// Cheap regex pre-filter. Skips Haiku call when no signal.
const DISLIKE_TRIGGER = /\b(hate|dislike|can'?t stand|no thanks?|never again|ugh|skip|avoid|stay away|not (?:my|a) thing|don'?t (?:like|want))\b/i;

const DISLIKE_EXTRACTOR_PROMPT = `you extract things the USER has just expressed dislike for, scoped to TRAVEL/LIFESTYLE topics that affect trip recommendations.

return ONLY a JSON array of short lowercase strings (max 4 words each). examples:
- "i hate crowds" → ["crowds"]
- "no spicy food please" → ["spicy food"]
- "long flights stress me out" → ["long flights"]
- "casinos are not my thing" → ["casinos"]
- "i'd skip all-inclusives" → ["all-inclusives"]
- "i love beaches" → []  (positive, ignore)
- "where should we go?" → []  (no preference expressed)
- "we want budget options" → []  (preference, not dislike)
- "i hate my ex" → []  (not travel-related, ignore)

be conservative: only catch explicit, travel-relevant dislike. return [] if unsure.
return ONLY the JSON array — no prose, no code fence, no labels.`;

async function extractDislikes(content: string): Promise<string[]> {
  if (!DISLIKE_TRIGGER.test(content)) return [];
  try {
    const result = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 200,
      system: DISLIKE_EXTRACTOR_PROMPT,
      messages: [{ role: "user", content }],
    });
    const text = (result.content[0] as { text: string }).text.trim();
    const arr = JSON.parse(text);
    if (!Array.isArray(arr)) return [];
    return arr
      .filter((x: unknown): x is string => typeof x === "string")
      .map((x: string) => x.toLowerCase().trim())
      .filter((x: string) => x.length > 0 && x.length <= 40);
  } catch (_) {
    return [];
  }
}

async function appendDislikes(
  service: any,
  userId: string,
  newOnes: string[],
): Promise<void> {
  if (newOnes.length === 0) return;
  try {
    const { data: prof } = await service
      .from("profiles")
      .select("dislikes")
      .eq("id", userId)
      .maybeSingle();
    const existing = (prof?.dislikes ?? []) as string[];
    // Case-insensitive dedupe.
    const existingLower = new Set(existing.map((s) => s.toLowerCase()));
    const merged = [...existing];
    for (const item of newOnes) {
      if (!existingLower.has(item.toLowerCase())) {
        merged.push(item);
        existingLower.add(item.toLowerCase());
      }
    }
    if (merged.length === existing.length) return; // nothing new
    await service.from("profiles").update({ dislikes: merged }).eq("id", userId);
  } catch (_) { /* non-fatal */ }
}

Deno.serve(async (req) => {
  try {
    // `private` = true means this is a solo-trip in-space Scout chat:
    // the assistant reply gets persisted to scout_messages with
    // trip_id set, NOT broadcast to the trip's group chat. v1.1.
    const { content, trip_id, image_url, private: isPrivate, tone } = await req.json();
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

    // Gather context. Three blocks, prepended in priority order:
    //   1. USER CONTEXT  — always fetched. Profile data the user gave us
    //      during onboarding (home city, departure airport, travel style,
    //      passports) plus completed-trip history. So scout never asks
    //      "where are you based?" if we already know.
    //   2. TRIP CONTEXT  — only when a trip_id is set. Squad + dates +
    //      destination of the active trip.
    //   3. RECENT CHAT   — only when there's no trip_id. Last 10 turns
    //      of the user's solo Scout chat for thread continuity.
    let context = "";

    // ── 1. USER CONTEXT (always) ──
    const [
      { data: profile },
      { data: pastTripRows },
      { data: lovedRecaps },
    ] = await Promise.all([
      service
        .from("profiles")
        .select("nickname, home_city, home_airport, travel_style, passports, dislikes, trips_completed")
        .eq("id", userId)
        .maybeSingle(),
      service
        .from("squad_members")
        .select("trips!inner(selected_destination,end_date,status)")
        .eq("user_id", userId)
        .eq("trips.status", "completed")
        .order("end_date", { ascending: false, foreignTable: "trips" })
        .limit(5),
      // 4-5★ recaps = destinations the user actually loved.
      // Drives "you crushed lisbon, porto's the obvious next move" energy.
      service
        .from("destination_recaps")
        .select("destination, stars")
        .eq("user_id", userId)
        .gte("stars", 4)
        .order("created_at", { ascending: false })
        .limit(5),
    ]);

    // Track how many context lines we actually populated. Stored in
    // scout_call_log so we can ask "do users with richer context
    // engage with Scout differently" without back-deriving.
    let userContextDepth = 0;
    if (profile) {
      const lines: string[] = [];
      if (profile.nickname)      lines.push(`name: ${profile.nickname}`);
      if (profile.home_city)     lines.push(`home base: ${profile.home_city}`);
      if (profile.home_airport)  lines.push(`usual departure airport: ${profile.home_airport}`);
      if (profile.travel_style)  lines.push(`travel style: ${profile.travel_style}`);
      if (Array.isArray(profile.passports) && profile.passports.length > 0) {
        lines.push(`passports: ${profile.passports.join(", ")}`);
      }
      if (Array.isArray(profile.dislikes) && profile.dislikes.length > 0) {
        lines.push(`dislikes (NEVER suggest these): ${profile.dislikes.join(", ")}`);
      }
      if (typeof profile.trips_completed === "number" && profile.trips_completed > 0) {
        lines.push(`trips completed on tripsquad: ${profile.trips_completed}`);
      }

      const recentDests = (pastTripRows ?? [])
        .map((row: any) => row?.trips?.selected_destination)
        .filter((d: unknown): d is string => typeof d === "string" && d.length > 0)
        .slice(0, 5);
      if (recentDests.length) lines.push(`recent trips: ${recentDests.join(", ")}`);

      const lovedDests = (lovedRecaps ?? [])
        .map((r: any) => r?.destination)
        .filter((d: unknown): d is string => typeof d === "string" && d.length > 0)
        .slice(0, 5);
      if (lovedDests.length) lines.push(`destinations they loved (4-5★ recaps): ${lovedDests.join(", ")}`);

      userContextDepth = lines.length;
      if (lines.length) {
        context += `USER CONTEXT (use naturally — don't ask for anything already here):\n${lines.join("\n")}\n\n`;
      }
    }

    // Measure conversation depth at call time. "Session" = this user's
    // scout_messages in the last 30min. Lets us answer "did the
    // 'opinions over surveys' prompt produce shorter or longer
    // conversations" without needing to derive sessions from the log.
    const sessionWindow = new Date(Date.now() - 30 * 60 * 1000).toISOString();
    const { count: messageCountInSession } = await service
      .from("scout_messages")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("role", "user")
      .gte("created_at", sessionWindow);

    // ── 2. TRIP CONTEXT (when trip_id) ──
    if (trip_id) {
      const { data: trip } = await service
        .from("trips")
        .select("name, selected_destination, start_date, end_date, vibes, squad_members(nickname,vibes,budget_min,budget_max)")
        .eq("id", trip_id)
        .single();
      if (trip) context += `TRIP CONTEXT:\n${JSON.stringify(trip, null, 2)}\n\n`;
    } else {
      // ── 3. RECENT CHAT (only when no trip context) ──
      const { data: recent } = await service
        .from("scout_messages")
        .select("role, content")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(20); // bumped from 10 — better thread continuity for
                    // "remember when you said you hate flying" energy
      if (recent?.length) {
        const history = recent.reverse()
          .map((m: any) => `${m.role}: ${m.content}`)
          .join("\n");
        context += `RECENT CHAT:\n${history}\n\n`;
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

    const callStartedAt = Date.now();
    const message = await anthropic.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: buildScoutSystem(typeof tone === "string" ? tone : "standard"),
      messages: [{ role: "user", content: userContent }],
    });
    const responseLatencyMs = Date.now() - callStartedAt;

    const reply = (message.content[0] as { text: string }).text.trim();

    // Event-level scout call log. Service-role writes (RLS denies all
    // client access). Lengths only — never the message content. The
    // PROMPT_VERSION constant ties this row to the system-prompt rev
    // so we can compare "before sharper prompt" vs. "after."
    const PROMPT_VERSION = "v1.2.0_sharper";
    const resolvedTone = typeof tone === "string" ? tone : "standard";
    let scoutCallLogId: string | null = null;
    try {
      const { data: logRow } = await service
        .from("scout_call_log")
        .insert({
          user_id: userId,
          trip_id: trip_id ?? null,
          is_private: !!isPrivate,
          tone: resolvedTone,
          user_context_depth: userContextDepth,
          message_count_in_session: messageCountInSession ?? 0,
          input_length: content.length,
          response_length: reply.length,
          response_latency_ms: responseLatencyMs,
          has_image: !!image_url,
          prompt_version: PROMPT_VERSION,
          dislike_inference_triggered: DISLIKE_TRIGGER.test(content),
          dislikes_inferred_count: 0, // updated by dislikeWork below
        })
        .select("id")
        .single();
      scoutCallLogId = logRow?.id ?? null;
    } catch (_) { /* non-fatal — analytics never breaks the call */ }

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

    // Fire-and-forget dislike inference. Runs in the background after
    // the response ships so the user doesn't wait for it. Uses
    // EdgeRuntime.waitUntil to keep the worker alive past the
    // response (otherwise the runtime kills in-flight promises the
    // moment the request handler returns — same issue we hit with
    // affiliate_redirect's clickthrough INSERT).
    //
    // Also writes provenance rows to dislike_inferences so we can
    // measure inference precision (still_present_pct over 30 days).
    const dislikeWork = (async () => {
      const detected = await extractDislikes(content);
      if (detected.length === 0) return;
      await appendDislikes(service, userId, detected);

      // Provenance: one row per inferred item, linked to the source call.
      try {
        await service.from("dislike_inferences").insert(
          detected.map((item) => ({
            user_id: userId,
            item,
            source_call_id: scoutCallLogId,
          })),
        );
      } catch (_) { /* non-fatal */ }

      // Backfill the count onto the call log row.
      if (scoutCallLogId) {
        try {
          await service
            .from("scout_call_log")
            .update({ dislikes_inferred_count: detected.length })
            .eq("id", scoutCallLogId);
        } catch (_) { /* non-fatal */ }
      }
    })();
    // @ts-ignore — EdgeRuntime is provided by the Supabase Edge runtime
    if (typeof EdgeRuntime !== "undefined" && EdgeRuntime?.waitUntil) {
      // @ts-ignore
      EdgeRuntime.waitUntil(dislikeWork);
    } else {
      // Fallback for local dev / non-Supabase runtimes — block briefly.
      // Cap at 1.5s so the user never waits long even if inference hangs.
      await Promise.race([
        dislikeWork,
        new Promise((r) => setTimeout(r, 1500)),
      ]);
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
