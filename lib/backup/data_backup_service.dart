import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/local/drift/app_database.dart';
import 'backup_config.dart';
import 'webdav_client.dart';

class DataBackupService {
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
    final baseUrl = Uri.tryParse(baseUrlRaw);
    if (baseUrl == null || (!baseUrl.hasScheme) || baseUrl.host.isEmpty) {
      throw const BackupException('服务器地址格式不正确');
    }
    if (config.webDavUsername.trim().isEmpty) {
      throw const BackupException('请先填写用户名');
    }
    if (config.webDavPassword.isEmpty) {
      throw const BackupException('请先填写密码');
    }
    final remoteDirRaw = config.webDavRemoteDir.trim();
    if (remoteDirRaw.isNotEmpty && !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)) {
      throw const BackupException('远程目录格式不正确');
    }
    final remoteDir = BackupConfig.normalizeWebDavRemoteDir(remoteDirRaw);

    onProgress(const BackupProgress(stage: BackupStage.packaging, message: '正在打包…'));
    final localFile = await _createBackupZip(onProgress: onProgress);

    final client = WebDavClient(
      baseUrl: baseUrl,
      username: config.webDavUsername.trim(),
      password: config.webDavPassword,
    );
    try {
      onProgress(const BackupProgress(stage: BackupStage.uploading, message: '正在连接网盘…'));
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

      onProgress(const BackupProgress(stage: BackupStage.uploading, message: '正在上传…'));
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

      onProgress(const BackupProgress(stage: BackupStage.done, message: '备份完成'));
      return BackupRunResult(localFile: localFile, remoteUrl: remoteUrl);
    } finally {
      await client.close();
    }
  }

  Future<File> _createBackupZip({required void Function(BackupProgress progress) onProgress}) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    await backupDir.create(recursive: true);

    final ts = DateTime.now();
    final baseName = _buildFileNameBase(ts);
    final outFile = File(p.join(backupDir.path, '$baseName.zip'));

    await _checkpointDrift();

    final files = <_BackupFileCandidate>[
      _BackupFileCandidate(
        local: File(p.join(dir.path, 'newshangli_drift.sqlite')),
        archivePath: 'db/newshangli_drift.sqlite',
        required: true,
      ),
      _BackupFileCandidate(
        local: File(p.join(dir.path, 'newshangli_drift.sqlite-wal')),
        archivePath: 'db/newshangli_drift.sqlite-wal',
        required: false,
      ),
      _BackupFileCandidate(
        local: File(p.join(dir.path, 'newshangli_drift.sqlite-shm')),
        archivePath: 'db/newshangli_drift.sqlite-shm',
        required: false,
      ),
      _BackupFileCandidate(
        local: File(p.join(dir.path, 'newshangli.db')),
        archivePath: 'db/newshangli.db',
        required: false,
      ),
    ];

    final archive = Archive();
    final included = <String>[];
    for (final f in files) {
      final exists = await f.local.exists();
      if (!exists) {
        if (f.required) {
          throw BackupException('未找到数据库文件：${f.local.path}');
        }
        continue;
      }
      final bytes = await f.local.readAsBytes();
      if (!f.required && bytes.isEmpty) continue;
      included.add(f.archivePath);
      archive.addFile(ArchiveFile(f.archivePath, bytes.length, bytes));
    }

    final manifest = <String, Object?>{
      'createdAt': ts.toIso8601String(),
      'files': included,
    };
    final manifestBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    onProgress(const BackupProgress(stage: BackupStage.packaging, message: '正在生成 ZIP…'));
    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) {
      throw const BackupException('ZIP 打包失败');
    }
    await outFile.writeAsBytes(zipped, flush: true);
    return outFile;
  }

  Future<void> _checkpointDrift() async {
    final db = AppDatabase();
    try {
      await db.customStatement('PRAGMA wal_checkpoint(FULL);');
    } finally {
      await db.close();
    }
  }

  String _buildFileNameBase(DateTime ts) {
    String two(int n) => n.toString().padLeft(2, '0');
    final t = '${ts.year}${two(ts.month)}${two(ts.day)}_${two(ts.hour)}${two(ts.minute)}${two(ts.second)}';
    return '尚礼_备份_$t';
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

class BackupRunResult {
  const BackupRunResult({required this.localFile, required this.remoteUrl});

  final File localFile;
  final String remoteUrl;
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

class _BackupFileCandidate {
  const _BackupFileCandidate({
    required this.local,
    required this.archivePath,
    required this.required,
  });

  final File local;
  final String archivePath;
  final bool required;
}
