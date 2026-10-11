import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/tab_shell.dart';
import 'package:newshangli/ui/pages/account_book_data_import_page.dart';
import 'package:newshangli/ui/pages/account_book_detail_page.dart';
import 'package:newshangli/ui/pages/account_book_edit_page.dart';
import 'package:newshangli/ui/pages/account_book_records_page.dart';
import 'package:newshangli/ui/pages/account_books_page.dart';
import 'package:newshangli/ui/pages/contact_relation_edit_page.dart';
import 'package:newshangli/ui/pages/data_backup_page.dart';
import 'package:newshangli/ui/pages/data_export_page.dart';
import 'package:newshangli/ui/pages/data_import_page.dart';
import 'package:newshangli/ui/pages/edit_protection_page.dart';
import 'package:newshangli/ui/pages/person_edit_page.dart';
import 'package:newshangli/ui/pages/person_detail_page.dart';
import 'package:newshangli/ui/pages/reason_detail_page.dart';
import 'package:newshangli/ui/pages/reason_manage_page.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';
import 'package:newshangli/ui/pages/record_detail_page.dart';
import 'package:newshangli/ui/pages/recycle_bin_page.dart';
import 'package:newshangli/ui/pages/relation_type_manage_page.dart';
import 'package:newshangli/ui/pages/relation_type_detail_page.dart';

import '../support/preview_fonts.dart';

final _updatePreviews = Platform.environment['UPDATE_FORUI_PREVIEWS'] == 'true';

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

Future<void> _capturePreview(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String slug,
) async {
  final file = File('docs/forui-preview/$slug.png').absolute;
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile(Uri.file(file.path)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDirectory;
  late PathProviderPlatform previousPathProvider;
  setUpAll(() async {
    await loadForuiPreviewFonts();
    tempDirectory = await Directory.systemTemp.createTemp(
      'newshangli_ui_preview_',
    );
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPaths(tempDirectory.path);
    SharedPreferences.setMockInitialValues({});
  });
  tearDownAll(() async {
    PathProviderPlatform.instance = previousPathProvider;
    try {
      await tempDirectory.delete(recursive: true);
    } on FileSystemException {
      // Windows may keep a short-lived SQLite/media handle open after the
      // widget tree is disposed. The OS temp directory can remove it later.
    }
  });

  testWidgets('secondary pages render at 360 pixels with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final previewKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: NewShangliApp(
          databaseFactory: () =>
              AppDatabase.forTesting(NativeDatabase.memory()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    final db = AppDatabaseScope.of(tester.element(find.byType(MainTabShell)));
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion(
        bookId: const Value('responsive-book'),
        name: const Value('响应式账簿'),
        reasonType: const Value(''),
        themeColor: const Value('#111827'),
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion(
        personId: const Value('responsive-person'),
        bookId: const Value('responsive-book'),
        name: const Value('测试联系人'),
        relationshipType: const Value('朋友'),
      ),
    );
    await db.relationTypesDao.create(name: '测试关系');
    final relationType = (await db.relationTypesDao.listAll()).firstWhere(
      (type) => type.name == '测试关系',
    );

    final pages = <(String, String, Widget)>[
      ('账簿管理', 'account-books', const AccountBooksPage()),
      ('编辑账簿', 'account-book-edit', const AccountBookEditPage()),
      (
        '账簿详情',
        'account-book-detail',
        const AccountBookDetailPage(bookId: 'responsive-book'),
      ),
      (
        '账簿记录',
        'account-book-records',
        const AccountBookRecordsPage(
          bookId: 'responsive-book',
          bookName: '响应式账簿',
          isDefaultBook: false,
        ),
      ),
      (
        '账簿导入',
        'account-book-data-import',
        const AccountBookDataImportPage(
          bookId: 'responsive-book',
          bookName: '响应式账簿',
        ),
      ),
      ('事由管理', 'reason-manage', const ReasonManagePage()),
      ('新增事由', 'reason-detail-create', const ReasonDetailPage.create()),
      ('关系类型', 'relation-type-manage', const RelationTypeManagePage()),
      (
        '关系类型详情',
        'relation-type-detail',
        RelationTypeDetailPage(type: relationType),
      ),
      ('新增关系', 'contact-relation-edit', const ContactRelationEditPage.create()),
      ('新增关系人', 'person-edit', const PersonEditPage()),
      (
        '关系人详情',
        'person-detail',
        const PersonDetailPage(personId: 'responsive-person'),
      ),
      ('新增记录', 'record-add', const RecordAddPage()),
      (
        '记录详情缺失态',
        'record-detail-missing',
        const RecordDetailPage(recordId: 'missing-record'),
      ),
      ('编辑保护', 'edit-protection', const EditProtectionPage()),
      ('回收站', 'recycle-bin', const RecycleBinPage()),
      ('数据导入', 'data-import', const DataImportPage()),
      ('数据导出', 'data-export', const DataExportPage()),
      ('数据备份', 'data-backup', const DataBackupPage()),
    ];

    for (final (name, _, page) in pages) {
      navigator.push<void>(MaterialPageRoute(builder: (_) => page));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: name);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: '$name 关闭后');
    }

    if (_updatePreviews) {
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      tester.view.physicalSize = const Size(430, 900);
      await tester.pumpAndSettle();
      for (final (name, slug, page) in pages) {
        navigator.push<void>(MaterialPageRoute(builder: (_) => page));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: '$name 预览');
        await _capturePreview(tester, previewKey, slug);
        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
