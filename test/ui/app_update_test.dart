import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_forui_theme.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/app_update_host.dart';
import 'package:newshangli/ui/pages/settings_home_page.dart';
import 'package:newshangli/update/app_update_service.dart';
import 'package:newshangli/update/github_release.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/update_fixtures.dart';

final _now = DateTime(2026, 11, 8, 10);

Future<void> _pumpSettings(
  WidgetTester tester,
  AppUpdateService service,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => AppForuiBoundary(child: child!),
      home: AppUpdateHost(service: service, child: const SettingsHomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    200,
    scrollable: find
        .descendant(
          of: find.byType(SettingsHomePage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  late FakeUpdatePlatform platform;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platform = FakeUpdatePlatform();
  });

  void skipAutomaticCheck() {
    SharedPreferences.setMockInitialValues({
      AppUpdateService.lastAutomaticCheckKey: _now.millisecondsSinceEpoch,
    });
  }

  AppUpdateService service(Future<GitHubRelease?> Function() fetch) =>
      AppUpdateService(
        platform: platform,
        fetchLatest: fetch,
        clock: () => _now,
      );

  testWidgets('关于页面显示完整版本号，手动检查可发现同版本的新构建', (tester) async {
    skipAutomaticCheck();
    await _pumpSettings(tester, service(() async => releaseFixture()));
    await _scrollTo(tester, '关于礼记');
    expect(find.text('v1.2.5+2008'), findsOneWidget);
    await tester.tap(find.text('关于礼记'));
    await tester.pumpAndSettle();
    expect(find.textContaining('版本 v1.2.5+2008'), findsOneWidget);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, '检查更新');
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    expect(find.text('发现新版本 1.2.5+2009'), findsOneWidget);
    expect(find.textContaining('当前版本：1.2.5+2008'), findsOneWidget);
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    await _dispose(tester);
  });

  testWidgets('启动检查提示更新，下载打开正确的 Release 页面', (tester) async {
    await _pumpSettings(tester, service(() async => releaseFixture()));
    expect(find.text('发现新版本 1.2.5+2009'), findsOneWidget);
    await tester.tap(find.text('前往下载'));
    await tester.pumpAndSettle();
    expect(
      platform.opened.toString(),
      'https://github.com/ztlgc/NewShangli/releases/tag/1.2.5+2009',
    );
    await _dispose(tester);
  });

  testWidgets('忽略保存完整版本，手动检查仍能查看', (tester) async {
    await _pumpSettings(tester, service(() async => releaseFixture()));
    await tester.tap(find.text('忽略此版本'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppUpdateService.ignoredVersionKey), '1.2.5+2009');
    await _scrollTo(tester, '检查更新');
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    expect(find.text('发现新版本 1.2.5+2009'), findsOneWidget);
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    await _dispose(tester);
  });

  testWidgets('自动失败保持安静，手动检查失败给出提示', (tester) async {
    await _pumpSettings(
      tester,
      service(() async => throw StateError('offline')),
    );
    expect(find.text('检查更新失败，请检查网络后重试'), findsNothing);
    await _scrollTo(tester, '检查更新');
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    expect(find.text('检查更新失败，请检查网络后重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('手动检查当前版本给出反馈', (tester) async {
    skipAutomaticCheck();
    await _pumpSettings(
      tester,
      service(() async => releaseFixture('1.2.5+2008')),
    );
    await _scrollTo(tester, '检查更新');
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    expect(find.text('当前已是最新版本（1.2.5+2008）'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('重复点击只发出一次请求和一个弹窗', (tester) async {
    skipAutomaticCheck();
    final pending = Completer<GitHubRelease?>();
    var requests = 0;
    await _pumpSettings(
      tester,
      service(() {
        requests++;
        return pending.future;
      }),
    );
    await _scrollTo(tester, '检查更新');
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('正在检查更新…'));
    await tester.tap(find.text('正在检查更新…'));
    expect(requests, 1);
    pending.complete(releaseFixture());
    await tester.pumpAndSettle();
    expect(find.text('发现新版本 1.2.5+2009'), findsOneWidget);
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    await _dispose(tester);
  });

  testWidgets('不会打断其他页面，返回后再显示自动更新提醒', (tester) async {
    final pending = Completer<GitHubRelease?>();
    await _pumpSettings(tester, service(() => pending.future));
    final navigator = Navigator.of(
      tester.element(find.byType(SettingsHomePage)),
    );
    unawaited(
      navigator.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('正在编辑记录'))),
      ),
    );
    await tester.pumpAndSettle();
    pending.complete(releaseFixture());
    await tester.pumpAndSettle();
    expect(find.text('发现新版本 1.2.5+2009'), findsNothing);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('发现新版本 1.2.5+2009'), findsOneWidget);
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    await _dispose(tester);
  });

  testWidgets('下载页无法打开时显示失败提示', (tester) async {
    platform.openResult = false;
    await _pumpSettings(tester, service(() async => releaseFixture()));
    await tester.tap(find.text('前往下载'));
    await tester.pumpAndSettle();
    expect(find.text('无法打开下载页面，请检查是否已安装浏览器'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('请求返回前退出应用不会在已销毁的上下文弹窗', (tester) async {
    final pending = Completer<GitHubRelease?>();
    await _pumpSettings(tester, service(() => pending.future));
    await _dispose(tester);
    pending.complete(releaseFixture());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('长更新说明在窄屏和放大字体下可滚动操作', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final release = releaseFixture();
    await _pumpSettings(
      tester,
      service(
        () async => GitHubRelease(
          version: release.version,
          notes: List.filled(60, '完善版本更新与数据管理。').join('\n'),
          page: release.page,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('稍后'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });
}
