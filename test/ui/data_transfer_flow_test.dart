import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/export/data_export_service.dart';
import 'package:newshangli/import/data_import_service.dart';
import 'package:newshangli/platform/app_platform.dart';
import 'package:newshangli/platform/flutter_platform_adapter.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_icons.dart';
import 'package:newshangli/ui/app_localizations.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/data_transfer/import_review_widgets.dart';
import 'package:newshangli/ui/pages/data_export_page.dart';
import 'package:newshangli/ui/pages/data_import_page.dart';

import '../support/preview_fonts.dart';
import '../support/transfer_test_data.dart';

class _TransferPlatform extends FlutterPlatformAdapter {
  _TransferPlatform(this.directory);
  final Directory directory;
  final picks = Queue<AppPickedFiles?>();
  final shared = <String>[];
  bool failShare = false;
  @override
  Future<Directory> documentsDirectory() async => directory;
  @override
  Future<Directory> temporaryDirectory() async => directory;
  @override
  Future<AppPickedFiles?> pickFiles({
    required List<String> allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
  }) async => picks.isEmpty ? null : picks.removeFirst();
  @override
  Future<void> shareFile(String path, {required String text}) async {
    shared.add(path);
    if (failShare) throw StateError('share unavailable');
  }

  void pick(File file) => picks.add(
    AppPickedFiles([
      AppPickedFile(
        name: file.uri.pathSegments.last,
        path: file.path,
        size: file.lengthSync(),
      ),
    ]),
  );
}

class _Fixture {
  _Fixture(this.db, this.directory, this.platform);
  final AppDatabase db;
  final Directory directory;
  final _TransferPlatform platform;
  final key = GlobalKey();
  Future<void> page(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(393, 852),
    double scale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: AppDatabaseScope(
          db: db,
          child: RepaintBoundary(key: key, child: page),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final directory = Platform.environment['TRANSFER_PREVIEW_DIR'];
    if (directory == null) return;
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      await Directory(directory).create(recursive: true);
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$directory/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }
}

Future<void> _until(WidgetTester tester, bool Function() condition) async {
  for (var index = 0; index < 500; index++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 30));
    if (condition()) return;
  }
  fail('The expected transfer state was not reached');
}

bool _has(String text) => find.text(text).evaluate().isNotEmpty;

void _flow(String name, Future<void> Function(WidgetTester, _Fixture) body) {
  testWidgets(name, (tester) async {
    final directory = Directory.systemTemp.createTempSync('data_transfer_ui_');
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() => seedTransferData(db, directory));
    final previous = AppPlatform.instance;
    final platform = _TransferPlatform(directory);
    AppPlatform.instance = platform;
    try {
      await body(tester, _Fixture(db, directory, platform));
    } finally {
      for (var round = 0; round < 4; round++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 6));
      for (var round = 0; round < 4; round++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.runAsync(db.close);
      await tester.pump(const Duration(seconds: 1));
      AppPlatform.instance = previous;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 5; attempt++) {
          try {
            await directory.delete(recursive: true);
            return;
          } on FileSystemException {
            if (attempt == 4) rethrow;
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        }
      });
    }
  });
}

void main() {
  setUpAll(loadForuiPreviewFonts);

  _flow(
    'import mapping applies explicit ignore and a double tap creates one real job',
    (tester, f) async {
      final csv = writeTransferCsv(f.directory, aliases: true);
      f.platform.pick(csv);
      await f.page(tester, const DataImportPage(initialBookId: 'default'));
      await tester.tap(find.text('点击选择 Excel 或 CSV 文件'));
      await _until(tester, () => _has('字段匹配'));
      expect(await f.db.select(f.db.dataImportJobs).get(), isEmpty);
      f.platform.picks.add(null);
      await tester.tap(find.text('更换'));
      await _until(tester, () => _has('字段匹配'));
      expect(find.text(csv.uri.pathSegments.last), findsOneWidget);
      await tester.tap(find.text('字段匹配'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('import_mapping_备注')),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ImportMappingSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('import_mapping_备注')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('不导入').hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('应用匹配'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('开始导入'));
      await tester.tap(find.text('开始导入'), warnIfMissed: false);
      await _until(tester, () => _has('导入完成'));
      final jobs = await f.db.select(f.db.dataImportJobs).get();
      expect(jobs, hasLength(1));
      expect(jobs.single.successRows, 2);
      final rows = await f.db.giftRecordsDao.listAllWithPersonInAllBooks();
      final imported = rows
          .where((row) => row.person.name.startsWith('测试联系人'))
          .toList();
      expect(imported, hasLength(2));
      expect(imported.every((row) => (row.record.note ?? '').isEmpty), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  _flow(
    'full preview exposes all columns and optional ZIP can be selected and removed',
    (tester, f) async {
      final csv = File('${f.directory.path}/wide.csv')
        ..writeAsStringSync(
          [
            '数据类型,联系人姓名,收支方向,金额(元),发生时间,备注,额外1,额外2,额外3,额外4,额外5,最后一列',
            for (var i = 0; i < 25; i++)
              '礼金收支记录,预览$i,收入,100,2026-10-01,备注,a,b,c,d,e,末列$i',
          ].join('\n'),
        );
      final zip = File('${f.directory.path}/images.zip')
        ..writeAsBytesSync(ZipEncoder().encode(Archive())!);
      f.platform.pick(csv);
      f.platform.pick(zip);
      await f.page(tester, const DataImportPage(initialBookId: 'default'));
      await tester.tap(find.text('点击选择 Excel 或 CSV 文件'));
      await _until(tester, () => _has('数据预览'));
      await tester.tap(find.text('数据预览'));
      await tester.pumpAndSettle();
      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.columns, hasLength(12));
      expect(table.rows, hasLength(20));
      await tester.tap(find.byIcon(AppIcons.x).hitTestable().last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(ImportMediaCard));
      await tester.tap(find.text('头像与附件'));
      await _until(tester, () => _has('images.zip'));
      await tester.tap(find.bySemanticsLabel('移除图片 ZIP'));
      await tester.pump();
      expect(find.text('images.zip'), findsNothing);
      expect(await f.db.select(f.db.dataImportJobs).get(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  _flow('duplicate dialog skip and keep decisions affect the actual records', (
    tester,
    f,
  ) async {
    final csv = File('${f.directory.path}/duplicate.csv')
      ..writeAsStringSync(
        '数据类型,记录ID,联系人ID,联系人姓名,收支方向,金额(元),发生时间\n礼金收支记录,r1,p1,张伟,收入,1000,2026-10-01',
      );
    f.platform.pick(csv);
    f.platform.pick(csv);
    await f.page(tester, const DataImportPage(initialBookId: 'default'));
    await tester.tap(find.text('点击选择 Excel 或 CSV 文件'));
    await _until(tester, () => _has('字段匹配'));
    await tester.tap(find.text('开始导入'));
    await _until(tester, () => _has('疑似重复记录'));
    await tester.tap(find.text('跳过').hitTestable().last);
    await _until(tester, () => _has('导入完成'));
    expect(await f.db.select(f.db.giftRecords).get(), hasLength(3));
    expect(
      (await f.db.select(f.db.dataImportJobs).get()).single.skippedRows,
      1,
    );
    await tester.tap(find.text('选择其他文件'));
    await _until(tester, () => _has('字段匹配'));
    await tester.tap(find.text('开始导入'));
    await _until(tester, () => _has('疑似重复记录'));
    await tester.tap(find.text('保留').hitTestable().last);
    await _until(tester, () => _has('导入完成'));
    expect(await f.db.select(f.db.giftRecords).get(), hasLength(4));
    expect(tester.takeException(), isNull);
  });

  _flow('history resumes the same saved checkpoint without recreating a job', (
    tester,
    f,
  ) async {
    final csv = writeTransferCsv(f.directory);
    final service = DataImportService(
      db: f.db,
      documentsDirectoryProvider: () async => f.directory,
    );
    final jobId = await tester.runAsync(
      () => service.createJob(
        bookId: 'default',
        sourceFilePath: csv.path,
        kind: DataImportKind.recordsAndPersons,
      ),
    );
    final saved = (await f.db.dataImportJobsDao.findById(jobId!))!;
    await f.db.dataImportJobsDao.updateOne(
      saved.copyWith(
        status: DataImportStatus.paused.name,
        lastRowIndex: 1,
        processedRows: 1,
        successRows: 1,
      ),
    );
    await f.db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value('resume-first'),
        bookId: 'default',
        name: '测试联系人0',
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    await f.db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        recordId: const Value('resume-record'),
        bookId: 'default',
        personId: 'resume-first',
        amountCent: 10025,
        occurredAt: DateTime(2026, 10, 1).millisecondsSinceEpoch,
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    await f.page(tester, const DataImportPage(initialBookId: 'default'));
    await tester.tap(find.text('历史'));
    await _until(tester, () => _has('继续'));
    await tester.tap(find.text('继续'));
    await _until(tester, () => _has('导入完成'));
    final jobs = await f.db.select(f.db.dataImportJobs).get();
    expect(jobs, hasLength(1));
    expect(jobs.single.jobId, jobId);
    expect(jobs.single.processedRows, 2);
    expect(jobs.single.successRows, 2);
    expect(await f.db.select(f.db.giftRecords).get(), hasLength(5));
    expect(tester.takeException(), isNull);
  });

  for (final cancel in [false, true]) {
    _flow(
      cancel
          ? 'cancel during a pending import decision ends as canceled'
          : 'pause and continue retain the same job and checkpoint',
      (tester, f) async {
        final csv = File('${f.directory.path}/controlled.csv')
          ..writeAsStringSync(
            '数据类型,记录ID,联系人ID,联系人姓名,收支方向,金额(元),发生时间\n'
            '礼金收支记录,r1,p1,张伟,收入,1000,2026-10-01\n'
            '礼金收支记录,,,暂停后联系人,收入,200,2026-10-02',
          );
        final service = _GateImportService(f.db, f.directory);
        f.platform.pick(csv);
        await f.page(
          tester,
          DataImportPage(
            initialBookId: 'default',
            serviceFactory: (_) => service,
          ),
        );
        await tester.tap(find.text('点击选择 Excel 或 CSV 文件'));
        await _until(tester, () => _has('字段匹配'));
        await tester.tap(find.text('开始导入'));
        await _until(tester, () => service.entered.isCompleted);
        if (cancel) {
          await tester.tap(find.text('取消导入'));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.tap(find.text('取消导入').hitTestable().last);
          await tester.pump(const Duration(milliseconds: 250));
        } else {
          await tester.tap(find.text('暂停'));
          await tester.pump();
        }
        service.release.complete(false);
        await _until(tester, () => _has(cancel ? '已取消' : '已暂停'));
        final paused = (await f.db.select(f.db.dataImportJobs).get()).single;
        expect(
          paused.status,
          cancel
              ? DataImportStatus.canceled.name
              : DataImportStatus.paused.name,
        );
        expect(await f.db.select(f.db.giftRecords).get(), hasLength(3));
        if (!cancel) {
          await tester.tap(find.text('继续导入'));
          await _until(tester, () => _has('导入完成'));
          final complete =
              (await f.db.select(f.db.dataImportJobs).get()).single;
          expect(complete.jobId, paused.jobId);
          expect(complete.processedRows, 2);
          expect(await f.db.select(f.db.giftRecords).get(), hasLength(4));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  _flow('download template shares a real generated CSV', (tester, f) async {
    await f.page(tester, const DataImportPage(initialBookId: 'default'));
    await tester.tap(find.text('下载模板'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSV 模板 (.csv)'));
    await _until(tester, () => f.platform.shared.isNotEmpty);
    expect(File(f.platform.shared.single).readAsStringSync(), contains('数据类型'));
    expect(tester.takeException(), isNull);
  });

  _flow(
    'book filtering, ZIP creation and sharing use the same actual export scope',
    (tester, f) async {
      await f.page(tester, const DataExportPage());
      await _until(tester, () => _has('共 3 条记录'));
      await tester.tap(find.text('账簿'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('日常礼账'));
      await _until(tester, () => _has('共 2 条记录'));
      await tester.tap(find.text('ZIP 压缩包'));
      await tester.pump();
      await tester.tap(find.text('开始导出'));
      await _until(tester, () => _has('导出完成'));
      await tester.tap(find.text('分享文件'));
      await _until(tester, () => f.platform.shared.isNotEmpty);
      final file = File(f.platform.shared.single);
      final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
      expect(
        archive.files.any((entry) => entry.name.startsWith('media/avatars/')),
        isTrue,
      );
      expect(
        archive.files.any(
          (entry) => entry.name.startsWith('media/attachments/'),
        ),
        isTrue,
      );
      final workbook = archive.files.singleWhere(
        (entry) => entry.name.endsWith('.xlsx'),
      );
      expect(
        Excel.decodeBytes(workbook.content as List<int>).tables['礼金记录']!.rows,
        hasLength(3),
      );
      await tester.tap(find.text('Excel 表格'));
      await tester.pump();
      expect(find.text('导出完成'), findsNothing);
      expect(find.text('开始导出'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  _flow(
    'export date cancellation preserves the old range and confirmation filters rows',
    (tester, f) async {
      await f.page(tester, const DataExportPage());
      await _until(tester, () => _has('共 3 条记录'));
      await tester.tap(find.text('日期范围'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('自定义时间'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('所有时间'), findsOneWidget);
      expect(find.text('共 3 条记录'), findsOneWidget);
      await tester.tap(find.text('日期范围'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('自定义时间'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(280, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30').hitTestable().first);
      await tester.tap(find.text('确定'));
      await _until(tester, () => _has('共 1 条记录'));
      expect(find.text('自定义时间'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  _flow(
    'failed export can retry, busy taps are ignored, and failed share keeps its file',
    (tester, f) async {
      final service = _GateExportService();
      await f.page(tester, DataExportPage(service: service));
      await _until(tester, () => _has('共 3 条记录'));
      await tester.tap(find.text('开始导出'));
      await tester.tap(find.text('开始导出'), warnIfMissed: false);
      await _until(tester, () => service.calls == 1);
      await tester.tap(find.text('账簿'));
      await tester.pump();
      expect(find.text('选择账簿'), findsNothing);
      service.release.complete();
      await _until(tester, () => _has('重试导出'));
      await tester.tap(find.text('重试导出'));
      await _until(tester, () => _has('导出完成'));
      expect(service.calls, 2);
      f.platform.failShare = true;
      await tester.tap(find.text('分享文件'));
      await _until(tester, () => _has('文件已生成，分享未完成，可重试分享'));
      f.platform.failShare = false;
      await tester.tap(find.text('分享文件'));
      await _until(tester, () => f.platform.shared.length == 2);
      expect(f.platform.shared[0], f.platform.shared[1]);
      expect(service.calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (name, size, scale, brightness) in [
    ('light', const Size(393, 852), 1.0, Brightness.light),
    ('dark', const Size(393, 852), 1.0, Brightness.dark),
    ('compact-large-text', const Size(360, 800), 1.3, Brightness.light),
    ('wide', const Size(800, 900), 1.0, Brightness.light),
  ]) {
    _flow('import and export layout: $name', (tester, f) async {
      final csv = writeTransferCsv(f.directory);
      f.platform.pick(csv);
      await f.page(
        tester,
        const DataImportPage(initialBookId: 'default'),
        size: size,
        scale: scale,
        brightness: brightness,
      );
      await tester.tap(find.text('点击选择 Excel 或 CSV 文件'));
      await _until(tester, () => _has('字段匹配'));
      await f.capture(tester, '$name-import');
      expect(tester.takeException(), isNull);
      await f.page(
        tester,
        const DataExportPage(),
        size: size,
        scale: scale,
        brightness: brightness,
      );
      await _until(tester, () => _has('共 3 条记录'));
      await tester.tap(find.text('ZIP 压缩包'));
      await tester.pump();
      await f.capture(tester, '$name-export');
      expect(tester.takeException(), isNull);
    });
  }
}

class _GateExportService extends DataExportService {
  int calls = 0;
  final release = Completer<void>();
  @override
  Future<File> exportFromDrift({
    required AppDatabase db,
    required DataExportRequest request,
    Directory? outputDir,
    void Function(DataExportSummary)? onPrepared,
  }) async {
    calls++;
    if (calls == 1) {
      await release.future;
      throw const DataExportException('测试导出失败');
    }
    return super.exportFromDrift(
      db: db,
      request: request,
      outputDir: outputDir,
      onPrepared: onPrepared,
    );
  }
}

class _GateImportService extends DataImportService {
  _GateImportService(AppDatabase db, Directory directory)
    : super(db: db, documentsDirectoryProvider: () async => directory);
  final entered = Completer<void>();
  final release = Completer<bool>();
  @override
  Future<DataImportRunHandle> start(
    String jobId, {
    ImportDuplicateDecision? onDuplicate,
  }) => super.start(
    jobId,
    onDuplicate: (duplicate) {
      if (!entered.isCompleted) {
        entered.complete();
        return release.future;
      }
      return onDuplicate?.call(duplicate) ?? Future.value(false);
    },
  );
}
