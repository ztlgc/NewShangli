import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_notification_tokens.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../contact_avatar.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

class ContactRelationEditPage extends StatefulWidget {
  const ContactRelationEditPage({super.key, required this.id})
    : createMode = false;

  const ContactRelationEditPage.create({super.key})
    : id = null,
      createMode = true;

  final String? id;
  final bool createMode;

  @override
  State<ContactRelationEditPage> createState() =>
      _ContactRelationEditPageState();
}

class _ContactRelationEditPageState extends State<ContactRelationEditPage> {
  bool _saving = false;
  bool _inited = false;
  String? _personAId;
  String? _personBId;
  String? _typeId;
  late final TextEditingController _noteCtrl;
  ContactRelation? _relation;

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
    _loadRelation();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);

    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: StreamBuilder<List<Person>>(
        stream: db.personsDao.watchAllInAllBooks(),
        builder: (context, personSnapshot) {
          final persons = personSnapshot.data ?? const <Person>[];
          return StreamBuilder<List<RelationType>>(
            stream: db.relationTypesDao.watchAll(),
            builder: (context, typeSnapshot) {
              final types = typeSnapshot.data ?? const <RelationType>[];
              _ensureDefaults(persons, types);
              final aName = _resolvePersonName(persons, _personAId);
              final bName = _resolvePersonName(persons, _personBId);
              final tName = _resolveTypeName(types, _typeId);
              return Column(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _saving
                                  ? AppColors.gray300
                                  : AppColors.brandPrimary,
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
                                  final picked = await _pickPerson(
                                    context,
                                    persons,
                                  );
                                  if (picked == null) return;
                                  setState(() => _personAId = picked.personId);
                                },
                              ),
                              const PrototypeDivider(
                                color: AppColors.borderDivider,
                              ),
                              _SelectRow(
                                label: '联系人 B',
                                value: bName,
                                onTap: () async {
                                  final picked = await _pickPerson(
                                    context,
                                    persons,
                                  );
                                  if (picked == null) return;
                                  setState(() => _personBId = picked.personId);
                                },
                              ),
                              const PrototypeDivider(
                                color: AppColors.borderDivider,
                              ),
                              _SelectRow(
                                label: '关系类型',
                                value: tName,
                                onTap: () async {
                                  final picked = await _pickType(
                                    context,
                                    types,
                                  );
                                  if (picked == null) return;
                                  setState(() => _typeId = picked.typeId);
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
                                  fillColor: context.appColors.surfaceSubtle,
                                  hintText: '可填写补充说明',
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!widget.createMode)
                          PressableScale(
                            onTap: _saving
                                ? null
                                : () => _confirmDelete(context, db),
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
                                '删除关系',
                                style: AppTypography.base(
                                  fontSize: 14,
                                  fontWeight: AppTypography.medium,
                                  color: AppColors.red500,
                                ),
                              ),
                            ),
                          ),
                        if (!widget.createMode && _relation == null)
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
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onSave() async {
    final db = AppDatabaseScope.of(context);
    final a = _personAId;
    final b = _personBId;
    final t = _typeId;
    if (a == null || b == null || t == null) {
      AppNotifier.warning(context, '请先选择联系人与关系类型');
      return;
    }
    setState(() => _saving = true);
    try {
      if (a == b) {
        throw ArgumentError('两个联系人不能相同');
      }
      final exists = await db.contactRelationsDao.existsByPair(
        personAId: a,
        personBId: b,
        typeId: t,
        excludeRelationId: widget.createMode ? null : widget.id,
      );
      if (exists) throw ArgumentError('该关系已存在');
      if (widget.createMode) {
        await db.contactRelationsDao.create(
          personAId: a,
          personBId: b,
          typeId: t,
          note: _noteCtrl.text,
        );
        if (!mounted) return;
        AppNotifier.success(context, '已创建');
        AppNav.pop(context);
      } else {
        await db.contactRelationsDao.updateOne(
          relationId: widget.id!,
          personAId: a,
          personBId: b,
          typeId: t,
          note: _noteCtrl.text,
        );
        if (!mounted) return;
        AppNotifier.success(context, '已保存');
        AppNav.pop(context);
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
      title: '删除关系',
      message: '确认删除该联系人关系？',
      confirmLabel: '删除',
      cancelLabel: '取消',
      tone: AppNotificationTone.error,
    );
    if (ok != true) return;
    try {
      await db.contactRelationsDao.deleteById(widget.id!);
      if (!context.mounted) return;
      AppNotifier.success(context, '已删除');
      AppNav.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      AppNotifier.error(context, '删除失败：$e');
    }
  }

  Future<void> _loadRelation() async {
    final id = widget.id;
    if (id == null || id.trim().isEmpty) return;
    final db = AppDatabaseScope.of(context);
    final rel = await db.contactRelationsDao.findById(id);
    if (!mounted) return;
    setState(() {
      _relation = rel;
      _personAId = rel?.personAId;
      _personBId = rel?.personBId;
      _typeId = rel?.typeId;
      _noteCtrl.text = rel?.note ?? '';
    });
  }

  void _ensureDefaults(List<Person> persons, List<RelationType> types) {
    if (_personAId == null && persons.isNotEmpty) {
      _personAId = persons.first.personId;
    }
    if (_personBId == null && persons.length >= 2) {
      _personBId = persons[1].personId;
    }
    if (_typeId == null && types.isNotEmpty) {
      _typeId = types.first.typeId;
    }
  }

  String _resolvePersonName(List<Person> persons, String? personId) {
    if (personId == null || personId.trim().isEmpty) return '请选择';
    for (final p in persons) {
      if (p.personId == personId) return p.name;
    }
    return '未知';
  }

  String _resolveTypeName(List<RelationType> types, String? typeId) {
    if (typeId == null || typeId.trim().isEmpty) return '请选择';
    for (final t in types) {
      if (t.typeId == typeId) return t.name;
    }
    return '未知';
  }

  Future<Person?> _pickPerson(BuildContext context, List<Person> persons) {
    return showModalBottomSheet<Person>(
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
                        avatarUrl: p.avatarUri,
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

  Future<RelationType?> _pickType(
    BuildContext context,
    List<RelationType> types,
  ) {
    return showModalBottomSheet<RelationType>(
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
                      const FaIcon(
                        FontAwesomeIcons.tag,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
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
          const FaIcon(
            FontAwesomeIcons.chevronRight,
            size: 10,
            color: AppColors.gray300,
          ),
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
                    backgroundColor: context.appColors.surfaceSubtle,
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
