import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/export/data_export_service.dart';
import 'package:newshangli/import/data_import_service.dart';
import 'package:newshangli/import/import_field_mapping.dart';
import 'package:newshangli/import/import_file_reader.dart';

import '../support/transfer_test_data.dart';

void main() {
  late AppDatabase db;
  late Directory directory;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    directory = await Directory.systemTemp.createTemp('transfer_workflow_');
    await seedTransferData(db, directory);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'common headers auto-match and missing mandatory mappings block import',
    () async {
      final file = writeTransferCsv(directory, aliases: true);
      final preview = await ImportFileReader.preview(filePath: file.path);
      final mapping = defaultImportMapping(preview.headers);
      expect(mapping['联系人姓名'], '姓名');
      expect(mapping['金额(元)'], '金额元');
      expect(importMappingProblem(preview, mapping), isNull);
      mapping['金额(元)'] = '';
      expect(importMappingProblem(preview, mapping), contains('金额(元)'));
    },
  );

  test(
    'explicit ignore is persisted and prevents canonical-header fallback',
    () async {
      final file = File('${directory.path}/ignored.csv')
        ..writeAsStringSync(
          '数据类型,联系人姓名,收支方向,金额(元),发生时间,备注\n礼金收支记录,忽略备注测试,收礼,100.25,2026-10-10,不应写入\n',
        );
      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => directory,
      );
      final job = await service.createJob(
        bookId: 'default',
        sourceFilePath: file.path,
        kind: DataImportKind.recordsAndPersons,
        fieldMapping: const {'备注': ''},
      );
      final result = await (await service.start(job)).progress.last;
      expect(result.status, DataImportStatus.completed);
      expect(result.failedRows, 0);
      final records = await db.giftRecordsDao.listAllWithPersonInAllBooks();
      final record = records
          .singleWhere((r) => r.person.name == '忽略备注测试')
          .record;
      expect(record.note, isNull);
      expect(record.amountCent, 10025);
      expect(record.direction, '收入');
    },
  );

  test(
    'unknown data types are counted as failed rows with a readable log',
    () async {
      final file = File('${directory.path}/bad-type.csv')
        ..writeAsStringSync('数据类型,联系人姓名\n未知类型,某人\n,缺少类型\n');
      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => directory,
      );
      final job = await service.createJob(
        bookId: 'default',
        sourceFilePath: file.path,
        kind: DataImportKind.recordsAndPersons,
      );
      final result = await (await service.start(job)).progress.last;
      expect(result.processedRows, 2);
      expect(result.failedRows, 2);
      final saved = (await db.dataImportJobsDao.findById(job))!;
      expect(
        await File(saved.errorLogPath!).readAsString(),
        contains('数据类型不合法'),
      );
    },
  );

  test(
    'default-book preview count and exported rows share the same expense scope',
    () async {
      final service = DataExportService();
      final summary = await service.inspectScope(db: db, bookId: 'default');
      expect(summary.recordCount, 2);
      expect(summary.personCount, 2);
      DataExportSummary? actual;
      final file = await service.exportFromDrift(
        db: db,
        outputDir: directory,
        request: DataExportRequest(
          format: DataExportFormat.excel,
          start: DateTime(2026),
          end: DateTime(2026, 12, 31),
          bookId: 'default',
          includeRecords: true,
          includePersons: true,
          includeImages: false,
        ),
        onPrepared: (summary) => actual = summary,
      );
      final rows = Excel.decodeBytes(await file.readAsBytes())
          .tables['礼金记录']!
          .rows;
      expect(rows.length - 1, summary.recordCount);
      expect(actual?.recordCount, summary.recordCount);
      final oneDay = await service.inspectScope(
        db: db,
        bookId: 'default',
        start: DateTime(2026, 10, 5),
        end: DateTime(2026, 10, 5),
      );
      expect(oneDay.recordCount, 1);
    },
  );

  test(
    'Excel keeps image paths and its separated sheets can be imported',
    () async {
      final service = DataExportService();
      final file = await service.exportFromDrift(
        db: db,
        outputDir: directory,
        request: DataExportRequest(
          format: DataExportFormat.excel,
          start: DateTime(2026),
          end: DateTime(2026, 12, 31),
          includeRecords: true,
          includePersons: true,
          includeImages: false,
        ),
      );
      final excel = Excel.decodeBytes(await file.readAsBytes());
      final records = excel.tables['礼金记录']!.rows;
      final headers = records.first
          .map((cell) => cell?.value.toString())
          .toList();
      expect(
        records[1][headers.indexOf('附件1名称')]?.value.toString(),
        '${directory.path}/gift.jpg',
      );
      final people = excel.tables['联系人']!.rows;
      final personHeaders = people.first
          .map((cell) => cell?.value.toString())
          .toList();
      expect(
        people[1][personHeaders.indexOf('头像文件名')]?.value.toString(),
        '${directory.path}/avatar.png',
      );
      final preview = await ImportFileReader.preview(filePath: file.path);
      expect(preview.hasRecordSheet, isTrue);
      expect(preview.hasPersonSheet, isTrue);
      expect(
        importMappingProblem(preview, defaultImportMapping(preview.headers)),
        isNull,
      );
    },
  );

  test('ZIP export and selected spreadsheet plus media ZIP restore records and images', () async {
    final file = await DataExportService().exportFromDrift(
      db: db,
      outputDir: directory,
      request: DataExportRequest(
        format: DataExportFormat.zip,
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
        includeRecords: true,
        includePersons: true,
        includeImages: true,
      ),
    );
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final spreadsheet = archive.files.singleWhere(
      (entry) => entry.name.endsWith('.xlsx'),
    );
    final source = File('${directory.path}/roundtrip.xlsx')
      ..writeAsBytesSync(spreadsheet.content as List<int>);
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      // The import job's fallback book must exist, independently of any books
      // described by the exported record metadata.
      final fallback = await target.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(name: '导入目标', createdAt: 1, updatedAt: 1),
      );
      final preview = await ImportFileReader.preview(filePath: source.path);
      final service = DataImportService(
        db: target,
        documentsDirectoryProvider: () async =>
            Directory('${directory.path}/restored'),
      );
      final job = await service.createJob(
        bookId: fallback,
        sourceFilePath: source.path,
        kind: DataImportKind.recordsAndPersons,
        fieldMapping: defaultImportMapping(preview.headers),
        mediaZipPath: file.path,
      );
      final result = await (await service.start(job)).progress.last;
      expect(result.status, DataImportStatus.completed);
      expect(result.failedRows, 0);
      expect(await target.select(target.giftRecords).get(), hasLength(3));
      final restored = await target.personsDao.findById('p1');
      expect(restored?.avatarUri, isNotNull);
      expect(await File(restored!.avatarUri!).readAsBytes(), [1, 2, 3]);
      final record = await (target.select(
        target.giftRecords,
      )..where((r) => r.recordId.equals('r1'))).getSingle();
      expect(await File(record.attachments!.single).readAsBytes(), [4, 5, 6]);
    } finally {
      await target.close();
    }
  });
}
