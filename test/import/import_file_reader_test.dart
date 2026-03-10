import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:newshangli/import/import_file_reader.dart';

void main() {
  group('ImportFileReader', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('newshangli_preview_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('CSV 预览：解析表头与前N行（含引号转义）', () async {
      final f = File('${tempDir.path}/a.csv');
      await f.writeAsString(
        [
          '数据类型,备注',
          '礼金收支记录,"包含,逗号与""引号"""',
          '关系人列表,普通备注',
        ].join('\n'),
        flush: true,
      );

      final preview = await ImportFileReader.preview(filePath: f.path, maxPreviewRows: 10);
      expect(preview.headers, <String>['数据类型', '备注']);
      expect(preview.rows.length, 2);
      expect(preview.rows.first[0], '礼金收支记录');
      expect(preview.rows.first[1], '包含,逗号与"引号"');
    });
  });
}

