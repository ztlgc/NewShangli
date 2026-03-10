import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/stats/stats_time_range.dart';

void main() {
  test('时间范围计算正确', () {
    final now = DateTime(2026, 3, 1, 10, 0);

    final m = resolveStatsDateRange(StatsTimePreset.thisMonth, now: now);
    expect(m.start, DateTime(2026, 3, 1));
    expect(m.endExclusive, DateTime(2026, 4, 1));

    final custom = StatsDateRange(start: DateTime(2025, 10, 1), endExclusive: DateTime(2026, 4, 1));
    final c = resolveStatsDateRange(StatsTimePreset.custom, now: now, customRange: custom);
    expect(c.start, DateTime(2025, 10, 1));
    expect(c.endExclusive, DateTime(2026, 4, 1));

    final y = resolveStatsDateRange(StatsTimePreset.thisYear, now: now);
    expect(y.start, DateTime(2026, 1, 1));
    expect(y.endExclusive, DateTime(2027, 1, 1));
  });
}

