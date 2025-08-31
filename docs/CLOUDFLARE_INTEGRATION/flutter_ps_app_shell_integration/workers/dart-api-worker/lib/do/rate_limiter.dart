import 'package:cloudflare_workers/cloudflare_workers.dart';

@DurableObject()
class RateLimiterDO {
  RateLimiterDO(State this.state);
  final State state;
  static const int maxPerMinute = 100;
  Future<Response> fetch(Request req) async {
    final url = URL(req.url);
    final u = url.searchParams.get('u');
    if (u == null) return Response('Bad request', status: 400);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final win = now ~/ 60000;
    final key = '$u:$win';
    final cur = (await state.storage.get<int>(key)) ?? 0;
    if (cur >= maxPerMinute) return Response('Too Many Requests', status: 429);
    await state.storage
        .put<int>(key, cur + 1, expiration: Duration(seconds: 70));
    return Response('ok');
  }
}
