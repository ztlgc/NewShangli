// 统计页 - 重构设计
//
// 视觉设计要点：
// 1. 顶部使用品牌色（indigo 渐变）Hero 卡片，承载核心 KPI（净收支 + 总收/支 + 笔数 + 同比/环比）
// 2. 时间维度切换采用更紧凑的 Segmented Control + 横向滑动 chip
// 3. 趋势图采用「收入/支出/净流量」三态切换的柱状图，弱化双线对比的视觉噪声
// 4. 分类饼图改造为 Donut + 水平进度条列表，信息密度更高
// 5. Top 5 榜单引入 1/2/3 名奖牌、占比进度条，关系人头像占位增强识别度
// 6. 所有颜色、圆角、字号、阴影均使用 AppColors / AppRadii / AppShadows / AppTypography 设计令牌
// 7. 整体信息层级：时间选择 → 总览（Hero）→ 趋势 → 构成 → 关系人
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../lunar_date_picker.dart';
import '../prototype_kit.dart';
import '../stats/stats_view_model.dart';

import '../../stats/stats_db.dart';
import '../../stats/stats_models.dart';
import '../../stats/stats_repository.dart';
import '../../stats/stats_time_range.dart';

/// 统计页专用色板：
/// 收入：teal 色系（与品牌 indigo 互补，且与「入账」语义一致）
/// 支出：暖橙色（突出警示感）
const Color _statsPrimary = Color(0xFF0F766E); // teal700 - 统计页强调色
const Color _statsExpenseColor = Color(0xFFF97316); // orange500
const Color _statsIncomeColor = Color(0xFF14B8A6); // teal500
const Color _statsNetPositiveColor = Color(0xFF0EA5E9); // sky500 - 净收入为正
const Color _statsNetNegativeColor = Color(0xFFE11D48); // rose600 - 净收入为负

final StatsRepository _statsRepository = StatsRepository(db: StatsDb());

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, this.now, this.repository});

  final DateTime Function()? now;
  final IStatsRepository? repository;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StatsViewModel? _vm;
  Object? _boundDatabase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDatabaseScope.of(context);
    if (identical(_boundDatabase, db)) return;
    _vm?.dispose();
    _boundDatabase = db;
    final vm = StatsViewModel(
      repository: widget.repository ?? _statsRepository,
      db: db,
      now: widget.now,
    );
    _vm = vm;
    unawaited(vm.init());
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) {
      return const SizedBox.shrink();
    }
    return ChangeNotifierProvider<StatsViewModel>.value(
      value: vm,
      child: const _StatsPageBody(),
    );
  }
}

/// 顶部 Tab 与 ViewModel 的 preset 不是 1:1 对应：
/// - 月统计/年统计在选择历史月份/历史年份时，会走 preset=custom 来加载指定范围；
/// - 但 UI 仍需要保持停留在原 Tab 上，因此这里单独维护 UI 状态。
enum _StatsUiTab { month, year, custom }

/// 趋势图指标态：
/// - expense：仅显示支出柱
/// - income：仅显示收入柱
/// - net：净流量（收入 - 支出），正值用蓝、负值用红
enum _TrendMetric { expense, income, net }

extension _TrendMetricLabel on _TrendMetric {
  String get label {
    switch (this) {
      case _TrendMetric.expense:
        return '支出';
      case _TrendMetric.income:
        return '收入';
      case _TrendMetric.net:
        return '净流量';
    }
  }

  Color get accent {
    switch (this) {
      case _TrendMetric.expense:
        return _statsExpenseColor;
      case _TrendMetric.income:
        return _statsIncomeColor;
      case _TrendMetric.net:
        return _statsPrimary;
    }
  }
}

class _StatsPageBody extends StatefulWidget {
  const _StatsPageBody();

  @override
  State<_StatsPageBody> createState() => _StatsPageBodyState();
}

class _StatsPageBodyState extends State<_StatsPageBody> {
  _StatsUiTab _tab = _StatsUiTab.month;
  _TrendMetric _trendMetric = _TrendMetric.expense;

  /// 月统计：选中的月份（用该月的 1 号表示）。
  late DateTime _selectedMonthStart;

  /// 年统计：选中的年份；为 null 时表示"所有"。
  int? _selectedYear;

  /// 自定义：用于在页面内展示已选日期范围（与 vm.customRange 同步）。
  StatsDateRange? _customRange;
  bool _rangeCommitScheduled = false;
  Completer<void>? _pendingRangeCompleter;
  Future<void> Function()? _pendingRangeAction;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthStart = DateTime(now.year, now.month, 1);
    _selectedYear = now.year;

    // 自定义默认值：最近 30 天（含当天）。
    // 注意：这里只是 UI 侧默认显示；真正触发数据加载发生在切到"自定义"Tab 时。
    final today = DateTime(now.year, now.month, now.day);
    _customRange = StatsDateRange(
      start: today.subtract(const Duration(days: 29)),
      endExclusive: today.add(const Duration(days: 1)),
    );
  }

  @override
  void dispose() {
    _pendingRangeCompleter?.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatsViewModel>();
    final data = vm.data;
    final compare = vm.compareData;
    final hasData = data != null;

    _customRange ??= vm.customRange;

    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          _Header(
            tab: _tab,
            range: _resolveDisplayedRange(vm),
            compareLabel: _compareLabelForTab(),
            onSelectTab: (t) => unawaited(_handleSelectTab(vm, t)),
          ),
          _SubHeader(
            tab: _tab,
            selectedMonthStart: _selectedMonthStart,
            selectedYear: _selectedYear,
            customRange: _customRange,
            onSelectMonth: (m) => unawaited(_selectMonth(vm, m)),
            onSelectYear: (y) => unawaited(_selectYear(vm, y)),
            onPickCustomStart: () => unawaited(_pickCustomStart(vm)),
            onPickCustomEnd: () => unawaited(_pickCustomEnd(vm)),
          ),
          if (vm.loading && hasData)
            const SizedBox(
              height: 2,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (!hasData && vm.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!hasData && vm.error != null) {
                  return _ErrorPane(
                    message: vm.error!,
                    onRetry: () => unawaited(vm.refresh()),
                  );
                }
                if (!hasData) return const SizedBox.shrink();

                final range = _resolveDisplayedRange(vm);
                final totalCount = _resolveTotalRecordCount(data);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        _KpiHeroCard(
                          range: range,
                          data: data,
                          compare: compare,
                          compareLabel: _compareLabelForTab(),
                          totalCount: totalCount,
                        ),
                        const SizedBox(height: 16),
                        _TrendCard(
                          buckets: data.buckets,
                          range: range,
                          metric: _trendMetric,
                          onChangeMetric: (m) =>
                              setState(() => _trendMetric = m),
                        ),
                        const SizedBox(height: 16),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _CategoryCard(
                                  totalExpenseCent: data.expenseTotalCent,
                                  categories: data.expenseCategories,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TopContactsCard(items: data.ranking),
                              ),
                            ],
                          )
                        else ...[
                          _CategoryCard(
                            totalExpenseCent: data.expenseTotalCent,
                            categories: data.expenseCategories,
                          ),
                          const SizedBox(height: 16),
                          _TopContactsCard(items: data.ranking),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 通过已加载的 buckets 数量推断当前时间范围内的总记录笔数（用于 KPI 卡片展示）。
  ///
  /// 实际数据中 buckets 仅聚合到「天/月/年」粒度，但 recordCount 不会跨桶重复，
  /// 因此 buckets 内的 income/expense 之和可以反推一个粗略的"非空桶计数"。
  /// 这里采用更稳妥的策略：sum(桶内收入+支出 > 0 的数量)，作为"有金额活动的天数/月数"展示。
  int _resolveTotalRecordCount(StatsSnapshot data) {
    var n = 0;
    for (final b in data.buckets) {
      if (b.incomeCent > 0 || b.expenseCent > 0) n++;
    }
    return n;
  }

  StatsDateRange _resolveDisplayedRange(StatsViewModel vm) {
    final now = DateTime.now();
    switch (_tab) {
      case _StatsUiTab.month:
        final s = DateTime(
          _selectedMonthStart.year,
          _selectedMonthStart.month,
          1,
        );
        return StatsDateRange(
          start: s,
          endExclusive: DateTime(s.year, s.month + 1, 1),
        );
      case _StatsUiTab.year:
        final y = _selectedYear;
        if (y == null) {
          final minYear = vm.minRecordYear ?? now.year;
          return StatsDateRange(
            start: DateTime(minYear, 1, 1),
            endExclusive: DateTime(now.year, now.month, now.day + 1),
          );
        }
        return StatsDateRange(
          start: DateTime(y, 1, 1),
          endExclusive: DateTime(y + 1, 1, 1),
        );
      case _StatsUiTab.custom:
        return vm.customRange ??
            _customRange ??
            StatsDateRange(
              start: DateTime(now.year, now.month, 1),
              endExclusive: DateTime(now.year, now.month + 1, 1),
            );
    }
  }

  String _compareLabelForTab() {
    switch (_tab) {
      case _StatsUiTab.month:
        return '较上月';
      case _StatsUiTab.year:
        return _selectedYear == null ? '较上期' : '较去年';
      case _StatsUiTab.custom:
        return '较上期';
    }
  }

  Future<void> _handleSelectTab(StatsViewModel vm, _StatsUiTab tab) async {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    final now = DateTime.now();
    switch (tab) {
      case _StatsUiTab.month:
        _selectedMonthStart = DateTime(now.year, now.month, 1);
        await _scheduleRangeCommit(
          () => vm.setPreset(StatsTimePreset.thisMonth),
        );
      case _StatsUiTab.year:
        _selectedYear = now.year;
        await _scheduleRangeCommit(
          () => vm.setPreset(StatsTimePreset.thisYear),
        );
      case _StatsUiTab.custom:
        final range = _customRange ?? _defaultCustomRange();
        setState(() => _customRange = range);
        await _scheduleRangeCommit(() => vm.setCustomRange(range));
    }
  }

  StatsDateRange _defaultCustomRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return StatsDateRange(
      start: today.subtract(const Duration(days: 29)),
      endExclusive: today.add(const Duration(days: 1)),
    );
  }

  Future<void> _selectMonth(StatsViewModel vm, DateTime monthStart) async {
    final normalized = DateTime(monthStart.year, monthStart.month, 1);
    if (normalized.year == _selectedMonthStart.year &&
        normalized.month == _selectedMonthStart.month) {
      return;
    }
    setState(() => _selectedMonthStart = normalized);
    final now = DateTime.now();
    final isThisMonth =
        monthStart.year == now.year && monthStart.month == now.month;
    if (isThisMonth) {
      await _scheduleRangeCommit(() => vm.setPreset(StatsTimePreset.thisMonth));
      return;
    }
    final s = DateTime(monthStart.year, monthStart.month, 1);
    await _scheduleRangeCommit(
      () => vm.setCustomRange(
        StatsDateRange(
          start: s,
          endExclusive: DateTime(s.year, s.month + 1, 1),
        ),
      ),
    );
  }

  Future<void> _selectYear(StatsViewModel vm, int? year) async {
    if (_selectedYear == year) return;
    setState(() => _selectedYear = year);
    final now = DateTime.now();
    if (year == null) {
      final minYear = vm.minRecordYear ?? now.year;
      await _scheduleRangeCommit(
        () => vm.setCustomRange(
          StatsDateRange(
            start: DateTime(minYear, 1, 1),
            endExclusive: DateTime(now.year, now.month, now.day + 1),
          ),
        ),
      );
      return;
    }
    if (year == now.year) {
      await _scheduleRangeCommit(() => vm.setPreset(StatsTimePreset.thisYear));
      return;
    }
    await _scheduleRangeCommit(
      () => vm.setCustomRange(
        StatsDateRange(
          start: DateTime(year, 1, 1),
          endExclusive: DateTime(year + 1, 1, 1),
        ),
      ),
    );
  }

  Future<void> _scheduleRangeCommit(Future<void> Function() action) {
    _pendingRangeAction = action;
    final existing = _pendingRangeCompleter;
    if (_rangeCommitScheduled && existing != null) {
      return existing.future;
    }

    _pendingRangeCompleter?.complete();
    final completer = Completer<void>();
    _pendingRangeCompleter = completer;
    _rangeCommitScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _rangeCommitScheduled = false;
      final fn = _pendingRangeAction;
      _pendingRangeAction = null;
      try {
        await fn?.call();
      } finally {
        if (identical(_pendingRangeCompleter, completer)) {
          _pendingRangeCompleter = null;
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  Future<void> _pickCustomStart(StatsViewModel vm) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = _customRange ?? vm.customRange ?? _defaultCustomRange();

    // 起始时间的上限不应超过当前的截止时间（含）。
    final currentEndInclusive = existing.endExclusive.subtract(
      const Duration(days: 1),
    );
    final picked = await showLunarDatePicker(
      context: context,
      initialDate: existing.start,
      firstDate: DateTime(now.year - 10, 1, 1),
      lastDate: currentEndInclusive.isBefore(today)
          ? currentEndInclusive
          : today,
    );
    if (picked == null) return;

    final start = DateTime(picked.year, picked.month, picked.day);
    final endInclusive = currentEndInclusive.isBefore(start)
        ? start
        : currentEndInclusive;
    final range = StatsDateRange(
      start: start,
      endExclusive: DateTime(
        endInclusive.year,
        endInclusive.month,
        endInclusive.day + 1,
      ),
    );
    setState(() => _customRange = range);
    await vm.setCustomRange(range);
  }

  Future<void> _pickCustomEnd(StatsViewModel vm) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = _customRange ?? vm.customRange ?? _defaultCustomRange();
    final currentEndInclusive = existing.endExclusive.subtract(
      const Duration(days: 1),
    );

    // 截止时间的下限不应早于起始时间。
    final picked = await showLunarDatePicker(
      context: context,
      initialDate: currentEndInclusive,
      firstDate: existing.start,
      lastDate: today,
    );
    if (picked == null) return;

    final endInclusive = DateTime(picked.year, picked.month, picked.day);
    final start = existing.start.isAfter(endInclusive)
        ? endInclusive
        : existing.start;
    final range = StatsDateRange(
      start: start,
      endExclusive: DateTime(
        endInclusive.year,
        endInclusive.month,
        endInclusive.day + 1,
      ),
    );
    setState(() => _customRange = range);
    await vm.setCustomRange(range);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 顶部 Header：标题 + 时间维度 Segmented Control + 当前范围描述
// ────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.tab,
    required this.range,
    required this.compareLabel,
    required this.onSelectTab,
  });

  final _StatsUiTab tab;
  final StatsDateRange range;
  final String compareLabel;
  final ValueChanged<_StatsUiTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        border: Border(
          bottom: BorderSide(color: colors.borderDivider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '统计',
                style: AppTypography.base(
                  fontSize: 22,
                  fontWeight: AppTypography.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  _formatRange(range),
                  style: AppTypography.base(
                    fontSize: 11,
                    fontWeight: AppTypography.medium,
                    color: colors.brandOnSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SegmentedControl(active: tab, onSelect: onSelectTab),
        ],
      ),
    );
  }

  String _formatRange(StatsDateRange r) {
    final start = r.start;
    final end = r.endExclusive.subtract(const Duration(days: 1));
    final sM = start.month.toString().padLeft(2, '0');
    final sD = start.day.toString().padLeft(2, '0');
    final eM = end.month.toString().padLeft(2, '0');
    final eD = end.day.toString().padLeft(2, '0');
    if (start.year == end.year) {
      if (start.month == end.month && start.day == end.day) {
        return '$sM月$sD日';
      }
      return '$sM月$sD日 - $eM月$eD日';
    }
    return '${start.year}年$sM月$sD日 - ${end.year}年$eM月$eD日';
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.active, required this.onSelect});

  final _StatsUiTab active;
  final ValueChanged<_StatsUiTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget item(_StatsUiTab t, String label, IconData icon) {
      final selected = active == t;
      return Expanded(
        child: PressableScale(
          onTap: () => onSelect(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _statsPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  icon,
                  size: 13,
                  color: selected ? colors.textInverse : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.semibold,
                    color: selected ? colors.textInverse : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          item(_StatsUiTab.month, '月统计', FontAwesomeIcons.calendarDay),
          item(_StatsUiTab.year, '年统计', FontAwesomeIcons.calendar),
          item(_StatsUiTab.custom, '自定义', FontAwesomeIcons.sliders),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SubHeader：根据 tab 切换显示月选择器 / 年选择器 / 自定义日期范围
// ────────────────────────────────────────────────────────────────────────────

class _SubHeader extends StatelessWidget {
  const _SubHeader({
    required this.tab,
    required this.selectedMonthStart,
    required this.selectedYear,
    required this.customRange,
    required this.onSelectMonth,
    required this.onSelectYear,
    required this.onPickCustomStart,
    required this.onPickCustomEnd,
  });

  final _StatsUiTab tab;
  final DateTime selectedMonthStart;
  final int? selectedYear;
  final StatsDateRange? customRange;
  final ValueChanged<DateTime> onSelectMonth;
  final ValueChanged<int?> onSelectYear;
  final VoidCallback onPickCustomStart;
  final VoidCallback onPickCustomEnd;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _StatsUiTab.month:
        return _MonthSelector(
          selectedMonthStart: selectedMonthStart,
          onSelectMonth: onSelectMonth,
        );
      case _StatsUiTab.year:
        return _YearSelector(
          selectedYear: selectedYear,
          onSelectYear: onSelectYear,
        );
      case _StatsUiTab.custom:
        return _CustomRangeSelector(
          range: customRange,
          onPickStart: onPickCustomStart,
          onPickEnd: onPickCustomEnd,
        );
    }
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedMonthStart,
    required this.onSelectMonth,
  });

  final DateTime selectedMonthStart;
  final ValueChanged<DateTime> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final colors = context.appColors;
    final options = <DateTime>[];
    for (var i = 0; i < 18; i++) {
      options.add(DateTime(now.year, now.month - i, 1));
    }

    Widget chip(DateTime m) {
      final selected =
          m.year == selectedMonthStart.year &&
          m.month == selectedMonthStart.month;
      final isThisMonth = m.year == now.year && m.month == now.month;
      final isPrevMonth =
          DateTime(now.year, now.month - 1, 1).year == m.year &&
          DateTime(now.year, now.month - 1, 1).month == m.month;
      final label = isThisMonth ? '本月' : (isPrevMonth ? '上月' : '${m.month}月');
      return PressableScale(
        onTap: () => onSelectMonth(m),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _statsPrimary : colors.surfaceCard,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: selected ? _statsPrimary : colors.borderDefault,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.base(
                fontSize: 13,
                fontWeight: AppTypography.semibold,
                color: selected ? colors.textInverse : colors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: colors.surfaceApp,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Text(
            '${selectedMonthStart.year}年',
            style: AppTypography.base(
              fontSize: 15,
              fontWeight: AppTypography.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [for (final m in options) chip(m)]),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({required this.selectedYear, required this.onSelectYear});

  final int? selectedYear;
  final ValueChanged<int?> onSelectYear;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final colors = context.appColors;
    final years = <int>[for (var i = 0; i < 8; i++) now.year - i];

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return PressableScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _statsPrimary : colors.surfaceCard,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: selected ? _statsPrimary : colors.borderDefault,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.base(
                fontSize: 13,
                fontWeight: AppTypography.semibold,
                color: selected ? colors.textInverse : colors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: colors.surfaceApp,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(
              label: '所有',
              selected: selectedYear == null,
              onTap: () => onSelectYear(null),
            ),
            chip(
              label: '今年',
              selected: selectedYear == now.year,
              onTap: () => onSelectYear(now.year),
            ),
            chip(
              label: '去年',
              selected: selectedYear == now.year - 1,
              onTap: () => onSelectYear(now.year - 1),
            ),
            for (final y in years.skip(2))
              chip(
                label: '$y年',
                selected: selectedYear == y,
                onTap: () => onSelectYear(y),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomRangeSelector extends StatelessWidget {
  const _CustomRangeSelector({
    required this.range,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final StatsDateRange? range;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final r = range;
    final colors = context.appColors;
    final startText = r == null ? '请选择' : _fmtCnDate(r.start);
    final endText = r == null
        ? '请选择'
        : _fmtCnDate(r.endExclusive.subtract(const Duration(days: 1)));
    return Container(
      color: colors.surfaceApp,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _DateCell(
              icon: FontAwesomeIcons.play,
              label: '起始',
              value: startText,
              onTap: onPickStart,
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FaIcon(
              FontAwesomeIcons.arrowRight,
              size: 12,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateCell(
              icon: FontAwesomeIcons.stop,
              label: '截止',
              value: endText,
              onTap: onPickEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderDefault, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.brandSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: FaIcon(icon, size: 12, color: colors.brandOnSoft),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.base(
                      fontSize: 10,
                      fontWeight: AppTypography.regular,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.base(
                      fontSize: 13,
                      fontWeight: AppTypography.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Hero KPI 卡片：渐变背景 + 净收支 + 总收/支 + 同比/环比 + 笔数
// ────────────────────────────────────────────────────────────────────────────

class _KpiHeroCard extends StatelessWidget {
  const _KpiHeroCard({
    required this.range,
    required this.data,
    required this.compare,
    required this.compareLabel,
    required this.totalCount,
  });

  final StatsDateRange range;
  final StatsSnapshot data;
  final StatsSnapshot? compare;
  final String compareLabel;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final net = data.incomeTotalCent - data.expenseTotalCent;

    final compareExpense = compare?.expenseTotalCent;
    final compareIncome = compare?.incomeTotalCent;
    final compareNet = compare == null
        ? null
        : (compare!.incomeTotalCent - compare!.expenseTotalCent);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
        ),
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.lg,
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：标签 + 净收支
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      net >= 0
                          ? FontAwesomeIcons.arrowTrendUp
                          : FontAwesomeIcons.arrowTrendDown,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '净收支',
                      style: AppTypography.base(
                        fontSize: 11,
                        fontWeight: AppTypography.medium,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FaIcon(
                FontAwesomeIcons.chartPie,
                size: 14,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCentToYuan(net),
              maxLines: 1,
              style: AppTypography.base(
                fontSize: 34,
                height: 1.0,
                fontWeight: AppTypography.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            net >= 0 ? '本期有盈余' : '本期有支出缺口',
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.regular,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          // 分隔线
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 14),
          // 支出 / 收入 双列
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  icon: FontAwesomeIcons.arrowUp,
                  iconColor: _statsExpenseColor,
                  label: '总支出',
                  value: formatCentToYuan(data.expenseTotalCent),
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _MetricColumn(
                  icon: FontAwesomeIcons.arrowDown,
                  iconColor: _statsIncomeColor,
                  label: '总收入',
                  value: formatCentToYuan(data.incomeTotalCent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 同比/环比 + 笔数
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DeltaChip(
                label: '$compareLabel 支出',
                delta: _computeDeltaPct(compareExpense, data.expenseTotalCent),
                invertColor: true,
              ),
              _DeltaChip(
                label: '$compareLabel 收入',
                delta: _computeDeltaPct(compareIncome, data.incomeTotalCent),
              ),
              _DeltaChip(
                label: '$compareLabel 净',
                delta: _computeDeltaPct(compareNet, net),
                invertColor: true,
              ),
              _CountChip(
                icon: FontAwesomeIcons.list,
                label: '有金额活动',
                value: '$totalCount 个时段',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 计算百分比变化。返回值在 -1.0 ~ +∞ 区间。
  /// 上一期为 0、当前为 0：返回 0
  /// 上一期为 0、当前非 0：返回 double.infinity（用 +∞ 表示"新增"）
  double? _computeDeltaPct(int? prev, int cur) {
    if (prev == null) return null;
    if (prev == 0) return cur == 0 ? 0 : double.infinity;
    return ((cur - prev) * 1.0) / prev.abs();
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: FaIcon(icon, size: 10, color: iconColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.medium,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: AppTypography.base(
              fontSize: 18,
              height: 1.0,
              fontWeight: AppTypography.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// 同比/环比变化 chip：
/// - invertColor：true 表示"增长是坏消息"（如支出上升），此时用红；
///               false 表示"增长是好消息"（如收入上升），此时用绿。
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.label,
    required this.delta,
    this.invertColor = false,
  });

  final String label;
  final double? delta;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    final v = delta;
    Color bg = Colors.white.withValues(alpha: 0.1);
    Color fg = Colors.white.withValues(alpha: 0.85);
    IconData icon = FontAwesomeIcons.minus;
    String text = '—';
    if (v == null) {
      text = '无对比';
      icon = FontAwesomeIcons.minus;
      fg = Colors.white.withValues(alpha: 0.5);
    } else if (v == 0) {
      text = '持平';
      icon = FontAwesomeIcons.equals;
    } else if (v.isInfinite) {
      text = '新增';
      icon = FontAwesomeIcons.burst;
    } else {
      final pct = (v * 100).toStringAsFixed(0);
      final up = v > 0;
      text = '${up ? '+' : ''}$pct%';
      icon = up ? FontAwesomeIcons.caretUp : FontAwesomeIcons.caretDown;
      // 默认：上涨=好；invertColor：上涨=坏
      final positive = invertColor ? !up : up;
      if (positive) {
        bg = const Color(0xFF064E3B); // emerald900
        fg = const Color(0xFF6EE7B7); // emerald300
      } else {
        bg = const Color(0xFF7F1D1D); // red900
        fg = const Color(0xFFFCA5A5); // red300
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.base(
              fontSize: 11,
              fontWeight: AppTypography.medium,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.base(
              fontSize: 11,
              fontWeight: AppTypography.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.base(
              fontSize: 11,
              fontWeight: AppTypography.medium,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.base(
              fontSize: 11,
              fontWeight: AppTypography.bold,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 趋势图：单指标柱状图 + 状态切换器
// ────────────────────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.buckets,
    required this.range,
    required this.metric,
    required this.onChangeMetric,
  });

  final List<StatsBarBucket> buckets;
  final StatsDateRange range;
  final _TrendMetric metric;
  final ValueChanged<_TrendMetric> onChangeMetric;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final values = buckets.map(_valueFor).toList();
    var maxAbs = 0.0;
    for (final v in values) {
      if (v.abs() > maxAbs) maxAbs = v.abs();
    }
    if (maxAbs <= 0) maxAbs = 1;

    final positiveColor = _statsNetPositiveColor;
    final negativeColor = _statsNetNegativeColor;
    final showEvery = buckets.length <= 12
        ? 1
        : (buckets.length <= 24 ? 2 : (buckets.length <= 36 ? 3 : 6));

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '收支趋势',
                style: AppTypography.base(
                  fontSize: 16,
                  fontWeight: AppTypography.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '共 ${buckets.length} 个时段',
                style: AppTypography.base(
                  fontSize: 11,
                  fontWeight: AppTypography.regular,
                  color: colors.textMuted,
                ),
              ),
              const Spacer(),
              _TrendMetricSegment(value: metric, onChange: onChangeMetric),
            ],
          ),
          const SizedBox(height: 16),
          if (buckets.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  '当前范围内暂无数据',
                  style: AppTypography.base(
                    fontSize: 13,
                    fontWeight: AppTypography.regular,
                    color: colors.textMuted,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                duration: Duration.zero,
                BarChartData(
                  minY: metric == _TrendMetric.net ? -maxAbs * 1.15 : 0,
                  maxY: metric == _TrendMetric.net
                      ? maxAbs * 1.15
                      : maxAbs * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _niceInterval(maxAbs),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colors.borderSubtle,
                      strokeWidth: 1,
                      dashArray: const [3, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF111827),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      getTooltipItem: (group, gIdx, rod, rIdx) {
                        final bucket = buckets[group.x];
                        final v = _valueFor(bucket);
                        return BarTooltipItem(
                          '${bucket.label}\n${formatCentToYuan(v.toInt())}',
                          AppTypography.base(
                            fontSize: 12,
                            fontWeight: AppTypography.semibold,
                            color: colors.textInverse,
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (metric == _TrendMetric.net) {
                            if (value == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  '0',
                                  style: AppTypography.base(
                                    fontSize: 10,
                                    fontWeight: AppTypography.regular,
                                    color: colors.textMuted,
                                  ),
                                ),
                              );
                            }
                            return Text(
                              value.toInt().toString(),
                              style: AppTypography.base(
                                fontSize: 10,
                                fontWeight: AppTypography.regular,
                                color: colors.textMuted,
                              ),
                            );
                          }
                          return Text(
                            value.toInt().toString(),
                            style: AppTypography.base(
                              fontSize: 10,
                              fontWeight: AppTypography.regular,
                              color: colors.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          if (idx % showEvery != 0 &&
                              idx != buckets.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              buckets[idx].label,
                              style: AppTypography.base(
                                fontSize: 10,
                                fontWeight: AppTypography.regular,
                                color: colors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < buckets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: metric == _TrendMetric.net
                                ? values[i]
                                : values[i].abs(),
                            color: _colorFor(
                              values[i],
                              metric,
                              positiveColor,
                              negativeColor,
                            ),
                            width: buckets.length > 24 ? 6 : 10,
                            borderRadius: BorderRadius.circular(3),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: metric == _TrendMetric.net,
                              toY: 0,
                              color: colors.surfaceSubtle,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _valueFor(StatsBarBucket b) {
    switch (metric) {
      case _TrendMetric.expense:
        return b.expenseCent / 100.0;
      case _TrendMetric.income:
        return b.incomeCent / 100.0;
      case _TrendMetric.net:
        return (b.incomeCent - b.expenseCent) / 100.0;
    }
  }

  Color _colorFor(
    double value,
    _TrendMetric m,
    Color positiveColor,
    Color negativeColor,
  ) {
    switch (m) {
      case _TrendMetric.expense:
        return _statsExpenseColor;
      case _TrendMetric.income:
        return _statsIncomeColor;
      case _TrendMetric.net:
        return value >= 0 ? positiveColor : negativeColor;
    }
  }

  double _niceInterval(double maxValue) {
    if (maxValue <= 0) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 50) return 10;
    if (maxValue <= 200) return 50;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 5000) return 1000;
    return 2000;
  }
}

class _TrendMetricSegment extends StatelessWidget {
  const _TrendMetricSegment({required this.value, required this.onChange});

  final _TrendMetric value;
  final ValueChanged<_TrendMetric> onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget item(_TrendMetric v) {
      final selected = value == v;
      return PressableScale(
        onTap: () => onChange(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? v.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            v.label,
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.semibold,
              color: selected ? colors.textInverse : colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(_TrendMetric.expense),
          item(_TrendMetric.income),
          item(_TrendMetric.net),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 类别分布：Donut + Top 类别水平进度条列表
// ────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.totalExpenseCent,
    required this.categories,
  });

  final int totalExpenseCent;
  final List<StatsCategorySlice> categories;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // 饼图尺寸：缩小到约原大小的 75%，避免在分类卡片中视觉占比过重
    const pieSize = 100.0;
    const pieRadius = 38.0;
    const pieCenterSpaceRadius = 26.0;

    final palette = <Color>[
      const Color(0xFF4F46E5), // indigo600
      const Color(0xFF14B8A6), // teal500
      const Color(0xFFF97316), // orange500
      const Color(0xFFEC4899), // pink500
      const Color(0xFF3B82F6), // blue500
      const Color(0xFFA855F7), // purple500
      const Color(0xFFEAB308), // yellow500
      const Color(0xFF22C55E), // green500
    ];

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < categories.length; i++) {
      final c = categories[i];
      final isOther = c.category == '其他';
      final color = isOther
          ? colors.neutralAccent
          : palette[i % palette.length];
      sections.add(
        PieChartSectionData(
          value: c.amountCent.toDouble(),
          color: color,
          radius: pieRadius,
          title: '',
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '支出分类',
                style: AppTypography.base(
                  fontSize: 16,
                  fontWeight: AppTypography.bold,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.orangeSoft,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'TOP ${categories.length}',
                  style: AppTypography.base(
                    fontSize: 10,
                    fontWeight: AppTypography.bold,
                    color: colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: pieSize,
                height: pieSize,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PieChart(
                        duration: Duration.zero,
                        PieChartData(
                          sections: sections.isEmpty
                              ? [
                                  PieChartSectionData(
                                    value: 1,
                                    color: colors.surfaceDisabled,
                                    radius: pieRadius,
                                    title: '',
                                  ),
                                ]
                              : sections,
                          centerSpaceRadius: pieCenterSpaceRadius,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '总支出',
                            style: AppTypography.base(
                              fontSize: 10,
                              fontWeight: AppTypography.regular,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatCentToYuan(totalExpenseCent),
                              style: AppTypography.base(
                                fontSize: 13,
                                fontWeight: AppTypography.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < categories.length && i < 5; i++) ...[
                      _CategoryProgressRow(
                        color: categories[i].category == '其他'
                            ? colors.neutralAccent
                            : palette[i % palette.length],
                        label: categories[i].category,
                        amountCent: categories[i].amountCent,
                        totalCent: totalExpenseCent,
                      ),
                      if (i !=
                          (categories.length < 5 ? categories.length - 1 : 4))
                        const SizedBox(height: 10),
                    ],
                    if (categories.length > 5) ...[
                      const SizedBox(height: 6),
                      Text(
                        '还有 ${categories.length - 5} 项',
                        style: AppTypography.base(
                          fontSize: 11,
                          fontWeight: AppTypography.regular,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({
    required this.color,
    required this.label,
    required this.amountCent,
    required this.totalCent,
  });

  final Color color;
  final String label;
  final int amountCent;
  final int totalCent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pct = totalCent <= 0 ? 0.0 : (amountCent / totalCent).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.base(
                  fontSize: 12,
                  fontWeight: AppTypography.medium,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: AppTypography.base(
                fontSize: 11,
                fontWeight: AppTypography.bold,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: colors.surfaceSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatCentToYuan(amountCent),
          style: AppTypography.base(
            fontSize: 10,
            fontWeight: AppTypography.regular,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Top 5 关系人：奖牌 + 姓名 + 占比进度条 + 净收/支
// ────────────────────────────────────────────────────────────────────────────

class _TopContactsCard extends StatelessWidget {
  const _TopContactsCard({required this.items});

  final List<StatsRankItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '人情榜单',
                style: AppTypography.base(
                  fontSize: 16,
                  fontWeight: AppTypography.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Top ${items.length}',
                style: AppTypography.base(
                  fontSize: 11,
                  fontWeight: AppTypography.regular,
                  color: colors.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '按总流水',
                  style: AppTypography.base(
                    fontSize: 10,
                    fontWeight: AppTypography.bold,
                    color: colors.brandOnSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '当前范围内暂无数据',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: colors.textMuted,
                  ),
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                // 取当前榜单中最大总流水作为进度条基准。
                var maxTotal = 0;
                for (final it in items) {
                  if (it.totalCent > maxTotal) maxTotal = it.totalCent;
                }
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      _TopContactRow(
                        index: i,
                        item: items[i],
                        maxTotal: maxTotal,
                      ),
                      if (i != items.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Divider(
                            color: colors.borderSubtle,
                            height: 14,
                          ),
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
}

class _TopContactRow extends StatelessWidget {
  const _TopContactRow({
    required this.index,
    required this.item,
    required this.maxTotal,
  });

  final int index;
  final StatsRankItem item;
  final int maxTotal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pct = maxTotal <= 0
        ? 0.0
        : (item.totalCent / maxTotal).clamp(0.0, 1.0);
    final net = item.netCent;
    final netColor = net >= 0 ? _statsNetPositiveColor : _statsNetNegativeColor;
    final netBg = net >= 0 ? const Color(0xFFE0F2FE) : const Color(0xFFFFE4E6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RankBadge(index: index),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.personName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.semibold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: netBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${net >= 0 ? '+' : '-'}${formatCentToYuan(net.abs()).replaceFirst('¥', '')}',
                      style: AppTypography.base(
                        fontSize: 11,
                        fontWeight: AppTypography.bold,
                        color: netColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: colors.surfaceSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _statsPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '收 ${formatCentToYuan(item.incomeCent).replaceFirst('¥', '')}',
                    style: AppTypography.base(
                      fontSize: 10,
                      fontWeight: AppTypography.regular,
                      color: _statsIncomeColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '支 ${formatCentToYuan(item.expenseCent).replaceFirst('¥', '')}',
                    style: AppTypography.base(
                      fontSize: 10,
                      fontWeight: AppTypography.regular,
                      color: _statsExpenseColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rank = index + 1;
    late Color bg;
    late Color fg;
    late IconData? icon;
    switch (rank) {
      case 1:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = FontAwesomeIcons.crown;
        break;
      case 2:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        icon = FontAwesomeIcons.medal;
        break;
      case 3:
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFB45309);
        icon = FontAwesomeIcons.award;
        break;
      default:
        bg = colors.surfaceSubtle;
        fg = colors.textSecondary;
        icon = null;
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? FaIcon(icon, size: 12, color: fg)
          : Text(
              '$rank',
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.bold,
                color: fg,
              ),
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 错误态
// ────────────────────────────────────────────────────────────────────────────

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.stateDangerSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 22,
                color: colors.stateDangerStrong,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '加载失败',
              style: AppTypography.base(
                fontSize: 16,
                fontWeight: AppTypography.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.regular,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            PrototypePrimaryButton(label: '重试', onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 工具方法
// ────────────────────────────────────────────────────────────────────────────

String _fmtCnDate(DateTime dt) {
  final y = dt.year;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y年$m月$d日';
}
