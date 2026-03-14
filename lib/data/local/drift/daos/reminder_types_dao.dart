part of '../app_database.dart';

@DriftAccessor(tables: [ReminderTypes])
class ReminderTypesDao extends DatabaseAccessor<AppDatabase> with _$ReminderTypesDaoMixin {
  ReminderTypesDao(super.db);

  Stream<List<ReminderType>> watchAllInBook(String bookId) {
    return (select(reminderTypes)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCustom),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  Future<List<ReminderType>> listAllInBook(String bookId) {
    return (select(reminderTypes)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCustom),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  Future<ReminderType?> findByName({
    required String bookId,
    required String name,
  }) {
    return (select(reminderTypes)
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
  }

  Future<String> insertOne(ReminderTypesCompanion row) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final withDefaults = row.copyWith(
      typeId: row.typeId.present ? row.typeId : Value(db.newId()),
      createdAt: row.createdAt.present ? row.createdAt : Value(now),
      updatedAt: row.updatedAt.present ? row.updatedAt : Value(now),
    );
    await into(reminderTypes).insert(withDefaults);
    return withDefaults.typeId.value;
  }
}
