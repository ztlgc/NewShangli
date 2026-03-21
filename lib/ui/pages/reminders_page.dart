import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lunar/lunar.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/default_book_service.dart';
import '../../reminders/reminders_service.dart';
import '../app_toast.dart';
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
      backgroundColor: Color(0xFFF7F8FA), // 浅灰色背景
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
  // 默认只显示未完成，符合一般提醒列表逻辑
  final _StatusFilter _statusFilter = _StatusFilter.active;
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
    if (reminderId.startsWith('mock')) {
      _toast('这是演示数据，添加真实提醒后将自动消失');
      return;
    }
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
    if (reminderId.startsWith('mock')) {
      _toast('演示数据不可操作，添加真实提醒后将自动消失');
      return;
    }
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
    AppToast.show(context, message, duration: const Duration(milliseconds: 800));
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
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              color: const Color(0xFFF7F8FA),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '提醒',
                      style: AppTypography.base(
                        fontSize: 24,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  PrototypeIconButton(
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textPrimary,
                    onPressed: bookId == null ? null : () => _openCreate(bookId),
                    radius: 12,
                  ),
                ],
              ),
            ),
            // Filter 区域
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              color: const Color(0xFFF7F8FA),
              child: StreamBuilder<List<String>>(
                stream: bookId == null ? null : _service.watchTypeOptions(bookId),
                builder: (context, snapshot) {
                  final types = snapshot.data ?? const <String>['生日', '回礼', '纪念日'];
                  final options = <String>['全部', ...types];
                  return SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final type in options)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _FilterChip(
                                label: type == '全部' ? '全部' : type,
                                selected: _typeFilter == type,
                                onTap: () => setState(() => _typeFilter = type),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Expanded(
              child: bookId == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<EventReminder>>(
                      stream: db.eventRemindersDao.watchAllInBook(bookId),
                      builder: (context, snapshot) {
                        var all = snapshot.data ?? const <EventReminder>[];
                        
                        // Mock Data for Demo if empty
                        if (all.isEmpty) {
                          final now = DateTime.now();
                          all = [
                            EventReminder(
                              reminderId: 'mock1',
                              bookId: bookId,
                              title: '张伟 生日',
                              reminderType: '生日',
                              remindAt: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
                              note: '建议红包 ¥600',
                              status: 'active',
                              createdAt: now.millisecondsSinceEpoch,
                              updatedAt: now.millisecondsSinceEpoch,
                              relationPersonIds: '[]',
                              targetDate: now.add(const Duration(days: 1)).toIso8601String(),
                              repeatRule: 'none',
                              channel: 'notification',
                            ),
                            EventReminder(
                              reminderId: 'mock2',
                              bookId: bookId,
                              title: '李娜 孩子百日宴',
                              reminderType: '回礼',
                              remindAt: now.add(const Duration(days: 3)).millisecondsSinceEpoch,
                              note: '上次她送了 ¥800',
                              status: 'active',
                              createdAt: now.millisecondsSinceEpoch,
                              updatedAt: now.millisecondsSinceEpoch,
                              relationPersonIds: '[]',
                              targetDate: now.add(const Duration(days: 3)).toIso8601String(),
                              repeatRule: 'none',
                              channel: 'notification',
                            ),
                            EventReminder(
                              reminderId: 'mock3',
                              bookId: bookId,
                              title: '结婚纪念日',
                              reminderType: '纪念日',
                              remindAt: DateTime(now.year, 2, 28).millisecondsSinceEpoch,
                              status: 'active',
                              createdAt: now.millisecondsSinceEpoch,
                              updatedAt: now.millisecondsSinceEpoch,
                              relationPersonIds: '[]',
                              targetDate: DateTime(now.year, 2, 28).toIso8601String(),
                              repeatRule: 'none',
                              channel: 'notification',
                            ),
                            EventReminder(
                              reminderId: 'mock4',
                              bookId: bookId,
                              title: '王强 乔迁',
                              reminderType: '乔迁',
                              remindAt: DateTime(now.year, 3, 15).millisecondsSinceEpoch,
                              status: 'active',
                              createdAt: now.millisecondsSinceEpoch,
                              updatedAt: now.millisecondsSinceEpoch,
                              relationPersonIds: '[]',
                              targetDate: DateTime(now.year, 3, 15).toIso8601String(),
                              repeatRule: 'none',
                              channel: 'notification',
                            ),
                          ];
                          // Adjust dates for mock3 and mock4 to be future relative to now
                          // If Feb 28 is passed, make it next year
                          var d3 = DateTime(now.year, 2, 28);
                          if (d3.isBefore(now)) d3 = DateTime(now.year + 1, 2, 28);
                          all[2] = all[2].copyWith(remindAt: d3.millisecondsSinceEpoch);

                          var d4 = DateTime(now.year, 3, 15);
                          if (d4.isBefore(now)) d4 = DateTime(now.year + 1, 3, 15);
                          all[3] = all[3].copyWith(remindAt: d4.millisecondsSinceEpoch);
                        }

                        final filtered = _applyFilters(all);
                        // Hide "Empty" state if we are using mocks or real data
                        // But if filter result is empty (e.g. user selected 'Done'), show empty.
                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(FontAwesomeIcons.bellSlash, size: 48, color: AppColors.gray300),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无提醒',
                                  style: AppTypography.base(
                                    fontSize: 14,
                                    fontWeight: AppTypography.regular,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                PrototypePrimaryButton(
                                  label: '添加提醒',
                                  onTap: () => _openCreate(bookId),
                                ),
                              ],
                            ),
                          );
                        }

                        final sections = _buildSections(filtered);
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          children: [
                            for (final s in sections) ...[
                              _Overline(title: s.title),
                              const SizedBox(height: 12),
                              for (final r in s.items) ...[
                                if (s.title == '未来')
                                  _FutureReminderCard(
                                    reminder: r,
                                    onTap: () => _openEdit(bookId, r.reminderId),
                                  )
                                else
                                  _WeekReminderCard(
                                    reminder: r,
                                    onTap: () => _openEdit(bookId, r.reminderId),
                                    onToggleDone: () => _toggleDone(r.reminderId),
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
    // 定义“本周”为接下来的7天
    final weekEnd = today.add(const Duration(days: 7));
    
    final overdue = <EventReminder>[];
    final week = <EventReminder>[];
    final future = <EventReminder>[];
    
    // 如果需要显示已完成，可以单独处理，但根据设计图，可能不需要在主列表显示已完成
    // 这里假设只显示未完成的（StatusFilter.active）
    
    for (final r in list) {
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
    // 已过期的也放在本周或者单独显示，设计图中没有已过期，假设合并到本周或者显示在最前
    // 这里为了还原设计，如果过期了，可能需要特殊处理。
    // 暂时保留“已过期”分组，或者将其合并入“本周”并标红
    if (overdue.isNotEmpty) sections.add(_Section(title: '已过期', items: overdue));
    if (week.isNotEmpty) sections.add(_Section(title: '本周', items: week));
    if (future.isNotEmpty) sections.add(_Section(title: '未来', items: future));
    
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF312E81) : AppColors.gray100, // indigo-900 vs gray-100
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.base(
            fontSize: 14,
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
          fontSize: 14,
          fontWeight: AppTypography.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 本周样式卡片
class _WeekReminderCard extends StatelessWidget {
  const _WeekReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onToggleDone,
  });

  final EventReminder reminder;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(reminder.remindAt);
    final badge = _badgeOf(dt);
    final colors = _badgeColors(badge.kind);

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: colors.border, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge.text,
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.bold,
                              color: colors.badgeFg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reminder.title.trim().isEmpty ? '未命名' : reminder.title.trim(),
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
                    if ((reminder.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        reminder.note!,
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              PressableScale(
                onTap: onToggleDone,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gray200, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.check,
                    size: 14,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 未来样式卡片
class _FutureReminderCard extends StatelessWidget {
  const _FutureReminderCard({
    required this.reminder,
    required this.onTap,
  });

  final EventReminder reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(reminder.remindAt);
    final type = reminder.reminderType.trim();
    
    // 图标配置
    IconData icon;
    Color iconBg;
    Color iconFg;
    
    if (type == '生日') {
      icon = FontAwesomeIcons.cakeCandles;
      iconBg = const Color(0xFFFFEBEE); // 浅红
      iconFg = const Color(0xFFEF5350);
    } else if (type == '纪念日') {
      icon = FontAwesomeIcons.heart;
      iconBg = const Color(0xFFFCE4EC); // 浅粉
      iconFg = const Color(0xFFEC407A);
    } else if (type == '回礼') {
      icon = FontAwesomeIcons.gift;
      iconBg = const Color(0xFFE3F2FD); // 浅蓝
      iconFg = const Color(0xFF42A5F5);
    } else if (type.contains('乔迁')) {
      icon = FontAwesomeIcons.house;
      iconBg = const Color(0xFFE8EAF6); // 浅靛蓝
      iconFg = const Color(0xFF5C6BC0);
    } else {
      icon = FontAwesomeIcons.bell;
      iconBg = const Color(0xFFF3E5F5); // 浅紫
      iconFg = const Color(0xFFAB47BC);
    }

    // 计算天数
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = day.difference(today).inDays;
    
    final dateStr = '${dt.month}月${dt.day}日${diff > 0 ? ' ($diff天后)' : ''}';

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FaIcon(icon, size: 20, color: iconFg),
            ),
            const SizedBox(width: 16),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title.trim().isEmpty ? '未命名' : reminder.title.trim(),
                    style: AppTypography.base(
                      fontSize: 16,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: AppTypography.base(
                      fontSize: 13,
                      fontWeight: AppTypography.regular,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BadgeKind { overdue, today, tomorrow, soon, future }

class _Badge {
  const _Badge({required this.kind, required this.text});
  final _BadgeKind kind;
  final String text;
}

_Badge _badgeOf(DateTime remindAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(remindAt.year, remindAt.month, remindAt.day);
  final diff = day.difference(today).inDays;
  if (diff < 0) return const _Badge(kind: _BadgeKind.overdue, text: '已过期');
  if (diff == 0) return const _Badge(kind: _BadgeKind.today, text: '今天');
  if (diff == 1) return const _Badge(kind: _BadgeKind.tomorrow, text: '明天');
  if (diff <= 7) return _Badge(kind: _BadgeKind.soon, text: '$diff天后');
  return const _Badge(kind: _BadgeKind.future, text: '未来');
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

  _BadgeColorSet _badgeColors(_BadgeKind kind) {
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
          border: AppColors.red500,
          badgeBg: Color(0xFFFEE2E2), // red-100
          badgeFg: Color(0xFFDC2626), // red-600
        );
      case _BadgeKind.soon:
        return const _BadgeColorSet(
          border: Color(0xFFFB923C), // orange-400
          badgeBg: Color(0xFFFFEDD5), // orange-100
          badgeFg: Color(0xFFEA580C), // orange-600
        );
      case _BadgeKind.future:
        return const _BadgeColorSet(
          border: AppColors.indigo500,
          badgeBg: AppColors.indigo50,
          badgeFg: AppColors.indigo700,
        );
    }
  }
