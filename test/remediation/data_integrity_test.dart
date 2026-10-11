import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/import/data_import_service.dart';
import 'package:newshangli/import/csv_document.dart';
import 'package:newshangli/import/import_value_codec.dart';
import 'package:newshangli/export/data_export_service.dart';
import 'package:newshangli/backup/data_backup_service.dart';
import 'package:newshangli/backup/data_restore_service.dart';
import 'package:newshangli/backup/restore_safety.dart';

const date = 1767225600123;
Future<void> seed(AppDatabase db) async {
  for (final id in ['a', 'b']) {
    await db
        .into(db.accountBooks)
        .insert(
          AccountBooksCompanion.insert(
            bookId: Value(id),
            name: '同名账簿',
            reasonType: const Value('婚礼'),
            bookTime: const Value(date),
            createdAt: 1,
            updatedAt: 1,
          ),
        );
  }
  await db
      .into(db.persons)
      .insert(
        PersonsCompanion.insert(
          personId: const Value('p'),
          bookId: 'a',
          name: '张三',
          note: const Value('联系人备注'),
          birthday: const Value('1990-01-01'),
          createdAt: 1,
          updatedAt: 1,
        ),
      );
}

GiftRecordsCompanion record(
  String id, {
  String person = 'p',
  String book = 'b',
  int amount = 101,
}) => GiftRecordsCompanion.insert(
  recordId: Value(id),
  bookId: book,
  personId: person,
  amountCent: amount,
  eventName: const Value('婚礼'),
  occurredAt: date,
  direction: const Value('支出'),
  note: const Value('=SUM(A1:A2)\n中文,"引号"'),
  createdAt: 1,
  updatedAt: 1,
);

void main() {
  late AppDatabase db;
  late Directory temp;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    temp = await Directory.systemTemp.createTemp('shangli_remediation_');
    await seed(db);
  });
  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  test('全局联系人跨账本展示，删除来源账本不删除联系人及其他账本记录', () async {
    await db.into(db.giftRecords).insert(record('r'));
    expect(
      (await db.giftRecordsDao.watchAllWithPersonInBook('b').first)
          .single
          .person
          .personId,
      'p',
    );
    await db.accountBooksDao.deleteById('a');
    expect(await db.personsDao.findById('p'), isNotNull);
    expect((await db.select(db.giftRecords).get()).single.bookId, 'b');
    expect(
      (await db.personsDao.watchAllInBook('b').first).single.personId,
      'p',
    );
  });

  test('账本日期事由同步包含回收站；失败时整体回滚', () async {
    await db.into(db.giftRecords).insert(record('active'));
    await db
        .into(db.giftRecords)
        .insert(record('deleted').copyWith(deletedAt: const Value(5)));
    final book = (await db.accountBooksDao.findById('b'))!;
    await db.accountBooksDao.updateOne(
      book.copyWith(bookTime: date + 1000, reasonType: '生日'),
    );
    final rows = await db.select(db.giftRecords).get();
    expect(
      rows.every((r) => r.occurredAt == date + 1000 && r.eventName == '生日'),
      true,
    );
    expect(rows.singleWhere((r) => r.recordId == 'deleted').deletedAt, 5);
    await db.customStatement(
      "CREATE TRIGGER fail_record_update BEFORE UPDATE ON gift_record BEGIN SELECT RAISE(ABORT,'injected'); END",
    );
    await expectLater(
      db.accountBooksDao.updateOne(
        book.copyWith(bookTime: date + 2000, reasonType: '故障'),
      ),
      throwsA(anything),
    );
    expect((await db.accountBooksDao.findById('b'))!.reasonType, '生日');
    expect((await db.select(db.giftRecords).get()).first.eventName, '生日');
  });

  test('数据库拒绝零负数极大金额和非整数', () async {
    for (final amount in [0, -1, 100000000000000]) {
      await expectLater(
        db.into(db.giftRecords).insert(record('r$amount', amount: amount)),
        throwsA(anything),
      );
    }
    await expectLater(
      db.customStatement(
        "INSERT INTO gift_record(record_id,book_id,person_id,amount_cent,occurred_at,created_at,updated_at) VALUES('float','b','p',1.2,1,1,1)",
      ),
      throwsA(anything),
    );
  });

  test('严格金额与日期，不接受静默四舍五入或日期溢出', () {
    expect(ImportValueCodec.amountCent('1,234.56'), 123456);
    expect(ImportValueCodec.amountCent('999999999999.99'), 99999999999999);
    for (final s in [
      'NaN',
      'Infinity',
      '1e3',
      '0',
      '-1',
      '1.001',
      '1,23',
      '1000000000000',
    ]) {
      expect(ImportValueCodec.amountCent(s), isNull, reason: s);
    }
    expect(ImportValueCodec.date('2026-02-30'), isNull);
    expect(ImportValueCodec.date('2024-02-29T01:02:03.123Z')!.millisecond, 123);
  });

  test('CSV 多行引号转义及重复表头检测', () {
    final rows = CsvDocument.parse('姓名,备注\r\n张三,"第一行\r\n第二行""引号"""\r\n');
    expect(rows[1][1], '第一行\r\n第二行"引号"');
    expect(() => CsvDocument.parse('姓名,姓名\n张三,李四'), throwsFormatException);
    expect(() => CsvDocument.parse('姓名,备注\n张三,"未闭合'), throwsFormatException);
  });

  Future<String> importJob({String? content}) async {
    final file = File(temp.path + '/input.csv');
    await file.writeAsString(
      content ?? '数据类型,关系人ID,关系人姓名,金额(元),收支方向,发生时间,事由,备注\n礼金收支记录,p,张三,1.01,支出,2026-01-01T00:00:00.123Z,婚礼,"多行\n备注"',
    );
    return DataImportService(
      db: db,
      documentsDirectoryProvider: () async => temp,
    ).createJob(
      bookId: 'b',
      sourceFilePath: file.path,
      kind: DataImportKind.recordsAndPersons,
    );
  }

  DataImportService service() =>
      DataImportService(db: db, documentsDirectoryProvider: () async => temp);

  test('重复导入由用户逐条选择跳过或保留，保留获得新ID', () async {
    var h = await service().start(await importJob());
    expect((await h.progress.last).status, DataImportStatus.completed);
    var asked = 0;
    h = await service().start(
      await importJob(),
      onDuplicate: (d) async {
        asked++;
        return false;
      },
    );
    expect((await h.progress.last).skippedRows, 1);
    h = await service().start(
      await importJob(),
      onDuplicate: (d) async {
        asked++;
        return true;
      },
    );
    expect((await h.progress.last).status, DataImportStatus.completed);
    final records = await db.select(db.giftRecords).get();
    expect(asked, 2);
    expect(records.length, 2);
    expect(records.map((r) => r.recordId).toSet().length, 2);
    expect(
      records.every(
        (r) =>
            r.personId == 'p' &&
            r.bookId == 'b' &&
            r.amountCent == 101 &&
            r.direction == '支出',
      ),
      true,
    );
  });

  test('写入失败时关联对象和检查点回滚；重试只写一次', () async {
    final id = await importJob(
      content: '数据类型,关系人姓名,金额(元),收支方向,发生时间\n礼金收支记录,新联系人,20,收入,2026-01-01',
    );
    await db.customStatement(
      "CREATE TRIGGER fail_import BEFORE INSERT ON gift_record BEGIN SELECT RAISE(ABORT,'injected'); END",
    );
    var h = await service().start(id);
    expect((await h.progress.last).status, DataImportStatus.failed);
    expect((await db.select(db.persons).get()).length, 1);
    expect((await db.dataImportJobsDao.findById(id))!.lastRowIndex, 0);
    await db.customStatement('DROP TRIGGER fail_import');
    h = await service().start(id);
    expect((await h.progress.last).status, DataImportStatus.completed);
    expect((await db.select(db.giftRecords).get()).length, 1);
    expect((await db.select(db.persons).get()).length, 2);
  });

  test('同名联系人有不同ID时不合并，无ID歧义行失败且有日志', () async {
    await db
        .into(db.persons)
        .insert(
          PersonsCompanion.insert(
            personId: const Value('p2'),
            bookId: 'b',
            name: '张三',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    final id = await importJob(
      content: '数据类型,关系人姓名,金额(元),收支方向,发生时间\n礼金收支记录,张三,20,收入,2026-01-01',
    );
    final h = await service().start(id);
    expect((await h.progress.last).failedRows, 1);
    expect(await db.select(db.giftRecords).get(), isEmpty);
    final job = (await db.dataImportJobsDao.findById(id))!;
    expect(await File(job.errorLogPath!).readAsString(), contains('同名联系人'));
  });

  test('Excel 导出导入保留跨本ID、同名账本、金额、日期、方向和文本', () async {
    await db.into(db.giftRecords).insert(record('ra', book: 'a'));
    await db.into(db.giftRecords).insert(record('rb'));
    final file = await DataExportService().exportFromDrift(
      db: db,
      request: DataExportRequest(
        format: DataExportFormat.excel,
        start: DateTime(2025),
        end: DateTime(2027),
        includeRecords: true,
        includePersons: true,
        includeImages: false,
      ),
      outputDir: temp,
    );
    final excel = Excel.decodeBytes(await file.readAsBytes());
    expect(excel['礼金记录'].rows[1][9]!.value, isA<TextCellValue>());
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await target
          .into(target.accountBooks)
          .insert(
            AccountBooksCompanion.insert(
              bookId: const Value('target'),
              name: '目标',
              createdAt: 1,
              updatedAt: 1,
            ),
          );
      final importer = DataImportService(
        db: target,
        documentsDirectoryProvider: () async => temp,
      );
      final id = await importer.createJob(
        bookId: 'target',
        sourceFilePath: file.path,
        kind: DataImportKind.recordsAndPersons,
      );
      final handle = await importer.start(id);
      expect((await handle.progress.last).status, DataImportStatus.completed);
      final actual = await target.select(target.giftRecords).get();
      expect(actual.length, 2);
      for (final row in actual) {
        expect(row.bookId, row.recordId == 'ra' ? 'a' : 'b');
        expect(row.personId, 'p');
        expect(row.amountCent, 101);
        expect(row.direction, '支出');
        expect(row.occurredAt, date);
        expect(row.note, '=SUM(A1:A2)\n中文,"引号"');
        expect(row.eventName, '婚礼');
      }
      final contact = (await target.select(target.persons).get()).single;
      expect(contact.note, '联系人备注');
      expect(contact.birthday, '1990-01-01');
    } finally {
      await target.close();
    }
  });

  test('真实WAL快照跨目录恢复，两次恢复字段关系和附件一致', () async {
    final source = Directory(temp.path + '/source')..createSync();
    final target = Directory(temp.path + '/target')..createSync();
    final file = File(source.path + '/newshangli_drift.sqlite');
    final sourceDb = AppDatabase.forTesting(NativeDatabase(file));
    await seed(sourceDb);
    final media = File(source.path + '/media/attachments/image.png');
    await media.parent.create(recursive: true);
    await media.writeAsBytes([1, 2, 3]);
    await sourceDb
        .into(sourceDb.giftRecords)
        .insert(record('r').copyWith(attachments: Value([media.path])));
    await sourceDb.customStatement('PRAGMA journal_mode=WAL');
    final zip = await DataBackupService(
      documentsDirectoryProvider: () async => source,
    ).buildLocalBackupZip(onProgress: (_) {});
    await sourceDb.close();
    final restore = DataRestoreService(
      documentsDirectoryProvider: () async => target,
    );
    for (var i = 0; i < 2; i++) {
      await restore.restoreFromLocalZip(zipFile: zip, onProgress: (_) {});
      final restored = AppDatabase.forTesting(
        NativeDatabase(File(target.path + '/newshangli_drift.sqlite')),
      );
      final rows = await restored.select(restored.giftRecords).get();
      expect(rows.length, 1);
      final r = rows.single;
      expect(
        [
          r.recordId,
          r.bookId,
          r.personId,
          r.amountCent,
          r.direction,
          r.occurredAt,
          r.deletedAt,
        ],
        ['r', 'b', 'p', 101, '支出', date, null],
      );
      expect(
        r.attachments!.single.replaceAll(r'\', '/'),
        contains(target.path.replaceAll(r'\', '/')),
      );
      expect(await File(r.attachments!.single).readAsBytes(), [1, 2, 3]);
      expect(
        await restored.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      await restored.close();
    }
  });

  test('恢复拒绝路径穿越与损坏包且不改变原文件', () async {
    final original = File(temp.path + '/newshangli_drift.sqlite');
    await original.writeAsBytes([4, 5, 6]);
    final archive = Archive()
      ..addFile(ArchiveFile('media/../../escape', 1, [1]));
    final zip = File(temp.path + '/unsafe.zip');
    await zip.writeAsBytes(ZipEncoder().encode(archive)!);
    await expectLater(
      DataRestoreService(documentsDirectoryProvider: () async => temp)
          .restoreFromLocalZip(zipFile: zip, onProgress: (_) {}),
      throwsA(anything),
    );
    expect(await original.readAsBytes(), [4, 5, 6]);
  });

  test('启动恢复日志可回退中断后的数据库和媒体', () async {
    final original = File(temp.path + '/newshangli_drift.sqlite');
    await original.writeAsBytes([1, 2, 3]);
    final guard = Directory(temp.path + '/backups/restore_guard/test')
      ..createSync(recursive: true);
    await original.copy(guard.path + '/newshangli_drift.sqlite');
    await RestoreSafety.begin(temp, guard);
    await original.writeAsBytes([9]);
    await RestoreSafety.recoverIfNeeded(temp);
    expect(await original.readAsBytes(), [1, 2, 3]);
    expect(await RestoreSafety.journal(temp).exists(), false);
  });

  test('ZIP 导出导入完整保留超过20个附件及实际媒体目录', () async {
    final media = File(temp.path + '/media/attachments/a.png');
    await media.parent.create(recursive: true);
    await media.writeAsBytes([1, 2, 3]);
    await db
        .into(db.giftRecords)
        .insert(
          record('media')
              .copyWith(attachments: Value(List.filled(22, media.path))),
        );
    final zip = await DataExportService().exportFromDrift(
      db: db,
      request: DataExportRequest(
        format: DataExportFormat.zip,
        start: DateTime(2025),
        end: DateTime(2027),
        includeRecords: true,
        includePersons: true,
        includeImages: true,
      ),
      outputDir: temp,
    );
    final archive = RestoreSafety.decodeZip(await zip.readAsBytes());
    final sheet = archive.files.singleWhere(
      (file) => file.name.endsWith('.xlsx'),
    );
    final xlsx = File(temp.path + '/roundtrip.xlsx');
    await xlsx.writeAsBytes(sheet.content as List<int>);
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    final docs = Directory(temp.path + '/imported')..createSync();
    try {
      await seed(target);
      final importer = DataImportService(
        db: target,
        documentsDirectoryProvider: () async => docs,
      );
      final id = await importer.createJob(
        bookId: 'b',
        sourceFilePath: xlsx.path,
        kind: DataImportKind.recordsAndPersons,
        mediaZipPath: zip.path,
      );
      final handle = await importer.start(id);
      expect((await handle.progress.last).status, DataImportStatus.completed);
      final row = (await target.select(target.giftRecords).get()).single;
      expect(row.attachments!.length, 22);
      for (final path in row.attachments!) {
        expect(path.replaceAll(r'\', '/'), contains('/imported/media/'));
        expect(await File(path).readAsBytes(), [1, 2, 3]);
      }
    } finally {
      await target.close();
    }
  });

  test('恢复在替换数据库后失败时回退原记录和附件', () async {
    final source = Directory(temp.path + '/source')..createSync();
    final target = Directory(temp.path + '/target')..createSync();
    final sourceDb = AppDatabase.forTesting(
      NativeDatabase(File(source.path + '/newshangli_drift.sqlite')),
    );
    await seed(sourceDb);
    await sourceDb.into(sourceDb.giftRecords).insert(record('new'));
    final backup = await DataBackupService(
      documentsDirectoryProvider: () async => source,
    ).buildLocalBackupZip(onProgress: (_) {});
    await sourceDb.close();
    final original = AppDatabase.forTesting(
      NativeDatabase(File(target.path + '/newshangli_drift.sqlite')),
    );
    await seed(original);
    await original
        .into(original.giftRecords)
        .insert(record('old', amount: 999));
    await original.close();
    final media = File(target.path + '/media/a.png');
    await media.parent.create(recursive: true);
    await media.writeAsBytes([7]);
    await expectLater(
      DataRestoreService(
        documentsDirectoryProvider: () async => target,
      ).restoreFromLocalZip(
        zipFile: backup,
        onProgress: (message) {
          if (message == '正在恢复媒体文件…') throw StateError('injected interruption');
        },
      ),
      throwsA(isA<DataRestoreException>()),
    );
    final restored = AppDatabase.forTesting(
      NativeDatabase(File(target.path + '/newshangli_drift.sqlite')),
    );
    try {
      final row = (await restored.select(restored.giftRecords).get()).single;
      expect(
        [row.recordId, row.amountCent, row.personId, row.bookId],
        ['old', 999, 'p', 'b'],
      );
      expect(await media.readAsBytes(), [7]);
      expect(await RestoreSafety.journal(target).exists(), false);
    } finally {
      await restored.close();
    }
  });
}
