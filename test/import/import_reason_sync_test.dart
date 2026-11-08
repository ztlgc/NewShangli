import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/import/data_import_service.dart';

Future<DataImportProgress> _importRows(
  AppDatabase db,
  Directory directory,
  List<String> rows, {
  ImportDuplicateDecision? onDuplicate,
}) async {
  final file = File('${directory.path}/reasons.csv');
  await file.writeAsString(
    [
      '数据类型,记录ID,联系人ID,联系人姓名,收支方向,金额(元),事由,发生时间,所属账簿ID,所属账簿名称,账簿事由',
      for (final row in rows) '礼金收支记录,$row',
    ].join('\n'),
  );
  final service = DataImportService(
    db: db,
    documentsDirectoryProvider: () async => directory,
  );
  final jobId = await service.createJob(
    bookId: 'default',
    sourceFilePath: file.path,
    kind: DataImportKind.recordsOnly,
  );
  final handle = await service.start(jobId, onDuplicate: onDuplicate);
  return handle.progress.last;
}

void main() {
  late AppDatabase db;
  late Directory directory;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    directory = await Directory.systemTemp.createTemp('import_reason_sync_');
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value('default'),
        name: '日常礼账',
        isDefault: const Value(1),
        createdAt: 1,
        updatedAt: 1,
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('导入事由进入管理数据源，按名称去重并保留已有停用状态', () async {
    final disabledId = await db.reasonsDao.create(
      name: 'Travel',
      description: '保留描述',
      enabled: false,
    );
    final disabled = await db.reasonsDao.findById(disabledId);
    final result = await _importRows(db, directory, [
      'r1,p1,张三,收入,100,婚礼随礼,2026-01-01 10:00,,,',
      'r2,p2,李四,收入,200, 婚礼随礼 ,2026-01-01 10:00,,,',
      'r3,p3,王五,收入,300,CUSTOM,2026-01-01 10:00,,,',
      'r4,p4,赵六,收入,400,custom,2026-01-01 10:00,,,',
      'r5,p5,孙七,收入,500, travel ,2026-01-01 10:00,,,',
      'r6,p6,周八,收入,600,,2026-01-01 10:00,,,',
      'r7,p7,吴九,收入,-1,失败行事由,2026-01-01 10:00,,,',
    ]);

    expect(result.status, DataImportStatus.completed);
    expect(result.failedRows, 1);
    expect(await db.select(db.giftRecords).get(), hasLength(6));
    final reasons = await db.reasonsDao.listAll();
    expect(
      reasons.map((reason) => reason.name),
      unorderedEquals(['婚礼随礼', 'CUSTOM', 'Travel']),
    );
    expect(await db.reasonsDao.findById(disabledId), disabled);
    expect((await db.reasonsDao.findByName('婚礼随礼'))!.enabled, isTrue);
    expect(await db.reasonsDao.watchAll().first, reasons);
  });

  test('导入新账簿时同时登记账簿事由和记录事由', () async {
    final result = await _importRows(db, directory, [
      'r1,p1,张三,收入,100,记录事由,2026-01-01 10:00,new-book,导入账簿,账簿事由',
    ]);

    expect(result.status, DataImportStatus.completed);
    expect(
      (await db.reasonsDao.listAll()).map((reason) => reason.name),
      unorderedEquals(['账簿事由', '记录事由']),
    );
    expect((await db.accountBooksDao.findById('new-book'))!.reasonType, '账簿事由');
    expect((await db.select(db.giftRecords).get()).single.eventName, '记录事由');
  });

  test('跳过重复记录时不登记该行事由', () async {
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value('p1'),
        bookId: 'default',
        name: '张三',
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        recordId: const Value('existing'),
        bookId: 'default',
        personId: 'p1',
        amountCent: 10000,
        eventName: const Value('旧记录事由'),
        occurredAt: DateTime(2026, 1, 1, 10).millisecondsSinceEpoch,
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    final result = await _importRows(db, directory, [
      'existing,p1,张三,收入,100,跳过行事由,2026-01-01 10:00,,,',
      'new,p2,李四,收入,200,保留行事由,2026-01-01 10:00,,,',
    ], onDuplicate: (_) async => false);

    expect(result.status, DataImportStatus.completed);
    expect(result.skippedRows, 1);
    expect((await db.reasonsDao.listAll()).single.name, '保留行事由');
  });

  test('事由写入失败时整批记录、联系人和进度一起回滚', () async {
    await db.customStatement('''
      CREATE TRIGGER fail_reason_insert BEFORE INSERT ON reason
      BEGIN SELECT RAISE(ABORT, 'injected reason failure'); END;
    ''');
    final result = await _importRows(db, directory, [
      'r1,p1,张三,收入,100,事务事由,2026-01-01 10:00,new-book,新账簿,账簿事由',
    ]);

    expect(result.status, DataImportStatus.failed);
    expect(result.successRows, 0);
    expect(await db.select(db.giftRecords).get(), isEmpty);
    expect(await db.select(db.persons).get(), isEmpty);
    expect(await db.reasonsDao.listAll(), isEmpty);
    expect(await db.accountBooksDao.findById('new-book'), isNull);
    final job = (await db.select(db.dataImportJobs).get()).single;
    expect(job.lastRowIndex, 0);
    expect(job.successRows, 0);
  });
}
