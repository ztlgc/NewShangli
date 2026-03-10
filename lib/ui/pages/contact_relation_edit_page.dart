import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_data.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../contact_avatar.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

class ContactRelationEditPage extends StatefulWidget {
  const ContactRelationEditPage({
    super.key,
    required this.id,
  }) : createMode = false;

  const ContactRelationEditPage.create({super.key})
      : id = null,
        createMode = true;

  final String? id;
  final bool createMode;

  @override
  State<ContactRelationEditPage> createState() => _ContactRelationEditPageState();
}

class _ContactRelationEditPageState extends State<ContactRelationEditPage> {
  bool _saving = false;
  bool _inited = false;
  String? _personAId;
  String? _personBId;
  String? _typeId;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final data = AppDataScope.of(context);

    final rel = widget.id == null ? null : data.findContactRelation(widget.id!);
    if (rel != null) {
      _personAId = rel.personAId;
      _personBId = rel.personBId;
      _typeId = rel.typeId;
      _noteCtrl.text = rel.note ?? '';
      return;
    }

    final persons = data.persons;
    final types = data.relationTypes;
    _personAId = persons.isEmpty ? null : persons.first.id;
    _personBId = persons.length < 2 ? null : persons[1].id;
    _typeId = types.isEmpty ? null : types.first.id;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    final rel = widget.id == null ? null : data.findContactRelation(widget.id!);
    final persons = data.persons.toList()..sort((a, b) => a.name.compareTo(b.name));
    final types = data.relationTypes.toList()..sort((a, b) => a.name.compareTo(b.name));

    final aName = _personAId == null ? '请选择' : (data.findPerson(_personAId!)?.name ?? '未知');
    final bName = _personBId == null ? '请选择' : (data.findPerson(_personBId!)?.name ?? '未知');
    final tName = _typeId == null ? '请选择' : (data.findRelationType(_typeId!)?.name ?? '未知');

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
                GestureDetector(
                  onTap: _saving ? null : () => AppNav.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '取消',
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.medium,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.createMode ? '新增关系' : '编辑关系',
                      style: AppTypography.base(
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
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
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SelectRow(
                        label: '联系人 A',
                        value: aName,
                        onTap: () async {
                          final picked = await _pickPerson(context, persons);
                          if (picked == null) return;
                          setState(() => _personAId = picked.id);
                        },
                      ),
                      const PrototypeDivider(color: AppColors.borderDivider),
                      _SelectRow(
                        label: '联系人 B',
                        value: bName,
                        onTap: () async {
                          final picked = await _pickPerson(context, persons);
                          if (picked == null) return;
                          setState(() => _personBId = picked.id);
                        },
                      ),
                      const PrototypeDivider(color: AppColors.borderDivider),
                      _SelectRow(
                        label: '关系类型',
                        value: tName,
                        onTap: () async {
                          final picked = await _pickType(context, types);
                          if (picked == null) return;
                          setState(() => _typeId = picked.id);
                        },
                        borderBottom: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PrototypeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '备注（可选）',
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 4,
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.gray50,
                          hintText: '可填写补充说明',
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!widget.createMode)
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
                        '删除关系',
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          color: AppColors.red500,
                        ),
                      ),
                    ),
                  ),
                if (!widget.createMode && rel == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        '该关系已不存在（可能已被删除）',
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
    final data = AppDataScope.of(context);
    final a = _personAId;
    final b = _personBId;
    final t = _typeId;
    if (a == null || b == null || t == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择联系人与关系类型')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.createMode) {
        await data.createContactRelation(
          personAId: a,
          personBId: b,
          typeId: t,
          note: _noteCtrl.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已创建')));
        AppNav.pop(context);
      } else {
        await data.updateContactRelation(
          id: widget.id!,
          personAId: a,
          personBId: b,
          typeId: t,
          note: _noteCtrl.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
        AppNav.pop(context);
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
          title: const Text('删除关系'),
          content: const Text('确认删除该联系人关系？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await data.deleteContactRelation(widget.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
      AppNav.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  Future<PersonData?> _pickPerson(BuildContext context, List<PersonData> persons) {
    return showModalBottomSheet<PersonData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _Sheet(
          title: '选择联系人',
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final p in persons)
                PrototypePressableRow(
                  onTap: () => Navigator.of(context).pop(p),
                  child: Row(
                    children: [
                      ContactAvatar(
                        name: p.name,
                        avatarUrl: p.avatarUrl,
                        size: 28,
                        shape: ContactAvatarShape.circle,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.medium,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<RelationTypeData?> _pickType(BuildContext context, List<RelationTypeData> types) {
    return showModalBottomSheet<RelationTypeData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _Sheet(
          title: '选择关系类型',
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final t in types)
                PrototypePressableRow(
                  onTap: () => Navigator.of(context).pop(t),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.tag, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.name,
                          style: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.medium,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.borderBottom = true,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: onTap,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.base(
                    fontSize: 16,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
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

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadii.br2xl,
          boxShadow: AppShadows.lg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
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
                      title,
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
                    onPressed: () => Navigator.of(context).pop(),
                    radius: 12,
                  ),
                ],
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
