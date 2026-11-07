import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/pages/person_edit_page.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';
import 'package:newshangli/ui/ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/preview_fonts.dart';

Finder _amountPreset(String label) => find.descendant(
  of: find.byType(PressableScale),
  matching: find.text(label),
);

BoxDecoration _presetDecoration(WidgetTester tester, String label) =>
    tester
            .widget<Container>(
              find
                  .ancestor(
                    of: _amountPreset(label),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

Future<AppDatabase> _buildDb({bool includeOtherBook = false}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.accountBooksDao.insertOne(
    AccountBooksCompanion(
      bookId: const Value('book_default'),
      name: const Value('默认账簿'),
      reasonType: const Value(''),
      themeColor: const Value('#312E81'),
      isDefault: const Value(1),
    ),
  );
  if (includeOtherBook) {
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('book_other_for_test'),
        name: const Value('其他账簿'),
        reasonType: const Value(''),
        themeColor: const Value('#111827'),
      ),
    );
  }
  await db.personsDao.insertOne(
    PersonsCompanion(
      personId: const Value('p1'),
      bookId: const Value('book_default'),
      name: const Value('测试联系人'),
      relationshipType: const Value('朋友'),
      phone: const Value('13800000000'),
      avatarUri: const Value(null),
      note: const Value(null),
      birthday: const Value(null),
      anniversary: const Value(null),
      deletedAt: const Value(null),
    ),
  );
  await db.reasonsDao.create(name: '测试事由');
  return db;
}

Future<int> _recordCount(AppDatabase db) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS c FROM gift_record;')
      .getSingle();
  return row.data['c'] as int? ?? 0;
}

Future<void> _resetEditProtection() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EditProtectionConfig.save(
    const EditProtectionConfig(
      enabled: false,
      passwordSalt: '',
      passwordHash: '',
    ),
  );
}

void main() {
  setUpAll(loadForuiPreviewFonts);

  testWidgets('编辑金额：连续切换快捷金额及手动输入后高亮跟随当前金额', (tester) async {
    await _resetEditProtection();
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await _buildDb();
    addTearDown(db.close);
    final recordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion(
        bookId: const Value('book_default'),
        personId: const Value('p1'),
        amountCent: const Value(12345),
        eventName: const Value('测试事由'),
        occurredAt: Value(DateTime(2026, 10, 28).millisecondsSinceEpoch),
      ),
    );
    final previewKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: AppDatabaseScope(
          db: db,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: RecordAddPage(recordId: recordId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final unselected = _presetDecoration(tester, '200');
    final unselectedTextColor = tester
        .widget<Text>(_amountPreset('200'))
        .style!
        .color;
    for (final label in ['200', '500', '1000', '200']) {
      await tester.tap(_amountPreset(label));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        label,
      );
      for (final preset in ['200', '500', '1000']) {
        final decoration = _presetDecoration(tester, preset);
        expect(
          tester.widget<Text>(_amountPreset(preset)).style!.color,
          preset == label ? isNot(unselectedTextColor) : unselectedTextColor,
          reason: '点击 $label 后，$preset 的文字应匹配选中状态',
        );
        expect(
          decoration.border,
          preset == label ? isNot(unselected.border) : unselected.border,
          reason: '点击 $label 后，$preset 的边框应匹配选中状态',
        );
      }
      final previewDirectory = Platform.environment['AMOUNT_PREVIEW_DIR'];
      if (previewDirectory != null && label == '500') {
        await expectLater(
          find.byKey(previewKey),
          matchesGoldenFile(Uri.file('$previewDirectory/amount-500.png')),
        );
      }
    }
    await tester.enterText(find.byType(EditableText).first, '123.45');
    await tester.pumpAndSettle();
    for (final preset in ['200', '500', '1000']) {
      expect(_presetDecoration(tester, preset).border, unselected.border);
    }
    await tester.enterText(find.byType(EditableText).first, '500');
    await tester.pumpAndSettle();
    expect(_presetDecoration(tester, '500').border, isNot(unselected.border));
    expect(_presetDecoration(tester, '200').border, unselected.border);
    await tester.enterText(find.byType(EditableText).first, '');
    await tester.pumpAndSettle();
    expect(_presetDecoration(tester, '500').border, unselected.border);
    expect((await db.giftRecordsDao.findById(recordId))!.amountCent, 12345);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final editing in [false, true]) {
    testWidgets('${editing ? '编辑收支' : '记录收支'}：新增联系人保存后返回表单并选中新联系人', (
      tester,
    ) async {
      await _resetEditProtection();
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = await _buildDb();
      addTearDown(db.close);
      final date = DateTime(2026, 10, 2).millisecondsSinceEpoch;
      final recordId = editing
          ? await db.giftRecordsDao.insertOne(
              GiftRecordsCompanion(
                bookId: const Value('book_default'),
                personId: const Value('p1'),
                direction: const Value('支出'),
                amountCent: const Value(10000),
                eventName: const Value('测试事由'),
                occurredAt: Value(date),
                note: const Value('原有备注'),
              ),
            )
          : null;
      await tester.pumpWidget(
        AppDatabaseScope(
          db: db,
          child: MaterialApp(
            initialRoute: '/record',
            routes: {
              '/': (_) => const Scaffold(body: Text('收支列表')),
              '/record': (_) => RecordAddPage(recordId: recordId),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('200'));
      await tester.ensureVisible(find.byType(EditableText).last);
      await tester.enterText(find.byType(EditableText).last, '尚未保存的收支备注');
      await tester.ensureVisible(find.text('联系人'));
      await tester.tap(find.text('联系人'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加联系人'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonEditPage), findsOneWidget);
      await tester.tap(find.text('未设置').first);
      await tester.pumpAndSettle();
      // 编辑场景使用同名联系人，确保按新建 ID 选中，而不是按姓名匹配。
      final personName = editing ? '测试联系人' : '新建联系人';
      await tester.enterText(find.byType(EditableText), personName);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonEditPage), findsNothing);
      expect(find.byType(RecordAddPage), findsOneWidget);
      expect(find.text('选择联系人'), findsNothing);
      expect(find.text(personName), findsOneWidget);
      expect(find.text('200'), findsNWidgets(2));
      final newPerson = (await db.personsDao.listAll()).singleWhere(
        (person) => person.personId != 'p1',
      );
      await tester.ensureVisible(find.text('尚未保存的收支备注'));
      expect(find.text('尚未保存的收支备注'), findsOneWidget);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordAddPage), findsNothing);
      expect(find.text('收支列表'), findsOneWidget);
      final saved = await db.select(db.giftRecords).getSingle();
      expect(saved.personId, newPerson.personId);
      expect(saved.amountCent, 20000);
      expect(saved.note, '尚未保存的收支备注');
      expect(saved.bookId, 'book_default');
      expect(saved.eventName, '测试事由');
      if (editing) {
        expect(saved.recordId, recordId);
        expect(saved.direction, '支出');
        expect(saved.occurredAt, date);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('新增联系人：校验失败不返回，取消后保留原收支联系人', (tester) async {
    await _resetEditProtection();
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await _buildDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: const MaterialApp(home: RecordAddPage(initialPersonId: 'p1')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('200'));
    await tester.tap(find.text('联系人'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加联系人'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonEditPage), findsOneWidget);
    expect(find.text('姓名不能为空'), findsOneWidget);
    expect(await db.personsDao.listAll(), hasLength(1));

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonEditPage), findsNothing);
    expect(find.text('选择联系人'), findsOneWidget);
    Navigator.of(tester.element(find.text('选择联系人'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('测试联系人'), findsOneWidget);
    expect(find.text('200'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('编辑记录：加载完成后可查看金额、联系人、事由和备注', (tester) async {
    await _resetEditProtection();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await _buildDb();
    addTearDown(() async => db.close());
    final recordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion(
        recordId: const Value('r_full'),
        bookId: const Value('book_default'),
        personId: const Value('p1'),
        direction: const Value('支出'),
        amountCent: const Value(123456),
        currency: const Value('CNY'),
        eventName: const Value('完整记录事由'),
        occurredAt: Value(DateTime(2026, 9, 20).millisecondsSinceEpoch),
        note: const Value('这是一条需要在编辑页完整显示的备注'),
        attachments: const Value(null),
        deletedAt: const Value(null),
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(home: RecordAddPage(recordId: recordId)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('编辑收支'), findsOneWidget);
    expect(find.text('1234.56'), findsOneWidget);
    expect(find.text('测试联系人'), findsOneWidget);
    expect(find.text('完整记录事由'), findsOneWidget);
    expect(find.text('支付方式'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('这是一条需要在编辑页完整显示的备注'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('这是一条需要在编辑页完整显示的备注'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('编辑记录：账簿、联系人、和事由均可打开并选择', (tester) async {
    await _resetEditProtection();
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await _buildDb(includeOtherBook: true);
    addTearDown(() async => db.close());
    final recordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion(
        recordId: const Value('r_picker_regression'),
        bookId: const Value('book_default'),
        personId: const Value('p1'),
        direction: const Value('收入'),
        amountCent: const Value(10000),
        currency: const Value('CNY'),
        eventName: const Value('测试事由'),
        occurredAt: Value(DateTime(2026, 10, 2).millisecondsSinceEpoch),
        note: const Value(null),
        attachments: const Value(null),
        deletedAt: const Value(null),
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(home: RecordAddPage(recordId: recordId)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('账簿'));
    await tester.pumpAndSettle();
    expect(find.text('选择所属账簿'), findsOneWidget);
    final bookPanel = find
        .ancestor(of: find.text('选择所属账簿'), matching: find.byType(Material))
        .first;
    expect(tester.getRect(bookPanel).center, const Offset(215, 450));
    Navigator.of(tester.element(find.text('选择所属账簿'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('联系人'));
    await tester.pumpAndSettle();
    expect(find.text('选择联系人'), findsOneWidget);
    await tester.tap(find.text('测试联系人').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('事由'));
    await tester.pumpAndSettle();
    expect(find.text('选择事由'), findsOneWidget);
    await tester.tap(find.text('测试事由').last);
    await tester.pumpAndSettle();

    expect(find.text('支付方式'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('收支录入：保存后直接返回，不弹出放弃确认', (WidgetTester tester) async {
    await _resetEditProtection();
    final db = await _buildDb();
    addTearDown(() async => db.close());
    final initialCount = await _recordCount(db);

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const RecordAddPage(initialPersonId: 'p1'),
                      ),
                    ),
                    child: const Text('打开录入'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开录入'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RecordAddPage), findsOneWidget);

    await tester.tap(find.text('200'));
    await tester.pump();

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('放弃编辑？'), findsNothing);
    expect(find.byType(RecordAddPage), findsNothing);
    expect(await _recordCount(db), initialCount + 1);
  });

  testWidgets('收支录入：编辑记录保存应保留原 bookId', (WidgetTester tester) async {
    await _resetEditProtection();
    final db = await _buildDb(includeOtherBook: true);
    addTearDown(() async => db.close());
    final recordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion(
        recordId: const Value('r1'),
        bookId: const Value('book_other_for_test'),
        personId: const Value('p1'),
        direction: const Value('收入'),
        amountCent: const Value(100),
        currency: const Value('CNY'),
        eventName: const Value('其他账簿记录_仅测试'),
        occurredAt: Value(DateTime(2099, 1, 2, 12, 0).millisecondsSinceEpoch),
        note: const Value(null),
        attachments: const Value(null),
        deletedAt: const Value(null),
      ),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecordAddPage(recordId: recordId),
                      ),
                    ),
                    child: const Text('打开编辑'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开编辑'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byType(RecordAddPage), findsOneWidget);
    expect(find.text('金额 (元)'), findsOneWidget);

    await tester.tap(find.text('200'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final updated = await db.giftRecordsDao.findByIdAny(recordId);
    expect(updated, isNotNull);
    expect(updated!.bookId, 'book_other_for_test');
  });
}
