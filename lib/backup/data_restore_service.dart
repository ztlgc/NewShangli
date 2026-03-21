import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'backup_config.dart';
import 'webdav_client.dart';

class DataRestoreService {
  DataRestoreService({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<void> restoreFromRemote({
    required BackupConfig config,
    required BackupHistoryEntry entry,
    required void Function(String message) onProgress,
  }) async {
    final baseUrl = BackupConfig.parseAndNormalizeWebDavBaseUrl(config.webDavBaseUrl);
    if (baseUrl == null) {
      throw const DataRestoreException('服务器地址格式不正确');
    }
    if (config.webDavUsername.trim().isEmpty || config.webDavPassword.isEmpty) {
      throw const DataRestoreException('请先配置 WebDAV 用户名与密码');
    }
    final docs = await _documentsDirectoryProvider();
    final tmpDir = Directory(p.join(docs.path, 'backups', 'restore_tmp', DateTime.now().millisecondsSinceEpoch.toString()));
    await tmpDir.create(recursive: true);
    final guardDir = Directory(p.join(docs.path, 'backups', 'restore_guard', DateTime.now().millisecondsSinceEpoch.toString()));
    await guardDir.create(recursive: true);
    final zipFile = File(p.join(tmpDir.path, entry.fileName.trim().isEmpty ? 'restore.zip' : entry.fileName.trim()));

    final remoteDir = BackupConfig.normalizeWebDavRemoteDir(config.webDavRemoteDir.trim());
    final remotePath = _buildRemotePath(remoteDir: remoteDir, fileName: entry.fileName);
    final client = WebDavClient(
      baseUrl: baseUrl,
      username: config.webDavUsername.trim(),
      password: config.webDavPassword,
    );
    try {
      onProgress('正在下载备份包…');
      await client.getFile(
        remotePath: remotePath,
        outputFile: zipFile,
        onProgress: (_, __) {},
      );
      onProgress('正在校验备份包…');
      await _restoreFromZip(zipFile: zipFile, docsDir: docs, guardDir: guardDir, onProgress: onProgress);
    } finally {
      await client.close();
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
    }
  }

  Future<void> _restoreFromZip({
    required File zipFile,
    required Directory docsDir,
    required Directory guardDir,
    required void Function(String message) onProgress,
  }) async {
    if (!await zipFile.exists()) {
      throw const DataRestoreException('备份包不存在');
    }
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    ArchiveFile? manifestEntry;
    for (final file in archive.files) {
      if (file.name == 'manifest.json') {
        manifestEntry = file;
        break;
      }
    }
    if (manifestEntry == null) {
      throw const DataRestoreException('备份包缺少 manifest.json');
    }
    final manifestRaw = utf8.decode((manifestEntry.content as List<int>));
    final manifest = jsonDecode(manifestRaw);
    if (manifest is! Map) {
      throw const DataRestoreException('manifest 内容无效');
    }
    final dbFileInArchive = (manifest['dbFile'] as String?) ?? 'db/newshangli_drift.snapshot.sqlite';
    ArchiveFile? dbEntry;
    for (final file in archive.files) {
      if (file.name == dbFileInArchive) {
        dbEntry = file;
        break;
      }
    }
    if (dbEntry == null) {
      throw DataRestoreException('备份包缺少数据库文件：$dbFileInArchive');
    }

    final dbPath = p.join(docsDir.path, 'newshangli_drift.sqlite');
    final walPath = '$dbPath-wal';
    final shmPath = '$dbPath-shm';
    final dbFile = File(dbPath);
    final walFile = File(walPath);
    final shmFile = File(shmPath);
    final guardDb = File(p.join(guardDir.path, 'newshangli_drift.sqlite'));
    final guardWal = File(p.join(guardDir.path, 'newshangli_drift.sqlite-wal'));
    final guardShm = File(p.join(guardDir.path, 'newshangli_drift.sqlite-shm'));
    final mediaDir = Directory(p.join(docsDir.path, 'media'));
    final guardMediaDir = Directory(p.join(guardDir.path, 'media'));

    if (await dbFile.exists()) {
      await dbFile.copy(guardDb.path);
    }
    if (await walFile.exists()) {
      await walFile.copy(guardWal.path);
    }
    if (await shmFile.exists()) {
      await shmFile.copy(guardShm.path);
    }
    if (await mediaDir.exists()) {
      await _copyDir(mediaDir, guardMediaDir);
    }

    try {
      onProgress('正在恢复数据库…');
      await dbFile.writeAsBytes(dbEntry.content as List<int>, flush: true);
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();

      onProgress('正在恢复媒体文件…');
      await _restoreMediaFromArchive(archive: archive, docsDir: docsDir);
    } catch (e) {
      await _rollbackFromGuard(
        guardDb: guardDb,
        guardWal: guardWal,
        guardShm: guardShm,
        dbFile: dbFile,
        walFile: walFile,
        shmFile: shmFile,
        guardMediaDir: guardMediaDir,
        mediaDir: mediaDir,
      );
      throw DataRestoreException('恢复失败，已回滚：$e');
    }
  }

  Future<void> _restoreMediaFromArchive({
    required Archive archive,
    required Directory docsDir,
  }) async {
    final mediaEntries = archive.files.where((e) => e.name.startsWith('media/'));
    final mediaRoot = Directory(p.join(docsDir.path, 'media'));
    if (await mediaRoot.exists()) {
      await mediaRoot.delete(recursive: true);
    }
    await mediaRoot.create(recursive: true);
    for (final entry in mediaEntries) {
      if (entry.isFile == false) continue;
      final output = File(p.join(docsDir.path, entry.name.replaceAll('/', p.separator)));
      await output.parent.create(recursive: true);
      await output.writeAsBytes(entry.content as List<int>, flush: true);
    }
  }

  Future<void> _rollbackFromGuard({
    required File guardDb,
    required File guardWal,
    required File guardShm,
    required File dbFile,
    required File walFile,
    required File shmFile,
    required Directory guardMediaDir,
    required Directory mediaDir,
  }) async {
    if (await guardDb.exists()) {
      await guardDb.copy(dbFile.path);
    }
    if (await guardWal.exists()) {
      await guardWal.copy(walFile.path);
    } else if (await walFile.exists()) {
      await walFile.delete();
    }
    if (await guardShm.exists()) {
      await guardShm.copy(shmFile.path);
    } else if (await shmFile.exists()) {
      await shmFile.delete();
    }
    if (await guardMediaDir.exists()) {
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
      }
      await _copyDir(guardMediaDir, mediaDir);
    }
  }

  Future<void> _copyDir(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: from.path);
      final out = File(p.join(to.path, relative));
      await out.parent.create(recursive: true);
      await entity.copy(out.path);
    }
  }

  String _buildRemotePath({required String remoteDir, required String fileName}) {
    final dir = remoteDir.trim();
    if (dir.isEmpty) return fileName;
    var normalized = dir;
    normalized = normalized.startsWith('/') ? normalized.substring(1) : normalized;
    normalized = normalized.endsWith('/') ? normalized.substring(0, normalized.length - 1) : normalized;
    return p.posix.join(normalized, fileName);
  }
}

class DataRestoreException implements Exception {
  const DataRestoreException(this.message);

  final String message;

  @override
  String toString() => message;
}
