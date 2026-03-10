import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_data.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

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
    final data = AppDataScope.of(context);
    final types = data.relationTypes.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

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
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 14),
                backgroundColor: AppColors.gray100,
                foregroundColor: AppColors.textSecondary,
                onPressed: () => AppNav.pop(context),
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('关系类型', style: AppTypography.h2().copyWith(fontSize: 20))),
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                backgroundColor: AppColors.gray100,
                foregroundColor: AppColors.textSecondary,
                onPressed: () => _openEditor(context, data, null),
                radius: 12,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              PrototypeCard(
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
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < types.length; i++)
                        _TypeRow(
                          type: types[i],
                          used: data.contactRelations.any((e) => e.typeId == types[i].id),
                          borderBottom: i != types.length - 1,
                          onTap: () => _openEditor(context, data, types[i]),
                          onLongPress: () => _confirmDelete(context, data, types[i]),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, AppData data, RelationTypeData? type) async {
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
            decoration: const BoxDecoration(
              color: AppColors.white,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
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
                            icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                            backgroundColor: AppColors.gray100,
                            foregroundColor: AppColors.textSecondary,
                            onPressed: saving ? null : () => Navigator.of(context).pop(false),
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
                              fillColor: AppColors.gray50,
                              hintText: '如：家人、同事、朋友',
                              hintStyle: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.regular,
                                color: AppColors.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderFocus, width: 1),
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('类型名称不能为空')),
                                      );
                                      return;
                                    }
                                    setState(() => saving = true);
                                    try {
                                      if (type == null) {
                                        await data.createRelationType(name: text);
                                      } else {
                                        await data.updateRelationType(id: type.id, name: text);
                                      }
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(true);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
  }

  Future<void> _confirmDelete(BuildContext context, AppData data, RelationTypeData type) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除类型'),
          content: Text('确认删除「${type.name}」？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await data.deleteRelationType(type.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.used,
    required this.onTap,
    required this.onLongPress,
    this.borderBottom = true,
  });

  final RelationTypeData type;
  final bool used;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: onTap,
      onLongPress: onLongPress,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.indigo50, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const FaIcon(FontAwesomeIcons.tag, size: 14, color: AppColors.indigo700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  used ? '使用中' : '未使用',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: used ? AppColors.textSecondary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
        ],
      ),
    );
  }
}
