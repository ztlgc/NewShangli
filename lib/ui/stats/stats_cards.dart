import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../stats/stats_models.dart';
import '../../stats/stats_time_range.dart';
import '../app_icons.dart';
import '../app_tokens.dart';
import '../components.dart';

Text _text(
  BuildContext context,
  String value,
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
  int? maxLines,
}) => Text(
  value,
  maxLines: maxLines,
  overflow: maxLines == null ? null : TextOverflow.ellipsis,
  style: AppTypography.base(
    fontSize: size,
    fontWeight: weight,
    color: color ?? context.appColors.textPrimary,
    height: 1.35,
  ),
);

double _textWidth(BuildContext context, String value, double size) {
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: AppTypography.base(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: context.appColors.textPrimary,
      ),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

class StatsOverviewCard extends StatelessWidget {
  const StatsOverviewCard({
    super.key,
    required this.data,
    required this.title,
    required this.compareLabel,
    this.compare,
  });
  final StatsSnapshot data;
  final StatsSnapshot? compare;
  final String title;
  final String? compareLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final income = _Metric(
      label: '收礼',
      amount: data.incomeTotalCent,
      previous: compare?.incomeTotalCent,
      compareLabel: compareLabel,
      color: colors.stateSuccess,
      icon: AppIcons.arrowDown,
    );
    final expense = _Metric(
      label: '送礼',
      amount: data.expenseTotalCent,
      previous: compare?.expenseTotalCent,
      compareLabel: compareLabel,
      color: colors.stateDanger,
      icon: AppIcons.arrowUp,
    );
    final net = data.netTotalCent;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _text(context, title, 16, weight: FontWeight.w600),
              ),
              _text(context, '人民币 · 元', 11, color: colors.textTertiary),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final requiredWidth = math.max(
                _textWidth(context, formatCentToYuan(data.incomeTotalCent), 26),
                _textWidth(
                  context,
                  formatCentToYuan(data.expenseTotalCent),
                  26,
                ),
              );
              if (requiredWidth * 2 + 32 > constraints.maxWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    income,
                    const SizedBox(height: 16),
                    Divider(height: 1, color: colors.borderSubtle),
                    const SizedBox(height: 16),
                    expense,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: income),
                  Container(height: 66, width: 1, color: colors.borderSubtle),
                  const SizedBox(width: 18),
                  Expanded(child: expense),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _text(context, '收支结余', 13, color: colors.textSecondary),
                _text(
                  context,
                  '${net > 0 ? '+' : ''}${formatCentToYuan(net)}',
                  18,
                  weight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.amount,
    required this.previous,
    required this.compareLabel,
    required this.color,
    required this.icon,
  });
  final String label;
  final int amount;
  final int? previous;
  final String? compareLabel;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final formatted = formatCentToYuan(amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            _text(context, label, 13, color: context.appColors.textSecondary),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          label: '$label $formatted',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '¥',
                    style: TextStyle(fontSize: 15, color: color),
                  ),
                  TextSpan(
                    text: formatted.substring(1),
                    style: TextStyle(color: color),
                  ),
                ],
              ),
              style: AppTypography.base(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.1,
              ),
            ),
          ),
        ),
        if (compareLabel != null) ...[
          const SizedBox(height: 7),
          _text(
            context,
            _comparison(),
            11,
            color: context.appColors.textTertiary,
          ),
        ],
      ],
    );
  }

  String _comparison() {
    final prev = previous;
    if (prev == null) return '暂无对比数据';
    if (prev == 0) return amount == 0 ? '$compareLabel 持平' : '$compareLabel 新增';
    final change = (amount - prev) / prev.abs() * 100;
    if (change.abs() < 0.05) return '$compareLabel 持平';
    return '$compareLabel ${change > 0 ? '+' : '−'}${change.abs().toStringAsFixed(1)}%';
  }
}

class StatsTrendCard extends StatelessWidget {
  const StatsTrendCard({super.key, required this.buckets, required this.range});
  final List<StatsBarBucket> buckets;
  final StatsDateRange range;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxValue =
        buckets.fold<int>(
          0,
          (value, b) => math.max(value, math.max(b.incomeCent, b.expenseCent)),
        ) /
        100;
    final step = _niceInterval(maxValue / 3);
    final maxY = math.max(step, (maxValue / step).ceil() * step);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _text(context, '收支趋势', 16, weight: FontWeight.w600),
              ),
              _legend(context, '收礼', colors.stateSuccess),
              const SizedBox(width: 12),
              _legend(context, '送礼', colors.stateDanger),
            ],
          ),
          const SizedBox(height: 6),
          _text(
            context,
            formatStatsRange(range),
            11,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 18),
          if (maxValue == 0)
            const StatsEmptyMessage(message: '当前时段暂无收礼或送礼记录', height: 150)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = math.max(
                  constraints.maxWidth,
                  buckets.length * 9.0 + 40,
                );
                final every = math.max(1, (buckets.length / 7).ceil());
                final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        height: 150 + (scale - 1) * 32,
                        child: Semantics(
                          label: '收支趋势，共${buckets.length}个时段，点击柱形查看金额',
                          child: BarChart(
                            duration: Duration.zero,
                            BarChartData(
                              minY: 0,
                              maxY: maxY,
                              alignment: BarChartAlignment.spaceBetween,
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: step,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: colors.borderSubtle,
                                  strokeWidth: 1,
                                ),
                              ),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => colors.surfaceSubtle,
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final bucket = buckets[group.x];
                                    final income = rodIndex == 0;
                                    return BarTooltipItem(
                                      '${_bucketLabel(bucket, long: true)}\n'
                                      '${income ? '收礼' : '送礼'} ${formatCentToYuan(income ? bucket.incomeCent : bucket.expenseCent)}',
                                      AppTypography.base(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: income
                                            ? colors.stateSuccess
                                            : colors.stateDanger,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40 * scale,
                                    interval: step,
                                    getTitlesWidget: (value, _) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: _text(
                                        context,
                                        _axisAmount(value),
                                        10,
                                        color: colors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 24 * scale,
                                    interval: 1,
                                    getTitlesWidget: (value, _) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= buckets.length ||
                                          (index % every != 0 &&
                                              index != buckets.length - 1)) {
                                        return const SizedBox.shrink();
                                      }
                                      // Avoid two labels crowding together at the end of a timeline.
                                      if (index != buckets.length - 1 &&
                                          index > buckets.length - 1 - every &&
                                          buckets.length > every) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 9),
                                        child: _text(
                                          context,
                                          _bucketLabel(buckets[index]),
                                          10,
                                          color: colors.textTertiary,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                for (final (index, bucket) in buckets.indexed)
                                  BarChartGroupData(
                                    x: index,
                                    barsSpace: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: bucket.incomeCent / 100,
                                        color: colors.stateSuccess,
                                        width: 3,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(2),
                                            ),
                                      ),
                                      BarChartRodData(
                                        toY: bucket.expenseCent / 100,
                                        color: colors.stateDanger,
                                        width: 3,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(2),
                                            ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (chartWidth > constraints.maxWidth) ...[
                      const SizedBox(height: 8),
                      _text(
                        context,
                        '左右滑动查看趋势',
                        11,
                        color: colors.textTertiary,
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, String label, Color color) => Row(
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      _text(context, label, 11, color: context.appColors.textSecondary),
    ],
  );

  String _bucketLabel(StatsBarBucket bucket, {bool long = false}) {
    if (bucket.endExclusive.difference(bucket.start).inDays <= 1) {
      final sameMonth =
          range.start.year ==
              range.endExclusive.subtract(const Duration(days: 1)).year &&
          range.start.month ==
              range.endExclusive.subtract(const Duration(days: 1)).month;
      return long || !sameMonth
          ? '${bucket.start.month}月${bucket.start.day}日'
          : '${bucket.start.day}日';
    }
    if (bucket.start.month == 1 &&
        bucket.start.day == 1 &&
        bucket.endExclusive == DateTime(bucket.start.year + 1)) {
      return '${bucket.start.year}年';
    }
    return long
        ? '${bucket.start.year}年${bucket.start.month}月'
        : '${bucket.start.month}月';
  }

  double _niceInterval(double value) {
    if (value <= 0) return 1;
    final factor = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    for (final multiple in [1, 2, 4, 5, 8, 10]) {
      if (multiple * factor >= value) return multiple * factor;
    }
    return 10 * factor;
  }

  String _axisAmount(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}亿';
    }
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}万';
    }
    return value == value.roundToDouble()
        ? '${value.toInt()}'
        : value.toStringAsFixed(value < 0.1 ? 2 : 1);
  }
}

class StatsCategoryCard extends StatelessWidget {
  const StatsCategoryCard({
    super.key,
    required this.categories,
    required this.totalExpenseCent,
    required this.periodLabel,
  });
  final List<StatsCategorySlice> categories;
  final int totalExpenseCent;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final slices = categories.where((c) => c.amountCent > 0).toList();
    final palette = [
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.indigo200
          : AppColors.indigo600,
      Theme.of(context).brightness == Brightness.dark
          ? colors.orangeAccent
          : AppColors.orange500,
      Theme.of(context).brightness == Brightness.dark
          ? colors.blueAccent
          : AppColors.blue500,
      Theme.of(context).brightness == Brightness.dark
          ? colors.neutralAccent
          : AppColors.gray400,
      colors.purpleAccent,
      colors.pinkAccent,
      colors.stateSuccess,
      colors.stateWarning,
    ];
    Color sliceColor(int index) => slices[index].category == '其他'
        ? Theme.of(context).brightness == Brightness.dark
              ? colors.neutralAccent
              : AppColors.gray400
        : palette[index % palette.length];
    final empty = totalExpenseCent <= 0 || slices.isEmpty;
    final ring = SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: PieChart(
              duration: Duration.zero,
              PieChartData(
                centerSpaceRadius: 39,
                sectionsSpace: 3,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(enabled: false),
                sections: [
                  for (final (index, slice) in slices.indexed)
                    PieChartSectionData(
                      value: slice.amountCent.toDouble(),
                      color: sliceColor(index),
                      radius: 14,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _text(context, '送礼合计', 10, color: colors.textTertiary),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _text(
                    context,
                    formatCentToYuan(totalExpenseCent),
                    17,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final list = Column(
      children: [
        for (final (index, slice) in slices.indexed)
          _CategoryRow(
            slice: slice,
            total: totalExpenseCent,
            color: sliceColor(index),
          ),
      ],
    );
    final leading = empty
        ? null
        : slices.reduce((a, b) => a.amountCent >= b.amountCent ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _text(context, '送礼事由', 16, weight: FontWeight.w600),
              ),
              if (!empty)
                _text(
                  context,
                  '${slices.length}类',
                  11,
                  color: colors.textTertiary,
                ),
            ],
          ),
          if (empty)
            const StatsEmptyMessage(message: '当前时段暂无送礼记录')
          else ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(12) > 14.4) {
                  return Column(
                    children: [
                      Center(child: ring),
                      const SizedBox(height: 16),
                      list,
                    ],
                  );
                }
                return Row(
                  children: [
                    ring,
                    const SizedBox(width: 20),
                    Expanded(child: list),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: colors.borderSubtle),
            const SizedBox(height: 10),
            _text(
              context,
              '${leading!.category}占$periodLabel送礼金额的 '
              '${(leading.amountCent / totalExpenseCent * 100).toStringAsFixed(1)}%',
              11,
              color: colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.slice,
    required this.total,
    required this.color,
  });
  final StatsCategorySlice slice;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fraction = total > 0 ? slice.amountCent / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final values = Wrap(
                spacing: 8,
                runSpacing: 3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _text(
                    context,
                    formatCentToYuan(slice.amountCent),
                    12,
                    weight: FontWeight.w600,
                  ),
                  _text(
                    context,
                    '${(fraction * 100).toStringAsFixed(1)}%',
                    10,
                    color: colors.textTertiary,
                  ),
                ],
              );
              final name = Tooltip(
                message: slice.category,
                child: _text(context, slice.category, 12, maxLines: 2),
              );
              if (_textWidth(context, formatCentToYuan(slice.amountCent), 12) +
                      _textWidth(context, '100.0%', 10) +
                      60 >
                  constraints.maxWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [name, const SizedBox(height: 4), values],
                );
              }
              return Row(
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 8),
                  values,
                ],
              );
            },
          ),
          const SizedBox(height: 5),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fraction.clamp(0, 1),
                backgroundColor: colors.surfaceSubtle,
                color: color,
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatsRankingCard extends StatelessWidget {
  const StatsRankingCard({super.key, required this.items});
  final List<StatsRankItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _text(context, '往来排行', 16, weight: FontWeight.w600),
              ),
              if (items.isNotEmpty)
                _text(
                  context,
                  '前${items.length}位',
                  11,
                  color: colors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: 5),
          _text(context, '按收礼与送礼合计金额排序', 11, color: colors.textTertiary),
          if (items.isEmpty)
            const StatsEmptyMessage(message: '当前时段暂无往来记录')
          else ...[
            const SizedBox(height: 10),
            for (final (index, item) in items.indexed) ...[
              _RankingRow(index: index, item: item),
              if (index < items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 59),
                  child: Divider(height: 1, color: colors.borderSubtle),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.index, required this.item});
  final int index;
  final StatsRankItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = item.personName.trim().isEmpty ? '未知' : item.personName;
    final total = formatCentToYuan(item.totalCent);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              MediaQuery.textScalerOf(context).scale(12) > 14.4 ||
              _textWidth(context, total, 14) > constraints.maxWidth * 0.34;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: name,
                child: _text(
                  context,
                  name,
                  13,
                  weight: FontWeight.w600,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  _text(
                    context,
                    '收 ${formatCentToYuan(item.incomeCent).substring(1)}',
                    11,
                    color: colors.stateSuccess,
                  ),
                  _text(
                    context,
                    '送 ${formatCentToYuan(item.expenseCent).substring(1)}',
                    11,
                    color: colors.stateDanger,
                  ),
                ],
              ),
              if (stacked) ...[
                const SizedBox(height: 5),
                _text(context, total, 14, weight: FontWeight.w600),
              ],
            ],
          );
          return Row(
            children: [
              SizedBox(
                width: 18,
                child: _text(
                  context,
                  '${index + 1}',
                  12,
                  color: colors.textTertiary,
                  weight: FontWeight.w600,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: _text(
                  context,
                  name.characters.first,
                  13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(child: identity),
              if (!stacked) ...[
                const SizedBox(width: 8),
                _text(context, total, 14, weight: FontWeight.w600),
              ],
            ],
          );
        },
      ),
    );
  }
}

class StatsEmptyMessage extends StatelessWidget {
  const StatsEmptyMessage({
    super.key,
    required this.message,
    this.height = 100,
  });
  final String message;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Center(
      child: _text(context, message, 13, color: context.appColors.textTertiary),
    ),
  );
}

String formatStatsRange(StatsDateRange range) {
  final start = range.start;
  final end = range.endExclusive.subtract(const Duration(days: 1));
  if (start.year != end.year) {
    return '${start.year}年${start.month}月${start.day}日 — '
        '${end.year}年${end.month}月${end.day}日';
  }
  return '${start.month}月${start.day}日 — ${end.month}月${end.day}日';
}
