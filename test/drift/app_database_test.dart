import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/import/default_book_service.dart';

void main() {
  group('Drift AppDatabase', () {
    late AppDatabase db;

    setUp(() {
      // 使用内存数据库，确保测试稳定且无磁盘副作用。
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('AccountBook：CRUD + 默认账簿保护', () async {
      final bookTime = DateTime(2024, 2, 3).millisecondsSinceEpoch;
      final defaultBookId = await DefaultBookService().ensureDefaultBookId(db);
      final String bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '家庭账簿',
          bookTime: Value(bookTime),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final AccountBook? book = await db.accountBooksDao.findById(bookId);
      expect(book, isNotNull);
      expect(book!.name, '家庭账簿');
      expect(book.reasonType, '');
      expect(book.themeColor, '#312E81');
      expect(book.bookTime, bookTime);
      expect(book.isDefault, 0);

      final AccountBook? defaultBook = await db.accountBooksDao.findById(
        defaultBookId,
      );
      expect(defaultBook, isNotNull);
      expect(defaultBook!.reasonType, '');

      final AccountBook? currentDefaultBook = await db.accountBooksDao
          .findDefault();
      expect(currentDefaultBook?.bookId, defaultBookId);
      expect(currentDefaultBook?.isDefault, 1);

      final bool updatedOk = await db.accountBooksDao.updateOne(
        book.copyWith(
          name: '婚礼账簿',
          reasonType: '商务往来',
          themeColor: '#22C55E',
          description: const Value('备注'),
          bookTime: DateTime(2024, 5, 6).millisecondsSinceEpoch,
        ),
      );
      expect(updatedOk, isTrue);

      final AccountBook? book2 = await db.accountBooksDao.findById(bookId);
      expect(book2?.name, '婚礼账簿');
      expect(book2?.reasonType, '商务往来');
      expect(book2?.themeColor, '#22C55E');
      expect(book2?.description, '备注');
      expect(book2?.bookTime, DateTime(2024, 5, 6).millisecondsSinceEpoch);

      expect(
        () => db.accountBooksDao.deleteById(defaultBookId),
        throwsA(isA<StateError>()),
      );
      final int deleted = await db.accountBooksDao.deleteById(bookId);
      expect(deleted, 1);
      expect(await db.accountBooksDao.findById(bookId), isNull);
    });

    test('应用托管默认账簿：首个账簿为默认且可自动修复', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final firstBookId = await db.into(db.accountBooks).insert(
        AccountBooksCompanion.insert(
          bookId: const Value('b_first'),
          name: '第一账簿',
          isDefault: const Value(0),
          createdAt: now - 1000,
          updatedAt: now - 1000,
        ),
      );
      expect(firstBookId, greaterThan(0));
      await db.into(db.accountBooks).insert(
        AccountBooksCompanion.insert(
          bookId: const Value('b_second'),
          name: '第二账簿',
          isDefault: const Value(1),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final ensuredId = await DefaultBookService().ensureDefaultBookId(db);
      expect(ensuredId, 'b_first');

      final books = await (db.select(
        db.accountBooks,
      )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
      final defaults = books.where((b) => b.isDefault == 1).toList();
      expect(defaults.length, 1);
      expect(defaults.first.bookId, 'b_first');
    });

    test('外键约束：Person 必须绑定存在的 Book', () async {
      // 未先插入账簿，直接插入 Person 应触发外键失败。
      expect(
        () => db.personsDao.insertOne(
          PersonsCompanion.insert(
            bookId: 'missing-book',
            name: '张三',
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('GiftRecord：attachments JSON 往返 + CHECK 约束', () async {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final String bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final String personId = await db.personsDao.insertOne(
        PersonsCompanion.insert(
          bookId: bookId,
          name: '李四',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final String recordId = await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: bookId,
          personId: personId,
          direction: const Value('收入'),
          amountCent: 12345,
          currency: const Value('CNY'),
          occurredAt: now,
          attachments: const Value(<String>['a.png', 'b.jpg']),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final GiftRecord? record = await db.giftRecordsDao.findById(recordId);
      expect(record, isNotNull);
      expect(record!.attachments, <String>['a.png', 'b.jpg']);

      // amountCent 必须 > 0
      expect(
        () => db.giftRecordsDao.insertOne(
          GiftRecordsCompanion.insert(
            bookId: bookId,
            personId: personId,
            direction: const Value('收入'),
            amountCent: 0,
            currency: const Value('CNY'),
            occurredAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );

      // direction 只能是 '收入' 或 '支出'
      expect(
        () => db.giftRecordsDao.insertOne(
          GiftRecordsCompanion.insert(
            bookId: bookId,
            personId: personId,
            direction: const Value('未知'),
            amountCent: 1,
            currency: const Value('CNY'),
            occurredAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('级联删除：删除 Book 会删除 Person/Record', () async {
      final int now = DateTime.now().millisecondsSinceEpoch;
      await DefaultBookService().ensureDefaultBookId(db);
      final String bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final String personId = await db.personsDao.insertOne(
        PersonsCompanion.insert(
          bookId: bookId,
          name: '赵六',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: bookId,
          personId: personId,
          direction: const Value('支出'),
          amountCent: 200,
          currency: const Value('CNY'),
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.accountBooksDao.deleteById(bookId);

      expect(await db.accountBooksDao.findById(bookId), isNull);
      expect(await db.personsDao.findById(personId), isNull);
      final int recordCount = await (db.select(db.giftRecords).get()).then(
        (v) => v.length,
      );
      expect(recordCount, 0);
    });

    test('事务回滚：异常时不应落库', () async {
      final int now = DateTime.now().millisecondsSinceEpoch;

      try {
        await db.transaction(() async {
          final String bookId = await db.accountBooksDao.insertOne(
            AccountBooksCompanion.insert(
              name: '事务账簿',
              createdAt: now,
              updatedAt: now,
            ),
          );

          await db.personsDao.insertOne(
            PersonsCompanion.insert(
              bookId: bookId,
              name: '事务人',
              createdAt: now,
              updatedAt: now,
            ),
          );

          throw StateError('模拟异常');
        });
      } catch (_) {}

      final List<AccountBook> books = await db.select(db.accountBooks).get();
      final List<Person> people = await db.select(db.persons).get();
      expect(books, isEmpty);
      expect(people, isEmpty);
    });

    test('索引有效：索引存在且可被强制使用', () async {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final String bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '索引账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final String personId = await db.personsDao.insertOne(
        PersonsCompanion.insert(
          bookId: bookId,
          name: '索引人',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          bookId: bookId,
          personId: personId,
          direction: const Value('收入'),
          amountCent: 1,
          currency: const Value('CNY'),
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final List<QueryRow> indexRows = await db
          .customSelect("PRAGMA index_list('gift_record')")
          .get();

      final bool hasIndex = indexRows.any(
        (r) =>
            (r.data['name'] ?? '').toString() ==
            'idx_gift_record_book_occurred',
      );
      expect(hasIndex, isTrue);

      final List<QueryRow> planRows = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM gift_record INDEXED BY idx_gift_record_book_occurred WHERE book_id = ? ORDER BY occurred_at DESC',
            variables: [Variable<String>(bookId)],
          )
          .get();

      final String planText = planRows
          .map((r) => (r.data['detail'] ?? '').toString())
          .join('\n');

      expect(planText, contains('idx_gift_record_book_occurred'));
    });

    test('旧库(schema 12)缺少 normalized_name 时按开发阶段策略自动重建', () async {
      // 构造一个 schema 12 结构的旧库文件：
      // - 只有旧的 reason 表（没有 normalized_name 列）
      // - 且带有一个旧的 LOWER(name) 唯一索引
      final Directory dir = await Directory.systemTemp.createTemp(
        'drift_upgrade_test',
      );
      addTearDown(() async {
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      });
      final File dbFile = File(
        '${dir.path}${Platform.pathSeparator}legacy.sqlite',
      );

      final sqlite.Database legacy = sqlite.sqlite3.open(dbFile.path);
      try {
        legacy.execute(
          'CREATE TABLE reason ('
          'reason_id TEXT NOT NULL PRIMARY KEY, '
          'name TEXT NOT NULL, '
          'description TEXT, '
          'enabled INTEGER NOT NULL DEFAULT 1, '
          'created_at INTEGER NOT NULL, '
          'updated_at INTEGER NOT NULL'
          ');',
        );
        legacy.execute(
          'CREATE UNIQUE INDEX idx_reason_name ON reason(name COLLATE NOCASE);',
        );
        legacy.execute('PRAGMA user_version = 12;');
      } finally {
        legacy.dispose();
      }

      // 用当前 schema(13) 打开旧库，触发 onUpgrade
      final AppDatabase upgraded = AppDatabase.forTesting(
        NativeDatabase(dbFile),
      );
      addTearDown(() async {
        await upgraded.close();
      });

      // 验证数据库可正常打开，且 reason 表已重建出 normalized_name 列
      final List<QueryRow> columns = await upgraded
          .customSelect("PRAGMA table_info('reason');")
          .get();
      final bool hasNormalizedColumn = columns.any(
        (row) => (row.data['name'] as String?) == 'normalized_name',
      );
      expect(hasNormalizedColumn, isTrue);

      // 验证新结构可正常写入并查询
      await upgraded.reasonsDao.create(name: '婚礼礼金');
      final List<Reason> reasons = await upgraded.reasonsDao.listAll();
      expect(reasons, hasLength(1));
      expect(reasons.single.normalizedName, '婚礼礼金');
    });
  });
}
