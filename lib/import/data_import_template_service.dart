import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum DataImportTemplateFormat { csv, xlsx }

class DataImportTemplateService {
  Future<File> generateTemplate({
    required DataImportTemplateFormat format,
    Directory? outputDir,
  }) async {
    final rows = <List<String>>[
      <String>[
        '数据类型',
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
      ],
      <String>[
        '关系人列表',
        '',
        '',
        '',
        '',
        '',
        '',
        '张三',
        '朋友',
        '13800000000',
        '',
        '2026-01-01 10:00',
        '',
      ],
      <String>[
        '礼金收支记录',
        '',
        '收入',
        '100.00',
        '10000',
        '婚礼随礼',
        '',
        '张三',
        '朋友',
        '13800000000',
        '现金',
        '2026-01-01 10:00',
        '示例备注',
      ],
    ];

    final dir = outputDir ?? await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, 'imports', 'templates'));
    await outDir.create(recursive: true);

    final ts = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final nameBase = '尚礼_导入模板_${ts.year}${two(ts.month)}${two(ts.day)}_${two(ts.hour)}${two(ts.minute)}${two(ts.second)}';

    switch (format) {
      case DataImportTemplateFormat.csv:
        final file = File(p.join(outDir.path, '$nameBase.csv'));
        await file.writeAsString(_encodeCsv(rows), flush: true);
        return file;
      case DataImportTemplateFormat.xlsx:
        final bytes = _encodeXlsx(rows);
        final file = File(p.join(outDir.path, '$nameBase.xlsx'));
        await file.writeAsBytes(bytes, flush: true);
        return file;
    }
  }

  String _encodeCsv(List<List<String>> rows) {
    final b = StringBuffer();
    for (final r in rows) {
      for (var i = 0; i < r.length; i++) {
        if (i > 0) b.write(',');
        b.write(_escapeCsvCell(r[i]));
      }
      b.writeln();
    }
    return b.toString();
  }

  String _escapeCsvCell(String s) {
    final needsQuote = s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
    if (!needsQuote) return s;
    return '"${s.replaceAll('"', '""')}"';
  }

  List<int> _encodeXlsx(List<List<String>> rows) {
    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
        cell.value = TextCellValue(row[c]);
      }
    }
    final bytes = excel.encode();
    if (bytes == null) {
      throw const FileSystemException('Excel 生成失败');
    }
    return bytes;
  }
}
