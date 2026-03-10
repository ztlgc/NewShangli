import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/default_book_service.dart';
import '../../reminders/reminders_service.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../prototype_kit.dart';
import '../navigation.dart';
import 'reminder_edit_page.dart';
import 'person_list_page.dart';
import 'record_home_page.dart';
import 'settings_home_page.dart';
import 'stats_page.dart';

/// 页面：事件提醒
/// 对照原型：prototype/index.html -> "事件提醒"
class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(),
    );
  }
}

enum _StatusFilter { all, active, done }

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  _StatusFilter _statusFilter = _StatusFilter.active;
  String _typeFilter = '全部';

  RemindersService get _service => RemindersService(db: AppDatabaseScope.of(context));

  Future<void> _openCreate(String bookId) async {
    final ok = await AppNav.push<bool>(
      context,
      ReminderEditPage(bookId: bookId),
      requiresLogin: true,
    );
    if (!mounted) return;
    if (ok == true) {
      _toast('已保存');
    }
  }

  Future<void> _openEdit(String bookId, String reminderId) async {
    final ok = await AppNav.push<bool>(
      context,
      ReminderEditPage(bookId: bookId, reminderId: reminderId),
      requiresLogin: true,
    );
    if (!mounted) return;
    if (ok == true) {
      _toast('已更新');
    }
  }

  Future<void> _toggleDone(String reminderId) async {
    try {
      final status = await _service.toggleDone(reminderId);
      if (!mounted) return;
      _toast(status == 'done' ? '已标记完成' : '已标记未完成');
    } on ReminderException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      _toast('操作失败：$e');
    }
  }

  Future<void> _delete(String reminderId) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size.height - 24),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadii.br2xl,
                  boxShadow: AppShadows.lg,
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '确认删除提醒',
                                style: AppTypography.base(
                                  fontSize: 14,
                                  fontWeight: AppTypography.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            PrototypeIconButton(
                              icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                              backgroundColor: AppColors.gray100,
                              foregroundColor: AppColors.textSecondary,
                              onPressed: () => Navigator.of(context).pop(false),
                              radius: 12,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '删除后无法恢复。',
                              style: AppTypography.base(
                                fontSize: 13,
                                fontWeight: AppTypography.regular,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: PrototypeSecondaryButton(
                                    label: '取消',
                                    onTap: () => Navigator.of(context).pop(false),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PrototypePrimaryButton(
                                    label: '确认删除',
                                    onTap: () => Navigator.of(context).pop(true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    try {
      final deleted = await _service.deleteById(reminderId);
      if (!mounted) return;
      _toast(deleted > 0 ? '已删除' : '提醒不存在');
    } catch (e) {
      if (!mounted) return;
      _toast('删除失败：$e');
    }
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return FutureBuilder<String>(
      future: DefaultBookService().ensureDefaultBookId(db),
      builder: (context, snapshot) {
        final bookId = snapshot.data;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
              ),
              child: Row(
                children: [
                  Text('提醒', style: AppTypography.h2().copyWith(fontSize: 20)),
                  const Spacer(),
                  PrototypeIconButton(
                    key: const ValueKey<String>('reminder_add'),
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                    backgroundColor: AppColors.gray100,
                    foregroundColor: AppColors.textSecondary,
                    onPressed: bookId == null ? null : () => _openCreate(bookId),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.borderDivider, width: 1)),
              ),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: '未完成',
                      selected: _statusFilter == _StatusFilter.active,
                      onTap: () => setState(() => _statusFilter = _StatusFilter.active),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: '已完成',
                      selected: _statusFilter == _StatusFilter.done,
                      onTap: () => setState(() => _statusFilter = _StatusFilter.done),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: '全部',
                      selected: _statusFilter == _StatusFilter.all,
                      onTap: () => setState(() => _statusFilter = _StatusFilter.all),
                    ),
                    const SizedBox(width: 16),
                    _FilterChip(
                      label: '生日',
                      selected: _typeFilter == '生日',
                      onTap: () => setState(() => _typeFilter = '生日'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: '回礼',
                      selected: _typeFilter == '回礼',
                      onTap: () => setState(() => _typeFilter = '回礼'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: '纪念日',
                      selected: _typeFilter == '纪念日',
                      onTap: () => setState(() => _typeFilter = '纪念日'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: '全部类型',
                      selected: _typeFilter == '全部',
                      onTap: () => setState(() => _typeFilter = '全部'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: bookId == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<EventReminder>>(
                      stream: db.eventRemindersDao.watchAllInBook(bookId),
                      builder: (context, snapshot) {
                        final all = snapshot.data ?? const <EventReminder>[];
                        final filtered = _applyFilters(all);
                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              '暂无提醒',
                              style: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.regular,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        final sections = _buildSections(filtered);
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          children: [
                            for (final s in sections) ...[
                              _Overline(title: s.title),
                              const SizedBox(height: 12),
                              for (final r in s.items) ...[
                                _ReminderCard(
                                  reminder: r,
                                  onTap: () => _openEdit(bookId, r.reminderId),
                                  onToggleDone: () => _toggleDone(r.reminderId),
                                  onDelete: () => _delete(r.reminderId),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                    ),
            ),
            PrototypeBottomNav(
              activeIndex: -1,
              onTap: (index) {
                if (index == 0) {
                  AppNav.replaceRoot(context, const RecordHomePage());
                  return;
                }
                if (index == 1) {
                  AppNav.replaceRoot(context, const PersonListPage());
                  return;
                }
                if (index == 2) {
                  AppNav.replaceRoot(context, const StatsPage());
                  return;
                }
                if (index == 3) {
                  AppNav.replaceRoot(context, const SettingsHomePage());
                  return;
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<EventReminder> _applyFilters(List<EventReminder> src) {
    final out = <EventReminder>[];
    for (final r in src) {
      if (_statusFilter == _StatusFilter.active && r.status != 'active') continue;
      if (_statusFilter == _StatusFilter.done && r.status != 'done') continue;
      if (_typeFilter != '全部' && r.reminderType.trim() != _typeFilter) continue;
      out.add(r);
    }
    out.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    return out;
  }

  List<_Section> _buildSections(List<EventReminder> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));
    final overdue = <EventReminder>[];
    final week = <EventReminder>[];
    final future = <EventReminder>[];
    final done = <EventReminder>[];

    for (final r in list) {
      if (r.status == 'done') {
        done.add(r);
        continue;
      }
      final dt = DateTime.fromMillisecondsSinceEpoch(r.remindAt);
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day.isBefore(today)) {
        overdue.add(r);
      } else if (day.isBefore(weekEnd)) {
        week.add(r);
      } else {
        future.add(r);
      }
    }

    final sections = <_Section>[];
    if (overdue.isNotEmpty) sections.add(_Section(title: '已过期', items: overdue));
    if (week.isNotEmpty) sections.add(_Section(title: '本周', items: week));
    if (future.isNotEmpty) sections.add(_Section(title: '未来', items: future));
    if (_statusFilter != _StatusFilter.active && done.isNotEmpty) {
      sections.add(_Section(title: '已完成', items: done));
    }
    if (_statusFilter == _StatusFilter.done) {
      return done.isEmpty ? <_Section>[] : <_Section>[_Section(title: '已完成', items: done)];
    }
    if (_statusFilter == _StatusFilter.all && done.isNotEmpty) {
      if (sections.every((e) => e.title != '已完成')) {
        sections.add(_Section(title: '已完成', items: done));
      }
    }
    return sections;
  }
}

class _Section {
  const _Section({required this.title, required this.items});
  final String title;
  final List<EventReminder> items;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : AppColors.gray100,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: selected ? AppShadows.brandSoft : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.medium,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Overline extends StatelessWidget {
  const _Overline({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.base(
          fontSize: 12,
          fontWeight: AppTypography.bold,
          color: AppColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onToggleDone,
    required this.onDelete,
  });

  final EventReminder reminder;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(reminder.remindAt);
    final badge = _badgeOf(dt, reminder.status);
    final colors = _badgeColors(badge.kind, reminder.status);

    final repeat = RemindersService.parseRepeatRule(reminder.repeatRule);
    final repeatLabel = _repeatRuleLabel(repeat);
    final type = reminder.reminderType.trim().isEmpty ? '自定义' : reminder.reminderType.trim();
    final subtitle = '${_formatYmdHm(dt)} · $type · $repeatLabel';

    return PressableScale(
      onTap: onTap,
      child: Container(
        key: ValueKey<String>('reminder_card_${reminder.reminderId}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
          border: Border(left: BorderSide(color: colors.border, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.badgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge.text,
                          style: AppTypography.base(
                            fontSize: 10,
                            fontWeight: AppTypography.bold,
                            color: colors.badgeFg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reminder.title.trim().isEmpty ? '未命名提醒' : reminder.title.trim(),
                          style: AppTypography.base(
                            fontSize: 16,
                            fontWeight: AppTypography.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.regular,
                      color: AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((reminder.note ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.note!.trim(),
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                PressableScale(
                  onTap: onToggleDone,
                  child: Container(
                    key: ValueKey<String>('reminder_toggle_${reminder.reminderId}'),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: reminder.status == 'done' ? AppColors.gray100 : AppColors.green50,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: FaIcon(
                      reminder.status == 'done' ? FontAwesomeIcons.rotateLeft : FontAwesomeIcons.check,
                      size: 12,
                      color: reminder.status == 'done' ? AppColors.textSecondary : AppColors.green600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PressableScale(
                  onTap: onDelete,
                  child: Container(
                    key: ValueKey<String>('reminder_delete_${reminder.reminderId}'),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.red500.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const FaIcon(FontAwesomeIcons.trash, size: 12, color: AppColors.red500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _BadgeKind { overdue, today, tomorrow, soon, future, done }

class _Badge {
  const _Badge({required this.kind, required this.text});
  final _BadgeKind kind;
  final String text;
}

_Badge _badgeOf(DateTime remindAt, String status) {
  if (status == 'done') return const _Badge(kind: _BadgeKind.done, text: '已完成');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(remindAt.year, remindAt.month, remindAt.day);
  final diff = day.difference(today).inDays;
  if (diff < 0) return const _Badge(kind: _BadgeKind.overdue, text: '已过期');
  if (diff == 0) return const _Badge(kind: _BadgeKind.today, text: '今天');
  if (diff == 1) return const _Badge(kind: _BadgeKind.tomorrow, text: '明天');
  if (diff <= 3) return _Badge(kind: _BadgeKind.soon, text: '${diff}天后');
  return _Badge(kind: _BadgeKind.future, text: '${diff}天后');
}

class _BadgeColorSet {
  const _BadgeColorSet({
    required this.border,
    required this.badgeBg,
    required this.badgeFg,
  });

  final Color border;
  final Color badgeBg;
  final Color badgeFg;
}

_BadgeColorSet _badgeColors(_BadgeKind kind, String status) {
  if (status == 'done') {
    return const _BadgeColorSet(
      border: AppColors.gray200,
      badgeBg: AppColors.gray100,
      badgeFg: AppColors.textSecondary,
    );
  }
  switch (kind) {
    case _BadgeKind.overdue:
      return const _BadgeColorSet(
        border: AppColors.red500,
        badgeBg: AppColors.red100,
        badgeFg: AppColors.red600,
      );
    case _BadgeKind.today:
      return const _BadgeColorSet(
        border: AppColors.red500,
        badgeBg: AppColors.red100,
        badgeFg: AppColors.red600,
      );
    case _BadgeKind.tomorrow:
      return const _BadgeColorSet(
        border: AppColors.orange400,
        badgeBg: AppColors.orange100,
        badgeFg: AppColors.orange600,
      );
    case _BadgeKind.soon:
      return const _BadgeColorSet(
        border: AppColors.orange400,
        badgeBg: AppColors.orange100,
        badgeFg: AppColors.orange600,
      );
    case _BadgeKind.future:
      return const _BadgeColorSet(
        border: AppColors.indigo500,
        badgeBg: AppColors.indigo50,
        badgeFg: AppColors.indigo700,
      );
    case _BadgeKind.done:
      return const _BadgeColorSet(
        border: AppColors.gray200,
        badgeBg: AppColors.gray100,
        badgeFg: AppColors.textSecondary,
      );
  }
}

String _repeatRuleLabel(ReminderRepeatRule r) {
  switch (r) {
    case ReminderRepeatRule.none:
      return '不重复';
    case ReminderRepeatRule.daily:
      return '每天';
    case ReminderRepeatRule.weekly:
      return '每周';
    case ReminderRepeatRule.monthly:
      return '每月';
    case ReminderRepeatRule.yearly:
      return '每年';
  }
}

String _formatYmdHm(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
