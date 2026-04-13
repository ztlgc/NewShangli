import 'dart:async';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:lpinyin/lpinyin.dart';

import '../../data/local/drift/app_database.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../contact_avatar.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../widgets/person_display_row.dart';
import 'person_detail_page.dart';
import 'person_edit_page.dart';
import 'record_home_page.dart';
import 'settings_home_page.dart';
import 'stats_page.dart';

/// 页面：关系人管理 - 列表页
/// 对照原型：prototype/index.html -> "列表页"
class PersonListPage extends StatelessWidget {
  const PersonListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(backgroundColor: AppColors.white, body: _Canvas());
  }
}

// ──────────────────────────────────────────────
// 数据模型：实现 ISuspensionBean（azlistview 要求）
// ──────────────────────────────────────────────

class _ContactItem extends ISuspensionBean {
  _ContactItem({required this.personData, required this.tagIndex});

  final PersonData personData;

  String tagIndex;

  @override
  String getSuspensionTag() => tagIndex;
}

// ──────────────────────────────────────────────
// State
// ──────────────────────────────────────────────

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  final TextEditingController _searchController = TextEditingController();
  static const Duration _multiSelectFadeDuration = Duration(milliseconds: 250);
  static const Duration _longPressDuration = Duration(milliseconds: 650);
  static const double _multiSelectBarHeight = AppTokens.tabBarHeight;
  String _keyword = '';
  bool _multiSelectMode = false;
  Set<String> _selectedPersonIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return StreamBuilder<List<Person>>(
      stream: db.personsDao.watchAllInAllBooks(),
      builder: (context, snapshot) {
        final persons = snapshot.data ?? const <Person>[];
        final personDataList = _toPersonDataList(persons);
        return _CanvasBody(
          personDataList: personDataList,
          keyword: _keyword,
          searchController: _searchController,
          multiSelectMode: _multiSelectMode,
          selectedPersonIds: _selectedPersonIds,
          onKeywordChanged: (v) => setState(() => _keyword = v),
          onPersonTap: (id) => _handlePersonTap(context, id),
          onPersonLongPress: _enterMultiSelectMode,
          onPersonSelectionToggle: _togglePersonSelection,
          onBottomNavTap: (index) => _handleBottomNavTap(context, index),
          onExitMultiSelect: _exitMultiSelectMode,
          onToggleSelectAll: _toggleSelectAll,
          onDelete: () {
            final db2 = AppDatabaseScope.of(context);
            _deleteSelectedPersons(db2);
          },
        );
      },
    );
  }

  List<PersonData> _toPersonDataList(List<Person> persons) {
    return persons
        .map(
          (p) => PersonData(
            id: p.personId,
            name: p.name,
            relationship: p.relationshipType,
            phone: p.phone,
            note: p.note,
            avatarUrl: p.avatarUri,
            birthday: DateTime.tryParse(p.birthday ?? ''),
            isLunarBirthday: false,
            birthdayReminder: false,
            createdAt: DateTime.fromMillisecondsSinceEpoch(p.createdAt),
          ),
        )
        .toList();
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    if (index == 1) return;
    if (index == 0) {
      AppNav.replaceRoot(context, const RecordHomePage());
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
  }

  void _handlePersonTap(BuildContext context, String id) {
    if (_multiSelectMode) {
      _togglePersonSelection(id);
      return;
    }
    AppNav.push(context, PersonDetailPage(personId: id), requiresLogin: true);
  }

  void _enterMultiSelectMode(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      _multiSelectMode = true;
      _selectedPersonIds = <String>{id};
    });
  }

  void _togglePersonSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      final next = Set<String>.from(_selectedPersonIds);
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      _selectedPersonIds = next;
      if (_selectedPersonIds.isEmpty) {
        _multiSelectMode = false;
      }
    });
  }

  void _toggleSelectAll(List<String> visiblePersonIds) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedPersonIds.length == visiblePersonIds.length) {
        _selectedPersonIds = <String>{};
        _multiSelectMode = false;
      } else {
        _selectedPersonIds = visiblePersonIds.toSet();
      }
    });
  }

  Future<void> _deleteSelectedPersons(AppDatabase db) async {
    final ids = _selectedPersonIds.toList();
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Align(
          alignment: Alignment.center,
          child: AlertDialog(
            title: const Text('删除联系人'),
            content: Text('确认删除已选择的${ids.length}位联系人？删除后将进入回收站。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || ok != true) return;
    for (final id in ids) {
      await db.personsDao.deleteById(id);
    }
    if (!mounted) return;
    setState(() {
      _selectedPersonIds = <String>{};
      _multiSelectMode = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除：${ids.length}项')));
  }

  void _exitMultiSelectMode() {
    setState(() {
      _selectedPersonIds = <String>{};
      _multiSelectMode = false;
    });
  }
}

// ──────────────────────────────────────────────
// 主体 Widget（将 AzListView 与搜索联动）
// ──────────────────────────────────────────────

class _CanvasBody extends StatelessWidget {
  const _CanvasBody({
    required this.personDataList,
    required this.keyword,
    required this.searchController,
    required this.multiSelectMode,
    required this.selectedPersonIds,
    required this.onKeywordChanged,
    required this.onPersonTap,
    required this.onPersonLongPress,
    required this.onPersonSelectionToggle,
    required this.onBottomNavTap,
    required this.onExitMultiSelect,
    required this.onToggleSelectAll,
    required this.onDelete,
  });

  final List<PersonData> personDataList;
  final String keyword;
  final TextEditingController searchController;
  final bool multiSelectMode;
  final Set<String> selectedPersonIds;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<String> onPersonTap;
  final ValueChanged<String> onPersonLongPress;
  final ValueChanged<String> onPersonSelectionToggle;
  final ValueChanged<int> onBottomNavTap;
  final VoidCallback onExitMultiSelect;
  final ValueChanged<List<String>> onToggleSelectAll;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final trimmed = keyword.trim();
    final isSearching = trimmed.isNotEmpty;

    // 构建 AzListView 所需的数据
    final contactItems = _buildContactItems(personDataList);
    final allPersonIds = contactItems.map((e) => e.personData.id).toList();

    // 搜索过滤
    final filtered = isSearching
        ? personDataList
            .where((p) => _matchesPersonKeyword(p, trimmed))
            .toList()
        : null;

    return Column(
      children: [
        // 顶部标题栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.gray100, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text('关系人', style: AppTypography.h2().copyWith(fontSize: 20)),
              const Spacer(),
              if (multiSelectMode)
                PressableScale(
                  onTap: onExitMultiSelect,
                  child: Text(
                    '取消',
                    style: AppTypography.base(
                      fontSize: 14,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                PrototypeIconButton(
                  icon: const FaIcon(FontAwesomeIcons.userPlus, size: 16),
                  backgroundColor: AppColors.gray100,
                  foregroundColor: AppColors.textSecondary,
                  onPressed: () => AppNav.push(
                    context,
                    const PersonEditPage(),
                    requiresLogin: true,
                  ),
                ),
            ],
          ),
        ),
        // 搜索框
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PrototypeSearchField(
            controller: searchController,
            hintText: '搜索姓名、手机号',
            onChanged: onKeywordChanged,
          ),
        ),
        // 列表区域
        Expanded(
          child: isSearching
              ? _SearchResultList(
                  persons: filtered!,
                  multiSelectMode: multiSelectMode,
                  selectedPersonIds: selectedPersonIds,
                  onPersonTap: onPersonTap,
                  onPersonLongPress: onPersonLongPress,
                  onPersonSelectionToggle: onPersonSelectionToggle,
                )
              : _AzContactList(
                  items: contactItems,
                  multiSelectMode: multiSelectMode,
                  selectedPersonIds: selectedPersonIds,
                  onPersonTap: onPersonTap,
                  onPersonLongPress: onPersonLongPress,
                  onPersonSelectionToggle: onPersonSelectionToggle,
                ),
        ),
        // 底部导航 / 多选操作栏
        if (multiSelectMode)
          _MultiSelectActionBar(
            selectedCount: selectedPersonIds.length,
            allSelected:
                allPersonIds.isNotEmpty &&
                selectedPersonIds.length == allPersonIds.length,
            onToggleSelectAll: () => onToggleSelectAll(allPersonIds),
            onDelete: onDelete,
          )
        else
          PrototypeBottomNav(activeIndex: 1, onTap: onBottomNavTap),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// AzListView 联系人列表（非搜索状态）
// ──────────────────────────────────────────────

class _AzContactList extends StatelessWidget {
  const _AzContactList({
    required this.items,
    required this.multiSelectMode,
    required this.selectedPersonIds,
    required this.onPersonTap,
    required this.onPersonLongPress,
    required this.onPersonSelectionToggle,
  });

  final List<_ContactItem> items;
  final bool multiSelectMode;
  final Set<String> selectedPersonIds;
  final ValueChanged<String> onPersonTap;
  final ValueChanged<String> onPersonLongPress;
  final ValueChanged<String> onPersonSelectionToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(padding: EdgeInsets.only(top: 80), child: Text('暂无联系人')),
      );
    }

    return AzListView(
      data: items,
      itemCount: items.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        final p = item.personData;
        final isLast =
            index == items.length - 1 ||
            items[index + 1].tagIndex != item.tagIndex;
        return _PersonRow(
          id: p.id,
          avatarUrl: p.avatarUrl,
          name: p.name,
          subtitle: p.relationship,
          multiSelectMode: multiSelectMode,
          selected: selectedPersonIds.contains(p.id),
          fadeDuration: _CanvasState._multiSelectFadeDuration,
          longPressDuration: _CanvasState._longPressDuration,
          borderBottom: !isLast,
          onTap: () => onPersonTap(p.id),
          onLongPress: () => onPersonLongPress(p.id),
          onSelectionToggle: () => onPersonSelectionToggle(p.id),
        );
      },
      susItemBuilder: (context, index) {
        final item = items[index];
        return _SusHeader(letter: item.getSuspensionTag());
      },
      indexBarData: [...kIndexBarData, '#'],
      indexBarOptions: IndexBarOptions(
        needRebuild: true,
        ignoreDragCancel: true,
        textStyle: AppTypography.base(
          fontSize: 10,
          fontWeight: AppTypography.medium,
          color: AppColors.textMuted,
        ),
        downTextStyle: AppTypography.base(
          fontSize: 10,
          fontWeight: AppTypography.medium,
          color: AppColors.white,
        ),
        downItemDecoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.indigo600,
        ),
        indexHintWidth: 40,
        indexHintHeight: 40,
        indexHintDecoration: BoxDecoration(
          color: AppColors.indigo600,
          borderRadius: BorderRadius.circular(8),
        ),
        indexHintTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        indexHintAlignment: Alignment.centerRight,
        indexHintOffset: const Offset(-52, 0),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 搜索结果列表（搜索状态下不显示字母索引）
// ──────────────────────────────────────────────

class _SearchResultList extends StatelessWidget {
  const _SearchResultList({
    required this.persons,
    required this.multiSelectMode,
    required this.selectedPersonIds,
    required this.onPersonTap,
    required this.onPersonLongPress,
    required this.onPersonSelectionToggle,
  });

  final List<PersonData> persons;
  final bool multiSelectMode;
  final Set<String> selectedPersonIds;
  final ValueChanged<String> onPersonTap;
  final ValueChanged<String> onPersonLongPress;
  final ValueChanged<String> onPersonSelectionToggle;

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: Text('无匹配联系人'),
        ),
      );
    }
    final sorted = persons.toList()..sort(_comparePersonByInitialAndName);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final p = sorted[index];
        return _PersonRow(
          id: p.id,
          avatarUrl: p.avatarUrl,
          name: p.name,
          subtitle: p.relationship,
          multiSelectMode: multiSelectMode,
          selected: selectedPersonIds.contains(p.id),
          fadeDuration: _CanvasState._multiSelectFadeDuration,
          longPressDuration: _CanvasState._longPressDuration,
          borderBottom: index != sorted.length - 1,
          onTap: () => onPersonTap(p.id),
          onLongPress: () => onPersonLongPress(p.id),
          onSelectionToggle: () => onPersonSelectionToggle(p.id),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// 辅助：构建 _ContactItem 列表（排序 + 标记吸顶状态）
// ──────────────────────────────────────────────

List<_ContactItem> _buildContactItems(List<PersonData> persons) {
  final items = persons.map((p) {
    return _ContactItem(personData: p, tagIndex: _letterForName(p.name));
  }).toList();

  SuspensionUtil.sortListBySuspensionTag(items);
  SuspensionUtil.setShowSuspensionStatus(items);
  return items;
}

// ──────────────────────────────────────────────
// 工具函数
// ──────────────────────────────────────────────

int _comparePersonByInitialAndName(PersonData a, PersonData b) {
  final letterCompare = _compareInitialLetter(
    _letterForName(a.name),
    _letterForName(b.name),
  );
  if (letterCompare != 0) return letterCompare;
  final pinyinCompare = _nameSortKey(a.name).compareTo(_nameSortKey(b.name));
  if (pinyinCompare != 0) return pinyinCompare;
  return a.name.toUpperCase().compareTo(b.name.toUpperCase());
}

int _compareInitialLetter(String a, String b) {
  if (a == b) return 0;
  if (a == '#') return 1;
  if (b == '#') return -1;
  return a.compareTo(b);
}

String _letterForName(String name) {
  final initial = _namePinyin(name);
  if (initial.isNotEmpty) {
    final upper = initial[0].toUpperCase();
    if (RegExp(r'^[A-Z]$').hasMatch(upper)) return upper;
  }
  final first = contactAvatarTextFromName(name).toUpperCase();
  if (RegExp(r'^[A-Z]$').hasMatch(first)) return first;
  return '#';
}

String _nameSortKey(String name) {
  final pinyin = _namePinyin(name);
  if (pinyin.isEmpty) return 'ZZZZ|${name.toUpperCase()}';
  final first = pinyin[0].toUpperCase();
  if (!RegExp(r'^[A-Z]$').hasMatch(first)) return 'ZZZZ|${name.toUpperCase()}';
  return '$pinyin|${name.toUpperCase()}';
}

String _namePinyin(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final source = PinyinHelper.getPinyinE(
    trimmed,
    separator: '',
    defPinyin: '',
    format: PinyinFormat.WITHOUT_TONE,
  );
  return source.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

bool _matchesPersonKeyword(PersonData person, String keyword) {
  final normalized = keyword.trim().toLowerCase();
  if (normalized.isEmpty) return true;

  final pinyinKeyword = normalized.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  return person.name.toLowerCase().contains(normalized) ||
      person.relationship.toLowerCase().contains(normalized) ||
      (person.phone ?? '').toLowerCase().contains(normalized) ||
      (person.note ?? '').toLowerCase().contains(normalized) ||
      _namePinyin(person.name).contains(pinyinKeyword);
}

// ──────────────────────────────────────────────
// 组件
// ──────────────────────────────────────────────

/// 分组吸顶字母头部（悬浮在列表上方）
class _SusHeader extends StatelessWidget {
  const _SusHeader({required this.letter});

  final String letter;
  static const double _headerHeight = 24;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _headerHeight,
      color: AppColors.gray50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        letter,
        style: AppTypography.base(
          fontSize: 12,
          fontWeight: AppTypography.bold,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _PersonRow extends StatefulWidget {
  const _PersonRow({
    required this.id,
    required this.avatarUrl,
    required this.name,
    required this.subtitle,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionToggle,
    required this.multiSelectMode,
    required this.selected,
    required this.fadeDuration,
    required this.longPressDuration,
    this.borderBottom = true,
  });

  final String id;
  final String? avatarUrl;
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool borderBottom;
  final VoidCallback onSelectionToggle;
  final bool multiSelectMode;
  final bool selected;
  final Duration fadeDuration;
  final Duration longPressDuration;

  @override
  State<_PersonRow> createState() => _PersonRowState();
}

class _PersonRowState extends State<_PersonRow> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  void _handleTap() {
    if (widget.id.startsWith('p_')) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这是演示数据，添加真实联系人后将自动消失')));
    } else {
      widget.onTap();
    }
  }

  void _handleLongPress() {
    if (widget.id.startsWith('p_')) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这是演示数据，添加真实联系人后将自动消失')));
    } else {
      widget.onLongPress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarOverlay = IgnorePointer(
      ignoring: !widget.multiSelectMode,
      child: AnimatedOpacity(
        opacity: widget.multiSelectMode ? 1 : 0,
        duration: widget.fadeDuration,
        curve: Curves.easeInOut,
        child: _AvatarSelectionCheckbox(
          label: widget.name,
          selected: widget.selected,
          onToggle: widget.onSelectionToggle,
        ),
      ),
    );
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        color: _pressed ? AppColors.gray50 : Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: widget.borderBottom
                ? const Border(
                    bottom: BorderSide(
                      color: AppColors.borderDivider,
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: PersonDisplayRow(
                  name: widget.name,
                  subtitle: widget.subtitle,
                  avatarUrl: widget.avatarUrl,
                  avatarOverlay: avatarOverlay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarSelectionCheckbox extends StatelessWidget {
  const _AvatarSelectionCheckbox({
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppColors.brandPrimary
        : AppColors.gray500.withValues(alpha: 0.2);
    return Semantics(
      checked: selected,
      button: true,
      label: '$label，${selected ? '已选中' : '未选中'}',
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: AppShadows.sm,
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: selected
                ? const Icon(
                    Icons.check,
                    key: ValueKey('selected'),
                    size: 16,
                    color: AppColors.white,
                  )
                : const SizedBox(key: ValueKey('unselected')),
          ),
        ),
      ),
    );
  }
}

class _MultiSelectActionBar extends StatelessWidget {
  const _MultiSelectActionBar({
    required this.selectedCount,
    required this.allSelected,
    required this.onToggleSelectAll,
    required this.onDelete,
  });

  final int selectedCount;
  final bool allSelected;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canDelete = selectedCount > 0;
    return Container(
      height: _CanvasState._multiSelectBarHeight + bottomInset,
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
          height: _CanvasState._multiSelectBarHeight,
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
