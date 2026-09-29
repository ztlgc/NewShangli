import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'csv_document.dart';
import '../backup/restore_safety.dart';

class ImportPreview {
  const ImportPreview({required this.headers, required this.rows});
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
      final rows = await CsvDocument.read(filePath);
      return ImportPreview(
        headers: rows.first.map((v) => v.trim()).toList(),
        rows: rows.skip(1).take(maxPreviewRows).toList(),
      );
    }
    if (ext != '.xlsx') throw ArgumentError('不支持的文件类型：$ext');
    final file = File(filePath);
    if (await file.length() > CsvDocument.maxFileBytes) {
      throw const FormatException('文件超过 32 MB，请拆分后导入');
    }
    final bytes = await file.readAsBytes();
    RestoreSafety.decodeZip(bytes);
    final excel = Excel.decodeBytes(bytes);
    if (excel.sheets.isEmpty) throw const FormatException('Excel 内容为空');
    final sheet =
        excel.sheets['礼金记录'] ??
        excel.sheets['收支记录'] ??
        excel.sheets.values.first;
    if (sheet.rows.isEmpty) throw const FormatException('Excel 表格为空');
    final headers = sheet.rows.first
        .map((c) => (c?.value?.toString() ?? '').trim())
        .toList();
    CsvDocument.validateHeaders(headers);
    return ImportPreview(
      headers: headers,
      rows: sheet.rows
          .skip(1)
          .take(maxPreviewRows)
          .map((r) => r.map((c) => c?.value?.toString() ?? '').toList())
          .toList(),
    );
  }
}
