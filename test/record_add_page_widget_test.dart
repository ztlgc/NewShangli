import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppDatabase> _buildDb({bool includeOtherBook = false}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.accountBooksDao.insertOne(
    AccountBooksCompanion(
      bookId: const Value('book_default'),
      name: const Value('默认账簿'),
      reasonType: const Value(''),
      themeColor: const Value('#312E81'),
      isDefault: const Value(1),
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
  final row = await db
      .customSelect('SELECT COUNT(*) AS c FROM gift_record;')
      .getSingle();
  return row.data['c'] as int? ?? 0;
}

Future<void> _resetEditProtection() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EditProtectionConfig.save(
    const EditProtectionConfig(
      enabled: false,
      passwordSalt: '',
      passwordHash: '',
    ),
  );
}

void main() {
  testWidgets('编辑记录：加载完成后可查看金额、关系人、事由和备注', (tester) async {
    await _resetEditProtection();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await _buildDb();
    addTearDown(() async => db.close());
    final recordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion(
        recordId: const Value('r_full'),
        bookId: const Value('book_default'),
        personId: const Value('p1'),
        direction: const Value('支出'),
        amountCent: const Value(123456),
        currency: const Value('CNY'),
        eventName: const Value('完整记录事由'),
        occurredAt: Value(DateTime(2026, 9, 20).millisecondsSinceEpoch),
        note: const Value('这是一条需要在编辑页完整显示的备注'),
        attachments: const Value(null),
        deletedAt: const Value(null),
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(home: RecordAddPage(recordId: recordId)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('编辑收支'), findsOneWidget);
    expect(find.text('1234.56'), findsOneWidget);
    expect(find.text('测试联系人'), findsOneWidget);
    expect(find.text('完整记录事由'), findsOneWidget);
    expect(find.text('支付方式'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('这是一条需要在编辑页完整显示的备注'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('这是一条需要在编辑页完整显示的备注'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('编辑记录：账簿、关系人、和事由均可打开并选择', (tester) async {
    await _resetEditProtection();
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await _buildDb(includeOtherBook: true);
    addTearDown(() async => db.close());
    final recordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion(
        recordId: const Value('r_picker_regression'),
        bookId: const Value('book_default'),
        personId: const Value('p1'),
        direction: const Value('收入'),
        amountCent: const Value(10000),
        currency: const Value('CNY'),
        eventName: const Value('测试事由'),
        occurredAt: Value(DateTime(2026, 10, 2).millisecondsSinceEpoch),
        note: const Value(null),
        attachments: const Value(null),
        deletedAt: const Value(null),
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(home: RecordAddPage(recordId: recordId)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('账簿'));
    await tester.pumpAndSettle();
    expect(find.text('选择所属账簿'), findsOneWidget);
    Navigator.of(tester.element(find.text('选择所属账簿'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('关系人'));
    await tester.pumpAndSettle();
    expect(find.text('选择关系人'), findsOneWidget);
    await tester.tap(find.text('测试联系人').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('事由'));
    await tester.pumpAndSettle();
    expect(find.text('选择事由'), findsOneWidget);
    await tester.tap(find.text('测试事由').last);
    await tester.pumpAndSettle();

    expect(find.text('支付方式'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('收支录入：保存后直接返回，不弹出放弃确认', (WidgetTester tester) async {
    await _resetEditProtection();
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
                        builder: (_) =>
                            const RecordAddPage(initialPersonId: 'p1'),
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
    await _resetEditProtection();
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
