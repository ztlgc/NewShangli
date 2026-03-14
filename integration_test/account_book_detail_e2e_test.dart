import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/pages/account_books_page.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('账簿管理到详情再到导入页核心链路可用', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value('book_e2e'),
        name: 'E2E账簿',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        session: AppSession(),
        child: AppDatabaseScope(
          db: db,
          child: const MaterialApp(home: AccountBooksPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('E2E账簿'));
    await tester.pumpAndSettle();
    expect(find.text('总收入'), findsOneWidget);

    await tester.tap(find.byIcon(FontAwesomeIcons.fileImport));
    await tester.pumpAndSettle();
    expect(find.text('导入数据'), findsOneWidget);
  });
}
