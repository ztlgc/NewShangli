import 'package:forui/forui.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/relation_type_manage_page.dart';

void main() {
  testWidgets('编辑关系类型保存后正常关闭，不触发框架断言', (tester) async {
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

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: RelationTypeManagePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('朋友'), findsOneWidget);

    expect(find.text('1 位联系人'), findsOneWidget);
    expect(find.text('总类型'), findsNothing);
    expect(find.text('已分类联系人'), findsNothing);
    expect(find.byType(FTextField), findsNothing);
    await tester.tap(find.text('朋友'));
    await tester.pumpAndSettle();
    expect(find.text('测试联系人'), findsOneWidget);
    await tester.tap(find.byIcon(FLucideIcons.pen));
    await tester.pumpAndSettle();
    expect(find.text('编辑类型'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '好友');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('已保存'), findsOneWidget);
    final updated = await db.relationTypesDao.findById(
      (await db.relationTypesDao.listAll()).single.typeId,
    );
    expect(updated!.name, '好友');
    expect(find.text('好友'), findsNWidgets(2));
    expect(find.text('测试联系人'), findsOneWidget);
    expect(
      (await db.personsDao.findById('test-contact'))!.relationshipType,
      '好友',
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(FLucideIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(find.text('好友'), findsOneWidget);
    expect(find.text('1 位联系人'), findsOneWidget);
    await tester.tap(find.byIcon(FLucideIcons.plus));
    await tester.pumpAndSettle();
    expect(find.text('新增类型'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '邻居');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('邻居'), findsOneWidget);
    expect(find.text('暂无联系人'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 清理计时器并卸载组件树，避免测试收尾出现遗留 Timer。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
  });
}
