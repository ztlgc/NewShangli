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
    this._requestTimeout = const Duration(minutes: 5),
  }) : _connectTimeout = connectTimeout {
    _client.connectionTimeout = connectTimeout;
    _client.authenticate = (Uri url, String scheme, String? realm) async {
      if (scheme.toLowerCase() == 'basic') {
        _client.addCredentials(
          url,
          realm ?? '',
          HttpClientBasicCredentials(username, password),
        );
        return true;
      }
      if (scheme.toLowerCase() == 'digest') {
        _client.addCredentials(
          url,
          realm ?? '',
          HttpClientDigestCredentials(username, password),
        );
        return true;
      }
      return false;
    };
  }

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
    final rel = normalized.startsWith('/')
        ? normalized.substring(1)
        : normalized;
    final basePath = baseUrl.path.endsWith('/')
        ? baseUrl.path
        : '${baseUrl.path}/';
    final joined = p.posix.normalize(p.posix.join(basePath, rel));
    return baseUrl.replace(path: joined);
  }

  Future<WebDavTestResult> test() async {
    final uri = baseUrl;
    try {
      final propfindStatus = await _requestStatus(
        'PROPFIND',
        uri,
        headers: <String, String>{
          'Depth': '0',
          HttpHeaders.contentTypeHeader: 'application/xml; charset=utf-8',
        },
        body: utf8.encode(
          '<?xml version="1.0" encoding="utf-8"?><d:propfind xmlns:d="DAV:"><d:prop><d:displayname/></d:prop></d:propfind>',
        ),
      );
      if (propfindStatus == 401) {
        return const WebDavTestResult(ok: false, message: '鉴权失败，请检查用户名/密码');
      }
      if (propfindStatus == 403) {
        return const WebDavTestResult(ok: false, message: '账号已认证，但目录权限不足');
      }
      if (propfindStatus == 200 || propfindStatus == 207) {
        return const WebDavTestResult(ok: true, message: '连接成功');
      }
      if (propfindStatus == 301 ||
          propfindStatus == 302 ||
          propfindStatus == 307 ||
          propfindStatus == 308) {
        return const WebDavTestResult(
          ok: false,
          message:
              '连接失败：服务器发生重定向。\n请填写最终可直接访问的 WebDAV 地址（通常需要包含 /dav、/webdav 等后缀）。',
        );
      }
      if (propfindStatus == 405) {
        return const WebDavTestResult(
          ok: false,
          message: '连接失败：该地址不支持 WebDAV 操作 (HTTP 405)。\n请检查服务器地址是否正确（例如是否遗漏了 /dav、/webdav 等后缀）。',
        );
      }
      if (propfindStatus == 404) {
        return const WebDavTestResult(
          ok: false,
          message: '连接失败：路径不存在 (HTTP 404)。\n请检查服务器地址是否正确。',
        );
      }
      return WebDavTestResult(
        ok: false,
        message: '服务器响应异常：HTTP $propfindStatus',
      );
    } on SocketException catch (e) {
      return WebDavTestResult(ok: false, message: '网络错误：$e');
    } on TimeoutException {
      return const WebDavTestResult(ok: false, message: '请求超时，请检查地址或网络');
    } catch (e) {
      return WebDavTestResult(ok: false, message: '连接失败：$e');
    }
  }

  Future<void> ensureRemoteDir(String remoteDir) async {
    final dir = remoteDir.trim();
    if (dir.isEmpty) return;
    var normalized = dir;
    normalized = normalized.startsWith('/')
        ? normalized.substring(1)
        : normalized;
    normalized = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    if (normalized.isEmpty) return;

    final segments = normalized
        .split('/')
        .where((e) => e.trim().isNotEmpty)
        .toList();
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
    final deadline = _RequestDeadline(req, _requestTimeout);
    req.headers.set(HttpHeaders.contentTypeHeader, contentType);
    req.headers.contentLength = total;
    final input = StreamIterator(file.openRead());
    try {
      late int status;
      try {
        var sent = 0;
        while (await deadline.wait(input.moveNext())) {
          final chunk = input.current;
          req.add(chunk);
          await deadline.wait(req.flush());
          sent += chunk.length;
          onProgress(sent, total);
        }
        final resp = await deadline.wait(req.close());
        status = resp.statusCode;
        await _drainResponse(resp, deadline);
      } catch (_) {
        req.abort();
        rethrow;
      }
      await _handlePutStatus(status, uri, remotePath);
    } finally {
      try {
        await input.cancel();
      } catch (_) {
        // 输入句柄清理失败不能掩盖原始上传异常。
      }
    }
  }

  Future<void> _handlePutStatus(int status, Uri uri, String remotePath) async {
    if (status == 401) {
      throw const WebDavException('鉴权失败，请检查用户名/密码');
    }
    if (status == 403) {
      throw WebDavException('账号已认证，但无目录写入权限（$remotePath）');
    }
    if (status == 301 || status == 302 || status == 307 || status == 308) {
      throw const WebDavException('上传失败：服务器返回重定向。\n请改为最终可直接写入的 WebDAV 地址后重试。');
    }
    if (status == 405) {
      throw WebDavException(
        '上传失败：HTTP 405 (Method Not Allowed)。\n'
        '通常是 WebDAV 地址填写错误（例如填写了网页查看地址）。\n'
        '当前上传地址：${uri.toString()}',
      );
    }
    if (status < 200 || status >= 300) {
      throw WebDavException('上传失败：HTTP $status');
    }
  }

  Future<void> getFile({
    required String remotePath,
    required File outputFile,
    required void Function(int receivedBytes, int? totalBytes) onProgress,
  }) async {
    final uri = resolvePath(remotePath);
    final req = await _open('GET', uri, followRedirects: true);
    final deadline = _RequestDeadline(req, _requestTimeout);
    final partial = File(
      '${outputFile.path}.part_${DateTime.now().microsecondsSinceEpoch}',
    );
    StreamIterator<List<int>>? input;
    RandomAccessFile? output;
    try {
      final resp = await deadline.wait(req.close());
      input = StreamIterator(resp);
      final status = resp.statusCode;
      if (status == 401) {
        throw const WebDavException('鉴权失败，请检查用户名/密码');
      }
      if (status == 403) {
        throw WebDavException('账号已认证，但无目录读取权限（$remotePath）');
      }
      if (status == 404) {
        throw WebDavException('备份文件不存在（$remotePath）');
      }
      if (status < 200 || status >= 300) {
        throw WebDavException('下载失败：HTTP $status');
      }
      await outputFile.parent.create(recursive: true);
      output = await partial.open(mode: FileMode.write);
      var received = 0;
      final total = resp.contentLength >= 0 ? resp.contentLength : null;
      while (await deadline.wait(input.moveNext())) {
        // 等待每次文件写入完成，超时返回前关闭句柄，不留下后台写入。
        final chunk = input.current;
        await output.writeFrom(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      await output.flush();
      await output.close();
      output = null;
      await partial.rename(outputFile.path);
    } catch (_) {
      req.abort();
      rethrow;
    } finally {
      try {
        await input?.cancel();
      } catch (_) {}
      try {
        await output?.close();
      } catch (_) {}
      try {
        if (await partial.exists()) await partial.delete();
      } catch (_) {
        // 临时文件清理失败不能掩盖原始下载异常。
      }
    }
  }

  Future<HttpClientRequest> _open(
    String method,
    Uri uri, {
    bool followRedirects = false,
  }) async {
    var abandoned = false;
    final opening = _client.openUrl(method, uri);
    // openUrl 若晚于连接期限才完成，不能留下一个无人关闭的请求。
    opening.then<void>((request) {
      if (abandoned) {
        request.done.ignore();
        request.abort(const HttpException('连接已超时'));
      }
    }, onError: (Object error, StackTrace stack) {}).ignore();
    late HttpClientRequest req;
    try {
      req = await opening.timeout(_connectTimeout);
    } on TimeoutException {
      abandoned = true;
      rethrow;
    }
    req.headers.set(HttpHeaders.authorizationHeader, _authHeader);
    req.headers.set(HttpHeaders.userAgentHeader, 'newshangli-webdav');
    req.followRedirects = followRedirects;
    req.maxRedirects = followRedirects ? 3 : 0;
    return req;
  }

  Future<int> _requestStatus(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    List<int>? body,
  }) async {
    final req = await _open(method, uri);
    final deadline = _RequestDeadline(req, _requestTimeout);
    try {
      if (headers != null) {
        headers.forEach((key, value) => req.headers.set(key, value));
      }
      if (body != null && body.isNotEmpty) {
        req.headers.contentLength = body.length;
        req.add(body);
      }
      final resp = await deadline.wait(req.close());
      await _drainResponse(resp, deadline);
      return resp.statusCode;
    } catch (_) {
      req.abort();
      rethrow;
    }
  }

  Future<void> _drainResponse(
    HttpClientResponse response,
    _RequestDeadline deadline,
  ) async {
    final input = StreamIterator(response);
    try {
      while (await deadline.wait(input.moveNext())) {
        // 丢弃响应正文，但仍覆盖完整请求期限。
      }
    } finally {
      await input.cancel();
    }
  }

  Future<void> _mkcol(String relativeDir) async {
    final dirPath = relativeDir.endsWith('/') ? relativeDir : '$relativeDir/';
    final uri = resolvePath(dirPath);
    final status = await _requestStatus('MKCOL', uri);
    if (status == 201) return;
    if (status == 405) return;
    if (status == 301 || status == 302 || status == 307 || status == 308) {
      throw WebDavException('创建目录失败：服务器返回重定向（$relativeDir）');
    }
    if (status == 401) {
      throw const WebDavException('鉴权失败，请检查用户名/密码');
    }
    if (status == 403) {
      throw const WebDavException('账号已认证，但目录权限不足');
    }
    if (status == 409) {
      throw WebDavException('创建目录失败：上级目录不存在（$relativeDir）');
    }
    if (status >= 200 && status < 300) return;
    throw WebDavException('创建目录失败：HTTP $status（$relativeDir）');
  }
}

class _RequestDeadline {
  _RequestDeadline(this.request, this.limit) {
    request.done.ignore();
  }

  final HttpClientRequest request;
  final Duration limit;
  final Stopwatch elapsed = Stopwatch()..start();

  Future<T> wait<T>(Future<T> operation) {
    TimeoutException expire() {
      final error = TimeoutException('WebDAV 请求超时', limit);
      request.abort(error);
      return error;
    }

    final remaining = limit - elapsed.elapsed;
    if (remaining <= Duration.zero) {
      // operation 已启动；订阅其错误以便调用方 finally 取消后不产生游离异常。
      operation.ignore();
      return Future<T>.error(expire(), StackTrace.current);
    }
    return operation.timeout(remaining, onTimeout: () => throw expire());
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
