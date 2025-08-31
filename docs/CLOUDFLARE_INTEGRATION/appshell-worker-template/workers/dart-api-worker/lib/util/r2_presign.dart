import 'dart:convert';
import 'package:crypto/crypto.dart';

class R2PresignResult {
  R2PresignResult({required this.url});
  final Uri url;
}

R2PresignResult presignR2PutUrl({
  required String accountId,
  required String bucket,
  required String objectKey,
  required String accessKeyId,
  required String secretAccessKey,
  String region = 'auto',
  int expiresInSeconds = 600,
  DateTime? now,
}) {
  now ??= DateTime.now().toUtc();
  String fmtAmzDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year.toString().padLeft(4, '0')}${two(dt.month)}${two(dt.day)}T${two(dt.hour)}${two(dt.minute)}${two(dt.second)}Z';
  }

  String fmtDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year.toString().padLeft(4, '0')}${two(dt.month)}${two(dt.day)}';
  }

  List<int> hmacSha256(List<int> key, List<int> data) =>
      Hmac(sha256, key).convert(data).bytes;

  String uriEncode(String s, {bool encodeSlash = true}) {
    final enc = Uri.encodeComponent(s)
        .replaceAll('%2F', encodeSlash ? '%2F' : '/')
        .replaceAll('+', '%20');
    return enc;
  }

  final amzDate = fmtAmzDate(now);
  final date = fmtDate(now);
  final service = 's3';
  final credentialScope = '$date/$region/$service/aws4_request';

  final host = '$accountId.r2.cloudflarestorage.com';
  final canonicalUri = '/$bucket/${uriEncode(objectKey, encodeSlash: false)}';

  final params = {
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Credential':
        Uri.encodeQueryComponent('$accessKeyId/$credentialScope'),
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': expiresInSeconds.toString(),
    'X-Amz-SignedHeaders': 'host',
  };
  final entries = params.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final canonicalQuery = entries.map((e) => '${e.key}=${e.value}').join('&');

  final canonicalHeaders = 'host:$host\n';
  const signedHeaders = 'host';
  const payloadHash = 'UNSIGNED-PAYLOAD';

  final canonicalRequest = [
    'PUT',
    canonicalUri,
    canonicalQuery,
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');

  final canonicalRequestHash =
      sha256.convert(utf8.encode(canonicalRequest)).toString();

  final stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    canonicalRequestHash,
  ].join('\n');

  final kDate =
      hmacSha256(utf8.encode('AWS4$secretAccessKey'), utf8.encode(date));
  final kRegion = hmacSha256(kDate, utf8.encode(region));
  final kService = hmacSha256(kRegion, utf8.encode(service));
  final kSigning = hmacSha256(kService, utf8.encode('aws4_request'));
  final signature =
      Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

  final fullQuery = '$canonicalQuery&X-Amz-Signature=$signature';
  Map<String, String> parseQuery(String q) {
    final parts = q.split('&');
    final m = <String, String>{};
    for (final p in parts) {
      final i = p.indexOf('=');
      final k = i == -1 ? p : p.substring(0, i);
      final v = i == -1 ? '' : p.substring(i + 1);
      m[k] = v;
    }
    return m;
  }

  final url = Uri.https(host, canonicalUri, parseQuery(fullQuery));
  return R2PresignResult(url: url);
}
