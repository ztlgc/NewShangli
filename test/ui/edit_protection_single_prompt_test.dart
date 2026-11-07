import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/pages/person_edit_page.dart';
import 'package:newshangli/ui/pages/record_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppDatabase> _seed() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final now = DateTime.now().millisecondsSinceEpoch;
  // 首个账簿会被 insertOne 强制设为默认（只读），先占位再插入可编辑的测试账簿。
  await db.accountBooksDao.insertOne(
    AccountBooksCompanion(
      bookId: const Value('book_default'),
      name: const Value('默认账簿'),
    ),
  );
  await db.accountBooksDao.insertOne(
    AccountBooksCompanion(
      bookId: const Value('book_test'),
      name: const Value('测试账簿'),
      reasonType: const Value('婚礼'),
    ),
  );
  await db.relationTypesDao.create(name: '朋友');
  await db.personsDao.insertOne(
    PersonsCompanion(
      personId: const Value('person_test'),
      bookId: const Value('book_test'),
      name: const Value('测试联系人'),
      relationshipType: const Value('朋友'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
  await db.giftRecordsDao.insertOne(
    GiftRecordsCompanion(
      recordId: const Value('record_test'),
      bookId: const Value('book_test'),
      personId: const Value('person_test'),
      amountCent: const Value(5200),
      direction: const Value('收入'),
      eventName: const Value('乔迁'),
      occurredAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
  return db;
}

Widget _app(AppDatabase db, Widget home) => AppDatabaseScope(
  db: db,
  child: AppSessionScope(
    session: AppSession(),
    child: MaterialApp(theme: AppTheme.light(), home: home),
  ),
);

Future<void> _confirmPassword(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).last, '1234');
  await tester.tap(find.text('确认'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('记录：详情进编辑只弹一次密码，取消则退回详情', (tester) async {
    final db = await _seed();
    addTearDown(() async => db.close());
    SharedPreferences.setMockInitialValues({});
    await EditProtectionService().setPassword(newPassword: '1234');

    await tester.pumpWidget(
      _app(db, const RecordDetailPage(recordId: 'record_test')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byIcon(FLucideIcons.pen).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('编辑密码'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('编辑密码'), findsNothing);
    expect(find.byType(RecordDetailPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('联系人：编辑页只弹一次密码，确认后不再弹', (tester) async {
    final db = await _seed();
    addTearDown(() async => db.close());
    SharedPreferences.setMockInitialValues({});
    await EditProtectionService().setPassword(newPassword: '1234');

    await tester.pumpWidget(
      _app(db, const PersonEditPage(personId: 'person_test')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('编辑密码'), findsOneWidget);

    await _confirmPassword(tester);
    expect(find.text('编辑密码'), findsNothing);

    // 保存时不再弹第二次密码（保存动作本身不校验）。
    final saved = await db.personsDao.findById('person_test');
    expect(saved!.name, '测试联系人');
    expect(tester.takeException(), isNull);
  });
}
