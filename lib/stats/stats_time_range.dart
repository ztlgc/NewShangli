enum StatsTimePreset {
  thisMonth,
  custom,
  thisYear,
}

extension StatsTimePresetText on StatsTimePreset {
  String get label {
    switch (this) {
      case StatsTimePreset.thisMonth:
        return '本月';
      case StatsTimePreset.custom:
        return '自定义时间';
      case StatsTimePreset.thisYear:
        return '本年';
    }
  }
}

class StatsDateRange {
  const StatsDateRange({
    required this.start,
    required this.endExclusive,
  });

  final DateTime start;
  final DateTime endExclusive;
}

StatsDateRange resolveStatsDateRange(
  StatsTimePreset preset, {
  DateTime? now,
  StatsDateRange? customRange,
}) {
  final n = now ?? DateTime.now();
  switch (preset) {
    case StatsTimePreset.thisMonth:
      return StatsDateRange(
        start: DateTime(n.year, n.month, 1),
        endExclusive: DateTime(n.year, n.month + 1, 1),
      );
    case StatsTimePreset.custom:
      if (customRange != null) return customRange;
      return StatsDateRange(
        start: DateTime(n.year, n.month, 1),
        endExclusive: DateTime(n.year, n.month + 1, 1),
      );
    case StatsTimePreset.thisYear:
      return StatsDateRange(
        start: DateTime(n.year, 1, 1),
        endExclusive: DateTime(n.year + 1, 1, 1),
      );
  }
}
