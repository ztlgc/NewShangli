import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/reason_detail_page.dart';

void main() {
  testWidgets('Forui 事由表单保留必填校验和创建操作', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: ReasonDetailPage.create()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('事由名称不能为空'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, '婚礼');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect((await db.reasonsDao.listAll()).single.name, '婚礼');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
