import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WorkerDemoScreen extends StatefulWidget {
  const WorkerDemoScreen({
    super.key,
    required this.shimBaseUrl,
    required this.workerBaseUrl,
    required this.instantRefreshTokenProvider,
  });

  final String shimBaseUrl;
  final String workerBaseUrl;
  final Future<String> Function() instantRefreshTokenProvider;

  @override
  State<WorkerDemoScreen> createState() => _WorkerDemoScreenState();
}

class _WorkerDemoScreenState extends State<WorkerDemoScreen> {
  String? _sessionJwt;
  String _log = '';

  Future<void> _ensureSession() async {
    if (_sessionJwt != null) return;
    final refresh = await widget.instantRefreshTokenProvider();
    final res = await http.post(
      Uri.parse('${widget.shimBaseUrl}/auth/session'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'refresh_token': refresh}),
    );
    if (res.statusCode != 200) throw Exception('auth failed: ${res.body}');
    _sessionJwt = (jsonDecode(res.body) as Map)['token'] as String;
  }

  Future<void> _proxyUploadSmall() async {
    await _ensureSession();
    final bytes = Uint8List.fromList(
        List<int>.generate(256 * 1024, (i) => i % 256)); // 256KB
    final uri = Uri.parse(
        '${widget.workerBaseUrl}/v1/r2/upload?contentType=application/octet-stream');
    final res = await http.post(uri,
        headers: {
          'Authorization': 'Bearer $_sessionJwt',
          'content-type': 'application/octet-stream',
        },
        body: bytes);
    setState(() => _log = 'proxy upload: ${res.statusCode} ${res.body}');
  }

  Future<void> _presignedUploadLarge() async {
    await _ensureSession();
    final presign = await http.get(
      Uri.parse('${widget.workerBaseUrl}/v1/r2/signed-put'),
      headers: {'Authorization': 'Bearer $_sessionJwt'},
    );
    if (presign.statusCode != 200)
      throw Exception('presign failed: ${presign.body}');
    final j = jsonDecode(presign.body) as Map<String, dynamic>;
    final putUrl = j['url'] as String;
    final key = j['key'] as String;

    final big = Uint8List.fromList(
        List<int>.generate(2 * 1024 * 1024, (i) => (i * 31) % 256)); // 2MB
    final putRes = await http.put(Uri.parse(putUrl),
        headers: {'content-type': 'application/octet-stream'}, body: big);

    setState(() => _log =
        'presigned upload: ${putRes.statusCode}; key=$key; etag=${putRes.headers['etag']}');
  }

  Future<void> _aiText() async {
    await _ensureSession();
    final res = await http.post(
      Uri.parse('${widget.workerBaseUrl}/v1/ai/text-generate'),
      headers: {
        'Authorization': 'Bearer $_sessionJwt',
        'content-type': 'application/json'
      },
      body: jsonEncode({'prompt': 'Write a cheerful haiku about cameras.'}),
    );
    setState(() => _log = 'AI: ${res.statusCode}\n${res.body}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            ElevatedButton(
                onPressed: _proxyUploadSmall,
                child: const Text('Proxy Upload (small)')),
            ElevatedButton(
                onPressed: _presignedUploadLarge,
                child: const Text('Presigned Upload (large)')),
            ElevatedButton(
                onPressed: _aiText, child: const Text('AI: Text Generate')),
          ]),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(child: Text(_log))),
        ]),
      ),
    );
  }
}
