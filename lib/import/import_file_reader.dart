import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;

class ImportPreview {
  const ImportPreview({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;
}

class ImportFileReader {
  static Future<ImportPreview> preview({
    required String filePath,
    int maxPreviewRows = 20,
  }) async {
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.csv') {
      return _previewCsv(filePath: filePath, maxPreviewRows: maxPreviewRows);
    }
    if (ext == '.xlsx') {
      return _previewXlsx(filePath: filePath, maxPreviewRows: maxPreviewRows);
    }
    throw ArgumentError('不支持的文件类型：$ext');
  }

  static Future<ImportPreview> _previewXlsx({
    required String filePath,
    required int maxPreviewRows,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (excel.sheets.isEmpty) {
      throw const FormatException('Excel 内容为空');
    }
    final sheet = excel.sheets.values.first;
    final all = sheet.rows;
    if (all.isEmpty) {
      throw const FormatException('Excel 表格为空');
    }

    final headers = all.first.map((c) => (c?.value?.toString() ?? '').trim()).toList();
    final rows = <List<String>>[];
    for (var i = 1; i < all.length && rows.length < maxPreviewRows; i++) {
      final row = all[i];
      final cells = row.map((c) => (c?.value?.toString() ?? '').trim()).toList();
      rows.add(cells);
    }
    return ImportPreview(headers: headers, rows: rows);
  }

  static Future<ImportPreview> _previewCsv({
    required String filePath,
    required int maxPreviewRows,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FormatException('文件不存在');
    }

    final raf = await file.open();
    try {
      const maxBytes = 1024 * 1024;
      final size = await raf.length();
      final readBytes = size < maxBytes ? size : maxBytes;
      final bytes = await raf.read(readBytes);
      final text = _decodeUtf8AllowBom(bytes);
      final lines = const LineSplitter().convert(text);
      if (lines.isEmpty) {
        throw const FormatException('CSV 内容为空');
      }
      final headerCells = _parseCsvLine(lines.first);
      final headers = headerCells.map((s) => s.trim()).toList();
      final rows = <List<String>>[];
      for (var i = 1; i < lines.length && rows.length < maxPreviewRows; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        rows.add(_parseCsvLine(line).map((s) => s.trim()).toList());
      }
      return ImportPreview(headers: headers, rows: rows);
    } finally {
      await raf.close();
    }
  }

  static String _decodeUtf8AllowBom(List<int> bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static List<String> _parseCsvLine(String line) {
    final out = <String>[];
    final b = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          b.write('"');
          i++;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }
      if (ch == ',' && !inQuotes) {
        out.add(b.toString());
        b.clear();
        continue;
      }
      b.write(ch);
    }
    out.add(b.toString());
    return out;
  }
}

