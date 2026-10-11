import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/pages/person_detail_page.dart';
import 'package:newshangli/ui/pages/person_edit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('从关系人详情进入编辑页后，点关系类型标签可选择', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EditProtectionConfig.save(
      const EditProtectionConfig(
        enabled: false,
        passwordSalt: '',
        passwordHash: '',
      ),
    );
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_default'),
        name: const Value('默认账簿'),
      ),
    );
    for (final name in ['家人', '亲戚', '同事', '朋友', '同学', '邻居']) {
      await db.relationTypesDao.create(name: name);
    }
    await db.personsDao.insertOne(
      PersonsCompanion(
        personId: const Value('person_route_test'),
        bookId: const Value('book_default'),
        name: const Value('路线测试联系人'),
        relationshipType: const Value('朋友'),
      ),
    );
    await tester.pumpWidget(
      AppSessionScope(
        session: AppSession(),
        child: AppDatabaseScope(
          db: db,
          child: const MaterialApp(
            home: PersonDetailPage(personId: 'person_route_test'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byIcon(FLucideIcons.pen));
    await tester.pumpAndSettle();
    expect(find.text('编辑关系人'), findsOneWidget);
    await tester.tap(find.text('路线测试联系人').last);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pump();
    await tester.tap(find.text('关系类型', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('选择关系类型'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byType(FCard).last).dy,
      lessThanOrEqualTo(360),
    );
    await tester.tap(find.text('同事').last);
    await tester.pumpAndSettle();
    expect(find.text('同事'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('编辑关系人：点击关系类型可打开选择器并更新', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EditProtectionConfig.save(
      const EditProtectionConfig(
        enabled: false,
        passwordSalt: '',
        passwordHash: '',
      ),
    );
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_default'),
        name: const Value('默认账簿'),
      ),
    );
    await db.relationTypesDao.create(name: '朋友');
    await db.relationTypesDao.create(name: '同事');
    await db.personsDao.insertOne(
      PersonsCompanion(
        personId: const Value('person_edit_test'),
        bookId: const Value('book_default'),
        name: const Value('测试联系人'),
        relationshipType: const Value('朋友'),
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(
          home: PersonEditPage(personId: 'person_edit_test'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('编辑关系人'), findsOneWidget);
    await tester.tap(find.text('朋友'));
    await tester.pumpAndSettle();
    expect(find.text('选择关系类型'), findsOneWidget);

    await tester.tap(find.text('同事'));
    await tester.pumpAndSettle();
    expect(find.text('同事'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
