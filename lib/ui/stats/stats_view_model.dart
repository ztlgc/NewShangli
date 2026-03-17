import 'package:flutter/foundation.dart';

import '../../data/local/drift/app_database.dart';
import '../../stats/stats_models.dart';
import '../../stats/stats_repository.dart';
import '../../stats/stats_time_range.dart';

class StatsViewModel extends ChangeNotifier {
  StatsViewModel({
    required IStatsRepository repository,
    required AppDatabase db,
    StatsTimePreset initialPreset = StatsTimePreset.thisMonth,
    DateTime Function()? now,
  })  : _repository = repository,
        _db = db,
        _preset = initialPreset,
        _now = now ?? DateTime.now;

  final IStatsRepository _repository;
  final AppDatabase _db;
  final DateTime Function() _now;

  StatsTimePreset _preset;
  StatsDateRange? _customRange;
  bool _loading = false;
  String? _error;
  StatsSnapshot? _data;
  StatsSnapshot? _compareData;
  List<StatsSourceRecord> _records = const <StatsSourceRecord>[];
  int? _minRecordYear;
  bool _refreshPending = false;
  Future<void>? _refreshLoopFuture;
  bool _recordsSynced = false;
  String? _cachedBookId;

  StatsTimePreset get preset => _preset;
  StatsDateRange? get customRange => _customRange;
  bool get loading => _loading;
  String? get error => _error;
  StatsSnapshot? get data => _data;
  StatsSnapshot? get compareData => _compareData;
  int? get minRecordYear => _minRecordYear;

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
    if (_preset == StatsTimePreset.custom && _isSameRange(_customRange, range)) {
      return;
    }
    _preset = StatsTimePreset.custom;
    _customRange = range;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    _refreshPending = true;
    if (_refreshLoopFuture != null) {
      return;
    }
    final loopFuture = _runRefreshLoop();
    _refreshLoopFuture = loopFuture;
    try {
      await loopFuture;
    } finally {
      if (identical(_refreshLoopFuture, loopFuture)) {
        _refreshLoopFuture = null;
      }
    }
  }

  Future<void> _runRefreshLoop() async {
    while (_refreshPending) {
      _refreshPending = false;
      _loading = true;
      _error = null;
      notifyListeners();
      try {
        final now = _now();
        // 首次加载或强制刷新时同步数据；切换 Tab 时跳过
        if (!_recordsSynced) {
          await _loadRecordsFromDb();
          final repo = _repository;
          if (repo is StatsRepository) {
            await repo.ensureSynced(_records);
          }
          _recordsSynced = true;
          // 同时缓存默认账簿，避免每次 refresh 都查库
          final defaultBook = await _db.accountBooksDao.findDefault();
          _cachedBookId = defaultBook?.bookId;
        }
        final targetBookId = _cachedBookId;
        final range = resolveStatsDateRange(
          _preset,
          now: now,
          customRange: _preset == StatsTimePreset.custom ? _customRange : null,
        );
        final currentFuture = _repository.load(
          _preset,
          records: _records,
          bookId: targetBookId,
          now: now,
          customRange: _preset == StatsTimePreset.custom ? _customRange : null,
        );
        final compareRange = _resolveCompareRange(_preset, range);
        final compareFuture = _repository
            .load(
              StatsTimePreset.custom,
              records: _records,
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
  }

  bool _isSameRange(StatsDateRange? left, StatsDateRange right) {
    if (left == null) return false;
    return left.start == right.start && left.endExclusive == right.endExclusive;
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

  Future<void> _loadRecordsFromDb() async {
    final rows = await _db.giftRecordsDao.listAllWithPersonInAllBooks();
    _records = rows
        .map(
          (row) => StatsSourceRecord(
            id: row.record.recordId,
            bookId: row.record.bookId,
            direction: row.record.direction == '支出' ? 1 : 0,
            amountCent: row.record.amountCent,
            eventName: (row.record.eventName ?? '').trim().isEmpty ? '未设置' : row.record.eventName!.trim(),
            personName: row.person.name,
            paymentMethod: (row.record.paymentMethod ?? '').trim().isEmpty ? '' : row.record.paymentMethod!.trim(),
            occurredAt: DateTime.fromMillisecondsSinceEpoch(row.record.occurredAt),
            note: row.record.note,
          ),
        )
        .toList();
    if (_records.isEmpty) {
      _minRecordYear = null;
      return;
    }
    var minYear = _records.first.occurredAt.year;
    for (final r in _records) {
      if (r.occurredAt.year < minYear) minYear = r.occurredAt.year;
    }
    _minRecordYear = minYear;
  }
}
