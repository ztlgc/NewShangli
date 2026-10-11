import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/platform/app_platform.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/data_import_page.dart';

class _PickerAdapter implements AppPlatformAdapter {
  _PickerAdapter(this.result);
  final AppPickedFiles? result;
  List<String>? requestedExtensions;
  @override
  Future<AppPickedFiles?> pickFiles({
    required List<String> allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
  }) async {
    requestedExtensions = allowedExtensions;
    return result;
  }

  @override
  Future<Directory> documentsDirectory() => throw UnimplementedError();
  @override
  Future<Directory> temporaryDirectory() => throw UnimplementedError();
  @override
  Future<String?> pickDirectory({String? dialogTitle}) async => null;
  @override
  Future<void> shareFile(String path, {required String text}) async {}
}

void main() {
  for (final cancel in [false, true]) {
    testWidgets(cancel ? '取消系统选文件不改变导入状态或礼账' : '平台选择器返回 CSV 后可预览且尚未写入礼账', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final temp = Directory.systemTemp.createTempSync('shangli_picker_test_');
      final csv =
          File([temp.path, 'migration.csv'].join(Platform.pathSeparator))
            ..writeAsStringSync(
              '联系人姓名,金额(元),收支方向,事由,发生时间\n迁移测试联系人,100,收入,婚礼,2026-10-10\n',
            );
      addTearDown(() => temp.deleteSync(recursive: true));
      final original = AppPlatform.instance;
      final picker = _PickerAdapter(
        cancel
            ? null
            : AppPickedFiles([
                AppPickedFile(
                  name: 'migration.csv',
                  size: csv.lengthSync(),
                  path: csv.path,
                ),
              ]),
      );
      AppPlatform.instance = picker;
      addTearDown(() => AppPlatform.instance = original);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const bookId = 'platform_import_book';
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          bookId: const Value(bookId),
          name: '平台测试账簿',
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
      await tester.runAsync(() async {
        await tester.tap(find.text('点击选择 Excel 或 CSV 文件'));
        // Let the real file read complete outside the widget test's fake clock.
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(picker.requestedExtensions, ['xlsx', 'csv']);
      if (cancel) {
        expect(find.text('点击选择 Excel 或 CSV 文件'), findsOneWidget);
        expect(find.textContaining('migration.csv'), findsNothing);
      } else {
        expect(find.textContaining('migration.csv'), findsWidgets);
        expect(find.text('迁移测试联系人'), findsOneWidget);
      }
      expect(await db.select(db.giftRecords).get(), isEmpty);
      expect(await db.select(db.persons).get(), isEmpty);
      expect(await db.select(db.dataImportJobs).get(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
