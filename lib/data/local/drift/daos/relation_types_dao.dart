part of '../app_database.dart';

@DriftAccessor(tables: [RelationTypes, Persons])
class RelationTypesDao extends DatabaseAccessor<AppDatabase>
    with _$RelationTypesDaoMixin {
  RelationTypesDao(super.db);

  String _normalizeName(String value) => value.trim().toLowerCase();

  Stream<List<RelationType>> watchAll() {
    return (select(
      relationTypes,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  Future<List<RelationType>> listAll() {
    return (select(
      relationTypes,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  Future<RelationType?> findById(String id) {
    return (select(
      relationTypes,
    )..where((t) => t.typeId.equals(id))).getSingleOrNull();
  }

  Future<RelationType?> findByName(String name) {
    return (select(relationTypes)
          ..where((t) => t.normalizedName.equals(_normalizeName(name))))
        .getSingleOrNull();
  }

  Future<String> create({required String name}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = db.newId();
    await into(relationTypes).insert(
      RelationTypesCompanion.insert(
        typeId: id,
        name: name.trim(),
        normalizedName: _normalizeName(name),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> updateType({required String id, required String name}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final old = await findById(id);
    final next = name.trim();
    await db.transaction(() async {
      await (update(relationTypes)..where((t) => t.typeId.equals(id))).write(
        RelationTypesCompanion(
          name: Value(next),
          normalizedName: Value(_normalizeName(next)),
          updatedAt: Value(now),
        ),
      );
      if (old != null && old.name.trim().toLowerCase() != next.toLowerCase()) {
        await customUpdate(
          'UPDATE person SET relationship_type = ?, updated_at = ? WHERE LOWER(relationship_type) = LOWER(?);',
          variables: [
            Variable<String>(next),
            Variable<int>(now),
            Variable<String>(old.name.trim()),
          ],
          updates: {persons},
        );
      }
    });
  }

  Future<void> deleteById(String id) async {
    await (delete(relationTypes)..where((t) => t.typeId.equals(id))).go();
  }
}
