import 'stats_db.dart';
import 'stats_engine.dart';
import 'stats_models.dart';
import 'stats_time_range.dart';

abstract class IStatsRepository {
  Future<StatsSnapshot> load(
    StatsTimePreset preset, {
    required List<StatsSourceRecord> records,
    String? bookId,
    DateTime? now,
    StatsDateRange? customRange,
  });
}

class StatsSourceRecord {
  const StatsSourceRecord({
    required this.id,
    required this.bookId,
    required this.direction,
    required this.amountCent,
    required this.eventName,
    required this.personName,
    required this.paymentMethod,
    required this.occurredAt,
    this.note,
  });

  final String id;
  final String? bookId;
  final int direction;
  final int amountCent;
  final String eventName;
  final String personName;
  final String paymentMethod;
  final DateTime occurredAt;
  final String? note;
}

class StatsRepository implements IStatsRepository {
  StatsRepository({
    required StatsDb db,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _db = db,
        _cacheTtl = cacheTtl;

  final StatsDb _db;
  final Duration _cacheTtl;

  int? _lastSyncFingerprint;
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  @override
  Future<StatsSnapshot> load(
    StatsTimePreset preset, {
    required List<StatsSourceRecord> records,
    String? bookId,
    DateTime? now,
    StatsDateRange? customRange,
  }) async {
    final range = resolveStatsDateRange(preset, now: now, customRange: customRange);
    final lite = _filterRecordsInMemory(
      records,
      bookId: bookId,
      start: range.start,
      endExclusive: range.endExclusive,
    );
    return computeStatsSnapshot(
      preset: preset,
      start: range.start,
      endExclusive: range.endExclusive,
      records: lite,
    );
  }

  List<StatsRecordLite> _filterRecordsInMemory(
    List<StatsSourceRecord> records, {
    required String? bookId,
    required DateTime start,
    required DateTime endExclusive,
  }) {
    final normalizedBookId = _normalizeFilterBookId(bookId);
    final out = <StatsRecordLite>[];
    for (final record in records) {
      final recordBookId = _normalizeFilterBookId(record.bookId);
      if (normalizedBookId != null && recordBookId != normalizedBookId) {
        continue;
      }
      if (record.occurredAt.isBefore(start) ||
          !record.occurredAt.isBefore(endExclusive)) {
        continue;
      }
      out.add(
        StatsRecordLite(
          direction: record.direction,
          amountCent: record.amountCent,
          eventName: record.eventName,
          personName: record.personName,
          occurredAt: record.occurredAt,
        ),
      );
    }
    return out;
  }

  /// 将源记录同步到统计数据库。应在加载统计数据前调用一次。
  Future<void> ensureSynced(List<StatsSourceRecord> records) async {
    // 缓存/同步指纹：
    // - 之前仅用 records.length + max(occurredAt) 作为指纹，无法覆盖“仅变更 bookId”等场景
    // - 这里改为对记录关键字段做滚动哈希，以保证统计结果与账簿归属实时一致
    var fp = 0;
    for (final r in records) {
      final occurredAtS = r.occurredAt.millisecondsSinceEpoch ~/ 1000;
      final effectiveBookId = _normalizeBookId(r.bookId);
      fp = Object.hash(
        fp,
        r.id,
        effectiveBookId,
        r.direction,
        r.amountCent,
        r.eventName,
        r.personName,
        r.paymentMethod,
        occurredAtS,
        r.note ?? '',
      );
    }
    if (_lastSyncFingerprint == fp) return;
    _lastSyncFingerprint = fp;
    _cache.clear();

    final rows = <Map<String, Object?>>[];
    for (final r in records) {
      rows.add(<String, Object?>{
        'id': r.id,
        'book_id': _normalizeBookId(r.bookId),
        'direction': r.direction,
        'amount_cent': r.amountCent,
        'event_name': r.eventName,
        'person_name': r.personName,
        'payment_method': r.paymentMethod,
        'occurred_at_s': r.occurredAt.millisecondsSinceEpoch ~/ 1000,
      });
    }
    await _db.upsertRecords(rows);
  }

  String _normalizeBookId(String? bookId) {
    final v = bookId?.trim();
    if (v == null || v.isEmpty) return 'book_default';
    return v;
  }

  String? _normalizeFilterBookId(String? bookId) {
    final v = bookId?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<List<StatsRecordLite>> _queryRecords(String bookId, int startS, int endS) async {
    final rows = await _db.query(
      'SELECT direction, amount_cent, event_name, person_name, occurred_at_s FROM records WHERE book_id = ? AND occurred_at_s >= ? AND occurred_at_s < ?',
      <Object?>[bookId, startS, endS],
    );
    final out = <StatsRecordLite>[];
    for (final r in rows) {
      out.add(
        StatsRecordLite(
          direction: (r['direction'] as int?) ?? 0,
          amountCent: (r['amount_cent'] as int?) ?? 0,
          eventName: (r['event_name'] as String?) ?? '',
          personName: (r['person_name'] as String?) ?? '',
          occurredAt: DateTime.fromMillisecondsSinceEpoch(((r['occurred_at_s'] as int?) ?? 0) * 1000),
        ),
      );
    }
    return out;
  }
}

class _CacheEntry {
  const _CacheEntry({
    required this.data,
    required this.expiresAtMs,
  });

  final StatsSnapshot data;
  final int expiresAtMs;
}
