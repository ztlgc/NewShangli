import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';

void main() {
  test(
    'deleting a person moves related active records to recycle bin',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async => db.close());

      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: 'Cascade delete book',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final personId = await db.personsDao.insertOne(
        PersonsCompanion.insert(
          bookId: bookId,
          name: 'Cascade Person',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final recordId = await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: bookId,
          personId: personId,
          direction: const Value('\u6536\u5165'),
          amountCent: 1200,
          currency: const Value('CNY'),
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.personsDao.deleteById(personId);

      expect(await db.personsDao.findById(personId), isNull);
      expect(await db.giftRecordsDao.findById(recordId), isNull);
      expect((await db.personsDao.findByIdAny(personId))?.deletedAt, isNotNull);
      expect(
        (await db.giftRecordsDao.findByIdAny(recordId))?.deletedAt,
        isNotNull,
      );
    },
  );

  test('restoring a deleted record also restores its deleted person', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    final now = DateTime.now().millisecondsSinceEpoch;
    final bookId = await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        name: 'Cascade restore book',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final personId = await db.personsDao.insertOne(
      PersonsCompanion.insert(
        bookId: bookId,
        name: 'Restore Person',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final restoredRecordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: bookId,
        personId: personId,
        direction: const Value('\u6536\u5165'),
        amountCent: 1200,
        currency: const Value('CNY'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final stillDeletedRecordId = await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: bookId,
        personId: personId,
        direction: const Value('\u652f\u51fa'),
        amountCent: 800,
        currency: const Value('CNY'),
        occurredAt: now + 1,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await db.personsDao.deleteById(personId);
    await db.giftRecordsDao.restoreById(restoredRecordId);

    expect(await db.personsDao.findById(personId), isNotNull);
    expect(await db.giftRecordsDao.findById(restoredRecordId), isNotNull);
    expect(await db.giftRecordsDao.findById(stillDeletedRecordId), isNull);
    expect(
      (await db.giftRecordsDao.findByIdAny(stillDeletedRecordId))?.deletedAt,
      isNotNull,
    );
  });
}
