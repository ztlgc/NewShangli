import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';

Future<AppDatabase> _buildDb({
  bool includeOtherBook = false,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.accountBooksDao.insertOne(
    AccountBooksCompanion(
      bookId: const Value('book_default'),
      name: const Value('默认账簿'),
      reasonType: const Value(''),
      themeColor: const Value('#312E81'),
    ),
  );
  if (includeOtherBook) {
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_other_for_test'),
        name: const Value('其他账簿'),
        reasonType: const Value(''),
        themeColor: const Value('#111827'),
      ),
    );
  }
  await db.personsDao.insertOne(
    PersonsCompanion(
      personId: const Value('p1'),
      bookId: const Value('book_default'),
      name: const Value('测试联系人'),
      relationshipType: const Value('朋友'),
      phone: const Value('13800000000'),
      avatarUri: const Value(null),
      note: const Value(null),
      birthday: const Value(null),
      anniversary: const Value(null),
      deletedAt: const Value(null),
    ),
  );
  await db.reasonsDao.create(name: '测试事由');
  return db;
}

Future<int> _recordCount(AppDatabase db) async {
  final row = await db.customSelect('SELECT COUNT(*) AS c FROM gift_record;').getSingle();
  return row.data['c'] as int? ?? 0;
}

void main() {
  testWidgets('收支录入：保存后直接返回，不弹出放弃确认', (WidgetTester tester) async {
    final db = await _buildDb();
    addTearDown(() async => db.close());
    final initialCount = await _recordCount(db);

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RecordAddPage(),
                      ),
                    ),
                    child: const Text('打开录入'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开录入'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RecordAddPage), findsOneWidget);

    await tester.tap(find.text('200'));
    await tester.pump();

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('放弃编辑？'), findsNothing);
    expect(find.byType(RecordAddPage), findsNothing);
    expect(await _recordCount(db), initialCount + 1);
  });

  testWidgets('收支录入：编辑记录保存应保留原 bookId', (WidgetTester tester) async {
    final db = await _buildDb(includeOtherBook: true);
    addTearDown(() async => db.close());
    final recordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion(
        recordId: const Value('r1'),
        bookId: const Value('book_other_for_test'),
        personId: const Value('p1'),
        direction: const Value('收入'),
        amountCent: const Value(100),
        currency: const Value('CNY'),
        eventName: const Value('其他账簿记录_仅测试'),
        occurredAt: Value(DateTime(2099, 1, 2, 12, 0).millisecondsSinceEpoch),
        paymentMethod: const Value('现金'),
        note: const Value(null),
        attachments: const Value(null),
        deletedAt: const Value(null),
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecordAddPage(recordId: recordId),
                      ),
                    ),
                    child: const Text('打开编辑'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开编辑'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byType(RecordAddPage), findsOneWidget);
    expect(find.text('金额 (元)'), findsOneWidget);

    await tester.tap(find.text('200'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final updated = await db.giftRecordsDao.findByIdAny(recordId);
    expect(updated, isNotNull);
    expect(updated!.bookId, 'book_other_for_test');
  });
}
