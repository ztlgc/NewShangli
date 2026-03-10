import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

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
    expect(excel.tables.keys.contains('收支记录'), isTrue);
    expect(excel.tables.keys.contains('联系人'), isTrue);
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
        isA<DataExportException>().having((e) => e.message, 'message', contains('没有收支记录')),
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
    await img.writeAsBytes(<int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], flush: true);

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

  test('Export records filters by bookId and treats empty bookId as default', () async {
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
    final sheet = excel.tables['收支记录'];
    expect(sheet, isNotNull);

    final nonEmptyRows = sheet!.rows.where((row) {
      return row.any((c) => (c?.value?.toString() ?? '').trim().isNotEmpty);
    }).toList();
    // 1 行表头 + 1 行默认账本记录
    expect(nonEmptyRows.length, 2);
  });
}
