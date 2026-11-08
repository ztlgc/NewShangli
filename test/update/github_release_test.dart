import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/update/github_release.dart';

import '../support/update_fixtures.dart';

void main() {
  group('Release 解析', () {
    test('兼容旧标签及带构建号和 v 前缀的标签', () {
      for (final tag in ['1.2.5', '1.2.5+2009', 'v1.2.5+2009']) {
        final release = GitHubRelease.fromJson(releaseJson(tag))!;
        expect(release.version.label, tag.replaceFirst(RegExp(r'^v'), ''));
      }
    });

    test('草稿、预发布和未上传 APK 的发布不提示', () {
      expect(GitHubRelease.fromJson(releaseJson()..['draft'] = true), isNull);
      expect(
        GitHubRelease.fromJson(releaseJson()..['prerelease'] = true),
        isNull,
      );
      expect(GitHubRelease.fromJson(releaseJson()..['assets'] = []), isNull);
      final json = releaseJson();
      (json['assets'] as List).first['state'] = 'starter';
      expect(GitHubRelease.fromJson(json), isNull);
    });

    test('拒绝外部下载页面、不同标签和非 HTTPS 地址', () {
      for (final url in [
        'https://example.com/releases/tag/1.2.5+2009',
        'https://github.com/other/repo/releases/tag/1.2.5+2009',
        'https://github.com/ztlgc/NewShangli/releases/tag/1.2.5+2008',
        'http://github.com/ztlgc/NewShangli/releases/tag/1.2.5+2009',
        'https://github.com/ztlgc/NewShangli/releases/tag/1.2.5+2009?redirect=1',
      ]) {
        expect(
          () => GitHubRelease.fromJson(releaseJson()..['html_url'] = url),
          throwsFormatException,
        );
      }
    });

    test('编码后的 + 标签可以解析', () {
      final json = releaseJson()
        ..['html_url'] =
            'https://github.com/ztlgc/NewShangli/releases/tag/1.2.5%2B2009';
      expect(GitHubRelease.fromJson(json)!.version.label, '1.2.5+2009');
    });
  });

  group('GitHub HTTP 客户端', () {
    late HttpServer server;
    late Uri endpoint;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      endpoint = Uri.parse('http://127.0.0.1:${server.port}/latest');
    });
    tearDown(() async => server.close(force: true));

    test('请求版本接口并正确读取 JSON 和请求头', () async {
      server.listen((request) async {
        expect(
          request.headers.value(HttpHeaders.acceptHeader),
          'application/vnd.github+json',
        );
        expect(
          request.headers.value(HttpHeaders.userAgentHeader),
          'Liji-Update-Checker',
        );
        request.response.write(jsonEncode(releaseJson()));
        await request.response.close();
      });
      final release = await GitHubReleaseSource(endpoint: endpoint).latest();
      expect(release!.version.label, '1.2.5+2009');
    });

    test('无发布时返回空值', () async {
      server.listen((request) async {
        request.response.statusCode = 404;
        await request.response.close();
      });
      expect(await GitHubReleaseSource(endpoint: endpoint).latest(), isNull);
    });

    test('HTTP 403 限流不误报为最新版本', () async {
      server.listen((request) async {
        request.response.statusCode = 403;
        await request.response.close();
      });
      await expectLater(
        GitHubReleaseSource(endpoint: endpoint).latest(),
        throwsA(isA<HttpException>()),
      );
    });

    test('非 JSON 响应报告失败', () async {
      server.listen((request) async {
        request.response.write('<html>offline</html>');
        await request.response.close();
      });
      await expectLater(
        GitHubReleaseSource(endpoint: endpoint).latest(),
        throwsFormatException,
      );
    });

    test('限制响应大小', () async {
      server.listen((request) async {
        request.response.write('x' * (512 * 1024 + 1));
        await request.response.close();
      });
      await expectLater(
        GitHubReleaseSource(endpoint: endpoint).latest(),
        throwsFormatException,
      );
    });

    test('响应头到达后正文卡住也会超时', () async {
      server.listen((request) async {
        request.response.write('{');
        await request.response.flush();
        // Keep the body open until the client times out. No timer is needed.
      });
      await expectLater(
        GitHubReleaseSource(
          endpoint: endpoint,
          timeout: const Duration(milliseconds: 100),
        ).latest(),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
