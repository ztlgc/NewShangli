import 'package:drift/drift.dart';

import '../data/local/drift/app_database.dart';

class DefaultBookService {
  Future<String> ensureDefaultBookId(AppDatabase db) async {
    final existingDefault = await db.accountBooksDao.findDefault();
    if (existingDefault != null) {
      if (existingDefault.bookTime <= 0) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final repairedBookTime = existingDefault.createdAt > 0 ? existingDefault.createdAt : now;
        await db.accountBooksDao.updateOne(
          existingDefault.copyWith(
            bookTime: repairedBookTime,
          ),
        );
      }
      return existingDefault.bookId;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = db.newId();
    await db
        .into(db.accountBooks)
        .insert(
          AccountBooksCompanion.insert(
            bookId: Value(id),
            name: '默认账簿',
            reasonType: const Value(''),
            themeColor: const Value('#312E81'),
            icon: const Value.absent(),
            description: const Value.absent(),
            bookTime: Value(now),
            isDefault: const Value(1),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }
}
