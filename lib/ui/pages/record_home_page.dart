import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_data.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../contact_avatar.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'person_list_page.dart';
import 'record_add_page.dart';
import 'record_detail_page.dart';
import 'reminders_page.dart';
import 'settings_home_page.dart';
import 'stats_page.dart';

/// 页面：收支记录 - 首页
/// 对照原型：prototype/index.html -> "Row 1: Record" -> "首页"
class RecordHomePage extends StatelessWidget {
  const RecordHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      backgroundColor: AppColors.gray100,
      body: _Canvas(),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  bool _selectionMode = false;
  final Set<String> _selectedRecordIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  void _enterSelection(String firstId) {
    setState(() {
      _selectionMode = true;
      _selectedRecordIds
        ..clear()
        ..add(firstId);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedRecordIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedRecordIds.contains(id)) {
        _selectedRecordIds.remove(id);
      } else {
        _selectedRecordIds.add(id);
      }
      if (_selectedRecordIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmBatchDelete(AppData data) async {
    if (_selectedRecordIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('批量删除'),
          content: Text('确认删除 ${_selectedRecordIds.length} 条记录？删除后将进入回收站。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
          ],
        );
      },
    );
    if (ok != true) return;
    data.trashRecords(_selectedRecordIds);
    _exitSelection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已移入回收站')));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final data = AppDataScope.of(context);

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  if (_selectionMode) ...[
                    PrototypeIconButton(
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                      backgroundColor: AppColors.gray100,
                      foregroundColor: AppColors.textSecondary,
                      onPressed: _exitSelection,
                    ),
                    const SizedBox(width: 12),
                    Text('已选择 ${_selectedRecordIds.length}', style: AppTypography.h2().copyWith(fontSize: 20)),
                  ] else ...[
                    Text('尚礼', style: AppTypography.h2().copyWith(fontSize: 20)),
                  ],
                  const Spacer(),
                  if (_selectionMode) ...[
                    PrototypeIconButton(
                      icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
                      backgroundColor: AppColors.red100,
                      foregroundColor: AppColors.red600,
                      onPressed: () => _confirmBatchDelete(data),
                    ),
                  ] else ...[
                    PrototypeIconButton(
                      icon: const FaIcon(FontAwesomeIcons.bell, size: 16),
                      backgroundColor: AppColors.gray100,
                      foregroundColor: AppColors.textSecondary,
                      onPressed: () => AppNav.push(context, const RemindersPage(), requiresLogin: true),
                    ),
                  ],
                ],
              ),
            ),
            if (!_selectionMode)
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: PrototypeSearchField(
                  controller: _searchController,
                  hintText: '搜索姓名、事由、备注',
                  onChanged: (v) => setState(() => _keyword = v),
                ),
              ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ..._buildRecordSlivers(data),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
                ],
              ),
            ),
            PrototypeBottomNav(
              activeIndex: 0,
              onTap: (index) {
                if (index == 0) return;
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
        ),
        if (!_selectionMode)
          Positioned(
            right: 16,
            bottom: AppTokens.tabBarHeight + 13 + bottomInset,
            child: PressableScale(
              onTap: () => AppNav.push(context, const RecordAddPage()),
              pressedScale: 0.95,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.brandFab,
                ),
                alignment: Alignment.center,
                child: const FaIcon(FontAwesomeIcons.plus, color: AppColors.white, size: 24),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildRecordSlivers(AppData data) {
    final trimmed = _keyword.trim();
    final records = trimmed.isEmpty
        ? data.records
        : data.records.where((r) {
            final kw = trimmed.toLowerCase();
            return r.personName.toLowerCase().contains(kw) ||
                r.eventName.toLowerCase().contains(kw) ||
                r.paymentMethod.toLowerCase().contains(kw) ||
                (r.note ?? '').toLowerCase().contains(kw);
          }).toList();
    if (records.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: Text(trimmed.isEmpty ? '暂无记录' : '无匹配记录')),
          ),
        ),
      ];
    }

    final Map<String, List<RecordData>> groups = {};
    for (final r in records) {
      final key = '${r.occurredAt.year}-${r.occurredAt.month.toString().padLeft(2, '0')}';
      (groups[key] ??= <RecordData>[]).add(r);
    }

    final keys = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final slivers = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final title = '$year年$month月';
      slivers.add(_MonthHeaderSliver(title: title, topMargin: i == 0 ? 0 : 8));

      final monthRecords = groups[key]!..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            child: Column(
              children: [
                for (var j = 0; j < monthRecords.length; j++)
                  _RecordRow(
                    id: monthRecords[j].id,
                    avatarUrl: monthRecords[j].personAvatarUrl,
                    name: monthRecords[j].personName,
                    direction: monthRecords[j].direction,
                    amountCent: monthRecords[j].amountCent,
                    subtitle: '${monthRecords[j].eventName} - ${monthRecords[j].paymentMethod}',
                    occurredAt: monthRecords[j].occurredAt,
                    selectionMode: _selectionMode,
                    selected: _selectedRecordIds.contains(monthRecords[j].id),
                    borderBottom: j != monthRecords.length - 1,
                    onTap: () {
                      if (_selectionMode) {
                        _toggleSelection(monthRecords[j].id);
                        return;
                      }
                      AppNav.push(context, RecordDetailPage(recordId: monthRecords[j].id));
                    },
                    onLongPress: () {
                      if (_selectionMode) {
                        _toggleSelection(monthRecords[j].id);
                        return;
                      }
                      _enterSelection(monthRecords[j].id);
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return slivers;
  }
}

class _MonthHeaderSliver extends StatelessWidget {
  const _MonthHeaderSliver({required this.title, this.topMargin = 0});

  final String title;
  final double topMargin;

  @override
  Widget build(BuildContext context) {
    const headerHeight = 32.0;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SimpleHeaderDelegate(
        minHeight: headerHeight + topMargin,
        maxHeight: headerHeight + topMargin,
        child: Column(
          children: [
            if (topMargin > 0) SizedBox(height: topMargin),
            Container(
              height: headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.gray50,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: AppTypography.base(
                  fontSize: 12,
                  fontWeight: AppTypography.medium,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SimpleHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_SimpleHeaderDelegate oldDelegate) =>
      minHeight != oldDelegate.minHeight ||
      maxHeight != oldDelegate.maxHeight ||
      child != oldDelegate.child;
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.id,
    required this.avatarUrl,
    required this.name,
    required this.direction,
    required this.amountCent,
    required this.subtitle,
    required this.occurredAt,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.borderBottom = true,
  });

  final String id;
  final String? avatarUrl;
  final String name;
  final RecordDirection direction;
  final int amountCent;
  final String subtitle;
  final DateTime occurredAt;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    final amountText = _formatSignedAmount(direction, amountCent);
    final amountColor = direction == RecordDirection.income ? AppColors.green600 : AppColors.red500;
    final dateText = '${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';

    return PrototypePressableRow(
      onTap: onTap,
      onLongPress: onLongPress,
      borderBottom: borderBottom,
      pressedColor: selectionMode ? AppColors.indigo50 : AppColors.gray50,
      enablePressedFeedback: !selectionMode,
      child: Row(
        children: [
          if (selectionMode) ...[
            _SelectDot(selected: selected),
            const SizedBox(width: 10),
          ],
          ContactAvatar(
            name: name,
            avatarUrl: avatarUrl,
            size: 40,
            shape: ContactAvatarShape.circle,
            border: Border.all(color: AppColors.gray100, width: 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.base(
                          fontSize: 16,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      amountText,
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: AppTypography.semibold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      dateText,
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSignedAmount(RecordDirection direction, int cent) {
    final sign = direction == RecordDirection.income ? '+' : '-';
    final absCent = cent.abs();
    final yuan = (absCent / 100).toStringAsFixed(2);
    final parts = yuan.split('.');
    final intPart = parts[0];
    final fracPart = parts[1];
    final grouped = intPart.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$sign$grouped.$fracPart';
  }

}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.indigo600 : Colors.transparent,
        border: Border.all(color: selected ? AppColors.indigo600 : AppColors.gray300, width: 1.5),
      ),
      alignment: Alignment.center,
      child: selected ? const FaIcon(FontAwesomeIcons.check, size: 12, color: AppColors.white) : null,
    );
  }
}


