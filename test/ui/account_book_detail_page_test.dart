import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/platform/app_platform.dart';
import 'package:newshangli/platform/flutter_platform_adapter.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/app_toast.dart';
import 'package:newshangli/ui/pages/account_book_detail_page.dart';

import '../support/preview_fonts.dart';

class _PdfPlatform extends FlutterPlatformAdapter {
  _PdfPlatform(this.directory);
  final Directory directory;
  String? sharedPath;
  int shareAttempts = 0;
  bool failSharing = false;
  bool failSaving = false;
  @override
  Future<Directory> documentsDirectory() async {
    if (failSaving) throw const FileSystemException('保存位置不可用');
    return directory;
  }

  @override
  Future<void> shareFile(String path, {required String text}) async {
    shareAttempts++;
    if (failSharing) throw StateError('分享不可用');
    sharedPath = path;
  }
}

Future<void> _action(
  WidgetTester tester,
  String label, {
  GlobalKey? previewKey,
}) async {
  await tester.tap(find.bySemanticsLabel('账簿导入导出'));
  await tester.pumpAndSettle();
  final previewDirectory = Platform.environment['LEDGER_PDF_PREVIEW_DIR'];
  if (previewDirectory != null && previewKey != null) {
    await expectLater(
      find.byKey(previewKey),
      matchesGoldenFile(
        Uri.file('$previewDirectory/account-book-transfer-menu.png'),
      ),
    );
  }
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(loadForuiPreviewFonts);
  testWidgets('账簿详情导出真实 PDF，支持分享和分享失败重试', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final previewKey = GlobalKey();
    final semantics = tester.ensureSemantics();
    final directory = Directory.systemTemp.createTempSync('ledger_pdf_ui_');
    final platform = _PdfPlatform(directory);
    final previous = AppPlatform.instance;
    AppPlatform.instance = platform;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      const bookId = 'book_1';
      const personId = 'person_1';

      await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          bookId: const Value(bookId),
          name: '礼金账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.personsDao.insertOne(
        PersonsCompanion.insert(
          personId: const Value(personId),
          bookId: bookId,
          name: '李四',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: bookId,
          personId: personId,
          amountCent: 88800,
          direction: const Value('收入'),
          eventName: const Value('结婚礼金'),
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        RepaintBoundary(
          key: previewKey,
          child: AppSessionScope(
            session: AppSession(),
            child: AppDatabaseScope(
              db: db,
              child: const MaterialApp(
                home: AccountBookDetailPage(bookId: bookId),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('总收入'), findsOneWidget);
      expect(find.text('记录数量'), findsOneWidget);
      expect(find.bySemanticsLabel('返回上一页'), findsOneWidget);
      expect(find.bySemanticsLabel('账簿导入导出'), findsOneWidget);
      expect(find.bySemanticsLabel('添加附件'), findsOneWidget);
      expect(find.text('新增记录'), findsOneWidget);
      expect(find.text('导出 PDF'), findsNothing);
      expect(find.text('李四'), findsOneWidget);
      final previewDirectory = Platform.environment['LEDGER_PDF_PREVIEW_DIR'];
      if (previewDirectory != null) {
        await expectLater(
          find.byKey(previewKey),
          matchesGoldenFile(
            Uri.file('$previewDirectory/account-book-pdf-entry.png'),
          ),
        );
      }

      await _action(tester, '导出 PDF', previewKey: previewKey);
      await tester.pump();
      for (var i = 0; i < 30 && platform.sharedPath == null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('导出 PDF'), findsNothing);
      final files = directory
          .listSync(recursive: true)
          .whereType<File>()
          .toList();
      expect(files, hasLength(1));
      expect(
        String.fromCharCodes(files.single.readAsBytesSync().take(5)),
        '%PDF-',
      );
      await _action(tester, '分享 PDF');
      await tester.pumpAndSettle();
      expect(platform.sharedPath, files.single.path);

      platform.failSharing = true;
      await _action(tester, '分享 PDF');
      await tester.pumpAndSettle();
      expect(find.text('导出 PDF'), findsNothing);
      expect(files.single.existsSync(), isTrue);
      expect(tester.takeException(), isNull);
      AppToast.dismiss();
      await tester.pump(const Duration(milliseconds: 300));
      if (previewDirectory != null) {
        await expectLater(
          find.byKey(previewKey),
          matchesGoldenFile(
            Uri.file('$previewDirectory/account-book-pdf-saved.png'),
          ),
        );
      }

      platform.failSaving = true;
      final attempts = platform.shareAttempts;
      await _action(tester, '导出 PDF');
      await tester.pump();
      for (
        var i = 0;
        i < 30 && find.bySemanticsLabel('正在导出 PDF').evaluate().isNotEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.bySemanticsLabel('账簿导入导出'), findsOneWidget);
      expect(platform.shareAttempts, attempts);
      expect(files.single.existsSync(), isTrue);
      expect(
        directory.listSync(recursive: true).whereType<File>(),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      AppToast.dismiss();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
      semantics.dispose();
      AppPlatform.instance = previous;
      directory.deleteSync(recursive: true);
    }
  });
}
