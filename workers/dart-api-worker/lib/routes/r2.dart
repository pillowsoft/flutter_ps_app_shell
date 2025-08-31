import 'dart:convert';
import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import 'auth_guard.dart';
import '../util/r2_presign.dart';

Future<Response> handleR2Routes(Request req, Env env, AuthContext auth) async {
  final url = URL(req.url);

  // Proxy upload (small/medium files)
  if (req.method == 'POST' && url.pathname == '/v1/r2/upload') {
    final contentType =
        url.searchParams.get('contentType') ?? 'application/octet-stream';
    final key = url.searchParams.get('key') ??
        '${auth.userId}/${DateTime.now().millisecondsSinceEpoch}.bin';

    final putRes = await (env.R2 as dynamic).put(key, req.body, {
      'httpMetadata': {'contentType': contentType},
      'customMetadata': {'userId': auth.userId}
    });

    final publicUrl = '${env.R2_PUBLIC_BASE}/$key';
    return Response.json(
        {'key': key, 'etag': putRes['etag'], 'url': publicUrl});
  }

  // Presigned PUT for large files
  if (req.method == 'GET' && url.pathname == '/v1/r2/signed-put') {
    final key = url.searchParams.get('key') ??
        '${auth.userId}/${DateTime.now().millisecondsSinceEpoch}.bin';

    // TODO: implement getSecret to fetch actual secrets
    final accountId = await getSecret('R2_ACCOUNT_ID');
    final accessKey = await getSecret('R2_ACCESS_KEY_ID');
    final secretKey = await getSecret('R2_SECRET_ACCESS_KEY');
    final bucket = await getSecret('R2_BUCKET');

    final presigned = presignR2PutUrl(
      accountId: accountId,
      bucket: bucket,
      objectKey: key,
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
      region: 'auto',
      expiresInSeconds: 600,
    );
    return Response.json({'url': presigned.url.toString(), 'key': key});
  }

  // GET object
  if (req.method == 'GET' && url.pathname == '/v1/r2/object') {
    final key = url.searchParams.get('key');
    if (key == null) return Response('Bad request', status: 400);
    final obj = await (env.R2 as dynamic).get(key);
    if (obj == null) return Response('Not Found', status: 404);
    final ct = (obj.httpMetadata?['contentType']) ?? 'application/octet-stream';
    return Response(obj.body, headers: {'content-type': ct});
  }

  // DELETE object
  if (req.method == 'DELETE' && url.pathname == '/v1/r2/object') {
    final key = url.searchParams.get('key');
    if (key == null) return Response('Bad request', status: 400);
    await (env.R2 as dynamic).delete(key);
    return Response.json({'ok': true});
  }

  return Response('Not found', status: 404);
}
