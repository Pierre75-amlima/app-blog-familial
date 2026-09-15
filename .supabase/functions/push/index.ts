// ─────────────────────────────────────────────────────────────────────────────
// Supabase Edge Function: "push"
//
// Envoie des notifications push FCM et les enregistre dans la table
// "notifications" (pour le badge in-app).
//
// Secrets requis (Project Settings → Edge Functions → Secrets) :
//   FCM_PROJECT_ID      → Project ID du projet Firebase
//   FCM_SERVICE_ACCOUNT → JSON complet du service account Firebase
//                         (Project Settings → Service accounts → Generate key)
//
// Appelée depuis l'app (le JWT Supabase du user est envoyé automatiquement) :
//   supabase.functions.invoke('push', {
//     body: {
//       title: "Nouvelle publication",
//       body: "Marie a partagé un nouveau message",
//       type: "post",        // post | comment | message | event
//       ref_id: "uuid",      // optionnel : id de la ligne liée
//       user_ids: ["uuid"],  // destinataires (NE PAS inclure l'expéditeur)
//     },
//   });
// ─────────────────────────────────────────────────────────────────────────────

// deno-lint-ignore-file no-explicit-any
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// ─── Token OAuth FCM (JWT RS256 signé avec le service account) ────────────
let cachedToken: { token: string; expiresAt: number } | null = null;

function b64url(input: string | Uint8Array): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : input;
  let bin = "";
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getFcmAccessToken(): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expiresAt > now + 60_000) {
    return cachedToken.token;
  }

  const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!) as {
    client_email: string;
    private_key: string;
  };

  const pem = sa.private_key
    .replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const rawKey = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const signingKey = await crypto.subtle.importKey(
    "pkcs8",
    rawKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const iat = Math.floor(now / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/fcm",
      aud: "https://oauth2.googleapis.com/token",
      iat,
      exp: iat + 3600,
    }),
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    signingKey,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const assertion = `${header}.${claims}.${b64url(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) {
    throw new Error(`FCM OAuth error ${res.status}: ${await res.text()}`);
  }
  const data = (await res.json()) as {
    access_token: string;
    expires_in: number;
  };
  cachedToken = {
    token: data.access_token,
    expiresAt: now + data.expires_in * 1000,
  };
  return data.access_token;
}

interface PushPayload {
  title: string;
  body?: string;
  type?: string;
  ref_id?: string;
  user_ids: string[];
}

async function sendFcm(
  token: string,
  payload: { title: string; body: string; data: Record<string, string> },
): Promise<void> {
  const accessToken = await getFcmAccessToken();
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${Deno.env.get(
      "FCM_PROJECT_ID",
    )}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: payload.title, body: payload.body },
          data: payload.data,
        },
      }),
    },
  );
  if (!res.ok) {
    throw new Error(`FCM error ${res.status}: ${await res.text()}`);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    // 1. Vérifier le JWT Supabase (user connecté ou service role)
    const jwt = (req.headers.get("Authorization") ?? "")
      .replace(/^Bearer\s+/i, "");
    const { data: authData, error: authError } =
      await supabaseAdmin.auth.getUser(jwt);
    if (authError || !authData.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = await req.json() as PushPayload;
    if (
      !body.title || !Array.isArray(body.user_ids) || body.user_ids.length === 0
    ) {
      return jsonResponse(
        { error: "'title' and a non-empty 'user_ids' array are required" },
        400,
      );
    }

    // 2. Récupérer les tokens FCM des destinataires
    const { data: rows, error: rowsError } = await supabaseAdmin
      .from("push_subscriptions")
      .select("id, user_id, fcm_token")
      .in("user_id", body.user_ids);
    if (rowsError) throw rowsError;

    // 3. Envoyer via FCM (nettoie les tokens morts)
    let sent = 0;
    let failed = 0;
    for (const row of rows ?? []) {
      try {
        await sendFcm(row.fcm_token as string, {
          title: body.title,
          body: body.body ?? "",
          data: {
            type: body.type ?? "post",
            ref_id: body.ref_id ?? "",
          },
        });
        sent++;
      } catch (e) {
        failed++;
        const err = String(e);
        console.error(`FCM send failed (user ${row.user_id}): ${err}`);
        if (err.includes("404") || err.includes("400")) {
          // Token plus valide (app désinstallée, token révoqué...)
          await supabaseAdmin
            .from("push_subscriptions")
            .delete()
            .eq("id", row.id as string);
        }
      }
    }

    // 4. Enregistrer dans "notifications" (badge in-app),
    //    même pour les destinataires sans token FCM.
    if (rows !== null) {
      const { error: notifError } = await supabaseAdmin
        .from("notifications")
        .insert(
          body.user_ids.map((userId) => ({
            user_id: userId,
            title: body.title,
            body: body.body ?? "",
            type: body.type ?? "post",
            ref_id: body.ref_id ?? null,
          })),
        );
      if (notifError) {
        console.error(
          `Failed to store notifications: ${notifError.message}`,
        );
      }
    }

    return jsonResponse({ sent, failed, recipients: (rows ?? []).length });
  } catch (e) {
    console.error(e);
    return jsonResponse({ error: String(e) }, 500);
  }
});

function jsonResponse(body: any, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}
