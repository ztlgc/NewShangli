import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/platform/app_platform.dart';
import 'package:newshangli/platform/flutter_platform_adapter.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/app_toast.dart';
import 'package:newshangli/ui/pages/account_book_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MediaPlatform extends FlutterPlatformAdapter {
  _MediaPlatform(this.directory);
  final Directory directory;
  @override
  Future<Directory> documentsDirectory() async => directory;
}

void main() {
  for (final input in ['cancel', 'wrong', '1234']) {
    testWidgets('删除已有账簿附件校验密码：$input', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EditProtectionService().setPassword(newPassword: '1234');
      final directory = Directory.systemTemp.createTempSync(
        'attachment_guard_',
      );
      final file = File('${directory.path}/media/attachments/test.png');
      file.parent.createSync(recursive: true);
      final previous = AppPlatform.instance;
      AppPlatform.instance = _MediaPlatform(directory);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.accountBooksDao.insertOne(
          AccountBooksCompanion(
            bookId: const Value('protected_book'),
            name: const Value('protected'),
            attachments: Value([file.path]),
          ),
        );
        await tester.pumpWidget(
          AppSessionScope(
            session: AppSession(),
            child: AppDatabaseScope(
              db: db,
              child: const MaterialApp(
                home: AccountBookDetailPage(bookId: 'protected_book'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.bySemanticsLabel('删除附件'));
        await tester.tap(find.bySemanticsLabel('删除附件'));
        await tester.pumpAndSettle();
        expect(find.text('编辑密码'), findsOneWidget);
        if (input == 'cancel') {
          await tester.tap(find.text('取消'));
        } else {
          await tester.enterText(find.byType(EditableText), input);
          await tester.tap(find.text('确认'));
        }
        await tester.pumpAndSettle();
        expect(
          (await db.accountBooksDao.findById('protected_book'))!.attachments,
          [file.path],
        );
        if (input == '1234') {
          expect(find.text('确认删除该附件？'), findsOneWidget);
          await tester.tap(find.text('删除'));
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
          expect(
            (await db.accountBooksDao.findById('protected_book'))!.attachments,
            isNull,
          );
        } else {
          expect(find.text('确认删除该附件？'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      } finally {
        AppToast.dismiss();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await db.close();
        AppPlatform.instance = previous;
        await tester.runAsync(() async {
          for (var attempt = 0; ; attempt++) {
            try {
              await directory.delete(recursive: true);
              break;
            } on FileSystemException {
              if (attempt >= 50) rethrow;
              await Future<void>.delayed(const Duration(milliseconds: 20));
            }
          }
        });
      }
    });
  }
}
