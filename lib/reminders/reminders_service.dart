import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lunar/lunar.dart';
import '../data/local/drift/app_database.dart';

/// 重复规则（提醒的重复触发策略）。
///
/// 说明：
/// - 数据库存储为字符串（event_reminder.repeat_rule），这里做一层类型化封装，便于校验与 UI 显示；
/// - 当前实现覆盖常见规则：不重复/每天/每周/每月/每年；
/// - 如需扩展自定义规则（例如“每两周”），建议在存储层继续使用字符串，解析层做版本化兼容。
enum ReminderRepeatRule {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  lunarYearly,
}

/// 提醒业务异常（用于将“可预期的业务错误”与其它异常区分开）。
class ReminderException implements Exception {
  const ReminderException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 提醒模块“后端 API”（App 内部的业务服务层）。
///
/// 你可以把它理解为：
/// - UI 只负责收集用户输入、呈现状态；
/// - 具体的校验、落库、状态切换、时间字段格式化等由此服务统一完成；
/// - 未来如果接入真实后端 HTTP API，也可以用同样的函数签名替换实现。
class RemindersService {
  RemindersService({required AppDatabase db}) : _db = db;

  final AppDatabase _db;
  static const List<String> defaultTypes = <String>['生日', '回礼', '纪念日'];

  /// 创建提醒并落库，返回新 reminderId。
  Future<String> create({
    required String bookId,
    required String title,
    required DateTime targetDate,
    required DateTime remindAt,
    ReminderRepeatRule repeatRule = ReminderRepeatRule.none,
    String reminderType = '自定义',
    String? personId,
    List<String> relationPersonIds = const <String>[],
    String channel = 'notification',
    String? note,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ReminderException('标题不能为空');
    }
    final trimmedBookId = bookId.trim();
    if (trimmedBookId.isEmpty) {
      throw const ReminderException('账簿不能为空');
    }
    final trimmedType = reminderType.trim().isEmpty ? '自定义' : reminderType.trim();
    final trimmedChannel = channel.trim().isEmpty ? 'notification' : channel.trim();

    await ensureBuiltInTypes(trimmedBookId);
    await addCustomType(bookId: trimmedBookId, name: trimmedType);

    final target = _formatYmd(targetDate);
    final remindAtMs = remindAt.millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final normalizedRelationPersonIds = _normalizeIds(relationPersonIds);

    return _db.eventRemindersDao.insertOne(
      EventRemindersCompanion(
        bookId: Value(trimmedBookId),
        personId: (personId ?? '').trim().isEmpty ? const Value.absent() : Value(personId!.trim()),
        relationPersonIds: Value(jsonEncode(normalizedRelationPersonIds)),
        reminderType: Value(trimmedType),
        title: Value(trimmedTitle),
        targetDate: Value(target),
        remindAt: Value(remindAtMs),
        repeatRule: Value(repeatRule.name),
        status: const Value('active'),
        channel: Value(trimmedChannel),
        note: (note ?? '').trim().isEmpty ? const Value.absent() : Value(note!.trim()),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// 更新提醒（按 reminderId），返回更新是否成功。
  Future<bool> update({
    required String reminderId,
    required String title,
    required DateTime targetDate,
    required DateTime remindAt,
    ReminderRepeatRule repeatRule = ReminderRepeatRule.none,
    String reminderType = '自定义',
    String? personId,
    List<String> relationPersonIds = const <String>[],
    String channel = 'notification',
    String? note,
  }) async {
    final existing = await _db.eventRemindersDao.findById(reminderId.trim());
    if (existing == null) {
      throw const ReminderException('提醒不存在或已被删除');
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ReminderException('标题不能为空');
    }
    final trimmedType = reminderType.trim().isEmpty ? '自定义' : reminderType.trim();
    final trimmedChannel = channel.trim().isEmpty ? existing.channel : channel.trim();
    final normalizedRelationPersonIds = _normalizeIds(relationPersonIds);

    await ensureBuiltInTypes(existing.bookId);
    await addCustomType(bookId: existing.bookId, name: trimmedType);

    final updated = existing.copyWith(
      personId: Value((personId ?? '').trim().isEmpty ? null : personId!.trim()),
      relationPersonIds: jsonEncode(normalizedRelationPersonIds),
      reminderType: trimmedType,
      title: trimmedTitle,
      targetDate: _formatYmd(targetDate),
      remindAt: remindAt.millisecondsSinceEpoch,
      repeatRule: repeatRule.name,
      channel: trimmedChannel,
      note: Value((note ?? '').trim().isEmpty ? null : note!.trim()),
    );

    return _db.eventRemindersDao.updateOne(updated);
  }

  Future<void> ensureBuiltInTypes(String bookId) async {
    final trimmedBookId = bookId.trim();
    if (trimmedBookId.isEmpty) return;
    for (final type in defaultTypes) {
      final found = await _db.reminderTypesDao.findByName(bookId: trimmedBookId, name: type);
      if (found != null) continue;
      await _db.reminderTypesDao.insertOne(
        ReminderTypesCompanion(
          bookId: Value(trimmedBookId),
          name: Value(type),
          isCustom: const Value(false),
        ),
      );
    }
  }

  Future<bool> addCustomType({
    required String bookId,
    required String name,
  }) async {
    final trimmedBookId = bookId.trim();
    final trimmedName = name.trim();
    if (trimmedBookId.isEmpty || trimmedName.isEmpty) return false;
    if (defaultTypes.contains(trimmedName)) return false;
    final existing = await _db.reminderTypesDao.findByName(bookId: trimmedBookId, name: trimmedName);
    if (existing != null) return false;
    await _db.reminderTypesDao.insertOne(
      ReminderTypesCompanion(
        bookId: Value(trimmedBookId),
        name: Value(trimmedName),
        isCustom: const Value(true),
      ),
    );
    return true;
  }

  Stream<List<String>> watchTypeOptions(String bookId) async* {
    await ensureBuiltInTypes(bookId);
    await for (final rows in _db.reminderTypesDao.watchAllInBook(bookId)) {
      final names = rows.map((e) => e.name.trim()).where((e) => e.isNotEmpty).toList();
      yield names;
    }
  }

  /// 删除提醒，返回删除行数（0 表示不存在）。
  Future<int> deleteById(String reminderId) {
    return _db.eventRemindersDao.deleteById(reminderId.trim());
  }

  /// 切换完成/未完成状态（done <-> active），并返回最新状态。
  Future<String> toggleDone(String reminderId) async {
    final r = await _db.eventRemindersDao.findById(reminderId.trim());
    if (r == null) {
      throw const ReminderException('提醒不存在或已被删除');
    }
    if (r.status == 'done') {
      await _db.eventRemindersDao.markActive(r.reminderId);
      return 'active';
    }
    await _db.eventRemindersDao.markDone(r.reminderId);
    return 'done';
  }

  /// 将重复规则字符串解析为枚举；遇到未知值时回退为 none，保证兼容旧数据/脏数据。
  static ReminderRepeatRule parseRepeatRule(String raw) {
    final v = raw.trim();
    for (final e in ReminderRepeatRule.values) {
      if (e.name == v) return e;
    }
    return ReminderRepeatRule.none;
  }

  static List<String> parseRelationPersonIds(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return const <String>[];
      return _normalizeIds(decoded.whereType<String>());
    } catch (_) {
      return const <String>[];
    }
  }

  static String buildCronExpression({
    required ReminderRepeatRule repeatRule,
    required DateTime remindAt,
    DateTime? targetDate,
  }) {
    final minute = remindAt.minute;
    final hour = remindAt.hour;
    switch (repeatRule) {
      case ReminderRepeatRule.none:
        if (targetDate == null) return '$minute $hour * * *';
        return '$minute $hour ${targetDate.day} ${targetDate.month} *';
      case ReminderRepeatRule.daily:
        return '$minute $hour * * *';
      case ReminderRepeatRule.weekly:
        if (targetDate == null) return '$minute $hour * * 1';
        final weekday = targetDate.weekday % 7;
        return '$minute $hour * * $weekday';
      case ReminderRepeatRule.monthly:
        if (targetDate == null) return '$minute $hour 1 * *';
        return '$minute $hour ${targetDate.day} * *';
      case ReminderRepeatRule.yearly:
        if (targetDate == null) return '$minute $hour 1 1 *';
        return '$minute $hour ${targetDate.day} ${targetDate.month} *';
      case ReminderRepeatRule.lunarYearly:
        final date = targetDate ?? remindAt;
        final lunar = Lunar.fromDate(date);
        final leap = lunar.getMonth() < 0 ? 1 : 0;
        return 'lunarYearly:$minute $hour ${lunar.getDay()} ${lunar.getMonth()} $leap';
    }
  }

  static Iterable<DateTime> generateNextOccurrences({
    required ReminderRepeatRule repeatRule,
    required DateTime startAt,
    required int count,
  }) sync* {
    var current = startAt;
    for (var i = 0; i < count; i++) {
      yield current;
      switch (repeatRule) {
        case ReminderRepeatRule.none:
          return;
        case ReminderRepeatRule.daily:
          current = current.add(const Duration(days: 1));
          break;
        case ReminderRepeatRule.weekly:
          current = current.add(const Duration(days: 7));
          break;
        case ReminderRepeatRule.monthly:
          current = DateTime(
            current.year,
            current.month + 1,
            current.day,
            current.hour,
            current.minute,
          );
          break;
        case ReminderRepeatRule.yearly:
          current = DateTime(
            current.year + 1,
            current.month,
            current.day,
            current.hour,
            current.minute,
          );
          break;
        case ReminderRepeatRule.lunarYearly:
          current = _nextLunarYearly(current);
          break;
      }
    }
  }

  static DateTime _nextLunarYearly(DateTime current) {
    final source = Lunar.fromDate(current);
    final nextLunarYear = source.getYear() + 1;
    final month = source.getMonth().abs();
    final day = source.getDay();
    final leap = source.getMonth() < 0;
    var solar = Lunar.fromYmd(nextLunarYear, month, day).getSolar();
    if (leap) {
      try {
        solar = Lunar.fromYmdHms(nextLunarYear, -month, day, current.hour, current.minute, 0).getSolar();
      } catch (_) {
        solar = Lunar.fromYmd(nextLunarYear, month, day).getSolar();
      }
    }
    return DateTime(
      solar.getYear(),
      solar.getMonth(),
      solar.getDay(),
      current.hour,
      current.minute,
    );
  }

  static List<String> _normalizeIds(Iterable<String> src) {
    final out = <String>[];
    final seen = <String>{};
    for (final item in src) {
      final v = item.trim();
      if (v.isEmpty) continue;
      if (seen.add(v)) out.add(v);
    }
    return out;
  }

  /// 将日期格式化为 yyyy-MM-dd（用于 event_reminder.target_date）。
  static String _formatYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
