import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ui/app_data.dart';

enum DataExportFormat { excel, zip }

class DataExportRequest {
  const DataExportRequest({
    required this.format,
    required this.start,
    required this.end,
    this.bookId,
    required this.includeRecords,
    required this.includePersons,
    required this.includeImages,
  });

  final DataExportFormat format;
  final DateTime start;
  final DateTime end;
  /// 需要导出的礼簿（账簿）ID：
  /// - 为 null 表示导出所有礼簿
  /// - 非 null 时，只导出该礼簿下的记录（记录未指定 bookId 时会被视为默认礼簿）
  final String? bookId;
  final bool includeRecords;
  final bool includePersons;
  final bool includeImages;
}

class DataExportService {
  Future<File> export({
    required bool loggedIn,
    required AppData data,
    required DataExportRequest request,
    Directory? outputDir,
  }) async {
    if (!loggedIn) {
      throw const DataExportException('未登录，无法导出');
    }
    if (!request.includeRecords && !request.includePersons) {
      throw const DataExportException('请至少选择一种导出内容');
    }
    final start = _startOfDay(request.start);
    final endExclusive = _startOfDay(request.end).add(const Duration(days: 1));
    if (!start.isBefore(endExclusive)) {
      throw const DataExportException('时间范围不合法');
    }

    final recordRows = <List<String>>[];
    final personRows = <List<String>>[];

    var recordCount = 0;
    if (request.includeRecords) {
      recordRows.add(
        <String>[
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
          if (request.includeImages) '图片/头像',
        ],
      );
      for (final r in data.records) {
        if (r.occurredAt.isBefore(start) || !r.occurredAt.isBefore(endExclusive)) continue;
        if (request.bookId != null) {
          final effectiveBookId = data.resolveBookId(r.bookId);
          final targetBookId = data.resolveBookId(request.bookId);
          if (effectiveBookId != targetBookId) continue;
        }
        recordCount++;
        final person = data.findPerson(r.personId);
        recordRows.add(
          <String>[
            r.id,
            r.direction == RecordDirection.income ? '收入' : '支出',
            (r.amountCent / 100.0).toStringAsFixed(2),
            r.amountCent.toString(),
            r.eventName,
            r.personId,
            r.personName,
            person?.relationship ?? '',
            person?.phone ?? '',
            r.paymentMethod,
            _formatDateTime(r.occurredAt),
            r.note ?? '',
            if (request.includeImages) r.personAvatarUrl ?? '',
          ],
        );
      }
    }

    var personCount = 0;
    if (request.includePersons) {
      personRows.add(
        <String>[
          '关系人ID',
          '姓名',
          '关系',
          '手机号',
          '创建时间',
          '备注',
          if (request.includeImages) '图片/头像',
        ],
      );
      for (final person in data.persons) {
        personCount++;
        personRows.add(
          <String>[
            person.id,
            person.name,
            person.relationship,
            person.phone ?? '',
            _formatDateTime(person.createdAt),
            person.note ?? '',
            if (request.includeImages) person.avatarUrl ?? '',
          ],
        );
      }
    }

    if (request.includeRecords && !request.includePersons && recordCount == 0) {
      throw const DataExportException('所选时间范围内没有收支记录');
    }
    if (!request.includeRecords && request.includePersons && personCount == 0) {
      throw const DataExportException('当前没有可导出的关系人');
    }

    final dir = outputDir ?? Directory((await getApplicationDocumentsDirectory()).path);
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);

    final baseName = _buildFileNameBase(start: request.start, end: request.end);
    switch (request.format) {
      case DataExportFormat.excel:
        final bytes = _encodeXlsx(
          recordRows: recordRows,
          personRows: personRows,
          includeRecords: request.includeRecords,
          includePersons: request.includePersons,
        );
        final file = File(p.join(exportDir.path, '$baseName.xlsx'));
        await file.writeAsBytes(bytes, flush: true);
        return file;
      case DataExportFormat.zip:
        final xlsxBytes = _encodeXlsx(
          recordRows: recordRows,
          personRows: personRows,
          includeRecords: request.includeRecords,
          includePersons: request.includePersons,
        );
        final archive = Archive()..addFile(ArchiveFile('$baseName.xlsx', xlsxBytes.length, xlsxBytes));
        if (request.includeImages) {
          await _addLocalImagesToArchive(
            archive: archive,
            data: data,
            request: request,
            start: start,
            endExclusive: endExclusive,
          );
        }
        final zipped = ZipEncoder().encode(archive);
        if (zipped == null) {
          throw const DataExportException('ZIP 打包失败');
        }
        final file = File(p.join(exportDir.path, '$baseName.zip'));
        await file.writeAsBytes(zipped, flush: true);
        return file;
    }
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  String _buildFileNameBase({required DateTime start, required DateTime end}) {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = '${start.year}${two(start.month)}${two(start.day)}';
    final e = '${end.year}${two(end.month)}${two(end.day)}';
    final ts = DateTime.now();
    final t = '${ts.year}${two(ts.month)}${two(ts.day)}_${two(ts.hour)}${two(ts.minute)}${two(ts.second)}';
    return '尚礼_导出_${s}_${e}_$t';
  }

  List<int> _encodeXlsx({
    required List<List<String>> recordRows,
    required List<List<String>> personRows,
    required bool includeRecords,
    required bool includePersons,
  }) {
    final excel = Excel.createExcel();
    if (!includeRecords && !includePersons) {
      throw const DataExportException('请至少选择一种导出内容');
    }

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FFE5E7EB'),
      fontColorHex: ExcelColor.fromHexString('FF111827'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final bodyStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('FF111827'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    void writeSheet(Sheet sheet, List<List<String>> rows) {
      for (var r = 0; r < rows.length; r++) {
        final row = rows[r];
        for (var c = 0; c < row.length; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
          cell.value = TextCellValue(row[c]);
          cell.cellStyle = r == 0 ? headerStyle : bodyStyle;
        }
      }
    }

    if (includeRecords) {
      excel.rename('Sheet1', '收支记录');
      writeSheet(excel['收支记录'], recordRows);
      if (includePersons) {
        writeSheet(excel['联系人'], personRows);
      }
    } else {
      excel.rename('Sheet1', '联系人');
      writeSheet(excel['联系人'], personRows);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw const DataExportException('Excel 生成失败');
    }
    return bytes;
  }

  String _buildImageUrlManifest({
    required AppData data,
    required DataExportRequest request,
    required DateTime start,
    required DateTime endExclusive,
  }) {
    final b = StringBuffer();
    b.writeln('说明：当前应用内图片多为网络链接，本 ZIP 仅收集链接清单。');
    b.writeln();
    if (request.includeRecords) {
      b.writeln('收支记录相关头像/图片链接：');
      for (final r in data.records) {
        if (r.occurredAt.isBefore(start) || !r.occurredAt.isBefore(endExclusive)) continue;
        if (request.bookId != null) {
          final effectiveBookId = data.resolveBookId(r.bookId);
          final targetBookId = data.resolveBookId(request.bookId);
          if (effectiveBookId != targetBookId) continue;
        }
        final url = r.personAvatarUrl;
        if (url == null || url.trim().isEmpty) continue;
        b.writeln('${r.id}\t${r.personName}\t$url');
      }
      b.writeln();
    }
    if (request.includePersons) {
      b.writeln('关系人头像链接：');
      for (final p in data.persons) {
        final url = p.avatarUrl;
        if (url == null || url.trim().isEmpty) continue;
        b.writeln('${p.id}\t${p.name}\t$url');
      }
      b.writeln();
    }
    return b.toString();
  }

  Future<void> _addLocalImagesToArchive({
    required Archive archive,
    required AppData data,
    required DataExportRequest request,
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final seen = <String>{};
    final usedNames = <String, int>{};
    final included = <String>[];
    final skipped = <String>[];

    Future<void> addPath(String source) async {
      final raw = source.trim();
      if (raw.isEmpty) return;
      if (!seen.add(raw)) return;

      final path = _tryParseFilePath(raw);
      if (path == null) {
        skipped.add(raw);
        return;
      }
      final f = File(path);
      if (!await f.exists()) {
        skipped.add(raw);
        return;
      }

      final bytes = await f.readAsBytes();
      final base = p.basename(path);
      final safe = base.trim().isEmpty ? 'image' : base;
      final count = usedNames[safe] ?? 0;
      usedNames[safe] = count + 1;
      final finalName = count == 0 ? safe : '${p.basenameWithoutExtension(safe)}_${count + 1}${p.extension(safe)}';

      archive.addFile(ArchiveFile(p.posix.join('images', finalName), bytes.length, bytes));
      included.add(raw);
    }

    if (request.includeRecords) {
      for (final r in data.records) {
        if (r.occurredAt.isBefore(start) || !r.occurredAt.isBefore(endExclusive)) continue;
        if (request.bookId != null) {
          final effectiveBookId = data.resolveBookId(r.bookId);
          final targetBookId = data.resolveBookId(request.bookId);
          if (effectiveBookId != targetBookId) continue;
        }
        final url = r.personAvatarUrl;
        if (url != null) {
          await addPath(url);
        }
      }
    }
    if (request.includePersons) {
      for (final person in data.persons) {
        final url = person.avatarUrl;
        if (url != null) {
          await addPath(url);
        }
      }
    }

    final manifest = _buildImageLocalManifest(included: included, skipped: skipped);
    final b = utf8.encode(manifest);
    archive.addFile(ArchiveFile('图片清单.txt', b.length, b));
  }

  String? _tryParseFilePath(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return null;
    if (raw.startsWith('file://')) {
      try {
        final uri = Uri.parse(raw);
        if (uri.scheme != 'file') return null;
        return uri.toFilePath(windows: Platform.isWindows);
      } catch (_) {
        return null;
      }
    }
    return raw;
  }

  String _buildImageLocalManifest({required List<String> included, required List<String> skipped}) {
    final b = StringBuffer();
    b.writeln('图片打包结果：');
    b.writeln();
    b.writeln('已打包（${included.length}）：');
    for (final s in included) {
      b.writeln(s);
    }
    b.writeln();
    b.writeln('已跳过（${skipped.length}）：');
    b.writeln('仅支持本地路径（或 file:// URI），网络链接会跳过；不存在/不可读也会跳过。');
    for (final s in skipped) {
      b.writeln(s);
    }
    return b.toString();
  }
}

class DataExportException implements Exception {
  const DataExportException(this.message);
  final String message;
  @override
  String toString() => message;
}
