import 'dart:io';

import 'package:drift/drift.dart';
import 'package:newshangli/data/local/drift/app_database.dart';

Future<void> seedTransferData(AppDatabase db, Directory directory) async {
  final at = DateTime(2026, 10, 1).millisecondsSinceEpoch;
  final avatar = File('${directory.path}/avatar.png')
    ..writeAsBytesSync([1, 2, 3]);
  final attachment = File('${directory.path}/gift.jpg')
    ..writeAsBytesSync([4, 5, 6]);
  await db.transaction(() async {
    for (final (id, name, isDefault) in [
      ('default', '日常礼账', 1),
      ('other', '婚礼礼账', 0),
    ]) {
      await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          bookId: Value(id),
          name: name,
          isDefault: Value(isDefault),
          createdAt: at,
          updatedAt: at,
        ),
      );
    }
    for (final (id, name, book) in [
      ('p1', '张伟', 'default'),
      ('p2', '李娜', 'other'),
      ('p3', '王芳', 'default'),
    ]) {
      await db.personsDao.insertOne(
        PersonsCompanion.insert(
          personId: Value(id),
          bookId: book,
          name: name,
          avatarUri: id == 'p1' ? Value(avatar.path) : const Value.absent(),
          createdAt: at,
          updatedAt: at,
        ),
      );
    }
    for (final (id, book, person, direction, amount, date) in [
      ('r1', 'default', 'p1', '收入', 100000, DateTime(2026, 10, 1)),
      ('r2', 'other', 'p2', '支出', 60000, DateTime(2026, 10, 5)),
      ('r3', 'other', 'p2', '收入', 80000, DateTime(2026, 9, 1)),
    ]) {
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          recordId: Value(id),
          bookId: book,
          personId: person,
          direction: Value(direction),
          amountCent: amount,
          occurredAt: date.millisecondsSinceEpoch,
          attachments: id == 'r1'
              ? Value([attachment.path])
              : const Value.absent(),
          createdAt: at,
          updatedAt: at,
        ),
      );
    }
  });
}

File writeTransferCsv(
  Directory directory, {
  String name = 'import.csv',
  int rows = 2,
  bool aliases = false,
}) {
  final file = File('${directory.path}/$name');
  final headers = aliases
      ? '类型,方向,金额元,姓名,时间,备注'
      : '数据类型,收支方向,金额(元),联系人姓名,发生时间,备注';
  file.writeAsStringSync(
    [
      headers,
      for (var index = 0; index < rows; index++)
        '礼金收支记录,收入,${100 + index}.25,测试联系人$index,2026-10-${(index % 20 + 1).toString().padLeft(2, '0')} 12:00,导入备注$index',
    ].join('\n'),
  );
  return file;
}
