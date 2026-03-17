part of '../app_database.dart';

@DriftAccessor(tables: [Reasons])
class ReasonsDao extends DatabaseAccessor<AppDatabase> with _$ReasonsDaoMixin {
  ReasonsDao(super.db);

  Stream<List<Reason>> watchAll() {
    return (select(reasons)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  Future<List<Reason>> listAll() {
    return (select(reasons)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  Future<Reason?> findById(String id) {
    return (select(reasons)..where((t) => t.reasonId.equals(id))).getSingleOrNull();
  }

  Future<Reason?> findByName(String name) {
    return (select(reasons)..where((t) => t.name.equals(name))).getSingleOrNull();
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
        description: Value(_normalizeText(description)),
        enabled: Value(enabled),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
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
        description: Value(_normalizeText(description)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> setEnabled({
    required String id,
    required bool enabled,
  }) async {
    if (!enabled) {
      final enabledRows =
          await (select(reasons)..where((t) => t.enabled.equals(true))).get();
      if (enabledRows.length <= 1 &&
          enabledRows.any((row) => row.reasonId == id)) {
        throw StateError('至少保留一个启用的事由');
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(reasons)..where((t) => t.reasonId.equals(id))).write(
      ReasonsCompanion(
        enabled: Value(enabled),
        updatedAt: Value(now),
      ),
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
