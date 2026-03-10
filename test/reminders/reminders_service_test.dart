import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/reminders/reminders_service.dart';

void main() {
  group('RemindersService', () {
    late AppDatabase db;
    late RemindersService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = RemindersService(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('创建/更新/切换完成/删除：可正确落库并反映状态', () async {
      final now = DateTime.now();
      final bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );

      final reminderId = await service.create(
        bookId: bookId,
        title: '张伟生日',
        reminderType: '生日',
        targetDate: DateTime(2026, 3, 2),
        remindAt: DateTime(2026, 3, 2, 9, 0),
        repeatRule: ReminderRepeatRule.yearly,
        note: '准备红包',
      );

      final created = await db.eventRemindersDao.findById(reminderId);
      expect(created, isNotNull);
      expect(created!.title, '张伟生日');
      expect(created.reminderType, '生日');
      expect(created.repeatRule, 'yearly');
      expect(created.status, 'active');

      final ok = await service.update(
        reminderId: reminderId,
        title: '张伟生日（更新）',
        reminderType: '生日',
        targetDate: DateTime(2026, 3, 2),
        remindAt: DateTime(2026, 3, 2, 10, 30),
        repeatRule: ReminderRepeatRule.none,
        note: '改为上午10:30提醒',
      );
      expect(ok, isTrue);

      final updated = await db.eventRemindersDao.findById(reminderId);
      expect(updated, isNotNull);
      expect(updated!.title, '张伟生日（更新）');
      expect(updated.repeatRule, 'none');
      expect(updated.note, '改为上午10:30提醒');

      final status1 = await service.toggleDone(reminderId);
      expect(status1, 'done');
      expect((await db.eventRemindersDao.findById(reminderId))!.status, 'done');

      final status2 = await service.toggleDone(reminderId);
      expect(status2, 'active');
      expect((await db.eventRemindersDao.findById(reminderId))!.status, 'active');

      final deleted = await service.deleteById(reminderId);
      expect(deleted, 1);
      expect(await db.eventRemindersDao.findById(reminderId), isNull);
    });
  });
}

