import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/platform/app_update_platform.dart';
import 'package:newshangli/update/app_update_service.dart';
import 'package:newshangli/update/app_version.dart';
import 'package:newshangli/update/github_release.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/update_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('完整版本号', () {
    for (final (older, newer) in [
      ('1.2.5+2008', '1.2.5+2009'),
      ('1.2.5+9', '1.2.5+10'),
      ('1.9.0+2010', '1.10.0+2011'),
      ('1.2.5+2010', '1.2.6+2011'),
      ('1.2.5', '1.2.5+2008'),
    ]) {
      test('$newer 比 $older 新', () {
        expect(AppVersion.parse(newer).compareTo(AppVersion.parse(older)), 1);
        expect(AppVersion.parse(older).compareTo(AppVersion.parse(newer)), -1);
      });
    }

    test('标签前缀规范化，构建号参与相等比较', () {
      final version = AppVersion.parse('v1.2.5+2008');
      expect(version.label, '1.2.5+2008');
      expect(version.compareTo(AppVersion.parse('1.2.5+2008')), 0);
    });

    test('拒绝预发布标签、非数字构建号和不完整版本号', () {
      for (final value in ['1.2', '1.2.5-beta+2009', '1.2.5+abc', '1.2.5+']) {
        expect(() => AppVersion.parse(value), throwsFormatException);
      }
    });

    test('平台返回原始构建号，不使用带 ABI 偏移的 Android versionCode', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AndroidAppUpdatePlatform.channel, (
            call,
          ) async {
            expect(call.method, 'installedVersion');
            return {'version': '1.2.5', 'build': '2008'};
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(AndroidAppUpdatePlatform.channel, null);
      });
      final version = await const AndroidAppUpdatePlatform().installedVersion();
      expect(version.label, '1.2.5+2008');
      expect(version.build, 2008);
    });
  });

  group('更新服务', () {
    late FakeUpdatePlatform platform;
    late DateTime now;
    late int requests;
    GitHubRelease? release;
    late AppUpdateService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      platform = FakeUpdatePlatform();
      now = DateTime(2026, 11, 8, 10);
      requests = 0;
      release = releaseFixture();
      service = AppUpdateService(
        platform: platform,
        fetchLatest: () async {
          requests++;
          return release;
        },
        clock: () => now,
      );
    });

    test('同一主版本构建号增加也提示更新', () async {
      final result = await service.check(manual: true);
      expect(result!.current.label, '1.2.5+2008');
      expect(result.release!.version.label, '1.2.5+2009');
    });

    test('兼容旧标签，同版本、旧构建和旧主版本不提示更新', () async {
      for (final tag in ['1.2.5', '1.2.5+2008', '1.2.5+2007', '1.2.4+3000']) {
        release = releaseFixture(tag);
        expect((await service.check(manual: true))!.release, isNull);
      }
    });

    test('24 小时内跨服务实例限流，手动检查绕过限制', () async {
      expect((await service.check(manual: false))!.release, isNotNull);
      final next = AppUpdateService(
        platform: platform,
        fetchLatest: () async {
          requests++;
          return release;
        },
        clock: () => now,
      );
      expect(await next.check(manual: false), isNull);
      expect(requests, 1);
      expect((await next.check(manual: true))!.release, isNotNull);
      expect(requests, 2);
      now = now.add(const Duration(hours: 24));
      expect((await next.check(manual: false))!.release, isNotNull);
      expect(requests, 3);
    });

    test('忽略只影响该版本的自动提醒，手动检查和后续版本仍可用', () async {
      await service.ignore(release!);
      expect((await service.check(manual: false))!.release, isNull);
      expect((await service.check(manual: true))!.release, isNotNull);
      release = releaseFixture('1.2.5+2010');
      now = now.add(const Duration(hours: 24));
      expect(
        (await service.check(manual: false))!.release!.version.label,
        '1.2.5+2010',
      );
    });

    test('忽略标签的 v 前缀不影响匹配', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppUpdateService.ignoredVersionKey, 'v1.2.5+2009');
      expect((await service.check(manual: false))!.release, isNull);
    });

    test('系统时钟回退后仍可检查，损坏的忽略值不会屏蔽更新', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        AppUpdateService.lastAutomaticCheckKey,
        now.add(const Duration(days: 2)).millisecondsSinceEpoch,
      );
      await prefs.setString(AppUpdateService.ignoredVersionKey, 'broken');
      expect((await service.check(manual: false))!.release, isNotNull);
    });

    test('自动网络失败计入限流，仍可立即手动重试', () async {
      var fail = true;
      final retrying = AppUpdateService(
        platform: platform,
        fetchLatest: () async {
          requests++;
          if (fail) throw TimeoutException('offline');
          return release;
        },
        clock: () => now,
      );
      await expectLater(
        retrying.check(manual: false),
        throwsA(isA<TimeoutException>()),
      );
      expect(await retrying.check(manual: false), isNull);
      fail = false;
      expect((await retrying.check(manual: true))!.release, isNotNull);
      expect(requests, 2);
    });

    test('手动检查不依赖偏好设置，版本读取失败后可重试', () async {
      final independent = AppUpdateService(
        platform: platform,
        preferences: () async => throw StateError('preferences unavailable'),
        fetchLatest: () async => release,
      );
      platform.failVersion = true;
      await expectLater(independent.check(manual: true), throwsStateError);
      platform.failVersion = false;
      expect((await independent.check(manual: true))!.release, isNotNull);
    });

    test('只打开当前仓库的 Release 页面', () async {
      expect(await service.openRelease(release!), isTrue);
      expect(platform.opened, release!.page);
      final unsafe = GitHubRelease(
        version: release!.version,
        notes: '',
        page: Uri.parse('https://example.com/app.apk'),
      );
      await expectLater(
        Future.sync(() => service.openRelease(unsafe)),
        throwsFormatException,
      );
    });
  });
}
