part of '../app_database.dart';

/// 账簿 DAO：提供 book 维度的数据访问能力。
@DriftAccessor(tables: [AccountBooks])
class AccountBooksDao extends DatabaseAccessor<AppDatabase>
    with _$AccountBooksDaoMixin {
  AccountBooksDao(super.db);

  /// 监听单个账簿变化。
  Stream<AccountBook> watchBook(String bookId) {
    return (select(accountBooks)..where((t) => t.bookId.equals(bookId)))
        .watchSingle();
  }

  /// 查询所有账簿（按创建时间倒序）。
  Stream<List<AccountBook>> watchAll() {
    return (select(accountBooks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 根据 bookId 查询单个账簿。
  Future<AccountBook?> findById(String bookId) {
    return (select(accountBooks)..where((t) => t.bookId.equals(bookId)))
        .getSingleOrNull();
  }

  /// 插入账簿。
  ///
  /// - 若未提供 createdAt/updatedAt，自动以当前时间填充（毫秒时间戳）。
  Future<String> insertOne(AccountBooksCompanion companion) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final AccountBooksCompanion withDefaults = companion.copyWith(
      bookId: companion.bookId.present ? companion.bookId : Value(db.newId()),
      createdAt:
          companion.createdAt.present ? companion.createdAt : Value(now),
      updatedAt:
          companion.updatedAt.present ? companion.updatedAt : Value(now),
    );

    await into(accountBooks).insert(withDefaults);
    return withDefaults.bookId.value;
  }

  /// 更新账簿（会自动刷新 updatedAt）。
  Future<bool> updateOne(AccountBook book) {
    final AccountBook updated = book.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return update(accountBooks).replace(updated);
  }

  /// 删除账簿。
  ///
  /// 表结构上 book_id 作为其它表外键，开启级联删除。
  Future<int> deleteById(String bookId) {
    return (delete(accountBooks)..where((t) => t.bookId.equals(bookId))).go();
  }

  /// 将指定账簿设置为默认账簿（事务保证只有一个默认）。
  Future<void> setDefaultBook(String bookId) {
    return transaction(() async {
      await (update(accountBooks)).write(
        const AccountBooksCompanion(isDefault: Value(0)),
      );
      await (update(accountBooks)..where((t) => t.bookId.equals(bookId))).write(
        AccountBooksCompanion(
          isDefault: const Value(1),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    });
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
