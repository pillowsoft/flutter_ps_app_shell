import 'dart:convert';
import 'package:crypto/crypto.dart';

Map<String, dynamic> verifyHs256Jwt({
  required String token,
  required String secret,
  String? issuer,
  String? audience,
}) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Invalid token');
  }

  String pad(String s) => s + '=' * ((4 - s.length % 4) % 4);

  final header = jsonDecode(utf8.decode(base64Url.decode(pad(parts[0]))));
  final payload = jsonDecode(utf8.decode(base64Url.decode(pad(parts[1]))));
  final sig = base64Url.decode(pad(parts[2]));

  final data = utf8.encode('${parts[0]}.${parts[1]}');
  final expected = Hmac(sha256, utf8.encode(secret)).convert(data).bytes;

  bool constTimeEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a[i] ^ b[i];
    }
    return r == 0;
  }

  if (!constTimeEq(sig, expected)) throw Exception('Bad signature');

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (payload['exp'] is int && now > payload['exp']) throw Exception('Expired');
  if (issuer != null && payload['iss'] != issuer) throw Exception('Bad iss');
  if (audience != null && payload['aud'] != audience)
    throw Exception('Bad aud');

  return Map<String, dynamic>.from(payload);
}
