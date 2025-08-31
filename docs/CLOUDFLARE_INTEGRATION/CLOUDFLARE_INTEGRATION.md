Awesome—let’s lock in the Dart-first Worker with a tiny TS auth shim, and expand the spec to include R2 (video + generic objects), Cloudflare Images/Stream (optional), and Workers AI. Hand this to your dev as-is.

⸻

Implementation Spec – Dart Cloudflare Worker (+ TS Auth Shim) for InstantDB, R2 & Workers AI

Goals
	•	Keep business logic in Dart (share models/types with your Flutter package).
	•	Verify users via InstantDB (through a minimal TS auth shim).
	•	Provide REST endpoints for app operations, including:
	•	Auth session exchange
	•	Permissioned CRUD on your domain objects
	•	R2: large file uploads (video), downloads, lifecycle ops
	•	Workers AI: text, image, (optional) speech endpoints
	•	Enforce rate limiting (Durable Objects), logging, and observability.

⸻

High-Level Architecture

Flutter (mobile/desktop/web)
 └── instant_refresh_token ──► [TS Auth Shim Worker]
                                └─ verify via @instantdb/admin
                                └─ mint short-lived session JWT (HS256)
         session JWT ◄──────────┘
 └── Authorization: Bearer <session JWT>
     ───────────────────────────► [Dart API Worker]
                                  ├─ verify JWT (pure Dart)
                                  ├─ enforce perms
                                  ├─ rate limit (Durable Object)
                                  ├─ business routes (Instant, R2, Images/Stream, AI)
                                  └─ audit logs / metrics


⸻

Repos & File Layout

/infra
  /ts-auth-shim          # minimal TS Worker for Instant verification → session JWT
    wrangler.toml
    src/index.ts

/dart-worker
  wrangler.toml
  pubspec.yaml
  /lib
    env.dart             # typed bindings for KV, DO, R2Bucket, etc.
    main.dart            # fetch handler + router
    routes/
      auth_guard.dart    # JWT verify + user context
      rate_limit.dart    # Durable Object client wrapper
      r2.dart            # upload/download/list/delete + presign (optional)
      ai.dart            # Workers AI calls
      domain.dart        # your resource routes (e.g. /v1/projects)
    do/
      rate_limiter.dart  # Durable Object implementation
    util/
      jwt.dart           # HS256 verify
      http.dart          # JSON helpers, errors
      perms.dart         # convenience permission checks mapping to Instant rules

/flutter-package
  lib/
    instant_rest_client.dart  # calls to /auth/session and Dart Worker APIs
    upload.dart               # stream-upload helper + presign PUT helper


⸻

1) TS Auth Shim Worker (minimal & boring)

Purpose: accept an Instant refresh token, verify with @instantdb/admin, mint a short-lived session JWT (5–15 minutes), and return {token, user}.

/ts-auth-shim/wrangler.toml

name = "instant-auth-shim"
main = "src/index.ts"
compatibility_date = "2025-01-15"
compatibility_flags = ["nodejs_compat"]

[vars]
INSTANT_APP_ID = "xxx"
SESSION_JWT_ISSUER = "your-app"
SESSION_JWT_AUDIENCE = "your-app-clients"

# Bind a secret for minting your JWT
# wrangler secret put SESSION_JWT_SECRET

/ts-auth-shim/src/index.ts (sketch)

import { init } from "@instantdb/admin";

interface Env {
  INSTANT_APP_ID: string;
  SESSION_JWT_SECRET: string;
  SESSION_JWT_ISSUER: string;
  SESSION_JWT_AUDIENCE: string;
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    if (req.method === "POST" && url.pathname === "/auth/session") {
      const { refresh_token } = await req.json<any>();
      if (!refresh_token) return new Response("Missing refresh_token", { status: 400 });

      const db = init({ appId: env.INSTANT_APP_ID });
      // Verify the Instant token → returns user identity/claims
      const user = await db.auth.verifyToken(refresh_token);

      // Mint a short-lived session JWT for the Dart Worker
      const payload = {
        sub: user.id,
        email: user.email ?? undefined,
        roles: user.roles ?? [],
        iat: Math.floor(Date.now()/1000),
        exp: Math.floor(Date.now()/1000) + 10 * 60, // 10 min
        iss: env.SESSION_JWT_ISSUER,
        aud: env.SESSION_JWT_AUDIENCE
      };

      const token = await new Crypto().subtle
        // use HMAC SHA-256 to sign (pseudo; you can use jose or your own tiny signer)
        // or bundle 'jose' since nodejs_compat is enabled
      ;

      return Response.json({ token, user: { id: user.id, email: user.email } });
    }
    return new Response("Not found", { status: 404 });
  }
};

Notes:
	•	Keep it absolutely minimal. If you prefer, use jose to sign HS256.
	•	Token contents should be small (sub, exp, roles). Do not embed large claims.

⸻

2) Dart API Worker

2.1 Wrangler & Bindings

/dart-worker/wrangler.toml

name = "dart-api-worker"
main = "build/worker.js"          # output JS from Dart compile
compatibility_date = "2025-01-15"

[vars]
SESSION_JWT_ISSUER = "your-app"
SESSION_JWT_AUDIENCE = "your-app-clients"
R2_PUBLIC_BASE = "https://<accountid>.r2.cloudflarestorage.com/<bucket>" # optional convenience

# Bindings
[[r2_buckets]]
binding = "R2"            # env.R2 in Dart
bucket_name = "app-media"

[[durable_objects.bindings]]
name = "RATE_LIMITER"
class_name = "RateLimiterDO"

[durable_objects]
bindings = [{ name = "RATE_LIMITER", class_name = "RateLimiterDO" }]

[[kv_namespaces]]
binding = "KV"
id = "<kv-id>"

# Optional: if you also bind Workers AI (account-level binding)
# [[ai]]
# binding = "AI"

Build your Dart worker to JS (the Dart Edge toolchain or cloudflare_workers build pipeline will generate build/worker.js).

2.2 pubspec

/dart-worker/pubspec.yaml

name: dart_api_worker
environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  cloudflare_workers: ^<latest>   # runtime bindings for Request/Response, DO, R2, KV
  jose: ^0.3.4                    # or any lightweight HS256 lib for JWT verify
  crypto: ^3.0.3
  http_parser: ^4.0.2
  mime: ^1.0.5
  # Optional helpers:
  cloudflare_ai: ^<latest>        # if you prefer a Dart wrapper for AI

2.3 Environment & Handler Skeleton

/dart-worker/lib/env.dart

// Minimal typed accessors for bindings.
class Env {
  external String get SESSION_JWT_ISSUER;
  external String get SESSION_JWT_AUDIENCE;
  external dynamic get R2;             // R2Bucket binding
  external dynamic get KV;             // KVNamespace binding
  external dynamic get RATE_LIMITER;   // Durable Object namespace
  // Optional: external dynamic get AI;
}

/dart-worker/lib/main.dart

import 'package:cloudflare_workers/cloudflare_workers.dart';
import 'routes/auth_guard.dart';
import 'routes/r2.dart';
import 'routes/ai.dart';
import 'routes/rate_limit.dart';
import 'routes/domain.dart';

@CloudflareWorker()
Future<Response> fetch(Request req, Env env, Context ctx) async {
  final url = URL(req.url);
  final rl = RateLimiterClient(env); // DO client

  // Health
  if (url.pathname == '/health') return Response('ok');

  // Extract & verify our session JWT (throws 401 on failure)
  final auth = await authenticate(req, env);

  // Rate limit: key on user id
  await rl.consume(auth.userId);

  // Router
  if (url.pathname.startsWith('/v1/r2')) {
    return await handleR2Routes(req, env, auth);
  }
  if (url.pathname.startsWith('/v1/ai')) {
    return await handleAIRoutes(req, env, auth);
  }
  if (url.pathname.startsWith('/v1/projects')) {
    return await handleDomainRoutes(req, env, auth);
  }

  return Response('Not found', status: 404);
}

2.4 Auth Guard (verify the session JWT)

/dart-worker/lib/routes/auth_guard.dart

import 'dart:convert';
import '../util/jwt.dart';

class AuthContext {
  AuthContext(this.userId, this.email, this.roles);
  final String userId;
  final String? email;
  final List<String> roles;
}

Future<AuthContext> authenticate(Request req, Env env) async {
  final header = req.headers.get('Authorization');
  if (header == null || !header.startsWith('Bearer ')) {
    throw Response('Unauthorized', status: 401);
  }
  final token = header.substring(7);

  final claims = verifyHs256Jwt(
    token: token,
    // The auth shim signed with this same secret; store it as a secret on *both* Workers.
    // If you prefer, the Dart Worker can fetch the shim’s JWK once and cache.
    secret: await getSessionJwtSecret(), // implement via env.KV or binding
    issuer: env.SESSION_JWT_ISSUER,
    audience: env.SESSION_JWT_AUDIENCE,
  );

  final sub = claims['sub'] as String?;
  if (sub == null) throw Response('Unauthorized', status: 401);

  final roles = (claims['roles'] as List?)?.cast<String>() ?? const <String>[];
  return AuthContext(sub, claims['email'] as String?, roles);
}

/dart-worker/lib/util/jwt.dart (sketch)

import 'dart:convert';
import 'package:crypto/crypto.dart';

Map<String, dynamic> verifyHs256Jwt({
  required String token,
  required String secret,
  String? issuer,
  String? audience,
}) {
  final parts = token.split('.');
  if (parts.length != 3) throw Exception('Invalid token');
  final header = jsonDecode(utf8.decode(base64Url.decode(pad(parts[0]))));
  final payload = jsonDecode(utf8.decode(base64Url.decode(pad(parts[1]))));
  final sig = base64Url.decode(pad(parts[2]));

  final hmac = Hmac(sha256, utf8.encode(secret));
  final data = utf8.encode('${parts[0]}.${parts[1]}');
  final expected = hmac.convert(data).bytes;
  if (!_constTimeEq(sig, expected)) throw Exception('Bad signature');

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (payload['exp'] is int && now > payload['exp']) throw Exception('Expired');
  if (issuer != null && payload['iss'] != issuer) throw Exception('Bad iss');
  if (audience != null && payload['aud'] != audience) throw Exception('Bad aud');

  return Map<String, dynamic>.from(payload);
}

String pad(String s) => s + '=' * ((4 - s.length % 4) % 4);

bool _constTimeEq(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var r = 0;
  for (var i = 0; i < a.length; i++) { r |= a[i] ^ b[i]; }
  return r == 0;
}

Store SESSION_JWT_SECRET as a secret on both Workers. You can also fetch & cache it from KV or use a rotation scheme.

2.5 Rate Limiting (Durable Object)

/dart-worker/lib/do/rate_limiter.dart

import 'package:cloudflare_workers/cloudflare_workers.dart';

@DurableObject()
class RateLimiterDO {
  RateLimiterDO(State this.state);

  final State state;

  // windowed counter (e.g., 100 req / minute)
  static const int maxPerMinute = 100;

  Future<Response> fetch(Request req) async {
    final url = URL(req.url);
    final userId = url.searchParams.get('u');
    if (userId == null) return Response('Bad request', status: 400);

    final window = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    final key = '${userId}:${window}';
    final storage = state.storage;

    final count = (await storage.get<int>(key)) ?? 0;
    if (count >= maxPerMinute) {
      return Response('Too Many Requests', status: 429);
    }
    await storage.put<int>(key, count + 1, expiration: Duration(seconds: 70));
    return Response('ok');
  }
}

Client wrapper: /dart-worker/lib/routes/rate_limit.dart

class RateLimiterClient {
  RateLimiterClient(this.env);
  final Env env;

  Future<void> consume(String userId) async {
    final id = env.RATE_LIMITER.idFromName(userId);
    final stub = env.RATE_LIMITER.get(id);
    final res = await stub.fetch('https://do/limit?u=$userId');
    if (res.status == 429) throw Response('Too Many Requests', status: 429);
  }
}


⸻

3) R2 – Upload/Download Patterns

You’ll likely want two upload modes:
	•	A. Worker-proxy uploads (simple, good for small/medium files; Worker streams to R2).
	•	B. Presigned S3 PUT (best for large videos; client uploads directly to R2).

Implement both; choose based on file size.

3.1 Worker-proxy upload (simple path)

POST /v1/r2/upload?key=<optional-key>&contentType=video/mp4
	•	Body: raw bytes (or multipart—stream Request.body).
	•	Server:
	•	Generate a key if none supplied: ${userId}/${timestamp}-${rand}.mp4
	•	R2.put(objectKey, bodyStream, { httpMetadata: { contentType }, customMetadata: {...} })
	•	Returns: { key, size, etag, url }

/dart-worker/lib/routes/r2.dart (sketch)

Future<Response> handleR2Routes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);

  // POST /v1/r2/upload
  if (req.method == 'POST' && url.pathname == '/v1/r2/upload') {
    final ct = url.searchParams.get('contentType') ?? 'application/octet-stream';
    final customKey = url.searchParams.get('key');
    final key = customKey ?? '${auth.userId}/${DateTime.now().millisecondsSinceEpoch}.bin';

    final putRes = await env.R2.put(
      key,
      req.body, // stream
      {
        'httpMetadata': { 'contentType': ct },
        'customMetadata': { 'userId': auth.userId }
      }
    );

    final publicUrl = '${env.R2_PUBLIC_BASE}/$key'; // optional convenience
    return Response.json({'key': key, 'etag': putRes['etag'], 'url': publicUrl});
  }

  // GET /v1/r2/signed-put?key=...&contentType=...
  if (req.method == 'GET' && url.pathname == '/v1/r2/signed-put') {
    // For LARGE uploads: return a presigned S3 PUT URL valid ~10 minutes
    final key = url.searchParams.get('key') ?? '${auth.userId}/${DateTime.now().millisecondsSinceEpoch}.bin';
    final ct = url.searchParams.get('contentType') ?? 'application/octet-stream';
    final signed = await presignS3Put(key, ct, expiresMinutes: 10, env: env); // implement S3 SigV4 in Dart
    return Response.json(signed); // {url, headers} or {url} depending on your signing style
  }

  // GET /v1/r2/object?key=...
  if (req.method == 'GET' && url.pathname == '/v1/r2/object') {
    final key = url.searchParams.get('key');
    if (key == null) return Response('Bad request', status: 400);
    // Optional: permission check that user owns/has access
    final obj = await env.R2.get(key);
    if (obj == null) return Response('Not Found', status: 404);
    return Response(obj.body, headers: {'Content-Type': obj.httpMetadata?['contentType'] ?? 'application/octet-stream'});
  }

  // DELETE /v1/r2/object?key=...
  if (req.method == 'DELETE' && url.pathname == '/v1/r2/object') {
    final key = url.searchParams.get('key');
    if (key == null) return Response('Bad request', status: 400);
    // Permission check here
    await env.R2.delete(key);
    return Response.json({'ok': true});
  }

  return Response('Not found', status: 404);
}

Presigning (S3 SigV4): add a small helper that signs the canonical request with your R2 access key/secret stored as secrets. For very large uploads, this is preferable to proxying bytes through the Worker.

3.2 Lifecycle
	•	Set R2 lifecycle rules for automatic transitions (e.g., delete tmp uploads after 7 days).
	•	Store app metadata (owner, mime, duration, etc.) in KV or in your primary DB (Instant), keyed by r2Key.

⸻

4) (Optional) Cloudflare Images / Stream

If you’ll manage thumbnails or posters, consider Cloudflare Images:
	•	Worker route: /v1/images/direct-upload → request a Direct Creator Upload URL and return it to the client.
	•	Client uploads directly to Images; store imageId; serve via Images variants.

For playback-optimized video, consider Cloudflare Stream:
	•	Worker route: /v1/stream/direct-upload → create direct upload, return a one-time URL.
	•	Client uploads; you receive a videoId; playback via Stream player/HLS.

You can keep R2 as origin storage and copy to Stream as needed, or upload straight to Stream for user-facing playback while archiving in R2.

⸻

5) Workers AI Endpoints

Expose a small set of AI routes. Two patterns:
	•	A) Use the Workers AI binding (if available in your account → env.AI).
	•	B) Call the public Workers AI HTTPS API with your token (from secret).

Routes (examples):
	•	POST /v1/ai/text-generate → { prompt, model }
	•	POST /v1/ai/image-generate → { prompt, model, size }
	•	POST /v1/ai/summarize → { text }

/dart-worker/lib/routes/ai.dart (sketch)

Future<Response> handleAIRoutes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);

  if (req.method == 'POST' && url.pathname == '/v1/ai/text-generate') {
    final body = await req.json() as Map<String, dynamic>;
    final model = (body['model'] as String?) ?? '@cf/meta/llama-3.1-8b-instruct';
    final prompt = body['prompt'] as String? ?? '';
    // If you have AI binding:
    // final aiRes = await env.AI.run(model, {'prompt': prompt});
    // Otherwise, call the HTTPS API with account & token from secrets.
    final aiRes = await callWorkersAIHttp(model: model, input: {'prompt': prompt}, env: env);
    return Response.json(aiRes);
  }

  if (req.method == 'POST' && url.pathname == '/v1/ai/image-generate') {
    final body = await req.json() as Map<String, dynamic>;
    final model = (body['model'] as String?) ?? '@cf/stabilityai/stable-diffusion-xl-base-1.0';
    final prompt = body['prompt'] as String? ?? '';
    final img = await callWorkersAIHttp(model: model, input: {'prompt': prompt}, env: env);
    // Return base64 or write to R2 and return key
    return Response.json(img);
  }

  return Response('Not found', status: 404);
}

For long-running tasks (e.g., large video analysis), return a job id and use KV to track status; have the client poll /v1/jobs/:id.

⸻

6) Domain Routes & Permissions
	•	Maintain permission checks server-side that parallel your instant.perms.ts rules (owner-only reads/writes, role checks).
	•	Cache user → project membership in KV for quick checks; do a background refresh as needed.

/dart-worker/lib/routes/domain.dart (example)

Future<Response> handleDomainRoutes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);

  if (req.method == 'GET' && url.pathname == '/v1/projects') {
    // Example: fetch from your DB (Instant) via your own internal service
    // or call out to a minimal admin endpoint that the TS shim also exposes.
    final projects = await getProjectsForUser(auth.userId);
    return Response.json({'projects': projects});
  }

  return Response('Not found', status: 404);
}


⸻

7) Flutter Client Additions

Auth exchange:

class AuthApi {
  AuthApi(this.baseUrl);
  final String baseUrl;

  Future<String> exchangeRefreshForSession(String instantRefreshToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/session'), // TS shim URL
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'refresh_token': instantRefreshToken}),
    );
    if (res.statusCode != 200) throw Exception('Auth failed');
    final j = jsonDecode(res.body);
    return j['token'] as String; // short-lived session JWT
  }
}

Dart Worker client:

class ApiClient {
  ApiClient(this.workerBaseUrl, this.getSessionToken);
  final String workerBaseUrl;
  final Future<String> Function() getSessionToken; // handles refresh

  Future<http.Response> _authedGet(Uri uri) async {
    final t = await getSessionToken();
    return http.get(uri, headers: {'Authorization': 'Bearer $t'});
  }

  Future<Map<String, dynamic>> aiTextGenerate(String prompt) async {
    final res = await http.post(
      Uri.parse('$workerBaseUrl/v1/ai/text-generate'),
      headers: {
        'Authorization': 'Bearer ${await getSessionToken()}',
        'content-type': 'application/json'
      },
      body: jsonEncode({'prompt': prompt}),
    );
    if (res.statusCode == 429) throw Exception('Rate limited');
    if (res.statusCode >= 400) throw Exception('API error');
    return jsonDecode(res.body);
  }
}

Uploads:
	•	For small/medium: POST /v1/r2/upload with the file stream.
	•	For large: GET /v1/r2/signed-put → use returned PUT URL (S3 V4); then PUT bytes directly (with http).

⸻

8) Security & Ops
	•	Secrets: store SESSION_JWT_SECRET, R2 access key/secret (if presigning), Workers AI token (if HTTP mode) as secrets (Wrangler).
	•	CORS: configure for your app origins (especially for web Flutter builds).
	•	Logging: log request id, user id, route, and duration; consider sampling for heavy traffic.
	•	Observability: add simple metrics to KV or an external sink (errors, 429s, upload sizes).
	•	Abuse controls: add WAF rate-limiting rules at the zone (coarse) + DO limiter (fine).

⸻

9) Deliverables Checklist

TS Auth Shim
	•	wrangler.toml with nodejs_compat
	•	src/index.ts with /auth/session
	•	Uses @instantdb/admin to verify; signs HS256 (10-min TTL)
	•	SESSION_JWT_SECRET secret set

Dart API Worker
	•	wrangler.toml with R2/KV/DO bindings
	•	lib/main.dart (router) + auth_guard.dart (JWT verify)
	•	do/rate_limiter.dart (100/min default)
	•	routes/r2.dart (proxy upload + presigned PUT)
	•	routes/ai.dart (text/image endpoints)
	•	routes/domain.dart (example resources)
	•	util/jwt.dart, util/http.dart, perms.dart
	•	CI task to build Dart → JS and wrangler deploy

Flutter package
	•	AuthApi for session exchange
	•	ApiClient for Worker calls (401/429 handling)
	•	Upload helpers for proxy & presigned PUT

⸻

10) Rollout Plan
	1.	Deploy TS auth shim to staging; test with an Instant refresh token; verify session JWT.
	2.	Deploy Dart Worker with health route; then turn on auth guard + DO limiter.
	3.	Enable R2 bindings; test proxy upload; then add presigned PUT for large files.
	4.	Enable AI endpoints behind a feature flag; test with a small prompt/image.
	5.	Wire Flutter client to use the new session exchange and Worker routes.
	6.	Add WAF rate limits at the zone for extra protection.

---
Amazing — let’s ship the full kit: (1) a Dart S3 SigV4 presigner for R2, (2) a Justfile (plus optional Melos), (3) a tiny Flutter demo screen, and (4) an extensible “Worker Template” design that your Flutter App Shell can expose so other teams can clone/extend/deploy their own Workers.

⸻

0) Monorepo layout (suggested)

appshell/
├─ packages/
│  ├─ flutter_app_shell/                 # your existing Flutter package
│  └─ flutter_app_shell_cli/             # optional: a small CLI to scaffold worker projects
├─ workers/
│  ├─ ts-auth-shim/                      # TypeScript auth shim (Instant verify → session JWT)
│  └─ dart-api-worker/                   # Dart Worker (R2, AI, domain routes, DO rate-limit)
│     ├─ lib/
│     │  ├─ main.dart
│     │  ├─ env.dart
│     │  ├─ routes/
│     │  │  ├─ auth_guard.dart
│     │  │  ├─ r2.dart
│     │  │  ├─ ai.dart
│     │  │  ├─ rate_limit.dart
│     │  │  └─ domain.dart
│     │  ├─ do/rate_limiter.dart
│     │  └─ util/
│     │     ├─ jwt.dart
│     │     ├─ http.dart
│     │     └─ r2_presign.dart          # (1) S3 SigV4 presigner (below)
│     ├─ pubspec.yaml
│     └─ wrangler.toml
└─ Justfile                               # (2) build/deploy tasks for both workers


⸻

1) Dart S3 SigV4 R2 presigned PUT helper

Works for very large uploads: client asks the Dart Worker for a presigned PUT URL, then uploads directly to R2.

lib/util/r2_presign.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Presign an R2 S3-compatible PUT URL using AWS SigV4.
/// Defaults to region 'auto' which is typical for Cloudflare R2.
/// host looks like: "<accountId>.r2.cloudflarestorage.com"
class R2PresignResult {
  R2PresignResult({required this.url});
  final Uri url; // complete presigned URL for HTTP PUT
}

R2PresignResult presignR2PutUrl({
  required String accountId,
  required String bucket,
  required String objectKey,
  required String accessKeyId,      // R2 access key
  required String secretAccessKey,  // R2 secret
  String region = 'auto',
  int expiresInSeconds = 600,       // 10 minutes
  DateTime? now,
}) {
  now ??= DateTime.now().toUtc();
  final amzDate = _fmtAmzDate(now);        // yyyyMMdd'T'HHmmss'Z'
  final date = _fmtDate(now);              // yyyyMMdd
  final service = 's3';
  final credentialScope = '$date/$region/$service/aws4_request';

  final host = '$accountId.r2.cloudflarestorage.com';
  final canonicalUri = '/$bucket/${_uriEncode(objectKey, encodeSlash: false)}';

  // Query params (sorted)
  final query = <String, String>{
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Credential':
        '${Uri.encodeQueryComponent('$accessKeyId/$credentialScope')}',
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': expiresInSeconds.toString(),
    'X-Amz-SignedHeaders': 'host',
  };

  final canonicalQuery = _canonicalQuery(query);

  // Only 'host' as signed header for a classic presign.
  final canonicalHeaders = 'host:$host\n';
  final signedHeaders = 'host';

  // For presigned URL we can use the literal 'UNSIGNED-PAYLOAD'
  const payloadHash = 'UNSIGNED-PAYLOAD';

  final canonicalRequest = [
    'PUT',
    canonicalUri,
    canonicalQuery,
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');

  final canonicalRequestHash =
      sha256.convert(utf8.encode(canonicalRequest)).toString();

  final stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    canonicalRequestHash,
  ].join('\n');

  // Derive signing key
  final kDate = _hmac(utf8.encode('AWS4$secretAccessKey'), utf8.encode(date));
  final kRegion = _hmac(kDate, utf8.encode(region));
  final kService = _hmac(kRegion, utf8.encode(service));
  final kSigning = _hmac(kService, utf8.encode('aws4_request'));

  final signature =
      Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

  final fullQuery = '$canonicalQuery&X-Amz-Signature=$signature';
  final url = Uri.https(host, canonicalUri, _parseQuery(fullQuery));
  return R2PresignResult(url: url);
}

String _fmtAmzDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  final ss = dt.second.toString().padLeft(2, '0');
  return '$y$m$d' 'T' '$hh$mm$ss' 'Z';
}

String _fmtDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y$m$d';
}

List<int> _hmac(List<int> key, List<int> data) =>
    Hmac(sha256, key).convert(data).bytes;

/// Build canonical query string from map (already URI-encoded values for AWS).
String _canonicalQuery(Map<String, String> params) {
  final entries = params.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries
      .map((e) => '${e.key}=${e.value}')
      .join('&');
}

/// Convert canonical query back to map for Uri.https ctor.
Map<String, dynamic> _parseQuery(String query) {
  final pairs = query.split('&');
  final map = <String, String>{};
  for (final p in pairs) {
    final i = p.indexOf('=');
    final k = i == -1 ? p : p.substring(0, i);
    final v = i == -1 ? '' : p.substring(i + 1);
    map[k] = v;
  }
  return map;
}

/// URI-encode per AWS rules (space -> %20, slash optionally preserved).
String _uriEncode(String s, {bool encodeSlash = true}) {
  final enc = Uri.encodeComponent(s)
      .replaceAll('%2F', encodeSlash ? '%2F' : '/')
      .replaceAll('+', '%20');
  return enc;
}

Usage inside routes/r2.dart (presign endpoint sketch):

import '../util/r2_presign.dart';

Future<Response> handleR2Routes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);

  if (req.method == 'GET' && url.pathname == '/v1/r2/signed-put') {
    final key = url.searchParams.get('key') ??
        '${auth.userId}/${DateTime.now().millisecondsSinceEpoch}.mp4';

    // Fetch your R2 credentials from Secrets/KV.
    final accountId = await getSecret('R2_ACCOUNT_ID');
    final accessKey = await getSecret('R2_ACCESS_KEY_ID');
    final secretKey = await getSecret('R2_SECRET_ACCESS_KEY');
    final bucket = await getSecret('R2_BUCKET');

    final presigned = presignR2PutUrl(
      accountId: accountId,
      bucket: bucket,
      objectKey: key,
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
      region: 'auto',
      expiresInSeconds: 600,
    );

    return Response.json({
      'url': presigned.url.toString(),
      'key': key,
    });
  }

  // ... existing proxy upload / get / delete handlers
  return Response('Not found', status: 404);
}

Tip: for very large uploads, prefer presigned PUT. Keep proxy upload for small files and for environments where direct PUT isn’t possible.

⸻

2) Justfile (and optional Melos) for build & deploy

Justfile (top-level)

# Global variables (edit per environment)
set dotenv-load := true

# Paths
WORKER_DART_DIR := "workers/dart-api-worker"
WORKER_TS_DIR   := "workers/ts-auth-shim"

# ---- Shared ----
default: help

help:
	@echo "Tasks:"
	@echo "  just setup                     # wrangler login, npm install"
	@echo "  just secrets                   # set shared secrets (interactive)"
	@echo "  just dev-dart                  # run Dart worker in wrangler dev"
	@echo "  just build-dart                # compile Dart → JS"
	@echo "  just deploy-dart               # deploy Dart worker"
	@echo "  just dev-shim                  # run TS shim in wrangler dev"
	@echo "  just deploy-shim               # deploy TS shim"
	@echo "  just r2-create BUCKET=...      # create R2 bucket"
	@echo "  just tail-dart                 # tail logs"
	@echo "  just tail-shim                 # tail logs"

setup:
	cd {{WORKER_TS_DIR}} && npm i
	wrangler login

secrets:
	# TS shim secrets
	cd {{WORKER_TS_DIR}} && wrangler secret put SESSION_JWT_SECRET
	cd {{WORKER_TS_DIR}} && wrangler secret put INSTANT_APP_ID
	# Dart worker secrets
	cd {{WORKER_DART_DIR}} && wrangler secret put SESSION_JWT_SECRET
	cd {{WORKER_DART_DIR}} && wrangler secret put R2_ACCOUNT_ID
	cd {{WORKER_DART_DIR}} && wrangler secret put R2_ACCESS_KEY_ID
	cd {{WORKER_DART_DIR}} && wrangler secret put R2_SECRET_ACCESS_KEY
	cd {{WORKER_DART_DIR}} && wrangler secret put R2_BUCKET

dev-dart:
	cd {{WORKER_DART_DIR}} && dart compile js -O4 -o build/worker.js lib/main.dart
	cd {{WORKER_DART_DIR}} && wrangler dev

build-dart:
	cd {{WORKER_DART_DIR}} && dart compile js -O4 -o build/worker.js lib/main.dart

deploy-dart: build-dart
	cd {{WORKER_DART_DIR}} && wrangler deploy

dev-shim:
	cd {{WORKER_TS_DIR}} && wrangler dev

deploy-shim:
	cd {{WORKER_TS_DIR}} && wrangler deploy

r2-create BUCKET:
	wrangler r2 bucket create {{BUCKET}}

tail-dart:
	cd {{WORKER_DART_DIR}} && wrangler tail

tail-shim:
	cd {{WORKER_TS_DIR}} && wrangler tail

Optional melos.yaml (if you want workspace management)

name: appshell
packages:
  - workers/dart-api-worker
  - workers/ts-auth-shim
  - packages/**
scripts:
  build:dart: dart --version && dart compile js -O4 -o build/worker.js lib/main.dart
  deploy:dart: wrangler deploy
  dev:dart: wrangler dev
  deploy:shim: wrangler deploy


⸻

3) Mini Flutter demo screen (proxy upload, presigned upload, AI text)

Assumes you’ve wired a small AuthApi to get a session JWT from the TS shim, and ApiClient to call the Dart Worker (you likely already have these from earlier).

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WorkerDemoScreen extends StatefulWidget {
  const WorkerDemoScreen({
    super.key,
    required this.shimBaseUrl,     // e.g. https://instant-auth-shim.your.workers.dev
    required this.workerBaseUrl,   // e.g. https://dart-api-worker.your.workers.dev
    required this.instantRefreshTokenProvider,
  });

  final String shimBaseUrl;
  final String workerBaseUrl;
  final Future<String> Function() instantRefreshTokenProvider;

  @override
  State<WorkerDemoScreen> createState() => _WorkerDemoScreenState();
}

class _WorkerDemoScreenState extends State<WorkerDemoScreen> {
  String? _sessionJwt;
  String _log = '';

  Future<void> _ensureSession() async {
    if (_sessionJwt != null) return;
    final refresh = await widget.instantRefreshTokenProvider();
    final res = await http.post(
      Uri.parse('${widget.shimBaseUrl}/auth/session'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'refresh_token': refresh}),
    );
    if (res.statusCode != 200) throw Exception('auth failed: ${res.body}');
    _sessionJwt = (jsonDecode(res.body) as Map)['token'] as String;
  }

  Future<void> _proxyUploadSmall() async {
    await _ensureSession();
    final bytes = Uint8List.fromList(List<int>.generate(256 * 1024, (i) => i % 256)); // 256KB
    final uri = Uri.parse('${widget.workerBaseUrl}/v1/r2/upload?contentType=application/octet-stream');
    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $_sessionJwt',
      'content-type': 'application/octet-stream',
    }, body: bytes);
    setState(() => _log = 'proxy upload: ${res.statusCode} ${res.body}');
  }

  Future<void> _presignedUploadLarge() async {
    await _ensureSession();
    // 1) Get a presigned PUT URL
    final presign = await http.get(
      Uri.parse('${widget.workerBaseUrl}/v1/r2/signed-put'),
      headers: {'Authorization': 'Bearer $_sessionJwt'},
    );
    if (presign.statusCode != 200) throw Exception('presign failed: ${presign.body}');
    final j = jsonDecode(presign.body) as Map<String, dynamic>;
    final putUrl = j['url'] as String;
    final key = j['key'] as String;

    // 2) PUT the bytes directly to R2
    final big = Uint8List.fromList(List<int>.generate(2 * 1024 * 1024, (i) => (i * 31) % 256)); // 2MB
    final putRes = await http.put(Uri.parse(putUrl),
        headers: {'content-type': 'application/octet-stream'}, body: big);

    setState(() => _log =
        'presigned upload: ${putRes.statusCode}; key=$key; etag=${putRes.headers['etag']}');
  }

  Future<void> _aiText() async {
    await _ensureSession();
    final res = await http.post(
      Uri.parse('${widget.workerBaseUrl}/v1/ai/text-generate'),
      headers: {
        'Authorization': 'Bearer $_sessionJwt',
        'content-type': 'application/json'
      },
      body: jsonEncode({'prompt': 'Write a cheerful haiku about cameras.'}),
    );
    setState(() => _log = 'AI: ${res.statusCode}\n${res.body}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            ElevatedButton(onPressed: _proxyUploadSmall, child: const Text('Proxy Upload (small)')),
            ElevatedButton(onPressed: _presignedUploadLarge, child: const Text('Presigned Upload (large)')),
            ElevatedButton(onPressed: _aiText, child: const Text('AI: Text Generate')),
          ]),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(child: Text(_log))),
        ]),
      ),
    );
  }
}

For web builds, remember CORS on both Workers (shim + Dart). For mobile, you’re fine.

⸻

4) Make the Dart Worker easy to extend (for downstream teams)

You want other devs to copy a template, add routes, and deploy under their account. Here’s a lightweight, robust plan:

A. Publish a Worker Template in your package

Inside flutter_app_shell, ship:
	•	/templates/dart-api-worker-template/ (entire ready-to-deploy worker)
	•	/templates/ts-auth-shim-template/
	•	A tiny CLI (optional) flutter_app_shell_cli with:
	•	appshell init-worker my-worker → copies template to ./my-worker
	•	Prompts for accountId, bucket, INSTANT_APP_ID, etc.
	•	Writes wrangler.toml, seeds a Justfile with the right paths

Developers do:

dart pub global activate flutter_app_shell_cli
appshell init-worker my-api
cd my-api
just setup
just secrets
just deploy-shim
just deploy-dart

B. Route extension hooks

In your template worker:

lib/main.dart

typedef RouteHandler = Future<Response> Function(Request req, Env env, AuthContext auth);
final Map<String, RouteHandler> routeRegistry = {};

void registerRoute(String prefix, RouteHandler handler) {
  routeRegistry[prefix] = handler;
}

@CloudflareWorker()
Future<Response> fetch(Request req, Env env, Context ctx) async {
  final url = URL(req.url);

  // public health
  if (url.pathname == '/health') return Response('ok');

  // auth + rate-limit
  final auth = await authenticate(req, env);
  final rl = RateLimiterClient(env);
  await rl.consume(auth.userId);

  // built-in routes
  if (url.pathname.startsWith('/v1/r2')) return handleR2Routes(req, env, auth);
  if (url.pathname.startsWith('/v1/ai')) return handleAIRoutes(req, env, auth);
  if (url.pathname.startsWith('/v1/projects')) return handleDomainRoutes(req, env, auth);

  // extension hooks
  for (final entry in routeRegistry.entries) {
    if (url.pathname.startsWith(entry.key)) {
      return entry.value(req, env, auth);
    }
  }

  return Response('Not found', status: 404);
}

Downstream developers drop a new file extensions/my_feature.dart:

import '../lib/main.dart' show registerRoute;
import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../lib/routes/auth_guard.dart';

void registerMyFeature() {
  registerRoute('/v1/my-feature', (Request req, Env env, AuthContext auth) async {
    // add your logic here
    return Response.json({'hello': auth.userId});
  });
}

Then call registerMyFeature() from a small extensions/bootstrap.dart that the template imports in main.dart. This gives teams a simple, declarative way to add features without touching core code.

C. Configuration Strategy
	•	Everything via Wrangler vars/secrets: bucket name, R2 keys, JWT issuer/audience, etc.
	•	Provide a single env.sample file and a just secrets task to set them.
	•	Make session JWT claims your public contract (sub, email?, roles[], exp); document it in the template README so downstream services can rely on it.

D. Multi-tenant considerations
	•	Keep the auth shim + Dart Worker per tenant (simplest).
	•	Or: centralize the auth shim (multi-tenant) and encode tenantId into the session JWT so one Dart Worker instance can route to different buckets/prefixes: key = "$tenantId/$userId/<timestamp>.mp4".

E. Versioning
	•	Maintain semver on the template: tag releases (v1.x → stable JWT schema).
	•	Keep the Flutter client and Worker template in lockstep (changelog entries include “JWT claim change,” “route path change,” etc.).

⸻

Final notes & tips
	•	For R2 large uploads from the web, add CORS response headers on OPTIONS and PUT (your presign URL host is R2; configure bucket CORS too).
	•	Add WAF rate-limit rules at the zone as a coarse front line; keep the Durable Object limiter for per-user fairness.
	•	For Workers AI: start with the text route; images can optionally write outputs to R2 and return a key rather than fat base64.
	•	If you later get access to an InstantDB JWKS or Dart-friendly verification, you can retire the TS shim and verify tokens directly in Dart; your session-JWT design makes that a drop-in change.

⸻

Boom — shipped. I put a ready-to-use template on disk with:
	•	a minimal TS auth shim (Instant verify → HS256 session JWT),
	•	a Dart Cloudflare Worker (auth guard, DO rate-limiter, R2 proxy + presigned PUT, Workers AI route),
	•	a top-level Justfile,
	•	and a small Flutter demo screen.

Download the full template (ZIP)

What’s inside (quick map)

appshell-worker-template/
├─ workers/
│  ├─ ts-auth-shim/             # TypeScript Worker: /auth/session → session JWT
│  │  ├─ wrangler.toml
│  │  ├─ package.json
│  │  ├─ tsconfig.json
│  │  └─ src/index.ts
│  └─ dart-api-worker/          # Dart Worker: R2, AI, DO rate-limit, extension hooks
│     ├─ wrangler.toml
│     ├─ pubspec.yaml
│     └─ lib/
│        ├─ env.dart
│        ├─ main.dart
│        ├─ routes/
│        │  ├─ auth_guard.dart          # verifies our short-lived session JWT
│        │  ├─ r2.dart                  # proxy/presigned uploads, get, delete
│        │  ├─ ai.dart                  # Workers AI via HTTPS API
│        │  ├─ domain.dart              # example "projects" route
│        │  └─ rate_limit.dart          # DO client wrapper
│        ├─ do/rate_limiter.dart        # Durable Object (100/min per user)
│        └─ util/
│           ├─ jwt.dart                 # HS256 verify
│           └─ r2_presign.dart          # S3 SigV4 presigner for R2
├─ packages/
│  └─ flutter_app_shell_demo/
│     └─ lib/worker_demo_screen.dart    # small UI to exercise the endpoints
├─ Justfile
└─ README.md

How your Flutter App Shell can let others extend/deploy
	•	Treat workers/dart-api-worker as a template. In your flutter_app_shell package, ship this folder under /templates/ and provide a CLI or a just task to copy and rename it.
	•	Extension hooks: the worker already supports simple extension. Teams can drop lib/extensions/my_feature.dart and either:
	•	wire it in main.dart (uncomment the example), or
	•	register routes via a tiny registry function (keeps core untouched).
	•	Per-team deploy: each team sets their own secrets & R2 bucket via wrangler.toml vars/secrets, then runs just deploy-shim and just deploy-dart.

Dev notes & to-dos for your team
	•	In lib/routes/auth_guard.dart, implement getSecret(...) to read secrets from env or KV (right now it throws to remind you).
	•	In workers/dart-api-worker/pubspec.yaml, bump cloudflare_workers to the latest version you use.
	•	For Workers AI:
	•	If your account exposes an AI binding, you can switch from HTTPS calls to using that binding.
	•	Otherwise, the included route uses the public HTTPS API with CF_API_TOKEN.
	•	For web apps, set CORS on both workers and make sure your R2 bucket has permissive CORS for PUT on the presigned endpoint domain.

One-liners you’ll use a lot
	•	configure auth + R2 + AI secrets:

just secrets


	•	local dev:

just dev-shim
just dev-dart


	•	deploy:

just deploy-shim
just deploy-dart


	•	create an R2 bucket:

just r2-create BUCKET=app-media


---
Perfect — I tailored the template to your repo layout and bundled it so you can just drop it in.

Download the repo-ready integration bundle

Where to place things in flutter_ps_app_shell
	•	Unzip to the repo root. It will create:

workers/
  ts-auth-shim/        # TS auth shim (Instant verify → HS256 session JWT)
  dart-api-worker/     # Dart Worker (R2 + AI + DO rate limiter)
packages/flutter_app_shell/templates/
  ts-auth-shim/
  dart-api-worker/
docs/CLOUDFLARE_INTEGRATION_ADDENDUM.md
justfile.cloudflare


	•	If you prefer to keep templates inside your package only, you can move the two folders under packages/flutter_app_shell/templates/ and keep workers/ empty until a downstream app uses the template.

Hook into your existing justfile

You already have a root justfile. Easiest options:
	1.	Include the provided justfile.cloudflare tasks (copy/paste the targets you want), or
	2.	Keep it separate and run from repo root when needed.

Key tasks you’ll use:

just setup          # wrangler login + npm install for shim
just secrets        # set all required secrets
just dev-shim       # local dev for TS auth shim
just deploy-shim    # deploy TS auth shim
just dev-dart       # build Dart → JS + wrangler dev
just deploy-dart    # deploy Dart worker

Secrets you’ll need to set
	•	Auth shim: SESSION_JWT_SECRET, INSTANT_APP_ID
	•	Dart worker: SESSION_JWT_SECRET, R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET, CF_API_TOKEN (for Workers AI HTTPS)
	•	Optional vars to tweak in workers/dart-api-worker/wrangler.toml:
	•	R2_PUBLIC_BASE (public read URL form)
	•	CF_ACCOUNT_ID (for AI HTTPS endpoint routing)

How other developers extend & deploy from your App Shell
	•	Ship the contents of packages/flutter_app_shell/templates/ with your package.
	•	Document a tiny workflow (works for each downstream app):
	1.	Copy packages/flutter_app_shell/templates/ts-auth-shim → workers/ts-auth-shim
	2.	Copy packages/flutter_app_shell/templates/dart-api-worker → workers/dart-api-worker
	3.	Run just setup && just secrets
	4.	just deploy-shim && just deploy-dart
	•	They add new routes in workers/dart-api-worker/lib/extensions/ and wire them in main.dart (there’s a comment showing where).

What’s included (recap)
	•	ts-auth-shim: /auth/session endpoint using @instantdb/admin to verify the Instant token and mint a short-lived HS256 session JWT.
	•	dart-api-worker:
	•	Auth guard that verifies your session JWT in pure Dart
	•	Durable Object rate limiter (100/min/user by default)
	•	R2 routes:
	•	Proxy upload: POST /v1/r2/upload
	•	Presigned PUT: GET /v1/r2/signed-put
	•	Get/Delete object
	•	S3 SigV4 presigner in Dart (util/r2_presign.dart)
	•	Workers AI route:
	•	POST /v1/ai/text-generate (HTTPS API; switch to AI binding later if you prefer)
	•	Extension-ready router and a simple domain route stub

Next small tweaks you’ll want to make
	•	In workers/dart-api-worker/lib/routes/auth_guard.dart, implement getSecret(...) to read from environment or KV (right now it throws to remind you).
	•	Tune the CORS headers for your web origins.
	•	If you want to demo this inside your example/ app quickly, point it at:
	•	shimBaseUrl = https://<your-shim>.workers.dev
	•	workerBaseUrl = https://<your-dart-worker>.workers.dev
