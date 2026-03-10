part of '../app_database.dart';

/// 事件提醒 DAO。
@DriftAccessor(tables: [EventReminders])
class EventRemindersDao extends DatabaseAccessor<AppDatabase>
    with _$EventRemindersDaoMixin {
  EventRemindersDao(super.db);

  Stream<List<EventReminder>> watchAllInBook(String bookId) {
    return (select(eventReminders)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.asc(t.remindAt)]))
        .watch();
  }

  Stream<List<EventReminder>> watchUpcoming({
    required String bookId,
    required int now,
    int limit = 200,
  }) {
    return (select(eventReminders)
          ..where((t) => t.bookId.equals(bookId))
          ..where((t) => t.remindAt.isBiggerOrEqualValue(now))
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.remindAt)])
          ..limit(limit))
        .watch();
  }

  Future<EventReminder?> findById(String reminderId) {
    return (select(eventReminders)
          ..where((t) => t.reminderId.equals(reminderId)))
        .getSingleOrNull();
  }

  Future<String> insertOne(EventRemindersCompanion companion) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final EventRemindersCompanion withDefaults = companion.copyWith(
      reminderId: companion.reminderId.present
          ? companion.reminderId
          : Value(db.newId()),
      createdAt:
          companion.createdAt.present ? companion.createdAt : Value(now),
      updatedAt:
          companion.updatedAt.present ? companion.updatedAt : Value(now),
    );

    await into(eventReminders).insert(withDefaults);
    return withDefaults.reminderId.value;
  }

  Future<bool> updateOne(EventReminder reminder) {
    final EventReminder updated = reminder.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return update(eventReminders).replace(updated);
  }

  Future<int> deleteById(String reminderId) {
    return (delete(eventReminders)
          ..where((t) => t.reminderId.equals(reminderId)))
        .go();
  }

  /// 标记提醒完成（status = done）。
  Future<int> markDone(String reminderId) {
    return (update(eventReminders)
          ..where((t) => t.reminderId.equals(reminderId)))
        .write(
      EventRemindersCompanion(
        status: const Value('done'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 标记提醒未完成（status = active）。
  Future<int> markActive(String reminderId) {
    return (update(eventReminders)
          ..where((t) => t.reminderId.equals(reminderId)))
        .write(
      EventRemindersCompanion(
        status: const Value('active'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
