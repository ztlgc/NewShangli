import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/pages/account_book_data_import_page.dart';

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

Future<void> waitForText(WidgetTester tester, String text) async {
  for (var i = 0; i < 60 && find.text(text).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
  expect(find.text(text), findsOneWidget);
}

void main() {
  testWidgets('粘贴导入提示疑似重复，跳过后只写入用户保留的记录', (tester) async {
    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('paste_import_'),
    ))!;
    final previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPaths(temp.path);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      PathProviderPlatform.instance = previous;
      await tester.runAsync(() => temp.delete(recursive: true));
    });
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(name: '默认', createdAt: 1, updatedAt: 1),
    );
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value('b'),
        name: '测试',
        reasonType: const Value('测试'),
        bookTime: Value(now),
        createdAt: 2,
        updatedAt: 2,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value('p'),
        bookId: 'b',
        name: '李四',
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: 'b',
        personId: 'p',
        amountCent: 50000,
        direction: const Value('收入'),
        eventName: const Value('测试'),
        occurredAt: now,
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    await tester.pumpWidget(
      AppSessionScope(
        session: AppSession(),
        child: AppDatabaseScope(
          db: db,
          child: const MaterialApp(
            home: AccountBookDataImportPage(bookId: 'b', bookName: '测试'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(FTextField), '李四 500\n王五 600\n李四 500');
    await tester.scrollUntilVisible(
      find.text('立即解析并导入'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('立即解析并导入'));
    await waitForText(tester, '疑似重复记录');
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    await waitForText(tester, '疑似重复记录');
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    await waitForText(tester, '导入完成');
    final records = await db.select(db.giftRecords).get();
    expect(records.length, 2);
    expect(records.map((r) => r.amountCent).toSet(), {50000, 60000});
    expect(
      records.every(
        (r) => r.bookId == 'b' && r.occurredAt == now && r.direction == '收入',
      ),
      true,
    );
    expect(find.textContaining('跳过 2 行'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
