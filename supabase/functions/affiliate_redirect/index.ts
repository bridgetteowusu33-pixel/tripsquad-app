// v1.2 — Booking Layer
// affiliate_redirect: the single redirect endpoint for every outbound
// booking link in TripSquad. Never link directly to Booking/Skyscanner/
// etc. from the client. Instead, point at this function with our
// internal click_id, partner, kind, target — we record the click in
// affiliate_clickthroughs, inject our affiliate ID into the partner
// URL, and 302 redirect.
//
// Flow:
//   1. Client opens https://<project>.functions.supabase.co/affiliate_redirect
//      ?partner=booking_com
//      &kind=hotel
//      &target=<rec_uuid>
//      &trip=<trip_uuid>
//      &q=<base64-json-search-params>
//   2. We generate a click_id, INSERT into affiliate_clickthroughs.
//   3. We build the partner URL with affiliate ID + click_id passed
//      through (so the partner postback can reconcile).
//   4. 302 to the partner URL. User lands on Booking/Skyscanner.
//   5. (Phase 2) When the partner sends us a postback, we look up
//      click_id and credit the conversion.
//
// Env required:
//   - BOOKING_AFFILIATE_AID    (Booking.com affiliate id, e.g. "12345")
//   - SKYSCANNER_AFFILIATE_ID  (or via Travelpayouts marker)
//   - EXPEDIA_AFFILIATE_ID     (Phase 2)
//
// Missing IDs => clean fallback: redirect without the affiliate
// parameter. We still record the click for analytics/eligibility.

import { createClient } from "npm:@supabase/supabase-js@2";

const BOOKING_AID = Deno.env.get("BOOKING_AFFILIATE_AID");
// Travelpayouts marker — used for Aviasales (flights), Hotellook
// (hotels), WayAway, and other Travelpayouts partners. One marker
// covers all of them. Set via `supabase secrets set TRAVELPAYOUTS_MARKER=...`.
const TP_MARKER = Deno.env.get("TRAVELPAYOUTS_MARKER");
const EXPEDIA_AID = Deno.env.get("EXPEDIA_AFFILIATE_ID");

// Generate a short, URL-safe click_id (12 hex chars). Persisted as
// PRIMARY-key-uniqued in affiliate_clickthroughs and passed to the
// partner so postbacks can be attributed back.
function generateClickId(): string {
  const arr = new Uint8Array(6);
  crypto.getRandomValues(arr);
  return Array.from(arr).map((b) => b.toString(16).padStart(2, "0")).join("");
}

// SHA-256 hash of an IP for fraud signals (never store raw IP).
async function hashIp(ip: string | null): Promise<string | null> {
  if (!ip) return null;
  const buf = new TextEncoder().encode(ip);
  const hashed = await crypto.subtle.digest("SHA-256", buf);
  return Array.from(new Uint8Array(hashed))
    .slice(0, 8)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

interface RedirectParams {
  partner: string;
  kind: string;
  target?: string;
  trip?: string;
  q?: Record<string, unknown>; // partner-specific search params
  clickId: string;
}

// Build the partner URL with the affiliate ID injected. Each partner
// has its own URL shape — keep them all in one place so the
// click-tracking layer is the only source of truth.
function buildPartnerUrl(params: RedirectParams): string {
  const { partner, q, clickId } = params;
  const search = q ?? {};

  switch (partner) {
    case "booking_com": {
      const ss = String(search.ss ?? "");
      const checkin = String(search.checkin ?? "");
      const checkout = String(search.checkout ?? "");
      const group_adults = String(search.group_adults ?? "");
      const u = new URL("https://www.booking.com/searchresults.html");
      if (ss) u.searchParams.set("ss", ss);
      if (checkin) u.searchParams.set("checkin", checkin);
      if (checkout) u.searchParams.set("checkout", checkout);
      if (group_adults) u.searchParams.set("group_adults", group_adults);
      if (BOOKING_AID) u.searchParams.set("aid", BOOKING_AID);
      // label = our click_id; Booking echoes it on postback.
      u.searchParams.set("label", `tripsquad-${clickId}`);
      return u.toString();
    }

    case "aviasales": {
      // Aviasales is the Travelpayouts flagship flight metasearch
      // (Skyscanner-tier inventory). We build a deep search URL,
      // then wrap in Travelpayouts' tp.media/r attribution proxy
      // so the marker is properly recorded.
      //
      // Aviasales URL pattern (path-based search):
      //   /search/{from}{ddmm}{to}{ddmm_return?}{adults}
      // Example: /search/JFK0105MEX08051 means JFK→MEX, May 1 outbound,
      // May 8 return, 1 adult. We use this format for clean deep-linking.
      const from = String(search.from ?? "").toUpperCase();
      const to = String(search.to ?? "").toUpperCase();
      const outboundDdmm = String(search.outbound_ddmm ?? "");
      const returnDdmm = String(search.return_ddmm ?? "");
      const adults = String(search.adults ?? "1");
      let path = "/search";
      if (from && to && outboundDdmm) {
        path = `/search/${from}${outboundDdmm}${to}${returnDdmm}${adults}`;
      }
      const target = `https://www.aviasales.com${path}`;
      // Travelpayouts attribution wrapper. p=4114 is Aviasales' partner id.
      const wrap = new URL("https://tp.media/r");
      if (TP_MARKER) wrap.searchParams.set("marker", TP_MARKER);
      wrap.searchParams.set("p", "4114");
      wrap.searchParams.set("u", target);
      wrap.searchParams.set("campaign_id", "100");
      // sub_id = our click_id so Travelpayouts postbacks reconcile.
      wrap.searchParams.set("sub_id", clickId);
      return wrap.toString();
    }

    case "hotellook": {
      // Hotellook is the Travelpayouts hotels offer. Same wrapper
      // pattern. p=4115 is the Hotellook partner id. Caller may use
      // Booking's `group_adults` param — fall back to it so smart
      // routing from `best_hotel` works without re-encoding params.
      const ss = String(search.ss ?? "");
      const checkin = String(search.checkin ?? "");
      const checkout = String(search.checkout ?? "");
      const adults = String(search.adults ?? search.group_adults ?? "2");
      const target = new URL("https://search.hotellook.com");
      if (ss) target.searchParams.set("destination", ss);
      if (checkin) target.searchParams.set("checkIn", checkin);
      if (checkout) target.searchParams.set("checkOut", checkout);
      target.searchParams.set("adults", adults);
      const wrap = new URL("https://tp.media/r");
      if (TP_MARKER) wrap.searchParams.set("marker", TP_MARKER);
      wrap.searchParams.set("p", "4115");
      wrap.searchParams.set("u", target.toString());
      wrap.searchParams.set("campaign_id", "101");
      wrap.searchParams.set("sub_id", clickId);
      return wrap.toString();
    }

    case "google_flights": {
      // Google Flights doesn't have an affiliate program; we just
      // build a deep link so users have a quality alternative.
      const from = String(search.from ?? "");
      const to = String(search.to ?? "");
      const outbound = String(search.outbound ?? ""); // YYYY-MM-DD
      const ret = String(search.return ?? "");
      const adults = String(search.adults ?? "1");
      // Google's URL format isn't officially documented; this is the
      // public web-search format. Falls back gracefully.
      const tfs = `${from}.${to}.${outbound}` + (ret ? `*${to}.${from}.${ret}` : "");
      const u = new URL("https://www.google.com/travel/flights");
      u.searchParams.set("q", `flights from ${from} to ${to}`);
      u.searchParams.set("hl", "en");
      // We do NOT inject an affiliate id (none exists). Click is still
      // tracked in our table for analytics.
      return u.toString();
    }

    case "expedia": {
      const ss = String(search.ss ?? "");
      const checkin = String(search.checkin ?? "");
      const checkout = String(search.checkout ?? "");
      const u = new URL("https://www.expedia.com/Hotel-Search");
      if (ss) u.searchParams.set("destination", ss);
      if (checkin) u.searchParams.set("startDate", checkin);
      if (checkout) u.searchParams.set("endDate", checkout);
      if (EXPEDIA_AID) u.searchParams.set("camref", EXPEDIA_AID);
      u.searchParams.set("clickref", `tripsquad-${clickId}`);
      return u.toString();
    }

    case "best_hotel": {
      // Smart routing — pick the highest-commission partner whose
      // affiliate ID is configured. Booking.com pays the most (~30-40%
      // of their fee) when we have a direct AID; Hotellook (via
      // Travelpayouts) is the always-attributed fallback. As the user
      // adds Marriott / Expedia / etc., extend this chain.
      const next = BOOKING_AID
        ? "booking_com"
        : (TP_MARKER ? "hotellook" : "booking_com");
      return buildPartnerUrl({ ...params, partner: next });
    }

    case "best_flight": {
      // Same idea for flights. Aviasales (Travelpayouts) is the
      // primary; Google Flights is a no-affiliate fallback so the
      // user always lands somewhere usable.
      const next = TP_MARKER ? "aviasales" : "google_flights";
      return buildPartnerUrl({ ...params, partner: next });
    }

    default:
      // Unknown partner — bounce to home, still record the click.
      return "https://gettripsquad.com";
  }
}

Deno.serve(async (req) => {
  try {
    const url = new URL(req.url);
    const partner = url.searchParams.get("partner") ?? "";
    const kind = url.searchParams.get("kind") ?? "";
    const target = url.searchParams.get("target") ?? null;
    const trip = url.searchParams.get("trip") ?? null;
    const qB64 = url.searchParams.get("q");

    // Decode the q param — base64-encoded JSON of partner search
    // parameters. Keeps the URL clean and lets us pass arbitrary
    // partner-specific shapes without exploding query string.
    let q: Record<string, unknown> = {};
    if (qB64) {
      try {
        q = JSON.parse(atob(qB64));
      } catch (_) {
        // Bad encoding — ignore, treat as empty.
      }
    }

    if (!partner || !kind) {
      return new Response("missing partner or kind", { status: 400 });
    }
    if (!["hotel", "flight", "activity"].includes(kind)) {
      return new Response("invalid kind", { status: 400 });
    }

    // Auth — if the user is signed in, attach their user_id. Anon
    // clicks still get recorded (just without user_id).
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    let user_id: string | null = null;
    const authHeader = req.headers.get("Authorization");
    if (authHeader?.startsWith("Bearer ")) {
      try {
        const token = authHeader.slice(7);
        const { data } = await supabase.auth.getUser(token);
        user_id = data.user?.id ?? null;
      } catch (_) {
        // Bad token — proceed anonymously.
      }
    }

    const clickId = generateClickId();
    const ip =
      req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? null;
    const ipHash = await hashIp(ip);
    const ua = req.headers.get("user-agent") ?? null;

    // Build partner URL FIRST (cheap, deterministic) so a DB hiccup
    // doesn't block the redirect. We INSERT in the background.
    const params: RedirectParams = { partner, kind, target: target ?? undefined,
      trip: trip ?? undefined, q, clickId };
    const partnerUrl = buildPartnerUrl(params);

    // Record the click. Don't await — fire and continue. The user
    // gets the redirect immediately. If the insert fails we log and
    // move on; the worst case is one missed analytic row.
    supabase.from("affiliate_clickthroughs").insert({
      trip_id: trip,
      user_id,
      partner,
      kind,
      target_id: target,
      query: q,
      click_id: clickId,
      user_agent: ua,
      ip_hash: ipHash,
    }).then(({ error }) => {
      if (error) console.warn("affiliate_clickthrough insert", error);
    });

    return Response.redirect(partnerUrl, 302);
  } catch (err) {
    console.error("affiliate_redirect", err);
    return new Response("redirect error", { status: 500 });
  }
});
