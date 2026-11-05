import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// 不依赖 UI/Drift 的恢复校验及启动回退协议。
class RestoreSafety {
  static const maxZipBytes = 128 * 1024 * 1024;
  static const maxExpandedBytes = 256 * 1024 * 1024;
  static const maxArchiveFiles = 20000;

  // 生产和消费必须共享限制；展开体积包括数据库、媒体和 manifest。
  static void validateZipSize(int bytes) {
    if (bytes < 0 || bytes > maxZipBytes) {
      throw const FormatException('压缩包超过 128 MB');
    }
  }

  static void validatePayloadSize({required int files, required int bytes}) {
    if (files < 0 || files > maxArchiveFiles) {
      throw const FormatException('压缩包文件数量过多');
    }
    if (bytes < 0 || bytes > maxExpandedBytes) {
      throw const FormatException('压缩包解压后超过 256 MB');
    }
  }

  static Archive decodeZip(List<int> bytes) {
    validateZipSize(bytes.length);
    // 先检查中央目录，禁止在体积校验前解压并计算 CRC。
    final directory = ZipDirectory.read(InputStream(bytes));
    var total = 0;
    validatePayloadSize(files: directory.fileHeaders.length, bytes: 0);
    for (final header in directory.fileHeaders) {
      final size = header.uncompressedSize ?? -1;
      if (size < 0) throw const FormatException('压缩包文件大小无效');
      total += size;
      validatePayloadSize(files: directory.fileHeaders.length, bytes: total);
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
    validatePayloadSize(files: archive.files.length, bytes: 0);
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
      if (entry.size < 0) throw const FormatException('备份文件大小无效');
      total += entry.size;
      validatePayloadSize(files: archive.files.length, bytes: total);
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
      _validateCurrentStructure(db, columns);
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

  static void _validateCurrentStructure(
    sqlite.Database db,
    Map<String, List<String>> columns,
  ) {
    const integerColumns = {
      'account_book': {
        'book_time',
        'is_default',
        'created_at',
        'updated_at',
        'deleted_at',
      },
      'person': {'created_at', 'updated_at', 'deleted_at'},
      'gift_record': {
        'amount_cent',
        'occurred_at',
        'created_at',
        'updated_at',
        'deleted_at',
      },
      'reason': {'enabled', 'created_at', 'updated_at'},
      'relation_type': {'created_at', 'updated_at'},
      'contact_relation': {'created_at', 'updated_at'},
      'entity_remark': {'created_at'},
      'data_import_job': {
        'file_size',
        'total_rows',
        'processed_rows',
        'success_rows',
        'skipped_rows',
        'failed_rows',
        'byte_offset',
        'last_row_index',
        'started_at',
        'finished_at',
        'updated_at',
      },
    };
    const nullable = {
      'account_book': {'icon', 'description', 'attachments', 'deleted_at'},
      'person': {
        'phone',
        'birthday',
        'anniversary',
        'avatar_uri',
        'note',
        'deleted_at',
      },
      'gift_record': {'event_name', 'note', 'attachments', 'deleted_at'},
      'reason': {'description'},
      'contact_relation': {'note'},
      'data_import_job': {
        'mapping_json',
        'total_rows',
        'error_log_path',
        'finished_at',
      },
    };
    const defaults = {
      'account_book': {
        'reason_type': "''",
        'theme_color': "'#312E81'",
        'is_default': '0',
      },
      'person': {'relationship_type': "'其他'"},
      'gift_record': {'direction': "'收入'", 'currency': "'CNY'"},
      'reason': {'enabled': '1'},
      'data_import_job': {
        'processed_rows': '0',
        'success_rows': '0',
        'skipped_rows': '0',
        'failed_rows': '0',
        'byte_offset': '0',
        'last_row_index': '0',
      },
    };
    const checks = {
      'account_book': [
        'check(length(name)between1and32)',
        'check(is_defaultin(0,1))',
      ],
      'person': ['check(length(name)between1and32)'],
      'gift_record': [
        "check(directionin('收入','支出'))",
        "check(typeof(amount_cent)='integer'andamount_centbetween1and99999999999999)",
      ],
      'reason': ['check(enabledin(0,1))'],
    };
    const foreignKeys = {
      'gift_record': {
        'book_id|account_book|book_id|CASCADE',
        'person_id|person|person_id|CASCADE',
      },
      'contact_relation': {
        'person_a_id|person|person_id|CASCADE',
        'person_b_id|person|person_id|CASCADE',
        'type_id|relation_type|type_id|RESTRICT',
      },
      'data_import_job': {'book_id|account_book|book_id|CASCADE'},
    };
    if (db
        .select("SELECT 1 FROM sqlite_master WHERE type='trigger' LIMIT 1")
        .isNotEmpty) {
      throw const FormatException('当前备份结构不能包含触发器');
    }
    for (final table in columns.entries) {
      final master = db.select(
        'SELECT type,sql FROM sqlite_master WHERE name=?',
        [table.key],
      );
      final info = db.select('PRAGMA table_info(${table.key})');
      if (master.length != 1 ||
          master.single['type'] != 'table' ||
          info.length != table.value.length) {
        throw FormatException('备份表结构不符合当前版本：${table.key}');
      }
      final definition = (master.single['sql'] as String)
          .toLowerCase()
          .replaceAll(RegExp(r'[\s"`\[\]]'), '');
      if (definition.startsWith('createvirtualtable') ||
          (checks[table.key] ?? const <String>[]).any(
            (c) => !definition.contains(c),
          )) {
        throw FormatException('备份缺少当前数据约束：${table.key}');
      }
      for (final name in table.value) {
        final matches = info.where((r) => r['name'] == name);
        final optional = nullable[table.key]?.contains(name) ?? false;
        final type = integerColumns[table.key]!.contains(name)
            ? 'INTEGER'
            : 'TEXT';
        final expectedDefault = defaults[table.key]?[name];
        if (matches.length != 1 ||
            matches.single['type'] != type ||
            matches.single['notnull'] != (optional ? 0 : 1) ||
            matches.single['pk'] != (name == table.value.first ? 1 : 0) ||
            matches.single['dflt_value'] != expectedDefault) {
          throw FormatException('备份字段结构不符合当前版本：${table.key}.$name');
        }
        final storedType = type == 'INTEGER' ? 'integer' : 'text';
        final invalid = optional
            ? '$name IS NOT NULL AND typeof($name)!=\'$storedType\''
            : '$name IS NULL OR typeof($name)!=\'$storedType\'';
        if (db
            .select('SELECT 1 FROM ${table.key} WHERE $invalid LIMIT 1')
            .isNotEmpty) {
          throw FormatException('备份字段值不合法：${table.key}.$name');
        }
      }
      final key = table.value.first;
      if (db
          .select('SELECT 1 FROM ${table.key} WHERE length($key)=0 LIMIT 1')
          .isNotEmpty) {
        throw FormatException('备份主键为空：${table.key}');
      }
      final actualForeignKeys = db.select(
        'PRAGMA foreign_key_list(${table.key})',
      );
      final expectedForeignKeys = foreignKeys[table.key] ?? const <String>{};
      final signatures = actualForeignKeys
          .map((r) => '${r['from']}|${r['table']}|${r['to']}|${r['on_delete']}')
          .toSet();
      if (actualForeignKeys.length != expectedForeignKeys.length ||
          !signatures.containsAll(expectedForeignKeys) ||
          actualForeignKeys.any((r) => r['on_update'] != 'NO ACTION')) {
        throw FormatException('备份外键结构不符合当前版本：${table.key}');
      }
    }
    for (final table in ['reason', 'relation_type']) {
      final uniqueNames = db
          .select('PRAGMA index_list($table)')
          .where((r) => r['unique'] == 1 && r['partial'] == 0);
      final hasNameConstraint = uniqueNames.any((r) {
        final index = (r['name'] as String).replaceAll("'", "''");
        final info = db.select("PRAGMA index_info('$index')");
        return info.length == 1 && info.single['name'] == 'normalized_name';
      });
      if (!hasNameConstraint) throw FormatException('备份缺少名称唯一约束：$table');
    }
    const invalidValues = {
      'account_book':
          'length(name) NOT BETWEEN 1 AND 32 OR is_default NOT IN (0,1)',
      'person': 'length(name) NOT BETWEEN 1 AND 32',
      'reason': 'length(name) NOT BETWEEN 1 AND 64 OR length(normalized_name) NOT BETWEEN 1 AND 64 OR enabled NOT IN (0,1)',
      'relation_type': 'length(name) NOT BETWEEN 1 AND 64 OR length(normalized_name) NOT BETWEEN 1 AND 64',
      'data_import_job': 'file_size<0 OR total_rows<0 OR processed_rows<0 OR success_rows<0 OR skipped_rows<0 OR failed_rows<0 OR byte_offset<0 OR last_row_index<0',
    };
    for (final entry in invalidValues.entries) {
      if (db
          .select('SELECT 1 FROM ${entry.key} WHERE ${entry.value} LIMIT 1')
          .isNotEmpty) {
        throw FormatException('备份包含非法字段值：${entry.key}');
      }
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
          db.execute('UPDATE $table SET attachments=? WHERE $key=?', [
            includeMedia
                ? jsonEncode(values.map((v) => remap(v as String)).toList())
                : null,
            row[key],
          ]);
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
      'hadDb': await File(p.join(docs.path, 'newshangli_drift.sqlite'))
          .exists(),
      'hadMedia': await Directory(p.join(docs.path, 'media')).exists(),
      'guardFiles': await _guardInventory(guard.path),
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
    final targetMedia = Directory(p.join(docs.path, 'media'));
    final savedMedia = Directory(p.join(guard, 'media'));
    if (data['hadMedia'] == true && !await savedMedia.exists()) {
      throw const FormatException('恢复保护媒体缺失');
    }
    // 先读取和校验整套保护文件，不能在检查媒体之前改写 live DB。
    final actual = await _guardInventory(guard);
    final expected = data['guardFiles'];
    if (expected != null) {
      if (expected is! Map ||
          actual.length != expected.length ||
          actual.entries.any((entry) {
            final saved = expected[entry.key];
            return saved is! Map ||
                saved['size'] != entry.value['size'] ||
                saved['sha256'] != entry.value['sha256'];
          })) {
        throw const FormatException('恢复保护文件缺失或已损坏');
      }
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
    if (await targetMedia.exists()) await targetMedia.delete(recursive: true);
    if (await savedMedia.exists()) await copyDirectory(savedMedia, targetMedia);
    await pending.delete();
  }

  static Future<Map<String, Map<String, Object>>> _guardInventory(
    String guard,
  ) async {
    final files = <String, Map<String, Object>>{};
    Future<void> inspect(File file) async {
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type != FileSystemEntityType.file) {
        throw const FormatException('恢复保护文件类型不合法');
      }
      final name = p.relative(file.path, from: guard).replaceAll('\\', '/');
      files[name] = {
        'size': await file.length(),
        'sha256': (await sha256.bind(file.openRead()).first).toString(),
      };
    }

    if (await FileSystemEntity.isLink(guard)) {
      throw const FormatException('恢复保护目录不能是符号链接');
    }
    for (final name in [
      'newshangli_drift.sqlite',
      'newshangli_drift.sqlite-wal',
      'newshangli_drift.sqlite-shm',
    ]) {
      final file = File(p.join(guard, name));
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.notFound) {
        await inspect(file);
      }
    }
    final media = Directory(p.join(guard, 'media'));
    final type = await FileSystemEntity.type(media.path, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      if (type != FileSystemEntityType.directory) {
        throw const FormatException('恢复保护媒体目录类型不合法');
      }
      await for (final entity in media.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Directory) continue;
        if (entity is! File) throw const FormatException('恢复保护媒体类型不合法');
        await inspect(entity);
      }
    }
    return files;
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
