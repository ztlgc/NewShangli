import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_version.dart';

class GitHubRelease {
  const GitHubRelease({
    required this.version,
    required this.notes,
    required this.page,
  });

  final AppVersion version;
  final String notes;
  final Uri page;

  static bool isReleasePage(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == 'github.com' &&
      !uri.hasPort &&
      uri.userInfo.isEmpty &&
      uri.path.startsWith('/ztlgc/NewShangli/releases/tag/') &&
      uri.pathSegments.length == 5 &&
      !uri.hasQuery &&
      !uri.hasFragment;

  static GitHubRelease? fromJson(Map<String, dynamic> json) {
    if (json['draft'] == true || json['prerelease'] == true) return null;
    final tag = json['tag_name'];
    final pageValue = json['html_url'];
    if (tag is! String || pageValue is! String) {
      throw const FormatException('更新信息缺少版本号或下载页面');
    }
    final version = AppVersion.parse(tag);
    final page = Uri.parse(pageValue);
    if (!isReleasePage(page) || page.pathSegments.last != tag) {
      throw const FormatException('更新页面地址无效');
    }
    // Do not advertise a release before its installable APK has been uploaded.
    final assets = json['assets'];
    if (assets is! List ||
        !assets.any((asset) {
          if (asset is! Map) return false;
          final name = asset['name'];
          final download = asset['browser_download_url'];
          if (name is! String || download is! String) return false;
          final uri = Uri.tryParse(download);
          return name.toLowerCase().endsWith('.apk') &&
              (asset['state'] == null || asset['state'] == 'uploaded') &&
              uri != null &&
              uri.scheme == 'https' &&
              uri.host == 'github.com' &&
              uri.userInfo.isEmpty &&
              uri.path.startsWith('/ztlgc/NewShangli/releases/download/');
        })) {
      return null;
    }
    final notes = json['body'];
    return GitHubRelease(
      version: version,
      notes: notes is String ? notes.trim() : '',
      page: page,
    );
  }
}

class GitHubReleaseSource {
  GitHubReleaseSource({
    Uri? endpoint,
    this.timeout = const Duration(seconds: 15),
  }) : endpoint =
           endpoint ??
           Uri.https(
             'api.github.com',
             '/repos/ztlgc/NewShangli/releases/latest',
           );

  final Uri endpoint;
  final Duration timeout;
  static const _maximumResponseBytes = 512 * 1024;

  Future<GitHubRelease?> latest() async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      // This covers both response headers and the complete response body.
      return await _read(client).timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }

  Future<GitHubRelease?> _read(HttpClient client) async {
    final request = await client.getUrl(endpoint);
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    request.headers.set(HttpHeaders.userAgentHeader, 'Liji-Update-Checker');
    request.headers.set('X-GitHub-Api-Version', '2022-11-28');
    final response = await request.close();
    if (response.statusCode == HttpStatus.notFound) return null;
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('检查更新失败（HTTP ${response.statusCode}）');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > _maximumResponseBytes) {
        throw const FormatException('更新信息过大');
      }
      bytes.addAll(chunk);
    }
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('更新信息格式无效');
    }
    return GitHubRelease.fromJson(json);
  }
}
