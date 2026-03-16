import 'dart:async';

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
    return const AppScaffold(
      backgroundColor: AppColors.white,
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final db = AppDatabaseScope.of(context);
    return Stack(
      children: [
        StreamBuilder<List<Person>>(
          stream: db.personsDao.watchAllInAllBooks(),
          builder: (context, snapshot) {
            final data = _toPersonDataList(snapshot.data ?? const <Person>[]);
            final sectionData = _buildPersonSectionData(
              context,
              data,
              _keyword,
              multiSelectMode: _multiSelectMode,
              selectedPersonIds: _selectedPersonIds,
              onPersonTap: (id) => _handlePersonTap(context, id),
              onPersonLongPress: _enterMultiSelectMode,
              onPersonSelectionToggle: _togglePersonSelection,
            );
            final bottomBarHeight = _multiSelectMode ? _multiSelectBarHeight : AppTokens.tabBarHeight;
            return Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Text('关系人', style: AppTypography.h2().copyWith(fontSize: 20)),
                          const Spacer(),
                          if (_multiSelectMode)
                            PressableScale(
                              onTap: _exitMultiSelectMode,
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
                              onPressed: () => AppNav.push(context, const PersonEditPage(), requiresLogin: true),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: PrototypeSearchField(
                        controller: _searchController,
                        hintText: '搜索姓名、手机号',
                        onChanged: (v) => setState(() => _keyword = v),
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          ...sectionData.slivers,
                          const SliverToBoxAdapter(child: SizedBox(height: 96)),
                        ],
                      ),
                    ),
                    if (_multiSelectMode)
                      _MultiSelectActionBar(
                        selectedCount: _selectedPersonIds.length,
                        allSelected: sectionData.personIds.isNotEmpty &&
                            _selectedPersonIds.length == sectionData.personIds.length,
                        onToggleSelectAll: () => _toggleSelectAll(sectionData.personIds),
                        onDelete: () => _deleteSelectedPersons(db),
                      )
                    else
                      PrototypeBottomNav(activeIndex: 1, onTap: (index) => _handleBottomNavTap(context, index)),
                  ],
                ),
                Positioned(
                  right: 4,
                  top: 60,
                  bottom: bottomBarHeight + 24 + bottomInset,
                  child: _keyword.trim().isEmpty
                      ? _IndexBar(
                          letters: sectionData.indexLetters,
                          activeLetters: sectionData.activeIndexLetters,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ],
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
        return AlertDialog(
          title: const Text('删除联系人'),
          content: Text('确认删除已选择的${ids.length}位联系人？删除后将进入回收站。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
          ],
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除：${ids.length}项')));
  }

  void _exitMultiSelectMode() {
    setState(() {
      _selectedPersonIds = <String>{};
      _multiSelectMode = false;
    });
  }
}

class _PersonSectionData {
  const _PersonSectionData({
    required this.slivers,
    required this.indexLetters,
    required this.activeIndexLetters,
    required this.personIds,
  });

  final List<Widget> slivers;
  final List<String> indexLetters;
  final Set<String> activeIndexLetters;
  final List<String> personIds;
}

_PersonSectionData _buildPersonSectionData(
  BuildContext context,
  List<PersonData> sourcePersons,
  String keyword, {
  required bool multiSelectMode,
  required Set<String> selectedPersonIds,
  required ValueChanged<String> onPersonTap,
  required ValueChanged<String> onPersonLongPress,
  required ValueChanged<String> onPersonSelectionToggle,
}) {
  final trimmed = keyword.trim();
  final persons = (trimmed.isEmpty
          ? sourcePersons.toList()
          : sourcePersons
              .where((p) {
                final kw = trimmed.toLowerCase();
                return p.name.toLowerCase().contains(kw) || (p.phone ?? '').toLowerCase().contains(kw);
              })
              .toList())
    ..sort(_comparePersonByInitialAndName);
  if (persons.isEmpty) {
    return _PersonSectionData(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: Text(trimmed.isEmpty ? '暂无联系人' : '无匹配联系人')),
          ),
        ),
      ],
      indexLetters: const [],
      activeIndexLetters: const <String>{},
      personIds: const [],
    );
  }

  final Map<String, List<PersonData>> groups = {};
  for (final p in persons) {
    final letter = _letterForName(p.name);
    (groups[letter] ??= <PersonData>[]).add(p);
  }

  final keys = groups.keys.toList()..sort(_compareInitialLetter);
  final indexLetters = _buildIndexLetters(keys);
  final slivers = <Widget>[];
  for (final letter in keys) {
    slivers.add(_LetterHeader(letter: letter));
    final list = groups[letter]!;
    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      slivers.add(
        _PersonRow(
          id: p.id,
          avatarUrl: p.avatarUrl,
          name: p.name,
          subtitle: p.relationship,
          multiSelectMode: multiSelectMode,
          selected: selectedPersonIds.contains(p.id),
          fadeDuration: _CanvasState._multiSelectFadeDuration,
          longPressDuration: _CanvasState._longPressDuration,
          borderBottom: i != list.length - 1,
          onTap: () => onPersonTap(p.id),
          onLongPress: () => onPersonLongPress(p.id),
          onSelectionToggle: () => onPersonSelectionToggle(p.id),
        ),
      );
    }
  }
  return _PersonSectionData(
    slivers: slivers,
    indexLetters: indexLetters,
    activeIndexLetters: keys.toSet(),
    personIds: persons.map((e) => e.id).toList(growable: false),
  );
}

int _comparePersonByInitialAndName(PersonData a, PersonData b) {
  final letterCompare = _compareInitialLetter(_letterForName(a.name), _letterForName(b.name));
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

List<String> _buildIndexLetters(List<String> groupKeys) {
  final letters = List<String>.generate(26, (index) => String.fromCharCode(65 + index));
  if (groupKeys.contains('#')) {
    letters.add('#');
  }
  return letters;
}

class _LetterHeader extends StatelessWidget {
  const _LetterHeader({required this.letter});

  final String letter;
  static const double _headerHeight = 24;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: false,
      delegate: _HeaderDelegate(
        height: _headerHeight,
        child: Container(
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
        ),
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => child != oldDelegate.child;
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
  bool _longPressTriggered = false;
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
    _longPressTriggered = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(widget.longPressDuration, () {
      _longPressTriggered = true;
      if (mounted) {
        setState(() => _pressed = false);
      }
      widget.onLongPress();
    });
  }

  void _onTapUp(TapUpDetails _) {
    _longPressTimer?.cancel();
    if (!_longPressTriggered) {
      widget.onTap();
    }
    if (mounted) {
      setState(() => _pressed = false);
    }
  }

  void _onTapCancel() {
    _longPressTimer?.cancel();
    if (mounted) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: GestureDetector(
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
                  ? const Border(bottom: BorderSide(color: AppColors.borderDivider, width: 1))
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ContactAvatar(
                        name: widget.name,
                        avatarUrl: widget.avatarUrl,
                        size: 40,
                        shape: ContactAvatarShape.circle,
                        border: Border.all(color: AppColors.gray100, width: 1),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
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
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: AppTypography.base(
                          fontSize: 16,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    final backgroundColor = selected ? AppColors.brandPrimary : AppColors.gray500.withValues(alpha: 0.2);
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
        border: const Border(top: BorderSide(color: AppColors.borderDefault, width: 1)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: canDelete ? AppColors.stateDanger : AppColors.gray200,
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

class _IndexBar extends StatelessWidget {
  const _IndexBar({
    required this.letters,
    required this.activeLetters,
  });

  final List<String> letters;
  final Set<String> activeLetters;

  @override
  Widget build(BuildContext context) {
    if (letters.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final l in letters)
          Text(
            l,
            style: AppTypography.base(
              fontSize: 10,
              fontWeight: AppTypography.medium,
              color: activeLetters.contains(l) ? AppColors.indigo600 : AppColors.textMuted,
              height: 1.6,
            ),
          ),
      ],
    );
  }
}
