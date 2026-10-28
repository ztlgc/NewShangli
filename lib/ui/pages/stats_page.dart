import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import '../../stats/stats_db.dart';
import '../../stats/stats_repository.dart';
import '../../stats/stats_time_range.dart';
import '../app_bottom_sheet.dart';
import '../app_database_scope.dart';
import '../app_icons.dart';
import '../app_layout.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../lunar_date_picker.dart';
import '../stats/stats_cards.dart';
import '../stats/stats_view_model.dart';

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
    if (vm == null) return const SizedBox.shrink();
    return ChangeNotifierProvider<StatsViewModel>.value(
      value: vm,
      child: _StatsPageBody(now: widget.now ?? DateTime.now),
    );
  }
}

enum _StatsTab { month, year, custom }

class _StatsPageBody extends StatefulWidget {
  const _StatsPageBody({required this.now});
  final DateTime Function() now;
  @override
  State<_StatsPageBody> createState() => _StatsPageBodyState();
}

class _StatsPageBodyState extends State<_StatsPageBody> {
  _StatsTab _tab = _StatsTab.month;
  late DateTime _month;
  int? _year;
  late StatsDateRange _custom;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = widget.now();
    _month = DateTime(now.year, now.month);
    _year = now.year;
    final today = DateTime(now.year, now.month, now.day);
    _custom = StatsDateRange(
      start: today.subtract(const Duration(days: 29)),
      endExclusive: DateTime(today.year, today.month, today.day + 1),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  StatsDateRange _range(StatsViewModel vm) {
    final now = widget.now();
    return switch (_tab) {
      _StatsTab.month => StatsDateRange(
        start: _month,
        endExclusive: DateTime(_month.year, _month.month + 1),
      ),
      _StatsTab.year when _year == null => StatsDateRange(
        start: DateTime(vm.minRecordYear ?? now.year),
        endExclusive: DateTime(now.year, now.month, now.day + 1),
      ),
      _StatsTab.year => StatsDateRange(
        start: DateTime(_year!),
        endExclusive: DateTime(_year! + 1),
      ),
      _StatsTab.custom => _custom,
    };
  }

  String get _periodLabel => switch (_tab) {
    _StatsTab.month
        when _month == DateTime(widget.now().year, widget.now().month) =>
      '本月',
    _StatsTab.year when _year == widget.now().year => '本年',
    _StatsTab.year when _year == null => '全部',
    _ => '本期',
  };

  String get _overviewTitle => switch (_tab) {
    _StatsTab.month when _periodLabel != '本月' => '${_month.month}月收支',
    _StatsTab.year when _year != null && _periodLabel != '本年' => '$_year年收支',
    _StatsTab.custom => '期间收支',
    _ => '$_periodLabel收支',
  };

  String? get _compareLabel => switch (_tab) {
    _StatsTab.month => '较上月',
    _StatsTab.year when _year == null => null,
    _StatsTab.year => '较去年',
    _StatsTab.custom => '较上期',
  };

  int _firstYear(StatsViewModel vm) =>
      math.min(vm.minRecordYear ?? widget.now().year, widget.now().year - 10);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatsViewModel>();
    final range = _range(vm);
    final loaded = vm.dataRange;
    final hasData =
        vm.data != null &&
        loaded?.start == range.start &&
        loaded?.endExclusive == range.endExclusive;
    final colors = context.appColors;
    return AppScaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceApp,
              border: Border(bottom: BorderSide(color: colors.borderDefault)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _text(context, '统计', 28, weight: FontWeight.w700),
                    ),
                    Icon(
                      AppIcons.bookOpen,
                      size: 14,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    _text(context, '全部账簿', 12, color: colors.textTertiary),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final (index, tab) in _StatsTab.values.indexed) ...[
                      if (index != 0) const SizedBox(width: 8),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppTokens.tapTargetMin,
                          ),
                          child: FButton(
                            variant: _tab == tab ? .primary : .outline,
                            onPress: () => _selectTab(vm, tab),
                            child: Text(switch (tab) {
                              _StatsTab.month => '月统计',
                              _StatsTab.year => '年统计',
                              _StatsTab.custom => '自定义',
                            }),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                if (_tab == _StatsTab.custom)
                  _CustomRangeSelector(
                    range: _custom,
                    onPickStart: () =>
                        unawaited(_pickCustomDate(vm, start: true)),
                    onPickEnd: () =>
                        unawaited(_pickCustomDate(vm, start: false)),
                  )
                else
                  _PeriodSelector(
                    label: _tab == _StatsTab.month
                        ? '${_month.year}年${_month.month}月'
                        : _year == null
                        ? '全部年份'
                        : '$_year年',
                    isMonth: _tab == _StatsTab.month,
                    onPrevious: _canMove(vm, -1) ? () => _move(vm, -1) : null,
                    onNext: _canMove(vm, 1) ? () => _move(vm, 1) : null,
                    onPick: () => unawaited(_pickPeriod(vm)),
                  ),
              ],
            ),
          ),
          if (vm.loading && hasData)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: !hasData
                ? vm.error != null
                      ? _StatsError(
                          message: vm.error!,
                          onRetry: () => unawaited(vm.refresh()),
                        )
                      : const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final data = vm.data!;
                      final category = StatsCategoryCard(
                        categories: data.expenseCategories,
                        totalExpenseCent: data.expenseTotalCent,
                        periodLabel: _periodLabel,
                      );
                      final ranking = StatsRankingCard(items: data.ranking);
                      return ListView(
                        controller: _scrollController,
                        padding: AppLayout.tabContentPadding,
                        children: [
                          if (vm.error != null) ...[
                            _StatsError(
                              message: '统计更新失败，当前显示上次结果',
                              onRetry: () => unawaited(vm.refresh()),
                              compact: true,
                            ),
                            const SizedBox(height: 16),
                          ],
                          StatsOverviewCard(
                            data: data,
                            compare: vm.compareData,
                            title: _overviewTitle,
                            compareLabel: _compareLabel,
                          ),
                          const SizedBox(height: 16),
                          StatsTrendCard(buckets: data.buckets, range: range),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 760)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: category),
                                const SizedBox(width: 16),
                                Expanded(child: ranking),
                              ],
                            )
                          else ...[
                            category,
                            const SizedBox(height: 16),
                            ranking,
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _resetScroll() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _selectTab(StatsViewModel vm, _StatsTab tab) {
    if (_tab == tab) return;
    _resetScroll();
    final now = widget.now();
    setState(() {
      _tab = tab;
      if (tab == _StatsTab.month) _month = DateTime(now.year, now.month);
      if (tab == _StatsTab.year) _year = now.year;
    });
    unawaited(switch (tab) {
      _StatsTab.month => vm.setPreset(StatsTimePreset.thisMonth),
      _StatsTab.year => vm.setPreset(StatsTimePreset.thisYear),
      _StatsTab.custom => vm.setCustomRange(_custom),
    });
  }

  bool _canMove(StatsViewModel vm, int direction) {
    final now = widget.now();
    if (_tab == _StatsTab.month) {
      final next = DateTime(_month.year, _month.month + direction);
      return !next.isBefore(DateTime(_firstYear(vm))) &&
          !next.isAfter(DateTime(now.year, now.month));
    }
    return _year != null &&
        _year! + direction >= _firstYear(vm) &&
        _year! + direction <= now.year;
  }

  void _move(StatsViewModel vm, int direction) {
    if (_tab == _StatsTab.month) {
      _selectMonth(vm, DateTime(_month.year, _month.month + direction));
    } else {
      _selectYear(vm, _year! + direction);
    }
  }

  void _selectMonth(StatsViewModel vm, DateTime month) {
    if (_month == month) return;
    _resetScroll();
    setState(() => _month = month);
    final now = widget.now();
    unawaited(
      month == DateTime(now.year, now.month)
          ? vm.setPreset(StatsTimePreset.thisMonth)
          : vm.setCustomRange(
              StatsDateRange(
                start: month,
                endExclusive: DateTime(month.year, month.month + 1),
              ),
            ),
    );
  }

  void _selectYear(StatsViewModel vm, int? year) {
    if (_year == year) return;
    _resetScroll();
    setState(() => _year = year);
    unawaited(
      year == widget.now().year
          ? vm.setPreset(StatsTimePreset.thisYear)
          : vm.setCustomRange(_range(vm)),
    );
  }

  Future<void> _pickPeriod(StatsViewModel vm) async {
    if (_tab == _StatsTab.month) {
      final picked = await AppBottomSheet.show<DateTime>(
        context,
        title: '选择月份',
        child: _MonthPicker(
          selected: _month,
          now: widget.now(),
          firstYear: _firstYear(vm),
        ),
      );
      if (picked != null && mounted) _selectMonth(vm, picked);
    } else {
      final now = widget.now();
      final picked = await AppBottomSheet.showPicker<int>(
        context,
        title: '选择年份',
        options: [
          AppSheetOption(label: '全部年份', value: 0, selected: _year == null),
          for (var year = now.year; year >= _firstYear(vm); year--)
            AppSheetOption(
              label: '$year年',
              value: year,
              selected: _year == year,
            ),
        ],
      );
      if (picked != null && mounted) {
        _selectYear(vm, picked == 0 ? null : picked);
      }
    }
  }

  Future<void> _pickCustomDate(StatsViewModel vm, {required bool start}) async {
    final now = widget.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = _custom.endExclusive.subtract(const Duration(days: 1));
    final picked = await showLunarDatePicker(
      context: context,
      initialDate: start ? _custom.start : end,
      firstDate: start ? DateTime(_firstYear(vm)) : _custom.start,
      lastDate: start && end.isBefore(today) ? end : today,
    );
    if (picked == null || !mounted) return;
    _resetScroll();
    setState(
      () => _custom = StatsDateRange(
        start: start ? picked : _custom.start,
        endExclusive: start
            ? _custom.endExclusive
            : DateTime(picked.year, picked.month, picked.day + 1),
      ),
    );
    await vm.setCustomRange(_custom);
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.label,
    required this.isMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });
  final String label;
  final bool isMonth;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 44,
        height: 44,
        child: FButton.icon(
          key: const ValueKey('stats_previous_period'),
          variant: .ghost,
          semanticsLabel: isMonth ? '上个月' : '上一年',
          onPress: onPrevious,
          child: const Icon(AppIcons.chevronLeft, size: 18),
        ),
      ),
      Expanded(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: FButton.raw(
            variant: .ghost,
            semanticsLabel: isMonth ? '选择月份' : '选择年份',
            onPress: onPick,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: _text(context, label, 15, weight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Icon(
                  AppIcons.chevronDown,
                  size: 14,
                  color: context.appColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
      SizedBox(
        width: 44,
        height: 44,
        child: FButton.icon(
          key: const ValueKey('stats_next_period'),
          variant: .ghost,
          semanticsLabel: isMonth ? '下个月' : '下一年',
          onPress: onNext,
          child: const Icon(AppIcons.chevronRight, size: 18),
        ),
      ),
    ],
  );
}

class _CustomRangeSelector extends StatelessWidget {
  const _CustomRangeSelector({
    required this.range,
    required this.onPickStart,
    required this.onPickEnd,
  });
  final StatsDateRange range;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: _date(context, '起始', range.start, onPickStart)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            AppIcons.arrowRight,
            size: 12,
            color: context.appColors.textTertiary,
          ),
        ),
        Expanded(
          child: _date(
            context,
            '截止',
            range.endExclusive.subtract(const Duration(days: 1)),
            onPickEnd,
          ),
        ),
      ],
    ),
  );
  Widget _date(
    BuildContext context,
    String label,
    DateTime date,
    VoidCallback onPick,
  ) {
    final colors = context.appColors;
    return FButton.raw(
      variant: .outline,
      onPress: onPick,
      semanticsLabel: '选择$label日期',
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: AppRadii.brXl,
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(context, label, 11, color: colors.textTertiary),
            const SizedBox(height: 2),
            _text(
              context,
              '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
              13,
              weight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPicker extends StatefulWidget {
  const _MonthPicker({
    required this.selected,
    required this.now,
    required this.firstYear,
  });
  final DateTime selected;
  final DateTime now;
  final int firstYear;
  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int _year = widget.selected.year;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: FButton.icon(
                variant: .ghost,
                semanticsLabel: '上一年',
                onPress: _year > widget.firstYear
                    ? () => setState(() => _year--)
                    : null,
                child: const Icon(AppIcons.chevronLeft, size: 18),
              ),
            ),
            Expanded(
              child: Center(
                child: _text(context, '$_year年', 16, weight: FontWeight.w600),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: FButton.icon(
                variant: .ghost,
                semanticsLabel: '下一年',
                onPress: _year < widget.now.year
                    ? () => setState(() => _year++)
                    : null,
                child: const Icon(AppIcons.chevronRight, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.textScalerOf(context).scale(12) > 14.4
              ? 3
              : 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            for (var month = 1; month <= 12; month++)
              FButton(
                variant: widget.selected == DateTime(_year, month)
                    ? .primary
                    : .outline,
                onPress:
                    DateTime(
                      _year,
                      month,
                    ).isAfter(DateTime(widget.now.year, widget.now.month))
                    ? null
                    : () => Navigator.of(context).pop(DateTime(_year, month)),
                child: Text('$month月'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppSecondaryButton(
          label: '回到本月',
          onTap: () =>
              Navigator.of(context)
                  .pop(DateTime(widget.now.year, widget.now.month)),
        ),
      ],
    ),
  );
}

class _StatsError extends StatelessWidget {
  const _StatsError({
    required this.message,
    required this.onRetry,
    this.compact = false,
  });
  final String message;
  final VoidCallback onRetry;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.all(compact ? 12 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(
              AppIcons.triangleAlert,
              color: context.appColors.stateDanger,
              size: 28,
            ),
            const SizedBox(height: 12),
            _text(context, '统计加载失败', 16, weight: FontWeight.w600),
            const SizedBox(height: 6),
          ],
          _text(context, message, 12, color: context.appColors.textSecondary),
          const SizedBox(height: 12),
          AppSecondaryButton(label: '重试', onTap: onRetry),
        ],
      ),
    );
    return compact
        ? content
        : Center(child: SingleChildScrollView(child: content));
  }
}

Text _text(
  BuildContext context,
  String value,
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
}) => Text(
  value,
  style: AppTypography.base(
    fontSize: size,
    fontWeight: weight,
    color: color ?? context.appColors.textPrimary,
    height: 1.35,
  ),
);
