import 'package:cloudflare_workers/cloudflare_workers.dart';
import '../env.dart';
import 'auth_guard.dart';

Future<Response> handleDomainRoutes(
    Request req, Env env, AuthContext auth) async {
  return Response.json({'projects': []});
}
