# Cloudflare Workers Templates

This directory contains templates for extending your Flutter App Shell with Cloudflare Workers capabilities.

## What's Included

- **TypeScript Auth Shim** (`workers/ts-auth-shim/`): Handles InstantDB refresh token verification and mints short-lived session JWTs
- **Dart API Worker** (`workers/dart-api-worker/`): Main API endpoints with R2 storage, Workers AI, and rate limiting
- **Justfile**: Build automation for development and deployment
- **CloudflareService**: Pre-built Flutter service for seamless integration

## Quick Start

1. Copy templates to your project root:
   ```bash
   cp -r packages/flutter_app_shell/templates/cloudflare/* .
   ```

2. Install dependencies and login:
   ```bash
   just setup-cloudflare
   ```

3. Set your secrets (interactive prompts):
   ```bash
   just secrets-cloudflare
   ```

4. Optional - Create R2 bucket:
   ```bash
   just r2-create-cloudflare BUCKET=app-media
   ```

5. Start development:
   ```bash
   # Terminal 1: TypeScript Auth Shim
   just dev-auth-shim
   
   # Terminal 2: Dart API Worker  
   just dev-dart-worker
   ```

6. Deploy when ready:
   ```bash
   just deploy-cloudflare
   ```

## Architecture

### TypeScript Auth Shim
- Lightweight worker handling only InstantDB admin SDK integration
- Verifies refresh tokens and mints 10-minute session JWTs
- Minimal external dependencies for security and performance

### Dart API Worker
- Main business logic compiled from Dart to JavaScript
- Authenticated via session JWTs from the auth shim
- Features: R2 storage, Workers AI, rate limiting, custom endpoints

## Extending Functionality

### Adding Custom Routes
Create new route handlers in `workers/dart-api-worker/lib/routes/`:

```dart
// lib/routes/my_feature.dart
import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import 'auth_guard.dart';

Future<Response> handleMyFeatureRoutes(Request req, Env env, AuthResult auth) async {
  final url = URL(req.url);
  
  if (req.method == 'POST' && url.pathname == '/v1/my-feature/action') {
    // Your custom logic here
    return Response('{"success": true}', 
      headers: {'content-type': 'application/json'});
  }
  
  return Response('Not found', status: 404);
}
```

Then register in `lib/main.dart`:
```dart
if (url.pathname.startsWith('/v1/my-feature')) {
  return _cors(await handleMyFeatureRoutes(req, env, auth));
}
```

### Flutter Integration
The CloudflareService is automatically registered in your app's dependency injection. Use it in your Flutter app:

```dart
final cloudflare = getIt<CloudflareService>();

// Upload a file
final result = await cloudflare.uploadFile(
  bytes: fileBytes,
  filename: 'photo.jpg',
);

// Generate AI text
final text = await cloudflare.generateText(
  prompt: 'Write a haiku about Flutter',
);

// Custom API call
final response = await cloudflare.callCustomEndpoint(
  endpoint: '/v1/my-feature/action',
  method: 'POST',
  data: {'key': 'value'},
);
```

## Environment Configuration

Add these to your `.env` file:

```env
# Required for CloudflareService
CLOUDFLARE_WORKER_URL=https://your-worker.your-subdomain.workers.dev
SESSION_JWT_SECRET=your-256-bit-secret-here
SESSION_JWT_ISSUER=your-app-name
SESSION_JWT_AUDIENCE=your-app-name

# Required for auth shim
INSTANTDB_APP_ID=your-instant-app-id
```

## Development Tips

- Use `just tail-dart-worker` and `just tail-auth-shim` to monitor logs
- Test endpoints with `just test-cloudflare` after setup
- Keep JWT claims stable (`sub`, `email`, `roles`) for compatibility
- Use presigned URLs for uploads >5MB for better performance
