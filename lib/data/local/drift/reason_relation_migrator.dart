import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';

class ReasonRelationMigrator {
  static const String _kReasonsKey = 'reasons_v1';
  static const String _kRelationTypesKey = 'relation_types_v1';
  static const String _kContactRelationsKey = 'contact_relations_v1';
  static const String _kMigratedKey = 'drift_reason_relation_migrated_v1';

  static Future<void> migrateIfNeeded(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_kMigratedKey) ?? false;
    if (migrated) return;

    final hasReasons = (await db.reasonsDao.listAll()).isNotEmpty;
    final hasTypes = (await db.relationTypesDao.listAll()).isNotEmpty;
    final hasRelations = (await db.contactRelationsDao.watchAllWithDetails().first).isNotEmpty;
    if (hasReasons || hasTypes || hasRelations) {
      await prefs.setBool(_kMigratedKey, true);
      return;
    }

    await db.transaction(() async {
      await _migrateReasons(db, prefs);
      await _migrateRelationTypes(db, prefs);
      await _migrateContactRelations(db, prefs);
    });

    await prefs.setBool(_kMigratedKey, true);
  }

  static Future<void> _migrateReasons(AppDatabase db, SharedPreferences prefs) async {
    final raw = prefs.getString(_kReasonsKey);
    final rows = _decodeList(raw);
    if (rows.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.reasons).insert(
        ReasonsCompanion.insert(
          reasonId: db.newId(),
          name: '结婚礼金',
          description: const Value(null),
          enabled: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
      return;
    }
    for (final map in rows) {
      final id = _asString(map['id']);
      final name = _asString(map['name']).trim();
      if (id.isEmpty || name.isEmpty) continue;
      final createdAt = _parseTime(map['createdAt']);
      final updatedAt = _parseTime(map['updatedAt']);
      final enabled = map['enabled'] is bool ? map['enabled'] as bool : true;
      await db.into(db.reasons).insertOnConflictUpdate(
        ReasonsCompanion.insert(
          reasonId: id,
          name: name,
          description: Value(_normalizeText(map['description'])),
          enabled: Value(enabled),
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }
  }

  static Future<void> _migrateRelationTypes(AppDatabase db, SharedPreferences prefs) async {
    final raw = prefs.getString(_kRelationTypesKey);
    final rows = _decodeList(raw);
    if (rows.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final name in const <String>['家人', '亲戚', '同事', '朋友', '同学', '邻居']) {
        await db.into(db.relationTypes).insertOnConflictUpdate(
          RelationTypesCompanion.insert(
            typeId: db.newId(),
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      return;
    }
    for (final map in rows) {
      final id = _asString(map['id']);
      final name = _asString(map['name']).trim();
      if (id.isEmpty || name.isEmpty) continue;
      final createdAt = _parseTime(map['createdAt']);
      final updatedAt = _parseTime(map['updatedAt']);
      await db.into(db.relationTypes).insertOnConflictUpdate(
        RelationTypesCompanion.insert(
          typeId: id,
          name: name,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }
  }

  static Future<void> _migrateContactRelations(AppDatabase db, SharedPreferences prefs) async {
    final raw = prefs.getString(_kContactRelationsKey);
    final rows = _decodeList(raw);
    if (rows.isEmpty) return;
    for (final map in rows) {
      final id = _asString(map['id']);
      final a = _asString(map['personAId']);
      final b = _asString(map['personBId']);
      final typeId = _asString(map['typeId']);
      if (id.isEmpty || a.isEmpty || b.isEmpty || typeId.isEmpty || a == b) continue;
      final pa = await db.personsDao.findByIdAny(a);
      final pb = await db.personsDao.findByIdAny(b);
      final type = await db.relationTypesDao.findById(typeId);
      if (pa == null || pb == null || type == null) continue;
      final createdAt = _parseTime(map['createdAt']);
      final updatedAt = _parseTime(map['updatedAt']);
      final pair = a.compareTo(b) <= 0 ? (a, b) : (b, a);
      await db.into(db.contactRelations).insertOnConflictUpdate(
        ContactRelationsCompanion.insert(
          relationId: id,
          personAId: pair.$1,
          personBId: pair.$2,
          typeId: typeId,
          note: Value(_normalizeText(map['note'])),
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }
  }

  static List<Map<String, Object?>> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <Map<String, Object?>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <Map<String, Object?>>[];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, Object?>.from(e))
        .toList();
  }

  static String _asString(Object? value) {
    return value is String ? value : '';
  }

  static int _parseTime(Object? value) {
    if (value is! String || value.trim().isEmpty) return DateTime.now().millisecondsSinceEpoch;
    final dt = DateTime.tryParse(value);
    return (dt ?? DateTime.now()).millisecondsSinceEpoch;
  }

  static String? _normalizeText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
