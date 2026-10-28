import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/platform/app_platform.dart';
import 'package:newshangli/platform/flutter_platform_adapter.dart';
import 'package:newshangli/ui/app.dart';
import 'package:newshangli/ui/pages/account_books_page.dart';
import 'package:newshangli/ui/pages/data_export_page.dart';
import 'package:newshangli/ui/pages/data_import_page.dart';
import 'package:newshangli/ui/pages/person_detail_page.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/preview_fonts.dart';
import '../support/stats_preview_data.dart';

/// Documentation-only renderer. Every entity and imported file is fictional.
/// Run with README_SCREENSHOTS_DIR set; ordinary flutter tests do not run it.
class _ScreenshotPlatform extends FlutterPlatformAdapter {
  _ScreenshotPlatform(this.directory, this.csv);
  final Directory directory;
  final File csv;

  @override
  Future<Directory> documentsDirectory() async => directory;
  @override
  Future<Directory> temporaryDirectory() async => directory;
  @override
  Future<AppPickedFiles?> pickFiles({
    required List<String> allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
  }) async => AppPickedFiles([
    AppPickedFile(name: '家庭礼账示例.csv', path: csv.path, size: csv.lengthSync()),
  ]);
}

Future<void> _settle(WidgetTester tester) async {
  // Give real SQLite/file futures time outside the fake animation clock.
  for (var index = 0; index < 10; index++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String directory,
  String name,
) async {
  await _settle(tester);
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$directory/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadForuiPreviewFonts);
  testWidgets('render fictional ledger for README', (tester) async {
    final output = Directory(Platform.environment['README_SCREENSHOTS_DIR']!)
        .absolute;
    SharedPreferences.setMockInitialValues({});
    late Directory temporary;
    late File csv;
    late AppDatabase db;
    late String recordId;
    await tester.runAsync(() async {
      temporary = await Directory.systemTemp.createTemp('liji_readme_');
      csv = File('${temporary.path}/demo.csv')
        ..writeAsStringSync(
          '数据类型,收支方向,金额(元),联系人姓名,事由,发生时间,备注\n'
          '礼金收支记录,收入,600,周敏,乔迁礼金,2026-10-28,新居乔迁\n'
          '礼金收支记录,支出,500,李娜,生日礼金,2026-10-26,生日祝福\n'
          '礼金收支记录,收入,800,陈明,结婚礼金,2026-10-25,婚礼随礼\n',
        );
      db = await createStatsPreviewDatabase();
      await output.create(recursive: true);
      for (final name in ['结婚礼金', '生日礼金', '乔迁礼金', '满月礼金', '升学礼金']) {
        await db.reasonsDao.create(name: name);
      }
      for (final (index, relationship) in [
        '朋友',
        '同事',
        '亲戚',
        '同学',
        '邻居',
        '朋友',
        '家人',
        '同事',
        '朋友',
      ].indexed) {
        await (db.update(
              db.persons,
            )..where((person) => person.personId.equals('stats_person_$index')))
            .write(PersonsCompanion(relationshipType: Value(relationship)));
      }
      await (db.update(
        db.accountBooks,
      )..where((book) => book.bookId.equals('stats_book_1'))).write(
        AccountBooksCompanion(
          name: const Value('乔迁礼账'),
          reasonType: const Value('乔迁礼金'),
          description: const Value('新居落成，记录亲友的每一份心意'),
          bookTime: Value(DateTime(2026, 10, 25).millisecondsSinceEpoch),
        ),
      );
      recordId = await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion(
          bookId: const Value('stats_book_0'),
          personId: const Value('stats_person_0'),
          direction: const Value('收入'),
          amountCent: const Value(50000),
          eventName: const Value('乔迁礼金'),
          note: const Value('新居落成，谢谢老朋友的祝福'),
          occurredAt: Value(DateTime(2026, 10, 28).millisecondsSinceEpoch),
        ),
      );
    });
    final previousPlatform = AppPlatform.instance;
    AppPlatform.instance = _ScreenshotPlatform(temporary, csv);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
    addTearDown(() {
      AppPlatform.instance = previousPlatform;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearLocalesTestValue();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: NewShangliApp(databaseFactory: () => db),
      ),
    );
    await _capture(tester, key, output.path, 'records');
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );

    Future<void> page(String name, Widget page, {bool import = false}) async {
      navigator.push<void>(MaterialPageRoute(builder: (_) => page));
      await _settle(tester);
      if (import) {
        await tester.tap(find.text('点击选择 Excel 或 CSV 文件'));
        await _settle(tester);
        expect(find.text('字段匹配'), findsOneWidget);
      }
      await _capture(tester, key, output.path, name);
      navigator.pop();
      await _settle(tester);
    }

    await page('record-edit', RecordAddPage(recordId: recordId));
    await tester.tap(find.byType(FBottomNavigationBarItem).at(1));
    await _capture(tester, key, output.path, 'contacts');
    await page(
      'contact-detail',
      const PersonDetailPage(personId: 'stats_person_0'),
    );
    await tester.tap(find.byType(FBottomNavigationBarItem).at(2));
    await _capture(tester, key, output.path, 'statistics');
    await tester.tap(find.byType(FBottomNavigationBarItem).at(3));
    await page('account-books', const AccountBooksPage());
    await page('data-import', const DataImportPage(), import: true);
    await page('data-export', const DataExportPage());
    await tester.tap(find.byType(FBottomNavigationBarItem).at(2));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await _capture(tester, key, output.path, 'statistics-dark');
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    await tester.runAsync(() => temporary.delete(recursive: true));
  }, skip: Platform.environment['README_SCREENSHOTS_DIR'] == null);
}
