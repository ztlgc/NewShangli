import 'package:forui/forui.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/relation_type_manage_page.dart';

void main() {
  testWidgets('编辑关系类型保存后正常关闭，不触发框架断言', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.relationTypesDao.create(name: '朋友');

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: RelationTypeManagePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('朋友'), findsOneWidget);

    await tester.tap(find.byIcon(FLucideIcons.squarePen));
    await tester.pumpAndSettle();
    expect(find.text('编辑类型'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('已保存'), findsOneWidget);
    final updated = await db.relationTypesDao.findById(
      (await db.relationTypesDao.listAll()).single.typeId,
    );
    expect(updated, isNotNull);

    // 清理计时器并卸载组件树，避免测试收尾出现遗留 Timer。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
  });
}
