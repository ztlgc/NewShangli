import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/stats/stats_engine.dart';
import 'package:newshangli/stats/stats_models.dart';
import 'package:newshangli/stats/stats_repository.dart';
import 'package:newshangli/stats/stats_time_range.dart';
import 'package:newshangli/ui/stats/stats_view_model.dart';

class _FakeStatsRepository implements IStatsRepository {
  @override
  Future<StatsSnapshot> load(
    StatsTimePreset preset, {
    required List<StatsSourceRecord> records,
    String? bookId,
    DateTime? now,
    StatsDateRange? customRange,
  }) async {
    final range = resolveStatsDateRange(
      preset,
      now: now,
      customRange: customRange,
    );
    final filtered = records
        .where((record) => bookId == null || record.bookId == bookId)
        .where(
          (record) =>
              !record.occurredAt.isBefore(range.start) &&
              record.occurredAt.isBefore(range.endExclusive),
        )
        .map(
          (record) => StatsRecordLite(
            direction: record.direction,
            amountCent: record.amountCent,
            eventName: record.eventName,
            personName: record.personName,
            occurredAt: record.occurredAt,
          ),
        )
        .toList();
    return computeStatsSnapshot(
      preset: preset,
      start: range.start,
      endExclusive: range.endExclusive,
      records: filtered,
    );
  }
}

void main() {
  test('StatsViewModel 会实时纳入全账簿范围内的新记录', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async => db.close());

    const defaultBookId = 'default_book';
    const otherBookId = 'other_book';
    const defaultPersonId = 'p_default';
    const otherPersonId = 'p_other';
    final march5 = DateTime(2026, 3, 5).millisecondsSinceEpoch;
    final march6 = DateTime(2026, 3, 6).millisecondsSinceEpoch;
    final march7 = DateTime(2026, 3, 7).millisecondsSinceEpoch;

    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value(defaultBookId),
        name: '默认账簿',
        isDefault: const Value(1),
        createdAt: march5,
        updatedAt: march5,
      ),
    );
    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value(otherBookId),
        name: '婚礼账簿',
        createdAt: march5,
        updatedAt: march5,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value(defaultPersonId),
        bookId: defaultBookId,
        name: '默认联系人',
        createdAt: march5,
        updatedAt: march5,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value(otherPersonId),
        bookId: otherBookId,
        name: '其他联系人',
        createdAt: march5,
        updatedAt: march5,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: defaultBookId,
        personId: defaultPersonId,
        amountCent: 1000,
        direction: const Value('收入'),
        occurredAt: march5,
        createdAt: march5,
        updatedAt: march5,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: otherBookId,
        personId: otherPersonId,
        amountCent: 2000,
        direction: const Value('收入'),
        occurredAt: march6,
        createdAt: march6,
        updatedAt: march6,
      ),
    );

    final vm = StatsViewModel(
      repository: _FakeStatsRepository(),
      db: db,
      now: () => DateTime(2026, 3, 31),
    );
    addTearDown(vm.dispose);

    await vm.init();

    // 统计口径为全账簿：应同时包含默认账簿与其他账簿收入。
    expect(vm.data?.incomeTotalCent, 3000);
    expect(vm.data?.expenseTotalCent, 0);

    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: otherBookId,
        personId: otherPersonId,
        amountCent: 500,
        direction: const Value('支出'),
        occurredAt: march7,
        createdAt: march7,
        updatedAt: march7,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(vm.data?.incomeTotalCent, 3000);
    expect(vm.data?.expenseTotalCent, 500);
  });
}
