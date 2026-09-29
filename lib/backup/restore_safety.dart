import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// 不依赖 UI/Drift 的恢复校验及启动回退协议。
class RestoreSafety {
  static const maxZipBytes = 128 * 1024 * 1024;
  static const maxExpandedBytes = 256 * 1024 * 1024;
  static Archive decodeZip(List<int> bytes) {
    if (bytes.length > maxZipBytes) throw const FormatException('压缩包超过 128 MB');
    // 先检查中央目录，禁止在体积校验前解压并计算 CRC。
    final directory = ZipDirectory.read(InputStream(bytes));
    var total = 0;
    if (directory.fileHeaders.length > 20000) {
      throw const FormatException('压缩包文件数量过多');
    }
    for (final header in directory.fileHeaders) {
      final size = header.uncompressedSize ?? -1;
      if (size < 0 || (total += size) > maxExpandedBytes) {
        throw const FormatException('压缩包解压后超过 256 MB');
      }
      if (((header.externalFileAttributes ?? 0) >> 16) & 0xF000 == 0xA000) {
        throw const FormatException('压缩包不能包含符号链接');
      }
    }
    final archive = ZipDecoder().decodeBytes(bytes);
    validateArchive(archive);
    for (final entry in archive.files.where((entry) => entry.isFile)) {
      final content = entry.content as List<int>;
      if (content.length != entry.size || getCrc32(content) != entry.crc32) {
        throw const FormatException('压缩包文件校验失败');
      }
    }
    return archive;
  }

  static void validateArchive(Archive archive) {
    var total = 0;
    final names = <String>{};
    if (archive.files.length > 20000) throw const FormatException('备份文件数量过多');
    for (final entry in archive.files) {
      final name = entry.name.replaceAll(r'\', '/');
      if (!entry.isFile && entry.isSymbolicLink) {
        throw const FormatException('备份不能包含符号链接');
      }
      if (name.startsWith('/') ||
          name.contains(':') ||
          name.split('/').contains('..') ||
          name.contains('\u0000')) {
        throw const FormatException('备份包含不安全的文件路径');
      }
      final normalized = p.posix.normalize(name).toLowerCase();
      if (!names.add(normalized)) throw const FormatException('备份包含重复文件路径');
      total += entry.size;
      if (entry.size < 0 || total > maxExpandedBytes) {
        throw const FormatException('备份解压后超过 256 MB');
      }
    }
  }

  static void validateDatabase(File file, int expectedVersion) {
    final db = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
    try {
      if (db
          .select('PRAGMA integrity_check')
          .any((r) => r.values.first != 'ok')) {
        throw const FormatException('备份数据库完整性检查失败');
      }
      if (db.select('PRAGMA user_version').single.values.first !=
          expectedVersion) {
        throw const FormatException('备份数据库版本不兼容，原数据未修改');
      }
      const columns = {
        'account_book': [
          'book_id',
          'name',
          'reason_type',
          'theme_color',
          'icon',
          'description',
          'attachments',
          'book_time',
          'is_default',
          'created_at',
          'updated_at',
          'deleted_at',
        ],
        'person': [
          'person_id',
          'book_id',
          'name',
          'relationship_type',
          'phone',
          'birthday',
          'anniversary',
          'avatar_uri',
          'note',
          'created_at',
          'updated_at',
          'deleted_at',
        ],
        'gift_record': [
          'record_id',
          'book_id',
          'person_id',
          'direction',
          'amount_cent',
          'currency',
          'event_name',
          'occurred_at',
          'payment_method',
          'note',
          'attachments',
          'created_at',
          'updated_at',
          'deleted_at',
        ],
        'reason': [
          'reason_id',
          'name',
          'normalized_name',
          'description',
          'enabled',
          'created_at',
          'updated_at',
        ],
        'relation_type': [
          'type_id',
          'name',
          'normalized_name',
          'created_at',
          'updated_at',
        ],
        'contact_relation': [
          'relation_id',
          'person_a_id',
          'person_b_id',
          'type_id',
          'note',
          'created_at',
          'updated_at',
        ],
        'entity_remark': [
          'remark_id',
          'entity_type',
          'entity_id',
          'content',
          'created_at',
        ],
        'data_import_job': [
          'job_id',
          'book_id',
          'file_path',
          'file_name',
          'file_hash',
          'file_size',
          'format',
          'status',
          'import_kind',
          'mapping_json',
          'total_rows',
          'processed_rows',
          'success_rows',
          'skipped_rows',
          'failed_rows',
          'byte_offset',
          'last_row_index',
          'error_log_path',
          'started_at',
          'finished_at',
          'updated_at',
        ],
      };
      for (final table in columns.entries) {
        final names = db
            .select('PRAGMA table_info(${table.key})')
            .map((r) => r['name'])
            .toSet();
        if (!names.containsAll(table.value)) {
          throw FormatException('备份缺少必要的表或字段：${table.key}');
        }
      }
      if (db.select('PRAGMA foreign_key_check').isNotEmpty ||
          db
              .select(
                "SELECT 1 FROM gift_record r LEFT JOIN person p ON r.person_id=p.person_id LEFT JOIN account_book b ON b.book_id=r.book_id WHERE p.person_id IS NULL OR b.book_id IS NULL OR typeof(r.amount_cent)!='integer' OR r.amount_cent<=0 OR r.amount_cent>99999999999999 OR r.direction NOT IN ('收入','支出') LIMIT 1",
              )
              .isNotEmpty) {
        throw const FormatException('备份包含非法金额、方向或孤立记录');
      }
    } finally {
      db.dispose();
    }
  }

  static void rebaseMedia(
    File file,
    Directory docs,
    Set<String> archiveNames, {
    required bool includeMedia,
  }) {
    final db = sqlite.sqlite3.open(file.path);
    String remap(String value) {
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
      final normalized = value.replaceAll(r'\', '/');
      final at = normalized.lastIndexOf('/media/');
      final relative = normalized.startsWith('media/')
          ? normalized
          : at >= 0
          ? normalized.substring(at + 1)
          : '';
      if (relative.isEmpty || relative.split('/').contains('..')) {
        throw const FormatException('备份媒体引用不合法');
      }
      if (includeMedia && !archiveNames.contains(relative)) {
        throw FormatException('备份缺少媒体文件：$relative');
      }
      return p.joinAll([docs.path, ...relative.split('/')]);
    }

    try {
      db.execute('BEGIN');
      for (final table in ['account_book', 'gift_record']) {
        final key = table == 'account_book' ? 'book_id' : 'record_id';
        for (final row in db.select(
          'SELECT $key,attachments FROM $table WHERE attachments IS NOT NULL',
        )) {
          final values = jsonDecode(row['attachments'] as String);
          if (values is! List) throw const FormatException('备份附件字段不合法');
          db.execute(
            'UPDATE $table SET attachments=? WHERE $key=?',
            [
              includeMedia
                  ? jsonEncode(values.map((v) => remap(v as String)).toList())
                  : null,
              row[key],
            ],
          );
        }
      }
      for (final row in db.select(
        'SELECT person_id,avatar_uri FROM person WHERE avatar_uri IS NOT NULL',
      )) {
        final value = row['avatar_uri'] as String;
        db.execute('UPDATE person SET avatar_uri=? WHERE person_id=?', [
          includeMedia ? (value.isEmpty ? null : remap(value)) : null,
          row['person_id'],
        ]);
      }
      // 导入任务中的绝对源文件路径不能跨设备恢复为可继续任务。
      db.execute(
        "UPDATE data_import_job SET status='canceled' WHERE status IN ('running','pending','paused','failed')",
      );
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    } finally {
      db.dispose();
    }
  }

  static File journal(Directory docs) =>
      File(p.join(docs.path, 'backups', 'restore_pending.json'));
  static Future<void> begin(Directory docs, Directory guard) async {
    final data = {
      'guard': p.relative(guard.path, from: docs.path),
      'hadDb': await File(
        p.join(docs.path, 'newshangli_drift.sqlite'),
      ).exists(),
      'hadMedia': await Directory(p.join(docs.path, 'media')).exists(),
    };
    await journal(docs).parent.create(recursive: true);
    final pending = journal(docs);
    if (await pending.exists()) throw const FormatException('已有未完成恢复，需要先回退');
    final temporary = File('${pending.path}.tmp');
    await temporary.writeAsString(jsonEncode(data), flush: true);
    await temporary.rename(pending.path);
  }

  static Future<void> recoverIfNeeded(Directory docs) async {
    final pending = journal(docs);
    if (!await pending.exists()) return;
    final data =
        jsonDecode(await pending.readAsString()) as Map<String, dynamic>;
    final relative = data['guard'] as String;
    final root = p.normalize(p.join(docs.path, 'backups', 'restore_guard'));
    final guard = p.normalize(p.join(docs.path, relative));
    if (!p.isWithin(root, guard)) throw const FormatException('恢复保护路径不合法');
    if (data['hadDb'] == true &&
        !await File(p.join(guard, 'newshangli_drift.sqlite')).exists()) {
      throw const FormatException('恢复保护数据库缺失');
    }
    for (final name in [
      'newshangli_drift.sqlite',
      'newshangli_drift.sqlite-wal',
      'newshangli_drift.sqlite-shm',
    ]) {
      final saved = File(p.join(guard, name));
      final target = File(p.join(docs.path, name));
      if (await saved.exists()) {
        await saved.copy(target.path);
      } else if (await target.exists()) {
        if (name == 'newshangli_drift.sqlite' && data['hadDb'] == true) {
          throw const FormatException('恢复保护数据库缺失');
        }
        await target.delete();
      }
    }
    final targetMedia = Directory(p.join(docs.path, 'media'));
    final savedMedia = Directory(p.join(guard, 'media'));
    if (data['hadMedia'] == true && !await savedMedia.exists()) {
      throw const FormatException('恢复保护媒体缺失');
    }
    if (await targetMedia.exists()) await targetMedia.delete(recursive: true);
    if (await savedMedia.exists()) await copyDirectory(savedMedia, targetMedia);
    await pending.delete();
  }

  static Future<void> copyDirectory(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entry in from.list(recursive: true, followLinks: false)) {
      if (entry is! File) continue;
      final dest = File(
        p.join(to.path, p.relative(entry.path, from: from.path)),
      );
      await dest.parent.create(recursive: true);
      await entry.copy(dest.path);
    }
  }
}
