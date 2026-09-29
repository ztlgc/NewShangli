part of '../app_database.dart';

/// 账簿 DAO：提供 book 维度的数据访问能力。
@DriftAccessor(tables: [AccountBooks])
class AccountBooksDao extends DatabaseAccessor<AppDatabase>
    with _$AccountBooksDaoMixin {
  AccountBooksDao(super.db);

  /// 监听单个账簿变化。
  Stream<AccountBook> watchBook(String bookId) {
    return (select(
      accountBooks,
    )..where((t) => t.bookId.equals(bookId))).watchSingle();
  }

  /// 查询所有账簿（按创建时间倒序）。
  Stream<List<AccountBook>> watchAll() {
    return (select(
      accountBooks,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// 根据 bookId 查询单个账簿。
  Future<AccountBook?> findById(String bookId) {
    return (select(
      accountBooks,
    )..where((t) => t.bookId.equals(bookId))).getSingleOrNull();
  }

  /// 插入账簿。
  ///
  /// - 若未提供 createdAt/updatedAt，自动以当前时间填充（毫秒时间戳）。
  Future<String> insertOne(AccountBooksCompanion companion) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final Expression<int> countExp = accountBooks.bookId.count();
    final TypedResult row = await (selectOnly(
      accountBooks,
    )..addColumns([countExp])).getSingle();
    final bool hasAnyBook = (row.read(countExp) ?? 0) > 0;
    final AccountBooksCompanion withDefaults = companion.copyWith(
      bookId: companion.bookId.present ? companion.bookId : Value(db.newId()),
      bookTime: companion.bookTime.present ? companion.bookTime : Value(now),
      // 业务规则：首个账簿自动设为默认，后续账簿默认状态由系统托管。
      isDefault: Value(hasAnyBook ? 0 : 1),
      createdAt: companion.createdAt.present ? companion.createdAt : Value(now),
      updatedAt: companion.updatedAt.present ? companion.updatedAt : Value(now),
    );

    await into(accountBooks).insert(withDefaults);
    return withDefaults.bookId.value;
  }

  /// 更新账簿（会自动刷新 updatedAt）。
  Future<bool> updateOne(AccountBook book) {
    final AccountBook updated = book.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return db.transaction(() async {
      final previous = await findById(book.bookId);
      if (previous == null) return false;
      final changed = await update(accountBooks).replace(updated);
      if (changed && book.isDefault != 1) {
        if (previous.reasonType != book.reasonType) {
          await db.giftRecordsDao.updateEventNameByBookId(
            book.bookId,
            book.reasonType,
          );
        }
        if (previous.bookTime != book.bookTime) {
          await db.giftRecordsDao.updateOccurredAtByBookId(
            book.bookId,
            book.bookTime,
          );
        }
      }
      return changed;
    });
  }

  /// 删除账簿。
  ///
  /// 表结构上 book_id 作为其它表外键，开启级联删除。
  Future<int> deleteById(String bookId) async {
    final book = await findById(bookId);
    if (book == null) return 0;
    if (book.isDefault == 1) {
      throw StateError('默认账簿不可删除');
    }
    return (delete(accountBooks)..where((t) => t.bookId.equals(bookId))).go();
  }

  /// 获取默认账簿（若存在多个，返回 updatedAt 最新的一个）。
  Future<AccountBook?> findDefault() {
    return (select(accountBooks)
          ..where((t) => t.isDefault.equals(1))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}
