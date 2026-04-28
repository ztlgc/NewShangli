import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newshangli/backup/supabase_sync_service.dart';
import 'package:newshangli/data/local/drift/app_database.dart';

void main() {
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

    test('same reason and same contact relation use cloud version', () async {
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
            'name': 'Wedding',
            'description': 'cloud reason',
            'enabled': true,
            'created_at': now,
            'updated_at': now,
          },
        ],
        relationTypesData: [
          {
            'type_id': cloudTypeId,
            'name': 'Friend',
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
      expect(reasons.where((reason) => reason.name == 'Wedding'), hasLength(1));
      final reason = reasons.singleWhere((reason) => reason.name == 'Wedding');
      expect(reason.reasonId, 'cloud_reason');
      expect(reason.description, 'cloud reason');
      expect(reason.enabled, isTrue);

      final relationTypes = await db.relationTypesDao.listAll();
      expect(
        relationTypes.where((type) => type.name == 'Friend'),
        hasLength(1),
      );

      final relations = await db.select(db.contactRelations).get();
      expect(relations, hasLength(1));
      expect(relations.single.relationId, 'cloud_relation');
      expect(relations.single.personAId, p1);
      expect(relations.single.personBId, p2);
      expect(relations.single.note, 'cloud relation');
    });
  });
}
