// Minimal TypeScript Worker: verify Instant token -> mint short-lived session JWT (HS256)
import { init } from "@instantdb/admin";

interface Env {
  INSTANT_APP_ID: string;
  SESSION_JWT_SECRET: string;
  SESSION_JWT_ISSUER: string;
  SESSION_JWT_AUDIENCE: string;
}

async function signHS256(secret: string, header: object, payload: object): Promise<string> {
  const enc = new TextEncoder();
  const base64url = (b: ArrayBuffer | Uint8Array) => {
    let str = typeof b === "string" ? b : b instanceof Uint8Array ? b : new Uint8Array(b);
    const s = b instanceof Uint8Array ? b : new Uint8Array(b as ArrayBuffer);
    let hex = "";
    // We'll use btoa on string; simpler route: encode to base64 then convert to base64url
    const base64 = btoa(String.fromCharCode(...s));
    return base64.replace(/=+/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  };
  const encHeader = enc.encode(JSON.stringify(header));
  const encPayload = enc.encode(JSON.stringify(payload));
  const h64 = base64url(encHeader);
  const p64 = base64url(encPayload);
  const toSign = `${h64}.${p64}`;
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(toSign));
  const s64 = base64url(sig);
  return `${toSign}.${s64}`;
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    if (req.method === "POST" && url.pathname === "/auth/session") {
      try {
        const body = await req.json().catch(() => ({}));
        const refresh_token = body.refresh_token;
        if (!refresh_token) return new Response("Missing refresh_token", { status: 400 });

        const db = init({ appId: env.INSTANT_APP_ID });
        const user: any = await db.auth.verifyToken(refresh_token);

        const now = Math.floor(Date.now() / 1000);
        const exp = now + 10 * 60; // 10 minutes
        const header = { alg: "HS256", typ: "JWT" };
        const payload = {
          sub: user.id,
          email: user.email ?? undefined,
          roles: user.roles ?? [],
          iat: now,
          exp,
          iss: env.SESSION_JWT_ISSUER,
          aud: env.SESSION_JWT_AUDIENCE,
        };

        const token = await signHS256(env.SESSION_JWT_SECRET, header, payload);
        return new Response(JSON.stringify({ token, user: { id: user.id, email: user.email } }), {
          headers: { "content-type": "application/json" },
        });
      } catch (e: any) {
        return new Response(`Auth error: ${e?.message || e}`, { status: 401 });
      }
    }
    return new Response("Not found", { status: 404 });
  },
};
