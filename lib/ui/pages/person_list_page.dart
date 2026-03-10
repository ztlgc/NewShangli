import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_data.dart';
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
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              ),
              child: Row(
                children: [
                  Text('关系人', style: AppTypography.h2().copyWith(fontSize: 20)),
                  const Spacer(),
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
                  ..._buildPersonSlivers(context, data, _keyword),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            ),
            PrototypeBottomNav(
              activeIndex: 1,
              onTap: (index) {
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
              },
            ),
          ],
        ),
        Positioned(
          right: 4,
          top: 60,
          bottom: AppTokens.tabBarHeight + 24 + bottomInset,
          child: _keyword.trim().isEmpty ? const _IndexBar() : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

List<Widget> _buildPersonSlivers(BuildContext context, AppData data, String keyword) {
  final trimmed = keyword.trim();
  final persons = (trimmed.isEmpty
          ? data.persons.toList()
          : data.persons
              .where((p) {
                final kw = trimmed.toLowerCase();
                return p.name.toLowerCase().contains(kw) || (p.phone ?? '').toLowerCase().contains(kw);
              })
              .toList())
    ..sort((a, b) => a.name.compareTo(b.name));
  if (persons.isEmpty) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: Text(trimmed.isEmpty ? '暂无联系人' : '无匹配联系人')),
        ),
      ),
    ];
  }

  final Map<String, List<PersonData>> groups = {};
  for (final p in persons) {
    final letter = _letterForName(p.name);
    (groups[letter] ??= <PersonData>[]).add(p);
  }

  final keys = groups.keys.toList()..sort();
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
          borderBottom: i != list.length - 1,
          onTap: () => AppNav.push(context, PersonDetailPage(personId: p.id), requiresLogin: true),
          onLongPress: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('删除联系人'),
                  content: Text('确认删除「${p.name}」？删除后将进入回收站。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
                  ],
                );
              },
            );
            if (!context.mounted) return;
            if (ok != true) return;
            data.trashPerson(p.id);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已移入回收站')));
          },
        ),
      );
    }
  }
  return slivers;
}

String _letterForName(String name) {
  final first = contactAvatarTextFromName(name);
  if (first == '—' || first == '#') return '#';
  switch (first) {
    case '阿':
      return 'A';
    case '李':
      return 'L';
    case '王':
      return 'W';
    case '张':
    case '赵':
      return 'Z';
  }
  final upper = first.toUpperCase();
  if (RegExp(r'^[A-Z]$').hasMatch(upper)) return upper;
  return '#';
}

class _LetterHeader extends StatelessWidget {
  const _LetterHeader({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(
        child: Container(
          height: 20,
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
  _HeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 20;

  @override
  double get maxExtent => 20;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => child != oldDelegate.child;
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.id,
    required this.avatarUrl,
    required this.name,
    required this.subtitle,
    required this.onTap,
    required this.onLongPress,
    this.borderBottom = true,
  });

  final String id;
  final String? avatarUrl;
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: PrototypePressableRow(
        onTap: onTap,
        onLongPress: onLongPress,
        borderBottom: borderBottom,
        child: Row(
          children: [
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
                  Text(
                    name,
                    style: AppTypography.base(
                      fontSize: 16,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }
}

class _IndexBar extends StatelessWidget {
  const _IndexBar();

  @override
  Widget build(BuildContext context) {
    const letters = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      '#',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final l in letters)
          Text(
            l,
            style: AppTypography.base(
              fontSize: 10,
              fontWeight: (l == 'L' || l == 'W' || l == 'Z') ? AppTypography.bold : AppTypography.regular,
              color: (l == 'L' || l == 'W' || l == 'Z') ? AppColors.indigo600 : AppColors.textMuted,
              height: 1.6,
            ),
          ),
      ],
    );
  }
}

