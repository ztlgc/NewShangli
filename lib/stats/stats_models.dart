class StatsBarBucket {
  const StatsBarBucket({
    required this.start,
    required this.endExclusive,
    required this.label,
    required this.incomeCent,
    required this.expenseCent,
  });

  /// 桶起始时间（含）。
  final DateTime start;

  /// 桶结束时间（不含）。
  final DateTime endExclusive;

  final String label;
  final int incomeCent;
  final int expenseCent;

  int get netCent => incomeCent - expenseCent;
}

class StatsCategorySlice {
  const StatsCategorySlice({required this.category, required this.amountCent});

  final String category;
  final int amountCent;
}

class StatsRankItem {
  const StatsRankItem({
    required this.personName,
    this.personId,
    required this.incomeCent,
    required this.expenseCent,
  });

  final String personName;
  final String? personId;
  final int incomeCent;
  final int expenseCent;

  int get totalCent => incomeCent + expenseCent;
  int get netCent => incomeCent - expenseCent;
}

class StatsSnapshot {
  const StatsSnapshot({
    required this.incomeTotalCent,
    required this.expenseTotalCent,
    required this.buckets,
    required this.expenseCategories,
    required this.ranking,
  });

  final int incomeTotalCent;
  final int expenseTotalCent;
  final List<StatsBarBucket> buckets;
  final List<StatsCategorySlice> expenseCategories;
  final List<StatsRankItem> ranking;

  int get netTotalCent => incomeTotalCent - expenseTotalCent;
}

String formatCentToYuan(int amountCent) {
  final abs = amountCent.abs();
  final yuan = abs ~/ 100;
  final cent = abs % 100;
  final s = yuan.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - i;
    buf.write(s[i]);
    if (idx > 1 && idx % 3 == 1) buf.write(',');
  }
  final sign = amountCent < 0 ? '-' : '';
  return '$sign¥${buf.toString()}${cent == 0 ? '' : '.${cent.toString().padLeft(2, '0')}'}';
}
