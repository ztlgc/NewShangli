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
        relationPersonIds: const <String>['p_1', 'p_2'],
        targetDate: DateTime(2026, 3, 2),
        remindAt: DateTime(2026, 3, 2, 9, 0),
        repeatRule: ReminderRepeatRule.yearly,
        note: '准备红包',
      );

      final created = await db.eventRemindersDao.findById(reminderId);
      expect(created, isNotNull);
      expect(created!.title, '张伟生日');
      expect(created.reminderType, '生日');
      expect(created.relationPersonIds, '["p_1","p_2"]');
      expect(created.repeatRule, 'yearly');
      expect(created.status, 'active');

      final ok = await service.update(
        reminderId: reminderId,
        title: '张伟生日（更新）',
        reminderType: '生日',
        relationPersonIds: const <String>['p_2', 'p_3'],
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
      expect(updated.relationPersonIds, '["p_2","p_3"]');
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

    test('可新增自定义提醒类型，并完成重名拦截', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          name: '测试账簿',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await service.ensureBuiltInTypes(bookId);
      final firstAdd = await service.addCustomType(bookId: bookId, name: '升学宴');
      final secondAdd = await service.addCustomType(bookId: bookId, name: '升学宴');
      expect(firstAdd, isTrue);
      expect(secondAdd, isFalse);
    });

    test('lunarYearly 规则可生成 cron 表达式', () {
      final expression = RemindersService.buildCronExpression(
        repeatRule: ReminderRepeatRule.lunarYearly,
        remindAt: DateTime(2026, 2, 17, 8, 30),
        targetDate: DateTime(2026, 2, 17),
      );
      expect(expression.startsWith('lunarYearly:'), isTrue);
      expect(expression, contains('30 8'));
    });

    test('lunarYearly 可生成连续触发时间并保持时间精度', () {
      final list = RemindersService.generateNextOccurrences(
        repeatRule: ReminderRepeatRule.lunarYearly,
        startAt: DateTime(2026, 2, 17, 7, 45),
        count: 3,
      ).toList();
      expect(list.length, 3);
      expect(list[1].hour, 7);
      expect(list[1].minute, 45);
      expect(list[1].difference(list[0]).inDays, greaterThanOrEqualTo(340));
    });

    test('lunarYearly 在闰月场景下可映射到下一年', () {
      final list = RemindersService.generateNextOccurrences(
        repeatRule: ReminderRepeatRule.lunarYearly,
        startAt: DateTime(2020, 6, 1, 9, 0),
        count: 2,
      ).toList();
      expect(list.length, 2);
      expect(list[1].isAfter(list[0]), isTrue);
      expect(list[1].difference(list[0]).inDays, lessThanOrEqualTo(390));
    });

    test('lunarYearly 批量生成性能满足基线', () {
      final watch = Stopwatch()..start();
      final list = RemindersService.generateNextOccurrences(
        repeatRule: ReminderRepeatRule.lunarYearly,
        startAt: DateTime(2026, 2, 17, 10, 0),
        count: 200,
      ).toList();
      watch.stop();
      expect(list.length, 200);
      expect(watch.elapsedMilliseconds, lessThan(600));
    });
  });
}
