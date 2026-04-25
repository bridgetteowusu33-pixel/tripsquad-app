// Resolves a free-text travel destination to a canonical name, country,
// and flag emoji. Used to pre-fill flag + validate obscure inputs during
// trip creation + change-destination flows. Fast, cheap Claude call.

import Anthropic from "npm:@anthropic-ai/sdk@0.30.1";

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY")!,
});

const SYSTEM = `you resolve travel destination names to structured JSON.
given any input string (city, region, country, nickname, misspelling),
return ONE LINE of valid JSON:
{"valid": boolean, "canonical": "Canonical Name", "country": "Country",
 "flag": "🇬🇭", "region": "short region"}

rules:
- valid=false if input is gibberish, fictional (atlantis, narnia), or too vague to resolve
- canonical = the most common english name, proper capitalization
- country = full country name in english
- flag = the country's flag emoji (two regional-indicator chars)
- region = short helpful hint like "south america", "west africa", "southeast asia"
- prefer cities over countries when ambiguous (e.g. "dublin" = ireland city, not texas)
- ONLY return the JSON object, nothing else, no code fences`;

Deno.serve(async (req) => {
  try {
    const { destination } = await req.json();
    if (!destination || typeof destination !== "string" ||
        destination.trim().length < 2) {
      return new Response(
        JSON.stringify({ valid: false, error: "destination required" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const message = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 200,
      system: SYSTEM,
      messages: [{ role: "user", content: destination.trim() }],
    });

    const text = (message.content[0] as { text: string }).text.trim();
    // Strip code fences just in case
    const cleaned = text.replace(/```json\n?|\n?```/g, "").trim();
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      return new Response(
        JSON.stringify({
          valid: false,
          error: "could not parse AI response",
          raw: text,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(JSON.stringify(parsed), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});
