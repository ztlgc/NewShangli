import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../app_tokens.dart';
import '../app_data.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../lunar_date_picker.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../stats/stats_view_model.dart';
import '../../utils/date_util.dart';
import '../../stats/stats_db.dart';
import '../../stats/stats_models.dart';
import '../../stats/stats_repository.dart';
import '../../stats/stats_time_range.dart';
import 'data_export_page.dart';
import 'person_list_page.dart';
import 'record_home_page.dart';
import 'settings_home_page.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final appData = AppDataScope.of(context);
    final vm = StatsViewModel(repository: widget.repository ?? _statsRepository, appData: appData, now: widget.now);
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

/// 统计页顶部 Tab：
/// - 月统计：按月维度筛选，并在下方提供月份快捷切换
/// - 年统计：按年维度筛选，并在下方提供年份快捷切换
/// - 自定义：用户指定起止日期
enum _StatsUiTab { month, year, custom }

enum _StatsMetric { expense, income }

extension _StatsMetricText on _StatsMetric {
  String get label {
    switch (this) {
      case _StatsMetric.expense:
        return '支出';
      case _StatsMetric.income:
        return '收入';
    }
  }
}

class _StatsPageBody extends StatefulWidget {
  const _StatsPageBody();

  @override
  State<_StatsPageBody> createState() => _StatsPageBodyState();
}

class _StatsPageBodyState extends State<_StatsPageBody> {
  /// 注意：页面的「顶部 Tab」与 ViewModel 的 preset 不是 1:1 对应关系。
  ///
  /// - 月统计/年统计在选择历史月份/历史年份时，会走 preset=custom 来加载指定范围；
  /// - 但 UI 仍需要保持停留在“月统计/年统计”Tab 上。
  ///
  /// 因此这里额外维护一个 _tab 作为纯 UI 状态。
  _StatsUiTab _tab = _StatsUiTab.month;
  _StatsMetric _metric = _StatsMetric.expense;
  bool _kpiExpanded = false;

  /// 月统计：选中的月份（用该月的 1 号表示）。
  late DateTime _selectedMonthStart;

  /// 年统计：选中的年份；为 null 时表示“所有”。
  int? _selectedYear;

  /// 自定义：用于在页面内展示已选日期范围（与 vm.customRange 同步）。
  StatsDateRange? _customRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthStart = DateTime(now.year, now.month, 1);
    _selectedYear = now.year;

    // 自定义默认值：最近 30 天（含当天）。
    // 注意：这里只是 UI 侧默认显示；真正触发数据加载发生在切到“自定义”Tab 时。
    final today = DateTime(now.year, now.month, now.day);
    _customRange = StatsDateRange(
      start: today.subtract(const Duration(days: 29)),
      endExclusive: today.add(const Duration(days: 1)),
    );
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
          _TopBar(
            tab: _tab,
            onSelectTab: (t) => unawaited(_handleSelectTab(vm, t)),
            onOpenMenu: () => unawaited(_openMenu(vm)),
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
                  return _ErrorPane(message: vm.error!, onRetry: () => unawaited(vm.refresh()));
                }
                if (!hasData) return const SizedBox.shrink();

                final range = _resolveDisplayedRange(vm);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final list = ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        _KpiSummaryCard(
                          range: range,
                          data: data,
                          compare: compare,
                          compareLabel: _compareLabelForTab(),
                          expanded: _kpiExpanded,
                          onToggleExpanded: () => setState(() => _kpiExpanded = !_kpiExpanded),
                        ),
                        const SizedBox(height: 16),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _TrendLineCard(buckets: data.buckets, range: range)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HistogramCard(
                                  buckets: data.buckets,
                                  metric: _metric,
                                  onChangeMetric: (m) => setState(() => _metric = m),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _TrendLineCard(buckets: data.buckets, range: range),
                          const SizedBox(height: 16),
                          _HistogramCard(
                            buckets: data.buckets,
                            metric: _metric,
                            onChangeMetric: (m) => setState(() => _metric = m),
                          ),
                        ],
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
                              Expanded(child: _TopCard(items: data.ranking)),
                            ],
                          )
                        else ...[
                          _CategoryCard(
                            totalExpenseCent: data.expenseTotalCent,
                            categories: data.expenseCategories,
                          ),
                          const SizedBox(height: 16),
                          _TopCard(items: data.ranking),
                        ],
                      ],
                    );
                    return list;
                  },
                );
              },
            ),
          ),
          PrototypeBottomNav(
            activeIndex: 2,
            onTap: (index) {
              if (index == 2) return;
              if (index == 0) {
                AppNav.replaceRoot(context, const RecordHomePage());
                return;
              }
              if (index == 1) {
                AppNav.replaceRoot(context, const PersonListPage());
                return;
              }
              if (index == 3) {
                AppNav.replaceRoot(context, const SettingsHomePage());
                return;
              }
            },
          ),
        ],
      ),
    );
  }

  StatsDateRange _resolveDisplayedRange(StatsViewModel vm) {
    final now = DateTime.now();
    switch (_tab) {
      case _StatsUiTab.month:
        final s = DateTime(_selectedMonthStart.year, _selectedMonthStart.month, 1);
        return StatsDateRange(start: s, endExclusive: DateTime(s.year, s.month + 1, 1));
      case _StatsUiTab.year:
        final y = _selectedYear;
        if (y == null) {
          final minYear = _minRecordYear(context) ?? now.year;
          return StatsDateRange(
            start: DateTime(minYear, 1, 1),
            endExclusive: DateTime(now.year, now.month, now.day + 1),
          );
        }
        return StatsDateRange(start: DateTime(y, 1, 1), endExclusive: DateTime(y + 1, 1, 1));
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
    setState(() => _tab = tab);
    final now = DateTime.now();
    switch (tab) {
      case _StatsUiTab.month:
        /// 月统计：默认定位到本月
        _selectedMonthStart = DateTime(now.year, now.month, 1);
        await vm.setPreset(StatsTimePreset.thisMonth);
      case _StatsUiTab.year:
        /// 年统计：默认定位到今年
        _selectedYear = now.year;
        await vm.setPreset(StatsTimePreset.thisYear);
      case _StatsUiTab.custom:
        // 自定义：不再直接跳转/弹出范围选择页面。
        // 用户通过下方“起始时间/截止时间”来分别选择日期。
        final range = _customRange ?? _defaultCustomRange();
        setState(() => _customRange = range);
        await vm.setCustomRange(range);
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
    setState(() => _selectedMonthStart = DateTime(monthStart.year, monthStart.month, 1));
    final now = DateTime.now();
    final isThisMonth = monthStart.year == now.year && monthStart.month == now.month;
    if (isThisMonth) {
      await vm.setPreset(StatsTimePreset.thisMonth);
      return;
    }
    final s = DateTime(monthStart.year, monthStart.month, 1);
    await vm.setCustomRange(StatsDateRange(start: s, endExclusive: DateTime(s.year, s.month + 1, 1)));
  }

  Future<void> _selectYear(StatsViewModel vm, int? year) async {
    setState(() => _selectedYear = year);
    final now = DateTime.now();
    if (year == null) {
      final minYear = _minRecordYear(context) ?? now.year;
      await vm.setCustomRange(
        StatsDateRange(
          start: DateTime(minYear, 1, 1),
          endExclusive: DateTime(now.year, now.month, now.day + 1),
        ),
      );
      return;
    }
    if (year == now.year) {
      await vm.setPreset(StatsTimePreset.thisYear);
      return;
    }
    await vm.setCustomRange(StatsDateRange(start: DateTime(year, 1, 1), endExclusive: DateTime(year + 1, 1, 1)));
  }

  Future<void> _pickCustomStart(StatsViewModel vm) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = _customRange ?? vm.customRange ?? _defaultCustomRange();

    // 起始时间的上限不应超过当前的截止时间（含）。
    final currentEndInclusive = existing.endExclusive.subtract(const Duration(days: 1));
    final picked = await showLunarDatePicker(
      context: context,
      initialDate: existing.start,
      firstDate: DateTime(now.year - 10, 1, 1),
      lastDate: currentEndInclusive.isBefore(today) ? currentEndInclusive : today,
    );
    if (picked == null) return;

    final start = DateTime(picked.year, picked.month, picked.day);
    final endInclusive = currentEndInclusive.isBefore(start) ? start : currentEndInclusive;
    final range = StatsDateRange(
      start: start,
      endExclusive: DateTime(endInclusive.year, endInclusive.month, endInclusive.day + 1),
    );
    setState(() => _customRange = range);
    await vm.setCustomRange(range);
  }

  Future<void> _pickCustomEnd(StatsViewModel vm) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = _customRange ?? vm.customRange ?? _defaultCustomRange();
    final currentEndInclusive = existing.endExclusive.subtract(const Duration(days: 1));

    // 截止时间的下限不应早于起始时间。
    final picked = await showLunarDatePicker(
      context: context,
      initialDate: currentEndInclusive,
      firstDate: existing.start,
      lastDate: today,
    );
    if (picked == null) return;

    final endInclusive = DateTime(picked.year, picked.month, picked.day);
    final start = existing.start.isAfter(endInclusive) ? endInclusive : existing.start;
    final range = StatsDateRange(
      start: start,
      endExclusive: DateTime(endInclusive.year, endInclusive.month, endInclusive.day + 1),
    );
    setState(() => _customRange = range);
    await vm.setCustomRange(range);
  }

  int? _minRecordYear(BuildContext context) {
    final appData = AppDataScope.of(context);
    if (appData.records.isEmpty) return null;
    var minYear = appData.records.first.occurredAt.year;
    for (final r in appData.records) {
      final y = r.occurredAt.year;
      if (y < minYear) minYear = y;
    }
    return minYear;
  }

  Future<void> _openMenu(StatsViewModel vm) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('更多', style: AppTypography.h2().copyWith(fontSize: 16)),
              ),
              PrototypePressableRow(
                onTap: () => Navigator.of(context).pop('refresh'),
                child: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('刷新'),
                  ],
                ),
              ),
              PrototypePressableRow(
                onTap: () => Navigator.of(context).pop('export'),
                child: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.fileExport, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('导出数据'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (!mounted) return;
    if (picked == 'refresh') {
      await vm.refresh();
      return;
    }
    if (picked == 'export') {
      AppNav.push(context, const DataExportPage());
      return;
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.tab,
    required this.onSelectTab,
    required this.onOpenMenu,
  });

  final _StatsUiTab tab;
  final ValueChanged<_StatsUiTab> onSelectTab;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TopTabs(
              active: tab,
              onSelect: onSelectTab,
            ),
          ),
          const SizedBox(width: 8),
          PrototypeIconButton(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16),
            backgroundColor: AppColors.gray100,
            foregroundColor: AppColors.textSecondary,
            onPressed: onOpenMenu,
          ),
        ],
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({
    required this.active,
    required this.onSelect,
  });

  final _StatsUiTab active;
  final ValueChanged<_StatsUiTab> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tabItem(_StatsUiTab t, String label) {
      final selected = active == t;
      return PressableScale(
        onTap: () => onSelect(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandSecondary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppTypography.base(
              fontSize: 16,
              fontWeight: AppTypography.medium,
              color: selected ? AppColors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          tabItem(_StatsUiTab.month, '月统计'),
          const SizedBox(width: 10),
          tabItem(_StatsUiTab.year, '年统计'),
          const SizedBox(width: 10),
          tabItem(_StatsUiTab.custom, '自定义'),
        ],
      ),
    );
  }
}

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
    final options = <DateTime>[];
    for (var i = 0; i < 18; i++) {
      options.add(DateTime(now.year, now.month - i, 1));
    }

    Widget chip(DateTime m) {
      final selected = m.year == selectedMonthStart.year && m.month == selectedMonthStart.month;
      final isThisMonth = m.year == now.year && m.month == now.month;
      final isPrevMonth = DateTime(now.year, now.month - 1, 1).year == m.year &&
          DateTime(now.year, now.month - 1, 1).month == m.month;
      final label = isThisMonth ? '本月' : (isPrevMonth ? '上月' : '${m.month}月');
      return PressableScale(
        onTap: () => onSelectMonth(m),
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: PrototypePill(
            label: label,
            background: selected ? AppColors.brandSecondary : Colors.transparent,
            foreground: selected ? AppColors.white : AppColors.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            fontSize: 16,
            fontWeight: AppTypography.medium,
            radius: 10,
          ),
        ),
      );
    }

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Text(
            '${selectedMonthStart.year}',
            style: AppTypography.base(
              fontSize: 18,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
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
  const _YearSelector({
    required this.selectedYear,
    required this.onSelectYear,
  });

  final int? selectedYear;
  final ValueChanged<int?> onSelectYear;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = <int>[for (var i = 0; i < 8; i++) now.year - i];

    Widget chip({required String label, required bool selected, required VoidCallback onTap}) {
      return PressableScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: PrototypePill(
            label: label,
            background: selected ? AppColors.brandSecondary : Colors.transparent,
            foreground: selected ? AppColors.white : AppColors.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            fontSize: 16,
            fontWeight: AppTypography.medium,
            radius: 10,
          ),
        ),
      );
    }

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
    final startText = r == null ? '--' : _fmtCnDate(r.start);
    final endText = r == null ? '--' : _fmtCnDate(r.endExclusive.subtract(const Duration(days: 1)));
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateCell(
                  label: '起始时间',
                  value: startText,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateCell(
                  label: '截止时间',
                  value: endText,
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiSummaryCard extends StatelessWidget {
  const _KpiSummaryCard({
    required this.range,
    required this.data,
    required this.compare,
    required this.compareLabel,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final StatsDateRange range;
  final StatsSnapshot data;
  final StatsSnapshot? compare;
  final String compareLabel;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final days = range.endExclusive.difference(range.start).inDays;
    final dayCount = days <= 0 ? 1 : days;

    final avgExpense = data.expenseTotalCent ~/ dayCount;
    final avgIncome = data.incomeTotalCent ~/ dayCount;

    final compareExpense = compare?.expenseTotalCent;
    final compareIncome = compare?.incomeTotalCent;

    String formatDelta(int? prev, int cur) {
      if (prev == null) return '--';
      if (prev == 0) return cur == 0 ? '0%' : '∞';
      final pct = ((cur - prev) * 100.0) / prev.abs();
      final sign = pct >= 0 ? '+' : '';
      return '$sign${pct.toStringAsFixed(0)}%';
    }

    Color deltaColor(int? prev, int cur) {
      if (prev == null) return AppColors.white20;
      if (cur == prev) return AppColors.white20;
      return cur >= (prev) ? AppColors.green100 : AppColors.red100;
    }

    return PressableScale(
      onTap: onToggleExpanded,
      child: PrototypeCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        color: AppColors.brandSecondary,
        shadow: null,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _KpiItem(
                    title: '总支出',
                    value: formatCentToYuan(data.expenseTotalCent),
                  ),
                ),
                Expanded(
                  child: _KpiItem(
                    title: '总收入',
                    value: formatCentToYuan(data.incomeTotalCent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FaIcon(
              expanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
              size: 14,
              color: AppColors.white20,
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              _KpiSubRow(
                label: '日均支出',
                value: formatCentToYuan(avgExpense),
              ),
              const SizedBox(height: 6),
              _KpiSubRow(
                label: '日均收入',
                value: formatCentToYuan(avgIncome),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.white20),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ComparePill(
                      label: '$compareLabel 支出',
                      value: formatDelta(compareExpense, data.expenseTotalCent),
                      background: deltaColor(compareExpense, data.expenseTotalCent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ComparePill(
                      label: '$compareLabel 收入',
                      value: formatDelta(compareIncome, data.incomeTotalCent),
                      background: deltaColor(compareIncome, data.incomeTotalCent),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.base(
              fontSize: 14,
              height: 1.2,
              fontWeight: AppTypography.medium,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.base(
              fontSize: 26,
              height: 1.0,
              fontWeight: AppTypography.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiSubRow extends StatelessWidget {
  const _KpiSubRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.regular,
            color: AppColors.white20,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.bold,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _ComparePill extends StatelessWidget {
  const _ComparePill({
    required this.label,
    required this.value,
    required this.background,
  });

  final String label;
  final String value;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.base(
              fontSize: 11,
              fontWeight: AppTypography.medium,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendLineCard extends StatelessWidget {
  const _TrendLineCard({
    required this.buckets,
    required this.range,
  });

  final List<StatsBarBucket> buckets;
  final StatsDateRange range;

  @override
  Widget build(BuildContext context) {
    var maxY = 0.0;
    for (final b in buckets) {
      final i = b.incomeCent / 100.0;
      final e = b.expenseCent / 100.0;
      if (i > maxY) maxY = i;
      if (e > maxY) maxY = e;
    }
    if (maxY <= 0) maxY = 1;

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (var i = 0; i < buckets.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), buckets[i].incomeCent / 100.0));
      expenseSpots.add(FlSpot(i.toDouble(), buckets[i].expenseCent / 100.0));
    }

    return PrototypeCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '收支走势',
                style: AppTypography.base(
                  fontSize: 18,
                  fontWeight: AppTypography.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _LegendDot(label: '支出', color: AppColors.stateSuccess),
              const SizedBox(width: 12),
              _LegendDot(label: '收入', color: AppColors.stateDanger),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (buckets.length - 1).toDouble().clamp(0, double.infinity),
                minY: 0,
                maxY: maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 10 ? 2 : null,
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTypography.base(
                            fontSize: 10,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx != 0 && idx != buckets.length - 1) return const SizedBox.shrink();
                        final dt = idx == 0 ? range.start : range.endExclusive.subtract(const Duration(days: 1));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _fmtDotDate(dt),
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: AppColors.stateSuccess,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.green50.withValues(alpha: 0.7)),
                  ),
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: AppColors.stateDanger,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.red100.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.regular,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HistogramCard extends StatelessWidget {
  const _HistogramCard({
    required this.buckets,
    required this.metric,
    required this.onChangeMetric,
  });

  final List<StatsBarBucket> buckets;
  final _StatsMetric metric;
  final ValueChanged<_StatsMetric> onChangeMetric;

  @override
  Widget build(BuildContext context) {
    double maxY = 0;
    double minY = 0;
    for (final b in buckets) {
      final y = _valueForMetric(b, metric) / 100.0;
      if (y > maxY) maxY = y;
      if (y < minY) minY = y;
    }
    if (maxY <= 0 && minY >= 0) maxY = 1;
    final rangeY = (maxY - minY).abs();

    final showEvery = buckets.length <= 12
        ? 1
        : (buckets.length <= 24 ? 2 : (buckets.length <= 36 ? 3 : 6));

    return PrototypeCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '收支统计',
                style: AppTypography.base(
                  fontSize: 18,
                  fontWeight: AppTypography.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _MetricSegment(
                value: metric,
                onChange: onChangeMetric,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                minY: minY > 0 ? 0 : (minY - rangeY * 0.15),
                maxY: maxY + rangeY * 0.15,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTypography.base(
                            fontSize: 10,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= buckets.length) return const SizedBox.shrink();
                        if (idx % showEvery != 0 && idx != buckets.length - 1) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            buckets[idx].label,
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textMuted,
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
                          toY: _valueForMetric(buckets[i], metric) / 100.0,
                          color: _colorForMetric(metric),
                          width: buckets.length > 24 ? 6 : 10,
                          borderRadius: BorderRadius.circular(3),
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

  int _valueForMetric(StatsBarBucket b, _StatsMetric metric) {
    switch (metric) {
      case _StatsMetric.expense:
        return b.expenseCent;
      case _StatsMetric.income:
        return b.incomeCent;
    }
  }

  Color _colorForMetric(_StatsMetric metric) {
    switch (metric) {
      case _StatsMetric.expense:
        return AppColors.stateSuccess;
      case _StatsMetric.income:
        return AppColors.stateDanger;
    }
  }
}

class _MetricSegment extends StatelessWidget {
  const _MetricSegment({
    required this.value,
    required this.onChange,
  });

  final _StatsMetric value;
  final ValueChanged<_StatsMetric> onChange;

  @override
  Widget build(BuildContext context) {
    Widget item(_StatsMetric v) {
      final selected = value == v;
      return Expanded(
        child: PressableScale(
          onTap: () => onChange(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.brandSecondary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              v.label,
              style: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.medium,
                color: selected ? AppColors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 150,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          item(_StatsMetric.expense),
          item(_StatsMetric.income),
        ],
      ),
    );
  }
}

String _fmtCnDate(DateTime dt) {
  return DateUtil.format(dt);
}

String _fmtDotDate(DateTime dt) {
  return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.totalExpenseCent,
    required this.categories,
  });

  final int totalExpenseCent;
  final List<StatsCategorySlice> categories;

  @override
  Widget build(BuildContext context) {
    const pieSize = 120.0;
    const pieRadius = 44.0;
    const pieCenterSpaceRadius = 28.0;

    final colors = <Color>[
      AppColors.indigo600,
      AppColors.purple600,
      AppColors.blue600,
      AppColors.pink600,
      AppColors.orange500,
      AppColors.green600,
      AppColors.yellow500,
      AppColors.gray400,
    ];
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < categories.length; i++) {
      final c = categories[i];
      final isOther = c.category == '其他';
      final color = isOther ? AppColors.gray400 : colors[i % colors.length];
      sections.add(
        PieChartSectionData(
          value: c.amountCent.toDouble(),
          color: color,
          radius: pieRadius,
          title: '',
        ),
      );
    }

    return PrototypeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '支出分类',
            style: AppTypography.base(
              fontSize: 16,
              fontWeight: AppTypography.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: pieSize,
                height: pieSize,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PieChart(
                        PieChartData(
                          sections: sections.isEmpty
                              ? [
                                  PieChartSectionData(
                                    value: 1,
                                    color: AppColors.gray200,
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
                            '总计',
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCentToYuan(totalExpenseCent),
                            style: AppTypography.base(
                              fontSize: 14,
                              fontWeight: AppTypography.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < categories.length; i++) ...[
                      _LegendRow(
                        color: categories[i].category == '其他' ? AppColors.gray400 : colors[i % colors.length],
                        label: categories[i].category,
                        value: totalExpenseCent <= 0
                            ? '0%'
                            : '${((categories[i].amountCent * 100) / totalExpenseCent).toStringAsFixed(0)}%',
                      ),
                      if (i != categories.length - 1) const SizedBox(height: 12),
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

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.regular,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.medium,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard({required this.items});

  final List<StatsRankItem> items;

  @override
  Widget build(BuildContext context) {
    final rankColors = <Color>[
      AppColors.yellow500,
      AppColors.gray400,
      AppColors.orange400,
      AppColors.indigo600,
      AppColors.purple600,
    ];
    return PrototypeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '人情榜单 (Top 5)',
            style: AppTypography.base(
              fontSize: 16,
              fontWeight: AppTypography.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              '暂无数据',
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _TopRow(
                rank: '${i + 1}',
                rankColor: rankColors[i.clamp(0, rankColors.length - 1)],
                name: items[i].personName,
                incomeCent: items[i].incomeCent,
                expenseCent: items[i].expenseCent,
              ),
              if (i != items.length - 1) const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.rank,
    required this.rankColor,
    required this.name,
    required this.incomeCent,
    required this.expenseCent,
  });

  final String rank;
  final Color rankColor;
  final String name;
  final int incomeCent;
  final int expenseCent;

  @override
  Widget build(BuildContext context) {
    final net = incomeCent - expenseCent;
    final netColor = net >= 0 ? AppColors.green600 : AppColors.red600;
    final total = incomeCent + expenseCent;
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            rank,
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.bold,
              color: rankColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.medium,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          formatCentToYuan(total),
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.bold,
            color: netColor,
          ),
        ),
      ],
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '加载失败',
              style: AppTypography.base(
                fontSize: 16,
                fontWeight: AppTypography.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            PrototypePrimaryButton(
              label: '重试',
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
