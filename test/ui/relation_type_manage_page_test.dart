import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/relation_type_manage_page.dart';

void main() {
  testWidgets('关系类型管理页展示统一命名并使用明确删除确认', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
    });

    await db.relationTypesDao.create(name: '亲友');

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: RelationTypeManagePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('关系类型管理'), findsOneWidget);
    expect(find.text('联系人关系管理'), findsNothing);

    // 长按列表项会打开删除确认弹窗，这里顺带校验确认文案是否补全了实体名称。
    await tester.longPress(find.text('亲友'));
    await tester.pumpAndSettle();

    expect(find.text('删除关系类型'), findsOneWidget);
    expect(find.text('确认删除关系类型「亲友」？'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
