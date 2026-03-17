import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../widgets/record_list_row.dart';
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
  List<String> _allVisibleRecordIds = const <String>[];
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  void _enterSelection(String firstId) {
    HapticFeedback.lightImpact();
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
    HapticFeedback.selectionClick();
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

  Future<void> _confirmBatchDelete(AppDatabase db) async {
    if (_selectedRecordIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('批量删除'),
          content: Text('确认删除 ${_selectedRecordIds.length} 条记录？删除后将进入回收站。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('永久删除'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final ids = _selectedRecordIds.toList(growable: false);
    for (final id in ids) {
      await db.giftRecordsDao.deleteById(id);
    }
    if (!mounted) return;
    _exitSelection();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已删除选中记录')));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final db = AppDatabaseScope.of(context);

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.gray100, width: 1),
                ),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  Text('尚礼', style: AppTypography.h2().copyWith(fontSize: 20)),
                  const Spacer(),
                  if (_selectionMode)
                    PressableScale(
                      onTap: _exitSelection,
                      child: Text(
                        '取消',
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else ...[
                    PrototypeIconButton(
                      icon: const FaIcon(FontAwesomeIcons.bell, size: 16),
                      backgroundColor: AppColors.gray100,
                      foregroundColor: AppColors.textSecondary,
                      onPressed: () => AppNav.push(
                        context,
                        const RemindersPage(),
                        requiresLogin: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
              child: StreamBuilder<List<GiftRecordWithPerson>>(
                stream: db.giftRecordsDao.watchAllWithPersonInAllBooks(),
                builder: (context, snapshot) {
                  final records = _toRecordDataList(
                    snapshot.data ?? const <GiftRecordWithPerson>[],
                  );
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      ..._buildRecordSlivers(records),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
                    ],
                  );
                },
              ),
            ),
            if (_selectionMode)
              _RecordMultiSelectBar(
                selectedCount: _selectedRecordIds.length,
                allCount: _allVisibleRecordIds.length,
                onToggleSelectAll: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (_selectedRecordIds.length ==
                        _allVisibleRecordIds.length) {
                      _selectedRecordIds.clear();
                      _selectionMode = false;
                    } else {
                      _selectedRecordIds
                        ..clear()
                        ..addAll(_allVisibleRecordIds);
                    }
                  });
                },
                onDelete: () => _confirmBatchDelete(db),
              )
            else
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
                child: const FaIcon(
                  FontAwesomeIcons.plus,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<RecordData> _toRecordDataList(List<GiftRecordWithPerson> rows) {
    return rows
        .map(
          (row) => RecordData(
            id: row.record.recordId,
            bookId: row.record.bookId,
            personId: row.person.personId,
            personName: row.person.name,
            personAvatarUrl: row.person.avatarUri,
            direction: row.record.direction == '支出'
                ? RecordDirection.expense
                : RecordDirection.income,
            amountCent: row.record.amountCent,
            eventName: (row.record.eventName ?? '').trim().isEmpty
                ? '未设置'
                : row.record.eventName!.trim(),
            paymentMethod: (row.record.paymentMethod ?? '').trim().isEmpty
                ? '未设置'
                : row.record.paymentMethod!.trim(),
            occurredAt: DateTime.fromMillisecondsSinceEpoch(
              row.record.occurredAt,
            ),
            note: row.record.note,
          ),
        )
        .toList();
  }

  List<Widget> _buildRecordSlivers(List<RecordData> sourceRecords) {
    final trimmed = _keyword.trim();
    final records = trimmed.isEmpty
        ? sourceRecords
        : sourceRecords.where((r) {
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
      final key =
          '${r.occurredAt.year}-${r.occurredAt.month.toString().padLeft(2, '0')}';
      (groups[key] ??= <RecordData>[]).add(r);
    }

    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final slivers = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final title = '$year年$month月';
      slivers.add(_MonthHeaderSliver(title: title, topMargin: i == 0 ? 0 : 8));

      final monthRecords = groups[key]!
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            child: Column(
              children: [
                for (var j = 0; j < monthRecords.length; j++)
                  RecordListRow(
                    avatarUrl: monthRecords[j].personAvatarUrl,
                    name: monthRecords[j].personName,
                    direction: monthRecords[j].direction,
                    amountCent: monthRecords[j].amountCent,
                    subtitle:
                        monthRecords[j].paymentMethod == '未设置' ||
                            monthRecords[j].paymentMethod.isEmpty
                        ? monthRecords[j].eventName
                        : '${monthRecords[j].eventName} - ${monthRecords[j].paymentMethod}',
                    occurredAt: monthRecords[j].occurredAt,
                    selectionMode: _selectionMode,
                    selected: _selectedRecordIds.contains(monthRecords[j].id),
                    fadeDuration: const Duration(milliseconds: 250),
                    borderBottom: j != monthRecords.length - 1,
                    onTap: () {
                      if (_selectionMode) {
                        _toggleSelection(monthRecords[j].id);
                        return;
                      }
                      if (monthRecords[j].id.startsWith('r_')) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('这是演示数据，添加真实记录后将自动消失')),
                        );
                        return;
                      }
                      AppNav.push(
                        context,
                        RecordDetailPage(recordId: monthRecords[j].id),
                      );
                    },
                    onLongPress: () {
                      if (_selectionMode) {
                        _toggleSelection(monthRecords[j].id);
                        return;
                      }
                      if (monthRecords[j].id.startsWith('r_')) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('演示数据不可操作')),
                        );
                        return;
                      }
                      _enterSelection(monthRecords[j].id);
                    },
                    onSelectionToggle: () {
                      if (monthRecords[j].id.startsWith('r_')) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('演示数据不可操作')),
                        );
                        return;
                      }
                      _toggleSelection(monthRecords[j].id);
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    }
    _allVisibleRecordIds = records.map((r) => r.id).toList(growable: false);
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_SimpleHeaderDelegate oldDelegate) =>
      minHeight != oldDelegate.minHeight ||
      maxHeight != oldDelegate.maxHeight ||
      child != oldDelegate.child;
}

class _RecordMultiSelectBar extends StatelessWidget {
  const _RecordMultiSelectBar({
    required this.selectedCount,
    required this.allCount,
    required this.onToggleSelectAll,
    required this.onDelete,
  });

  final int selectedCount;
  final int allCount;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onDelete;

  static const double _barHeight = AppTokens.tabBarHeight;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canDelete = selectedCount > 0;
    final allSelected = allCount > 0 && selectedCount == allCount;
    return Container(
      height: _barHeight + bottomInset,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          top: BorderSide(color: AppColors.borderDefault, width: 1),
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset),
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: [
              PressableScale(
                onTap: onToggleSelectAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    allSelected ? '取消全选' : '全选',
                    style: AppTypography.base(
                      fontSize: 13,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '已选择$selectedCount项',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.base(
                    fontSize: 15,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PressableScale(
                onTap: canDelete ? onDelete : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: canDelete
                        ? AppColors.stateDanger
                        : AppColors.gray200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '删除',
                    style: AppTypography.base(
                      fontSize: 13,
                      fontWeight: AppTypography.medium,
                      color: AppColors.white,
                    ),
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
