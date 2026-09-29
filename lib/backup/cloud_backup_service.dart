import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'data_backup_service.dart';
import 'data_restore_service.dart';

class CloudBackupKind {
  static const String manual = 'manual';
  static const String auto = 'auto';
}

class CloudBackupVersion {
  const CloudBackupVersion({
    required this.backupId,
    required this.kind,
    required this.storageBucket,
    required this.storagePath,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory CloudBackupVersion.fromJson(Map<String, dynamic> json) {
    return CloudBackupVersion(
      backupId: (json['backup_id'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? '',
      storageBucket: (json['storage_bucket'] as String?) ?? 'backups',
      storagePath: (json['storage_path'] as String?) ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  final String backupId;
  final String kind;
  final String storageBucket;
  final String storagePath;
  final int sizeBytes;
  final int createdAt;
}

class CloudBackupService {
  CloudBackupService({
    SupabaseClient? supabase,
    DataBackupService? dataBackupService,
    DataRestoreService? dataRestoreService,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _dataBackupService = dataBackupService ?? DataBackupService(),
       _dataRestoreService = dataRestoreService ?? DataRestoreService();

  final SupabaseClient _supabase;
  final DataBackupService _dataBackupService;
  final DataRestoreService _dataRestoreService;

  String _newId() => const Uuid().v4();
  void _assertAccount(String id) {
    if (_supabase.auth.currentUser?.id != id) {
      throw const CloudBackupException('账号已切换，操作已停止');
    }
  }

  /// 确保 Storage Bucket 存在且已配置好 RLS 策略。
  ///
  /// 仅验证 bucket 是否可访问；不会尝试从客户端创建 bucket，
  /// 因为通过 anon key 调用 createBucket 通常没有权限，
  /// 即使成功也会创建一个没有 RLS 策略的 bucket（默认全部拒绝）。
  /// 请通过 Supabase 迁移来创建 bucket 并配置策略：
  ///   supabase/migrations/create_storage_backups_bucket.sql
  Future<void> _ensureStorageBucket(String bucketId) async {
    try {
      await _supabase.storage.from(bucketId).list();
    } on StorageException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.statusCode == '404' ||
          msg.contains('bucket not found') ||
          msg.contains('not found')) {
        throw CloudBackupException(
          'Storage bucket "$bucketId" 不存在。'
          '请在 Supabase 控制台运行迁移文件：'
          'supabase/migrations/create_storage_${bucketId}_bucket.sql'
          '（原始错误: ${e.message}）',
        );
      } else if (e.statusCode == '403' ||
          msg.contains('row-level security') ||
          msg.contains('unauthorized')) {
        throw CloudBackupException(
          'Storage bucket "$bucketId" 存在但 RLS 策略未正确配置，导致访问被拒绝。'
          '请运行迁移文件来创建/修复策略：'
          'supabase/migrations/create_storage_${bucketId}_bucket.sql'
          '（原始错误: ${e.message}）',
        );
      } else {
        rethrow;
      }
    }
  }

  static bool isAutoBackupDue({
    required int? lastCreatedAtMs,
    required Duration interval,
    int? nowMs,
  }) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (lastCreatedAtMs == null || lastCreatedAtMs <= 0) return true;
    final age = now - lastCreatedAtMs;
    if (age < 0) return true;
    return age >= interval.inMilliseconds;
  }

  static String buildAutoStoragePath(String userId) =>
      '$userId/auto/latest.zip';

  static String buildManualStoragePath({
    required String userId,
    required int createdAtMs,
    required String backupId,
  }) {
    return '$userId/manual/${createdAtMs}_$backupId.zip';
  }

  Future<List<CloudBackupVersion>> listVersions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const <CloudBackupVersion>[];
    final rows = await _supabase
        .from('cloud_backup_version')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return rows
        .map((e) => CloudBackupVersion.fromJson(e))
        .where((e) => e.backupId.trim().isNotEmpty)
        .toList();
  }

  Future<CloudBackupVersion> createManualBackup({
    required void Function(String message) onProgress,
    bool includeMedia = true,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const CloudBackupException('请先登录');
    final backupId = _newId();
    onProgress('正在打包…');
    final zip = await _dataBackupService.buildLocalBackupZip(
      onProgress: (p) => onProgress(p.message),
      includeMedia: includeMedia,
    );
    final sizeBytes = await zip.length();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final remotePath = buildManualStoragePath(
      userId: user.id,
      createdAtMs: createdAt,
      backupId: backupId,
    );
    await _ensureStorageBucket('backups');
    onProgress('正在上传…');
    await _supabase.storage
        .from('backups')
        .upload(remotePath, zip, fileOptions: const FileOptions(upsert: false));
    _assertAccount(user.id);
    await _supabase.from('cloud_backup_version').insert({
      'backup_id': backupId,
      'kind': CloudBackupKind.manual,
      'storage_bucket': 'backups',
      'storage_path': remotePath,
      'size_bytes': sizeBytes,
      'created_at': createdAt,
      'user_id': user.id,
    });
    _assertAccount(user.id);
    return CloudBackupVersion(
      backupId: backupId,
      kind: CloudBackupKind.manual,
      storageBucket: 'backups',
      storagePath: remotePath,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
    );
  }

  Future<CloudBackupVersion?> runAutoBackupIfNeeded({
    required void Function(String message) onProgress,
    Duration interval = const Duration(days: 3),
    bool includeMedia = true,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final autoRow = await _getAutoVersion(user.id);
    if (!isAutoBackupDue(
      lastCreatedAtMs: autoRow?.createdAt,
      interval: interval,
    )) {
      return null;
    }
    return _upsertAutoBackup(
      userId: user.id,
      existing: autoRow,
      includeMedia: includeMedia,
      onProgress: onProgress,
    );
  }

  Future<void> restoreVersion({
    required CloudBackupVersion version,
    required void Function(String message) onProgress,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const CloudBackupException('请先登录');
    if (version.storageBucket.trim().isEmpty ||
        version.storagePath.trim().isEmpty) {
      throw const CloudBackupException('备份版本信息不完整');
    }
    if (version.storageBucket != 'backups' ||
        !version.storagePath.startsWith('${user.id}/') ||
        version.storagePath.split('/').contains('..')) {
      throw const CloudBackupException('备份不属于当前账号');
    }
    onProgress('正在下载备份包…');
    final bytes = await _supabase.storage
        .from(version.storageBucket)
        .download(version.storagePath);
    final tmpDir = await getTemporaryDirectory();
    final tmpFile = File(
      p.join(tmpDir.path, 'cloud_restore_${_newId()}.zip'),
    );
    await tmpFile.writeAsBytes(bytes, flush: true);
    try {
      _assertAccount(user.id);
      await _dataRestoreService.restoreFromLocalZip(
        zipFile: tmpFile,
        onProgress: onProgress,
      );
    } finally {
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    }
  }

  Future<CloudBackupVersion?> _getAutoVersion(String userId) async {
    final rows = await _supabase
        .from('cloud_backup_version')
        .select()
        .eq('user_id', userId)
        .eq('kind', CloudBackupKind.auto)
        .limit(1);
    if (rows.isEmpty) return null;
    final v = CloudBackupVersion.fromJson(rows.first);
    if (v.backupId.trim().isEmpty) return null;
    return v;
  }

  Future<CloudBackupVersion> _upsertAutoBackup({
    required String userId,
    required CloudBackupVersion? existing,
    required bool includeMedia,
    required void Function(String message) onProgress,
  }) async {
    final backupId = existing?.backupId.trim().isNotEmpty == true
        ? existing!.backupId
        : _newId();
    onProgress('正在打包…');
    final zip = await _dataBackupService.buildLocalBackupZip(
      onProgress: (p) => onProgress(p.message),
      includeMedia: includeMedia,
    );
    final sizeBytes = await zip.length();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final remotePath =
        '$userId/auto/${createdAt}_${_newId()}.zip';
    await _ensureStorageBucket('backups');
    onProgress('正在上传…');
    await _supabase.storage
        .from('backups')
        .upload(remotePath, zip, fileOptions: const FileOptions(upsert: false));

    _assertAccount(userId);
    if (existing == null) {
      await _supabase.from('cloud_backup_version').insert({
        'backup_id': backupId,
        'kind': CloudBackupKind.auto,
        'storage_bucket': 'backups',
        'storage_path': remotePath,
        'size_bytes': sizeBytes,
        'created_at': createdAt,
        'user_id': userId,
      });
    } else {
      await _supabase
          .from('cloud_backup_version')
          .update({
            'storage_bucket': 'backups',
            'storage_path': remotePath,
            'size_bytes': sizeBytes,
            'created_at': createdAt,
          })
          .eq('backup_id', backupId)
          .eq('user_id', userId);
    }
    return CloudBackupVersion(
      backupId: backupId,
      kind: CloudBackupKind.auto,
      storageBucket: 'backups',
      storagePath: remotePath,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
    );
  }
}

class CloudBackupException implements Exception {
  const CloudBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
