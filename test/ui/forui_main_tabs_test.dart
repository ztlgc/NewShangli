import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';

import '../support/preview_fonts.dart';

final _updatePreviews = Platform.environment['UPDATE_FORUI_PREVIEWS'] == 'true';

Future<void> _capturePreview(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String path,
) async {
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile(Uri.file(File(path).absolute.path)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadForuiPreviewFonts();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Forui navigation switches all four main pages', (tester) async {
    final previewKey = GlobalKey();
    if (_updatePreviews) {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: NewShangliApp(
          databaseFactory: () =>
              AppDatabase.forTesting(NativeDatabase.memory()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('尚礼'), findsOneWidget);
    if (_updatePreviews) {
      await _capturePreview(
        tester,
        previewKey,
        'docs/forui-preview/record.png',
      );
    }
    for (final (index, title, slug) in [
      (0, '关系人', 'people'),
      (1, '统计', 'stats'),
      (2, '设置', 'settings'),
    ]) {
      await tester.tap(find.byType(FBottomNavigationBarItem).at(index + 1));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      if (_updatePreviews) {
        await _capturePreview(
          tester,
          previewKey,
          'docs/forui-preview/$slug.png',
        );
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('从应用首页进入记录页后可以打开账簿和关系人选择器', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_navigation_test'),
        name: const Value('导航测试账簿'),
        reasonType: const Value(''),
        themeColor: const Value('#111827'),
        isDefault: const Value(1),
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion(
        personId: const Value('person_navigation_test'),
        bookId: const Value('book_navigation_test'),
        name: const Value('导航测试联系人'),
        relationshipType: const Value('朋友'),
      ),
    );
    await tester.pumpWidget(NewShangliApp(databaseFactory: () => db));
    await tester.pumpAndSettle();
    expect(
      Localizations.localeOf(tester.element(find.text('记一笔'))).languageCode,
      'zh',
    );

    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordAddPage), findsOneWidget);

    final bookTap = await tester.startGesture(
      tester.getCenter(find.text('账簿')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await bookTap.up();
    await tester.pumpAndSettle();
    expect(find.text('选择所属账簿'), findsOneWidget);
    await tester.tap(find.text('导航测试账簿').last);
    await tester.pumpAndSettle();

    final personTap = await tester.startGesture(
      tester.getCenter(find.text('关系人')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await personTap.up();
    await tester.pumpAndSettle();
    expect(find.text('选择关系人'), findsOneWidget);
    await tester.tap(find.text('导航测试联系人').last);
    await tester.pumpAndSettle();
    expect(find.text('导航测试联系人'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('four main pages render on a narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      NewShangliApp(
        databaseFactory: () => AppDatabase.forTesting(NativeDatabase.memory()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getBottomLeft(find.byType(FBottomNavigationBar)).dy, 792);

    for (final index in [1, 2, 3, 0]) {
      await tester.tap(find.byType(FBottomNavigationBarItem).at(index));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'tab index $index');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('中文环境从设置进入数据备份后可打开 WebDAV 配置', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      NewShangliApp(
        initialTabIndex: 3,
        databaseFactory: () => AppDatabase.forTesting(NativeDatabase.memory()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('数据备份'));
    await tester.tap(find.text('数据备份'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('WebDAV 配置'));
    await tester.tap(find.text('WebDAV 配置'));
    await tester.pumpAndSettle();
    expect(find.text('服务器地址'), findsOneWidget);
    expect(find.text('保存配置'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('four main pages render in dark mode at 430 pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    final previewKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: NewShangliApp(
          databaseFactory: () =>
              AppDatabase.forTesting(NativeDatabase.memory()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    if (_updatePreviews) {
      await _capturePreview(
        tester,
        previewKey,
        'docs/forui-preview/dark/record.png',
      );
    }

    for (final (index, slug) in [
      (1, 'people'),
      (2, 'stats'),
      (3, 'settings'),
      (0, 'record'),
    ]) {
      await tester.tap(find.byType(FBottomNavigationBarItem).at(index));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'tab index $index');
      if (_updatePreviews) {
        await _capturePreview(
          tester,
          previewKey,
          'docs/forui-preview/dark/$slug.png',
        );
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
