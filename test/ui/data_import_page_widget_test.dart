import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/data_import_page.dart';

void main() {
  testWidgets('导入页使用应用数据库作用域并展示文件类型入口', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
    });

    const bookId = 'book_import_scope';
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value(bookId),
        name: '导入测试账本',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: DataImportPage(initialBookId: bookId)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('数据导入'), findsOneWidget);
    expect(find.text('点击选择 Excel 或 CSV 文件'), findsOneWidget);
    expect(find.text('支持 Excel / CSV'), findsOneWidget);
    expect(find.text('字段匹配'), findsNothing);
    expect(find.text('开始导入'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
