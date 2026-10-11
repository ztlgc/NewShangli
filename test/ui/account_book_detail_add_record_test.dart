import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/account_book_detail_page.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';

import '../support/preview_fonts.dart';

void main() {
  setUpAll(loadForuiPreviewFonts);
  for (final selected in ['default', 'other', 'empty', 'book_default']) {
    testWidgets('账簿详情新增：$selected 的账簿事由日期锁定并正确保存', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final previewKey = GlobalKey();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final bookDate = DateTime(2020, 3, 8, 9, 30).millisecondsSinceEpoch;
      try {
        for (final id in ['default', 'other', 'empty', 'book_default']) {
          await db.accountBooksDao.insertOne(
            AccountBooksCompanion.insert(
              bookId: Value(id),
              name: '$id礼金',
              reasonType: Value(id == 'empty' ? '' : '$id事由'),
              bookTime: Value(bookDate),
              createdAt: 1,
              updatedAt: 1,
            ),
          );
        }
        await db.personsDao.insertOne(
          PersonsCompanion.insert(
            personId: const Value('p1'),
            bookId: 'default',
            name: '李四',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
        // Locked empty reason must not be replaced by a globally available reason.
        await db.reasonsDao.create(name: '其他事由');
        await tester.pumpWidget(
          RepaintBoundary(
            key: previewKey,
            child: AppDatabaseScope(
              db: db,
              child: MaterialApp(home: AccountBookDetailPage(bookId: selected)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('导出 PDF'), findsNothing);
        await tester.tap(find.text('新增记录'));
        await tester.pumpAndSettle();
        expect(find.byType(RecordAddPage), findsOneWidget);
        final previewDirectory = Platform.environment['LEDGER_PDF_PREVIEW_DIR'];
        if (previewDirectory != null && selected == 'other') {
          await expectLater(
            find.byKey(previewKey),
            matchesGoldenFile(
              Uri.file('$previewDirectory/account-book-add-locked.png'),
            ),
          );
        }
        for (final label in ['账簿', '事由', '日期']) {
          expect(find.bySemanticsLabel(RegExp('$label，已锁定')), findsOneWidget);
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        expect(find.text('选择所属账簿'), findsNothing);
        expect(find.text('选择事由'), findsNothing);
        expect(find.text('其他事由'), findsNothing);
        expect(find.byType(CalendarDatePicker), findsNothing);
        expect(
          find.text(selected == 'empty' ? '未设置' : '$selected事由'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('联系人'));
        await tester.tap(find.text('联系人'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('李四'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('200'));
        await tester.tap(find.text('200'));
        await tester.pump();
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();
        expect(find.byType(RecordAddPage), findsNothing);
        final saved = await db.select(db.giftRecords).getSingle();
        expect(saved.bookId, selected);
        expect(saved.eventName, selected == 'empty' ? '' : '$selected事由');
        expect(saved.occurredAt, bookDate);
        expect(saved.personId, 'p1');
        expect(saved.amountCent, 20000);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        await db.close();
        semantics.dispose();
      }
    });
  }
}
