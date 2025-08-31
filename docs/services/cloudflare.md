# Cloudflare Integration

The Flutter App Shell provides comprehensive Cloudflare Workers integration for extending your app with edge computing capabilities, R2 storage, and AI functionality.

## Overview

Cloudflare integration consists of three main components:

1. **CloudflareService** - Flutter service for seamless integration
2. **TypeScript Auth Shim** - Handles InstantDB authentication and JWT minting
3. **Dart API Worker** - Main business logic with R2, AI, and custom endpoints

## Quick Setup

### 1. Copy Templates

```bash
# Copy worker templates to your project root
cp -r packages/flutter_app_shell/templates/cloudflare/* .
```

### 2. Install Dependencies

```bash
# Install Wrangler CLI and project dependencies
just setup-cloudflare
```

### 3. Configure Environment

Add to your `.env` file:

```env
# CloudflareService configuration
CLOUDFLARE_WORKER_URL=https://your-worker.your-subdomain.workers.dev
SESSION_JWT_SECRET=your-256-bit-secret-here
SESSION_JWT_ISSUER=your-app-name
SESSION_JWT_AUDIENCE=your-app-name

# InstantDB integration
INSTANTDB_APP_ID=your-instant-app-id
```

### 4. Set Worker Secrets

```bash
# Interactive prompts for all required secrets
just secrets-cloudflare
```

### 5. Deploy Workers

```bash
# Deploy both workers
just deploy-cloudflare
```

## CloudflareService API

The CloudflareService is automatically registered in your app's dependency injection system.

### Basic Usage

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final cloudflare = getIt<CloudflareService>();
        
        // Check if service is available
        if (!cloudflare.isConfigured) {
          print('Cloudflare not configured');
          return;
        }
        
        try {
          // Upload a file
          final result = await cloudflare.uploadFile(
            bytes: fileBytes,
            filename: 'photo.jpg',
          );
          print('Upload URL: ${result.url}');
          
        } catch (e) {
          print('Upload failed: $e');
        }
      },
      child: Text('Upload File'),
    );
  }
}
```

### File Upload Methods

The CloudflareService provides intelligent file upload handling:

```dart
final cloudflare = getIt<CloudflareService>();

// Automatic upload strategy selection
// <5MB: Proxy upload (simpler, faster for small files)
// ≥5MB: Presigned URL upload (better for large files)
final result = await cloudflare.uploadFile(
  bytes: fileBytes,
  filename: 'document.pdf',
  largeSizeThreshold: 5 * 1024 * 1024, // 5MB (default)
);

// Force proxy upload (good for small files)
final proxyResult = await cloudflare.uploadFileProxy(
  bytes: fileBytes,
  filename: 'small-image.jpg',
);

// Force presigned URL upload (good for large files)
final presignedResult = await cloudflare.uploadFilePresigned(
  bytes: fileBytes,
  filename: 'large-video.mp4',
);

print('File available at: ${result.url}');
print('CDN URL: ${result.cdnUrl}'); // If CDN is configured
```

### AI Integration with AI Gateway

The CloudflareService supports both direct Workers AI and the advanced AI Gateway for multi-provider AI capabilities.

#### Basic AI Usage (Backward Compatible)

```dart
final cloudflare = getIt<CloudflareService>();

// Text generation with Workers AI
final generatedText = await cloudflare.generateText(
  prompt: 'Write a professional email about Flutter development',
  model: '@cf/meta/llama-3.1-8b-instruct',
);

// Image generation with Workers AI  
final imageBytes = await cloudflare.generateImage(
  prompt: 'A beautiful sunset over mountains, digital art style',
  model: '@cf/stabilityai/stable-diffusion-xl-base-1.0',
);
```

#### Advanced AI Gateway Usage

When AI Gateway is configured, you get access to multiple providers with automatic fallback:

```dart
final cloudflare = getIt<CloudflareService>();

// Multi-provider text generation with advanced options
final result = await cloudflare.generateTextAdvanced(
  prompt: 'Explain quantum computing in simple terms',
  provider: 'openai',           // OpenAI, Anthropic, Workers AI, etc.
  model: 'gpt-4o',             // Model specific to provider
  maxTokens: 150,              // Fine-tune output length
  temperature: 0.7,            // Control creativity
  enableCache: true,           // Enable response caching
  fallbacks: [                 // Automatic fallback chain
    CloudflareAIFallback(provider: 'anthropic', model: 'claude-3-haiku-20240307'),
    CloudflareAIFallback(provider: 'workers-ai', model: '@cf/meta/llama-3.1-8b-instruct'),
  ],
);

// Access detailed result information
print('Response: ${result.response}');
print('Provider used: ${result.provider}');
print('Was cached: ${result.cached}');
print('Used fallback: ${result.usedFallback}');
if (result.usage != null) {
  print('Tokens used: ${result.usage!['total_tokens']}');
}

// Multi-provider image generation with fallback
final imageResult = await cloudflare.generateImageAdvanced(
  prompt: 'A futuristic city at sunset, cyberpunk style',
  provider: 'openai',
  model: 'dall-e-3',
  enableCache: true,
  fallbacks: [
    CloudflareAIFallback(provider: 'workers-ai', model: '@cf/stabilityai/stable-diffusion-xl-base-1.0'),
  ],
);

// Save generated image with metadata
final file = File('ai_generated_${imageResult.provider}.png');
await file.writeAsBytes(imageResult.imageBytes);
```

#### Get Available Providers

Dynamically discover available AI providers and models:

```dart
final providers = await cloudflare.getAvailableProviders();

for (final provider in providers.providers) {
  print('Provider: ${provider.name} (${provider.id})');
  print('Text models: ${provider.textModels}');
  print('Image models: ${provider.imageModels}');
  print('Requires API key: ${provider.requiresKey}');
}

// Get models for specific provider
final openAITextModels = providers.getTextModels('openai');
final workersAIImageModels = providers.getImageModels('workers-ai');
```

### Custom API Endpoints

Call your own custom worker endpoints:

```dart
final cloudflare = getIt<CloudflareService>();

// GET request
final response = await cloudflare.callCustomEndpoint(
  endpoint: '/v1/my-feature/data',
  method: 'GET',
);

// POST with data
final postResponse = await cloudflare.callCustomEndpoint(
  endpoint: '/v1/my-feature/action',
  method: 'POST',
  data: {
    'userId': 'user123',
    'action': 'process',
    'metadata': {'key': 'value'},
  },
);

print('Response: ${response.data}');
```

### Service Status and Health

Monitor the service connection and health:

```dart
final cloudflare = getIt<CloudflareService>();

// Check configuration status
if (cloudflare.isConfigured) {
  print('Service is configured and ready');
} else {
  print('Service needs configuration');
}

// Check connection status
switch (cloudflare.connectionStatus) {
  case CloudflareConnectionStatus.connected:
    print('Connected to Cloudflare');
    break;
  case CloudflareConnectionStatus.disconnected:
    print('Not connected');
    break;
  case CloudflareConnectionStatus.error:
    print('Connection error');
    break;
}

// Get current session info
final session = cloudflare.currentSession;
if (session != null) {
  print('Session expires at: ${session.expiresAt}');
  print('User ID: ${session.userId}');
}
```

## Architecture Details

### Authentication Flow

1. **Flutter App** → Gets InstantDB refresh token from AuthenticationService
2. **TypeScript Auth Shim** → Verifies refresh token with InstantDB admin SDK
3. **Auth Shim** → Mints short-lived (10min) session JWT with HS256
4. **Dart API Worker** → Validates session JWT for all protected endpoints
5. **CloudflareService** → Automatically handles token refresh and retry logic

### Security Features

- **Short-lived JWTs**: 10-minute session tokens minimize exposure
- **Automatic token refresh**: CloudflareService handles expired tokens transparently
- **Rate limiting**: 100 requests/minute per user via Durable Objects
- **CORS protection**: Configurable origins and headers
- **Request validation**: All endpoints validate authentication and input

### Performance Optimizations

- **Intelligent upload routing**: Small files via proxy, large files via presigned URLs
- **CDN integration**: Automatic CDN URL generation for uploaded files
- **Connection pooling**: Reuses HTTP connections for better performance  
- **Retry logic**: Automatic retry on network failures with exponential backoff

## Extending Worker Functionality

### Adding Custom Routes

1. Create a new route handler in `workers/dart-api-worker/lib/routes/`:

```dart
// lib/routes/analytics.dart
import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import 'auth_guard.dart';

Future<Response> handleAnalyticsRoutes(Request req, Env env, AuthResult auth) async {
  final url = URL(req.url);
  
  if (req.method == 'POST' && url.pathname == '/v1/analytics/event') {
    final body = await req.json();
    
    // Track analytics event
    await trackEvent(
      userId: auth.userId,
      event: body['event'],
      properties: body['properties'],
    );
    
    return Response('{"success": true}', 
      headers: {'content-type': 'application/json'});
  }
  
  return Response('Not found', status: 404);
}

Future<void> trackEvent(String userId, String event, Map<String, dynamic> properties) async {
  // Your analytics implementation
  console.log('Event: $userId did $event with $properties');
}
```

2. Register the route in `workers/dart-api-worker/lib/main.dart`:

```dart
import 'routes/analytics.dart';

// In the main fetch function:
if (url.pathname.startsWith('/v1/analytics')) {
  return _cors(await handleAnalyticsRoutes(req, env, auth));
}
```

3. Use from Flutter:

```dart
final response = await cloudflare.callCustomEndpoint(
  endpoint: '/v1/analytics/event',
  method: 'POST',
  data: {
    'event': 'button_clicked',
    'properties': {'button_id': 'upload_photo', 'screen': 'home'},
  },
);
```

### Environment Variables and Secrets

Add new secrets to both workers:

```bash
# Set secrets for the Dart worker
cd workers/dart-api-worker
wrangler secret put MY_API_KEY

# Set secrets for the auth shim
cd workers/ts-auth-shim  
wrangler secret put MY_OTHER_SECRET
```

Access in your Dart worker code:

```dart
// In your route handler
Future<Response> handleMyRoute(Request req, Env env, AuthResult auth) async {
  final apiKey = env.get('MY_API_KEY');
  // Use the secret...
}
```

## Development Workflow

### Local Development

```bash
# Terminal 1: Start auth shim
just dev-auth-shim

# Terminal 2: Start Dart worker  
just dev-dart-worker

# Terminal 3: Monitor logs
just tail-dart-worker
```

### Testing

```bash
# Test worker endpoints
curl -H "Authorization: Bearer YOUR_JWT" \
  https://your-worker.your-subdomain.workers.dev/v1/r2/upload

# Test from Flutter
final result = await cloudflare.uploadFile(
  bytes: testBytes,
  filename: 'test.jpg',
);
print('Success: ${result.success}');
```

### Deployment

```bash
# Deploy both workers
just deploy-cloudflare

# Or deploy individually
just deploy-dart-worker
just deploy-auth-shim

# Verify deployment
just test-cloudflare
```

## Troubleshooting

### Common Issues

**Service not configured**
- Check `.env` file has all required variables
- Verify `CLOUDFLARE_WORKER_URL` is accessible
- Ensure `SESSION_JWT_SECRET` matches between app and workers

**Authentication failures**
- Verify InstantDB app ID is correct in auth shim
- Check JWT secret consistency across all components
- Ensure user is logged in to InstantDB

**Upload failures**
- Verify R2 bucket exists and is configured
- Check R2 credentials and permissions
- Test with smaller files first

**AI generation errors**
- Verify Workers AI is enabled in Cloudflare dashboard
- Check AI model names are correct
- Monitor rate limits and quotas

### Debug Commands

```bash
# Check worker logs
just tail-dart-worker
just tail-auth-shim

# Test worker health
curl https://your-worker.your-subdomain.workers.dev/health

# Inspect JWT tokens
# In browser devtools or JWT.io
```

## Best Practices

1. **Error Handling**: Always wrap Cloudflare calls in try-catch blocks
2. **File Size Limits**: Set appropriate upload limits for your use case  
3. **Rate Limiting**: Respect the built-in rate limits (100 req/min/user)
4. **Security**: Never expose worker URLs or secrets in client-side code
5. **Performance**: Use presigned URLs for files >5MB
6. **Monitoring**: Monitor worker logs and set up alerts for errors

## Examples

See the example app's Cloudflare demo screen for complete working examples of all features.

## Migration

When updating CloudflareService or workers:

1. Update the templates: `cp -r packages/flutter_app_shell/templates/cloudflare/* .`
2. Review and merge any custom changes
3. Redeploy workers: `just deploy-cloudflare`  
4. Test all functionality thoroughly

For breaking changes, check the migration guide in the main documentation.