import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/import/default_book_service.dart';
import 'package:newshangli/ui/app_data.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/account_book_edit_page.dart';

import '../test_utils.dart';

class _DbHost extends StatelessWidget {
  const _DbHost({
    required this.db,
    required this.child,
  });

  final AppDatabase db;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppDatabaseScope(db: db, child: child);
  }
}

void main() {
  testWidgets('账簿编辑：事由类型只能从已启用事由中选择，且无自定义入口', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await DefaultBookService().ensureDefaultBookId(db);

    final data = AppData();
    await tester.runAsync(() async {
      await waitAppDataReady(data);
    });

    await tester.pumpWidget(
      _DbHost(
        db: db,
        child: AppDataScope(
          data: data,
          child: const MaterialApp(home: AccountBookEditPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('事由类型'), findsOneWidget);
    await tester.tap(find.text('事由类型'));
    await tester.pumpAndSettle();

    expect(find.text('选择事由'), findsOneWidget);
    expect(find.textContaining('自定义'), findsNothing);
    expect(find.text('管理事由'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    db.close();
  });

  testWidgets('默认账簿：只读展示且不可删除', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final defaultBookId = await DefaultBookService().ensureDefaultBookId(db);

    final data = AppData();
    await tester.runAsync(() async {
      await waitAppDataReady(data);
    });

    await tester.pumpWidget(
      _DbHost(
        db: db,
        child: AppDataScope(
          data: data,
          child: MaterialApp(home: AccountBookEditPage(bookId: defaultBookId)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('不可修改'), findsOneWidget);
    expect(find.text('全部事由'), findsOneWidget);
    expect(find.text('删除账簿'), findsNothing);
    expect(find.text('设为默认账簿'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    db.close();
  });
}
