import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';

void main() {
  testWidgets('从联系人入口录入沿用指定联系人，不选择数据库第一人', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value('book_default_test'),
        name: '默认账簿',
        reasonType: const Value(''),
        isDefault: const Value(1),
        bookTime: Value(now),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 先插入一个已软删除联系人，再插入一个有效联系人。
    // 如果默认联系人查询未过滤 deleted_at，可能错误命中已删除数据。
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value('person_deleted'),
        bookId: 'book_default_test',
        name: '已删除联系人',
        relationshipType: const Value('朋友'),
        createdAt: now,
        updatedAt: now,
        deletedAt: Value(now),
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value('person_active'),
        bookId: 'book_default_test',
        name: '有效联系人',
        relationshipType: const Value('朋友'),
        createdAt: now + 1,
        updatedAt: now + 1,
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: RecordAddPage(initialPersonId: 'person_active')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('有效联系人'), findsOneWidget);
    expect(find.text('已删除联系人'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await db.close();
  });
}
