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
}
