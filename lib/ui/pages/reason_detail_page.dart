import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import '../../utils/date_util.dart';

import '../app_icons.dart';

import '../app_layout.dart';

class ReasonDetailPage extends StatefulWidget {
  const ReasonDetailPage({
    super.key,
    required this.id,
    this.initialEdit = false,
  });

  const ReasonDetailPage.create({super.key}) : id = null, initialEdit = true;

  final String? id;
  final bool initialEdit;

  @override
  State<ReasonDetailPage> createState() => _ReasonDetailPageState();
}

class _ReasonDetailPageState extends State<ReasonDetailPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  bool _editing = false;
  bool _saving = false;
  bool _inited = false;
  Reason? _reason;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _editing = widget.initialEdit;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    _loadReason();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    final reason = _reason;

    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          FHeader.nested(
            title: Text(widget.id == null ? '新增事由' : '事由详情'),
            prefixes: [
              FButton.icon(
                variant: .ghost,
                semanticsLabel: '返回',
                onPress: _saving ? null : () => AppNav.pop(context),
                child: const Icon(AppIcons.chevronLeft),
              ),
            ],
            suffixes: [
              if (!_editing)
                FButton.icon(
                  variant: .ghost,
                  semanticsLabel: '编辑',
                  onPress: () => setState(() => _editing = true),
                  child: const Icon(AppIcons.pencil),
                )
              else
                FButton(
                  size: .sm,
                  mainAxisSize: MainAxisSize.min,
                  onPress: _saving ? null : _onSave,
                  child: Text(_saving ? '保存中' : '保存'),
                ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: AppLayout.tabContentPadding,
              children: [
                AppCard(
                  padding: AppLayout.pagePadding,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '事由名称',
                          style: AppTypography.base(
                            fontSize: 12,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _nameCtrl,
                          enabled: _editing,
                          hintText: '请输入事由名称',
                          maxLines: 1,
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return '事由名称不能为空';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '描述（可选）',
                          style: AppTypography.base(
                            fontSize: 12,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _descCtrl,
                          enabled: _editing,
                          hintText: '可填写备注或说明',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (reason != null)
                  AppCard(
                    padding: AppLayout.pagePadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '启用',
                            style: AppTypography.base(
                              fontSize: 14,
                              fontWeight: AppTypography.medium,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        FSwitch(
                          value: reason.enabled,
                          onChange: _saving
                              ? null
                              : (v) async {
                                  await db.reasonsDao.setEnabled(
                                    id: reason.reasonId,
                                    enabled: v,
                                  );
                                  await _loadReason();
                                },
                        ),
                      ],
                    ),
                  ),
                if (reason != null) const SizedBox(height: 16),
                if (!_editing && widget.id != null && reason != null)
                  AppCard(
                    padding: AppLayout.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '最近更新',
                          style: AppTypography.base(
                            fontSize: 12,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(
                            DateTime.fromMillisecondsSinceEpoch(
                              reason.updatedAt,
                            ),
                          ),
                          style: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.medium,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (widget.id != null)
                  PressableScale(
                    onTap: _saving ? null : () => _confirmDelete(context, db),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.appColors.surfaceSubtle,
                          width: 1,
                        ),
                        boxShadow: AppShadows.sm,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '删除事由',
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          color: AppColors.red500,
                        ),
                      ),
                    ),
                  ),
                if (widget.id != null && reason == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        '该事由已不存在（可能已被删除）',
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    setState(() => _saving = true);
    final db = AppDatabaseScope.of(context);
    try {
      final name = _nameCtrl.text.trim();
      final description = _descCtrl.text.trim();
      final all = await db.reasonsDao.listAll();
      final duplicated = all.any(
        (e) =>
            e.reasonId != widget.id &&
            e.name.trim().toLowerCase() == name.toLowerCase(),
      );
      if (duplicated) {
        throw ArgumentError.value(name, 'name', '已存在同名事由');
      }
      if (widget.id == null) {
        await db.reasonsDao.create(name: name, description: description);
        if (!mounted) return;
        AppNotifier.success(context, '已创建');
        AppNav.pop(context);
      } else {
        await db.reasonsDao.updateReason(
          id: widget.id!,
          name: name,
          description: description,
        );
        await _loadReason();
        if (!mounted) return;
        AppNotifier.success(context, '已保存');
        setState(() => _editing = false);
      }
    } catch (e) {
      if (!mounted) return;
      AppNotifier.error(context, '保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppDatabase db) async {
    final ok = await AppDialog.confirm(
      context,
      title: '删除事由',
      message: '确认删除该事由？',
      confirmLabel: '删除',
      danger: true,
    );
    if (ok != true) return;
    try {
      await db.reasonsDao.deleteById(widget.id!);
      if (!context.mounted) return;
      AppNotifier.success(context, '已删除');
      AppNav.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      AppNotifier.error(context, '删除失败：$e');
    }
  }

  Future<void> _loadReason() async {
    final id = widget.id;
    if (id == null || id.trim().isEmpty) return;
    final db = AppDatabaseScope.of(context);
    final row = await db.reasonsDao.findById(id);
    if (!mounted) return;
    setState(() {
      _reason = row;
      _nameCtrl.text = row?.name ?? '';
      _descCtrl.text = row?.description ?? '';
    });
  }

  String _formatTime(DateTime dt) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${DateUtil.format(dt)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.maxLines,
    this.validator,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FTextFormField(
      control: FTextFieldControl.managed(controller: controller),
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      hint: hintText,
    );
  }
}
