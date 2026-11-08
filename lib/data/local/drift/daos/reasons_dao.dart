part of '../app_database.dart';

@DriftAccessor(tables: [Reasons])
class ReasonsDao extends DatabaseAccessor<AppDatabase> with _$ReasonsDaoMixin {
  ReasonsDao(super.db);

  String _normalizeName(String value) => value.trim().toLowerCase();

  Stream<List<Reason>> watchAll() {
    return (select(
      reasons,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  Future<List<Reason>> listAll() {
    return (select(
      reasons,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  Future<Reason?> findById(String id) {
    return (select(
      reasons,
    )..where((t) => t.reasonId.equals(id))).getSingleOrNull();
  }

  Future<Reason?> findByName(String name) {
    return (select(reasons)
          ..where((t) => t.normalizedName.equals(_normalizeName(name))))
        .getSingleOrNull();
  }

  Future<String> create({
    required String name,
    String? description,
    bool enabled = true,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = db.newId();
    await into(reasons).insert(
      ReasonsCompanion.insert(
        reasonId: id,
        name: name.trim(),
        normalizedName: _normalizeName(name),
        description: Value(_normalizeText(description)),
        enabled: Value(enabled),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  /// 为导入和历史数据补齐缺失名称，已有事由的开关和描述保持不变。
  Future<void> ensureNames(Iterable<String?> names) async {
    final uniqueNames = <String, String>{};
    for (final raw in names) {
      final name = raw?.trim() ?? '';
      final normalized = _normalizeName(name);
      // 历史记录的事由文本没有长度限制；无法登记的名称仍保留在原记录中。
      if (name.isEmpty || name.length > 64 || normalized.length > 64) continue;
      uniqueNames.putIfAbsent(normalized, () => name);
    }
    if (uniqueNames.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      for (final entry in uniqueNames.entries) {
        batch.insert(
          reasons,
          ReasonsCompanion.insert(
            reasonId: db.newId(),
            name: entry.value,
            normalizedName: entry.key,
            createdAt: now,
            updatedAt: now,
          ),
          onConflict: DoNothing(target: [reasons.normalizedName]),
        );
      }
    });
  }

  Future<void> updateReason({
    required String id,
    required String name,
    String? description,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(reasons)..where((t) => t.reasonId.equals(id))).write(
      ReasonsCompanion(
        name: Value(name.trim()),
        normalizedName: Value(_normalizeName(name)),
        description: Value(_normalizeText(description)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> setEnabled({required String id, required bool enabled}) async {
    if (!enabled) {
      final enabledRows = await (select(
        reasons,
      )..where((t) => t.enabled.equals(true))).get();
      if (enabledRows.length <= 1 &&
          enabledRows.any((row) => row.reasonId == id)) {
        throw StateError('至少保留一个启用的事由');
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(reasons)..where((t) => t.reasonId.equals(id))).write(
      ReasonsCompanion(enabled: Value(enabled), updatedAt: Value(now)),
    );
  }

  Future<void> deleteById(String id) async {
    await (delete(reasons)..where((t) => t.reasonId.equals(id))).go();
  }

  String? _normalizeText(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
