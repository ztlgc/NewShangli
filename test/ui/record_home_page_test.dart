import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/pages/record_home_page.dart';

Future<AppDatabase> _buildDbWithRecord() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final now = DateTime.now().millisecondsSinceEpoch;

  // 说明：
  // - 记录首页依赖“账簿 + 联系人 + 记录”的完整关联数据；
  // - 这里构造一条最小可展示记录，确保测试聚焦在批量删除交互本身。
  await db.accountBooksDao.insertOne(
    AccountBooksCompanion.insert(
      bookId: const Value('book_test'),
      name: '测试账簿',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await db.personsDao.insertOne(
    PersonsCompanion.insert(
      personId: const Value('person_test'),
      bookId: 'book_test',
      name: '测试联系人',
      relationshipType: const Value('朋友'),
      createdAt: now,
      updatedAt: now,
    ),
  );
  await db.giftRecordsDao.insertOne(
    GiftRecordsCompanion.insert(
      recordId: const Value('record_test'),
      bookId: 'book_test',
      personId: 'person_test',
      amountCent: 5200,
      direction: const Value('收入'),
      eventName: const Value('乔迁'),
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
    ),
  );
  return db;
}

Widget _buildTestApp(AppDatabase db) {
  return AppSessionScope(
    session: AppSession(),
    child: AppDatabaseScope(
      db: db,
      child: MaterialApp(theme: AppTheme.light(), home: const RecordHomePage()),
    ),
  );
}

void main() {
  testWidgets('记录首页批量删除使用移入回收站文案并展示成功提示', (tester) async {
    final db = await _buildDbWithRecord();

    try {
      await tester.pumpWidget(_buildTestApp(db));
      await tester.pumpAndSettle();

      expect(find.text('测试联系人'), findsOneWidget);

      // 长按记录进入多选模式，再触发底部批量删除操作。
      await tester.longPress(find.text('测试联系人'));
      await tester.pumpAndSettle();

      expect(find.text('已选择1项'), findsOneWidget);

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(find.text('移入回收站'), findsNWidgets(2));
      expect(find.text('确认将 1 条记录移入回收站？'), findsOneWidget);
      expect(find.text('批量删除'), findsNothing);
      expect(find.text('永久删除'), findsNothing);

      await tester.tap(find.text('移入回收站').last);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('记录已移入回收站'), findsOneWidget);
      expect(find.text('已删除选中记录'), findsNothing);
      expect(await db.giftRecordsDao.findById('record_test'), isNull);

      final deletedRecord = await db.giftRecordsDao.findByIdAny('record_test');
      expect(deletedRecord, isNotNull);
      expect(deletedRecord!.deletedAt, isNotNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
      await db.close();
    }
  });
}
