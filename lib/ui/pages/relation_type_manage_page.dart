import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../data/local/drift/app_database.dart';
import '../app_bottom_sheet.dart';
import '../app_database_scope.dart';
import '../app_forui_theme.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_notification_tokens.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../forui_search_field.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import 'relation_type_detail_page.dart';

import '../app_icons.dart';

import '../app_layout.dart';

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
        AppTopBar(
          title: '关系类型管理',
          left: AppIconButton(
            icon: const Icon(AppIcons.chevronLeft, size: 14),
            backgroundColor: context.appColors.surfaceSubtle,
            foregroundColor: AppColors.textSecondary,
            onPressed: () => AppNav.pop(context),
            radius: 12,
          ),
          right: AppIconButton(
            icon: const Icon(AppIcons.plus, size: 16),
            backgroundColor: context.appColors.surfaceSubtle,
            foregroundColor: AppColors.textSecondary,
            onPressed: () => _openEditor(context, db, null),
            radius: 12,
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
                        padding: AppLayout.tabContentPadding,
                        children: [
                          ForuiSearchField(
                            controller: _searchCtrl,
                            hint: '搜索关系类型...',
                            onChanged: (_) {},
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
                            AppCard(
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
                            AppCard(
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
    final ok = await AppBottomSheet.showCustom<bool>(
      context,
      builder: (context) => _RelationTypeEditorSheet(db: db, type: type),
    );
    if (ok != true || !context.mounted) return;
    AppNotifier.success(context, '已保存');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppDatabase db,
    RelationType type,
    int contactCount,
  ) async {
    if (contactCount > 0) {
      AppNotifier.warning(context, '该类型已被 $contactCount 个联系人使用，无法删除');
      return;
    }
    final ok = await AppDialog.confirm(
      context,
      title: '删除关系类型',
      message: '确认删除关系类型「${type.name}」？',
      confirmLabel: '删除',
      cancelLabel: '取消',
      tone: AppNotificationTone.error,
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
      AppNotifier.success(context, '已删除');
    } catch (e) {
      if (!context.mounted) return;
      AppNotifier.error(context, '删除失败：$e');
    }
  }
}

class _RelationTypeEditorSheet extends StatefulWidget {
  const _RelationTypeEditorSheet({required this.db, this.type});

  final AppDatabase db;
  final RelationType? type;

  @override
  State<_RelationTypeEditorSheet> createState() =>
      _RelationTypeEditorSheetState();
}

class _RelationTypeEditorSheetState extends State<_RelationTypeEditorSheet> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.type?.name ?? '');
  }

  @override
  void dispose() {
    // 由弹层自身持有并释放，避免路由退出动画期间被外部提前 dispose。
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _nameCtrl.text.trim();
    if (text.isEmpty) {
      AppNotifier.warning(context, '类型名称不能为空');
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.type == null) {
        await widget.db.relationTypesDao.create(name: text);
      } else {
        await widget.db.relationTypesDao.updateType(
          id: widget.type!.typeId,
          name: text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppNotifier.error(context, '保存失败：$e');
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final type = widget.type;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: AppRadii.br2xl,
          boxShadow: AppShadows.lg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  AppIconButton(
                    icon: const Icon(AppIcons.x, size: 14),
                    backgroundColor: context.appColors.surfaceSubtle,
                    foregroundColor: AppColors.textSecondary,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    radius: 12,
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppLayout.pagePadding,
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
                  AppForuiBoundary(
                    child: FTextField(
                      control: FTextFieldControl.managed(controller: _nameCtrl),
                      autofocus: true,
                      hint: '如：家人、同事、朋友',
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    label: _saving ? '保存中' : '保存',
                    onTap: _saving ? null : _save,
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
                  child: Icon(icon, size: 18, color: pair.$2),
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
                    child: Icon(
                      AppIcons.squarePen,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  AppIcons.chevronRight,
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
      AppIcons.usersRound,
      AppIcons.briefcaseBusiness,
      AppIcons.house,
      AppIcons.graduationCap,
      AppIcons.handshake,
      AppIcons.tags,
    ];
    final idx = seed.hashCode.abs() % list.length;
    return list[idx];
  }
}
