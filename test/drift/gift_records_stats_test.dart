import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';

void main() {
  test('watchStats 返回收入与记录数', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    final now = DateTime.now().millisecondsSinceEpoch;
    const bookId = 'b1';
    const personId = 'p1';

    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value(bookId),
        name: '测试账簿',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value(personId),
        bookId: bookId,
        name: '张三',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: bookId,
        personId: personId,
        amountCent: 1200,
        direction: const Value('收入'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: bookId,
        personId: personId,
        amountCent: 500,
        direction: const Value('支出'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final stats = await db.giftRecordsDao.watchStats(bookId).first;
    expect(stats['income'], 1200);
    expect(stats['expense'], 500);
    expect(stats['count'], 2);
  });

  test('默认账簿范围仅包含默认账簿收支与其他账簿支出', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    final now = DateTime.now().millisecondsSinceEpoch;
    const defaultBookId = 'default_book';
    const otherBookId = 'other_book';
    const defaultPersonId = 'p_default';
    const otherPersonId = 'p_other';

    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value(defaultBookId),
        name: '默认账簿',
        isDefault: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value(otherBookId),
        name: '婚礼账簿',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value(defaultPersonId),
        bookId: defaultBookId,
        name: '默认联系人',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value(otherPersonId),
        bookId: otherBookId,
        name: '其他联系人',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        recordId: const Value('r_default_income'),
        bookId: defaultBookId,
        personId: defaultPersonId,
        amountCent: 1000,
        direction: const Value('收入'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        recordId: const Value('r_other_income'),
        bookId: otherBookId,
        personId: otherPersonId,
        amountCent: 2000,
        direction: const Value('收入'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        recordId: const Value('r_other_expense'),
        bookId: otherBookId,
        personId: otherPersonId,
        amountCent: 300,
        direction: const Value('支出'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final rows = await db.giftRecordsDao
        .listAllWithPersonInDefaultScope(defaultBookId);
    final count = await db.giftRecordsDao
        .watchCountInDefaultScope(defaultBookId)
        .first;

    expect(rows.map((e) => e.record.recordId), contains('r_default_income'));
    expect(rows.map((e) => e.record.recordId), contains('r_other_expense'));
    expect(rows.map((e) => e.record.recordId), isNot(contains('r_other_income')));
    expect(count, 2);
  });
}
