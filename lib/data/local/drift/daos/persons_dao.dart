part of '../app_database.dart';

/// 关系人 DAO：所有读写都要求 book 维度入参，避免跨账簿污染。
@DriftAccessor(tables: [Persons])
class PersonsDao extends DatabaseAccessor<AppDatabase> with _$PersonsDaoMixin {
  PersonsDao(super.db);

  Stream<List<Person>> watchAllInAllBooks() {
    return (select(persons)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<Person>> watchAllInBook(String bookId) {
    return (select(persons)
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Person?> findById(String personId) {
    return (select(persons)
          ..where((t) => t.personId.equals(personId))
          ..where((t) => t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<Person?> findByIdAny(String personId) {
    return (select(persons)..where((t) => t.personId.equals(personId)))
        .getSingleOrNull();
  }

  Stream<List<Person>> watchDeleted() {
    return (select(persons)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt), (t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<String> insertOne(PersonsCompanion companion) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final PersonsCompanion withDefaults = companion.copyWith(
      personId:
          companion.personId.present ? companion.personId : Value(db.newId()),
      createdAt:
          companion.createdAt.present ? companion.createdAt : Value(now),
      updatedAt:
          companion.updatedAt.present ? companion.updatedAt : Value(now),
    );

    await into(persons).insert(withDefaults);
    return withDefaults.personId.value;
  }

  Future<bool> updateOne(Person person) {
    final Person updated = person.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return update(persons).replace(updated);
  }

  Future<int> deleteById(String personId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(persons)..where((t) => t.personId.equals(personId))).write(
      PersonsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> restoreById(String personId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(persons)..where((t) => t.personId.equals(personId))).write(
      PersonsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> purgeById(String personId) {
    return (delete(persons)..where((t) => t.personId.equals(personId))).go();
  }

  /// 基于索引 (book_id, name) 的模糊搜索（前缀/包含）。
  Future<List<Person>> searchInBook({
    required String bookId,
    required String keyword,
    int limit = 50,
  }) {
    final String kw = keyword.trim();
    if (kw.isEmpty) {
      return Future.value(const <Person>[]);
    }

    return (select(persons)
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.name.like('%$kw%') | t.phone.like('%$kw%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(limit))
        .get();
  }
}
