import 'package:drift/drift.dart';

import '../data/local/drift/app_database.dart';

class DefaultBookService {
  /// 确保存在且唯一的默认账簿，返回其 bookId。
  ///
  /// - 不存在默认账簿时创建系统默认账簿，不再把任意普通账簿提升为默认。
  /// - 检查与写入在同一事务内完成，避免并发调用在空库上创建多个默认账簿。
  /// - 若历史数据存在多个默认账簿，保留 createdAt 最早的一个并取消其余的默认标记。
  Future<String> ensureDefaultBookId(AppDatabase db) {
    return db.transaction(() async {
      final defaults =
          await (db.select(db.accountBooks)
                ..where((t) => t.isDefault.equals(1))
                ..orderBy([
                  (t) => OrderingTerm.asc(t.createdAt),
                  (t) => OrderingTerm.asc(t.bookId),
                ]))
              .get();

      if (defaults.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final bookId = db.newId();
        await db
            .into(db.accountBooks)
            .insert(
              AccountBooksCompanion.insert(
                bookId: Value(bookId),
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
        return bookId;
      }

      final keeper = defaults.first;
      if (defaults.length == 1) {
        return keeper.bookId;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await (db.update(
        db.accountBooks,
      )..where((t) => t.bookId.isIn(defaults.skip(1).map((b) => b.bookId))))
          .write(AccountBooksCompanion(isDefault: const Value(0), updatedAt: Value(now)));
      return keeper.bookId;
    });
  }
}
