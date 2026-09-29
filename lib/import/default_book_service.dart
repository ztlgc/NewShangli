import 'package:drift/drift.dart';

import '../data/local/drift/app_database.dart';

class DefaultBookService {
  Future<String> ensureDefaultBookId(AppDatabase db) async {
    final books =
        await (db.select(db.accountBooks)..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.bookId),
            ]))
            .get();

    if (books.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '默认账簿',
          reasonType: const Value(''),
          themeColor: const Value('#312E81'),
          icon: const Value.absent(),
          description: const Value.absent(),
          bookTime: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final defaults = books.where((b) => b.isDefault == 1).toList();
    final keeper = defaults.isEmpty ? books.first : defaults.first;
    final isValidSingleDefault =
        defaults.length == 1 && defaults.first.bookId == keeper.bookId;
    if (isValidSingleDefault) {
      return keeper.bookId;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction(() async {
      await (db.update(db.accountBooks)).write(
        AccountBooksCompanion(isDefault: const Value(0), updatedAt: Value(now)),
      );
      await (db.update(
        db.accountBooks,
      )..where((t) => t.bookId.equals(keeper.bookId))).write(
        AccountBooksCompanion(isDefault: const Value(1), updatedAt: Value(now)),
      );
    });
    return keeper.bookId;
  }
}
