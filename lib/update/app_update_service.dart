import 'package:shared_preferences/shared_preferences.dart';

import '../platform/app_update_platform.dart';
import 'app_version.dart';
import 'github_release.dart';

class UpdateCheckResult {
  const UpdateCheckResult({required this.current, this.release});

  final AppVersion current;
  final GitHubRelease? release;
}

class AppUpdateService {
  AppUpdateService({
    AppUpdatePlatform? platform,
    Future<GitHubRelease?> Function()? fetchLatest,
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? clock,
  }) : _platform = platform ?? const AndroidAppUpdatePlatform(),
       _fetchLatest = fetchLatest ?? GitHubReleaseSource().latest,
       _preferences = preferences ?? SharedPreferences.getInstance,
       _clock = clock ?? DateTime.now;

  final AppUpdatePlatform _platform;
  final Future<GitHubRelease?> Function() _fetchLatest;
  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _clock;

  static const lastAutomaticCheckKey = 'update.last_automatic_check';
  static const ignoredVersionKey = 'update.ignored_version';
  static const automaticInterval = Duration(hours: 24);

  AppVersion? _installed;
  Future<AppVersion>? _versionRequest;

  Future<AppVersion> installedVersion() async {
    if (_installed case final version?) return version;
    return _versionRequest ??= _readVersion();
  }

  Future<AppVersion> _readVersion() async {
    try {
      return _installed = await _platform.installedVersion();
    } finally {
      _versionRequest = null;
    }
  }

  /// A null result means the automatic check was throttled. Manual checks bypass
  /// both throttling and ignored versions, and do not depend on preferences.
  Future<UpdateCheckResult?> check({required bool manual}) async {
    final current = await installedVersion();
    SharedPreferences? prefs;
    if (!manual) {
      prefs = await _preferences();
      final now = _clock().millisecondsSinceEpoch;
      final previous = prefs.getInt(lastAutomaticCheckKey);
      if (previous != null) {
        final elapsed = now - previous;
        if (elapsed >= 0 && elapsed < automaticInterval.inMilliseconds) {
          return null;
        }
      }
      // Count attempts too, so offline launches and API rate limits never cause
      // repeated automatic requests. A manual retry is always available.
      if (!await prefs.setInt(lastAutomaticCheckKey, now)) {
        throw StateError('无法保存更新检查时间');
      }
    }
    final release = await _fetchLatest();
    if (release == null || release.version.compareTo(current) <= 0) {
      return UpdateCheckResult(current: current);
    }
    final ignored = prefs?.getString(ignoredVersionKey);
    if (!manual && ignored != null) {
      AppVersion? ignoredVersion;
      try {
        ignoredVersion = AppVersion.parse(ignored);
      } on FormatException {
        // A malformed old preference must not suppress future updates.
      }
      if (ignoredVersion?.compareTo(release.version) == 0) {
        return UpdateCheckResult(current: current);
      }
    }
    return UpdateCheckResult(current: current, release: release);
  }

  Future<void> ignore(GitHubRelease release) async {
    final prefs = await _preferences();
    if (!await prefs.setString(ignoredVersionKey, release.version.label)) {
      throw StateError('无法保存忽略的版本');
    }
  }

  Future<bool> openRelease(GitHubRelease release) {
    if (!GitHubRelease.isReleasePage(release.page)) {
      throw const FormatException('更新页面地址无效');
    }
    return _platform.openRelease(release.page);
  }
}
