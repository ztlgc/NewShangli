import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:newshangli/data/local/drift/app_database.dart';

void main() {
  test('schema v2 -> v3：account_book.type 迁移为 reason_type 且历史值映射正确', () async {
    final raw = sqlite3.openInMemory();
    try {
      raw.execute('PRAGMA foreign_keys = ON;');
      raw.execute('PRAGMA user_version = 2;');

      raw.execute('''
CREATE TABLE account_book (
  book_id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'default',
  theme_color TEXT NOT NULL DEFAULT '#312E81',
  icon TEXT NULL,
  description TEXT NULL,
  is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''');

      raw.execute('''
CREATE TABLE person (
  person_id TEXT NOT NULL PRIMARY KEY,
  book_id TEXT NOT NULL,
  name TEXT NOT NULL,
  relationship_type TEXT NOT NULL DEFAULT '其他',
  phone TEXT NULL,
  birthday TEXT NULL,
  anniversary TEXT NULL,
  avatar_uri TEXT NULL,
  note TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''');

      raw.execute('''
CREATE TABLE event_reminder (
  reminder_id TEXT NOT NULL PRIMARY KEY,
  book_id TEXT NOT NULL,
  person_id TEXT NULL,
  reminder_type TEXT NOT NULL DEFAULT '自定义',
  target_date TEXT NOT NULL,
  remind_at INTEGER NOT NULL,
  repeat_rule TEXT NOT NULL DEFAULT 'none',
  status TEXT NOT NULL DEFAULT 'active',
  channel TEXT NOT NULL DEFAULT 'notification',
  note TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''');

      raw.execute('''
INSERT INTO account_book(book_id, name, type, theme_color, is_default, created_at, updated_at) VALUES
('b1', 'A', 'default',  '#312E81', 1, 1, 1),
('b2', 'B', 'wedding',  '#312E81', 0, 1, 1),
('b3', 'C', 'business', '#312E81', 0, 1, 1),
('b4', 'D', '乔迁',     '#312E81', 0, 1, 1);
''');

      final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      try {
        final cols = await db
            .customSelect('PRAGMA table_info(account_book);')
            .get();
        final names = cols
            .map((e) => (e.data['name'] as String?) ?? '')
            .toSet();
        expect(names.contains('reason_type'), isTrue);
        expect(names.contains('type'), isFalse);

        final b1 = await db.accountBooksDao.findById('b1');
        final b2 = await db.accountBooksDao.findById('b2');
        final b3 = await db.accountBooksDao.findById('b3');
        final b4 = await db.accountBooksDao.findById('b4');

        expect(b1, isNotNull);
        expect(b2, isNotNull);
        expect(b3, isNotNull);
        expect(b4, isNotNull);

        expect(b1!.reasonType, '');
        expect(b2!.reasonType, '结婚礼金');
        expect(b3!.reasonType, '商务往来');
        expect(b4!.reasonType, '乔迁');
      } finally {
        await db.close();
      }
    } finally {
      raw.dispose();
    }
  });

  test('schema v9 -> v10：account_book 新增 book_time 并回填历史时间', () async {
    final raw = sqlite3.openInMemory();
    try {
      raw.execute('PRAGMA foreign_keys = ON;');
      raw.execute('PRAGMA user_version = 9;');

      raw.execute('''
CREATE TABLE account_book (
  book_id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  reason_type TEXT NOT NULL DEFAULT '',
  theme_color TEXT NOT NULL DEFAULT '#312E81',
  icon TEXT NULL,
  description TEXT NULL,
  is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER NULL
);
''');

      raw.execute('''
INSERT INTO account_book(book_id, name, reason_type, theme_color, is_default, created_at, updated_at, deleted_at) VALUES
('b1', 'A', '', '#312E81', 1, 100, 200, NULL),
('b2', 'B', '乔迁', '#312E81', 0, 300, 400, NULL);
''');

      final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      try {
        final cols = await db
            .customSelect('PRAGMA table_info(account_book);')
            .get();
        final names = cols
            .map((e) => (e.data['name'] as String?) ?? '')
            .toSet();
        expect(names.contains('book_time'), isTrue);

        final b1 = await db.accountBooksDao.findById('b1');
        final b2 = await db.accountBooksDao.findById('b2');

        expect(b1, isNotNull);
        expect(b2, isNotNull);
        expect(b1!.bookTime, 100);
        expect(b2!.bookTime, 300);
      } finally {
        await db.close();
      }
    } finally {
      raw.dispose();
    }
  });
}
