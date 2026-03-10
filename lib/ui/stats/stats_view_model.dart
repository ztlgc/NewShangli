import 'package:flutter/foundation.dart';

import '../../stats/stats_models.dart';
import '../../stats/stats_repository.dart';
import '../../stats/stats_time_range.dart';
import '../app_data.dart';

class StatsViewModel extends ChangeNotifier {
  StatsViewModel({
    required IStatsRepository repository,
    required AppData appData,
    StatsTimePreset initialPreset = StatsTimePreset.thisMonth,
    DateTime Function()? now,
  })  : _repository = repository,
        _appData = appData,
        _preset = initialPreset,
        _now = now ?? DateTime.now;

  final IStatsRepository _repository;
  final AppData _appData;
  final DateTime Function() _now;

  StatsTimePreset _preset;
  StatsDateRange? _customRange;
  bool _loading = false;
  String? _error;
  StatsSnapshot? _data;
  StatsSnapshot? _compareData;

  StatsTimePreset get preset => _preset;
  StatsDateRange? get customRange => _customRange;
  bool get loading => _loading;
  String? get error => _error;
  StatsSnapshot? get data => _data;
  StatsSnapshot? get compareData => _compareData;

  Future<void> init() async {
    await refresh();
  }

  Future<void> setPreset(StatsTimePreset preset) async {
    if (_preset == preset) return;
    _preset = preset;
    if (_preset != StatsTimePreset.custom) {
      _customRange = null;
    }
    notifyListeners();
    await refresh();
  }

  Future<void> setCustomRange(StatsDateRange range) async {
    _preset = StatsTimePreset.custom;
    _customRange = range;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final now = _now();
      // 统计口径：默认按“礼簿/账簿”维度汇总。
      //
      // 目前原型层未提供切换礼簿的入口，因此统计范围固定为系统默认礼簿。
      // 当记录未显式指定 bookId 时，会在统计仓库层按默认礼簿进行兜底归属。
      final targetBookId = AppData.defaultBookId;
      final range = resolveStatsDateRange(
        _preset,
        now: now,
        customRange: _preset == StatsTimePreset.custom ? _customRange : null,
      );

      // 主数据：根据当前 preset / range 加载快照。
      final currentFuture = _repository.load(
        _preset,
        records: _appData.records,
        bookId: targetBookId,
        now: now,
        customRange: _preset == StatsTimePreset.custom ? _customRange : null,
      );

      // 趋势对比：在 UI 上展示“较上期/较上月/较去年”等。
      // 对比数据失败不应阻塞主数据，因此以 catchError 吞掉异常并返回 null。
      final compareRange = _resolveCompareRange(_preset, range);
      final compareFuture = _repository
          .load(
            StatsTimePreset.custom,
            records: _appData.records,
            bookId: targetBookId,
            now: now,
            customRange: compareRange,
          )
          .then<StatsSnapshot?>((v) => v)
          .catchError((_) => null);

      _data = await currentFuture;
      _compareData = await compareFuture;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  StatsDateRange _resolveCompareRange(StatsTimePreset preset, StatsDateRange current) {
    switch (preset) {
      case StatsTimePreset.thisMonth:
        return StatsDateRange(
          start: DateTime(current.start.year, current.start.month - 1, 1),
          endExclusive: current.start,
        );
      case StatsTimePreset.thisYear:
        return StatsDateRange(
          start: DateTime(current.start.year - 1, 1, 1),
          endExclusive: current.start,
        );
      case StatsTimePreset.custom:
        final isCalendarMonth = current.start.day == 1 &&
            current.endExclusive.day == 1 &&
            current.endExclusive == DateTime(current.start.year, current.start.month + 1, 1);
        if (isCalendarMonth) {
          return StatsDateRange(
            start: DateTime(current.start.year, current.start.month - 1, 1),
            endExclusive: current.start,
          );
        }

        final isCalendarYear = current.start.month == 1 &&
            current.start.day == 1 &&
            current.endExclusive.month == 1 &&
            current.endExclusive.day == 1 &&
            current.endExclusive == DateTime(current.start.year + 1, 1, 1);
        if (isCalendarYear) {
          return StatsDateRange(
            start: DateTime(current.start.year - 1, 1, 1),
            endExclusive: current.start,
          );
        }

        final len = current.endExclusive.difference(current.start).inDays;
        final days = len <= 0 ? 1 : len;
        return StatsDateRange(
          start: current.start.subtract(Duration(days: days)),
          endExclusive: current.start,
        );
    }
  }
}
