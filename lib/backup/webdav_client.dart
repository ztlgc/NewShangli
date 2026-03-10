import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class WebDavClient {
  WebDavClient({
    required this.baseUrl,
    required this.username,
    required this.password,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration requestTimeout = const Duration(minutes: 5),
  })  : _connectTimeout = connectTimeout,
        _requestTimeout = requestTimeout;

  final Uri baseUrl;
  final String username;
  final String password;
  final Duration _connectTimeout;
  final Duration _requestTimeout;

  Future<void> close() async {
    _client.close(force: true);
  }

  final HttpClient _client = HttpClient();

  String get _authHeader {
    final raw = utf8.encode('$username:$password');
    return 'Basic ${base64Encode(raw)}';
  }

  Uri resolvePath(String relativePath) {
    final normalized = relativePath.trim();
    final rel = normalized.startsWith('/') ? normalized.substring(1) : normalized;
    final basePath = baseUrl.path.endsWith('/') ? baseUrl.path : '${baseUrl.path}/';
    final joined = p.posix.normalize(p.posix.join(basePath, rel));
    return baseUrl.replace(path: joined);
  }

  Future<WebDavTestResult> test() async {
    final uri = baseUrl;
    HttpClientResponse? resp;
    try {
      final req = await _open('OPTIONS', uri);
      resp = await req.close().timeout(_requestTimeout);
      final status = resp.statusCode;
      if (status == 401 || status == 403) {
        return const WebDavTestResult(ok: false, message: '鉴权失败，请检查用户名/密码');
      }
      if (status >= 200 && status < 300) {
        return const WebDavTestResult(ok: true, message: '连接成功');
      }
      return WebDavTestResult(ok: false, message: '服务器响应异常：HTTP $status');
    } on SocketException catch (e) {
      return WebDavTestResult(ok: false, message: '网络错误：$e');
    } on TimeoutException {
      return const WebDavTestResult(ok: false, message: '请求超时，请检查地址或网络');
    } catch (e) {
      return WebDavTestResult(ok: false, message: '连接失败：$e');
    } finally {
      try {
        await resp?.drain<void>();
      } catch (_) {}
    }
  }

  Future<void> ensureRemoteDir(String remoteDir) async {
    final dir = remoteDir.trim();
    if (dir.isEmpty) return;
    var normalized = dir;
    normalized = normalized.startsWith('/') ? normalized.substring(1) : normalized;
    normalized = normalized.endsWith('/') ? normalized.substring(0, normalized.length - 1) : normalized;
    if (normalized.isEmpty) return;

    final segments = normalized.split('/').where((e) => e.trim().isNotEmpty).toList();
    var current = '';
    for (final seg in segments) {
      current = current.isEmpty ? seg : '$current/$seg';
      await _mkcol(current);
    }
  }

  Future<void> putFile({
    required String remotePath,
    required File file,
    required void Function(int sentBytes, int totalBytes) onProgress,
    String contentType = 'application/octet-stream',
  }) async {
    final total = await file.length();
    final uri = resolvePath(remotePath);

    final req = await _open('PUT', uri);
    req.headers.set(HttpHeaders.contentTypeHeader, contentType);
    req.headers.contentLength = total;

    var sent = 0;
    await for (final chunk in file.openRead()) {
      req.add(chunk);
      sent += chunk.length;
      onProgress(sent, total);
    }

    final resp = await req.close().timeout(_requestTimeout);
    await resp.drain<void>();
    final status = resp.statusCode;
    if (status == 401 || status == 403) {
      throw const WebDavException('鉴权失败，请检查用户名/密码');
    }
    if (status < 200 || status >= 300) {
      throw WebDavException('上传失败：HTTP $status');
    }
  }

  Future<HttpClientRequest> _open(String method, Uri uri) async {
    final req = await _client.openUrl(method, uri).timeout(_connectTimeout);
    req.headers.set(HttpHeaders.authorizationHeader, _authHeader);
    req.headers.set(HttpHeaders.userAgentHeader, 'newshangli-webdav');
    req.followRedirects = true;
    req.maxRedirects = 3;
    return req;
  }

  Future<void> _mkcol(String relativeDir) async {
    final dirPath = relativeDir.endsWith('/') ? relativeDir : '$relativeDir/';
    final uri = resolvePath(dirPath);
    final req = await _open('MKCOL', uri);
    final resp = await req.close().timeout(_requestTimeout);
    await resp.drain<void>();
    final status = resp.statusCode;
    if (status == 201) return;
    if (status == 405) return;
    if (status == 301 || status == 302 || status == 307 || status == 308) return;
    if (status == 401 || status == 403) {
      throw const WebDavException('鉴权失败，请检查用户名/密码');
    }
    if (status == 409) {
      throw WebDavException('创建目录失败：上级目录不存在（$relativeDir）');
    }
    if (status >= 200 && status < 300) return;
    throw WebDavException('创建目录失败：HTTP $status（$relativeDir）');
  }
}

class WebDavTestResult {
  const WebDavTestResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

class WebDavException implements Exception {
  const WebDavException(this.message);

  final String message;

  @override
  String toString() => message;
}

