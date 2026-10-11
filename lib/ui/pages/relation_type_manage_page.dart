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
              return StreamBuilder<List<Person>>(
                stream: db.personsDao.watchAllInAllBooks(),
                builder: (context, personSnapshot) {
                  final contactCountByName = <String, int>{};
                  for (final person
                      in personSnapshot.data ?? const <Person>[]) {
                    final key = person.relationshipType.trim().toLowerCase();
                    if (key.isEmpty) continue;
                    contactCountByName.update(
                      key,
                      (count) => count + 1,
                      ifAbsent: () => 1,
                    );
                  }
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: AppLayout.tabContentPadding,
                    children: [
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            if (types.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  '暂无类型，点击右上角添加',
                                  style: AppTypography.base(
                                    fontSize: 14,
                                    fontWeight: AppTypography.medium,
                                    color: context.appColors.textMuted,
                                  ),
                                ),
                              )
                            else
                              for (var i = 0; i < types.length; i++)
                                _TypeRow(
                                  type: types[i],
                                  contactCount:
                                      contactCountByName[types[i].name
                                          .trim()
                                          .toLowerCase()] ??
                                      0,
                                  borderBottom: i != types.length - 1,
                                  onTap: () => AppNav.push(
                                    context,
                                    RelationTypeDetailPage(
                                      type: types[i],
                                      onEdit: (type) =>
                                          _openEditor(context, db, type),
                                    ),
                                  ),
                                  onLongPress: () => _confirmDelete(
                                    context,
                                    db,
                                    types[i],
                                    contactCountByName[types[i].name
                                            .trim()
                                            .toLowerCase()] ??
                                        0,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
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

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.onTap,
    required this.onLongPress,
    required this.contactCount,
    required this.borderBottom,
  });

  final RelationType type;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int contactCount;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppPressableRow(
      onTap: onTap,
      onLongPress: onLongPress,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.brandSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              AppIcons.usersRound,
              size: 14,
              color: colors.brandOnSoft,
            ),
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
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contactCount > 0 ? '$contactCount 位联系人' : '暂无联系人',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(AppIcons.chevronRight, size: 12, color: colors.textMuted),
        ],
      ),
    );
  }
}
