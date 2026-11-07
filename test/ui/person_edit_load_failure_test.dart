import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/person_edit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('联系人加载失败时保存被阻止，且不覆盖数据库中的已有字段', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EditProtectionConfig.save(
      const EditProtectionConfig(
        enabled: false,
        passwordSalt: '',
        passwordHash: '',
      ),
    );
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_default'),
        name: const Value('默认账簿'),
      ),
    );
    await db.relationTypesDao.create(name: '朋友');
    await db.personsDao.insertOne(
      PersonsCompanion(
        personId: const Value('person_load_fail'),
        bookId: const Value('book_default'),
        name: const Value('原姓名'),
        relationshipType: const Value('同事'),
        avatarUri: const Value('avatar://old.png'),
        note: const Value('原备注'),
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(
          home: PersonEditPage(
            personId: 'person_load_fail',
            // 注入失败的读取，模拟加载异常，数据库本身保持可用。
            personLoader: (_, _) async => throw StateError('模拟读取失败'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('联系人加载失败，无法保存，请返回重试'), findsOneWidget);
    final saved = await db.personsDao.findByIdAny('person_load_fail');
    expect(saved!.name, '原姓名');
    expect(saved.note, '原备注');

    // 行内编辑备注同样被阻止，不会用页面默认值覆盖数据库字段。
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('未设置').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(EditableText).last, '新备注');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('联系人加载失败，无法保存，请返回重试'), findsOneWidget);
    final afterInline = await db.personsDao.findByIdAny('person_load_fail');
    expect(afterInline!.note, '原备注');
    expect(afterInline.relationshipType, '同事');
    expect(afterInline.avatarUri, 'avatar://old.png');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
