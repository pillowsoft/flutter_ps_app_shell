import 'package:cloudflare_workers/cloudflare_workers.dart';
import 'env.dart';
import 'routes/auth_guard.dart';
import 'routes/rate_limit.dart';
import 'routes/r2.dart';
import 'routes/ai.dart';
import 'routes/domain.dart';

Response _cors(Response r) => r.withHeaders({
      'access-control-allow-origin': '*',
      'access-control-allow-headers': 'authorization,content-type',
      'access-control-allow-methods': 'GET,POST,PUT,DELETE,OPTIONS'
    });

@CloudflareWorker()
Future<Response> fetch(Request req, Env env, Context ctx) async {
  final url = URL(req.url);
  if (req.method == 'OPTIONS') return _cors(Response('', status: 204));
  if (url.pathname == '/health') return _cors(Response('ok'));
  final auth = await authenticate(req, env);
  final rl = RateLimiterClient(env);
  await rl.consume(auth.userId);
  if (url.pathname.startsWith('/v1/r2'))
    return _cors(await handleR2Routes(req, env, auth));
  if (url.pathname.startsWith('/v1/ai'))
    return _cors(await handleAIRoutes(req, env, auth));
  if (url.pathname.startsWith('/v1/projects'))
    return _cors(await handleDomainRoutes(req, env, auth));
  return _cors(Response('Not found', status: 404));
}
