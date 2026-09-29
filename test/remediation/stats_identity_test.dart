import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/stats/stats_engine.dart';
import 'package:newshangli/stats/stats_time_range.dart';

void main() {
  test('同名不同ID联系人排名分别统计，同ID跨账本累加', () {
    final snapshot = computeStatsSnapshot(
      preset: StatsTimePreset.thisMonth,
      start: DateTime(2026),
      endExclusive: DateTime(2026, 2),
      records: [
        StatsRecordLite(
          personId: 'one',
          personName: '张三',
          direction: 0,
          amountCent: 100,
          eventName: '',
          occurredAt: DateTime(2026),
        ),
        StatsRecordLite(
          personId: 'two',
          personName: '张三',
          direction: 1,
          amountCent: 200,
          eventName: '',
          occurredAt: DateTime(2026),
        ),
        StatsRecordLite(
          personId: 'one',
          personName: '张三',
          direction: 0,
          amountCent: 300,
          eventName: '',
          occurredAt: DateTime(2026),
        ),
      ],
    );
    expect(snapshot.ranking.length, 2);
    expect(
      snapshot.ranking.singleWhere((r) => r.personId == 'one').incomeCent,
      400,
    );
    expect(
      snapshot.ranking.singleWhere((r) => r.personId == 'two').expenseCent,
      200,
    );
  });
}
