import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/import/data_import_service.dart';

void main() {
  group('DataImportService', () {
    late AppDatabase db;
    late Directory tempDir;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      tempDir = await Directory.systemTemp.createTemp('newshangli_import_');
    });

    tearDown(() async {
      await db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('CSV 导入：写入 Person/GiftRecord 并更新任务统计', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final csv = File('${tempDir.path}/input.csv');
      await csv.writeAsString(
        [
          '数据类型,记录ID,收支方向,金额(元),事由,所属账簿名称,关系人ID,关系人姓名,关系人关系,手机号,支付方式,发生时间,备注',
          '关系人列表,,,,,,p1,张三,朋友,13800000000,,2026-01-01 10:00,',
          '礼金收支记录,,收入,100.00,婚礼随礼,测试账簿,p1,张三,,,现金,2026-01-01 10:00,示例备注',
        ].join('\n'),
        flush: true,
      );

      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => tempDir,
      );

      final jobId = await service.createJob(
        bookId: bookId,
        sourceFilePath: csv.path,
        kind: DataImportKind.recordsAndPersons,
      );

      final handle = await service.start(jobId);
      final last = await handle.progress.last;
      expect(last.status, DataImportStatus.completed);

      final persons = await (db.select(
        db.persons,
      )..where((t) => t.bookId.equals(bookId))).get();
      final records = await (db.select(
        db.giftRecords,
      )..where((t) => t.bookId.equals(bookId))).get();
      expect(persons.length, 1);
      expect(persons.first.name, '张三');
      expect(records.length, 1);
      expect(records.first.amountCent, 10000);
      expect(records.first.direction, '收入');

      final job = await db.dataImportJobsDao.findById(jobId);
      expect(job, isNotNull);
      expect(job!.status, DataImportStatus.completed.name);
      expect(job.successRows, greaterThanOrEqualTo(1));
      expect(job.processedRows, greaterThanOrEqualTo(1));
    });

    test('CSV 断点续传：从 lastRowIndex 继续处理后续行', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final csv = File('${tempDir.path}/resume.csv');
      await csv.writeAsString(
        [
          '数据类型,记录ID,收支方向,金额(元),事由,所属账簿名称,关系人ID,关系人姓名,关系人关系,手机号,支付方式,发生时间,备注',
          '关系人列表,,,,,,p1,张三,朋友,13800000000,,2026-01-01 10:00,',
          '关系人列表,,,,,,p2,李四,同事,13900000000,,2026-01-01 10:00,',
        ].join('\n'),
        flush: true,
      );

      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => tempDir,
      );

      final jobId = await service.createJob(
        bookId: bookId,
        sourceFilePath: csv.path,
        kind: DataImportKind.personsOnly,
      );

      await (db.update(
        db.dataImportJobs,
      )..where((t) => t.jobId.equals(jobId))).write(
        DataImportJobsCompanion(
          lastRowIndex: const Value(1),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      final handle = await service.start(jobId);
      final last = await handle.progress.last;
      expect(last.status, DataImportStatus.completed);

      final persons = await (db.select(
        db.persons,
      )..where((t) => t.bookId.equals(bookId))).get();
      expect(persons.length, 1);
      expect(persons.first.personId, 'p2');
      expect(persons.first.name, '李四');
    });

    test('CSV 导入支持字段映射并写入统计', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final csv = File('${tempDir.path}/mapped.csv');
      await csv.writeAsString(
        [
          '类型,RID,方向,金额元,金额分,事项,PID,姓名,关系,电话,支付,时间,备注',
          '关系人列表,,,,,,p1,张三,朋友,13800000000,,,',
          '礼金收支记录,,收入,100.00,10000,婚礼随礼,p1,张三,朋友,13800000000,现金,2026-01-01 10:00,示例备注',
        ].join('\n'),
        flush: true,
      );

      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => tempDir,
      );

      final jobId = await service.createJob(
        bookId: bookId,
        sourceFilePath: csv.path,
        kind: DataImportKind.recordsAndPersons,
        fieldMapping: const <String, String?>{
          '数据类型': '类型',
          '记录ID': 'RID',
          '收支方向': '方向',
          '金额(元)': '金额元',
          '金额(分)': '金额分',
          '事由': '事项',
          '关系人ID': 'PID',
          '关系人姓名': '姓名',
          '关系人关系': '关系',
          '手机号': '电话',
          '支付方式': '支付',
          '发生时间': '时间',
          '备注': '备注',
        },
      );

      final handle = await service.start(jobId);
      final last = await handle.progress.last;
      expect(last.status, DataImportStatus.completed);
      expect(last.successRows, 2);
      expect(last.failedRows, 0);
    });

    test('Excel加ZIP导入可恢复头像与附件', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final excel = Excel.createExcel();
      excel.rename('Sheet1', '礼金记录');
      final recordSheet = excel['礼金记录'];
      final personSheet = excel['关系人'];
      final recordHeaders = <String>[
        '记录ID',
        '收支方向',
        '金额(元)',
        '金额(分)',
        '事由',
        '关系人ID',
        '关系人姓名',
        '关系人关系',
        '手机号',
        '支付方式',
        '发生时间',
        '备注',
        '附件1名称',
      ];
      for (var c = 0; c < recordHeaders.length; c++) {
        recordSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            .value = TextCellValue(
          recordHeaders[c],
        );
      }
      final recordRow = <String>[
        '',
        '收入',
        '20.00',
        '2000',
        '测试',
        'p1',
        '张三',
        '朋友',
        '13800000000',
        '现金',
        '2026-01-01 10:00',
        '',
        'att_1.jpg',
      ];
      for (var c = 0; c < recordRow.length; c++) {
        recordSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
            .value = TextCellValue(
          recordRow[c],
        );
      }

      final personHeaders = <String>[
        '关系人ID',
        '姓名',
        '关系',
        '手机号',
        '创建时间',
        '备注',
        '头像文件名',
      ];
      for (var c = 0; c < personHeaders.length; c++) {
        personSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            .value = TextCellValue(
          personHeaders[c],
        );
      }
      final personRow = <String>[
        'p1',
        '张三',
        '朋友',
        '13800000000',
        '2026-01-01 10:00',
        '',
        'avatar_1.png',
      ];
      for (var c = 0; c < personRow.length; c++) {
        personSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
            .value = TextCellValue(
          personRow[c],
        );
      }
      final xlsx = File('${tempDir.path}/input.xlsx');
      await xlsx.writeAsBytes(excel.encode()!, flush: true);

      final archive = Archive();
      archive.addFile(
        ArchiveFile('media/avatars/avatar_1.png', 3, <int>[1, 2, 3]),
      );
      archive.addFile(
        ArchiveFile('media/attachments/att_1.jpg', 3, <int>[4, 5, 6]),
      );
      final zipBytes = ZipEncoder().encode(archive)!;
      final zip = File('${tempDir.path}/media.zip');
      await zip.writeAsBytes(zipBytes, flush: true);

      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => tempDir,
      );
      final jobId = await service.createJob(
        bookId: bookId,
        sourceFilePath: xlsx.path,
        kind: DataImportKind.recordsAndPersons,
        mediaZipPath: zip.path,
      );
      final handle = await service.start(jobId);
      final last = await handle.progress.last;
      expect(last.status, DataImportStatus.completed);

      final persons = await (db.select(
        db.persons,
      )..where((t) => t.bookId.equals(bookId))).get();
      final records = await (db.select(
        db.giftRecords,
      )..where((t) => t.bookId.equals(bookId))).get();
      expect(persons.length, 1);
      expect((persons.first.avatarUri ?? '').isNotEmpty, true);
      expect(records.length, 1);
      expect((records.first.attachments ?? const <String>[]).isNotEmpty, true);
    });

    test('Excel加ZIP导入正确区分头像与附件同名文件', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final excel = Excel.createExcel();
      excel.rename('Sheet1', '礼金记录');
      final recordSheet = excel['礼金记录'];
      final personSheet = excel['关系人'];
      final recordHeaders = <String>[
        '记录ID',
        '收支方向',
        '金额(元)',
        '金额(分)',
        '事由',
        '关系人ID',
        '关系人姓名',
        '关系人关系',
        '手机号',
        '支付方式',
        '发生时间',
        '备注',
        '附件1名称',
      ];
      for (var c = 0; c < recordHeaders.length; c++) {
        recordSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            .value = TextCellValue(
          recordHeaders[c],
        );
      }
      final recordRow = <String>[
        '',
        '收入',
        '20.00',
        '2000',
        '测试',
        'p1',
        '张三',
        '朋友',
        '13800000000',
        '现金',
        '2026-01-01 10:00',
        '',
        'same.png',
      ];
      for (var c = 0; c < recordRow.length; c++) {
        recordSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
            .value = TextCellValue(
          recordRow[c],
        );
      }

      final personHeaders = <String>[
        '关系人ID',
        '姓名',
        '关系',
        '手机号',
        '创建时间',
        '备注',
        '头像文件名',
      ];
      for (var c = 0; c < personHeaders.length; c++) {
        personSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            .value = TextCellValue(
          personHeaders[c],
        );
      }
      final personRow = <String>[
        'p1',
        '张三',
        '朋友',
        '13800000000',
        '2026-01-01 10:00',
        '',
        'same.png',
      ];
      for (var c = 0; c < personRow.length; c++) {
        personSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
            .value = TextCellValue(
          personRow[c],
        );
      }
      final xlsx = File('${tempDir.path}/same_name_input.xlsx');
      await xlsx.writeAsBytes(excel.encode()!, flush: true);

      final archive = Archive();
      archive.addFile(ArchiveFile('media/avatars/same.png', 3, <int>[1, 2, 3]));
      archive.addFile(
        ArchiveFile('media/attachments/same.png', 3, <int>[4, 5, 6]),
      );
      // 正常 ZIP 中同名文件按头像/附件目录区分；恶意 ZIP 单独验证。
      final zipBytes = ZipEncoder().encode(archive)!;
      final zip = File('${tempDir.path}/same_name_media.zip');
      await zip.writeAsBytes(zipBytes, flush: true);

      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => tempDir,
      );
      final jobId = await service.createJob(
        bookId: bookId,
        sourceFilePath: xlsx.path,
        kind: DataImportKind.recordsAndPersons,
        mediaZipPath: zip.path,
      );
      final handle = await service.start(jobId);
      final last = await handle.progress.last;
      expect(last.status, DataImportStatus.completed);

      final persons = await (db.select(
        db.persons,
      )..where((t) => t.bookId.equals(bookId))).get();
      final records = await (db.select(
        db.giftRecords,
      )..where((t) => t.bookId.equals(bookId))).get();
      expect(persons.length, 1);
      expect(records.length, 1);

      final avatarPath = persons.first.avatarUri;
      final attachmentPath = records.first.attachments?.first;
      expect(avatarPath, isNotNull);
      expect(attachmentPath, isNotNull);
      expect(await File(avatarPath!).readAsBytes(), <int>[1, 2, 3]);
      expect(await File(attachmentPath!).readAsBytes(), <int>[4, 5, 6]);

      final escapedFile = File('${tempDir.path}/imports/files/escape.txt');
      expect(await escapedFile.exists(), false);
    });
  });
}
