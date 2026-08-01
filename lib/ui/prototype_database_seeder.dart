import 'package:drift/drift.dart';

import '../data/local/drift/app_database.dart';

class PrototypeDatabaseSeeder {
  static String _normalizeName(String value) => value.trim().toLowerCase();

  static Future<void> seed(AppDatabase db) async {
    final countExp = db.accountBooks.bookId.count();
    final row = await (db.selectOnly(
      db.accountBooks,
    )..addColumns([countExp])).getSingle();
    final existing = row.read(countExp) ?? 0;
    if (existing > 0) return;

    final now = DateTime.now();
    int ms(DateTime d) => d.millisecondsSinceEpoch;

    final defaultBookCreatedAt = now.subtract(const Duration(days: 365));
    await db
        .into(db.accountBooks)
        .insert(
          AccountBook(
            bookId: 'book_default',
            name: '默认账簿',
            reasonType: '',
            themeColor: '#312E81',
            icon: null,
            description: null,
            attachments: null,
            bookTime: ms(defaultBookCreatedAt),
            isDefault: 1,
            createdAt: ms(defaultBookCreatedAt),
            updatedAt: ms(defaultBookCreatedAt),
            deletedAt: null,
          ),
        );

    final persons = <Person>[
      Person(
        personId: 'p_zhangwei',
        bookId: 'book_default',
        name: '张伟',
        relationshipType: '朋友',
        phone: '13800000001',
        birthday: null,
        anniversary: null,
        avatarUri:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
        note: '大学室友，喜欢喝茶',
        createdAt: ms(now.subtract(const Duration(days: 320))),
        updatedAt: ms(now.subtract(const Duration(days: 320))),
        deletedAt: null,
      ),
      Person(
        personId: 'p_lina',
        bookId: 'book_default',
        name: '李娜',
        relationshipType: '亲戚 - 表妹',
        phone: '13800000002',
        birthday: null,
        anniversary: null,
        avatarUri:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
        note: null,
        createdAt: ms(now.subtract(const Duration(days: 280))),
        updatedAt: ms(now.subtract(const Duration(days: 280))),
        deletedAt: null,
      ),
      Person(
        personId: 'p_wangqiang',
        bookId: 'book_default',
        name: '王强',
        relationshipType: '同学',
        phone: '13800000003',
        birthday: null,
        anniversary: null,
        avatarUri:
            'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100&h=100&fit=crop',
        note: null,
        createdAt: ms(now.subtract(const Duration(days: 210))),
        updatedAt: ms(now.subtract(const Duration(days: 210))),
        deletedAt: null,
      ),
      Person(
        personId: 'p_zhaotiezhu',
        bookId: 'book_default',
        name: '赵铁柱',
        relationshipType: '邻居',
        phone: '13800000004',
        birthday: null,
        anniversary: null,
        avatarUri: null,
        note: null,
        createdAt: ms(now.subtract(const Duration(days: 150))),
        updatedAt: ms(now.subtract(const Duration(days: 150))),
        deletedAt: null,
      ),
      Person(
        personId: 'p_aliang',
        bookId: 'book_default',
        name: '阿强',
        relationshipType: '同事',
        phone: '13800000005',
        birthday: null,
        anniversary: null,
        avatarUri: null,
        note: null,
        createdAt: ms(now.subtract(const Duration(days: 60))),
        updatedAt: ms(now.subtract(const Duration(days: 60))),
        deletedAt: null,
      ),
      Person(
        personId: 'p_lianguo',
        bookId: 'book_default',
        name: '李建国',
        relationshipType: '长辈',
        phone: '13800000006',
        birthday: null,
        anniversary: null,
        avatarUri: null,
        note: null,
        createdAt: ms(now.subtract(const Duration(days: 30))),
        updatedAt: ms(now.subtract(const Duration(days: 30))),
        deletedAt: null,
      ),
    ];
    await db.batch((batch) {
      batch.insertAll(db.persons, persons);
    });

    final y = now.year;
    final records = <GiftRecord>[
      GiftRecord(
        recordId: 'r_20260210_zw',
        bookId: 'book_default',
        personId: 'p_zhangwei',
        direction: '收入',
        amountCent: 200000,
        currency: 'CNY',
        eventName: '结婚礼金',
        occurredAt: ms(DateTime(y, 2, 10, 12, 30)),
        paymentMethod: '微信支付',
        note: '现场收礼',
        attachments: null,
        createdAt: ms(now),
        updatedAt: ms(now),
        deletedAt: null,
      ),
      GiftRecord(
        recordId: 'r_20260208_ln',
        bookId: 'book_default',
        personId: 'p_lina',
        direction: '支出',
        amountCent: 80000,
        currency: 'CNY',
        eventName: '孩子满月',
        occurredAt: ms(DateTime(y, 2, 8, 19, 10)),
        paymentMethod: '现金',
        note: null,
        attachments: null,
        createdAt: ms(now),
        updatedAt: ms(now),
        deletedAt: null,
      ),
      GiftRecord(
        recordId: 'r_20260205_wq',
        bookId: 'book_default',
        personId: 'p_wangqiang',
        direction: '支出',
        amountCent: 120000,
        currency: 'CNY',
        eventName: '乔迁之喜',
        occurredAt: ms(DateTime(y, 2, 5, 18, 45)),
        paymentMethod: '支付宝',
        note: null,
        attachments: null,
        createdAt: ms(now),
        updatedAt: ms(now),
        deletedAt: null,
      ),
      GiftRecord(
        recordId: 'r_20260124_ztz',
        bookId: 'book_default',
        personId: 'p_zhaotiezhu',
        direction: '收入',
        amountCent: 50000,
        currency: 'CNY',
        eventName: '春节红包',
        occurredAt: ms(DateTime(y, 1, 24, 10, 0)),
        paymentMethod: '微信',
        note: null,
        attachments: null,
        createdAt: ms(now),
        updatedAt: ms(now),
        deletedAt: null,
      ),
      GiftRecord(
        recordId: 'r_20260115_lg',
        bookId: 'book_default',
        personId: 'p_lianguo',
        direction: '收入',
        amountCent: 100000,
        currency: 'CNY',
        eventName: '公司年会',
        occurredAt: ms(DateTime(y, 1, 15, 21, 5)),
        paymentMethod: '现金',
        note: null,
        attachments: null,
        createdAt: ms(now),
        updatedAt: ms(now),
        deletedAt: null,
      ),
      GiftRecord(
        recordId: 'r_20251212_aq',
        bookId: 'book_default',
        personId: 'p_aliang',
        direction: '支出',
        amountCent: 30000,
        currency: 'CNY',
        eventName: '探望',
        occurredAt: ms(DateTime(y - 1, 12, 12, 14, 20)),
        paymentMethod: '微信',
        note: '顺路带点心意',
        attachments: null,
        createdAt: ms(now),
        updatedAt: ms(now),
        deletedAt: null,
      ),
    ];
    await db.batch((batch) {
      batch.insertAll(db.giftRecords, records);
    });

    final reasonNames =
        records
            .map((e) => (e.eventName ?? '').trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.compareTo(b));
    final reasons = <Reason>[];
    for (var i = 0; i < reasonNames.length; i++) {
      final name = reasonNames[i];
      reasons.add(
        Reason(
          reasonId: 'reason_${i + 1}',
          name: name,
          normalizedName: _normalizeName(name),
          description: null,
          enabled: true,
          createdAt: ms(now),
          updatedAt: ms(now),
        ),
      );
    }
    await db.batch((batch) {
      batch.insertAll(db.reasons, reasons, mode: InsertMode.insertOrReplace);
    });

    final relationTypes = <RelationType>[
      RelationType(
        typeId: 'rt_friend',
        name: '朋友',
        normalizedName: _normalizeName('朋友'),
        createdAt: ms(now),
        updatedAt: ms(now),
      ),
      RelationType(
        typeId: 'rt_family',
        name: '家人',
        normalizedName: _normalizeName('家人'),
        createdAt: ms(now),
        updatedAt: ms(now),
      ),
      RelationType(
        typeId: 'rt_colleague',
        name: '同事',
        normalizedName: _normalizeName('同事'),
        createdAt: ms(now),
        updatedAt: ms(now),
      ),
    ];
    await db.batch((batch) {
      batch.insertAll(
        db.relationTypes,
        relationTypes,
        mode: InsertMode.insertOrReplace,
      );
    });
    await db
        .into(db.contactRelations)
        .insert(
          ContactRelation(
            relationId: 'cr_zhangwei_wangqiang_friend',
            personAId: 'p_zhangwei',
            personBId: 'p_wangqiang',
            typeId: 'rt_friend',
            note: null,
            createdAt: ms(now),
            updatedAt: ms(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
