import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/relation_type_manage_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppDatabase> _seed() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.relationTypesDao.create(name: '朋友');
  await db.accountBooksDao.insertOne(
    AccountBooksCompanion(
      bookId: const Value('test-book'),
      name: const Value('测试账簿'),
    ),
  );
  await db.personsDao.insertOne(
    PersonsCompanion(
      personId: const Value('test-contact'),
      bookId: const Value('test-book'),
      name: const Value('测试联系人'),
      relationshipType: const Value('朋友'),
    ),
  );
  return db;
}

Future<void> _openRenameSheet(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    AppDatabaseScope(
      db: db,
      child: const MaterialApp(home: RelationTypeManagePage()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('朋友'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(FLucideIcons.pen));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(EditableText).first, '好友');
}

Future<void> _tearDown(WidgetTester tester, AppDatabase db) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('开启编辑保护时重命名关系类型，取消密码则不改写联系人', (tester) async {
    await EditProtectionService().setPassword(newPassword: '1234');
    final db = await _seed();
    await _openRenameSheet(tester, db);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('编辑密码'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(
      (await db.personsDao.findById('test-contact'))!.relationshipType,
      '朋友',
    );
    expect((await db.relationTypesDao.listAll()).single.name, '朋友');
    expect(tester.takeException(), isNull);
    await _tearDown(tester, db);
  });

  testWidgets('开启编辑保护时输入正确密码后，重命名关系类型并改写联系人', (tester) async {
    await EditProtectionService().setPassword(newPassword: '1234');
    final db = await _seed();
    await _openRenameSheet(tester, db);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, '1234');
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(
      (await db.personsDao.findById('test-contact'))!.relationshipType,
      '好友',
    );
    expect(tester.takeException(), isNull);
    await _tearDown(tester, db);
  });
}
