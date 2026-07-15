import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/local/drift/app_database.dart';
import '../media/media_storage_service.dart';

enum DataImportFormat { csv, xlsx }

enum DataImportStatus { pending, running, paused, completed, failed, canceled }

enum DataImportKind { recordsAndPersons, recordsOnly, personsOnly }

const String _kMediaZipPathField = '__media_zip_path__';

class DataImportException implements Exception {
  const DataImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DataImportProgress {
  const DataImportProgress({
    required this.jobId,
    required this.status,
    required this.processedRows,
    required this.successRows,
    required this.skippedRows,
    required this.failedRows,
  });

  final String jobId;
  final DataImportStatus status;
  final int processedRows;
  final int successRows;
  final int skippedRows;
  final int failedRows;
}

class DataImportRunHandle {
  DataImportRunHandle._({
    required this.jobId,
    required this.progress,
    required this.pause,
    required this.cancel,
  });

  final String jobId;
  final Stream<DataImportProgress> progress;
  final Future<void> Function() pause;
  final Future<void> Function() cancel;
}

class DataImportService {
  DataImportService({
    required AppDatabase db,
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _db = db,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final AppDatabase _db;
  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<String> createJob({
    required String bookId,
    required String sourceFilePath,
    required DataImportKind kind,
    Map<String, String?>? fieldMapping,
    String? mediaZipPath,
  }) async {
    final f = File(sourceFilePath);
    if (!await f.exists()) {
      throw const DataImportException('文件不存在');
    }

    final ext = p.extension(sourceFilePath).toLowerCase();
    final format = switch (ext) {
      '.csv' => DataImportFormat.csv,
      '.xlsx' => DataImportFormat.xlsx,
      _ => throw DataImportException('不支持的文件类型：$ext'),
    };

    final stat = await f.stat();
    final fileName = p.basename(sourceFilePath);
    final fileHash = await _sha256OfFile(f);

    final dest = await _copyToImportDir(
      source: f,
      fileName: fileName,
      fileHash: fileHash,
    );
    final logFile = await _prepareLogFile(jobId: fileHash);
    final now = DateTime.now().millisecondsSinceEpoch;
    final normalizedMapping = <String, String>{
      for (final entry in (fieldMapping ?? const <String, String?>{}).entries)
        if ((entry.value ?? '').trim().isNotEmpty)
          entry.key.trim(): entry.value!.trim(),
    };
    if ((mediaZipPath ?? '').trim().isNotEmpty) {
      final zip = File(mediaZipPath!.trim());
      if (!await zip.exists()) {
        throw const DataImportException('媒体ZIP文件不存在');
      }
      final zipHash = await _sha256OfFile(zip);
      final zipDest = await _copyToImportDir(
        source: zip,
        fileName: p.basename(zip.path),
        fileHash: zipHash,
      );
      normalizedMapping[_kMediaZipPathField] = zipDest.path;
    }
    final mappingJson = normalizedMapping.isEmpty
        ? null
        : jsonEncode(normalizedMapping);

    final jobId = await _db.dataImportJobsDao.insertOne(
      DataImportJobsCompanion.insert(
        bookId: bookId,
        filePath: dest.path,
        fileName: fileName,
        fileHash: fileHash,
        fileSize: stat.size,
        format: format.name,
        status: DataImportStatus.pending.name,
        importKind: kind.name,
        mappingJson: mappingJson == null
            ? const Value.absent()
            : Value(mappingJson),
        errorLogPath: Value(logFile.path),
        startedAt: now,
        updatedAt: now,
      ),
    );

    return jobId;
  }

  Future<DataImportRunHandle> start(String jobId) async {
    final job = await _db.dataImportJobsDao.findById(jobId);
    if (job == null) {
      throw const DataImportException('导入任务不存在');
    }
    if (job.status == DataImportStatus.completed.name) {
      throw const DataImportException('该任务已完成，无法重复导入');
    }
    if (job.status == DataImportStatus.canceled.name) {
      throw const DataImportException('该任务已取消，无法继续导入');
    }

    final controller = StreamController<DataImportProgress>.broadcast();
    var paused = false;
    var canceled = false;

    Future<void> setStatus(DataImportStatus status, {int? finishedAt}) async {
      await (_db.update(
        _db.dataImportJobs,
      )..where((t) => t.jobId.equals(jobId))).write(
        DataImportJobsCompanion(
          status: Value(status.name),
          finishedAt: finishedAt == null
              ? const Value.absent()
              : Value(finishedAt),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      controller.add(
        DataImportProgress(
          jobId: jobId,
          status: status,
          processedRows: job.processedRows,
          successRows: job.successRows,
          skippedRows: job.skippedRows,
          failedRows: job.failedRows,
        ),
      );
    }

    unawaited(() async {
      try {
        await setStatus(DataImportStatus.running);
        final updatedJob = await _db.dataImportJobsDao.findById(jobId);
        if (updatedJob == null) throw const DataImportException('导入任务不存在');

        final kind = DataImportKind.values.firstWhere(
          (e) => e.name == updatedJob.importKind,
          orElse: () => DataImportKind.recordsAndPersons,
        );
        final format = DataImportFormat.values.firstWhere(
          (e) => e.name == updatedJob.format,
          orElse: () => DataImportFormat.csv,
        );

        final runner = _ImportRunner(
          db: _db,
          job: updatedJob,
          kind: kind,
          format: format,
          shouldPause: () => paused,
          shouldCancel: () => canceled,
          onProgress: (p) => controller.add(p),
          onLog: (line) => _appendLog(updatedJob.errorLogPath, line),
        );
        final endStatus = await runner.run();

        final now = DateTime.now().millisecondsSinceEpoch;
        if (endStatus == DataImportStatus.paused) {
          await (_db.update(
            _db.dataImportJobs,
          )..where((t) => t.jobId.equals(jobId))).write(
            DataImportJobsCompanion(
              status: Value(DataImportStatus.paused.name),
              updatedAt: Value(now),
            ),
          );
        } else {
          await (_db.update(
            _db.dataImportJobs,
          )..where((t) => t.jobId.equals(jobId))).write(
            DataImportJobsCompanion(
              status: Value(endStatus.name),
              finishedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
        final finalJob = await _db.dataImportJobsDao.findById(jobId);
        controller.add(
          DataImportProgress(
            jobId: jobId,
            status: endStatus,
            processedRows: finalJob?.processedRows ?? 0,
            successRows: finalJob?.successRows ?? 0,
            skippedRows: finalJob?.skippedRows ?? 0,
            failedRows: finalJob?.failedRows ?? 0,
          ),
        );
      } catch (e) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await (_db.update(
          _db.dataImportJobs,
        )..where((t) => t.jobId.equals(jobId))).write(
          DataImportJobsCompanion(
            status: Value(DataImportStatus.failed.name),
            finishedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        final finalJob = await _db.dataImportJobsDao.findById(jobId);
        controller.add(
          DataImportProgress(
            jobId: jobId,
            status: DataImportStatus.failed,
            processedRows: finalJob?.processedRows ?? job.processedRows,
            successRows: finalJob?.successRows ?? job.successRows,
            skippedRows: finalJob?.skippedRows ?? job.skippedRows,
            failedRows: finalJob?.failedRows ?? (job.failedRows + 1),
          ),
        );
        await controller.close();
        return;
      }
      await controller.close();
    }());

    return DataImportRunHandle._(
      jobId: jobId,
      progress: controller.stream,
      pause: () async {
        paused = true;
        await setStatus(DataImportStatus.paused);
      },
      cancel: () async {
        canceled = true;
        await setStatus(DataImportStatus.canceled);
      },
    );
  }

  Future<String> _sha256OfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<File> _copyToImportDir({
    required File source,
    required String fileName,
    required String fileHash,
  }) async {
    final dir = await _documentsDirectoryProvider();
    final importDir = Directory(p.join(dir.path, 'imports', 'files'));
    await importDir.create(recursive: true);
    final ext = p.extension(fileName);
    final dest = File(p.join(importDir.path, '$fileHash$ext'));
    if (await dest.exists()) return dest;
    return source.copy(dest.path);
  }

  Future<File> _prepareLogFile({required String jobId}) async {
    final dir = await _documentsDirectoryProvider();
    final logDir = Directory(p.join(dir.path, 'imports', 'logs'));
    await logDir.create(recursive: true);
    final file = File(p.join(logDir.path, '$jobId.log.txt'));
    if (!await file.exists()) {
      await file.writeAsString('', flush: true);
    }
    return file;
  }

  Future<void> _appendLog(String? logPath, String line) async {
    if (logPath == null) return;
    try {
      final f = File(logPath);
      await f.writeAsString('$line\n', mode: FileMode.append, flush: false);
    } catch (_) {}
  }
}

class _ImportRunner {
  _ImportRunner({
    required AppDatabase db,
    required DataImportJob job,
    required DataImportKind kind,
    required DataImportFormat format,
    required bool Function() shouldPause,
    required bool Function() shouldCancel,
    required void Function(DataImportProgress) onProgress,
    required Future<void> Function(String) onLog,
  }) : _db = db,
       _job = job,
       _kind = kind,
       _format = format,
       _shouldPause = shouldPause,
       _shouldCancel = shouldCancel,
       _onProgress = onProgress,
       _onLog = onLog,
       _processedRows = job.processedRows,
       _successRows = job.successRows,
       _skippedRows = job.skippedRows,
       _failedRows = job.failedRows,
       _lastRowIndex = job.lastRowIndex,
       _fieldMapping = _parseMapping(job.mappingJson) {
    _mediaStorageService = MediaStorageService(
      documentsDirectoryProvider: () async {
        final parent = File(job.filePath).parent;
        final dir = Directory(p.join(parent.path, 'runtime_docs'));
        await dir.create(recursive: true);
        return dir;
      },
    );
  }

  final AppDatabase _db;
  final DataImportJob _job;
  final DataImportKind _kind;
  final DataImportFormat _format;
  final bool Function() _shouldPause;
  final bool Function() _shouldCancel;
  final void Function(DataImportProgress) _onProgress;
  final Future<void> Function(String) _onLog;

  int _processedRows;
  int _successRows;
  int _skippedRows;
  int _failedRows;
  int _lastRowIndex;
  final Map<String, String> _fieldMapping;
  late final MediaStorageService _mediaStorageService;
  Map<String, List<_IndexedMediaEntry>>? _mediaEntriesByBaseName;
  Map<String, _IndexedMediaEntry>? _mediaEntriesByArchivePath;
  final Map<String, String> _materializedMediaPathCache = <String, String>{};

  final Map<String, String> _personIdByKey = <String, String>{};
  final Set<String> _existingPersonIds = <String>{};
  final Set<String> _existingRecordIds = <String>{};
  final Set<String> _seenPersonKeys = <String>{};
  final Set<String> _seenRecordKeys = <String>{};
  final Map<String, String> _bookIdByName = <String, String>{};

  static const _kType = '数据类型';
  static const _kPersonId = '关系人ID';
  static const _kPersonName = '关系人姓名';
  static const _kRelationship = '关系人关系';
  static const _kPhone = '手机号';
  static const _kDirection = '收支方向';
  static const _kAmountYuan = '金额(元)';
  static const _kEvent = '事由';
  static const _kPayment = '支付方式';
  static const _kOccurred = '发生时间';
  static const _kNote = '备注';
  static const _kRecordId = '记录ID';
  static const _kAvatarFile = '头像文件名';
  static const _kBookName = '所属账簿名称';

  Future<DataImportStatus> run() async {
    await _loadExistingPersons();
    await _ensureMediaIndexLoaded();
    switch (_format) {
      case DataImportFormat.csv:
        return _runCsv();
      case DataImportFormat.xlsx:
        return _runXlsx();
    }
  }

  Future<void> _loadExistingPersons() async {
    final list = await (_db.select(
      _db.persons,
    )..where((t) => t.bookId.equals(_job.bookId))).get();
    for (final p in list) {
      final key = _personKey(name: p.name, phone: p.phone);
      _personIdByKey[key] = p.personId;
      _existingPersonIds.add(p.personId);
    }
    final records =
        await (_db.select(_db.giftRecords)
              ..where((t) => t.bookId.equals(_job.bookId))
              ..where((t) => t.deletedAt.isNull()))
            .get();
    for (final r in records) {
      _existingRecordIds.add(r.recordId);
    }
    final books = await (_db.select(
      _db.accountBooks,
    )..where((t) => t.deletedAt.isNull())).get();
    for (final b in books) {
      _bookIdByName[b.name] = b.bookId;
    }
  }

  Future<DataImportStatus> _runCsv() async {
    final file = File(_job.filePath);
    if (!await file.exists()) {
      throw const DataImportException('导入文件不存在');
    }

    final lines = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    var lineNo = 0;
    var dataIndex = 0;
    List<String>? headers;
    final chunkPersons = <PersonsCompanion>[];
    final chunkRecords = <GiftRecordsCompanion>[];

    await for (final raw in lines) {
      lineNo++;
      if (headers == null) {
        if (raw.trim().isEmpty) continue;
        headers = _parseCsvLine(raw).map((e) => e.trim()).toList();
        _validateHeaders(headers);
        continue;
      }

      if (_shouldCancel()) {
        await _flush(
          rowIndex: dataIndex,
          persons: chunkPersons,
          records: chunkRecords,
        );
        return DataImportStatus.canceled;
      }
      if (_shouldPause()) {
        await _flush(
          rowIndex: dataIndex,
          persons: chunkPersons,
          records: chunkRecords,
        );
        return DataImportStatus.paused;
      }

      if (raw.trim().isEmpty) continue;
      dataIndex++;
      if (dataIndex <= _lastRowIndex) continue;

      final cells = _parseCsvLine(raw);
      final row = _rowMap(headers, cells);
      await _consumeRow(
        rowIndex: lineNo,
        row: row,
        persons: chunkPersons,
        records: chunkRecords,
      );
      if (chunkPersons.length + chunkRecords.length >= 2000) {
        await _flush(
          rowIndex: dataIndex,
          persons: chunkPersons,
          records: chunkRecords,
        );
      }
    }
    if (headers == null) {
      throw const DataImportException('CSV 为空，未找到表头');
    }
    await _flush(
      rowIndex: dataIndex,
      persons: chunkPersons,
      records: chunkRecords,
    );
    return DataImportStatus.completed;
  }

  Future<DataImportStatus> _runXlsx() async {
    final file = File(_job.filePath);
    if (!await file.exists()) {
      throw const DataImportException('导入文件不存在');
    }

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (excel.sheets.isEmpty) throw const DataImportException('Excel 内容为空');
    final personSheet = excel.sheets['关系人'];
    final recordSheet = excel.sheets['礼金记录'] ?? excel.sheets['收支记录'];
    if (personSheet != null || recordSheet != null) {
      return _runXlsxTwoSheets(
        personSheet: personSheet,
        recordSheet: recordSheet,
      );
    }
    final sheet = excel.sheets.values.first;
    final all = sheet.rows;
    if (all.isEmpty) throw const DataImportException('Excel 表格为空');

    final headers = all.first
        .map((c) => (c?.value?.toString() ?? '').trim())
        .toList();
    _validateHeaders(headers);

    final chunkPersons = <PersonsCompanion>[];
    final chunkRecords = <GiftRecordsCompanion>[];

    for (var i = 1; i < all.length; i++) {
      final dataIndex = i;
      if (_shouldCancel()) {
        await _flush(
          rowIndex: dataIndex - 1,
          persons: chunkPersons,
          records: chunkRecords,
        );
        return DataImportStatus.canceled;
      }
      if (_shouldPause()) {
        await _flush(
          rowIndex: dataIndex - 1,
          persons: chunkPersons,
          records: chunkRecords,
        );
        return DataImportStatus.paused;
      }

      if (dataIndex <= _lastRowIndex) continue;
      final rowIndex = i + 1;
      final rowCells = all[i].map((c) => (c?.value?.toString() ?? '')).toList();
      final row = _rowMap(headers, rowCells);
      await _consumeRow(
        rowIndex: rowIndex,
        row: row,
        persons: chunkPersons,
        records: chunkRecords,
      );
      if (chunkPersons.length + chunkRecords.length >= 2000) {
        await _flush(
          rowIndex: dataIndex,
          persons: chunkPersons,
          records: chunkRecords,
        );
      }
    }
    await _flush(
      rowIndex: all.length - 1,
      persons: chunkPersons,
      records: chunkRecords,
    );
    return DataImportStatus.completed;
  }

  Future<DataImportStatus> _runXlsxTwoSheets({
    required Sheet? personSheet,
    required Sheet? recordSheet,
  }) async {
    final chunkPersons = <PersonsCompanion>[];
    final chunkRecords = <GiftRecordsCompanion>[];
    var rowIndex = _lastRowIndex;

    if (_shouldCancel()) return DataImportStatus.canceled;
    if (_shouldPause()) return DataImportStatus.paused;
    await _ensureMediaIndexLoaded();

    if (personSheet != null && _kind != DataImportKind.recordsOnly) {
      final rows = personSheet.rows;
      if (rows.isNotEmpty) {
        final headers = rows.first
            .map((c) => (c?.value?.toString() ?? '').trim())
            .toList();
        for (var i = 1; i < rows.length; i++) {
          if (_shouldCancel()) {
            await _flush(
              rowIndex: rowIndex,
              persons: chunkPersons,
              records: chunkRecords,
            );
            return DataImportStatus.canceled;
          }
          if (_shouldPause()) {
            await _flush(
              rowIndex: rowIndex,
              persons: chunkPersons,
              records: chunkRecords,
            );
            return DataImportStatus.paused;
          }
          final cells = rows[i]
              .map((c) => (c?.value?.toString() ?? '').trim())
              .toList();
          final row = _rowMap(headers, cells);
          _processedRows += 1;
          final person = await _parsePersonRowV2(rowIndex: i + 1, row: row);
          if (person != null) {
            chunkPersons.add(person);
          }
          rowIndex++;
          if (chunkPersons.length + chunkRecords.length >= 2000) {
            await _flush(
              rowIndex: rowIndex,
              persons: chunkPersons,
              records: chunkRecords,
            );
          }
        }
      }
    }

    if (recordSheet != null && _kind != DataImportKind.personsOnly) {
      final rows = recordSheet.rows;
      if (rows.isNotEmpty) {
        final headers = rows.first
            .map((c) => (c?.value?.toString() ?? '').trim())
            .toList();
        for (var i = 1; i < rows.length; i++) {
          if (_shouldCancel()) {
            await _flush(
              rowIndex: rowIndex,
              persons: chunkPersons,
              records: chunkRecords,
            );
            return DataImportStatus.canceled;
          }
          if (_shouldPause()) {
            await _flush(
              rowIndex: rowIndex,
              persons: chunkPersons,
              records: chunkRecords,
            );
            return DataImportStatus.paused;
          }
          final cells = rows[i]
              .map((c) => (c?.value?.toString() ?? '').trim())
              .toList();
          final row = _rowMap(headers, cells);
          _processedRows += 1;
          final record = await _parseRecordRow(
            rowIndex: i + 1,
            row: row,
            persons: chunkPersons,
          );
          if (record != null) {
            chunkRecords.add(record);
          }
          rowIndex++;
          if (chunkPersons.length + chunkRecords.length >= 2000) {
            await _flush(
              rowIndex: rowIndex,
              persons: chunkPersons,
              records: chunkRecords,
            );
          }
        }
      }
    }
    await _flush(
      rowIndex: rowIndex,
      persons: chunkPersons,
      records: chunkRecords,
    );
    return DataImportStatus.completed;
  }

  void _validateHeaders(List<String> headers) {
    if (!_hasHeader(headers, _kType)) {
      throw const DataImportException('缺少列：数据类型');
    }
    if (!_hasHeader(headers, _kPersonName) &&
        !_hasHeader(headers, _kPersonId)) {
      throw const DataImportException('缺少列：关系人姓名/关系人ID（至少一个）');
    }
  }

  bool _hasHeader(List<String> headers, String standardField) {
    if (_fieldMapping.containsKey(standardField)) {
      return headers.contains(_fieldMapping[standardField]);
    }
    return headers.contains(standardField);
  }

  Future<void> _consumeRow({
    required int rowIndex,
    required Map<String, String> row,
    required List<PersonsCompanion> persons,
    required List<GiftRecordsCompanion> records,
  }) async {
    final type = _read(row, _kType).trim();
    if (type.isEmpty) return;
    if (type == '关系人列表') {
      if (_kind == DataImportKind.recordsOnly) return;
      _processedRows += 1;
      final person = _parsePersonRow(rowIndex: rowIndex, row: row);
      if (person == null) return;
      persons.add(person);
      return;
    }
    if (type == '礼金收支记录') {
      if (_kind == DataImportKind.personsOnly) return;
      _processedRows += 1;
      final record = await _parseRecordRow(
        rowIndex: rowIndex,
        row: row,
        persons: persons,
      );
      if (record == null) return;
      records.add(record);
      return;
    }
  }

  PersonsCompanion? _parsePersonRow({
    required int rowIndex,
    required Map<String, String> row,
  }) {
    final name = _read(row, _kPersonName).trim();
    if (name.isEmpty) {
      _failedRows += 1;
      _onLog('第$rowIndex行：关系人姓名为空，已跳过');
      return null;
    }
    final phone = _read(row, _kPhone).trim();
    final relationship = _read(row, _kRelationship).trim();
    final key = _personKey(name: name, phone: phone.isEmpty ? null : phone);
    if (_seenPersonKeys.contains(key)) {
      _skippedRows += 1;
      return null;
    }
    _seenPersonKeys.add(key);

    if (_personIdByKey.containsKey(key)) {
      _skippedRows += 1;
      return null;
    }

    final personId = _read(row, _kPersonId).trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = personId.isEmpty ? _db.newId() : personId;
    _personIdByKey[key] = id;
    if (_existingPersonIds.contains(id)) {
      _skippedRows += 1;
      return null;
    }
    _existingPersonIds.add(id);

    return PersonsCompanion.insert(
      personId: Value(id),
      bookId: _job.bookId,
      name: name,
      relationshipType: Value(relationship.isEmpty ? '其他' : relationship),
      phone: phone.isEmpty ? const Value.absent() : Value(phone),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<PersonsCompanion?> _parsePersonRowV2({
    required int rowIndex,
    required Map<String, String> row,
  }) async {
    final normalized = Map<String, String>.from(row);
    if ((normalized[_kPersonName] ?? '').trim().isEmpty &&
        (normalized['姓名'] ?? '').trim().isNotEmpty) {
      normalized[_kPersonName] = normalized['姓名']!.trim();
    }
    if ((normalized[_kRelationship] ?? '').trim().isEmpty &&
        (normalized['关系'] ?? '').trim().isNotEmpty) {
      normalized[_kRelationship] = normalized['关系']!.trim();
    }
    final base = _parsePersonRow(rowIndex: rowIndex, row: normalized);
    if (base == null) return null;
    final avatarName = (normalized[_kAvatarFile] ?? normalized['头像'] ?? '')
        .trim();
    if (avatarName.isEmpty) {
      return base;
    }
    final mediaPath = await _resolveMediaPathByName(
      avatarName,
      preferredFolders: const <String>['media/avatars', 'avatars'],
    );
    if (mediaPath == null) {
      _skippedRows += 1;
      await _onLog('第$rowIndex行：头像文件未在ZIP中找到（$avatarName）');
      return base;
    }
    try {
      final avatarUri = await _mediaStorageService.saveAvatarFromPath(
        mediaPath,
      );
      return base.copyWith(avatarUri: Value(avatarUri));
    } catch (e) {
      _failedRows += 1;
      await _onLog('第$rowIndex行：头像落盘失败（$avatarName）：$e');
      return base;
    }
  }

  Future<GiftRecordsCompanion?> _parseRecordRow({
    required int rowIndex,
    required Map<String, String> row,
    required List<PersonsCompanion> persons,
  }) async {
    final direction = _read(row, _kDirection).trim();
    if (direction != '收入' && direction != '支出') {
      _failedRows += 1;
      unawaited(_onLog('第$rowIndex行：收支方向不合法（$direction），已跳过'));
      return null;
    }

    final amountCent = _parseAmountCent(row);
    if (amountCent == null || amountCent <= 0) {
      _failedRows += 1;
      unawaited(_onLog('第$rowIndex行：金额不合法，已跳过'));
      return null;
    }

    final occurredAt = _parseOccurredAt(_read(row, _kOccurred));
    if (occurredAt == null) {
      _failedRows += 1;
      unawaited(_onLog('第$rowIndex行：发生时间不合法，已跳过'));
      return null;
    }

    final bookNameRaw = _read(row, _kBookName).trim();
    String effectiveBookId = _job.bookId;
    if (bookNameRaw.isNotEmpty) {
      final matchedId = _bookIdByName[bookNameRaw];
      if (matchedId != null) {
        effectiveBookId = matchedId;
      } else {
        effectiveBookId = _db.newId();
        final now = DateTime.now().millisecondsSinceEpoch;
        await _db
            .into(_db.accountBooks)
            .insert(
              AccountBooksCompanion.insert(
                bookId: Value(effectiveBookId),
                name: bookNameRaw,
                bookTime: Value(occurredAt.millisecondsSinceEpoch),
                createdAt: now,
                updatedAt: now,
              ),
            );
        _bookIdByName[bookNameRaw] = effectiveBookId;
      }
    }

    final personIdRaw = _read(row, _kPersonId).trim();
    final personName = _read(row, _kPersonName).trim();
    if (personIdRaw.isEmpty && personName.isEmpty) {
      _failedRows += 1;
      unawaited(_onLog('第$rowIndex行：关系人姓名/ID 为空，已跳过'));
      return null;
    }

    final phone = _read(row, _kPhone).trim();
    final relationship = _read(row, _kRelationship).trim();
    final key = _personKey(
      name: personName,
      phone: phone.isEmpty ? null : phone,
    );
    var personId = personIdRaw.isEmpty
        ? (_personIdByKey[key] ?? '')
        : personIdRaw;
    if (personId.isEmpty) {
      personId = _db.newId();
    }
    _personIdByKey[key] = personId;

    if (!_existingPersonIds.contains(personId)) {
      if (personName.isEmpty) {
        _failedRows += 1;
        unawaited(_onLog('第$rowIndex行：关系人姓名为空，无法创建关系人，已跳过'));
        return null;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      persons.add(
        PersonsCompanion.insert(
          personId: Value(personId),
          bookId: effectiveBookId,
          name: personName,
          relationshipType: Value(relationship.isEmpty ? '其他' : relationship),
          phone: phone.isEmpty ? const Value.absent() : Value(phone),
          createdAt: now,
          updatedAt: now,
        ),
      );
      _existingPersonIds.add(personId);
    }

    final recordId = _read(row, _kRecordId).trim();
    final id = recordId.isEmpty ? _db.newId() : recordId;
    if (_existingRecordIds.contains(id)) {
      _skippedRows += 1;
      return null;
    }
    final eventName = _read(row, _kEvent).trim();
    final book = await _db.accountBooksDao.findById(effectiveBookId);
    final effectiveOccurredAt = (book != null && book.isDefault != 1)
        ? book.bookTime
        : occurredAt.millisecondsSinceEpoch;
    final recordKey = recordId.isNotEmpty
        ? 'id:$id'
        : 'k:$personId|$effectiveOccurredAt|$amountCent|$direction|$eventName';
    if (_seenRecordKeys.contains(recordKey)) {
      _skippedRows += 1;
      return null;
    }
    _seenRecordKeys.add(recordKey);
    _existingRecordIds.add(id);

    final paymentMethod = _read(row, _kPayment).trim();
    final note = _read(row, _kNote).trim();
    final attachments = await _resolveAttachmentsFromRow(row);
    final now = DateTime.now().millisecondsSinceEpoch;
    return GiftRecordsCompanion.insert(
      recordId: Value(id),
      bookId: effectiveBookId,
      personId: personId,
      direction: Value(direction),
      amountCent: amountCent,
      currency: const Value('CNY'),
      eventName: eventName.isEmpty ? const Value.absent() : Value(eventName),
      occurredAt: effectiveOccurredAt,
      paymentMethod: paymentMethod.isEmpty
          ? const Value.absent()
          : Value(paymentMethod),
      note: note.isEmpty ? const Value.absent() : Value(note),
      attachments: attachments.isEmpty
          ? const Value.absent()
          : Value(attachments),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<String>> _resolveAttachmentsFromRow(
    Map<String, String> row,
  ) async {
    final out = <String>[];
    for (var i = 1; i <= 20; i++) {
      final fileName = _read(row, '附件$i名称').trim();
      if (fileName.isEmpty) continue;
      final path = await _resolveMediaPathByName(
        fileName,
        preferredFolders: const <String>['media/attachments', 'attachments'],
      );
      if (path == null) continue;
      try {
        final stored = await _mediaStorageService.saveAttachmentFromPath(path);
        out.add(stored);
      } catch (_) {}
    }
    return out;
  }

  int? _parseAmountCent(Map<String, String> row) {
    final yuan = _read(row, _kAmountYuan).trim();
    if (yuan.isEmpty) return null;
    final n = double.tryParse(yuan.replaceAll(',', ''));
    if (n == null) return null;
    return (n * 100).round();
  }

  DateTime? _parseOccurredAt(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s.replaceAll('/', '-'));
    if (dt != null) return dt;
    final m = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})',
    ).firstMatch(s);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
    );
  }

  Map<String, String> _rowMap(List<String> headers, List<String> cells) {
    final map = <String, String>{};
    for (var i = 0; i < headers.length; i++) {
      final key = headers[i];
      if (key.trim().isEmpty) continue;
      map[key] = i < cells.length ? cells[i] : '';
    }
    return map;
  }

  String _personKey({required String name, required String? phone}) {
    final n = name.trim();
    final p = (phone ?? '').trim();
    return '$n|$p';
  }

  Future<void> _flush({
    required int rowIndex,
    required List<PersonsCompanion> persons,
    required List<GiftRecordsCompanion> records,
  }) async {
    if (persons.isEmpty && records.isEmpty) {
      await _persistCheckpoint(rowIndex);
      return;
    }

    final before = await _countInsertedRowsSnapshot();
    await _db.transaction(() async {
      await _db.batch((b) {
        if (persons.isNotEmpty) {
          b.insertAll(_db.persons, persons, mode: InsertMode.insertOrIgnore);
        }
        if (records.isNotEmpty) {
          b.insertAll(
            _db.giftRecords,
            records,
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
    });
    await Future<void>.delayed(Duration.zero);
    final after = await _countInsertedRowsSnapshot();

    final insertedDelta = (after.$1 + after.$2) - (before.$1 + before.$2);
    _successRows += insertedDelta;
    await (_db.update(
      _db.dataImportJobs,
    )..where((t) => t.jobId.equals(_job.jobId))).write(
      DataImportJobsCompanion(
        processedRows: Value(_processedRows),
        successRows: Value(_successRows),
        skippedRows: Value(_skippedRows),
        failedRows: Value(_failedRows),
        lastRowIndex: Value(rowIndex),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    _lastRowIndex = rowIndex;

    persons.clear();
    records.clear();

    _onProgress(
      DataImportProgress(
        jobId: _job.jobId,
        status: DataImportStatus.running,
        processedRows: _processedRows,
        successRows: _successRows,
        skippedRows: _skippedRows,
        failedRows: _failedRows,
      ),
    );
  }

  Future<(int, int)> _countInsertedRowsSnapshot() async {
    final personRows = await _db
        .customSelect(
          'SELECT COUNT(1) AS c FROM person WHERE book_id = ? AND deleted_at IS NULL;',
          variables: <Variable<Object>>[Variable<String>(_job.bookId)],
        )
        .getSingle();
    final recordRows = await _db
        .customSelect(
          'SELECT COUNT(1) AS c FROM gift_record WHERE book_id = ? AND deleted_at IS NULL;',
          variables: <Variable<Object>>[Variable<String>(_job.bookId)],
        )
        .getSingle();
    final persons = (personRows.data['c'] as int?) ?? 0;
    final records = (recordRows.data['c'] as int?) ?? 0;
    return (persons, records);
  }

  String _read(Map<String, String> row, String standardField) {
    if (_fieldMapping.containsKey(standardField)) {
      final source = _fieldMapping[standardField]!;
      return row[source] ?? '';
    }
    return row[standardField] ?? '';
  }

  Future<void> _ensureMediaIndexLoaded() async {
    if (_mediaEntriesByBaseName != null && _mediaEntriesByArchivePath != null) {
      return;
    }
    final zipPath = _fieldMapping[_kMediaZipPathField];
    if (zipPath == null || zipPath.trim().isEmpty) {
      _mediaEntriesByBaseName = <String, List<_IndexedMediaEntry>>{};
      _mediaEntriesByArchivePath = <String, _IndexedMediaEntry>{};
      return;
    }
    final file = File(zipPath);
    if (!await file.exists()) {
      _mediaEntriesByBaseName = <String, List<_IndexedMediaEntry>>{};
      _mediaEntriesByArchivePath = <String, _IndexedMediaEntry>{};
      return;
    }
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final byBaseName = <String, List<_IndexedMediaEntry>>{};
    final byArchivePath = <String, _IndexedMediaEntry>{};
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final archivePath = _normalizeZipEntryName(entry.name);
      if (archivePath == null) {
        await _onLog('媒体ZIP包含非法路径，已跳过：${entry.name}');
        continue;
      }
      if (byArchivePath.containsKey(archivePath)) {
        await _onLog('媒体ZIP包含重复路径，已忽略后续条目：$archivePath');
        continue;
      }
      final indexed = _IndexedMediaEntry(archivePath: archivePath, file: entry);
      byArchivePath[archivePath] = indexed;
      final baseName = p.posix.basename(archivePath);
      byBaseName
          .putIfAbsent(baseName, () => <_IndexedMediaEntry>[])
          .add(indexed);
    }
    _mediaEntriesByBaseName = byBaseName;
    _mediaEntriesByArchivePath = byArchivePath;
  }

  Future<String?> _resolveMediaPathByName(
    String fileName, {
    List<String> preferredFolders = const <String>[],
  }) async {
    final name = fileName.trim();
    if (name.isEmpty) return null;

    final exactArchivePath = _normalizeZipEntryName(name);
    if (exactArchivePath != null) {
      final exact = _mediaEntriesByArchivePath?[exactArchivePath];
      if (exact != null) {
        return _materializeMediaEntry(exact);
      }
    }

    final baseName = p.posix.basename(name.replaceAll(r'\', '/'));
    final candidates = _mediaEntriesByBaseName?[baseName];
    if (candidates == null || candidates.isEmpty) return null;

    for (final folder in preferredFolders) {
      final normalizedFolder = _normalizeZipEntryName(folder);
      if (normalizedFolder == null) continue;
      for (final entry in candidates) {
        if (_isArchivePathInsideFolder(entry.archivePath, normalizedFolder)) {
          return _materializeMediaEntry(entry);
        }
      }
    }

    return _materializeMediaEntry(candidates.first);
  }

  String? _normalizeZipEntryName(String rawName) {
    final trimmed = rawName.trim().replaceAll(r'\', '/');
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(trimmed)) {
      return null;
    }

    final normalizedParts = <String>[];
    for (final part in trimmed.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') return null;
      normalizedParts.add(part);
    }
    if (normalizedParts.isEmpty) return null;
    return normalizedParts.join('/');
  }

  bool _isArchivePathInsideFolder(String archivePath, String folderPath) {
    final normalizedArchivePath = p.posix.normalize(archivePath);
    final normalizedFolderPath = p.posix.normalize(folderPath);
    return normalizedArchivePath == normalizedFolderPath ||
        normalizedArchivePath.startsWith('$normalizedFolderPath/');
  }

  Future<String> _materializeMediaEntry(_IndexedMediaEntry entry) async {
    final cached = _materializedMediaPathCache[entry.archivePath];
    if (cached != null && await File(cached).exists()) {
      return cached;
    }

    // 使用 ZIP 内的安全相对路径回放到任务隔离目录，避免条目名越界写入。
    final materializeRoot = Directory(
      p.join(File(_job.filePath).parent.path, 'unzipped', _job.jobId, 'media'),
    );
    await materializeRoot.create(recursive: true);
    final outputSegments = <String>[
      materializeRoot.path,
      ...entry.archivePath.split('/'),
    ];
    final outFile = File(p.joinAll(outputSegments));
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(entry.file.content as List<int>, flush: true);
    _materializedMediaPathCache[entry.archivePath] = outFile.path;
    return outFile.path;
  }

  static Map<String, String> _parseMapping(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String>{};
      final map = <String, String>{};
      decoded.forEach((key, value) {
        final k = key.toString().trim();
        final v = value?.toString().trim() ?? '';
        if (k.isNotEmpty && v.isNotEmpty) {
          map[k] = v;
        }
      });
      return map;
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _persistCheckpoint(int rowIndex) async {
    await (_db.update(
      _db.dataImportJobs,
    )..where((t) => t.jobId.equals(_job.jobId))).write(
      DataImportJobsCompanion(
        processedRows: Value(_processedRows),
        successRows: Value(_successRows),
        skippedRows: Value(_skippedRows),
        failedRows: Value(_failedRows),
        lastRowIndex: Value(rowIndex),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    _lastRowIndex = rowIndex;
  }

  List<String> _parseCsvLine(String line) {
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

class _IndexedMediaEntry {
  const _IndexedMediaEntry({required this.archivePath, required this.file});

  final String archivePath;
  final ArchiveFile file;
}
