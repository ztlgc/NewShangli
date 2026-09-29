import 'dart:convert';
import 'dart:io';

/// UTF-8 CSV 逻辑行解析；预览和执行共享。
class CsvDocument {
  static const maxFileBytes = 32 * 1024 * 1024;
  static Future<List<List<String>>> read(String path) async {
    final file = File(path);
    if (await file.length() > maxFileBytes) {
      throw const FormatException('文件超过 32 MB，请拆分后导入');
    }
    var text = utf8.decode(await file.readAsBytes());
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    return parse(text);
  }

  static void validateHeaders(List<String> headers) {
    final seen = <String>{};
    for (final header in headers) {
      final name = header.trim();
      if (name.isEmpty) throw const FormatException('表头包含空列名');
      if (!seen.add(name)) throw FormatException('表头重复：$name');
    }
  }

  static List<List<String>> parse(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    var cell = StringBuffer();
    var quoted = false;
    var closed = false;
    void finishCell() {
      row.add(cell.toString());
      cell = StringBuffer();
      closed = false;
    }

    void finishRow() {
      finishCell();
      if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
            closed = true;
          }
        } else {
          cell.write(ch);
        }
        continue;
      }
      if (ch == ',') {
        finishCell();
        continue;
      }
      if (ch == '\r' || ch == '\n') {
        if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        finishRow();
        continue;
      }
      if (closed) {
        throw FormatException(
          '第 ${rows.length + 1} 行：引号后存在多余字符',
        );
      }
      if (ch == '"') {
        if (cell.isNotEmpty) {
          throw FormatException(
            '第 ${rows.length + 1} 行：引号位置错误',
          );
        }
        quoted = true;
      } else {
        cell.write(ch);
      }
    }
    if (quoted) {
      throw FormatException('第 ${rows.length + 1} 行：引号未闭合');
    }
    if (cell.isNotEmpty || row.isNotEmpty || closed) finishRow();
    if (rows.isEmpty) throw const FormatException('文件为空');
    validateHeaders(rows.first);
    for (var i = 1; i < rows.length; i++) {
      if (rows[i].length != rows.first.length) {
        throw FormatException('第 ${i + 1} 行：列数与表头不一致');
      }
    }
    return rows;
  }
}
