import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/local/drift/app_database.dart';

class SupabaseSyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseSyncService(this._db);

  static int _parseBookTimeMillisValue(dynamic value) {
    if (value == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value).millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  static int _intValue(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _nullableIntValue(dynamic value) {
    if (value == null) return null;
    return _intValue(value);
  }

  static String _stringValue(dynamic value) => (value as String).trim();

  static String? _nullableStringValue(dynamic value) {
    final text = (value as String?)?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static bool _looksLikeRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool _isAbsolutePath(String value) {
    return p.isAbsolute(value) || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
  }

  static bool _isWithinRoot(String targetPath, String rootPath) {
    final normalizedTarget = p.normalize(targetPath);
    final normalizedRoot = p.normalize(rootPath);
    final target = Platform.isWindows
        ? normalizedTarget.toLowerCase()
        : normalizedTarget;
    final root = Platform.isWindows
        ? normalizedRoot.toLowerCase()
        : normalizedRoot;
    if (target == root) return true;
    return target.startsWith('$root${Platform.pathSeparator}');
  }

  static String _stripLeadingCurrentDir(String value) {
    if (value == '.') return '';
    if (value.startsWith('./')) return value.substring(2);
    return value;
  }

  /// 将本地存储路径提取为可跨设备复用的媒体相对路径。
  ///
  /// 例如：
  /// - `C:\foo\media\attachments\a.jpg` -> `attachments/a.jpg`
  /// - `media/avatars\a.png` -> `avatars/a.png`
  @visibleForTesting
  static String? extractPortableMediaRelativePath(String? storedPath) {
    final raw = (storedPath ?? '').trim();
    if (raw.isEmpty) return null;
    if (_looksLikeRemoteUrl(raw)) return raw;

    String normalized = raw;
    if (raw.startsWith('file://')) {
      try {
        normalized = Uri.parse(raw).toFilePath(windows: Platform.isWindows);
      } catch (_) {
        normalized = raw.substring('file://'.length);
      }
    }

    normalized = normalized.replaceAll('\\', '/');
    final mediaMarker = '/media/';
    final markerIndex = normalized.toLowerCase().lastIndexOf(mediaMarker);
    if (markerIndex >= 0) {
      final relative = normalized.substring(markerIndex + mediaMarker.length);
      return _stripLeadingCurrentDir(p.posix.normalize(relative));
    }

    var candidate = normalized;
    if (candidate.toLowerCase().startsWith('media/')) {
      candidate = candidate.substring('media/'.length);
    } else if (candidate.startsWith('/')) {
      candidate = candidate.substring(1);
    }

    if (candidate.startsWith('attachments/') ||
        candidate.startsWith('avatars/')) {
      return _stripLeadingCurrentDir(p.posix.normalize(candidate));
    }

    if (!_isAbsolutePath(raw)) {
      return _stripLeadingCurrentDir(p.posix.normalize(candidate));
    }

    return null;
  }

  /// 将本地数据库中的媒体路径规范化为云端可存储的相对路径。
  @visibleForTesting
  static String? normalizeMediaPathForCloud(
    String? storedPath, {
    required String mediaRootPath,
  }) {
    final raw = (storedPath ?? '').trim();
    if (raw.isEmpty) return null;
    if (_looksLikeRemoteUrl(raw)) return raw;

    if (_isAbsolutePath(raw)) {
      final normalizedAbsolute = p.normalize(raw);
      if (_isWithinRoot(normalizedAbsolute, mediaRootPath)) {
        final relative = p.relative(normalizedAbsolute, from: mediaRootPath);
        return _stripLeadingCurrentDir(
          p.posix.normalize(relative.replaceAll('\\', '/')),
        );
      }
    }

    return extractPortableMediaRelativePath(raw);
  }

  static List<String>? _normalizeMediaPathListForCloud(
    List<String>? storedPaths, {
    required String mediaRootPath,
  }) {
    if (storedPaths == null || storedPaths.isEmpty) return null;
    final normalized = storedPaths
        .map(
          (path) =>
              normalizeMediaPathForCloud(path, mediaRootPath: mediaRootPath),
        )
        .whereType<String>()
        .where((path) => path.trim().isNotEmpty)
        .toList();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  /// 将云端存储的相对路径还原为当前设备的本地媒体绝对路径。
  ///
  /// 这一步兼容两种旧数据：
  /// - 云端已经是 `attachments/a.jpg` 这种相对路径
  /// - 云端历史上写入了其它设备的绝对路径，但仍包含 `media/...`
  @visibleForTesting
  static String? materializeCloudMediaPath(
    String? storedPath, {
    required String mediaRootPath,
  }) {
    final raw = (storedPath ?? '').trim();
    if (raw.isEmpty) return null;
    if (_looksLikeRemoteUrl(raw)) return raw;

    final relative = extractPortableMediaRelativePath(raw);
    if (relative == null || relative.isEmpty) return null;
    final segments = p.posix
        .normalize(relative)
        .split('/')
        .where((segment) => segment.isNotEmpty && segment != '.')
        .toList();
    if (segments.isEmpty) return null;
    return p.joinAll(<String>[mediaRootPath, ...segments]);
  }

  static List<String>? _materializeCloudMediaPathList(
    List<String>? storedPaths, {
    required String mediaRootPath,
  }) {
    if (storedPaths == null || storedPaths.isEmpty) return null;
    final materialized = storedPaths
        .map(
          (path) =>
              materializeCloudMediaPath(path, mediaRootPath: mediaRootPath),
        )
        .whereType<String>()
        .where((path) => path.trim().isNotEmpty)
        .toList();
    if (materialized.isEmpty) return null;
    return materialized;
  }

  static List<Map<String, dynamic>> _rows(List<dynamic> data) {
    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  static String _normalizeUniqueName(String? value) =>
      (value ?? '').trim().toLowerCase();

  static (String, String) _normalizePair(String a, String b) {
    final x = a.trim();
    final y = b.trim();
    if (x.compareTo(y) <= 0) return (x, y);
    return (y, x);
  }

  static Future<void> _deleteReasonWithSameName({
    required AppDatabase db,
    required String name,
    required String keepReasonId,
  }) async {
    await db.customStatement(
      'DELETE FROM reason WHERE name = ? COLLATE NOCASE AND reason_id <> ?;',
      [name, keepReasonId],
    );
  }

  static Future<void> _deleteContactRelationWithSamePair({
    required AppDatabase db,
    required String personAId,
    required String personBId,
    required String typeId,
    required String keepRelationId,
  }) async {
    await db.customStatement(
      'DELETE FROM contact_relation '
      'WHERE person_a_id = ? AND person_b_id = ? AND type_id = ? '
      'AND relation_id <> ?;',
      [personAId, personBId, typeId, keepRelationId],
    );
  }

  static Future<void> _restoreAccountBooks(
    AppDatabase db,
    List<Map<String, dynamic>> rows,
    Map<String, String> bookIdMap, {
    required AccountBook? localDefaultBeforeRestore,
    required String mediaRootPath,
  }) async {
    if (rows.isEmpty) return;

    final defaultRows =
        rows.where((row) => _intValue(row['is_default']) == 1).toList()..sort(
          (a, b) =>
              _intValue(b['updated_at']).compareTo(_intValue(a['updated_at'])),
        );
    final cloudDefault = defaultRows.isEmpty ? null : defaultRows.first;
    final localDefault = localDefaultBeforeRestore;
    if (cloudDefault != null && localDefault != null) {
      final cloudDefaultId = _stringValue(cloudDefault['book_id']);
      if (cloudDefaultId != localDefault.bookId) {
        bookIdMap[cloudDefaultId] = localDefault.bookId;
      }
    }

    await db.transaction(() async {
      for (final mappedId in bookIdMap.keys) {
        await (db.delete(
          db.accountBooks,
        )..where((t) => t.bookId.equals(mappedId))).go();
      }

      for (final row in rows) {
        final sourceBookId = _stringValue(row['book_id']);
        final bookId = bookIdMap[sourceBookId] ?? sourceBookId;
        final book = AccountBook(
          bookId: bookId,
          name: _stringValue(row['name']),
          reasonType: _stringValue(row['reason_type'] ?? ''),
          themeColor: _stringValue(row['theme_color'] ?? '#312E81'),
          icon: _nullableStringValue(row['icon']),
          description: _nullableStringValue(row['description']),
          attachments: row['attachments'] != null
              ? _materializeCloudMediaPathList(
                  List<String>.from(row['attachments'] as Iterable),
                  mediaRootPath: mediaRootPath,
                )
              : null,
          bookTime: _parseBookTimeMillisValue(row['book_time']),
          isDefault: _intValue(row['is_default']),
          createdAt: _intValue(row['created_at']),
          updatedAt: _intValue(row['updated_at']),
          deletedAt: _nullableIntValue(row['deleted_at']),
        );
        final existing = await db.accountBooksDao.findById(bookId);
        if (existing == null) {
          await db.into(db.accountBooks).insert(book);
        } else {
          await (db.update(
            db.accountBooks,
          )..where((t) => t.bookId.equals(bookId))).write(
            AccountBooksCompanion(
              name: Value(book.name),
              reasonType: Value(book.reasonType),
              themeColor: Value(book.themeColor),
              icon: Value(book.icon),
              description: Value(book.description),
              attachments: Value(book.attachments),
              bookTime: Value(book.bookTime),
              isDefault: Value(book.isDefault),
              createdAt: Value(book.createdAt),
              updatedAt: Value(book.updatedAt),
              deletedAt: Value(book.deletedAt),
            ),
          );
        }
      }

      if (cloudDefault != null) {
        final defaultId =
            bookIdMap[_stringValue(cloudDefault['book_id'])] ??
            _stringValue(cloudDefault['book_id']);
        await db.customStatement(
          'UPDATE account_book SET is_default = CASE WHEN book_id = ? THEN 1 ELSE 0 END;',
          [defaultId],
        );
      }
    });
  }

  static Future<void> _restorePersons(
    AppDatabase db,
    List<Map<String, dynamic>> rows,
    Map<String, String> bookIdMap,
    String mediaRootPath,
  ) async {
    if (rows.isEmpty) return;
    await db.batch((batch) {
      batch.insertAll(
        db.persons,
        rows.map(
          (p) => Person(
            personId: _stringValue(p['person_id']),
            bookId:
                bookIdMap[_stringValue(p['book_id'])] ??
                _stringValue(p['book_id']),
            name: _stringValue(p['name']),
            relationshipType: _stringValue(p['relationship_type'] ?? '其他'),
            phone: _nullableStringValue(p['phone']),
            birthday: _nullableStringValue(p['birthday']),
            anniversary: _nullableStringValue(p['anniversary']),
            avatarUri: materializeCloudMediaPath(
              _nullableStringValue(p['avatar_uri']),
              mediaRootPath: mediaRootPath,
            ),
            note: _nullableStringValue(p['note']),
            createdAt: _intValue(p['created_at']),
            updatedAt: _intValue(p['updated_at']),
            deletedAt: _nullableIntValue(p['deleted_at']),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  static Future<void> _restoreGiftRecords(
    AppDatabase db,
    List<Map<String, dynamic>> rows,
    Map<String, String> bookIdMap,
    String mediaRootPath,
  ) async {
    if (rows.isEmpty) return;
    await db.batch((batch) {
      batch.insertAll(
        db.giftRecords,
        rows.map(
          (r) => GiftRecord(
            recordId: _stringValue(r['record_id']),
            bookId:
                bookIdMap[_stringValue(r['book_id'])] ??
                _stringValue(r['book_id']),
            personId: _stringValue(r['person_id']),
            direction: _stringValue(r['direction']),
            amountCent: _intValue(r['amount_cent']),
            currency: _stringValue(r['currency'] ?? 'CNY'),
            eventName: _nullableStringValue(r['event_name']),
            occurredAt: _intValue(r['occurred_at']),
            paymentMethod: _nullableStringValue(r['payment_method']),
            note: _nullableStringValue(r['note']),
            attachments: r['attachments'] != null
                ? _materializeCloudMediaPathList(
                    List<String>.from(r['attachments'] as Iterable),
                    mediaRootPath: mediaRootPath,
                  )
                : null,
            createdAt: _intValue(r['created_at']),
            updatedAt: _intValue(r['updated_at']),
            deletedAt: _nullableIntValue(r['deleted_at']),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  static Future<void> _restoreReasons(
    AppDatabase db,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await db.transaction(() async {
      for (final row in rows) {
        final reasonId = _stringValue(row['reason_id']);
        final name = _stringValue(row['name']);
        await _deleteReasonWithSameName(
          db: db,
          name: name,
          keepReasonId: reasonId,
        );
        await db
            .into(db.reasons)
            .insert(
              Reason(
                reasonId: reasonId,
                name: name,
                normalizedName:
                    _nullableStringValue(row['normalized_name']) ??
                    _normalizeUniqueName(name),
                description: _nullableStringValue(row['description']),
                enabled: _boolValue(row['enabled']),
                createdAt: _intValue(row['created_at']),
                updatedAt: _intValue(row['updated_at']),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  static Future<void> _restoreRelationTypes(
    AppDatabase db,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await db.transaction(() async {
      for (final row in rows) {
        final cloudTypeId = _stringValue(row['type_id']);
        final name = _stringValue(row['name']);
        final normalizedName =
            _nullableStringValue(row['normalized_name']) ??
            _normalizeUniqueName(name);
        final duplicates = await db
            .customSelect(
              'SELECT type_id FROM relation_type '
              'WHERE normalized_name = ? AND type_id <> ?;',
              variables: [
                Variable<String>(normalizedName),
                Variable<String>(cloudTypeId),
              ],
              readsFrom: {db.relationTypes},
            )
            .get();
        for (final duplicate in duplicates) {
          final duplicateTypeId = duplicate.data['type_id'] as String;
          await (db.update(
            db.relationTypes,
          )..where((t) => t.typeId.equals(duplicateTypeId))).write(
            RelationTypesCompanion(
              normalizedName: Value(
                '${normalizedName}__legacy__$duplicateTypeId',
              ),
              updatedAt: Value(_intValue(row['updated_at'])),
            ),
          );
        }
        final current = await db.relationTypesDao.findById(cloudTypeId);
        if (current == null) {
          await db
              .into(db.relationTypes)
              .insert(
                RelationType(
                  typeId: cloudTypeId,
                  name: name,
                  normalizedName: normalizedName,
                  createdAt: _intValue(row['created_at']),
                  updatedAt: _intValue(row['updated_at']),
                ),
              );
        } else {
          await (db.update(
            db.relationTypes,
          )..where((t) => t.typeId.equals(cloudTypeId))).write(
            RelationTypesCompanion(
              name: Value(name),
              normalizedName: Value(normalizedName),
              createdAt: Value(_intValue(row['created_at'])),
              updatedAt: Value(_intValue(row['updated_at'])),
            ),
          );
        }
        for (final duplicate in duplicates) {
          final duplicateTypeId = duplicate.data['type_id'] as String;
          await db.customStatement(
            'UPDATE contact_relation SET type_id = ? WHERE type_id = ?;',
            [cloudTypeId, duplicateTypeId],
          );
          await (db.delete(
            db.relationTypes,
          )..where((t) => t.typeId.equals(duplicateTypeId))).go();
        }
      }
    });
  }

  static Future<void> _restoreContactRelations(
    AppDatabase db,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await db.transaction(() async {
      for (final row in rows) {
        final relationId = _stringValue(row['relation_id']);
        final typeId = _stringValue(row['type_id']);
        final pair = _normalizePair(
          _stringValue(row['person_a_id']),
          _stringValue(row['person_b_id']),
        );
        await _deleteContactRelationWithSamePair(
          db: db,
          personAId: pair.$1,
          personBId: pair.$2,
          typeId: typeId,
          keepRelationId: relationId,
        );
        await db
            .into(db.contactRelations)
            .insert(
              ContactRelation(
                relationId: relationId,
                personAId: pair.$1,
                personBId: pair.$2,
                typeId: typeId,
                note: _nullableStringValue(row['note']),
                createdAt: _intValue(row['created_at']),
                updatedAt: _intValue(row['updated_at']),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  static Future<void> _restoreTablesFromCloudPayload({
    required AppDatabase db,
    required _CloudRestorePayload payload,
    AccountBook? localDefaultBeforeRestore,
    String mediaRootPath = 'media',
  }) async {
    final bookIdMap = <String, String>{};
    final effectiveLocalDefault =
        localDefaultBeforeRestore ?? await db.accountBooksDao.findDefault();
    await _restoreAccountBooks(
      db,
      payload.books,
      bookIdMap,
      localDefaultBeforeRestore: effectiveLocalDefault,
      mediaRootPath: mediaRootPath,
    );
    await _restorePersons(db, payload.persons, bookIdMap, mediaRootPath);
    await _restoreGiftRecords(db, payload.records, bookIdMap, mediaRootPath);
    await _restoreReasons(db, payload.reasons);
    await _restoreRelationTypes(db, payload.relationTypes);
    await _restoreContactRelations(db, payload.contactRelations);
  }

  @visibleForTesting
  static Future<void> restoreTablesForTesting({
    required AppDatabase db,
    required List<dynamic> booksData,
    List<dynamic> personsData = const [],
    List<dynamic> recordsData = const [],
    List<dynamic> reasonsData = const [],
    List<dynamic> relationTypesData = const [],
    List<dynamic> contactRelationsData = const [],
  }) async {
    return _restoreTablesFromCloudPayload(
      db: db,
      payload: _CloudRestorePayload(
        books: _rows(booksData),
        persons: _rows(personsData),
        records: _rows(recordsData),
        reasons: _rows(reasonsData),
        relationTypes: _rows(relationTypesData),
        contactRelations: _rows(contactRelationsData),
      ),
    );
  }

  @visibleForTesting
  static Map<String, dynamic> accountBookToCloudRow(
    AccountBook book,
    String userId,
  ) {
    return <String, dynamic>{
      'book_id': book.bookId,
      'name': book.name,
      'reason_type': book.reasonType,
      'theme_color': book.themeColor,
      'icon': book.icon,
      'description': book.description,
      'attachments': book.attachments,
      // 云端字段与本地 Drift 一致，统一使用毫秒时间戳，避免 bigint 列收到日期字符串。
      'book_time': book.bookTime,
      'is_default': book.isDefault,
      'created_at': book.createdAt,
      'updated_at': book.updatedAt,
      'deleted_at': book.deletedAt,
      'user_id': userId,
    };
  }

  Future<void> syncToCloud({required void Function(String) onProgress}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('用户未登录，无法同步');
    }
    final docs = await getApplicationDocumentsDirectory();
    final mediaRootPath = p.join(docs.path, 'media');

    // 1. 同步账簿
    onProgress('正在同步账簿...');
    final books = await _db.select(_db.accountBooks).get();
    if (books.isNotEmpty) {
      final booksData = books
          .map(
            (b) => {
              ...accountBookToCloudRow(b, user.id),
              'attachments': _normalizeMediaPathListForCloud(
                b.attachments,
                mediaRootPath: mediaRootPath,
              ),
            },
          )
          .toList();
      await _supabase.from('account_book').upsert(booksData);
    }

    // 2. 同步关系人
    onProgress('正在同步关系人...');
    final persons = await _db.select(_db.persons).get();
    if (persons.isNotEmpty) {
      final personsData = persons
          .map(
            (p) => {
              'person_id': p.personId,
              'book_id': p.bookId,
              'name': p.name,
              'relationship_type': p.relationshipType,
              'phone': p.phone,
              'birthday': p.birthday,
              'anniversary': p.anniversary,
              'avatar_uri': normalizeMediaPathForCloud(
                p.avatarUri,
                mediaRootPath: mediaRootPath,
              ),
              'note': p.note,
              'created_at': p.createdAt,
              'updated_at': p.updatedAt,
              'deleted_at': p.deletedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase.from('person').upsert(personsData);
    }

    // 3. 同步礼金记录
    onProgress('正在同步礼金记录...');
    final records = await _db.select(_db.giftRecords).get();
    if (records.isNotEmpty) {
      final recordsData = records
          .map(
            (r) => {
              'record_id': r.recordId,
              'book_id': r.bookId,
              'person_id': r.personId,
              'direction': r.direction,
              'amount_cent': r.amountCent,
              'currency': r.currency,
              'event_name': r.eventName,
              'occurred_at': r.occurredAt,
              'payment_method': r.paymentMethod,
              'note': r.note,
              'attachments': _normalizeMediaPathListForCloud(
                r.attachments,
                mediaRootPath: mediaRootPath,
              ),
              'created_at': r.createdAt,
              'updated_at': r.updatedAt,
              'deleted_at': r.deletedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase.from('gift_record').upsert(recordsData);
    }

    // 4. 同步事由
    onProgress('正在同步事由...');
    final reasons = await _db.select(_db.reasons).get();
    if (reasons.isNotEmpty) {
      final reasonsData = reasons
          .map(
            (r) => {
              'reason_id': r.reasonId,
              'name': r.name,
              'normalized_name': _normalizeUniqueName(r.name),
              'description': r.description,
              'enabled': r.enabled,
              'created_at': r.createdAt,
              'updated_at': r.updatedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase
          .from('reason')
          .upsert(reasonsData, onConflict: 'normalized_name');
    }

    // 5. 同步关系类型
    onProgress('正在同步关系类型...');
    final relationTypes = await _db.select(_db.relationTypes).get();
    if (relationTypes.isNotEmpty) {
      final relationTypesData = relationTypes
          .map(
            (rt) => {
              'type_id': rt.typeId,
              'name': rt.name,
              'normalized_name': _normalizeUniqueName(rt.name),
              'created_at': rt.createdAt,
              'updated_at': rt.updatedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase
          .from('relation_type')
          .upsert(relationTypesData, onConflict: 'normalized_name');
    }

    // 6. 同步联系人关系
    onProgress('正在同步联系人关系...');
    final contactRelations = await _db.select(_db.contactRelations).get();
    if (contactRelations.isNotEmpty) {
      final contactRelationsData = contactRelations
          .map(
            (cr) => {
              'relation_id': cr.relationId,
              'person_a_id': cr.personAId,
              'person_b_id': cr.personBId,
              'type_id': cr.typeId,
              'note': cr.note,
              'created_at': cr.createdAt,
              'updated_at': cr.updatedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase.from('contact_relation').upsert(contactRelationsData);
    }

    // 7. 同步附件媒体
    onProgress('正在同步附件媒体...');
    await _syncMediaToCloud(user.id, onProgress);

    onProgress('云端同步完成！');
  }

  /// 从云端拉取数据到本地 (Pull)
  Future<void> syncFromCloud({
    required void Function(String) onProgress,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('用户未登录，无法恢复');
    }

    // 1. 恢复账簿
    onProgress('正在拉取账簿...');
    final localDefaultBeforeRestore = await _db.accountBooksDao.findDefault();
    final booksData = await _supabase
        .from('account_book')
        .select()
        .eq('user_id', user.id);

    // 2. 恢复关系人
    onProgress('正在拉取关系人...');
    final personsData = await _supabase
        .from('person')
        .select()
        .eq('user_id', user.id);

    // 3. 恢复礼金记录
    onProgress('正在拉取礼金记录...');
    final recordsData = await _supabase
        .from('gift_record')
        .select()
        .eq('user_id', user.id);

    // 4. 恢复事由
    onProgress('正在拉取事由...');
    final reasonsData = await _supabase
        .from('reason')
        .select()
        .eq('user_id', user.id);

    // 5. 恢复关系类型
    onProgress('正在拉取关系类型...');
    final relationTypesData = await _supabase
        .from('relation_type')
        .select()
        .eq('user_id', user.id);

    // 6. 恢复联系人关系
    onProgress('正在拉取联系人关系...');
    final contactRelationsData = await _supabase
        .from('contact_relation')
        .select()
        .eq('user_id', user.id);

    // 7. 恢复附件媒体
    onProgress('正在写入恢复数据...');
    final docs = await getApplicationDocumentsDirectory();
    final mediaRootPath = p.join(docs.path, 'media');
    await _restoreTablesFromCloudPayload(
      db: _db,
      payload: _CloudRestorePayload(
        books: _rows(booksData),
        persons: _rows(personsData),
        records: _rows(recordsData),
        reasons: _rows(reasonsData),
        relationTypes: _rows(relationTypesData),
        contactRelations: _rows(contactRelationsData),
      ),
      localDefaultBeforeRestore: localDefaultBeforeRestore,
      mediaRootPath: mediaRootPath,
    );
    onProgress('正在拉取附件媒体...');
    await _syncMediaFromCloud(user.id, onProgress);

    onProgress('本地数据恢复完成！');
  }

  /// 确保 Storage Bucket 存在且已配置好 RLS 策略。
  ///
  /// 仅验证 bucket 是否可访问；不会尝试从客户端创建 bucket，
  /// 因为通过 anon key 调用 createBucket 通常没有权限，
  /// 即使成功也会创建一个没有 RLS 策略的 bucket（默认全部拒绝）。
  /// 请通过 Supabase 迁移来创建 bucket 并配置策略：
  ///   supabase/migrations/create_storage_media_bucket.sql
  Future<void> _ensureStorageBucket(String bucketId) async {
    try {
      // 尝试列出 bucket 内容以验证是否存在以及 RLS 是否允许查询
      await _supabase.storage.from(bucketId).list();
    } on StorageException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.statusCode == '404' || msg.contains('bucket not found') || msg.contains('not found')) {
        throw Exception(
          'Storage bucket "$bucketId" 不存在。'
          '请在 Supabase 控制台运行迁移文件：'
          'supabase/migrations/create_storage_${bucketId}_bucket.sql'
          '（原始错误: ${e.message}）',
        );
      } else if (e.statusCode == '403' || msg.contains('row-level security') || msg.contains('unauthorized')) {
        throw Exception(
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

  /// 同步本地媒体文件到云端
  Future<void> _syncMediaToCloud(
    String userId,
    void Function(String) onProgress,
  ) async {
    final docs = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docs.path, 'media'));
    if (!await mediaDir.exists()) return;

    // 确保 media bucket 存在
    await _ensureStorageBucket('media');

    final entities = await mediaDir
        .list(recursive: true, followLinks: false)
        .toList();
    var uploadCount = 0;
    final failedFiles = <String>[];
    for (final entity in entities) {
      if (entity is File) {
        final relative = p.relative(entity.path, from: mediaDir.path);
        final remotePath = '$userId/${relative.replaceAll('\\', '/')}';

        onProgress('上传附件: $relative...');
        try {
          await _supabase.storage
              .from('media')
              .upload(
                remotePath,
                entity,
                fileOptions: const FileOptions(upsert: true),
              );
          uploadCount++;
        } on StorageException catch (e) {
          failedFiles.add(relative);
          final detail = (e.statusCode == '403' ||
                  e.message.toLowerCase().contains('row-level security'))
              ? ' — RLS 策略拒绝访问，请确认已运行迁移：'
                  'supabase/migrations/create_storage_media_bucket.sql'
              : '';
          onProgress('上传附件失败: $relative ($e)$detail');
        } catch (e) {
          failedFiles.add(relative);
          onProgress('上传附件失败: $relative ($e)');
        }
      }
    }

    onProgress('附件上传完成：成功 $uploadCount 个，失败 ${failedFiles.length} 个。');
    if (failedFiles.isNotEmpty) {
      throw Exception('有 ${failedFiles.length} 个附件上传失败，请查看同步日志');
    }
  }

  /// 从云端拉取媒体文件到本地
  Future<void> _syncMediaFromCloud(
    String userId,
    void Function(String) onProgress,
  ) async {
    try {
      // 确保 media bucket 存在
      await _ensureStorageBucket('media');

      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(docs.path, 'media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      // 当前媒体全部落在 avatars / attachments 两个目录下。
      // 这里不再遍历根目录，避免把文件夹节点误当成文件下载。
      final candidates = <String>['$userId/avatars', '$userId/attachments'];
      var downloadCount = 0;
      final failedFiles = <String>[];
      for (final prefix in candidates) {
        final List<FileObject> remoteFiles = await _supabase.storage
            .from('media')
            .list(path: prefix);
        if (remoteFiles.isEmpty) continue;

        final relativePrefix = prefix == userId
            ? ''
            : prefix.substring(userId.length + 1);
        final localBaseDir = relativePrefix.isEmpty
            ? mediaDir
            : Directory(p.join(mediaDir.path, relativePrefix));
        if (!await localBaseDir.exists()) {
          await localBaseDir.create(recursive: true);
        }

        for (final file in remoteFiles) {
          if (file.name == '.emptyFolderPlaceholder') continue;

          final remotePath = relativePrefix.isEmpty
              ? '$userId/${file.name}'
              : '$userId/$relativePrefix/${file.name}';
          final localPath = p.join(localBaseDir.path, file.name);

          onProgress(
            '下载附件: ${relativePrefix.isEmpty ? file.name : '$relativePrefix/${file.name}'}...',
          );
          try {
            final bytes = await _supabase.storage
                .from('media')
                .download(remotePath);
            final localFile = File(localPath);
            await localFile.writeAsBytes(bytes);
            downloadCount++;
          } catch (e) {
            failedFiles.add(remotePath);
            onProgress(
              '下载附件失败: ${relativePrefix.isEmpty ? file.name : '$relativePrefix/${file.name}'} ($e)',
            );
          }
        }
      }

      onProgress('附件下载完成：成功 $downloadCount 个，失败 ${failedFiles.length} 个。');
      if (failedFiles.isNotEmpty) {
        throw Exception('有 ${failedFiles.length} 个附件下载失败，请查看同步日志');
      }
    } catch (e) {
      onProgress('获取云端附件列表失败 ($e)');
      rethrow;
    }
  }
}

class _CloudRestorePayload {
  const _CloudRestorePayload({
    required this.books,
    required this.persons,
    required this.records,
    required this.reasons,
    required this.relationTypes,
    required this.contactRelations,
  });

  final List<Map<String, dynamic>> books;
  final List<Map<String, dynamic>> persons;
  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> reasons;
  final List<Map<String, dynamic>> relationTypes;
  final List<Map<String, dynamic>> contactRelations;
}
