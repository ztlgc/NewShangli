import 'package:drift/drift.dart';

import 'drift/app_database.dart';

class EntityRemarkType {
  static const String accountBook = 'account_book';
  static const String person = 'person';
  static const String giftRecord = 'gift_record';
}

class EntityRemark {
  const EntityRemark({
    required this.remarkId,
    required this.entityType,
    required this.entityId,
    required this.content,
    required this.createdAt,
  });

  factory EntityRemark.fromRow(Map<String, Object?> row) {
    String readString(String key) => (row[key] as String?) ?? '';
    int readInt(String key) {
      final v = row[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return EntityRemark(
      remarkId: readString('remark_id'),
      entityType: readString('entity_type'),
      entityId: readString('entity_id'),
      content: readString('content'),
      createdAt: readInt('created_at'),
    );
  }

  final String remarkId;
  final String entityType;
  final String entityId;
  final String content;
  final int createdAt;
}

class EntityRemarksStore {
  EntityRemarksStore(this.db);

  final AppDatabase db;

  Future<List<EntityRemark>> listByEntity({
    required String entityType,
    required String entityId,
  }) async {
    final t = entityType.trim();
    final id = entityId.trim();
    if (t.isEmpty || id.isEmpty) return const <EntityRemark>[];
    final rows = await db.customSelect(
      '''
      SELECT remark_id, entity_type, entity_id, content, created_at
      FROM entity_remark
      WHERE entity_type = ? AND entity_id = ?
      ORDER BY created_at DESC
      ''',
      variables: [
        Variable<String>(t),
        Variable<String>(id),
      ],
    ).get();
    return rows.map((e) => EntityRemark.fromRow(e.data)).toList();
  }

  Future<String> addRemark({
    required String entityType,
    required String entityId,
    required String content,
  }) async {
    final t = entityType.trim();
    final id = entityId.trim();
    final c = content.trim();
    if (t.isEmpty) throw ArgumentError.value(entityType, 'entityType');
    if (id.isEmpty) throw ArgumentError.value(entityId, 'entityId');
    if (c.isEmpty) throw ArgumentError.value(content, 'content');
    final now = DateTime.now().millisecondsSinceEpoch;
    final remarkId = db.newId();
    await db.customStatement(
      '''
      INSERT INTO entity_remark(remark_id, entity_type, entity_id, content, created_at)
      VALUES(?, ?, ?, ?, ?)
      ''',
      [remarkId, t, id, c, now],
    );
    return remarkId;
  }
}

