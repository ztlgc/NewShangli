import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/contact_relation_edit_page.dart';

void main() {
  testWidgets('联系人关系编辑页可以打开并选择联系人和关系类型', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_navigation_test'),
        name: const Value('默认账簿'),
      ),
    );
    for (final (id, name) in [('person_a', '甲联系人'), ('person_b', '乙联系人')]) {
      await db.personsDao.insertOne(
        PersonsCompanion(
          personId: Value(id),
          bookId: const Value('book_navigation_test'),
          name: Value(name),
          relationshipType: const Value('朋友'),
        ),
      );
    }
    await db.relationTypesDao.create(name: '朋友');
    await db.relationTypesDao.create(name: '同事');
    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: ContactRelationEditPage.create()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('联系人 A'));
    await tester.pumpAndSettle();
    expect(find.text('选择联系人'), findsOneWidget);
    await tester.tap(find.text('乙联系人').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('关系类型'));
    await tester.pumpAndSettle();
    expect(find.text('选择关系类型'), findsOneWidget);
    await tester.tap(find.text('同事').last);
    await tester.pumpAndSettle();
    expect(find.text('同事'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
