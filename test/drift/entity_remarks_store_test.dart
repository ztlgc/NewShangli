import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/data/local/entity_remarks_store.dart';

void main() {
  group('EntityRemarksStore', () {
    late AppDatabase db;
    late EntityRemarksStore store;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      store = EntityRemarksStore(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('addRemark + listByEntity', () async {
      final rid = await store.addRemark(
        entityType: EntityRemarkType.person,
        entityId: 'p1',
        content: '第一次备注',
      );
      expect(rid, isNotEmpty);

      final rows = await store.listByEntity(
        entityType: EntityRemarkType.person,
        entityId: 'p1',
      );
      expect(rows.length, 1);
      expect(rows.first.content, '第一次备注');
      expect(rows.first.entityType, EntityRemarkType.person);
      expect(rows.first.entityId, 'p1');
    });

    test('listByEntity sorts by created_at desc', () async {
      await store.addRemark(
        entityType: EntityRemarkType.giftRecord,
        entityId: 'r1',
        content: 'A',
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await store.addRemark(
        entityType: EntityRemarkType.giftRecord,
        entityId: 'r1',
        content: 'B',
      );
      final rows = await store.listByEntity(
        entityType: EntityRemarkType.giftRecord,
        entityId: 'r1',
      );
      expect(rows.map((e) => e.content).toList(), ['B', 'A']);
    });
  });
}

