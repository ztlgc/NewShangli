import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/export/data_export_service.dart';
import 'package:newshangli/import/data_import_service.dart';
import 'package:newshangli/import/data_import_template_service.dart';
import 'package:newshangli/import/import_field_mapping.dart';
import 'package:newshangli/import/import_file_reader.dart';
import 'package:path/path.dart' as p;

// Fresh current-schema fixtures. No pre-existing test helper or fixture is used.
const _stamp = 1780000000123;
final _day = DateTime(2026, 8, 12, 10, 30, 12, 345);
const _headers = [
  '数据类型',
  '记录ID',
  '收支方向',
  '金额(元)',
  '事由',
  '所属账簿名称',
  '联系人ID',
  '联系人姓名',
  '联系人关系',
  '手机号',
  '发生时间',
  '备注',
  '创建时间',
  '生日',
  '纪念日',
  '头像文件名',
  '附件1名称',
];

List<String> _row(
  Map<String, String> values, [
  List<String> headers = _headers,
]) => headers.map((h) => values[h] ?? '').toList();
Map<String, String> _record(int i, {String amount = '88.08'}) => {
  '数据类型': '礼金收支记录',
  '记录ID': 'r$i',
  '联系人ID': 'p$i',
  '联系人姓名': '联系人$i',
  '收支方向': i.isEven ? '收入' : '支出',
  '金额(元)': amount,
  '发生时间': _day.toIso8601String(),
  '事由': '生日礼金',
};

class _Rig {
  _Rig(this.root);
  final Directory root;
  final databases = <AppDatabase>[];
  int sequence = 0;
  static Future<_Rig> create() async =>
      _Rig(await Directory.systemTemp.createTemp('liji_import_audit_'));
  Future<AppDatabase> database({String defaultId = 'default'}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    databases.add(db);
    await db
        .into(db.accountBooks)
        .insert(
          AccountBooksCompanion.insert(
            bookId: Value(defaultId),
            name: '默认账簿',
            isDefault: const Value(1),
            bookTime: Value(_day.millisecondsSinceEpoch),
            createdAt: _stamp,
            updatedAt: _stamp,
          ),
        );
    return db;
  }

  Future<Directory> directory(String prefix) =>
      Directory(p.join(root.path, '${prefix}_${sequence++}'))
          .create(recursive: true);
  Future<File> csv(List<List<String>> rows, {bool bom = false}) async {
    final file = File(p.join(root.path, 'input_${sequence++}.csv'));
    String cell(String s) => '"${s.replaceAll('"', '""')}"';
    await file.writeAsString(
      '${bom ? '﻿' : ''}${rows.map((r) => r.map(cell).join(',')).join('\r\n')}',
    );
    return file;
  }

  Future<File> workbook(Map<String, List<List<String>>> sheets) async {
    final x = Excel.createExcel();
    x.rename('Sheet1', sheets.keys.first);
    for (final entry in sheets.entries) {
      for (final row in entry.value) {
        x[entry.key].appendRow(row.map(TextCellValue.new).toList());
      }
    }
    final file = File(p.join(root.path, 'input_${sequence++}.xlsx'));
    await file.writeAsBytes(x.encode()!);
    return file;
  }

  Future<File> zip(Map<String, List<int>> entries) async {
    final a = Archive();
    entries.forEach(
      (name, data) => a.addFile(ArchiveFile(name, data.length, data)),
    );
    final f = File(p.join(root.path, 'input_${sequence++}.zip'));
    await f.writeAsBytes(ZipEncoder().encode(a)!);
    return f;
  }

  Future<DataImportJob> import(
    AppDatabase db,
    File file, {
    File? media,
    DataImportKind kind = DataImportKind.recordsAndPersons,
    bool duplicate = false,
    bool mapping = true,
  }) async {
    final service = DataImportService(
      db: db,
      documentsDirectoryProvider: () async => root,
    );
    final preview = mapping
        ? await ImportFileReader.preview(filePath: file.path)
        : null;
    final id = await service.createJob(
      bookId: 'default',
      sourceFilePath: file.path,
      kind: kind,
      fieldMapping: preview == null
          ? null
          : defaultImportMapping(preview.headers),
      mediaZipPath: media?.path,
    );
    final h = await service.start(id, onDuplicate: (_) async => duplicate);
    await h.progress.drain<void>();
    return (await db.dataImportJobsDao.findById(id))!;
  }

  Future<File> export(
    AppDatabase db, {
    DataExportFormat format = DataExportFormat.excel,
    bool images = false,
    bool records = true,
    bool persons = true,
    String? book,
    DateTime? start,
    DateTime? end,
  }) => DataExportService().exportFromDrift(
    db: db,
    outputDir: root,
    request: DataExportRequest(
      format: format,
      start: start ?? DateTime(2000),
      end: end ?? DateTime(2100),
      bookId: book,
      includeRecords: records,
      includePersons: persons,
      includeImages: images,
    ),
  );
  Future<File> unpackWorkbook(File zip) async {
    final a = ZipDecoder().decodeBytes(await zip.readAsBytes());
    final entry = a.files.singleWhere((e) => e.name.endsWith('.xlsx'));
    final f = File(p.join(root.path, 'unpacked_${sequence++}.xlsx'));
    await f.writeAsBytes(entry.content as List<int>);
    return f;
  }

  Future<File> media(String name, List<int> bytes) async {
    final f = File(p.join(root.path, 'media', name));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes);
    return f;
  }

  Future<List<File>> storedMedia() async {
    final directory = Directory(p.join(root.path, 'media'));
    if (!await directory.exists()) return [];
    return directory
        .list(recursive: true)
        .where((e) => e is File)
        .cast<File>()
        .toList();
  }

  Future<void> close() async {
    for (final db in databases) {
      await db.close();
    }
    await root.delete(recursive: true);
  }
}

Future<void> _person(
  AppDatabase db,
  String id, {
  String name = '张三',
  String? phone,
  String? avatar,
  String? note,
  int? deleted,
}) => db
    .into(db.persons)
    .insert(
      PersonsCompanion.insert(
        personId: Value(id),
        bookId: 'default',
        name: name,
        phone: Value(phone),
        avatarUri: Value(avatar),
        note: Value(note),
        birthday: const Value('1990-02-03'),
        anniversary: const Value('2020-10-01'),
        relationshipType: const Value('朋友'),
        createdAt: _stamp,
        updatedAt: _stamp,
        deletedAt: Value(deleted),
      ),
    )
    .then((_) {});
Future<void> _gift(
  AppDatabase db,
  String id,
  String person, {
  String book = 'default',
  int amount = 12345,
  DateTime? time,
  String event = '生日礼金',
  String direction = '收入',
  String? note,
  List<String>? attachments,
  int? deleted,
}) => db
    .into(db.giftRecords)
    .insert(
      GiftRecordsCompanion.insert(
        recordId: Value(id),
        bookId: book,
        personId: person,
        amountCent: amount,
        occurredAt: (time ?? _day).millisecondsSinceEpoch,
        direction: Value(direction),
        eventName: Value(event),
        note: Value(note),
        attachments: Value(attachments),
        createdAt: _stamp,
        updatedAt: _stamp,
        deletedAt: Value(deleted),
      ),
    )
    .then((_) {});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Every instance below has its own in-memory executor.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late _Rig rig;
  setUp(() async {
    rig = await _Rig.create();
  });
  tearDown(() => rig.close());

  for (final format in DataImportTemplateFormat.values) {
    test(
      'IE01 ${format.name} generated template previews and imports unchanged',
      () async {
        final db = await rig.database();
        final f = await DataImportTemplateService().generateTemplate(
          format: format,
          outputDir: rig.root,
        );
        final preview = await ImportFileReader.preview(filePath: f.path);
        expect(
          importMappingProblem(preview, defaultImportMapping(preview.headers)),
          isNull,
        );
        final job = await rig.import(db, f);
        expect(job.status, 'completed');
        expect(job.failedRows, 0);
        expect((await db.select(db.persons).get()).length, 1);
        expect(
          (await db.select(db.giftRecords).get()).single.amountCent,
          10000,
        );
      },
    );
  }

  test(
    'IE02 CSV BOM quoting multiline emoji and phone leading zeros survive',
    () async {
      final db = await rig.database();
      const note = '第一行,带逗号\r\n第二行"引号"🎁';
      final values = _record(1)
        ..addAll({'联系人姓名': '王,小"明🎁', '备注': note, '手机号': '0013800012345'});
      final f = await rig.csv([_headers, _row(values)], bom: true);
      final job = await rig.import(db, f);
      expect(job.status, 'completed');
      expect(job.successRows, 1);
      expect((await db.select(db.persons).get()).single.phone, '0013800012345');
      expect((await db.select(db.giftRecords).get()).single.note, note);
    },
  );

  for (final amount in ['0.01', '1.1', '1,234.56', '999999999999.99']) {
    test('IE03 exact amount $amount', () async {
      final db = await rig.database();
      final f = await rig.csv([_headers, _row(_record(1, amount: amount))]);
      final job = await rig.import(db, f);
      expect(job.status, 'completed');
      expect(job.failedRows, 0);
      final expected = {
        '0.01': 1,
        '1.1': 110,
        '1,234.56': 123456,
        '999999999999.99': 99999999999999,
      };
      expect(
        (await db.select(db.giftRecords).get()).single.amountCent,
        expected[amount],
      );
    });
  }

  test(
    'IE04 invalid amount date direction and empty identity rejected per row',
    () async {
      final db = await rig.database();
      final bad = [
        for (final a in [
          '0',
          '-1',
          '1.001',
          '1e3',
          'NaN',
          '1000000000000.00',
          '12,34.56',
        ])
          _record(10, amount: a),
        _record(11)..['发生时间'] = '2026-02-30',
        _record(12)..['发生时间'] = '2026-01-01 24:00:00',
        _record(13)..['收支方向'] = '未知',
        _record(14)..addAll({'联系人ID': '', '联系人姓名': ''}),
      ];
      final f = await rig.csv([_headers, ...bad.map(_row), _row(_record(99))]);
      final job = await rig.import(db, f);
      expect(job.status, 'completed');
      expect(job.failedRows, bad.length);
      expect(job.successRows, 1);
      expect((await db.select(db.giftRecords).get()).single.recordId, 'r99');
    },
  );

  for (final body in [
    '数据类型,数据类型\n联系人列表,张三',
    '数据类型,,联系人姓名\n联系人列表,,张三',
    '数据类型,联系人姓名\n联系人列表,张三,多余',
    '数据类型,联系人姓名\n联系人列表,"未闭合',
  ]) {
    test(
      'IE05 malformed CSV rejects without business writes ${body.hashCode}',
      () async {
        final db = await rig.database();
        final f = File(p.join(rig.root.path, 'bad.csv'));
        await f.writeAsString(body);
        await expectLater(
          ImportFileReader.preview(filePath: f.path),
          throwsFormatException,
        );
        final job = await rig.import(db, f, mapping: false);
        expect(job.status, 'failed');
        expect(await db.select(db.persons).get(), isEmpty);
        expect(await db.select(db.giftRecords).get(), isEmpty);
      },
    );
  }

  test('IE06 custom column mapping is honored', () async {
    final db = await rig.database();
    final f = await rig.csv([
      ['类别', '客人', '数额', '往来', '日期'],
      ['礼金收支记录', '刘先生', '88.88', '送礼', '2026/08/12'],
    ]);
    final service = DataImportService(
      db: db,
      documentsDirectoryProvider: () async => rig.root,
    );
    final id = await service.createJob(
      bookId: 'default',
      sourceFilePath: f.path,
      kind: DataImportKind.recordsAndPersons,
      fieldMapping: {
        '数据类型': '类别',
        '联系人姓名': '客人',
        '金额(元)': '数额',
        '收支方向': '往来',
        '发生时间': '日期',
      },
    );
    final h = await service.start(id);
    await h.progress.drain<void>();
    final r = (await db.select(db.giftRecords).get()).single;
    expect(r.direction, '支出');
    expect(r.amountCent, 8888);
  });

  test(
    'IE07 Excel roundtrip preserves exported person and record fields',
    () async {
      final source = await rig.database();
      await _person(
        source,
        'p1',
        name: '🎁李四',
        phone: '001234',
        note: '=SUM(A1:A2),备注\n第二行',
      );
      await _gift(
        source,
        'r1',
        'p1',
        amount: 99999999999999,
        note: '=HYPERLINK("x")',
      );
      final file = await rig.export(source);
      final target = await rig.database();
      final job = await rig.import(target, file);
      expect(job.status, 'completed');
      expect(job.failedRows, 0);
      final a = (await source.select(source.persons).get()).single;
      final b = (await target.select(target.persons).get()).single;
      expect(
        [
          b.personId,
          b.name,
          b.relationshipType,
          b.phone,
          b.birthday,
          b.anniversary,
          b.note,
          b.createdAt,
        ],
        [
          a.personId,
          a.name,
          a.relationshipType,
          a.phone,
          a.birthday,
          a.anniversary,
          a.note,
          a.createdAt,
        ],
      );
      final r = (await target.select(target.giftRecords).get()).single;
      expect(
        [
          r.recordId,
          r.personId,
          r.amountCent,
          r.direction,
          r.occurredAt,
          r.eventName,
          r.note,
        ],
        [
          'r1',
          'p1',
          99999999999999,
          '收入',
          _day.millisecondsSinceEpoch,
          '生日礼金',
          '=HYPERLINK("x")',
        ],
      );
      final x = Excel.decodeBytes(await file.readAsBytes());
      expect(x['礼金记录'].rows[1][8]!.value, isA<TextCellValue>());
    },
  );

  test('IE08 ZIP roundtrip restores avatar and six ordered same-name attachments by bytes', () async {
    final source = await rig.database();
    final avatar = await rig.media('avatars/same.png', [137, 80, 78, 71, 0, 1]);
    final attachments = <String>[];
    for (var i = 0; i < 6; i++) {
      attachments.add(
        (await rig.media('attachments/folder$i/same.png', [
          i,
          0,
          255,
          44,
        ])).path,
      );
    }
    await _person(source, 'p1', avatar: avatar.path);
    await _gift(source, 'r1', 'p1', attachments: attachments);
    final file = await rig.export(
      source,
      format: DataExportFormat.zip,
      images: true,
    );
    final target = await rig.database();
    final job = await rig.import(
      target,
      await rig.unpackWorkbook(file),
      media: file,
    );
    expect(job.status, 'completed');
    expect(job.failedRows, 0);
    final person = (await target.select(target.persons).get()).single;
    expect(
      await File(person.avatarUri!).readAsBytes(),
      await avatar.readAsBytes(),
    );
    final r = (await target.select(target.giftRecords).get()).single;
    expect(r.attachments, hasLength(6));
    for (var i = 0; i < 6; i++) {
      expect(await File(r.attachments![i]).readAsBytes(), [i, 0, 255, 44]);
    }
  });

  test(
    'IE09 export scope includes day boundaries and excludes deleted data',
    () async {
      final db = await rig.database();
      await _person(db, 'active');
      await _person(db, 'deleted', deleted: _stamp);
      await _gift(db, 'start', 'active', time: DateTime(2026, 8, 12));
      await _gift(
        db,
        'end',
        'active',
        time: DateTime(2026, 8, 12, 23, 59, 59, 999),
      );
      await _gift(
        db,
        'before',
        'active',
        time: DateTime(2026, 8, 11, 23, 59, 59, 999),
      );
      await _gift(db, 'after', 'active', time: DateTime(2026, 8, 13));
      await _gift(db, 'deleted-record', 'active', deleted: _stamp);
      await _gift(db, 'deleted-person', 'deleted');
      final f = await rig.export(db, start: _day, end: _day);
      final x = Excel.decodeBytes(await f.readAsBytes());
      expect(
        x['礼金记录'].rows.skip(1).map((r) => r[0]!.value.toString()).toSet(),
        {'start', 'end'},
      );
      expect(x['联系人'].rows.length, 2);
      final scope = await DataExportService().inspectScope(
        db: db,
        start: _day,
        end: _day,
      );
      expect([scope.recordCount, scope.personCount], [2, 1]);
    },
  );

  test('IE10 book scope applies default-book outgoing gift rule', () async {
    final db = await rig.database();
    await db
        .into(db.accountBooks)
        .insert(
          AccountBooksCompanion.insert(
            bookId: const Value('other'),
            name: '婚礼账簿',
            isDefault: const Value(0),
            createdAt: _stamp,
            updatedAt: _stamp,
          ),
        );
    await _person(db, 'p1');
    await _gift(db, 'a', 'p1');
    await _gift(db, 'b', 'p1', book: 'other');
    await _gift(db, 'c', 'p1', book: 'other', direction: '支出');
    for (final entry in {
      'default': {'a', 'c'},
      'other': {'b', 'c'},
    }.entries) {
      final f = await rig.export(db, book: entry.key);
      final x = Excel.decodeBytes(await f.readAsBytes());
      expect(
        x['礼金记录'].rows.skip(1).map((r) => r[0]!.value.toString()).toSet(),
        entry.value,
      );
    }
    await expectLater(
      rig.export(db, book: 'absent'),
      throwsA(isA<DataExportException>()),
    );
  });

  test('IE11 invalid range and no selected content rejected', () async {
    final db = await rig.database();
    await expectLater(
      rig.export(db, start: DateTime(2027), end: DateTime(2026)),
      throwsA(isA<DataExportException>()),
    );
    await expectLater(
      rig.export(db, persons: false, records: false),
      throwsA(isA<DataExportException>()),
    );
    await expectLater(
      rig.export(db, persons: false),
      throwsA(isA<DataExportException>()),
    );
    await expectLater(
      rig.export(db, records: false),
      throwsA(isA<DataExportException>()),
    );
  });

  test('IE12 repeat import skip or retain creates no duplicate IDs', () async {
    final db = await rig.database();
    final f = await rig.csv([_headers, _row(_record(1))]);
    expect((await rig.import(db, f)).successRows, 1);
    final skipped = await rig.import(db, f);
    expect([skipped.successRows, skipped.skippedRows], [0, 1]);
    expect((await rig.import(db, f, duplicate: true)).successRows, 1);
    final records = await db.select(db.giftRecords).get();
    expect(records.length, 2);
    expect(records.map((r) => r.recordId).toSet().length, 2);
    expect((await db.select(db.persons).get()).length, 1);
  });

  test('IE13 ambiguous same-name contacts require explicit identity', () async {
    final db = await rig.database();
    await _person(db, 'a');
    await _person(db, 'b');
    final values = _record(1)..addAll({'联系人ID': '', '联系人姓名': '张三'});
    final job = await rig.import(db, await rig.csv([_headers, _row(values)]));
    expect(job.failedRows, 1);
    expect(await db.select(db.giftRecords).get(), isEmpty);
    values['联系人ID'] = 'b';
    final ok = await rig.import(db, await rig.csv([_headers, _row(values)]));
    expect(ok.failedRows, 0);
    expect((await db.select(db.giftRecords).get()).single.personId, 'b');
  });

  test('IE14 pauses at committed chunk and resumes exactly once', () async {
    final db = await rig.database();
    final f = await rig.csv([
      _headers,
      for (var i = 0; i < 1100; i++) _row(_record(i)),
    ]);
    final service = DataImportService(
      db: db,
      documentsDirectoryProvider: () async => rig.root,
    );
    final id = await service.createJob(
      bookId: 'default',
      sourceFilePath: f.path,
      kind: DataImportKind.recordsAndPersons,
    );
    final h = await service.start(id);
    final progress = <DataImportProgress>[];
    await for (final event in h.progress) {
      progress.add(event);
      if (event.status == DataImportStatus.running &&
          event.successRows >= 1000) {
        await h.pause();
      }
    }
    expect(progress.last.status, DataImportStatus.paused);
    final pausedCount = (await db.select(db.giftRecords).get()).length;
    // The asynchronous progress listener can run while the next row is parsing.
    expect(pausedCount, inInclusiveRange(1000, 1099));
    expect(progress.last.successRows, pausedCount);
    expect(
      (await db.dataImportJobsDao.findById(id))!.lastRowIndex,
      pausedCount,
    );
    final resumed = await service.start(id);
    await resumed.progress.drain<void>();
    final job = (await db.dataImportJobsDao.findById(id))!;
    expect(
      [job.status, job.successRows, job.processedRows],
      ['completed', 1100, 1100],
    );
    expect((await db.select(db.giftRecords).get()).length, 1100);
    await expectLater(service.start(id), throwsA(isA<DataImportException>()));
  });

  test('IE15 cancel retains committed rows and cannot restart', () async {
    final db = await rig.database();
    final f = await rig.csv([
      _headers,
      for (var i = 0; i < 1100; i++) _row(_record(i)),
    ]);
    final service = DataImportService(
      db: db,
      documentsDirectoryProvider: () async => rig.root,
    );
    final id = await service.createJob(
      bookId: 'default',
      sourceFilePath: f.path,
      kind: DataImportKind.recordsAndPersons,
    );
    final h = await service.start(id);
    await for (final event in h.progress) {
      if (event.successRows >= 1000) await h.cancel();
    }
    final job = (await db.dataImportJobsDao.findById(id))!;
    expect(job.status, 'canceled');
    final retained = (await db.select(db.giftRecords).get()).length;
    expect(retained, inInclusiveRange(1000, 1099));
    expect(job.successRows, retained);
    expect(job.lastRowIndex, retained);
    await expectLater(service.start(id), throwsA(isA<DataImportException>()));
  });

  test(
    'IE16 transaction failure keeps prior chunk and truthful checkpoint',
    () async {
      final db = await rig.database();
      final bad = _record(1100)..['联系人姓名'] = '超' * 33;
      final f = await rig.csv([
        _headers,
        for (var i = 0; i < 1000; i++) _row(_record(i)),
        _row(bad),
      ]);
      final job = await rig.import(db, f);
      expect(job.status, 'failed');
      expect(job.successRows, 1000);
      expect(job.lastRowIndex, 1000);
      expect((await db.select(db.persons).get()).length, 1000);
      expect((await db.select(db.giftRecords).get()).length, 1000);
    },
  );

  test('IE17 concurrent import blocked until first task settles', () async {
    final db = await rig.database();
    final f = await rig.csv([_headers, _row(_record(1))]);
    await rig.import(db, f);
    final service = DataImportService(
      db: db,
      documentsDirectoryProvider: () async => rig.root,
    );
    final first = await service.createJob(
      bookId: 'default',
      sourceFilePath: f.path,
      kind: DataImportKind.recordsAndPersons,
    );
    final second = await service.createJob(
      bookId: 'default',
      sourceFilePath: f.path,
      kind: DataImportKind.recordsAndPersons,
    );
    final gate = Completer<bool>();
    final entered = Completer<void>();
    final h = await service.start(
      first,
      onDuplicate: (_) {
        entered.complete();
        return gate.future;
      },
    );
    final done = h.progress.drain<void>();
    await entered.future;
    await expectLater(
      service.start(second),
      throwsA(isA<DataImportException>()),
    );
    gate.complete(false);
    await done;
    final next = await service.start(second, onDuplicate: (_) async => false);
    await next.progress.drain<void>();
    expect(DataImportService.isRunning(db), false);
  });

  test(
    'IE18 records-only and persons-only import modes select intended rows',
    () async {
      final f = await rig.csv([
        _headers,
        _row({'数据类型': '联系人列表', '联系人ID': 'contact', '联系人姓名': '单独联系人'}),
        _row(_record(1)),
      ]);
      for (final kind in [
        DataImportKind.personsOnly,
        DataImportKind.recordsOnly,
      ]) {
        final db = await rig.database();
        final job = await rig.import(db, f, kind: kind);
        expect(job.status, 'completed');
        expect((await db.select(db.persons).get()).length, 1);
        expect(
          (await db.select(db.giftRecords).get()).length,
          kind == DataImportKind.recordsOnly ? 1 : 0,
        );
      }
    },
  );

  test(
    'IE19 timezone offset and milliseconds preserved in default book',
    () async {
      final db = await rig.database();
      final v = _record(1)..['发生时间'] = '2026-08-12T10:30:12.345+05:30';
      final job = await rig.import(db, await rig.csv([_headers, _row(v)]));
      expect(job.status, 'completed');
      expect(
        (await db.select(db.giftRecords).get()).single.occurredAt,
        DateTime.parse(v['发生时间']!).millisecondsSinceEpoch,
      );
    },
  );

  // The following assertions express data-integrity requirements, even when
  // the current implementation fails them. Keep failures visible in the audit.
  test(
    'IE20 Excel without media must remain importable with attachments omitted',
    () async {
      final source = await rig.database();
      final image = await rig.media('a.png', [1, 2, 3]);
      await _person(source, 'p1');
      await _gift(source, 'r1', 'p1', attachments: [image.path]);
      final file = await rig.export(source, images: false);
      final target = await rig.database();
      final job = await rig.import(target, file);
      expect(
        job.status,
        'completed',
        reason: 'Excel UI exports no pictures; absolute attachment references must not abort reimport',
      );
      expect((await target.select(target.giftRecords).get()).length, 1);
    },
  );

  test(
    'IE21 two-sheet roundtrip preserves significant note whitespace',
    () async {
      final source = await rig.database();
      await _person(source, 'p1', note: '  原样联系人备注\n');
      await _gift(source, 'r1', 'p1', note: '  原样礼金备注\n');
      final target = await rig.database();
      await rig.import(target, await rig.export(source));
      expect(
        (await target.select(target.persons).get()).single.note,
        '  原样联系人备注\n',
      );
      expect(
        (await target.select(target.giftRecords).get()).single.note,
        '  原样礼金备注\n',
      );
    },
  );

  test(
    'IE22 importing new default book preserves distinct gift timestamps',
    () async {
      final source = await rig.database(defaultId: 'foreign-default');
      await _person(source, 'p1');
      final later = _day.add(const Duration(days: 10));
      await _gift(source, 'r1', 'p1', book: 'foreign-default');
      await _gift(source, 'r2', 'p1', book: 'foreign-default', time: later);
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      rig.databases.add(target);
      // A non-default target is valid for service import; no existing default is available.
      await target
          .into(target.accountBooks)
          .insert(
            AccountBooksCompanion.insert(
              bookId: const Value('default'),
              name: '接收账簿',
              isDefault: const Value(0),
              createdAt: _stamp,
              updatedAt: _stamp,
            ),
          );
      final job = await rig.import(
        target,
        await rig.export(source),
        duplicate: true,
      );
      expect(job.status, 'completed');
      final r = (await target.select(target.giftRecords).get())
        ..sort((a, b) => a.recordId.compareTo(b.recordId));
      expect(r.map((x) => x.occurredAt).toList(), [
        _day.millisecondsSinceEpoch,
        later.millisecondsSinceEpoch,
      ]);
    },
  );

  test('IE23 CSV contact avatars supplied in media ZIP are imported', () async {
    final db = await rig.database();
    final f = await rig.csv([
      _headers,
      _row({
        '数据类型': '联系人列表',
        '联系人姓名': '头像联系人',
        '头像文件名': 'media/avatars/photo.png',
      }),
    ]);
    final media = await rig.zip({
      'media/avatars/photo.png': [137, 80, 78, 71, 9],
    });
    final job = await rig.import(db, f, media: media);
    expect(job.status, 'completed');
    final person = (await db.select(db.persons).get()).single;
    expect(
      person.avatarUri,
      isNotNull,
      reason:
          'CSV and Excel map the same avatar field and both accept a media ZIP',
    );
    expect(await File(person.avatarUri!).readAsBytes(), [137, 80, 78, 71, 9]);
  });

  test(
    'IE24 attachment custom mapping works when source header is renamed',
    () async {
      final db = await rig.database();
      final headers = [..._headers.where((h) => h != '附件1名称'), '票据'];
      final f = await rig.csv([
        headers,
        _row(_record(1)..['票据'] = 'media/attachments/proof.png', headers),
      ]);
      final media = await rig.zip({
        'media/attachments/proof.png': [1, 9, 8, 4],
      });
      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => rig.root,
      );
      final map = defaultImportMapping(headers)..['附件1名称'] = '票据';
      final id = await service.createJob(
        bookId: 'default',
        sourceFilePath: f.path,
        kind: DataImportKind.recordsAndPersons,
        fieldMapping: map,
        mediaZipPath: media.path,
      );
      final h = await service.start(id);
      await h.progress.drain<void>();
      final record = (await db.select(db.giftRecords).get()).single;
      expect(record.attachments, hasLength(1));
      expect(await File(record.attachments!.single).readAsBytes(), [
        1,
        9,
        8,
        4,
      ]);
    },
  );

  test(
    'IE25 failed database batch does not leave orphaned media files',
    () async {
      final db = await rig.database();
      final f = await rig.workbook({
        '联系人': [
          ['联系人ID', '姓名', '头像文件名'],
          ['p1', '名' * 33, 'media/avatars/a.png'],
        ],
      });
      final media = await rig.zip({
        'media/avatars/a.png': [5, 4, 3, 2],
      });
      final job = await rig.import(db, f, media: media);
      expect(job.status, 'failed');
      expect(await db.select(db.persons).get(), isEmpty);
      final stored = Directory(p.join(rig.root.path, 'media'));
      final files = await stored.exists()
          ? await stored.list(recursive: true).where((e) => e is File).toList()
          : [];
      expect(
        files,
        isEmpty,
        reason: 'Rolled-back rows must not leave permanent avatar files',
      );
    },
  );

  test(
    'IE26 existing ordinary-book roundtrip preserves record time and reason',
    () async {
      final source = await rig.database();
      await source
          .into(source.accountBooks)
          .insert(
            AccountBooksCompanion.insert(
              bookId: const Value('wedding'),
              name: '婚礼',
              reasonType: const Value('婚礼'),
              bookTime: Value(_day.millisecondsSinceEpoch),
              createdAt: _stamp,
              updatedAt: _stamp,
            ),
          );
      await _person(source, 'p1');
      await _gift(source, 'r1', 'p1', book: 'wedding', event: '婚礼');
      final target = await rig.database();
      final job = await rig.import(target, await rig.export(source));
      expect(job.status, 'completed');
      final r = (await target.select(target.giftRecords).get()).single;
      expect(
        [r.bookId, r.eventName, r.occurredAt],
        ['wedding', '婚礼', _day.millisecondsSinceEpoch],
      );
      final book = (await target.accountBooksDao.findById('wedding'))!;
      expect(
        [book.name, book.reasonType, book.bookTime],
        ['婚礼', '婚礼', _day.millisecondsSinceEpoch],
      );
    },
  );

  test('IE27 every rejected row has a complete valid UTF-8 error log', () async {
    final db = await rig.database();
    final rows = [for (var i = 0; i < 80; i++) _row(_record(i, amount: '-1'))];
    final job = await rig.import(db, await rig.csv([_headers, ...rows]));
    expect(job.failedRows, 80);
    // The log is part of the completed job result, so it must be readable now.
    final text = await File(job.errorLogPath!).readAsString();
    for (var i = 2; i <= 81; i++) {
      expect(text, contains('第$i行：金额不合法，已跳过'));
    }
  });

  test(
    'IE28 two-sheet Excel pause resume crosses person-record boundary',
    () async {
      final db = await rig.database();
      final file = await rig.workbook({
        '联系人': [
          ['联系人ID', '姓名'],
          for (var i = 0; i < 2010; i++) ['p$i', '联系人$i'],
        ],
        '礼金记录': [
          ['记录ID', '联系人ID', '联系人姓名', '金额(元)', '收支方向', '发生时间'],
          for (var i = 0; i < 10; i++)
            ['r$i', 'p$i', '联系人$i', '1.01', '收入', _day.toIso8601String()],
        ],
      });
      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => rig.root,
      );
      final id = await service.createJob(
        bookId: 'default',
        sourceFilePath: file.path,
        kind: DataImportKind.recordsAndPersons,
      );
      final h = await service.start(id);
      await for (final event in h.progress) {
        if (event.successRows >= 2000) await h.pause();
      }
      expect((await db.dataImportJobsDao.findById(id))!.status, 'paused');
      final resumed = await service.start(id);
      await resumed.progress.drain<void>();
      final job = (await db.dataImportJobsDao.findById(id))!;
      expect(
        [job.status, job.successRows, job.processedRows],
        ['completed', 2020, 2020],
      );
      expect((await db.select(db.persons).get()).length, 2010);
      expect((await db.select(db.giftRecords).get()).length, 10);
    },
  );

  test(
    'IE29 missing optional avatar does not double-count a source row',
    () async {
      final db = await rig.database();
      final f = await rig.workbook({
        '联系人': [
          ['联系人ID', '姓名', '头像文件名'],
          ['p1', '张三', 'missing.png'],
        ],
      });
      final job = await rig.import(db, f);
      expect(job.status, 'completed');
      expect(job.processedRows, 1);
      expect(
        job.successRows + job.skippedRows + job.failedRows,
        job.processedRows,
        reason: 'Row counters must partition processed rows; missing media is a warning on the imported person',
      );
    },
  );

  test(
    'IE30 corrupted workbook and duplicate Excel headers reject safely',
    () async {
      final db = await rig.database();
      final invalid = File(p.join(rig.root.path, 'invalid.xlsx'));
      await invalid.writeAsBytes([0, 1, 2, 3, 4]);
      await expectLater(
        ImportFileReader.preview(filePath: invalid.path),
        throwsA(anything),
      );
      final failed = await rig.import(db, invalid, mapping: false);
      expect(failed.status, 'failed');
      final duplicate = await rig.workbook({
        '联系人': [
          ['姓名', '姓名'],
          ['张三', '李四'],
        ],
      });
      await expectLater(
        ImportFileReader.preview(filePath: duplicate.path),
        throwsFormatException,
      );
      expect(
        (await rig.import(db, duplicate, mapping: false)).status,
        'failed',
      );
      expect(await db.select(db.persons).get(), isEmpty);
    },
  );

  test('IE31 import file size cap rejects before parsing', () async {
    final f = File(p.join(rig.root.path, 'oversize.csv'));
    final out = await f.open(mode: FileMode.write);
    await out.truncate(32 * 1024 * 1024 + 1);
    await out.close();
    await expectLater(
      ImportFileReader.preview(filePath: f.path),
      throwsFormatException,
    );
    final db = await rig.database();
    final job = await rig.import(db, f, mapping: false);
    expect(job.status, 'failed');
    expect(await db.select(db.persons).get(), isEmpty);
  });

  test(
    'IE32 missing files and unsupported formats produce no import jobs',
    () async {
      final db = await rig.database();
      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => rig.root,
      );
      await expectLater(
        service.createJob(
          bookId: 'default',
          sourceFilePath: p.join(rig.root.path, 'absent.csv'),
          kind: DataImportKind.recordsAndPersons,
        ),
        throwsA(isA<DataImportException>()),
      );
      final text = File(p.join(rig.root.path, 'unsupported.txt'));
      await text.writeAsString('hello');
      await expectLater(
        service.createJob(
          bookId: 'default',
          sourceFilePath: text.path,
          kind: DataImportKind.recordsAndPersons,
        ),
        throwsA(isA<DataImportException>()),
      );
      expect(await db.select(db.dataImportJobs).get(), isEmpty);
    },
  );

  test('IE33 explicit ignored field stays ignored', () async {
    final db = await rig.database();
    final f = await rig.csv([
      _headers,
      _row(_record(1)..['备注'] = 'do not import'),
    ]);
    final service = DataImportService(
      db: db,
      documentsDirectoryProvider: () async => rig.root,
    );
    final mapping = defaultImportMapping(_headers)..['备注'] = '';
    final id = await service.createJob(
      bookId: 'default',
      sourceFilePath: f.path,
      kind: DataImportKind.recordsAndPersons,
      fieldMapping: mapping,
    );
    final h = await service.start(id);
    await h.progress.drain<void>();
    expect((await db.select(db.giftRecords).get()).single.note, isNull);
  });

  test('IE34 separate contact sheet alone previews and imports', () async {
    final db = await rig.database();
    final f = await rig.workbook({
      '联系人': [
        ['联系人ID', '姓名', '关系', '生日', '纪念日', '创建时间'],
        [
          'p1',
          '张三',
          '朋友',
          '1990-02-03',
          '2020-10-01',
          '2026-08-12T10:30:12.345Z',
        ],
      ],
    });
    final preview = await ImportFileReader.preview(filePath: f.path);
    expect(
      importMappingProblem(preview, defaultImportMapping(preview.headers)),
      isNull,
    );
    final job = await rig.import(db, f);
    expect(job.status, 'completed');
    expect(job.successRows, 1);
    final person = (await db.select(db.persons).get()).single;
    expect(
      [person.name, person.birthday, person.anniversary],
      ['张三', '1990-02-03', '2020-10-01'],
    );
  });

  test(
    'IE35 duplicate decision failure rolls back uncommitted rows then resumes',
    () async {
      final db = await rig.database();
      final f = await rig.csv([_headers, _row(_record(1)), _row(_record(1))]);
      final service = DataImportService(
        db: db,
        documentsDirectoryProvider: () async => rig.root,
      );
      final id = await service.createJob(
        bookId: 'default',
        sourceFilePath: f.path,
        kind: DataImportKind.recordsAndPersons,
      );
      final h = await service.start(
        id,
        onDuplicate: (_) async => throw StateError('test interruption'),
      );
      await h.progress.drain<void>();
      final failed = (await db.dataImportJobsDao.findById(id))!;
      expect(failed.status, 'failed');
      expect(failed.successRows, 0);
      expect(failed.lastRowIndex, 0);
      expect(await db.select(db.giftRecords).get(), isEmpty);
      final resumed = await service.start(id, onDuplicate: (_) async => false);
      await resumed.progress.drain<void>();
      final job = (await db.dataImportJobsDao.findById(id))!;
      expect(
        [job.status, job.successRows, job.skippedRows],
        ['completed', 1, 1],
      );
      expect((await db.select(db.giftRecords).get()).length, 1);
    },
  );

  test(
    'IE36 ambiguous media basename must not silently bind the first file',
    () async {
      final db = await rig.database();
      final f = await rig.csv([
        _headers,
        _row(_record(1)..['附件1名称'] = 'photo.png'),
      ]);
      final media = await rig.zip({
        'media/attachments/a/photo.png': [1, 2, 3],
        'media/attachments/b/photo.png': [9, 8, 7],
      });
      final job = await rig.import(db, f, media: media);
      expect(
        job.status,
        'failed',
        reason: 'Two distinct attachments have the same basename; require an exact archive path instead of guessing',
      );
      expect(await db.select(db.giftRecords).get(), isEmpty);
    },
  );

  test('IE37 import media archive cannot write traversal entries outside task root', () async {
    final db = await rig.database();
    final f = await rig.csv([
      _headers,
      _row(_record(1)..['附件1名称'] = 'media/attachments/safe.png'),
    ]);
    final media = await rig.zip({
      '../escaped.png': [0, 0, 0],
      'media/attachments/safe.png': [1, 2, 3],
    });
    final job = await rig.import(db, f, media: media);
    expect(job.status, 'failed');
    expect(await db.select(db.giftRecords).get(), isEmpty);
    expect(await db.select(db.persons).get(), isEmpty);
    final escaped = await rig.root
        .list(recursive: true)
        .where((e) => p.basename(e.path) == 'escaped.png')
        .toList();
    expect(escaped, isEmpty);
  });

  test(
    'IE38 cross-database existing default remaps IDs and keeps distinct times',
    () async {
      final source = await rig.database(defaultId: 'source-default');
      await _person(source, 'p1');
      final later = _day.add(const Duration(days: 10));
      await _gift(source, 'r1', 'p1', book: 'source-default');
      await _gift(source, 'r2', 'p1', book: 'source-default', time: later);
      final target = await rig.database();
      final job = await rig.import(target, await rig.export(source));
      expect(job.status, 'completed');
      final records = await target.select(target.giftRecords).get();
      expect(records.map((r) => r.bookId).toSet(), {'default'});
      expect(records.map((r) => r.occurredAt).toSet(), {
        _day.millisecondsSinceEpoch,
        later.millisecondsSinceEpoch,
      });
      expect((await target.select(target.accountBooks).get()).length, 1);
    },
  );

  test(
    'IE39 real PNG avatar and attachment still decode after ZIP roundtrip',
    () async {
      Future<List<int>> png(ui.Color color) async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawColor(color, ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(2, 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final result = data!.buffer.asUint8List().toList();
        image.dispose();
        picture.dispose();
        return result;
      }

      final avatar = await rig.media(
        'avatars/real.png',
        await png(const ui.Color(0xff123456)),
      );
      final attachment = await rig.media(
        'attachments/real.png',
        await png(const ui.Color(0xffabcdef)),
      );
      final source = await rig.database();
      await _person(source, 'p1', avatar: avatar.path);
      await _gift(source, 'r1', 'p1', attachments: [attachment.path]);
      final zip = await rig.export(
        source,
        format: DataExportFormat.zip,
        images: true,
      );
      final target = await rig.database();
      final job = await rig.import(
        target,
        await rig.unpackWorkbook(zip),
        media: zip,
      );
      expect(job.status, 'completed');
      final person = (await target.select(target.persons).get()).single;
      final record = (await target.select(target.giftRecords).get()).single;
      final paths = [person.avatarUri!, record.attachments!.single];
      final expected = [
        await avatar.readAsBytes(),
        await attachment.readAsBytes(),
      ];
      for (var i = 0; i < paths.length; i++) {
        final bytes = await File(paths[i]).readAsBytes();
        expect(bytes, expected[i]);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect([frame.image.width, frame.image.height], [2, 2]);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  test('IE40 Excel without ZIP imports business rows with media warnings and truthful counts', () async {
    final source = await rig.database();
    final avatar = await rig.media('original/avatar.png', [1, 2, 3]);
    final attachment = await rig.media('original/receipt.png', [9, 8, 7]);
    await _person(source, 'p1', avatar: avatar.path);
    await _gift(source, 'r1', 'p1', attachments: [attachment.path]);
    final target = await rig.database();
    final job = await rig.import(target, await rig.export(source));
    expect(
      [
        job.status,
        job.processedRows,
        job.successRows,
        job.skippedRows,
        job.failedRows,
      ],
      ['completed', 2, 2, 0, 0],
    );
    expect(
      (await target.select(target.persons).get()).single.avatarUri,
      isNull,
    );
    expect(
      (await target.select(target.giftRecords).get()).single.attachments,
      isNull,
    );
    final log = await File(job.errorLogPath!).readAsString();
    expect(log, contains('未设置头像'));
    expect(log, contains('未导入附件'));
    expect(await avatar.readAsBytes(), [1, 2, 3]);
    expect(await attachment.readAsBytes(), [9, 8, 7]);
    expect(
      await rig.storedMedia(),
      hasLength(2),
      reason:
          'Import must never reuse or modify arbitrary local paths from Excel',
    );
  });

  test('IE41 supplied ZIP missing second attachment fails and cleans first uncommitted file', () async {
    final db = await rig.database();
    final headers = [..._headers, '附件2名称'];
    final file = await rig.csv([
      headers,
      _row(
        _record(1)..addAll({
          '附件1名称': 'media/attachments/a.png',
          '附件2名称': 'media/attachments/missing.png',
        }),
        headers,
      ),
    ]);
    final media = await rig.zip({
      'media/attachments/a.png': [1, 2, 3],
    });
    final job = await rig.import(db, file, media: media);
    expect(job.status, 'failed');
    expect(job.successRows, 0);
    expect(await db.select(db.persons).get(), isEmpty);
    expect(await db.select(db.giftRecords).get(), isEmpty);
    expect(await rig.storedMedia(), isEmpty);
    expect(
      await File(job.errorLogPath!).readAsString(),
      contains('附件未在媒体 ZIP 中找到'),
    );
  });

  test('IE42 failed later batch preserves already committed media and removes pending copies', () async {
    final db = await rig.database();
    final first = _record(0)..['附件1名称'] = 'media/attachments/a.png';
    final bad = _record(1000)
      ..addAll({'联系人姓名': '超' * 33, '附件1名称': 'media/attachments/a.png'});
    final file = await rig.csv([
      _headers,
      _row(first),
      for (var i = 1; i < 1000; i++) _row(_record(i)),
      _row(bad),
    ]);
    final media = await rig.zip({
      'media/attachments/a.png': [7, 1, 9],
    });
    final job = await rig.import(db, file, media: media);
    expect(
      [job.status, job.successRows, job.lastRowIndex],
      ['failed', 1000, 1000],
    );
    expect((await db.select(db.giftRecords).get()).length, 1000);
    final record = await (db.select(
      db.giftRecords,
    )..where((t) => t.recordId.equals('r0'))).getSingle();
    expect(await File(record.attachments!.single).readAsBytes(), [7, 1, 9]);
    expect((await rig.storedMedia()).map((f) => f.path).toList(), [
      record.attachments!.single,
    ]);
  });

  test('IE43 ambiguous avatar basename rejects instead of silently choosing an image', () async {
    final db = await rig.database();
    final file = await rig.csv([
      _headers,
      _row({'数据类型': '联系人列表', '联系人姓名': '张三', '头像文件名': 'photo.png'}),
    ]);
    final media = await rig.zip({
      'media/avatars/a/photo.png': [1, 2, 3],
      'media/avatars/b/photo.png': [9, 8, 7],
    });
    final job = await rig.import(db, file, media: media);
    expect(job.status, 'failed');
    expect(await db.select(db.persons).get(), isEmpty);
    expect(await rig.storedMedia(), isEmpty);
    expect(await File(job.errorLogPath!).readAsString(), contains('存在歧义'));
  });

  test('IE44 exact media path disambiguates same-name attachments', () async {
    final db = await rig.database();
    final file = await rig.csv([
      _headers,
      _row(_record(1)..['附件1名称'] = 'media/attachments/b/photo.png'),
    ]);
    final media = await rig.zip({
      'media/attachments/a/photo.png': [1, 2, 3],
      'media/attachments/b/photo.png': [9, 8, 7],
    });
    final job = await rig.import(db, file, media: media);
    expect(job.status, 'completed');
    final record = (await db.select(db.giftRecords).get()).single;
    expect(await File(record.attachments!.single).readAsBytes(), [9, 8, 7]);
  });

  test('IE45 avatar and attachment folders disambiguate the same basename by context', () async {
    final db = await rig.database();
    final file = await rig.csv([
      _headers,
      _row({
        '数据类型': '联系人列表',
        '联系人ID': 'p1',
        '联系人姓名': '联系人1',
        '头像文件名': 'photo.png',
      }),
      _row(_record(1)..['附件1名称'] = 'photo.png'),
    ]);
    final media = await rig.zip({
      'media/avatars/photo.png': [1, 2, 3],
      'media/attachments/photo.png': [9, 8, 7],
    });
    final job = await rig.import(db, file, media: media);
    expect([job.status, job.successRows, job.failedRows], ['completed', 2, 0]);
    final person = (await db.select(db.persons).get()).single;
    final record = (await db.select(db.giftRecords).get()).single;
    expect(await File(person.avatarUri!).readAsBytes(), [1, 2, 3]);
    expect(await File(record.attachments!.single).readAsBytes(), [9, 8, 7]);
  });

  test('IE46 supplied ZIP missing referenced avatar rejects and keeps counts uncommitted', () async {
    final db = await rig.database();
    final file = await rig.workbook({
      '联系人': [
        ['联系人ID', '姓名', '头像文件名'],
        ['p1', '张三', 'media/avatars/missing.png'],
      ],
    });
    final media = await rig.zip({
      'media/avatars/another.png': [1, 2, 3],
    });
    final job = await rig.import(db, file, media: media);
    expect([job.status, job.successRows], ['failed', 0]);
    expect(await db.select(db.persons).get(), isEmpty);
    expect(await rig.storedMedia(), isEmpty);
    expect(
      await File(job.errorLogPath!).readAsString(),
      contains('头像未在媒体 ZIP 中找到'),
    );
  });
}
