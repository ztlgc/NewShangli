import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/local/drift/app_database.dart';
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
  Future<File> exportFromDrift({
    required bool loggedIn,
    required AppDatabase db,
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

    final allPersons = await (db.select(
      db.persons,
    )..where((t) => t.deletedAt.isNull())).get();
    final personById = <String, Person>{
      for (final person in allPersons) person.personId: person,
    };

    final allBooks = await (db.select(
      db.accountBooks,
    )..where((t) => t.deletedAt.isNull())).get();
    final bookById = <String, AccountBook>{
      for (final b in allBooks) b.bookId: b,
    };

    final recordQuery = db.select(db.giftRecords)
      ..where((t) => t.deletedAt.isNull());
    if (request.bookId != null) {
      final selected = bookById[request.bookId];
      recordQuery.where(
        (t) => selected?.isDefault == 1
            ? t.bookId.equals(request.bookId!) | t.direction.equals('支出')
            : t.bookId.equals(request.bookId!),
      );
    }
    final allRecords = await recordQuery.get();
    final records = allRecords
        .where(
          (r) =>
              r.occurredAt >= start.millisecondsSinceEpoch &&
              r.occurredAt < endExclusive.millisecondsSinceEpoch,
        )
        .toList();

    final relatedIds = records.map((record) => record.personId).toSet();
    final scopedPersons = request.bookId == null
        ? allPersons
        : allPersons
              .where((person) => relatedIds.contains(person.personId))
              .toList();
    final recordRows = <List<String>>[];
    final personRows = <List<String>>[];
    final links = <String, String>{};
    final maxAttachmentCount = records.fold<int>(1, (prev, r) {
      final len = (r.attachments ?? const <String>[]).length;
      return len > prev ? len : prev;
    });
    final mediaBundle = await _prepareDriftMediaBundle(
      records: request.includeImages && request.includeRecords
          ? records
          : const [],
      persons: request.includeImages && request.includePersons
          ? scopedPersons
          : const [],
    );

    var recordCount = 0;
    if (request.includeRecords) {
      final recordHeaders = <String>[
        '记录ID',
        '收支方向',
        '金额(元)',
        '事由',
        '所属账簿名称',
        '关系人ID',
        '关系人姓名',
        '支付方式',
        '发生时间',
        '备注',
        '所属账簿ID',
        '账簿时间',
        '账簿事由',
        '默认账簿',
      ];
      for (var i = 1; i <= maxAttachmentCount; i++) {
        recordHeaders.add('附件$i名称');
      }
      recordRows.add(recordHeaders);
      for (final r in records) {
        recordCount++;
        final person = personById[r.personId];
        final row = <String>[
          r.recordId,
          r.direction == '支出' ? '支出' : '收入',
          (r.amountCent / 100.0).toStringAsFixed(2),
          r.eventName ?? '',
          bookById[r.bookId]?.name ?? '默认账簿',
          r.personId,
          person?.name ?? '',
          r.paymentMethod ?? '',
          _formatDateTime(DateTime.fromMillisecondsSinceEpoch(r.occurredAt)),
          r.note ?? '',
          r.bookId,
          DateTime.fromMillisecondsSinceEpoch(
            bookById[r.bookId]!.bookTime,
          ).toUtc().toIso8601String(),
          bookById[r.bookId]!.reasonType,
          bookById[r.bookId]!.isDefault.toString(),
        ];
        final refs =
            mediaBundle.recordAttachmentRefs[r.recordId] ?? const <_MediaRef>[];
        for (var i = 0; i < maxAttachmentCount; i++) {
          if (i < refs.length) {
            final ref = refs[i];
            row.add(
              _displayCellText(
                fileName: ref.displayName,
                archivePath: request.format == DataExportFormat.zip
                    ? ref.archivePath
                    : null,
                links: links,
              ),
            );
          } else {
            row.add('');
          }
        }
        recordRows.add(row);
      }
    }

    var personCount = 0;
    if (request.includePersons) {
      personRows.add(<String>[
        '关系人ID',
        '姓名',
        '关系',
        '手机号',
        '创建时间',
        '备注',
        '头像文件名',
        '生日',
        '纪念日',
      ]);
      for (final person in scopedPersons) {
        personCount++;
        final avatarRef = mediaBundle.personAvatarRefs[person.personId];
        personRows.add(<String>[
          person.personId,
          person.name,
          person.relationshipType,
          person.phone ?? '',
          _formatDateTime(
            DateTime.fromMillisecondsSinceEpoch(person.createdAt),
          ),
          person.note ?? '',
          _displayCellText(
            fileName: request.includeImages
                ? (avatarRef?.displayName ?? _extractFileName(person.avatarUri))
                : '',
            archivePath: request.format == DataExportFormat.zip
                ? avatarRef?.archivePath
                : null,
            links: links,
          ),
          person.birthday ?? '',
          person.anniversary ?? '',
        ]);
      }
    }

    if (request.includeRecords && !request.includePersons && recordCount == 0) {
      throw const DataExportException('所选时间范围内没有收支记录');
    }
    if (!request.includeRecords && request.includePersons && personCount == 0) {
      throw const DataExportException('当前没有可导出的关系人');
    }

    final dir =
        outputDir ?? Directory((await getApplicationDocumentsDirectory()).path);
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);

    final baseName = _buildFileNameBase();
    switch (request.format) {
      case DataExportFormat.excel:
        final bytes = _encodeXlsx(
          recordRows: recordRows,
          personRows: personRows,
          includeRecords: request.includeRecords,
          includePersons: request.includePersons,
          links: const <String, String>{},
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
          links: links,
        );
        final archive = Archive()
          ..addFile(ArchiveFile('$baseName.xlsx', xlsxBytes.length, xlsxBytes));
        await _addMediaBundleToArchive(archive: archive, bundle: mediaBundle);
        final zipped = ZipEncoder().encode(archive);
        if (zipped == null) {
          throw const DataExportException('ZIP 打包失败');
        }
        final file = File(p.join(exportDir.path, '$baseName.zip'));
        await file.writeAsBytes(zipped, flush: true);
        return file;
    }
  }

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
      recordRows.add(<String>[
        '记录ID',
        '收支方向',
        '金额(元)',
        '事由',
        '所属账簿名称',
        '关系人ID',
        '关系人姓名',
        '支付方式',
        '发生时间',
        '备注',
      ]);
      for (final r in data.records) {
        if (r.occurredAt.isBefore(start) ||
            !r.occurredAt.isBefore(endExclusive)) {
          continue;
        }
        if (request.bookId != null) {
          final effectiveBookId = data.resolveBookId(r.bookId);
          final targetBookId = data.resolveBookId(request.bookId);
          if (effectiveBookId != targetBookId) continue;
        }
        recordCount++;
        final bookName = data.resolveBookName(r.bookId);
        recordRows.add(<String>[
          r.id,
          r.direction == RecordDirection.income ? '收入' : '支出',
          (r.amountCent / 100.0).toStringAsFixed(2),
          r.eventName,
          bookName,
          r.personId,
          r.personName,
          r.paymentMethod,
          _formatDateTime(r.occurredAt),
          r.note ?? '',
        ]);
      }
    }

    var personCount = 0;
    if (request.includePersons) {
      personRows.add(<String>[
        '关系人ID',
        '姓名',
        '关系',
        '手机号',
        '创建时间',
        '备注',
        if (request.includeImages) '图片/头像',
      ]);
      for (final person in data.persons) {
        personCount++;
        personRows.add(<String>[
          person.id,
          person.name,
          person.relationship,
          person.phone ?? '',
          _formatDateTime(person.createdAt),
          person.note ?? '',
          if (request.includeImages) person.avatarUrl ?? '',
        ]);
      }
    }

    if (request.includeRecords && !request.includePersons && recordCount == 0) {
      throw const DataExportException('所选时间范围内没有收支记录');
    }
    if (!request.includeRecords && request.includePersons && personCount == 0) {
      throw const DataExportException('当前没有可导出的关系人');
    }

    final dir =
        outputDir ?? Directory((await getApplicationDocumentsDirectory()).path);
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);

    final baseName = _buildFileNameBase();
    switch (request.format) {
      case DataExportFormat.excel:
        final bytes = _encodeXlsx(
          recordRows: recordRows,
          personRows: personRows,
          includeRecords: request.includeRecords,
          includePersons: request.includePersons,
          links: const <String, String>{},
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
          links: const <String, String>{},
        );
        final archive = Archive()
          ..addFile(ArchiveFile('$baseName.xlsx', xlsxBytes.length, xlsxBytes));
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

  String _formatDateTime(DateTime d) => d.toUtc().toIso8601String();

  String _buildFileNameBase() {
    String two(int n) => n.toString().padLeft(2, '0');
    final ts = DateTime.now();
    final t =
        '${ts.year}${two(ts.month)}${two(ts.day)}_${two(ts.hour)}${two(ts.minute)}${two(ts.second)}';
    return '尚礼_导出_${t}_${ts.microsecondsSinceEpoch}';
  }

  List<int> _encodeXlsx({
    required List<List<String>> recordRows,
    required List<List<String>> personRows,
    required bool includeRecords,
    required bool includePersons,
    required Map<String, String> links,
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
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
          );
          final text = row[c];
          // 业务文本始终作为文本输出，包括以 = 和链接标记开头的内容。
          cell.value = TextCellValue(text);
          cell.cellStyle = r == 0 ? headerStyle : bodyStyle;
        }
      }
    }

    excel.rename('Sheet1', '礼金记录');
    writeSheet(
      excel['礼金记录'],
      includeRecords
          ? recordRows
          : const <List<String>>[
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
                '联系人头像',
                '附件1名称',
              ],
            ],
    );
    writeSheet(
      excel['关系人'],
      includePersons
          ? personRows
          : const <List<String>>[
              <String>['关系人ID', '姓名', '关系', '手机号', '创建时间', '备注', '头像文件名'],
            ],
    );

    final bytes = excel.encode();
    if (bytes == null) {
      throw const DataExportException('Excel 生成失败');
    }
    return bytes;
  }

  String _displayCellText({
    required String fileName,
    required String? archivePath,
    required Map<String, String> links,
  }) {
    final name = fileName.trim();
    if (name.isEmpty) return '';
    if (archivePath == null || archivePath.trim().isEmpty) return name;
    return archivePath.replaceAll('\\', '/');
  }

  String _extractFileName(String? raw) {
    final source = (raw ?? '').trim();
    if (source.isEmpty) return '';
    final path = _tryParseFilePath(source) ?? source;
    return p.basename(path);
  }

  Future<_DriftMediaBundle> _prepareDriftMediaBundle({
    required List<GiftRecord> records,
    required List<Person> persons,
  }) async {
    final personAvatarRefs = <String, _MediaRef>{};
    final recordAttachmentRefs = <String, List<_MediaRef>>{};
    final filesForArchive = <_MediaFileForArchive>[];
    final usedArchiveNames = <String>{};

    String allocateArchivePath({
      required String folder,
      required String preferredName,
      required String uniquePrefix,
    }) {
      final safeBase = preferredName.trim().isEmpty
          ? 'file.bin'
          : preferredName.trim();
      final ext = p.extension(safeBase);
      final stem = p
          .basenameWithoutExtension(safeBase)
          .replaceAll(RegExp(r'\s+'), '_');
      var candidate = '${uniquePrefix}_$stem$ext';
      var index = 1;
      var path = p.posix.join(folder, candidate);
      while (usedArchiveNames.contains(path)) {
        candidate = '${uniquePrefix}_${stem}_$index$ext';
        path = p.posix.join(folder, candidate);
        index++;
      }
      usedArchiveNames.add(path);
      return path;
    }

    for (final person in persons) {
      final raw = (person.avatarUri ?? '').trim();
      if (raw.isEmpty) continue;
      final path = _tryParseFilePath(raw);
      if (path == null) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final displayName = p.basename(path);
      final archivePath = allocateArchivePath(
        folder: 'media/avatars',
        preferredName: displayName,
        uniquePrefix: 'person_${person.personId}',
      );
      personAvatarRefs[person.personId] = _MediaRef(
        displayName: p.basename(archivePath),
        archivePath: archivePath,
      );
      filesForArchive.add(
        _MediaFileForArchive(sourcePath: path, archivePath: archivePath),
      );
    }

    for (final record in records) {
      final rawAttachments = record.attachments ?? const <String>[];
      if (rawAttachments.isEmpty) continue;
      final refs = <_MediaRef>[];
      for (var i = 0; i < rawAttachments.length; i++) {
        final raw = rawAttachments[i].trim();
        if (raw.isEmpty) continue;
        final path = _tryParseFilePath(raw);
        if (path == null) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        final displayName = p.basename(path);
        final archivePath = allocateArchivePath(
          folder: 'media/attachments',
          preferredName: displayName,
          uniquePrefix: 'record_${record.recordId}_${i + 1}',
        );
        refs.add(
          _MediaRef(
            displayName: p.basename(archivePath),
            archivePath: archivePath,
          ),
        );
        filesForArchive.add(
          _MediaFileForArchive(sourcePath: path, archivePath: archivePath),
        );
      }
      if (refs.isNotEmpty) {
        recordAttachmentRefs[record.recordId] = refs;
      }
    }

    return _DriftMediaBundle(
      personAvatarRefs: personAvatarRefs,
      recordAttachmentRefs: recordAttachmentRefs,
      filesForArchive: filesForArchive,
    );
  }

  Future<void> _addMediaBundleToArchive({
    required Archive archive,
    required _DriftMediaBundle bundle,
  }) async {
    for (final item in bundle.filesForArchive) {
      final file = File(item.sourcePath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(item.archivePath, bytes.length, bytes));
    }
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
      final finalName = count == 0
          ? safe
          : '${p.basenameWithoutExtension(safe)}_${count + 1}${p.extension(safe)}';

      archive.addFile(
        ArchiveFile(p.posix.join('images', finalName), bytes.length, bytes),
      );
      included.add(raw);
    }

    if (request.includeRecords) {
      for (final r in data.records) {
        if (r.occurredAt.isBefore(start) ||
            !r.occurredAt.isBefore(endExclusive)) {
          continue;
        }
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

    final manifest = _buildImageLocalManifest(
      included: included,
      skipped: skipped,
    );
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

  String _buildImageLocalManifest({
    required List<String> included,
    required List<String> skipped,
  }) {
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

class _MediaRef {
  const _MediaRef({required this.displayName, required this.archivePath});

  final String displayName;
  final String archivePath;
}

class _MediaFileForArchive {
  const _MediaFileForArchive({
    required this.sourcePath,
    required this.archivePath,
  });

  final String sourcePath;
  final String archivePath;
}

class _DriftMediaBundle {
  const _DriftMediaBundle({
    required this.personAvatarRefs,
    required this.recordAttachmentRefs,
    required this.filesForArchive,
  });

  final Map<String, _MediaRef> personAvatarRefs;
  final Map<String, List<_MediaRef>> recordAttachmentRefs;
  final List<_MediaFileForArchive> filesForArchive;
}
