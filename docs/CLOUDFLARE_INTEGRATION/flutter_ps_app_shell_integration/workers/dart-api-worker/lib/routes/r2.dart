import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import 'auth_guard.dart';
import '../util/r2_presign.dart';

Future<Response> handleR2Routes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);
  if (req.method == 'POST' && url.pathname == '/v1/r2/upload') {
    final ct =
        url.searchParams.get('contentType') ?? 'application/octet-stream';
    final key = url.searchParams.get('key') ??
        '${auth.userId}/${DateTime.now().millisecondsSinceEpoch}.bin';
    final put = await (env.R2 as dynamic).put(key, req.body, {
      'httpMetadata': {'contentType': ct},
      'customMetadata': {'userId': auth.userId}
    });
    return Response.json(
        {'key': key, 'etag': put['etag'], 'url': '${env.R2_PUBLIC_BASE}/$key'});
  }
  if (req.method == 'GET' && url.pathname == '/v1/r2/signed-put') {
    final key = url.searchParams.get('key') ??
        '${auth.userId}/${DateTime.now().millisecondsSinceEpoch}.bin';
    final acc = await getSecret('R2_ACCOUNT_ID');
    final ak = await getSecret('R2_ACCESS_KEY_ID');
    final sk = await getSecret('R2_SECRET_ACCESS_KEY');
    final bucket = await getSecret('R2_BUCKET');
    final p = presignR2PutUrl(
        accountId: acc,
        bucket: bucket,
        objectKey: key,
        accessKeyId: ak,
        secretAccessKey: sk);
    return Response.json({'url': p.url.toString(), 'key': key});
  }
  if (req.method == 'GET' && url.pathname == '/v1/r2/object') {
    final key = url.searchParams.get('key');
    if (key == null) return Response('Bad request', status: 400);
    final obj = await (env.R2 as dynamic).get(key);
    if (obj == null) return Response('Not Found', status: 404);
    final ct = (obj.httpMetadata?['contentType']) ?? 'application/octet-stream';
    return Response(obj.body, headers: {'content-type': ct});
  }
  if (req.method == 'DELETE' && url.pathname == '/v1/r2/object') {
    final key = url.searchParams.get('key');
    if (key == null) return Response('Bad request', status: 400);
    await (env.R2 as dynamic).delete(key);
    return Response.json({'ok': true});
  }
  return Response('Not found', status: 404);
}
