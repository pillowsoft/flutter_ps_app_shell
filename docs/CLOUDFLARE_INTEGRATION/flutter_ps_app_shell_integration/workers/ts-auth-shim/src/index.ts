// TS Auth Shim (Instant verify -> HS256 session JWT)
import { init } from "@instantdb/admin";
interface Env {
  INSTANT_APP_ID: string;
  SESSION_JWT_SECRET: string;
  SESSION_JWT_ISSUER: string;
  SESSION_JWT_AUDIENCE: string;
}
function b64url(a: ArrayBuffer){const s=String.fromCharCode(...new Uint8Array(a));return btoa(s).replace(/=+/g,"").replace(/\+/g,"-").replace(/\//g,"_");}
export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const u = new URL(req.url);
    if (req.method==="POST" && u.pathname==="/auth/session"){
      const {refresh_token} = await req.json<any>();
      if(!refresh_token) return new Response("Missing refresh_token",{status:400});
      const db = init({ appId: env.INSTANT_APP_ID });
      const user: any = await db.auth.verifyToken(refresh_token);
      const now = Math.floor(Date.now()/1000);
      const header = { alg:"HS256", typ:"JWT" };
      const payload = { sub:user.id, email:user.email, roles:user.roles??[], iat:now, exp:now+600, iss:env.SESSION_JWT_ISSUER, aud:env.SESSION_JWT_AUDIENCE };
      const enc = new TextEncoder();
      const h64 = b64url(enc.encode(JSON.stringify(header)));
      const p64 = b64url(enc.encode(JSON.stringify(payload)));
      const key = await crypto.subtle.importKey("raw", enc.encode(env.SESSION_JWT_SECRET), {name:"HMAC", hash:"SHA-256"}, false, ["sign"]);
      const sig = await crypto.subtle.sign("HMAC", key, enc.encode(`${h64}.${p64}`));
      const jwt = `${h64}.${p64}.${b64url(sig)}`;
      return new Response(JSON.stringify({ token: jwt, user: { id: user.id, email: user.email } }), {headers:{'content-type':'application/json'}});
    }
    return new Response("Not found", {status:404});
  }
}
