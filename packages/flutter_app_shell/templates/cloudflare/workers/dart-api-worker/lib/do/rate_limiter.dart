import 'package:cloudflare_workers/cloudflare_workers.dart';

@DurableObject()
class RateLimiterDO {
  RateLimiterDO(State this.state);
  final State state;

  static const int maxPerMinute = 100;

  Future<Response> fetch(Request req) async {
    final url = URL(req.url);
    final userId = url.searchParams.get('u');
    if (userId == null) return Response('Bad request', status: 400);

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final window = now ~/ 60000;
    final key = '$userId:$window';
    final current = (await state.storage.get<int>(key)) ?? 0;
    if (current >= maxPerMinute) {
      return Response('Too Many Requests', status: 429);
    }
    await state.storage
        .put<int>(key, current + 1, expiration: Duration(seconds: 70));
    return Response('ok');
  }
}
