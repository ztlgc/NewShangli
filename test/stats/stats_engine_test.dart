import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/stats/stats_engine.dart';
import 'package:newshangli/stats/stats_models.dart';
import 'package:newshangli/stats/stats_time_range.dart';

void main() {
  test('统计聚合：总收支/分类/榜单/柱状', () {
    final start = DateTime(2026, 3, 1);
    final end = DateTime(2026, 4, 1);
    final records = <StatsRecordLite>[
      StatsRecordLite(
        direction: 0,
        amountCent: 20000,
        eventName: '结婚礼金',
        personName: '张伟',
        occurredAt: DateTime(2026, 3, 2),
      ),
      StatsRecordLite(
        direction: 1,
        amountCent: 8000,
        eventName: '孩子满月',
        personName: '李娜',
        occurredAt: DateTime(2026, 3, 3),
      ),
      StatsRecordLite(
        direction: 1,
        amountCent: 12000,
        eventName: '乔迁之喜',
        personName: '王强',
        occurredAt: DateTime(2026, 3, 10),
      ),
      StatsRecordLite(
        direction: 1,
        amountCent: 5000,
        eventName: '孩子满月',
        personName: '李娜',
        occurredAt: DateTime(2026, 3, 20),
      ),
    ];

    final s = computeStatsSnapshot(
      preset: StatsTimePreset.thisMonth,
      start: start,
      endExclusive: end,
      records: records,
    );

    expect(s.incomeTotalCent, 20000);
    expect(s.expenseTotalCent, 25000);
    expect(s.expenseCategories.first.category, '孩子满月');
    expect(s.expenseCategories.first.amountCent, 13000);
    expect(s.ranking.first.personName, '张伟');
    expect(s.ranking.first.totalCent, 20000);
    expect(s.buckets.length, 31);
  });

  test('金额格式化', () {
    expect(formatCentToYuan(10000), '¥100');
    expect(formatCentToYuan(123456), '¥1,234.56');
    expect(formatCentToYuan(-10000), '-¥100');
  });

  test('性能：大数据量聚合不超过2秒', () {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2027, 1, 1);
    final rng = Random(1);

    final records = <StatsRecordLite>[];
    for (var i = 0; i < 20000; i++) {
      final month = 1 + rng.nextInt(12);
      final day = 1 + rng.nextInt(28);
      records.add(
        StatsRecordLite(
          direction: rng.nextBool() ? 0 : 1,
          amountCent: 100 + rng.nextInt(500000),
          eventName: rng.nextBool() ? '婚礼' : '其他',
          personName: 'P${rng.nextInt(100)}',
          occurredAt: DateTime(2026, month, day),
        ),
      );
    }

    final sw = Stopwatch()..start();
    computeStatsSnapshot(
      preset: StatsTimePreset.thisYear,
      start: start,
      endExclusive: end,
      records: records,
    );
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(2000));
  });
}

