import 'stats_models.dart';
import 'stats_time_range.dart';

class StatsRecordLite {
  const StatsRecordLite({
    required this.direction,
    required this.amountCent,
    required this.eventName,
    required this.personName,
    this.personId,
    required this.occurredAt,
  });

  final int direction;
  final int amountCent;
  final String eventName;
  final String personName;
  final String? personId;
  final DateTime occurredAt;
}

StatsSnapshot computeStatsSnapshot({
  required StatsTimePreset preset,
  required DateTime start,
  required DateTime endExclusive,
  required List<StatsRecordLite> records,
}) {
  var incomeTotal = 0;
  var expenseTotal = 0;

  final categoryMap = <String, int>{};
  final rankMap = <String, (int income, int expense)>{};
  final personNames = <String, String>{};

  for (final r in records) {
    if (r.direction == 0) {
      incomeTotal += r.amountCent;
    } else {
      expenseTotal += r.amountCent;
      final c = r.eventName.trim().isEmpty ? '未分类' : r.eventName.trim();
      categoryMap[c] = (categoryMap[c] ?? 0) + r.amountCent;
    }

    final name = r.personName.trim().isEmpty ? '未知' : r.personName.trim();
    final p = r.personId ?? name;
    personNames[p] = name;
    final old = rankMap[p] ?? (0, 0);
    if (r.direction == 0) {
      rankMap[p] = (old.$1 + r.amountCent, old.$2);
    } else {
      rankMap[p] = (old.$1, old.$2 + r.amountCent);
    }
  }

  final categories = _buildCategories(categoryMap, expenseTotal);
  final ranking = _buildRanking(rankMap, personNames);
  final buckets = _buildBuckets(
    preset: preset,
    start: start,
    endExclusive: endExclusive,
    records: records,
  );

  return StatsSnapshot(
    incomeTotalCent: incomeTotal,
    expenseTotalCent: expenseTotal,
    buckets: buckets,
    expenseCategories: categories,
    ranking: ranking,
  );
}

List<StatsCategorySlice> _buildCategories(
  Map<String, int> categoryMap,
  int totalExpense,
) {
  final entries = categoryMap.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final out = <StatsCategorySlice>[];
  var topSum = 0;
  for (final e in entries.take(8)) {
    topSum += e.value;
    out.add(StatsCategorySlice(category: e.key, amountCent: e.value));
  }
  final rest = totalExpense - topSum;
  if (rest > 0 && out.length >= 2) {
    out.add(StatsCategorySlice(category: '其他', amountCent: rest));
  }
  return out;
}

List<StatsRankItem> _buildRanking(
  Map<String, (int income, int expense)> rankMap,
  Map<String, String> names,
) {
  final items = <StatsRankItem>[];
  for (final e in rankMap.entries) {
    if (e.value.$1 <= 0 && e.value.$2 <= 0) continue;
    items.add(
      StatsRankItem(
        personId: e.key,
        personName: names[e.key] ?? e.key,
        incomeCent: e.value.$1,
        expenseCent: e.value.$2,
      ),
    );
  }
  items.sort((a, b) => b.totalCent.compareTo(a.totalCent));
  return items.take(5).toList();
}

/// 构建时间维度的桶，用于：
/// - 直方图（按日/按月/按年）
/// - 趋势折线（同一组桶直接转折线点）
///
/// 选择策略：
/// - 本月 / 最近30天：按日
/// - 本年：按月
/// - 自定义：<= 62 天按日；<= 24 个月按月；否则按年
List<StatsBarBucket> _buildBuckets({
  required StatsTimePreset preset,
  required DateTime start,
  required DateTime endExclusive,
  required List<StatsRecordLite> records,
}) {
  final rawDays = endExclusive.difference(start).inDays;
  final days = rawDays <= 0 ? 1 : rawDays;

  final endInclusive = endExclusive.subtract(const Duration(days: 1));
  final sameMonth =
      start.year == endInclusive.year && start.month == endInclusive.month;

  final useDay =
      preset == StatsTimePreset.thisMonth ||
      (preset == StatsTimePreset.custom && days <= 62);
  if (useDay) {
    final byKey = <int, (int income, int expense)>{};
    for (final r in records) {
      final dt = DateTime(
        r.occurredAt.year,
        r.occurredAt.month,
        r.occurredAt.day,
      );
      final k = dt.year * 10000 + dt.month * 100 + dt.day;
      final old = byKey[k] ?? (0, 0);
      if (r.direction == 0) {
        byKey[k] = (old.$1 + r.amountCent, old.$2);
      } else {
        byKey[k] = (old.$1, old.$2 + r.amountCent);
      }
    }

    final out = <StatsBarBucket>[];
    var cursor = DateTime(start.year, start.month, start.day);
    while (cursor.isBefore(endExclusive)) {
      final k = cursor.year * 10000 + cursor.month * 100 + cursor.day;
      final v = byKey[k] ?? (0, 0);
      final label = sameMonth
          ? '${cursor.day}'
          : '${cursor.month}/${cursor.day}';
      final next = cursor.add(const Duration(days: 1));
      out.add(
        StatsBarBucket(
          start: cursor,
          endExclusive: next,
          label: label,
          incomeCent: v.$1,
          expenseCent: v.$2,
        ),
      );
      cursor = next;
    }
    return out;
  }

  int countMonths(DateTime a, DateTime bExclusive) {
    var count = 0;
    var cursor = DateTime(a.year, a.month, 1);
    while (cursor.isBefore(bExclusive)) {
      count++;
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return count;
  }

  final monthCount = countMonths(start, endExclusive);
  final useMonth =
      preset == StatsTimePreset.thisYear ||
      (preset == StatsTimePreset.custom && monthCount <= 24);
  if (useMonth) {
    final byKey = <int, (int income, int expense)>{};
    for (final r in records) {
      final k = r.occurredAt.year * 100 + r.occurredAt.month;
      final old = byKey[k] ?? (0, 0);
      if (r.direction == 0) {
        byKey[k] = (old.$1 + r.amountCent, old.$2);
      } else {
        byKey[k] = (old.$1, old.$2 + r.amountCent);
      }
    }

    final out = <StatsBarBucket>[];
    var cursor = DateTime(start.year, start.month, 1);
    while (cursor.isBefore(endExclusive)) {
      final k = cursor.year * 100 + cursor.month;
      final v = byKey[k] ?? (0, 0);
      final next = DateTime(cursor.year, cursor.month + 1, 1);
      out.add(
        StatsBarBucket(
          start: cursor,
          endExclusive: next,
          label: '${cursor.month}',
          incomeCent: v.$1,
          expenseCent: v.$2,
        ),
      );
      cursor = next;
    }
    return out;
  }

  final byYear = <int, (int income, int expense)>{};
  for (final r in records) {
    final k = r.occurredAt.year;
    final old = byYear[k] ?? (0, 0);
    if (r.direction == 0) {
      byYear[k] = (old.$1 + r.amountCent, old.$2);
    } else {
      byYear[k] = (old.$1, old.$2 + r.amountCent);
    }
  }

  final out = <StatsBarBucket>[];
  var cursor = DateTime(start.year, 1, 1);
  while (cursor.isBefore(endExclusive)) {
    final k = cursor.year;
    final v = byYear[k] ?? (0, 0);
    final next = DateTime(cursor.year + 1, 1, 1);
    out.add(
      StatsBarBucket(
        start: cursor,
        endExclusive: next,
        label: '${cursor.year}',
        incomeCent: v.$1,
        expenseCent: v.$2,
      ),
    );
    cursor = next;
  }
  return out;
}
