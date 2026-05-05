import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/export/data_export_service.dart';
import 'package:newshangli/ui/app_data.dart';

import '../test_utils.dart';

void main() {
  test('Export records writes xlsx file', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await waitAppDataReady(data);
    final dir = await Directory.systemTemp.createTemp('newshangli_export_');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    final service = DataExportService();
    final file = await service.export(
      loggedIn: true,
      data: data,
      request: DataExportRequest(
        format: DataExportFormat.excel,
        start: DateTime(2025, 1, 1),
        end: DateTime(2026, 12, 31),
        bookId: null,
        includeRecords: true,
        includePersons: false,
        includeImages: false,
      ),
      outputDir: dir,
    );

    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(4));
    expect(bytes[0], 0x50);
    expect(bytes[1], 0x4B);
  });

  test('Export excel splits records and persons into two sheets', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await waitAppDataReady(data);
    final dir = await Directory.systemTemp.createTemp('newshangli_export_');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    final service = DataExportService();
    final file = await service.export(
      loggedIn: true,
      data: data,
      request: DataExportRequest(
        format: DataExportFormat.excel,
        start: DateTime(2025, 1, 1),
        end: DateTime(2026, 12, 31),
        bookId: null,
        includeRecords: true,
        includePersons: true,
        includeImages: false,
      ),
      outputDir: dir,
    );

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    expect(excel.tables.keys.contains('礼金记录'), isTrue);
    expect(excel.tables.keys.contains('关系人'), isTrue);
  });

  test('Export records throws when no record in range', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await waitAppDataReady(data);
    final dir = await Directory.systemTemp.createTemp('newshangli_export_');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    final service = DataExportService();
    await expectLater(
      () => service.export(
        loggedIn: true,
        data: data,
        request: DataExportRequest(
          format: DataExportFormat.excel,
          start: DateTime(2000, 1, 1),
          end: DateTime(2000, 1, 2),
          bookId: null,
          includeRecords: true,
          includePersons: false,
          includeImages: false,
        ),
        outputDir: dir,
      ),
      throwsA(
        isA<DataExportException>().having(
          (e) => e.message,
          'message',
          contains('没有收支记录'),
        ),
      ),
    );
  });

  test('Export zip packs local image files when includeImages', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await waitAppDataReady(data);

    final dir = await Directory.systemTemp.createTemp('newshangli_export_');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    final img = File(p.join(dir.path, 'avatar.png'));
    await img.writeAsBytes(<int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ], flush: true);

    data.createPerson(
      name: '本地头像',
      relationship: '朋友',
      phone: null,
      note: null,
      avatarUrl: img.path,
    );
    final person = data.persons.first;
    data.createRecord(
      personId: person.id,
      direction: RecordDirection.expense,
      amountCent: 100,
      eventName: '测试',
      paymentMethod: '现金',
      occurredAt: DateTime(2026, 1, 2, 12, 0),
      note: null,
    );

    final service = DataExportService();
    final file = await service.export(
      loggedIn: true,
      data: data,
      request: DataExportRequest(
        format: DataExportFormat.zip,
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
        bookId: null,
        includeRecords: true,
        includePersons: true,
        includeImages: true,
      ),
      outputDir: dir,
    );

    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    final decoded = ZipDecoder().decodeBytes(bytes);
    final names = decoded.files.map((f) => f.name).toList();
    expect(names.any((n) => n.endsWith('.xlsx')), isTrue);
    expect(names.contains('images/avatar.png'), isTrue);
    expect(names.contains('图片清单.txt'), isTrue);
  });

  test(
    'Export records filters by bookId and treats empty bookId as default',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final data = AppData();
      await waitAppDataReady(data);
      final dir = await Directory.systemTemp.createTemp('newshangli_export_');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      });

      final person = data.persons.first;
      data.createRecord(
        personId: person.id,
        direction: RecordDirection.income,
        amountCent: 100,
        eventName: '默认账本记录',
        paymentMethod: '现金',
        occurredAt: DateTime(2030, 1, 2, 12, 0),
        note: null,
      );
      data.createRecord(
        bookId: 'book_other',
        personId: person.id,
        direction: RecordDirection.income,
        amountCent: 200,
        eventName: '其他账本记录',
        paymentMethod: '现金',
        occurredAt: DateTime(2030, 1, 2, 12, 30),
        note: null,
      );

      final service = DataExportService();
      final file = await service.export(
        loggedIn: true,
        data: data,
        request: DataExportRequest(
          format: DataExportFormat.excel,
          start: DateTime(2030, 1, 1),
          end: DateTime(2030, 1, 3),
          bookId: AppData.defaultBookId,
          includeRecords: true,
          includePersons: false,
          includeImages: false,
        ),
        outputDir: dir,
      );

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables['礼金记录'];
      expect(sheet, isNotNull);

      final nonEmptyRows = sheet!.rows.where((row) {
        return row.any((c) => (c?.value?.toString() ?? '').trim().isNotEmpty);
      }).toList();
      // 1 行表头 + 1 行默认账本记录
      expect(nonEmptyRows.length, 2);
    },
  );

  test('Drift导出ZIP包含双Sheet及头像附件列和媒体文件', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
    });
    final dir = await Directory.systemTemp.createTemp(
      'newshangli_export_drift_',
    );
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    final avatar = File(p.join(dir.path, 'avatar.png'));
    await avatar.writeAsBytes(<int>[1, 2, 3], flush: true);
    final att = File(p.join(dir.path, 'a.jpg'));
    await att.writeAsBytes(<int>[4, 5, 6], flush: true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final bookId = await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(name: 'b1', createdAt: now, updatedAt: now),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value('p1'),
        bookId: bookId,
        name: '张三',
        relationshipType: const Value('朋友'),
        avatarUri: Value(avatar.path),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        recordId: const Value('r1'),
        bookId: bookId,
        personId: 'p1',
        amountCent: 100,
        direction: const Value('收入'),
        eventName: const Value('测试'),
        paymentMethod: const Value('现金'),
        occurredAt: now,
        attachments: Value(<String>[att.path]),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final service = DataExportService();
    final file = await service.exportFromDrift(
      loggedIn: true,
      db: db,
      request: DataExportRequest(
        format: DataExportFormat.zip,
        start: DateTime(2020, 1, 1),
        end: DateTime(2100, 1, 1),
        includeRecords: true,
        includePersons: true,
        includeImages: true,
      ),
      outputDir: dir,
    );
    final decoded = ZipDecoder().decodeBytes(await file.readAsBytes());
    final names = decoded.files.map((e) => e.name).toList();
    expect(names.any((n) => n.contains('media/avatars/')), true);
    expect(names.any((n) => n.contains('media/attachments/')), true);
    final xlsxEntry = decoded.files.firstWhere((e) => e.name.endsWith('.xlsx'));
    final excel = Excel.decodeBytes(xlsxEntry.content as List<int>);
    expect(excel.tables.keys.contains('礼金记录'), true);
    expect(excel.tables.keys.contains('关系人'), true);
    final header = excel.tables['礼金记录']!.rows.first
        .map((e) => (e?.value?.toString() ?? ''))
        .toList();
    expect(header.contains('联系人头像'), false);
    expect(header.contains('附件1名称'), true);
  });

  test('Drift按账本导出时只包含该账本关系人和媒体文件', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
    });
    final dir = await Directory.systemTemp.createTemp(
      'newshangli_export_book_',
    );
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    final avatar1 = File(p.join(dir.path, 'avatar_book_1.png'));
    final avatar2 = File(p.join(dir.path, 'avatar_book_2.png'));
    await avatar1.writeAsBytes(<int>[1, 2, 3], flush: true);
    await avatar2.writeAsBytes(<int>[4, 5, 6], flush: true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final book1 = await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(name: '账本一', createdAt: now, updatedAt: now),
    );
    final book2 = await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(name: '账本二', createdAt: now, updatedAt: now),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value('p_book_1'),
        bookId: book1,
        name: '张三',
        relationshipType: const Value('朋友'),
        avatarUri: Value(avatar1.path),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value('p_book_2'),
        bookId: book2,
        name: '李四',
        relationshipType: const Value('同事'),
        avatarUri: Value(avatar2.path),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        recordId: const Value('r_book_1'),
        bookId: book1,
        personId: 'p_book_1',
        amountCent: 10000,
        direction: const Value('收入'),
        eventName: const Value('测试'),
        paymentMethod: const Value('现金'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final service = DataExportService();
    final file = await service.exportFromDrift(
      loggedIn: true,
      db: db,
      request: DataExportRequest(
        format: DataExportFormat.zip,
        start: DateTime(2020, 1, 1),
        end: DateTime(2100, 1, 1),
        bookId: book1,
        includeRecords: true,
        includePersons: true,
        includeImages: true,
      ),
      outputDir: dir,
    );

    final decoded = ZipDecoder().decodeBytes(await file.readAsBytes());
    final names = decoded.files.map((e) => e.name).toList();
    expect(names.any((n) => n.contains('p_book_1')), true);
    expect(names.any((n) => n.contains('p_book_2')), false);

    final xlsxEntry = decoded.files.firstWhere((e) => e.name.endsWith('.xlsx'));
    final excel = Excel.decodeBytes(xlsxEntry.content as List<int>);
    final personCells = excel.tables['关系人']!.rows
        .expand((row) => row)
        .map((cell) => cell?.value?.toString() ?? '')
        .toList();
    expect(personCells, contains('张三'));
    expect(personCells, isNot(contains('李四')));
  });
}
