import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:newshangli/data/local/drift/app_database.dart';

/// Deterministic sample ledger for the approved statistics design. This uses an
/// isolated in-memory database and the production aggregation path.
Future<AppDatabase> createStatsPreviewDatabase() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final timestamp = DateTime(2026, 10, 1).millisecondsSinceEpoch;
  const people = ['张伟', '李娜', '王芳', '陈明', '刘洋', '赵强', '周敏', '孙婷', '吴磊'];
  await db.transaction(() async {
    for (var index = 0; index < 2; index++) {
      await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          bookId: Value('stats_book_$index'),
          name: index == 0 ? '日常礼账' : '家庭礼账',
          isDefault: Value(index == 0 ? 1 : 0),
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
    for (final (index, name) in people.indexed) {
      await db.personsDao.insertOne(
        PersonsCompanion.insert(
          personId: Value('stats_person_$index'),
          bookId: 'stats_book_${index % 2}',
          name: name,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
    const income = [
      (0, 1, 1800),
      (0, 6, 1200),
      (1, 6, 800),
      (1, 12, 1200),
      (2, 3, 1000),
      (2, 16, 1000),
      (3, 23, 1600),
      (4, 19, 1000),
      (5, 8, 500),
      (6, 12, 300),
      (6, 23, 200),
      (7, 26, 1100),
      (8, 26, 1100),
    ];
    const expense = [
      (0, 1, 1000, '婚礼'),
      (0, 18, 800, '生日'),
      (1, 2, 800, '婚礼'),
      (1, 7, 600, '生日'),
      (1, 5, 200, '婚礼'),
      (2, 5, 1000, '婚礼'),
      (3, 12, 800, '乔迁'),
      (4, 16, 500, '生日'),
      (4, 12, 200, '乔迁'),
      (4, 25, 100, '其他'),
      (5, 23, 800, '婚礼'),
      (6, 23, 400, '婚礼'),
      (6, 25, 400, '其他'),
      (7, 25, 100, '生日'),
      (7, 25, 400, '乔迁'),
      (8, 25, 200, '乔迁'),
      (8, 25, 300, '其他'),
    ];
    for (final (person, day, amount) in income) {
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: 'stats_book_${person % 2}',
          personId: 'stats_person_$person',
          amountCent: amount * 100,
          direction: const Value('收入'),
          eventName: const Value('婚礼'),
          occurredAt: DateTime(2026, 10, day).millisecondsSinceEpoch,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
    for (final (person, day, amount, event) in expense) {
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: 'stats_book_${person % 2}',
          personId: 'stats_person_$person',
          amountCent: amount * 100,
          direction: const Value('支出'),
          eventName: Value(event),
          occurredAt: DateTime(2026, 10, day).millisecondsSinceEpoch,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
    for (final (direction, amount) in [('收入', 1080000), ('支出', 979500)]) {
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: 'stats_book_1',
          personId: 'stats_person_8',
          amountCent: amount,
          direction: Value(direction),
          eventName: const Value('生日'),
          occurredAt: DateTime(2026, 9, 5).millisecondsSinceEpoch,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
  });
  return db;
}
