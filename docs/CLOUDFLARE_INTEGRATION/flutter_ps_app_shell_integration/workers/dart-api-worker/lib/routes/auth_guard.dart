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
  throw UnimplementedError('Provide secret ' + name);
}

Future<AuthContext> authenticate(Request req, Env env) async {
  final h = req.headers.get('Authorization');
  if (h == null || !h.startsWith('Bearer '))
    throw Response('Unauthorized', status: 401);
  final token = h.substring(7);
  final secret = await getSecret('SESSION_JWT_SECRET');
  final claims = verifyHs256Jwt(
      token: token,
      secret: secret,
      issuer: env.SESSION_JWT_ISSUER,
      audience: env.SESSION_JWT_AUDIENCE);
  final sub = claims['sub'] as String?;
  if (sub == null) throw Response('Unauthorized', status: 401);
  final roles = (claims['roles'] as List?)?.cast<String>() ?? const <String>[];
  return AuthContext(sub, claims['email'] as String?, roles);
}
