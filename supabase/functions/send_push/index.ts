// Triggered by a Postgres webhook on `notifications` INSERT.
// Reads every push_tokens row for the target user and delivers the
// notification via FCM HTTP v1 (FCM handles iOS APNs fan-out when
// you upload an APNs key to Firebase).
//
// Required env vars:
//   FCM_SERVICE_ACCOUNT_JSON  — entire Firebase service account JSON (string)
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY
//
// Configure the webhook in Supabase Dashboard → Database → Webhooks:
//   Table: notifications, Event: INSERT, URL: this function

import { createClient } from "npm:@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.1/mod.ts";

interface NotificationRow {
  id: string;
  user_id: string;
  trip_id?: string;
  event_id?: string;
  kind: string;
  title: string;
  body?: string;
  pushed_at?: string | null;
}

async function getAccessToken(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const pemKey = serviceAccount.private_key;

  // Convert PEM to CryptoKey
  const pemContents = pemKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: getNumericDate(3600),
      iat: now,
    },
    cryptoKey,
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  return data.access_token as string;
}

Deno.serve(async (req) => {
  try {
    // Supabase webhook payload shape: { type, table, record, ... }
    const payload = await req.json();
    const record: NotificationRow = payload.record ?? payload;
    if (!record?.user_id) {
      return new Response("no user_id", { status: 400 });
    }

    const service = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Idempotency guard — "claim" this notification by setting
    // pushed_at atomically. If a duplicate webhook (or retry) fires
    // send_push again for the same row, the second invocation will
    // find pushed_at already set and exit without sending.
    if (record.id) {
      const { data: claimed } = await service
        .from("notifications")
        .update({ pushed_at: new Date().toISOString() })
        .eq("id", record.id)
        .is("pushed_at", null)
        .select("id");
      if (!claimed || claimed.length === 0) {
        return new Response("already pushed", { status: 200 });
      }
    }

    // Pull all tokens for this user, newest first. Testing across
    // debug builds + TestFlight reinstalls leaves stale tokens in the
    // table. FCM sometimes still accepts them for a while before
    // returning UNREGISTERED, so filter here: keep only the most
    // recently-updated token PER platform. That way a user with an
    // iPad + iPhone still gets both rings, but the same iPhone
    // reinstalled 4× doesn't spam.
    const { data: allTokens } = await service
      .from("push_tokens")
      .select("token, platform, updated_at")
      .eq("user_id", record.user_id)
      .order("updated_at", { ascending: false });

    if (!allTokens?.length) {
      return new Response("no push tokens for user", { status: 200 });
    }
    const seenPlatforms = new Set<string>();
    const tokens: Array<{ token: string; platform: string }> = [];
    for (const t of allTokens) {
      const p = (t as { platform: string }).platform;
      if (seenPlatforms.has(p)) continue;
      seenPlatforms.add(p);
      tokens.push({
        token: (t as { token: string }).token,
        platform: p,
      });
    }

    const saJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!saJson) {
      console.error("FCM_SERVICE_ACCOUNT_JSON not set");
      return new Response("not configured", { status: 500 });
    }
    const serviceAccount = JSON.parse(saJson);
    const accessToken = await getAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id;

    const results = await Promise.all(tokens.map(async (t) => {
      const body = {
        message: {
          token: t.token,
          notification: {
            title: record.title,
            body: record.body ?? "",
          },
          data: {
            kind: record.kind,
            trip_id: record.trip_id ?? "",
            event_id: record.event_id ?? "",
            notification_id: record.id,
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        },
      };
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(body),
        },
      );
      const ok = res.ok;
      if (!ok) {
        const err = await res.text();
        console.error("fcm error", err);
        // Clean up invalid tokens
        if (res.status === 404 || res.status === 400) {
          await service.from("push_tokens").delete().eq("token", t.token);
        }
      }
      return ok;
    }));

    const delivered = results.filter(Boolean).length;
    return new Response(JSON.stringify({ delivered, total: tokens.length }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
