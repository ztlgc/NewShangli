import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'relation_type_detail_page.dart';

class RelationTypeManagePage extends StatelessWidget {
  const RelationTypeManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      backgroundColor: AppColors.surfaceApp,
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final next = _searchCtrl.text.trim();
    if (next == _keyword) return;
    setState(() => _keyword = next);
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            border: Border(
              bottom: BorderSide(
                color: context.appColors.surfaceSubtle,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 14),
                backgroundColor: context.appColors.surfaceSubtle,
                foregroundColor: AppColors.textSecondary,
                onPressed: () => AppNav.pop(context),
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '联系人关系管理',
                  style: AppTypography.h2().copyWith(fontSize: 20),
                ),
              ),
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                backgroundColor: context.appColors.surfaceSubtle,
                foregroundColor: AppColors.textSecondary,
                onPressed: () => _openEditor(context, db, null),
                radius: 12,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<RelationType>>(
            stream: db.relationTypesDao.watchAll(),
            builder: (context, typeSnapshot) {
              final types = typeSnapshot.data ?? const <RelationType>[];
              return StreamBuilder<List<ContactRelationWithDetails>>(
                stream: db.contactRelationsDao.watchAllWithDetails(),
                builder: (context, relationSnapshot) {
                  final relationCountByTypeId = <String, int>{};
                  for (final relation
                      in relationSnapshot.data ??
                          const <ContactRelationWithDetails>[]) {
                    relationCountByTypeId.update(
                      relation.relation.typeId,
                      (v) => v + 1,
                      ifAbsent: () => 1,
                    );
                  }
                  return StreamBuilder<List<Person>>(
                    stream: db.personsDao.watchAllInAllBooks(),
                    builder: (context, personSnapshot) {
                      final personCountByRelationName = <String, int>{};
                      var categorizedContacts = 0;
                      for (final person
                          in personSnapshot.data ?? const <Person>[]) {
                        final relation = person.relationshipType.trim();
                        if (relation.isEmpty) continue;
                        categorizedContacts += 1;
                        final key = relation.toLowerCase();
                        personCountByRelationName.update(
                          key,
                          (v) => v + 1,
                          ifAbsent: () => 1,
                        );
                      }
                      final filter = _keyword.toLowerCase();
                      final visibleTypes = filter.isEmpty
                          ? types
                          : types
                                .where(
                                  (e) => e.name.toLowerCase().contains(filter),
                                )
                                .toList();
                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: context.appColors.surfaceCard,
                              borderRadius: AppRadii.brXl,
                              border: Border.all(
                                color: AppColors.borderDefault,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              style: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.medium,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '搜索关系类型...',
                                hintStyle: AppTypography.base(
                                  fontSize: 14,
                                  fontWeight: AppTypography.regular,
                                  color: AppColors.textMuted,
                                ),
                                icon: const FaIcon(
                                  FontAwesomeIcons.magnifyingGlass,
                                  size: 14,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: '总类型',
                                  value: '${types.length}',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  title: '已分类联系人',
                                  value: '$categorizedContacts',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              '所有类别',
                              style: AppTypography.base(
                                fontSize: 12,
                                fontWeight: AppTypography.semibold,
                                color: AppColors.textTertiary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (types.isEmpty)
                            PrototypeCard(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: Text(
                                    '暂无类型，点击右上角添加',
                                    style: AppTypography.base(
                                      fontSize: 14,
                                      fontWeight: AppTypography.medium,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else if (visibleTypes.isEmpty)
                            PrototypeCard(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: Text(
                                    '没有找到匹配的关系类型',
                                    style: AppTypography.base(
                                      fontSize: 14,
                                      fontWeight: AppTypography.medium,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            for (var i = 0; i < visibleTypes.length; i++) ...[
                              _TypeRow(
                                type: visibleTypes[i],
                                contactCount:
                                    personCountByRelationName[visibleTypes[i]
                                        .name
                                        .trim()
                                        .toLowerCase()] ??
                                    0,
                                relationCount:
                                    relationCountByTypeId[visibleTypes[i]
                                        .typeId] ??
                                    0,
                                onTap: () => AppNav.push(
                                  context,
                                  RelationTypeDetailPage(type: visibleTypes[i]),
                                  requiresLogin: true,
                                ),
                                onEdit: () =>
                                    _openEditor(context, db, visibleTypes[i]),
                                onLongPress: () => _confirmDelete(
                                  context,
                                  db,
                                  visibleTypes[i],
                                  personCountByRelationName[visibleTypes[i].name
                                          .trim()
                                          .toLowerCase()] ??
                                      0,
                                ),
                              ),
                              if (i != visibleTypes.length - 1)
                                const SizedBox(height: 10),
                            ],
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppDatabase db,
    RelationType? type,
  ) async {
    final nameCtrl = TextEditingController(text: type?.name ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        var saving = false;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: AppRadii.br2xl,
              boxShadow: AppShadows.lg,
            ),
            clipBehavior: Clip.antiAlias,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceCard,
                        border: Border(
                          bottom: BorderSide(
                            color: context.appColors.surfaceSubtle,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              type == null ? '新增类型' : '编辑类型',
                              style: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          PrototypeIconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.xmark,
                              size: 14,
                            ),
                            backgroundColor: context.appColors.surfaceSubtle,
                            foregroundColor: AppColors.textSecondary,
                            onPressed: saving
                                ? null
                                : () => Navigator.of(context).pop(false),
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
                            '类型名称',
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameCtrl,
                            autofocus: true,
                            style: AppTypography.base(
                              fontSize: 14,
                              fontWeight: AppTypography.medium,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: context.appColors.surfaceSubtle,
                              hintText: '如：家人、同事、朋友',
                              hintStyle: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.regular,
                                color: AppColors.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.borderSubtle,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.borderSubtle,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.borderFocus,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrototypePrimaryButton(
                            label: saving ? '保存中' : '保存',
                            onTap: saving
                                ? null
                                : () async {
                                    final text = nameCtrl.text.trim();
                                    if (text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('类型名称不能为空'),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() => saving = true);
                                    try {
                                      if (type == null) {
                                        await db.relationTypesDao.create(
                                          name: text,
                                        );
                                      } else {
                                        await db.relationTypesDao.updateType(
                                          id: type.typeId,
                                          name: text,
                                        );
                                      }
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(true);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('保存失败：$e')),
                                      );
                                      setState(() => saving = false);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    nameCtrl.dispose();
    if (ok != true || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已保存')));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppDatabase db,
    RelationType type,
    int contactCount,
  ) async {
    if (contactCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('该类型已被 $contactCount 个联系人使用，无法删除')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除类型'),
          content: Text('确认删除「${type.name}」？'),
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
        );
      },
    );
    if (ok != true) return;
    try {
      final relations = await db.contactRelationsDao
          .watchAllWithDetails()
          .first;
      final used = relations.any((e) => e.relation.typeId == type.typeId);
      if (used) throw StateError('该类型正在被使用，无法删除');
      await db.relationTypesDao.deleteById(type.typeId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已删除')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSubtle,
        borderRadius: AppRadii.brXl,
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.base(
              fontSize: 11,
              fontWeight: AppTypography.semibold,
              color: AppColors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.base(
              fontSize: 22,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.onTap,
    required this.onEdit,
    required this.onLongPress,
    required this.contactCount,
    required this.relationCount,
  });

  final RelationType type;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onLongPress;
  final int contactCount;
  final int relationCount;

  @override
  Widget build(BuildContext context) {
    final pair = _palette(type.name);
    final icon = _icon(type.name);
    final usageText = contactCount > 0
        ? '$contactCount 个联系人'
        : relationCount > 0
        ? '$relationCount 条联系人关系'
        : '未使用';
    return Material(
      color: context.appColors.surfaceCard,
      borderRadius: AppRadii.brXl,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadii.brXl,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadii.brXl,
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pair.$1,
                    borderRadius: AppRadii.brLg,
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(icon, size: 18, color: pair.$2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.base(
                          fontSize: 16,
                          fontWeight: AppTypography.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        usageText,
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkResponse(
                  radius: 18,
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 12,
                  color: AppColors.gray300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _palette(String seed) {
    final list = <(Color, Color)>[
      (AppColors.blue100, AppColors.blue600),
      (AppColors.orange100, AppColors.orange600),
      (AppColors.purple100, AppColors.purple600),
      (AppColors.green100, AppColors.green600),
      (AppColors.pink100, AppColors.pink600),
      (AppColors.indigo100, AppColors.indigo700),
    ];
    final idx = seed.hashCode.abs() % list.length;
    return list[idx];
  }

  IconData _icon(String seed) {
    final list = <IconData>[
      FontAwesomeIcons.userGroup,
      FontAwesomeIcons.briefcase,
      FontAwesomeIcons.house,
      FontAwesomeIcons.graduationCap,
      FontAwesomeIcons.handshake,
      FontAwesomeIcons.tags,
    ];
    final idx = seed.hashCode.abs() % list.length;
    return list[idx];
  }
}
