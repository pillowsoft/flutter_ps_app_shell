# Cloudflare Integration (Repo-tailored)

This folder is ready to drop into your repo root. Suggested placement:
- `workers/ts-auth-shim/`
- `workers/dart-api-worker/`

Add these lines to your root `justfile` (or keep a separate `justfile.cloudflare`):

```
WORKER_DART_DIR := "workers/dart-api-worker"
WORKER_TS_DIR   := "workers/ts-auth-shim"

dev-dart:
	cd {{WORKER_DART_DIR}} && dart compile js -O4 -o build/worker.js lib/main.dart
	cd {{WORKER_DART_DIR}} && wrangler dev

deploy-dart:
	cd {{WORKER_DART_DIR}} && dart compile js -O4 -o build/worker.js lib/main.dart
	cd {{WORKER_DART_DIR}} && wrangler deploy

dev-shim:
	cd {{WORKER_TS_DIR}} && wrangler dev

deploy-shim:
	cd {{WORKER_TS_DIR}} && wrangler deploy
```

Secrets to set:
```
wrangler secret put SESSION_JWT_SECRET
wrangler secret put INSTANT_APP_ID            # shim
wrangler secret put R2_ACCOUNT_ID             # dart worker
wrangler secret put R2_ACCESS_KEY_ID
wrangler secret put R2_SECRET_ACCESS_KEY
wrangler secret put R2_BUCKET
wrangler secret put CF_API_TOKEN              # Workers AI HTTPS
```
