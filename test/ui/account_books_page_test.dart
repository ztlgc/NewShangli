import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/account_books_page.dart';
import 'package:newshangli/utils/date_util.dart';

void main() {
  testWidgets('账簿列表显示账簿时间', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().millisecondsSinceEpoch;
    final bookTime = DateTime(2024, 2, 3).millisecondsSinceEpoch;
    final expectedBookTimeLabel =
        '账簿时间：${DateUtil.format(DateTime.fromMillisecondsSinceEpoch(bookTime))}';

    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value('book_test_1'),
        name: '测试账簿',
        reasonType: const Value('结婚礼金'),
        bookTime: Value(bookTime),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: AccountBooksPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('测试账簿'), findsOneWidget);
    expect(find.text(expectedBookTimeLabel), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await db.close();
  });
}
