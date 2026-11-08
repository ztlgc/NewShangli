import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';

void main() {
  test('旧库自动补齐有效账簿与记录事由，保留停用状态且只修复一次', () async {
    final directory = await Directory.systemTemp.createTemp('reason_repair_');
    final file = File('${directory.path}/app.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      await directory.delete(recursive: true);
    });

    for (final (id, name, deleted) in [
      ('active', '  账簿事由  ', false),
      ('trashed', '回收站账簿事由', true),
    ]) {
      await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          bookId: Value(id),
          name: id,
          reasonType: Value(name),
          deletedAt: Value(deleted ? 1 : null),
          createdAt: 1,
          updatedAt: 1,
        ),
      );
    }
    for (final (id, deleted) in [('p1', false), ('p2', true)]) {
      await db.personsDao.insertOne(
        PersonsCompanion.insert(
          personId: Value(id),
          bookId: 'active',
          name: id,
          deletedAt: Value(deleted ? 1 : null),
          createdAt: 1,
          updatedAt: 1,
        ),
      );
    }
    final disabledId = await db.reasonsDao.create(
      name: '已停用事由',
      description: '保留原信息',
      enabled: false,
    );
    final disabled = await db.reasonsDao.findById(disabledId);
    for (final (name, bookId, personId, deleted) in [
      ('历史记录事由', 'active', 'p1', false),
      (' 历史记录事由 ', 'active', 'p1', false),
      ('Custom', 'active', 'p1', false),
      ('custom', 'active', 'p1', false),
      ('已停用事由', 'active', 'p1', false),
      ('   ', 'active', 'p1', false),
      ('长' * 65, 'active', 'p1', false),
      ('回收站记录事由', 'active', 'p1', true),
      ('已删除联系人事由', 'active', 'p2', false),
      ('已删除账簿记录事由', 'trashed', 'p1', false),
    ]) {
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: bookId,
          personId: personId,
          amountCent: 100,
          eventName: Value(name),
          occurredAt: 1,
          deletedAt: Value(deleted ? 1 : null),
          createdAt: 1,
          updatedAt: 1,
        ),
      );
    }
    // 模拟修复前的同版本数据库：已有业务数据，但没有补全标记。
    await db.customStatement('DROP TABLE IF EXISTS app_data_repair');
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    final reasons = await db.reasonsDao.listAll();
    expect(
      reasons.map((reason) => reason.name.toLowerCase()),
      unorderedEquals(['账簿事由', '历史记录事由', 'custom', '已停用事由']),
    );
    expect(await db.reasonsDao.findById(disabledId), disabled);
    expect(await db.select(db.giftRecords).get(), hasLength(10));
    expect(
      (await db.accountBooksDao.findById('active'))!.reasonType,
      '  账簿事由  ',
    );

    final repaired = (await db.reasonsDao.findByName('历史记录事由'))!;
    await db.reasonsDao.deleteById(repaired.reasonId);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    expect(await db.reasonsDao.findByName('历史记录事由'), isNull);
    expect(await db.reasonsDao.listAll(), hasLength(3));
  });
}
