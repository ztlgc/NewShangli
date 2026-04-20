import 'dart:async';

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
  StreamSubscription<List<GiftRecordWithPerson>>? _recordsSubscription;

  StatsTimePreset get preset => _preset;
  StatsDateRange? get customRange => _customRange;
  bool get loading => _loading;
  String? get error => _error;
  StatsSnapshot? get data => _data;
  StatsSnapshot? get compareData => _compareData;
  int? get minRecordYear => _minRecordYear;

  Future<void> init() async {
    await _reloadRecords();
    _subscribeToRecords();
    await refresh();
  }

  @override
  void dispose() {
    _recordsSubscription?.cancel();
    super.dispose();
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
        // 统计页按“全账簿”口径聚合，避免非默认账簿数据漏统。
        const String? targetBookId = null;
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

  void _subscribeToRecords() {
    _recordsSubscription?.cancel();
    _recordsSubscription = _db.giftRecordsDao.watchAllWithPersonInAllBooks().listen((
      rows,
    ) {
      _replaceRecords(rows);
      unawaited(refresh());
    });
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

  Future<void> _reloadRecords() async {
    final rows = await _db.giftRecordsDao.listAllWithPersonInAllBooks();
    _replaceRecords(rows);
  }

  void _replaceRecords(
    List<GiftRecordWithPerson> rows,
  ) {
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
