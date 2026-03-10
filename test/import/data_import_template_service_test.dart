import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:newshangli/import/data_import_template_service.dart';

void main() {
  group('DataImportTemplateService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('newshangli_template_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('生成 CSV 模板文件', () async {
      final service = DataImportTemplateService();
      final file = await service.generateTemplate(
        format: DataImportTemplateFormat.csv,
        outputDir: tempDir,
      );
      expect(await file.exists(), isTrue);
      final text = await file.readAsString();
      expect(text, contains('数据类型'));
      expect(text, contains('礼金收支记录'));
    });

    test('生成 XLSX 模板文件', () async {
      final service = DataImportTemplateService();
      final file = await service.generateTemplate(
        format: DataImportTemplateFormat.xlsx,
        outputDir: tempDir,
      );
      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(4));
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
    });
  });
}

