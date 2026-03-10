part of '../app_database.dart';

/// 礼金记录与关系人联表后的展示数据结构。
///
/// 说明：
/// - UI 层展示账簿记录列表时通常需要同时展示关系人姓名/关系等信息；
/// - 这里用一个轻量 DTO 承接 join 的结果，避免 UI 自己拼 SQL。
class GiftRecordWithPerson {
  const GiftRecordWithPerson({
    required this.record,
    required this.person,
  });

  final GiftRecord record;
  final Person person;
}

/// 礼金记录 DAO。
@DriftAccessor(tables: [GiftRecords, Persons])
class GiftRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$GiftRecordsDaoMixin {
  GiftRecordsDao(super.db);

  /// 账簿内按时间倒序分页查询（后续可与 Paging 组件对接）。
  Stream<List<GiftRecord>> watchRecentInBook(String bookId, {int limit = 200}) {
    return (select(giftRecords)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
          ..limit(limit))
        .watch();
  }

  /// 账簿内按时间倒序查询全部记录（用于账簿记录页列表展示）。
  ///
  /// 注意：如果未来数据量很大，应改为分页或与 Paging 组件对接。
  Stream<List<GiftRecord>> watchAllInBook(String bookId) {
    return (select(giftRecords)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch();
  }

  /// 账簿内联表查询：礼金记录 + 关系人。
  ///
  /// - 用于“账簿记录页面”展示：姓名、金额、收支方向、发生时间等。
  /// - 这里额外约束 persons.bookId，与 gift_record.book_id 一致，防止异常数据污染。
  Stream<List<GiftRecordWithPerson>> watchAllWithPersonInBook(String bookId) {
    final joined = select(giftRecords).join([
      innerJoin(
        persons,
        persons.personId.equalsExp(giftRecords.personId),
      ),
    ])
      ..where(giftRecords.bookId.equals(bookId))
      ..where(persons.bookId.equals(bookId))
      ..orderBy([OrderingTerm.desc(giftRecords.occurredAt)]);

    return joined.watch().map((rows) {
      return rows
          .map(
            (row) => GiftRecordWithPerson(
              record: row.readTable(giftRecords),
              person: row.readTable(persons),
            ),
          )
          .toList();
    });
  }

  /// 默认账簿视角：展示所有记录（用于“默认账簿包含未指定账簿的记录/全部记录”的需求）。
  ///
  /// 说明：
  /// - 当前表结构 gift_record.book_id 必填，因此“未指定账簿”的含义在 UI 上等价为“默认账簿汇总视角”
  /// - 这里不按 bookId 过滤，直接返回所有记录
  Stream<List<GiftRecordWithPerson>> watchAllWithPersonInAllBooks() {
    final joined = select(giftRecords).join([
      innerJoin(
        persons,
        persons.personId.equalsExp(giftRecords.personId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(giftRecords.occurredAt)]);

    return joined.watch().map((rows) {
      return rows
          .map(
            (row) => GiftRecordWithPerson(
              record: row.readTable(giftRecords),
              person: row.readTable(persons),
            ),
          )
          .toList();
    });
  }

  /// 账簿内记录数（用于账簿列表展示“xx 条记录”）。
  Stream<int> watchCountInBook(String bookId) {
    final countExp = giftRecords.recordId.count();
    final query = selectOnly(giftRecords)
      ..addColumns([countExp])
      ..where(giftRecords.bookId.equals(bookId));

    return query.watch().map((rows) {
      if (rows.isEmpty) return 0;
      return rows.first.read(countExp) ?? 0;
    });
  }

  /// 默认账簿视角：统计所有记录数。
  Stream<int> watchCountInAllBooks() {
    final countExp = giftRecords.recordId.count();
    final query = selectOnly(giftRecords)..addColumns([countExp]);
    return query.watch().map((rows) {
      if (rows.isEmpty) return 0;
      return rows.first.read(countExp) ?? 0;
    });
  }

  Future<GiftRecord?> findById(String recordId) {
    return (select(giftRecords)..where((t) => t.recordId.equals(recordId)))
        .getSingleOrNull();
  }

  Future<String> insertOne(GiftRecordsCompanion companion) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final GiftRecordsCompanion withDefaults = companion.copyWith(
      recordId:
          companion.recordId.present ? companion.recordId : Value(db.newId()),
      createdAt:
          companion.createdAt.present ? companion.createdAt : Value(now),
      updatedAt:
          companion.updatedAt.present ? companion.updatedAt : Value(now),
    );

    await into(giftRecords).insert(withDefaults);
    return withDefaults.recordId.value;
  }

  Future<bool> updateOne(GiftRecord record) {
    final GiftRecord updated = record.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return update(giftRecords).replace(updated);
  }

  Future<int> deleteById(String recordId) {
    return (delete(giftRecords)..where((t) => t.recordId.equals(recordId))).go();
  }

  /// 查询某个关系人在指定账簿下的往来记录（按时间倒序）。
  Future<List<GiftRecord>> listByPerson({
    required String bookId,
    required String personId,
    int limit = 500,
  }) {
    return (select(giftRecords)
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.personId.equals(personId))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
          ..limit(limit))
        .get();
  }

  /// 在账簿内按时间范围查询（用于统计/导出）。
  Future<List<GiftRecord>> listInRange({
    required String bookId,
    required int startAt,
    required int endAt,
  }) {
    return (select(giftRecords)
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.occurredAt.isBetweenValues(startAt, endAt))
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .get();
  }

  /// 统计某个关系人在账簿内的总收/总支（单位：分）。
  ///
  /// direction:
  /// - 收入：总收礼
  /// - 支出：总送礼
  Future<int> sumAmountByPersonAndDirection({
    required String bookId,
    required String personId,
    required String direction,
  }) async {
    final Expression<int> sumExp = giftRecords.amountCent.sum();
    final query = selectOnly(giftRecords)
      ..addColumns([sumExp])
      ..where(giftRecords.bookId.equals(bookId))
      ..where(giftRecords.personId.equals(personId))
      ..where(giftRecords.direction.equals(direction));

    final row = await query.getSingleOrNull();
    return row == null ? 0 : (row.read(sumExp) ?? 0);
  }
}
