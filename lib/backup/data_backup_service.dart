import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'backup_config.dart';
import 'webdav_client.dart';

typedef BackupSnapshotExecutor =
    Future<void> Function({
      required String sourceDbPath,
      required String outputDbPath,
    });

class DataBackupService {
  DataBackupService({
    Future<Directory> Function()? documentsDirectoryProvider,
    BackupSnapshotExecutor? snapshotExecutor,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _snapshotExecutor = snapshotExecutor ?? _defaultSnapshotExecutor;

  final Future<Directory> Function() _documentsDirectoryProvider;
  final BackupSnapshotExecutor _snapshotExecutor;

  Future<BackupRunResult> run({
    required BackupConfig config,
    required void Function(BackupProgress progress) onProgress,
    BackupHistoryType historyType = BackupHistoryType.manual,
  }) async {
    if (!config.webDavEnabled) {
      throw const BackupException('请先启用 WebDAV 备份');
    }
    final baseUrlRaw = config.webDavBaseUrl.trim();
    if (baseUrlRaw.isEmpty) {
      throw const BackupException('请先填写服务器地址');
    }
    final baseUrl = BackupConfig.parseAndNormalizeWebDavBaseUrl(baseUrlRaw);
    if (baseUrl == null) {
      throw const BackupException('服务器地址格式不正确');
    }
    if (config.webDavUsername.trim().isEmpty) {
      throw const BackupException('请先填写用户名');
    }
    if (config.webDavPassword.isEmpty) {
      throw const BackupException('请先填写密码');
    }
    final remoteDirRaw = config.webDavRemoteDir.trim();
    if (remoteDirRaw.isNotEmpty &&
        !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)) {
      throw const BackupException('远程目录格式不正确');
    }
    final remoteDir = BackupConfig.normalizeWebDavRemoteDir(remoteDirRaw);

    onProgress(
      const BackupProgress(stage: BackupStage.packaging, message: '正在打包…'),
    );
    final localFile = await _createBackupZip(onProgress: onProgress);

    final client = WebDavClient(
      baseUrl: baseUrl,
      username: config.webDavUsername.trim(),
      password: config.webDavPassword,
    );
    try {
      onProgress(
        const BackupProgress(stage: BackupStage.uploading, message: '正在连接网盘…'),
      );
      final test = await client.test();
      if (!test.ok) {
        throw BackupException(test.message);
      }

      await client.ensureRemoteDir(remoteDir);

      final remotePath = _buildRemotePath(
        remoteDir: remoteDir,
        fileName: p.basename(localFile.path),
      );
      final remoteUrl = client.resolvePath(remotePath).toString();

      onProgress(
        const BackupProgress(stage: BackupStage.uploading, message: '正在上传…'),
      );
      await client.putFile(
        remotePath: remotePath,
        file: localFile,
        contentType: 'application/zip',
        onProgress: (sent, total) {
          onProgress(
            BackupProgress(
              stage: BackupStage.uploading,
              message: '正在上传…',
              sentBytes: sent,
              totalBytes: total,
            ),
          );
        },
      );

      final now = DateTime.now();
      await BackupStateStore.setLastBackup(
        at: now,
        fileName: p.basename(localFile.path),
        sizeBytes: await localFile.length(),
        remoteUrl: remoteUrl,
      );
      await BackupStateStore.addHistory(
        BackupHistoryEntry(
          type: historyType,
          at: now,
          fileName: p.basename(localFile.path),
          sizeBytes: await localFile.length(),
          remoteUrl: remoteUrl,
        ),
      );

      onProgress(
        const BackupProgress(stage: BackupStage.done, message: '备份完成'),
      );
      return BackupRunResult(localFile: localFile, remoteUrl: remoteUrl);
    } finally {
      await client.close();
    }
  }

  Future<File> buildLocalBackupZip({
    required void Function(BackupProgress progress) onProgress,
    bool includeMedia = true,
  }) {
    return _createBackupZip(onProgress: onProgress, includeMedia: includeMedia);
  }

  Future<LocalBackupDirectoryInfo> inspectLocalBackupDirectory({
    String? preferredOutputDir,
  }) async {
    final outputDir = await _resolveLocalBackupOutputDirectory(
      preferredOutputDir: preferredOutputDir,
    );
    final writable = await _isDirectoryWritable(outputDir);
    return LocalBackupDirectoryInfo(
      directory: outputDir,
      writable: writable,
      usingDefault: (preferredOutputDir?.trim().isEmpty ?? true),
    );
  }

  Future<File> exportLocalBackupZip({
    required void Function(BackupProgress progress) onProgress,
    String? preferredOutputDir,
    bool includeMedia = true,
  }) async {
    final outputDir = await _resolveLocalBackupOutputDirectory(
      preferredOutputDir: preferredOutputDir,
    );
    final writable = await _isDirectoryWritable(outputDir);
    if (!writable) {
      throw BackupException('备份目录不可写：${outputDir.path}');
    }
    return _createBackupZip(
      onProgress: onProgress,
      includeMedia: includeMedia,
      outputDirectory: outputDir,
    );
  }

  Future<File> _createBackupZip({
    required void Function(BackupProgress progress) onProgress,
    bool includeMedia = true,
    Directory? outputDirectory,
  }) async {
    final dir = await _documentsDirectoryProvider();
    final backupDir = outputDirectory ?? Directory(p.join(dir.path, 'backups'));
    await backupDir.create(recursive: true);

    final ts = DateTime.now();
    final baseName = _buildFileNameBase(ts);
    final outFile = File(p.join(backupDir.path, '$baseName.zip'));

    final archive = Archive();
    final sourceDb = File(p.join(dir.path, 'newshangli_drift.sqlite'));
    if (!await sourceDb.exists()) {
      throw BackupException('未找到数据库文件：${sourceDb.path}');
    }
    final snapshot = await _createSnapshotDbFile(
      sourceDbPath: sourceDb.path,
      ts: ts,
    );
    final included = <String>[snapshot.archivePath];
    try {
      final bytes = await snapshot.file.readAsBytes();
      archive.addFile(ArchiveFile(snapshot.archivePath, bytes.length, bytes));
    } finally {
      if (await snapshot.file.exists()) {
        await snapshot.file.delete();
      }
    }

    _MediaArchiveSummary mediaSummary = const _MediaArchiveSummary(
      fileCount: 0,
      totalBytes: 0,
    );
    if (includeMedia) {
      mediaSummary = await _addMediaToArchive(
        archive: archive,
        docsDir: dir,
        included: included,
      );
    }

    final manifest = <String, Object?>{
      'createdAt': ts.toIso8601String(),
      'backupMode': 'snapshot_vacuum_into',
      'dbFile': snapshot.archivePath,
      'dbSizeBytes': snapshot.sizeBytes,
      'mediaIncluded': mediaSummary.fileCount > 0,
      'mediaFilesCount': mediaSummary.fileCount,
      'mediaBytes': mediaSummary.totalBytes,
      'schemaVersion': null,
      'files': included,
    };
    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    onProgress(
      const BackupProgress(stage: BackupStage.packaging, message: '正在生成 ZIP…'),
    );
    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) {
      throw const BackupException('ZIP 打包失败');
    }
    await outFile.writeAsBytes(zipped, flush: true);
    return outFile;
  }

  Future<_BackupSnapshotResult> _createSnapshotDbFile({
    required String sourceDbPath,
    required DateTime ts,
  }) async {
    final dir = await _documentsDirectoryProvider();
    final snapshotDir = Directory(p.join(dir.path, 'backups', 'snapshots'));
    await snapshotDir.create(recursive: true);
    final fileName =
        'newshangli_snapshot_${ts.millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}.sqlite';
    final snapshotFile = File(p.join(snapshotDir.path, fileName));
    if (await snapshotFile.exists()) {
      await snapshotFile.delete();
    }

    try {
      await _snapshotExecutor(
        sourceDbPath: sourceDbPath,
        outputDbPath: snapshotFile.path,
      );
    } catch (e) {
      if (await snapshotFile.exists()) {
        await snapshotFile.delete();
      }
      throw BackupException('生成数据库快照失败：$e');
    }

    final exists = await snapshotFile.exists();
    final size = exists ? await snapshotFile.length() : 0;
    if (!exists || size <= 0) {
      if (exists) {
        await snapshotFile.delete();
      }
      throw const BackupException('生成数据库快照失败：快照文件为空');
    }
    return _BackupSnapshotResult(
      file: snapshotFile,
      archivePath: 'db/newshangli_drift.snapshot.sqlite',
      sizeBytes: size,
    );
  }

  Future<_MediaArchiveSummary> _addMediaToArchive({
    required Archive archive,
    required Directory docsDir,
    required List<String> included,
  }) async {
    final mediaDir = Directory(p.join(docsDir.path, 'media'));
    if (!await mediaDir.exists()) {
      return const _MediaArchiveSummary(fileCount: 0, totalBytes: 0);
    }
    var fileCount = 0;
    var totalBytes = 0;
    await for (final entity in mediaDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: docsDir.path);
      final archivePath = p.posix.normalize(relative.replaceAll('\\', '/'));
      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
      included.add(archivePath);
      fileCount += 1;
      totalBytes += bytes.length;
    }
    return _MediaArchiveSummary(fileCount: fileCount, totalBytes: totalBytes);
  }

  String _buildFileNameBase(DateTime ts) {
    String two(int n) => n.toString().padLeft(2, '0');
    final t =
        '${ts.year}${two(ts.month)}${two(ts.day)}_${two(ts.hour)}${two(ts.minute)}${two(ts.second)}';
    return '尚礼_备份_$t';
  }

  String _buildRemotePath({
    required String remoteDir,
    required String fileName,
  }) {
    final dir = remoteDir.trim();
    if (dir.isEmpty) return fileName;
    var normalized = dir;
    normalized = normalized.startsWith('/')
        ? normalized.substring(1)
        : normalized;
    normalized = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    return p.posix.join(normalized, fileName);
  }

  Future<Directory> _resolveLocalBackupOutputDirectory({
    String? preferredOutputDir,
  }) async {
    final normalized = preferredOutputDir?.trim() ?? '';
    try {
      if (normalized.isNotEmpty) {
        final preferredDir = Directory(normalized);
        await preferredDir.create(recursive: true);
        return preferredDir;
      }
      final docs = await _documentsDirectoryProvider();
      final backupDir = Directory(p.join(docs.path, 'backups'));
      await backupDir.create(recursive: true);
      return backupDir;
    } catch (e) {
      throw BackupException('无法创建备份目录：$e');
    }
  }

  Future<bool> _isDirectoryWritable(Directory dir) async {
    try {
      await dir.create(recursive: true);
      final probe = File(
        p.join(
          dir.path,
          '.newshangli_write_probe_${DateTime.now().microsecondsSinceEpoch}.tmp',
        ),
      );
      await probe.writeAsString('ok', flush: true);
      if (await probe.exists()) {
        await probe.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _defaultSnapshotExecutor({
    required String sourceDbPath,
    required String outputDbPath,
  }) async {
    final sourceFile = File(sourceDbPath);
    if (!await sourceFile.exists()) {
      throw BackupException('未找到数据库文件：$sourceDbPath');
    }
    final db = sqlite.sqlite3.open(sourceDbPath);
    try {
      db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
      final escapedPath = outputDbPath.replaceAll("'", "''");
      db.execute("VACUUM INTO '$escapedPath';");
    } finally {
      db.dispose();
    }
  }
}

class BackupRunResult {
  const BackupRunResult({required this.localFile, required this.remoteUrl});

  final File localFile;
  final String remoteUrl;
}

class LocalBackupDirectoryInfo {
  const LocalBackupDirectoryInfo({
    required this.directory,
    required this.writable,
    required this.usingDefault,
  });

  final Directory directory;
  final bool writable;
  final bool usingDefault;
}

enum BackupStage { packaging, uploading, done }

class BackupProgress {
  const BackupProgress({
    required this.stage,
    required this.message,
    this.sentBytes,
    this.totalBytes,
  });

  final BackupStage stage;
  final String message;
  final int? sentBytes;
  final int? totalBytes;
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _BackupSnapshotResult {
  const _BackupSnapshotResult({
    required this.file,
    required this.archivePath,
    required this.sizeBytes,
  });

  final File file;
  final String archivePath;
  final int sizeBytes;
}

class _MediaArchiveSummary {
  const _MediaArchiveSummary({
    required this.fileCount,
    required this.totalBytes,
  });

  final int fileCount;
  final int totalBytes;
}
