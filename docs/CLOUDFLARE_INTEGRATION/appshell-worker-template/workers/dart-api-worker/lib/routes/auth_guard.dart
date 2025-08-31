import 'dart:convert';
import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import '../util/jwt.dart';

class AuthContext {
  AuthContext(this.userId, this.email, this.roles);
  final String userId;
  final String? email;
  final List<String> roles;
}

Future<String> getSecret(String name) async {
  // In a real setup, use environment bindings or KV. For demo, check KV first.
  // e.g., wrangler secret put SESSION_JWT_SECRET; you can retrieve via env on some toolchains.
  // Here we just simulate absence -> throw.
  throw UnimplementedError(
      'Provide secret $name via env or KV and implement getSecret.');
}

Future<AuthContext> authenticate(Request req, Env env) async {
  final header = req.headers.get('Authorization');
  if (header == null || !header.startsWith('Bearer ')) {
    throw Response('Unauthorized', status: 401);
  }
  final token = header.substring(7);

  final secret = await getSecret('SESSION_JWT_SECRET');
  final claims = verifyHs256Jwt(
    token: token,
    secret: secret,
    issuer: env.SESSION_JWT_ISSUER,
    audience: env.SESSION_JWT_AUDIENCE,
  );

  final sub = claims['sub'] as String?;
  if (sub == null) throw Response('Unauthorized', status: 401);

  final roles = (claims['roles'] as List?)?.cast<String>() ?? const <String>[];
  return AuthContext(sub, claims['email'] as String?, roles);
}
