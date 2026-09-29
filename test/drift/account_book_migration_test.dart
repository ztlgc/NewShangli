import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:newshangli/data/local/drift/app_database.dart';

void main() {
  test('未发布旧版本拒绝打开且原表和数据保持不变', () async {
    final dir = await Directory.systemTemp.createTemp('schema_reject_');
    try {
      for (final version in [2, 9, 11, 12]) {
        final file = File(dir.path + '/$version.sqlite');
        final raw = sqlite.sqlite3.open(file.path);
        raw.execute('CREATE TABLE marker(value TEXT)');
        raw.execute("INSERT INTO marker VALUES('preserve')");
        raw.execute('PRAGMA user_version=$version');
        raw.dispose();
        final db = AppDatabase.forTesting(NativeDatabase(file));
        await expectLater(db.customSelect('SELECT 1').get(), throwsStateError);
        await db.close();
        final check = sqlite.sqlite3.open(file.path);
        expect(
          check.select('SELECT value FROM marker').single['value'],
          'preserve',
        );
        expect(
          check.select('PRAGMA user_version').single.values.first,
          version,
        );
        check.dispose();
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('13到14解除联系人外键后保留跨本记录和所有业务字段', () async {
    final dir = await Directory.systemTemp.createTemp('schema_upgrade_');
    final file = File(dir.path + '/test.sqlite');
    final initial = AppDatabase.forTesting(NativeDatabase(file));
    for (final id in ['a', 'b']) {
      await initial
          .into(initial.accountBooks)
          .insert(
            AccountBooksCompanion.insert(
              bookId: Value(id),
              name: id,
              createdAt: 1,
              updatedAt: 1,
            ),
          );
    }
    await initial
        .into(initial.persons)
        .insert(
          PersonsCompanion.insert(
            personId: const Value('p'),
            bookId: 'a',
            name: '张三',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await initial
        .into(initial.giftRecords)
        .insert(
          GiftRecordsCompanion.insert(
            recordId: const Value('r'),
            bookId: 'b',
            personId: 'p',
            amountCent: 12345,
            occurredAt: 42,
            direction: const Value('支出'),
            note: const Value('保留'),
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await initial.close();
    final raw = sqlite.sqlite3.open(file.path);
    var schema =
        raw
                .select("SELECT sql FROM sqlite_master WHERE name='person'")
                .single['sql']
            as String;
    schema = schema
        .replaceFirst('"person"', '"old_person"')
        .replaceFirst(
          '"book_id" TEXT NOT NULL',
          '"book_id" TEXT NOT NULL REFERENCES account_book(book_id) ON DELETE CASCADE',
        );
    raw.execute(schema);
    raw.execute('INSERT INTO old_person SELECT * FROM person');
    raw.execute('DROP TABLE person');
    raw.execute('ALTER TABLE old_person RENAME TO person');
    raw.execute('PRAGMA user_version=13');
    raw.dispose();
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final row = (await upgraded.select(upgraded.giftRecords).get()).single;
      expect(
        [
          row.bookId,
          row.personId,
          row.amountCent,
          row.occurredAt,
          row.direction,
          row.note,
        ],
        ['b', 'p', 12345, 42, '支出', '保留'],
      );
      expect(
        await upgraded.customSelect('PRAGMA foreign_key_list(person)').get(),
        isEmpty,
      );
      expect(
        await upgraded.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    } finally {
      await upgraded.close();
      await dir.delete(recursive: true);
    }
  });
}
