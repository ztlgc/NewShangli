import 'package:newshangli/platform/app_update_platform.dart';
import 'package:newshangli/update/app_version.dart';
import 'package:newshangli/update/github_release.dart';

class FakeUpdatePlatform implements AppUpdatePlatform {
  AppVersion version = AppVersion.parse('1.2.5+2008');
  bool openResult = true;
  bool failVersion = false;
  Uri? opened;

  @override
  Future<AppVersion> installedVersion() async {
    if (failVersion) throw StateError('version unavailable');
    return version;
  }

  @override
  Future<bool> openRelease(Uri uri) async {
    opened = uri;
    return openResult;
  }
}

Map<String, dynamic> releaseJson([String tag = '1.2.5+2009']) => {
  'tag_name': tag,
  'html_url': 'https://github.com/ztlgc/NewShangli/releases/tag/$tag',
  'draft': false,
  'prerelease': false,
  'body': '修复问题，完善使用体验。',
  'assets': [
    {
      'name': 'Liji_${tag}_arm64.apk',
      'state': 'uploaded',
      'browser_download_url':
          'https://github.com/ztlgc/NewShangli/releases/download/$tag/Liji.apk',
    },
  ],
};

GitHubRelease releaseFixture([String tag = '1.2.5+2009']) =>
    GitHubRelease.fromJson(releaseJson(tag))!;
