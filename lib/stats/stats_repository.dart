import '../ui/app_data.dart';
import 'stats_db.dart';
import 'stats_engine.dart';
import 'stats_models.dart';
import 'stats_time_range.dart';

abstract class IStatsRepository {
  Future<StatsSnapshot> load(
    StatsTimePreset preset, {
    required List<RecordData> records,
    String? bookId,
    DateTime? now,
    StatsDateRange? customRange,
  });
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
    required List<RecordData> records,
    String? bookId,
    DateTime? now,
    StatsDateRange? customRange,
  }) async {
    final range = resolveStatsDateRange(preset, now: now, customRange: customRange);
    final startS = range.start.millisecondsSinceEpoch ~/ 1000;
    final endS = range.endExclusive.millisecondsSinceEpoch ~/ 1000;
    await _ensureSynced(records);

    final targetBookId = _normalizeBookId(bookId);
    final cacheKey = '${preset.name}|$targetBookId|$startS|$endS';
    final cached = _cache[cacheKey];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (cached != null && cached.expiresAtMs > nowMs) {
      return cached.data;
    }

    final lite = await _queryRecords(targetBookId, startS, endS);

    final snapshot = computeStatsSnapshot(
      preset: preset,
      start: range.start,
      endExclusive: range.endExclusive,
      records: lite,
    );

    _cache[cacheKey] = _CacheEntry(
      data: snapshot,
      expiresAtMs: nowMs + _cacheTtl.inMilliseconds,
    );

    return snapshot;
  }

  Future<void> _ensureSynced(List<RecordData> records) async {
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
        r.direction.index,
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
        'direction': r.direction == RecordDirection.income ? 0 : 1,
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
    if (v == null || v.isEmpty) return AppData.defaultBookId;
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
