import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/pages/account_book_data_import_page.dart';

void main() {
  testWidgets('导入完成弹窗展示重复记录明细', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().millisecondsSinceEpoch;
    const bookId = 'book_1';
    const personId = 'person_1';

    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value(bookId),
        name: '测试账簿',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value(personId),
        bookId: bookId,
        name: '李四',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: bookId,
        personId: personId,
        amountCent: 50000,
        direction: const Value('收入'),
        eventName: const Value('测试'),
        paymentMethod: const Value('现金'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        session: AppSession(),
        child: AppDatabaseScope(
          db: db,
          child: const MaterialApp(
            home: AccountBookDataImportPage(bookId: bookId, bookName: '测试账簿'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '李四 500\n王五 600\n李四 500\n无效行',
    );
    await tester.scrollUntilVisible(
      find.text('立即解析并导入'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('立即解析并导入'));
    await tester.pumpAndSettle();

    expect(find.text('导入完成'), findsOneWidget);
    expect(find.textContaining('成功 1 条'), findsOneWidget);
    expect(find.textContaining('重复跳过 2 条'), findsOneWidget);
    expect(find.textContaining('解析失败 1 条'), findsOneWidget);
    expect(find.textContaining('重复记录：'), findsOneWidget);
    expect(find.textContaining('第1行：李四 500.00元'), findsOneWidget);
    expect(find.textContaining('第3行：李四 500.00元'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await db.close();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
