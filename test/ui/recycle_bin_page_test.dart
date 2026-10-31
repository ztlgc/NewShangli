import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/pages/recycle_bin_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/preview_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadForuiPreviewFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void recycleTest(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      }
    });
  }

  Future<AppDatabase> database({
    bool deletePerson = false,
    bool longText = false,
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book'),
        name: const Value('婚礼礼簿'),
      ),
    );
    for (final entry in {
      'zhang': longText ? '一位姓名特别长需要完整辨认的联系人张伟' : '张伟',
      'zhou': '周敏',
    }.entries) {
      await db.personsDao.insertOne(
        PersonsCompanion(
          personId: Value(entry.key),
          bookId: const Value('book'),
          name: Value(entry.value),
          relationshipType: const Value('朋友'),
          phone: Value(entry.key == 'zhang' ? '13800138000' : '13900139000'),
        ),
      );
    }
    for (final entry in [
      ('one', 'zhang', '收入', longText ? 99999999999999 : 50000, '婚礼'),
      ('two', 'zhou', '支出', 80000, '乔迁'),
      ('three', 'zhang', '收入', 20000, '生日'),
    ]) {
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion(
          recordId: Value(entry.$1),
          bookId: const Value('book'),
          personId: Value(entry.$2),
          direction: Value(entry.$3),
          amountCent: Value(entry.$4),
          eventName: Value(entry.$5),
          occurredAt: Value(now),
          deletedAt: Value(
            entry.$1 == 'three'
                ? DateTime.now()
                      .subtract(const Duration(days: 1))
                      .millisecondsSinceEpoch
                : now,
          ),
        ),
      );
    }
    if (deletePerson) await db.personsDao.deleteById('zhang');
    return db;
  }

  Future<void> mount(
    WidgetTester tester,
    AppDatabase db, {
    bool dark = false,
    GlobalKey? boundary,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
      await tester.pump(const Duration(milliseconds: 50));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: boundary == null
              ? const RecycleBinPage()
              : RepaintBoundary(key: boundary, child: const RecycleBinPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectAll(WidgetTester tester) async {
    await tester.tap(find.text('管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('全选').last);
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, String id) async {
    final row = find.byKey(ValueKey('recycle-row-$id'));
    await tester.dragFrom(
      tester.getTopLeft(row) + const Offset(180, 25),
      const Offset(-160, 0),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirmPurge(WidgetTester tester) async {
    final confirm = find.widgetWithText(OutlinedButton, '彻底删除');
    await tester.tap(confirm);
    await tester.pumpAndSettle();
  }

  recycleTest('按原账簿与姓名搜索，分组显示，清除搜索恢复列表', (tester) async {
    final db = await database();
    await mount(tester, db);
    expect(find.text('今天删除'), findsOneWidget);
    expect(find.text('昨天删除'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '婚礼礼簿');
    await tester.pumpAndSettle();
    expect(find.text('找到 3 项'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '周敏');
    await tester.pumpAndSettle();
    expect(
      find.text('周敏', findRichText: false).hitTestable().last,
      findsOneWidget,
    );
    expect(find.text('张伟'), findsNothing);
    await tester.enterText(find.byType(EditableText), '不存在的事由');
    await tester.pumpAndSettle();
    expect(find.text('没有找到相关内容'), findsOneWidget);
    await tester.tap(find.text('清除搜索'));
    await tester.pumpAndSettle();
    expect(find.text('今天删除'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  recycleTest('全选只作用于搜索结果，批量恢复保留其他删除记录', (tester) async {
    final db = await database();
    await mount(tester, db);
    await tester.enterText(find.byType(EditableText), '张伟');
    await tester.pumpAndSettle();
    await selectAll(tester);
    expect(find.text('已选择 2 项'), findsOneWidget);
    await tester.tap(find.text('恢复 2 项'));
    await tester.pumpAndSettle();
    expect(await db.giftRecordsDao.findById('one'), isNotNull);
    expect(await db.giftRecordsDao.findById('three'), isNotNull);
    expect(await db.giftRecordsDao.findById('two'), isNull);
    expect((await db.giftRecordsDao.findByIdAny('two'))!.deletedAt, isNotNull);
    expect(find.text('回收站'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  recycleTest('恢复记录前确认关联联系人，仅恢复选中记录', (tester) async {
    final db = await database(deletePerson: true);
    await mount(tester, db);
    await tester.enterText(find.byType(EditableText), '婚礼');
    await tester.pumpAndSettle();
    // 账簿名同样包含婚礼，改为姓名再只选第一条。
    await tester.enterText(find.byType(EditableText), '张伟');
    await tester.pumpAndSettle();
    await reveal(tester, 'one');
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();
    expect(find.text('同时恢复关联联系人？'), findsOneWidget);
    expect(await db.personsDao.findById('zhang'), isNull);
    await tester.tap(find.text('同时恢复'));
    await tester.pumpAndSettle();
    expect(await db.personsDao.findById('zhang'), isNotNull);
    expect(await db.giftRecordsDao.findById('one'), isNotNull);
    expect(await db.giftRecordsDao.findById('three'), isNull);
  });

  recycleTest('联系人可按电话搜索，恢复联系人不恢复收支记录', (tester) async {
    final db = await database(deletePerson: true);
    await mount(tester, db);
    await tester.tap(find.text('联系人  1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '13800138000');
    await tester.pumpAndSettle();
    expect(find.text('张伟'), findsOneWidget);
    expect(find.text('关联 2 条已删除记录'), findsOneWidget);
    await reveal(tester, 'zhang');
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();
    expect(find.textContaining('相关收支记录仍留在回收站'), findsOneWidget);
    await tester.tap(find.text('恢复联系人'));
    await tester.pumpAndSettle();
    expect(await db.personsDao.findById('zhang'), isNotNull);
    expect(await db.giftRecordsDao.findById('one'), isNull);
    expect(await db.giftRecordsDao.findById('three'), isNull);
  });

  recycleTest('批量彻底删除可以取消，确认后保留对应联系人', (tester) async {
    final db = await database();
    await mount(tester, db);
    await selectAll(tester);
    await confirmPurge(tester);
    expect(find.text('彻底删除这 3 条记录？'), findsOneWidget);
    expect(find.text('对应联系人将保留。'), findsOneWidget);
    await tester.tap(find.text('取消').last);
    await tester.pumpAndSettle();
    expect(await db.giftRecordsDao.findByIdAny('one'), isNotNull);
    expect(find.text('已选择 3 项'), findsOneWidget);
    await confirmPurge(tester);
    await tester.tap(find.text('彻底删除').last);
    await tester.pumpAndSettle();
    expect(await db.giftRecordsDao.findByIdAny('one'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('two'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('three'), isNull);
    expect(await db.personsDao.findById('zhang'), isNotNull);
    expect(find.text('暂无已删除收支记录'), findsOneWidget);
  });

  recycleTest('彻底删除联系人明确提示并删除关联记录', (tester) async {
    final db = await database(deletePerson: true);
    await mount(tester, db);
    await tester.tap(find.text('联系人  1'));
    await tester.pumpAndSettle();
    await selectAll(tester);
    await confirmPurge(tester);
    expect(find.text('彻底删除这 1 位联系人？'), findsOneWidget);
    expect(find.textContaining('关联的 2 条记录'), findsOneWidget);
    await tester.tap(find.text('彻底删除').last);
    await tester.pumpAndSettle();
    expect(await db.personsDao.findByIdAny('zhang'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('one'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('three'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('two'), isNotNull);
  });

  recycleTest('确认期间关联数据变化时阻止扩大删除范围', (tester) async {
    final db = await database(deletePerson: true);
    await mount(tester, db);
    await tester.tap(find.text('联系人  1'));
    await tester.pumpAndSettle();
    await selectAll(tester);
    await confirmPurge(tester);
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion(
        recordId: const Value('new'),
        bookId: const Value('book'),
        personId: const Value('zhang'),
        amountCent: const Value(10000),
        occurredAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    await tester.tap(find.text('彻底删除').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('关联记录已变化'), findsOneWidget);
    expect(await db.personsDao.findByIdAny('zhang'), isNotNull);
    expect(await db.giftRecordsDao.findByIdAny('new'), isNotNull);
    expect(await db.giftRecordsDao.findByIdAny('one'), isNotNull);
  });

  recycleTest('切换分类清除选择，系统返回优先退出选择模式', (tester) async {
    final db = await database(deletePerson: true);
    await mount(tester, db);
    await tester.longPress(find.text('周敏'));
    await tester.pumpAndSettle();
    expect(find.text('已选择 1 项'), findsOneWidget);
    await tester.tap(find.text('联系人  1'));
    await tester.pumpAndSettle();
    expect(find.text('回收站'), findsOneWidget);
    expect(find.text('恢复 1 项'), findsNothing);
    await tester.tap(find.text('管理'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('回收站'), findsOneWidget);
    expect(find.text('管理'), findsOneWidget);
  });

  recycleTest('编辑保护开启时取消密码不修改记录', (tester) async {
    final db = await database();
    await EditProtectionService().setPassword(newPassword: '123456');
    await mount(tester, db);
    await reveal(tester, 'one');
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();
    expect(find.text('验证后继续操作'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect((await db.giftRecordsDao.findByIdAny('one'))!.deletedAt, isNotNull);
    expect(find.text('正在处理…'), findsNothing);
  });

  recycleTest('窄屏深色与放大字体下长姓名和最大金额不溢出', (tester) async {
    final db = await database(longText: true);
    await mount(tester, db, dark: true);
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await reveal(tester, 'one');
    expect(find.text('恢复'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (Platform.environment['UPDATE_FORUI_PREVIEWS'] == 'true') {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          Uri.file(
            File('docs/design/recycle-bin/implemented-dark-swipe.png')
                .absolute
                .path,
          ),
        ),
      );
    }
    await selectAll(tester);
    expect(tester.takeException(), isNull);
    await confirmPurge(tester);
    expect(tester.takeException(), isNull);
  });

  recycleTest('点按不展开详情，左滑仅显示按钮，恢复只处理当前记录', (tester) async {
    final db = await database();
    await mount(tester, db);
    await tester.tap(find.text('周敏'));
    await tester.pumpAndSettle();
    expect(find.text('恢复'), findsNothing);
    expect(find.text('删除'), findsNothing);
    expect(find.text('已删除的记录'), findsNothing);
    await reveal(tester, 'two');
    expect(find.text('恢复'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect((await db.giftRecordsDao.findByIdAny('two'))!.deletedAt, isNotNull);
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();
    expect((await db.giftRecordsDao.findByIdAny('two'))!.deletedAt, isNull);
    expect((await db.giftRecordsDao.findByIdAny('one'))!.deletedAt, isNotNull);
    expect(find.text('恢复'), findsNothing);
  });

  recycleTest('左滑删除必须确认，取消保留数据，确认仅删除当前项', (tester) async {
    final db = await database();
    await mount(tester, db);
    await reveal(tester, 'two');
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('彻底删除这 1 条记录？'), findsOneWidget);
    expect(find.text('对应联系人将保留。'), findsOneWidget);
    await tester.tap(find.text('取消').last);
    await tester.pumpAndSettle();
    expect(await db.giftRecordsDao.findByIdAny('two'), isNotNull);
    await reveal(tester, 'two');
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('彻底删除').last);
    await tester.pumpAndSettle();
    expect(await db.giftRecordsDao.findByIdAny('two'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('one'), isNotNull);
    expect(await db.personsDao.findById('zhou'), isNotNull);
  });

  recycleTest('仅展开一行，右滑与系统返回收起，搜索和多选清除滑动状态', (tester) async {
    final db = await database();
    await mount(tester, db);
    await reveal(tester, 'one');
    await reveal(tester, 'two');
    expect(find.text('恢复'), findsOneWidget);
    // The action belongs to the newly opened row, not the previous one.
    expect(
      tester.getCenter(find.text('恢复')).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('recycle-row-two'))).dy,
      ),
    );
    await tester.dragFrom(
      tester.getTopLeft(find.byKey(const ValueKey('recycle-row-two'))) +
          const Offset(90, 25),
      const Offset(180, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('恢复'), findsNothing);
    await reveal(tester, 'one');
    await tester.tap(find.text('周敏'));
    await tester.pumpAndSettle();
    expect(find.text('恢复'), findsNothing);
    await reveal(tester, 'one');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('回收站'), findsOneWidget);
    expect(find.text('恢复'), findsNothing);
    await reveal(tester, 'one');
    await tester.enterText(find.byType(EditableText), '周敏');
    await tester.pumpAndSettle();
    expect(find.text('恢复'), findsNothing);
    await reveal(tester, 'two');
    await tester.tap(find.text('管理'));
    await tester.pumpAndSettle();
    await reveal(tester, 'two');
    expect(find.text('恢复'), findsNothing);
    expect(find.text('删除'), findsNothing);
  });

  recycleTest('整行滑到底不执行删除，纵向滚动收起操作', (tester) async {
    final db = await database();
    await mount(tester, db);
    await tester.timedDrag(
      find.byKey(const ValueKey('recycle-row-two')),
      const Offset(-24, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(find.text('恢复'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('recycle-row-two')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(await db.giftRecordsDao.findByIdAny('two'), isNotNull);
    expect(find.text('删除'), findsOneWidget);
    await tester.dragFrom(
      tester.getTopLeft(find.byKey(const ValueKey('recycle-row-two'))) +
          const Offset(70, 25),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    expect(find.text('恢复'), findsNothing);
    expect(find.text('删除'), findsNothing);
    expect((await db.giftRecordsDao.findByIdAny('two'))!.deletedAt, isNotNull);
  });

  recycleTest('联系人左滑删除确认关联范围，切换分类收起操作', (tester) async {
    final db = await database(deletePerson: true);
    await mount(tester, db);
    await reveal(tester, 'two');
    await tester.tap(find.text('联系人  1'));
    await tester.pumpAndSettle();
    expect(find.text('恢复'), findsNothing);
    await reveal(tester, 'zhang');
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('彻底删除这 1 位联系人？'), findsOneWidget);
    expect(find.textContaining('关联的 2 条记录'), findsOneWidget);
    await tester.tap(find.text('彻底删除').last);
    await tester.pumpAndSettle();
    expect(await db.personsDao.findByIdAny('zhang'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('one'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('three'), isNull);
    expect(await db.giftRecordsDao.findByIdAny('two'), isNotNull);
  });

  recycleTest('生成有数据的回收站预览', (tester) async {
    final db = await database();
    final key = GlobalKey();
    await mount(tester, db, boundary: key);
    for (final state in ['browse', 'swipe', 'selection', 'confirmation']) {
      if (state == 'swipe') await reveal(tester, 'two');
      if (state == 'selection') await selectAll(tester);
      if (state == 'confirmation') await confirmPurge(tester);
      if (Platform.environment['UPDATE_FORUI_PREVIEWS'] == 'true') {
        await expectLater(
          state == 'confirmation' ? find.byType(MaterialApp) : find.byKey(key),
          matchesGoldenFile(
            Uri.file(
              File('docs/design/recycle-bin/implemented-$state.png')
                  .absolute
                  .path,
            ),
          ),
        );
      }
      expect(tester.takeException(), isNull);
    }
  });
}
