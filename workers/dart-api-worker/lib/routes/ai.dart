import 'dart:convert';
import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import 'auth_guard.dart';

Future<Response> handleAIRoutes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);

  // Text generation with AI Gateway support
  if (req.method == 'POST' && url.pathname == '/v1/ai/text-generate') {
    final body = await req.json() as Map<String, dynamic>;
    final provider = (body['provider'] as String?) ?? 'workers-ai';
    final model =
        (body['model'] as String?) ?? '@cf/meta/llama-3.1-8b-instruct';
    final prompt = body['prompt'] as String? ?? '';
    final maxTokens = (body['max_tokens'] as int?) ?? 512;
    final temperature = (body['temperature'] as double?) ?? 0.7;
    final enableCache = (body['cache'] as bool?) ?? true;

    try {
      // Check if AI Gateway is configured
      final gatewayId = await getSecretOptional('AI_GATEWAY_ID');
      if (gatewayId != null && gatewayId.isNotEmpty) {
        return await _generateTextViaGateway(env, gatewayId, provider, model,
            prompt, maxTokens, temperature, enableCache);
      } else {
        // Fallback to direct Workers AI API
        return await _generateTextDirect(env, model, prompt);
      }
    } catch (e) {
      console.error('AI text generation error: $e');
      return Response(
          jsonEncode(
              {'error': 'AI generation failed', 'details': e.toString()}),
          status: 500,
          headers: {'content-type': 'application/json'});
    }
  }

  // Image generation with AI Gateway support
  if (req.method == 'POST' && url.pathname == '/v1/ai/image-generate') {
    final body = await req.json() as Map<String, dynamic>;
    final provider = (body['provider'] as String?) ?? 'workers-ai';
    final model = (body['model'] as String?) ??
        '@cf/stabilityai/stable-diffusion-xl-base-1.0';
    final prompt = body['prompt'] as String? ?? '';
    final enableCache = (body['cache'] as bool?) ?? true;

    try {
      final gatewayId = await getSecretOptional('AI_GATEWAY_ID');
      if (gatewayId != null && gatewayId.isNotEmpty) {
        return await _generateImageViaGateway(
            env, gatewayId, provider, model, prompt, enableCache);
      } else {
        // Fallback to direct Workers AI API
        return await _generateImageDirect(env, model, prompt);
      }
    } catch (e) {
      console.error('AI image generation error: $e');
      return Response(
          jsonEncode(
              {'error': 'AI image generation failed', 'details': e.toString()}),
          status: 500,
          headers: {'content-type': 'application/json'});
    }
  }

  // Get available AI providers and models
  if (req.method == 'GET' && url.pathname == '/v1/ai/providers') {
    return Response(jsonEncode(_getAvailableProviders()),
        headers: {'content-type': 'application/json'});
  }

  return Response('Not found', status: 404);
}

// Generate text via AI Gateway
Future<Response> _generateTextViaGateway(
  Env env,
  String gatewayId,
  String provider,
  String model,
  String prompt,
  int maxTokens,
  double temperature,
  bool enableCache,
) async {
  final accountId = env.CF_ACCOUNT_ID;
  final gatewayUrl =
      'https://gateway.ai.cloudflare.com/v1/$accountId/$gatewayId/$provider';

  // Build request based on provider format
  Map<String, dynamic> requestBody;
  Map<String, String> headers = {
    'content-type': 'application/json',
  };

  switch (provider) {
    case 'openai':
      final apiKey = await getSecretOptional('OPENAI_API_KEY');
      if (apiKey != null) headers['Authorization'] = 'Bearer $apiKey';

      requestBody = {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
      };
      break;

    case 'anthropic':
      final apiKey = await getSecretOptional('ANTHROPIC_API_KEY');
      if (apiKey != null) {
        headers['x-api-key'] = apiKey;
        headers['anthropic-version'] = '2023-06-01';
      }

      requestBody = {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
      };
      break;

    default: // workers-ai
      requestBody = {
        'prompt': prompt,
        'max_tokens': maxTokens,
        'temperature': temperature,
      };
  }

  // Add cache headers if enabled
  if (enableCache) {
    headers['cf-aig-cache-ttl'] = '3600'; // Cache for 1 hour
  }

  final res = await fetch(
      '$gatewayUrl${_getProviderEndpoint(provider)}',
      RequestInit(
        method: 'POST',
        headers: headers,
        body: jsonEncode(requestBody),
      ));

  final responseText = await res.text();

  // Normalize response format across providers
  final normalizedResponse = _normalizeTextResponse(provider, responseText);

  return Response(jsonEncode(normalizedResponse),
      status: res.status, headers: {'content-type': 'application/json'});
}

// Generate image via AI Gateway
Future<Response> _generateImageViaGateway(
  Env env,
  String gatewayId,
  String provider,
  String model,
  String prompt,
  bool enableCache,
) async {
  final accountId = env.CF_ACCOUNT_ID;
  final gatewayUrl =
      'https://gateway.ai.cloudflare.com/v1/$accountId/$gatewayId/$provider';

  Map<String, dynamic> requestBody;
  Map<String, String> headers = {'content-type': 'application/json'};

  switch (provider) {
    case 'openai':
      final apiKey = await getSecretOptional('OPENAI_API_KEY');
      if (apiKey != null) headers['Authorization'] = 'Bearer $apiKey';

      requestBody = {
        'model': model,
        'prompt': prompt,
        'n': 1,
        'size': '1024x1024',
      };
      break;

    default: // workers-ai
      requestBody = {'prompt': prompt};
  }

  if (enableCache) {
    headers['cf-aig-cache-ttl'] = '86400'; // Cache images for 24 hours
  }

  final res = await fetch(
      '$gatewayUrl${_getImageEndpoint(provider)}',
      RequestInit(
        method: 'POST',
        headers: headers,
        body: jsonEncode(requestBody),
      ));

  final responseText = await res.text();
  final normalizedResponse = _normalizeImageResponse(provider, responseText);

  return Response(jsonEncode(normalizedResponse),
      status: res.status, headers: {'content-type': 'application/json'});
}

// Fallback to direct Workers AI API
Future<Response> _generateTextDirect(
    Env env, String model, String prompt) async {
  final token = await getSecret('CF_API_TOKEN');
  final accountId = env.CF_ACCOUNT_ID;

  final aiUrl =
      'https://api.cloudflare.com/client/v4/accounts/$accountId/ai/run/$model';
  final res = await fetch(
      aiUrl,
      RequestInit(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
            'content-type': 'application/json'
          },
          body: jsonEncode({'prompt': prompt})));

  final txt = await res.text();
  return Response(txt,
      status: res.status, headers: {'content-type': 'application/json'});
}

// Fallback to direct Workers AI API for images
Future<Response> _generateImageDirect(
    Env env, String model, String prompt) async {
  final token = await getSecret('CF_API_TOKEN');
  final accountId = env.CF_ACCOUNT_ID;

  final aiUrl =
      'https://api.cloudflare.com/client/v4/accounts/$accountId/ai/run/$model';
  final res = await fetch(
      aiUrl,
      RequestInit(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
            'content-type': 'application/json'
          },
          body: jsonEncode({'prompt': prompt})));

  final txt = await res.text();
  return Response(txt,
      status: res.status, headers: {'content-type': 'application/json'});
}

// Get provider-specific endpoint
String _getProviderEndpoint(String provider) {
  switch (provider) {
    case 'openai':
      return '/chat/completions';
    case 'anthropic':
      return '/messages';
    default: // workers-ai
      return '';
  }
}

// Get provider-specific image endpoint
String _getImageEndpoint(String provider) {
  switch (provider) {
    case 'openai':
      return '/images/generations';
    default: // workers-ai
      return '';
  }
}

// Normalize text response across providers
Map<String, dynamic> _normalizeTextResponse(
    String provider, String responseText) {
  try {
    final response = jsonDecode(responseText) as Map<String, dynamic>;

    switch (provider) {
      case 'openai':
        final choices = response['choices'] as List?;
        if (choices?.isNotEmpty == true) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          return {
            'response': message?['content'] ?? '',
            'usage': response['usage'],
            'provider': provider,
          };
        }
        break;

      case 'anthropic':
        final content = response['content'] as List?;
        if (content?.isNotEmpty == true) {
          return {
            'response': content[0]['text'] ?? '',
            'usage': response['usage'],
            'provider': provider,
          };
        }
        break;

      default: // workers-ai
        return {
          'response': response['result'] ?? response['response'] ?? '',
          'provider': provider,
        };
    }
  } catch (e) {
    console.error('Failed to parse response: $e');
  }

  return {'response': responseText, 'provider': provider};
}

// Normalize image response across providers
Map<String, dynamic> _normalizeImageResponse(
    String provider, String responseText) {
  try {
    final response = jsonDecode(responseText) as Map<String, dynamic>;

    switch (provider) {
      case 'openai':
        final data = response['data'] as List?;
        if (data?.isNotEmpty == true) {
          return {
            'result': data[0]['b64_json'] ?? data[0]['url'],
            'provider': provider,
          };
        }
        break;

      default: // workers-ai
        return {
          'result': response['result'],
          'provider': provider,
        };
    }
  } catch (e) {
    console.error('Failed to parse image response: $e');
  }

  return {'result': responseText, 'provider': provider};
}

// Get available providers and their models
Map<String, dynamic> _getAvailableProviders() {
  return {
    'providers': [
      {
        'id': 'workers-ai',
        'name': 'Cloudflare Workers AI',
        'textModels': [
          '@cf/meta/llama-3.1-8b-instruct',
          '@cf/microsoft/phi-2',
          '@cf/qwen/qwen1.5-14b-chat-awq',
        ],
        'imageModels': [
          '@cf/stabilityai/stable-diffusion-xl-base-1.0',
          '@cf/lykon/dreamshaper-8-lcm',
        ],
      },
      {
        'id': 'openai',
        'name': 'OpenAI',
        'textModels': [
          'gpt-4o',
          'gpt-4o-mini',
          'gpt-3.5-turbo',
        ],
        'imageModels': [
          'dall-e-3',
          'dall-e-2',
        ],
        'requiresKey': true,
      },
      {
        'id': 'anthropic',
        'name': 'Anthropic',
        'textModels': [
          'claude-3-5-sonnet-20241022',
          'claude-3-opus-20240229',
          'claude-3-haiku-20240307',
        ],
        'requiresKey': true,
      },
    ],
  };
}

// Helper to get optional secret (returns null if not found)
Future<String?> getSecretOptional(String key) async {
  try {
    return await getSecret(key);
  } catch (e) {
    return null;
  }
}
