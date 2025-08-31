import 'dart:convert';
import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import 'auth_guard.dart';

Future<Response> handleAIRoutes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);

  // Text generation example via Workers AI HTTPS API
  if (req.method == 'POST' && url.pathname == '/v1/ai/text-generate') {
    final body = await req.json() as Map<String, dynamic>;
    final model =
        (body['model'] as String?) ?? '@cf/meta/llama-3.1-8b-instruct';
    final prompt = body['prompt'] as String? ?? '';

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

  return Response('Not found', status: 404);
}
