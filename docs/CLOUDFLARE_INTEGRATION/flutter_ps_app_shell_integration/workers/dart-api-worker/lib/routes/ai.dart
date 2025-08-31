import 'dart:convert';
import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import 'auth_guard.dart';

Future<Response> handleAIRoutes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);
  if (req.method == 'POST' && url.pathname == '/v1/ai/text-generate') {
    final body = await req.json() as Map<String, dynamic>;
    final model =
        (body['model'] as String?) ?? '@cf/meta/llama-3.1-8b-instruct';
    final prompt = body['prompt'] as String? ?? '';
    final token = await getSecret('CF_API_TOKEN');
    final acct = env.CF_ACCOUNT_ID;
    final res = await fetch(
        'https://api.cloudflare.com/client/v4/accounts/$acct/ai/run/$model',
        RequestInit(
            method: 'POST',
            headers: {
              'Authorization': 'Bearer $token',
              'content-type': 'application/json'
            },
            body: jsonEncode({'prompt': prompt})));
    return Response(await res.text(),
        status: res.status, headers: {'content-type': 'application/json'});
  }
  return Response('Not found', status: 404);
}
