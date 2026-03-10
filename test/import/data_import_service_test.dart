import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
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
          '数据类型,记录ID,收支方向,金额(元),金额(分),事由,关系人ID,关系人姓名,关系人关系,手机号,支付方式,发生时间,备注',
          '关系人列表,,,,,,p1,张三,朋友,13800000000,,2026-01-01 10:00,',
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
      );

      final handle = await service.start(jobId);
      final last = await handle.progress.last;
      expect(last.status, DataImportStatus.completed);

      final persons = await (db.select(db.persons)..where((t) => t.bookId.equals(bookId))).get();
      final records = await (db.select(db.giftRecords)..where((t) => t.bookId.equals(bookId))).get();
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
          '数据类型,记录ID,收支方向,金额(元),金额(分),事由,关系人ID,关系人姓名,关系人关系,手机号,支付方式,发生时间,备注',
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

      await (db.update(db.dataImportJobs)..where((t) => t.jobId.equals(jobId))).write(
        DataImportJobsCompanion(
          lastRowIndex: const Value(1),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      final handle = await service.start(jobId);
      final last = await handle.progress.last;
      expect(last.status, DataImportStatus.completed);

      final persons = await (db.select(db.persons)..where((t) => t.bookId.equals(bookId))).get();
      expect(persons.length, 1);
      expect(persons.first.personId, 'p2');
      expect(persons.first.name, '李四');
    });
  });
}
