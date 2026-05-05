// Edge Function: envia FCM HTTP v1 para tokens em `fcm_device_tokens`, exceto `exclude_actor`.
// Deploy: `supabase functions deploy send-jbc-push --no-verify-jwt` (ou configure JWT conforme política).
// Secrets (Dashboard → Edge Functions): FIREBASE_SERVICE_ACCOUNT_JSON (string JSON da conta de serviço com Firebase Cloud Messaging API).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { GoogleAuth } from "npm:google-auth-library@9.14.2";

type Body = {
  exclude_actor?: string;
  title?: string;
  body?: string;
  /** Valores string para o payload `data` do FCM (deep links, event_type, etc.). */
  data?: Record<string, string>;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  let payload: Body;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "invalid json" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const excludeRaw = payload.exclude_actor;
  /** When unset or empty string, send to all profiles (e.g. match broadcast). */
  const exclude =
    excludeRaw === undefined || excludeRaw === null || excludeRaw === ""
      ? null
      : String(excludeRaw);
  const title = (payload.title ?? "JBC").slice(0, 120);
  const body = (payload.body ?? "").slice(0, 240);
  const dataPayload: Record<string, string> = {};
  for (const [k, v] of Object.entries(payload.data ?? {})) {
    if (typeof v === "string" && v.length > 0) {
      dataPayload[String(k).slice(0, 40)] = v.slice(0, 500);
    }
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!saJson) {
    return new Response(
      JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT_JSON not set" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const credentials = JSON.parse(saJson);
  const supabase = createClient(supabaseUrl, serviceKey);
  let tokenQuery = supabase.from("fcm_device_tokens").select("token, profile");
  if (exclude != null && exclude.length > 0) {
    tokenQuery = tokenQuery.neq("profile", exclude);
  }
  const { data: rows, error } = await tokenQuery;

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const auth = new GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const client = await auth.getClient();
  const access = await client.getAccessToken();
  const token = access.token;
  if (!token) {
    return new Response(JSON.stringify({ error: "no oauth token" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const projectId = credentials.project_id as string;
  const url =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  let sent = 0;
  for (const row of rows ?? []) {
    const t = row.token as string;
    if (!t) continue;
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: t,
          notification: { title, body },
          android: { priority: "HIGH" },
          apns: {
            headers: { "apns-priority": "10" },
            payload: { aps: { sound: "default" } },
          },
          ...(Object.keys(dataPayload).length > 0 ? { data: dataPayload } : {}),
        },
      }),
    });
    if (res.ok) sent++;
  }

  return new Response(JSON.stringify({ ok: true, targets: rows?.length ?? 0, sent }), {
    headers: { "Content-Type": "application/json" },
  });
});
