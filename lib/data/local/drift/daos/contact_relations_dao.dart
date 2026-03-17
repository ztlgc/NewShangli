part of '../app_database.dart';

class ContactRelationWithDetails {
  const ContactRelationWithDetails({
    required this.relation,
    required this.personA,
    required this.personB,
    required this.type,
  });

  final ContactRelation relation;
  final Person personA;
  final Person personB;
  final RelationType type;
}

@DriftAccessor(tables: [ContactRelations, Persons, RelationTypes])
class ContactRelationsDao extends DatabaseAccessor<AppDatabase>
    with _$ContactRelationsDaoMixin {
  ContactRelationsDao(super.db);

  String pairKey(String personAId, String personBId, String typeId) {
    if (personAId.compareTo(personBId) <= 0) return '$personAId|$personBId|$typeId';
    return '$personBId|$personAId|$typeId';
  }

  Stream<List<ContactRelationWithDetails>> watchAllWithDetails() {
    final p1 = alias(persons, 'p1');
    final p2 = alias(persons, 'p2');
    final joined = select(contactRelations).join([
      innerJoin(p1, p1.personId.equalsExp(contactRelations.personAId)),
      innerJoin(p2, p2.personId.equalsExp(contactRelations.personBId)),
      innerJoin(relationTypes, relationTypes.typeId.equalsExp(contactRelations.typeId)),
    ])
      ..where(p1.deletedAt.isNull())
      ..where(p2.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(contactRelations.updatedAt)]);
    return joined.watch().map(
      (rows) => rows
          .map(
            (row) => ContactRelationWithDetails(
              relation: row.readTable(contactRelations),
              personA: row.readTable(p1),
              personB: row.readTable(p2),
              type: row.readTable(relationTypes),
            ),
          )
          .toList(),
    );
  }

  Future<ContactRelation?> findById(String relationId) {
    return (select(contactRelations)
          ..where((t) => t.relationId.equals(relationId)))
        .getSingleOrNull();
  }

  Future<String> create({
    required String personAId,
    required String personBId,
    required String typeId,
    String? note,
  }) async {
    final normalized = _normalizePair(personAId, personBId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = db.newId();
    await into(contactRelations).insert(
      ContactRelationsCompanion.insert(
        relationId: id,
        personAId: normalized.$1,
        personBId: normalized.$2,
        typeId: typeId,
        note: Value(_normalizeText(note)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> updateOne({
    required String relationId,
    required String personAId,
    required String personBId,
    required String typeId,
    String? note,
  }) async {
    final normalized = _normalizePair(personAId, personBId);
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(contactRelations)
          ..where((t) => t.relationId.equals(relationId)))
        .write(
      ContactRelationsCompanion(
        personAId: Value(normalized.$1),
        personBId: Value(normalized.$2),
        typeId: Value(typeId),
        note: Value(_normalizeText(note)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteById(String relationId) async {
    await (delete(contactRelations)
          ..where((t) => t.relationId.equals(relationId)))
        .go();
  }

  Future<bool> existsByPair({
    required String personAId,
    required String personBId,
    required String typeId,
    String? excludeRelationId,
  }) async {
    final normalized = _normalizePair(personAId, personBId);
    final query = select(contactRelations)
      ..where((t) => t.personAId.equals(normalized.$1))
      ..where((t) => t.personBId.equals(normalized.$2))
      ..where((t) => t.typeId.equals(typeId));
    if (excludeRelationId != null && excludeRelationId.trim().isNotEmpty) {
      query.where((t) => t.relationId.equals(excludeRelationId).not());
    }
    final row = await query.getSingleOrNull();
    return row != null;
  }

  (String, String) _normalizePair(String a, String b) {
    final x = a.trim();
    final y = b.trim();
    if (x.compareTo(y) <= 0) return (x, y);
    return (y, x);
  }

  String? _normalizeText(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
