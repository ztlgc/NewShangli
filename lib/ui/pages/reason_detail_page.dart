import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_data.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../../utils/date_util.dart';

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
    if (widget.id == null) return;
    final data = AppDataScope.of(context);
    final reason = data.findReason(widget.id!);
    _nameCtrl.text = reason?.name ?? '';
    _descCtrl.text = reason?.description ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    final reason = widget.id == null ? null : data.findReason(widget.id!);

    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
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
                  onPressed: _saving ? null : () => AppNav.pop(context),
                  radius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.id == null ? '新增事由' : '事由详情',
                    style: AppTypography.h2().copyWith(fontSize: 20),
                  ),
                ),
                if (!_editing)
                  PrototypeIconButton(
                    icon: const FaIcon(FontAwesomeIcons.pen, size: 14),
                    backgroundColor: AppColors.gray100,
                    foregroundColor: AppColors.textSecondary,
                    onPressed: () => setState(() => _editing = true),
                    radius: 12,
                  )
                else
                  PressableScale(
                    onTap: _saving ? null : _onSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _saving ? AppColors.gray300 : AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Text(
                        _saving ? '保存中' : '保存',
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                PrototypeCard(
                  padding: const EdgeInsets.all(16),
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
                  PrototypeCard(
                    padding: const EdgeInsets.all(16),
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
                        Switch(
                          value: reason.enabled,
                          onChanged: _saving ? null : (v) => data.setReasonEnabled(id: reason.id, enabled: v),
                        ),
                      ],
                    ),
                  ),
                if (reason != null) const SizedBox(height: 16),
                if (!_editing && widget.id != null && reason != null)
                  PrototypeCard(
                    padding: const EdgeInsets.all(16),
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
                          _formatTime(reason.updatedAt),
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
                    onTap: _saving ? null : () => _confirmDelete(context, data),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray100, width: 1),
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
    final data = AppDataScope.of(context);
    try {
      if (widget.id == null) {
        await data.createReason(name: _nameCtrl.text, description: _descCtrl.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已创建')));
        AppNav.pop(context);
      } else {
        await data.updateReason(id: widget.id!, name: _nameCtrl.text, description: _descCtrl.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
        setState(() => _editing = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppData data) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除事由'),
          content: const Text('确认删除该事由？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await data.deleteReason(widget.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
      AppNav.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
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
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      style: AppTypography.base(
        fontSize: 14,
        fontWeight: AppTypography.medium,
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled ? AppColors.gray50 : AppColors.gray100,
        hintText: hintText,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red500, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red500, width: 1),
        ),
      ),
    );
  }
}
