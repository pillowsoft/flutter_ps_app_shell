import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';

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
