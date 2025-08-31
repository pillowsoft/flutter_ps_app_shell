# AppShell Worker Template

This bundle contains:
- **TS Auth Shim** (`workers/ts-auth-shim`): verifies Instant token and mints a short-lived session JWT.
- **Dart API Worker** (`workers/dart-api-worker`): authenticated REST API with R2 uploads (proxy + presigned) and Workers AI routes, plus a Durable Object rate limiter.
- **Justfile**: common tasks for local dev and deploy.
- **Flutter demo**: `packages/flutter_app_shell_demo/lib/worker_demo_screen.dart` showing proxy upload, presigned upload, and AI call.

## Quick start

1. Install Cloudflare Wrangler and login:
   ```bash
   npm i -g wrangler
   just setup
   ```

2. Set secrets (interactive prompts):
   ```bash
   just secrets
   ```

3. (Optional) Create an R2 bucket:
   ```bash
   just r2-create BUCKET=app-media
   ```

4. Run locally:
   ```bash
   just dev-shim
   just dev-dart
   ```

5. Deploy:
   ```bash
   just deploy-shim
   just deploy-dart
   ```

## Extend the Dart Worker

- Add routes under `lib/routes/` or create `lib/extensions/my_feature.dart` and wire it in `lib/main.dart`.
- Keep JWT claims stable (`sub`, `email?`, `roles[]`) or bump a major version.

## Notes

- Implement `getSecret(...)` in `auth_guard.dart` to load secrets from environment or KV.
- Adjust `cloudflare_workers` version in `pubspec.yaml` if needed.
- For very large uploads, prefer presigned PUT URLs.
- For web uploads, configure CORS on the Worker and your R2 bucket.
