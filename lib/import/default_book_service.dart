import 'package:drift/drift.dart';

import '../data/local/drift/app_database.dart';

class DefaultBookService {
  Future<String> ensureDefaultBookId(AppDatabase db) async {
    final existingDefault = await db.accountBooksDao.findDefault();
    if (existingDefault != null) return existingDefault.bookId;

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = db.newId();
    await db.into(db.accountBooks).insert(
      AccountBooksCompanion.insert(
        bookId: Value(id),
        name: '默认账簿',
        reasonType: const Value(''),
        themeColor: const Value('#312E81'),
        icon: const Value.absent(),
        description: const Value.absent(),
        isDefault: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }
}
