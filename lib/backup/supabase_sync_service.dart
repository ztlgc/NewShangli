import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/local/drift/app_database.dart';

class SupabaseSyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseSyncService(this._db);

  String _formatDateYmdFromMillis(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  int _parseBookTimeMillis(dynamic value) {
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

  /// 同步本地数据到云端 (Push)
  Future<void> syncToCloud({required void Function(String) onProgress}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('用户未登录，无法同步');
    }

    // 1. 同步账簿
    onProgress('正在同步账簿...');
    final books = await _db.select(_db.accountBooks).get();
    if (books.isNotEmpty) {
      final booksData = books
          .map(
            (b) => {
              'book_id': b.bookId,
              'name': b.name,
              'reason_type': b.reasonType,
              'theme_color': b.themeColor,
              'icon': b.icon,
              'description': b.description,
              'book_time': _formatDateYmdFromMillis(b.bookTime),
              'is_default': b.isDefault,
              'created_at': b.createdAt,
              'updated_at': b.updatedAt,
              'deleted_at': b.deletedAt,
              'user_id': user.id,
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
              'avatar_uri': p.avatarUri,
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
              'reminder_id': r.reminderId,
              'direction': r.direction,
              'amount_cent': r.amountCent,
              'currency': r.currency,
              'event_name': r.eventName,
              'occurred_at': r.occurredAt,
              'payment_method': r.paymentMethod,
              'note': r.note,
              'attachments': r.attachments,
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
              'description': r.description,
              'enabled': r.enabled,
              'created_at': r.createdAt,
              'updated_at': r.updatedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase.from('reason').upsert(reasonsData);
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
              'created_at': rt.createdAt,
              'updated_at': rt.updatedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase.from('relation_type').upsert(relationTypesData);
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

    // 7. 同步提醒类型
    onProgress('正在同步提醒类型...');
    final reminderTypes = await _db.select(_db.reminderTypes).get();
    if (reminderTypes.isNotEmpty) {
      final reminderTypesData = reminderTypes
          .map(
            (rt) => {
              'type_id': rt.typeId,
              'book_id': rt.bookId,
              'name': rt.name,
              'is_custom': rt.isCustom,
              'created_at': rt.createdAt,
              'updated_at': rt.updatedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase.from('reminder_type').upsert(reminderTypesData);
    }

    // 8. 同步事件提醒
    onProgress('正在同步事件提醒...');
    final eventReminders = await _db.select(_db.eventReminders).get();
    if (eventReminders.isNotEmpty) {
      final eventRemindersData = eventReminders
          .map(
            (er) => {
              'reminder_id': er.reminderId,
              'book_id': er.bookId,
              'person_id': er.personId,
              'relation_person_ids': er.relationPersonIds,
              'reminder_type': er.reminderType,
              'title': er.title,
              'target_date': er.targetDate,
              'remind_at': er.remindAt,
              'repeat_rule': er.repeatRule,
              'status': er.status,
              'channel': er.channel,
              'note': er.note,
              'created_at': er.createdAt,
              'updated_at': er.updatedAt,
              'user_id': user.id,
            },
          )
          .toList();
      await _supabase.from('event_reminder').upsert(eventRemindersData);
    }

    // 9. 同步附件媒体
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
    final booksData = await _supabase
        .from('account_book')
        .select()
        .eq('user_id', user.id);
    if (booksData.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.accountBooks,
          booksData.map(
            (b) => AccountBook(
              bookId: b['book_id'] as String,
              name: b['name'] as String,
              reasonType: b['reason_type'] as String,
              themeColor: b['theme_color'] as String,
              icon: b['icon'] as String?,
              description: b['description'] as String?,
              bookTime: _parseBookTimeMillis(b['book_time']),
              isDefault: b['is_default'] as int,
              createdAt: b['created_at'] as int,
              updatedAt: b['updated_at'] as int,
              deletedAt: b['deleted_at'] as int?,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // 2. 恢复关系人
    onProgress('正在拉取关系人...');
    final personsData = await _supabase
        .from('person')
        .select()
        .eq('user_id', user.id);
    if (personsData.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.persons,
          personsData.map(
            (p) => Person(
              personId: p['person_id'] as String,
              bookId: p['book_id'] as String,
              name: p['name'] as String,
              relationshipType: p['relationship_type'] as String,
              phone: p['phone'] as String?,
              birthday: p['birthday'] as String?,
              anniversary: p['anniversary'] as String?,
              avatarUri: p['avatar_uri'] as String?,
              note: p['note'] as String?,
              createdAt: p['created_at'] as int,
              updatedAt: p['updated_at'] as int,
              deletedAt: p['deleted_at'] as int?,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // 3. 恢复礼金记录
    onProgress('正在拉取礼金记录...');
    final recordsData = await _supabase
        .from('gift_record')
        .select()
        .eq('user_id', user.id);
    if (recordsData.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.giftRecords,
          recordsData.map(
            (r) => GiftRecord(
              recordId: r['record_id'] as String,
              bookId: r['book_id'] as String,
              personId: r['person_id'] as String,
              reminderId: r['reminder_id'] as String?,
              direction: r['direction'] as String,
              amountCent: r['amount_cent'] as int,
              currency: r['currency'] as String,
              eventName: r['event_name'] as String?,
              occurredAt: r['occurred_at'] as int,
              paymentMethod: r['payment_method'] as String?,
              note: r['note'] as String?,
              attachments: r['attachments'] != null
                  ? List<String>.from(r['attachments'])
                  : null,
              createdAt: r['created_at'] as int,
              updatedAt: r['updated_at'] as int,
              deletedAt: r['deleted_at'] as int?,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // 4. 恢复事由
    onProgress('正在拉取事由...');
    final reasonsData = await _supabase
        .from('reason')
        .select()
        .eq('user_id', user.id);
    if (reasonsData.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.reasons,
          reasonsData.map(
            (r) => Reason(
              reasonId: r['reason_id'] as String,
              name: r['name'] as String,
              description: r['description'] as String?,
              enabled: r['enabled'] as bool,
              createdAt: r['created_at'] as int,
              updatedAt: r['updated_at'] as int,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // 5. 恢复关系类型
    onProgress('正在拉取关系类型...');
    final relationTypesData = await _supabase
        .from('relation_type')
        .select()
        .eq('user_id', user.id);
    if (relationTypesData.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.relationTypes,
          relationTypesData.map(
            (rt) => RelationType(
              typeId: rt['type_id'] as String,
              name: rt['name'] as String,
              createdAt: rt['created_at'] as int,
              updatedAt: rt['updated_at'] as int,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // 6. 恢复联系人关系
    onProgress('正在拉取联系人关系...');
    final contactRelationsData = await _supabase
        .from('contact_relation')
        .select()
        .eq('user_id', user.id);
    if (contactRelationsData.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.contactRelations,
          contactRelationsData.map(
            (cr) => ContactRelation(
              relationId: cr['relation_id'] as String,
              personAId: cr['person_a_id'] as String,
              personBId: cr['person_b_id'] as String,
              typeId: cr['type_id'] as String,
              note: cr['note'] as String?,
              createdAt: cr['created_at'] as int,
              updatedAt: cr['updated_at'] as int,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // 7. 恢复提醒类型
    onProgress('正在拉取提醒类型...');
    final reminderTypesData = await _supabase
        .from('reminder_type')
        .select()
        .eq('user_id', user.id);
    if (reminderTypesData.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.reminderTypes,
          reminderTypesData.map(
            (rt) => ReminderType(
              typeId: rt['type_id'] as String,
              bookId: rt['book_id'] as String,
              name: rt['name'] as String,
              isCustom: rt['is_custom'] as bool,
              createdAt: rt['created_at'] as int,
              updatedAt: rt['updated_at'] as int,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // 8. 恢复事件提醒
    onProgress('正在拉取事件提醒...');
    final eventRemindersData = await _supabase
        .from('event_reminder')
        .select()
        .eq('user_id', user.id);
    if (eventRemindersData.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.eventReminders,
          eventRemindersData.map(
            (er) => EventReminder(
              reminderId: er['reminder_id'] as String,
              bookId: er['book_id'] as String,
              personId: er['person_id'] as String?,
              relationPersonIds: er['relation_person_ids'] as String,
              reminderType: er['reminder_type'] as String,
              title: er['title'] as String,
              targetDate: er['target_date'] as String,
              remindAt: er['remind_at'] as int,
              repeatRule: er['repeat_rule'] as String,
              status: er['status'] as String,
              channel: er['channel'] as String,
              note: er['note'] as String?,
              createdAt: er['created_at'] as int,
              updatedAt: er['updated_at'] as int,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // 9. 恢复附件媒体
    onProgress('正在拉取附件媒体...');
    await _syncMediaFromCloud(user.id, onProgress);

    onProgress('本地数据恢复完成！');
  }

  /// 同步本地媒体文件到云端
  Future<void> _syncMediaToCloud(
    String userId,
    void Function(String) onProgress,
  ) async {
    final docs = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docs.path, 'media'));
    if (!await mediaDir.exists()) return;

    final entities = await mediaDir
        .list(recursive: true, followLinks: false)
        .toList();
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
        } catch (e) {
          onProgress('上传附件失败: $relative ($e)');
        }
      }
    }
  }

  /// 从云端拉取媒体文件到本地
  Future<void> _syncMediaFromCloud(
    String userId,
    void Function(String) onProgress,
  ) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(docs.path, 'media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final candidates = <String>[
        userId,
        '$userId/avatars',
        '$userId/attachments',
      ];
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
          } catch (e) {
            onProgress(
              '下载附件失败: ${relativePrefix.isEmpty ? file.name : '$relativePrefix/${file.name}'} ($e)',
            );
          }
        }
      }
    } catch (e) {
      onProgress('获取云端附件列表失败 ($e)');
    }
  }
}
