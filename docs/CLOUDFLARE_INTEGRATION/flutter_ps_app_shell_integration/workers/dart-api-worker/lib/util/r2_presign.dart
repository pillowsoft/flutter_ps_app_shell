import 'dart:convert'; import 'package:crypto/crypto.dart';
class R2PresignResult{R2PresignResult({required this.url});final Uri url;}
R2PresignResult presignR2PutUrl({required String accountId,required String bucket,required String objectKey,required String accessKeyId,required String secretAccessKey,String region='auto',int expiresInSeconds=600,DateTime? now,}){
  now??=DateTime.now().toUtc();String two(int n)=>n.toString().padLeft(2,'0');
  String d()=> '${now!.year.toString().padLeft(4,'0')}${two(now!.month)}${two(now!.day)}';
  String amz()=> '${d()}T${two(now!.hour)}${two(now!.minute)}${two(now!.second)}Z';
  List<int> h(List<int>k,List<int>d)=>Hmac(sha256,k).convert(d).bytes;
  String enc(String s,{bool slash=true})=>Uri.encodeComponent(s).replaceAll('%2F',slash?'%2F':'/').replaceAll('+','%20');
  final service='s3', host='$accountId.r2.cloudflarestorage.com', scope='${d()}/$region/$service/aws4_request';
  final uri='/$bucket/${enc(objectKey,slash=False)}'; final params={'X-Amz-Algorithm':'AWS4-HMAC-SHA256','X-Amz-Credential':Uri.encodeQueryComponent('$accessKeyId/$scope'),'X-Amz-Date':amz(),'X-Amz-Expires':'$expiresInSeconds','X-Amz-SignedHeaders':'host'};
  final q=({for(final e in (params.entries.toList()..sort((a,b)=>a.key.compareTo(b.key)))) e.key:e.value}).entries.map((e)=>'${e.key}=${e.value}').join('&');
  final canonical=['PUT',uri,q,'host:$host\n','host','UNSIGNED-PAYLOAD'].join('\n');
  final crHash=sha256.convert(utf8.encode(canonical)).toString();
  final toSign=['AWS4-HMAC-SHA256',amz(),scope,crHash].join('\n');
  final kDate=h(utf8.encode('AWS4$secretAccessKey'), utf8.encode(d())); final kRegion=h(kDate, utf8.encode(region));
  final kService=h(kRegion, utf8.encode(service)); final kSigning=h(kService, utf8.encode('aws4_request'));
  final sig=Hmac(sha256, kSigning).convert(utf8.encode(toSign)).toString();
  Map<String,String> parse(String s){final m=<String,String>{};for(final p in s.split('&')){final i=p.indexOf('=');m[i==-1?p:p[:i]]=i==-1?'':p[i+1:];}return m;}
  return R2PresignResult(url: Uri.https(host, uri, parse(q+'&X-Amz-Signature='+sig)));
}