import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_data.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/account_book_edit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils.dart';

void main() {
  testWidgets('鉴权等待期间保存按钮保持忙碌态，取消密码不写库', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EditProtectionService().setPassword(newPassword: '1234');

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());
    // insertOne 会把首个账簿强制设为默认（只读），先占位再插入可编辑的 book_a。
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_default'),
        name: const Value('默认账簿'),
      ),
    );
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_a'),
        name: const Value('原账簿名'),
        reasonType: const Value('婚礼'),
      ),
    );

    final data = AppData();
    await tester.runAsync(() async {
      await waitAppDataReady(data);
    });

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: AppDataScope(
          data: data,
          child: const MaterialApp(home: AccountBookEditPage(bookId: 'book_a')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑账簿'), findsOneWidget);
    await tester.tap(find.text('保存').last);
    await tester.pump();

    // 鉴权弹窗出现的同时，按钮已进入忙碌态。
    expect(find.text('保存中'), findsOneWidget);
    expect(find.text('编辑密码'), findsOneWidget);

    // 顶栏本身有“取消”按钮，这里点击的是密码弹窗里的取消。
    await tester.tap(find.text('取消').last);
    await tester.pumpAndSettle();

    final saved = await db.accountBooksDao.findById('book_a');
    expect(saved!.name, '原账簿名');
    expect(find.text('保存'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
