import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newshangli/backup/supabase_sync_service.dart';
import 'package:newshangli/data/local/drift/app_database.dart';

void main() {
  group('SupabaseSyncService cloud payload rules', () {
    test('account book cloud row keeps book_time as millisecond integer', () {
      final now = DateTime(2026, 4, 25, 12, 30).millisecondsSinceEpoch;
      final row = SupabaseSyncService.accountBookToCloudRow(
        AccountBook(
          bookId: 'book_1',
          name: '测试账簿',
          reasonType: '',
          themeColor: '#312E81',
          icon: null,
          description: null,
          attachments: const <String>['a.png'],
          bookTime: now,
          isDefault: 1,
          createdAt: now - 1000,
          updatedAt: now,
          deletedAt: null,
        ),
        'user_1',
      );

      expect(row['book_time'], now);
      expect(row['book_time'], isA<int>());
      expect(row['user_id'], 'user_1');
    });

    test('normalize media path for cloud converts absolute local path', () {
      final mediaRoot = r'C:\app\data\media';
      final absolute = r'C:\app\data\media\attachments\att_1.jpg';

      final value = SupabaseSyncService.normalizeMediaPathForCloud(
        absolute,
        mediaRootPath: mediaRoot,
      );

      expect(value, 'attachments/att_1.jpg');
    });

    test(
      'materialize cloud media path supports portable and legacy values',
      () {
        final mediaRoot = r'C:\restore\data\media';

        final portable = SupabaseSyncService.materializeCloudMediaPath(
          'attachments/att_1.jpg',
          mediaRootPath: mediaRoot,
        );
        final legacyAbsolute = SupabaseSyncService.materializeCloudMediaPath(
          r'D:\old\device\media\avatars\avatar_1.png',
          mediaRootPath: mediaRoot,
        );

        expect(portable, r'C:\restore\data\media\attachments\att_1.jpg');
        expect(legacyAbsolute, r'C:\restore\data\media\avatars\avatar_1.png');
      },
    );

    test('cloud restore backfills normalized_name for legacy rows', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
      });

      final now = DateTime(2026, 4, 25, 12, 30).millisecondsSinceEpoch;

      await SupabaseSyncService.restoreTablesForTesting(
        db: db,
        booksData: const [],
        reasonsData: [
          {
            'reason_id': 'cloud_reason',
            'name': 'Wedding',
            'description': 'cloud',
            'enabled': true,
            'created_at': now - 1000,
            'updated_at': now,
          },
        ],
        relationTypesData: [
          {
            'type_id': 'cloud_type',
            'name': 'Friend',
            'created_at': now - 1000,
            'updated_at': now,
          },
        ],
      );

      final reason = await db.reasonsDao.findById('cloud_reason');
      final relationType = await db.relationTypesDao.findById('cloud_type');

      expect(reason, isNotNull);
      expect(reason!.normalizedName, 'wedding');
      expect(relationType, isNotNull);
      expect(relationType!.normalizedName, 'friend');
    });
  });

  group('SupabaseSyncService cloud restore merge rules', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('cloud default book name overwrites local default book', () async {
      const localDefaultId = 'local_default_book';
      const cloudDefaultId = 'cloud_default_book';
      const personId = 'person_1';
      const recordId = 'record_1';
      final now = DateTime(2026, 4, 25).millisecondsSinceEpoch;

      await db
          .into(db.accountBooks)
          .insert(
            AccountBooksCompanion.insert(
              bookId: const Value(localDefaultId),
              name: 'Local Default',
              bookTime: Value(now - 2000),
              isDefault: const Value(1),
              createdAt: now - 2000,
              updatedAt: now - 2000,
            ),
          );

      await SupabaseSyncService.restoreTablesForTesting(
        db: db,
        booksData: [
          {
            'book_id': cloudDefaultId,
            'name': 'Cloud Default',
            'reason_type': '',
            'theme_color': '#22C55E',
            'icon': 'cloud',
            'description': 'from cloud',
            'book_time': now,
            'is_default': 1,
            'created_at': now - 1000,
            'updated_at': now,
            'deleted_at': null,
          },
        ],
        personsData: [
          {
            'person_id': personId,
            'book_id': cloudDefaultId,
            'name': 'Alice',
            'relationship_type': 'Friend',
            'phone': null,
            'birthday': null,
            'anniversary': null,
            'avatar_uri': null,
            'note': null,
            'created_at': now,
            'updated_at': now,
            'deleted_at': null,
          },
        ],
        recordsData: [
          {
            'record_id': recordId,
            'book_id': cloudDefaultId,
            'person_id': personId,
            'direction': '收入',
            'amount_cent': 10000,
            'currency': 'CNY',
            'event_name': 'Wedding',
            'occurred_at': now,
            'payment_method': null,
            'note': null,
            'attachments': null,
            'created_at': now,
            'updated_at': now,
            'deleted_at': null,
          },
        ],
      );

      final books = await db.select(db.accountBooks).get();
      expect(books, hasLength(1));
      expect(books.single.bookId, localDefaultId);
      expect(books.single.name, 'Cloud Default');
      expect(books.single.themeColor, '#22C55E');
      expect(books.single.isDefault, 1);

      final person = await db.personsDao.findById(personId);
      expect(person, isNotNull);
      expect(person!.bookId, localDefaultId);

      final record = await db.giftRecordsDao.findById(recordId);
      expect(record, isNotNull);
      expect(record!.bookId, localDefaultId);
    });

    test(
      'same reason and same contact relation use cloud version case-insensitively',
      () async {
        const bookId = 'book_1';
        const p1 = 'person_1';
        const p2 = 'person_2';
        const localTypeId = 'local_type';
        const cloudTypeId = 'cloud_type';
        final now = DateTime(2026, 4, 25).millisecondsSinceEpoch;

        await db
            .into(db.accountBooks)
            .insert(
              AccountBooksCompanion.insert(
                bookId: const Value(bookId),
                name: 'Book',
                isDefault: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: const Value(p1),
                bookId: bookId,
                name: 'Alice',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: const Value(p2),
                bookId: bookId,
                name: 'Bob',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.reasons)
            .insert(
              ReasonsCompanion.insert(
                reasonId: 'local_reason',
                name: 'Wedding',
                normalizedName: 'wedding',
                description: const Value('local reason'),
                enabled: const Value(false),
                createdAt: now - 2000,
                updatedAt: now - 2000,
              ),
            );
        await db
            .into(db.relationTypes)
            .insert(
              RelationTypesCompanion.insert(
                typeId: localTypeId,
                name: 'Friend',
                normalizedName: 'friend',
                createdAt: now - 2000,
                updatedAt: now - 2000,
              ),
            );
        await db
            .into(db.contactRelations)
            .insert(
              ContactRelationsCompanion.insert(
                relationId: 'local_relation',
                personAId: p1,
                personBId: p2,
                typeId: localTypeId,
                note: const Value('local relation'),
                createdAt: now - 2000,
                updatedAt: now - 2000,
              ),
            );

        await SupabaseSyncService.restoreTablesForTesting(
          db: db,
          booksData: [
            {
              'book_id': bookId,
              'name': 'Book',
              'reason_type': '',
              'theme_color': '#312E81',
              'icon': null,
              'description': null,
              'book_time': now,
              'is_default': 1,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          reasonsData: [
            {
              'reason_id': 'cloud_reason',
              'name': 'wedding',
              'description': 'cloud reason',
              'enabled': true,
              'created_at': now,
              'updated_at': now,
            },
          ],
          relationTypesData: [
            {
              'type_id': cloudTypeId,
              'name': 'friend',
              'created_at': now,
              'updated_at': now,
            },
          ],
          contactRelationsData: [
            {
              'relation_id': 'cloud_relation',
              'person_a_id': p2,
              'person_b_id': p1,
              'type_id': cloudTypeId,
              'note': 'cloud relation',
              'created_at': now,
              'updated_at': now,
            },
          ],
        );

        final reasons = await db.reasonsDao.listAll();
        expect(reasons, hasLength(1));
        final reason = reasons.single;
        expect(reason.reasonId, 'cloud_reason');
        expect(reason.name, 'wedding');
        expect(reason.normalizedName, 'wedding');
        expect(reason.description, 'cloud reason');
        expect(reason.enabled, isTrue);

        final relationTypes = await db.relationTypesDao.listAll();
        expect(relationTypes, hasLength(1));
        expect(relationTypes.single.typeId, cloudTypeId);
        expect(relationTypes.single.name, 'friend');
        expect(relationTypes.single.normalizedName, 'friend');

        final relations = await db.select(db.contactRelations).get();
        expect(relations, hasLength(1));
        expect(relations.single.relationId, 'cloud_relation');
        expect(relations.single.personAId, p1);
        expect(relations.single.personBId, p2);
        expect(relations.single.typeId, cloudTypeId);
        expect(relations.single.note, 'cloud relation');
      },
    );

    test(
      'different book IDs remain distinct even with the same name',
      () async {
        const localDefaultId = 'local_default';
        const localTripId = 'local_trip';
        const cloudDefaultId = 'cloud_default';
        const cloudTripId = 'cloud_trip';
        const personId = 'person_trip';
        const recordId = 'record_trip';
        final now = DateTime(2026, 4, 26).millisecondsSinceEpoch;

        await db
            .into(db.accountBooks)
            .insert(
              AccountBooksCompanion.insert(
                bookId: const Value(localDefaultId),
                name: '默认账簿',
                isDefault: const Value(1),
                createdAt: now - 3000,
                updatedAt: now - 3000,
              ),
            );
        await db
            .into(db.accountBooks)
            .insert(
              AccountBooksCompanion.insert(
                bookId: const Value(localTripId),
                name: '旅行',
                isDefault: const Value(0),
                createdAt: now - 2000,
                updatedAt: now - 2000,
              ),
            );

        await SupabaseSyncService.restoreTablesForTesting(
          db: db,
          booksData: [
            {
              'book_id': cloudDefaultId,
              'name': '默认账簿',
              'reason_type': '',
              'theme_color': '#312E81',
              'icon': null,
              'description': null,
              'book_time': now,
              'is_default': 1,
              'created_at': now - 1000,
              'updated_at': now,
              'deleted_at': null,
            },
            {
              'book_id': cloudTripId,
              'name': '旅行',
              'reason_type': '',
              'theme_color': '#22C55E',
              'icon': null,
              'description': null,
              'book_time': now,
              'is_default': 0,
              'created_at': now - 1000,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          personsData: [
            {
              'person_id': personId,
              'book_id': cloudTripId,
              'name': '张三',
              'relationship_type': '朋友',
              'phone': null,
              'birthday': null,
              'anniversary': null,
              'avatar_uri': null,
              'note': null,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          recordsData: [
            {
              'record_id': recordId,
              'book_id': cloudTripId,
              'person_id': personId,
              'direction': '支出',
              'amount_cent': 5000,
              'currency': 'CNY',
              'event_name': '旅游',
              'occurred_at': now,
              'payment_method': null,
              'note': null,
              'attachments': null,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
        );

        final books = await db.select(db.accountBooks).get();
        expect(books, hasLength(3));
        expect(books.map((b) => b.bookId).toSet(), <String>{
          localDefaultId,
          localTripId,
          cloudTripId,
        });
        expect(books.where((b) => b.bookId == localTripId).single.name, '旅行');
        expect(
          books.where((b) => b.bookId == cloudTripId).single.themeColor,
          '#22C55E',
        );
        expect(books.where((b) => b.isDefault == 1), hasLength(1));

        final person = await db.personsDao.findById(personId);
        expect(person, isNotNull);
        expect(person!.bookId, cloudTripId);

        final record = await db.giftRecordsDao.findById(recordId);
        expect(record, isNotNull);
        expect(record!.bookId, cloudTripId);
      },
    );

    test(
      'distinct IDs preserve same-name persons and similar records',
      () async {
        const localBookId = 'local_book';
        const localPersonId = 'local_person';
        const localRecordId = 'local_record';
        const cloudBookId = 'cloud_book';
        const cloudPersonId = 'cloud_person';
        const cloudRecordId = 'cloud_record';
        const cloudNewRecordId = 'cloud_new_record';
        final now = DateTime(2026, 4, 27).millisecondsSinceEpoch;

        await db
            .into(db.accountBooks)
            .insert(
              AccountBooksCompanion.insert(
                bookId: const Value(localBookId),
                name: '默认账簿',
                isDefault: const Value(1),
                createdAt: now - 3000,
                updatedAt: now - 3000,
              ),
            );
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: const Value(localPersonId),
                bookId: localBookId,
                name: 'Alice',
                phone: const Value('13800000000'),
                createdAt: now - 3000,
                updatedAt: now - 3000,
              ),
            );
        await db
            .into(db.giftRecords)
            .insert(
              GiftRecordsCompanion.insert(
                recordId: const Value(localRecordId),
                bookId: localBookId,
                personId: localPersonId,
                direction: const Value('收入'),
                amountCent: 10000,
                eventName: const Value('婚礼'),
                occurredAt: now - 1000,
                paymentMethod: const Value('微信'),
                createdAt: now - 3000,
                updatedAt: now - 3000,
              ),
            );

        await SupabaseSyncService.restoreTablesForTesting(
          db: db,
          booksData: [
            {
              'book_id': cloudBookId,
              'name': '默认账簿',
              'reason_type': '',
              'theme_color': '#312E81',
              'icon': null,
              'description': null,
              'book_time': now,
              'is_default': 1,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          personsData: [
            {
              'person_id': cloudPersonId,
              'book_id': cloudBookId,
              'name': 'Alice',
              'relationship_type': '朋友',
              'phone': '13800000000',
              'birthday': null,
              'anniversary': null,
              'avatar_uri': null,
              'note': null,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          recordsData: [
            {
              'record_id': cloudRecordId,
              'book_id': cloudBookId,
              'person_id': cloudPersonId,
              'direction': '收入',
              'amount_cent': 10000,
              'currency': 'CNY',
              'event_name': '婚礼',
              'occurred_at': now - 1000,
              'payment_method': '微信',
              'note': null,
              'attachments': null,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
            {
              'record_id': cloudNewRecordId,
              'book_id': cloudBookId,
              'person_id': cloudPersonId,
              'direction': '支出',
              'amount_cent': 2000,
              'currency': 'CNY',
              'event_name': '回礼',
              'occurred_at': now,
              'payment_method': '现金',
              'note': null,
              'attachments': null,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
        );

        final persons = await db.select(db.persons).get();
        expect(persons.map((p) => p.personId).toSet(), {
          localPersonId,
          cloudPersonId,
        });

        final records = await db.select(db.giftRecords).get();
        expect(records, hasLength(3));
        expect(records.map((r) => r.recordId).toSet(), <String>{
          localRecordId,
          cloudRecordId,
          cloudNewRecordId,
        });
        final newRecord = records
            .where((r) => r.recordId == cloudNewRecordId)
            .single;
        expect(newRecord.bookId, localBookId);
        expect(newRecord.personId, cloudPersonId);
      },
    );

    test(
      'global contacts preserve distinct IDs across books with matching names and phones',
      () async {
        const localBookId = 'local_default';
        const cloudBookId = 'cloud_trip';
        const localPersonId = 'local_person';
        const cloudPersonId = 'cloud_person';
        const cloudRecordId = 'cloud_record';
        final now = DateTime(2026, 4, 28).millisecondsSinceEpoch;

        await db
            .into(db.accountBooks)
            .insert(
              AccountBooksCompanion.insert(
                bookId: const Value(localBookId),
                name: '默认账簿',
                isDefault: const Value(1),
                createdAt: now - 3000,
                updatedAt: now - 3000,
              ),
            );
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: const Value(localPersonId),
                bookId: localBookId,
                name: 'Alice',
                phone: const Value('13800000000'),
                createdAt: now - 3000,
                updatedAt: now - 3000,
              ),
            );

        await SupabaseSyncService.restoreTablesForTesting(
          db: db,
          booksData: [
            {
              'book_id': cloudBookId,
              'name': '旅行',
              'reason_type': '',
              'theme_color': '#22C55E',
              'icon': null,
              'description': null,
              'book_time': now,
              'is_default': 0,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          personsData: [
            {
              'person_id': cloudPersonId,
              'book_id': cloudBookId,
              'name': 'Alice',
              'relationship_type': '朋友',
              'phone': '13800000000',
              'birthday': null,
              'anniversary': null,
              'avatar_uri': null,
              'note': null,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          recordsData: [
            {
              'record_id': cloudRecordId,
              'book_id': cloudBookId,
              'person_id': cloudPersonId,
              'direction': '收入',
              'amount_cent': 6666,
              'currency': 'CNY',
              'event_name': '乔迁',
              'occurred_at': now,
              'payment_method': '微信',
              'note': null,
              'attachments': null,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
        );

        final persons = await db.select(db.persons).get();
        expect(persons.map((p) => p.personId).toSet(), {
          localPersonId,
          cloudPersonId,
        });

        final record = await db.giftRecordsDao.findById(cloudRecordId);
        expect(record, isNotNull);
        expect(record!.bookId, cloudBookId);
        expect(record.personId, cloudPersonId);
      },
    );
  });
}
