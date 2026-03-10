import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_data.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../contact_avatar.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'contact_relation_edit_page.dart';
import 'relation_type_manage_page.dart';

class ContactRelationManagePage extends StatelessWidget {
  const ContactRelationManagePage({super.key});

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
  static const int _pageSize = 20;
  final ScrollController _controller = ScrollController();
  int _visibleCount = _pageSize;
  bool _graphMode = false;
  String? _selectedPersonId;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_graphMode) return;
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    setState(() => _visibleCount += _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    final persons = data.persons.toList()..sort((a, b) => a.name.compareTo(b.name));

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
              Expanded(child: Text('联系人关系管理', style: AppTypography.h2().copyWith(fontSize: 20))),
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.layerGroup, size: 14),
                backgroundColor: AppColors.gray100,
                foregroundColor: AppColors.textSecondary,
                onPressed: () => AppNav.push(context, const RelationTypeManagePage()),
                radius: 12,
              ),
              const SizedBox(width: 8),
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                backgroundColor: AppColors.gray100,
                foregroundColor: AppColors.textSecondary,
                onPressed: () => AppNav.push(context, const ContactRelationEditPage.create()),
                radius: 12,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (data.relationsLoadError != null)
                PrototypeCard(
                  color: AppColors.orange50,
                  shadow: null,
                  border: Border.all(color: AppColors.orange100, width: 1),
                  child: Text(
                    '联系人关系加载失败，已使用默认数据：${data.relationsLoadError}',
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.medium,
                      color: AppColors.orange600,
                    ),
                  ),
                ),
              if (data.relationsLoadError != null) const SizedBox(height: 12),
              _ModeSwitch(
                graphMode: _graphMode,
                onChanged: (v) => setState(() => _graphMode = v),
              ),
              const SizedBox(height: 12),
              if (_graphMode)
                _GraphView(
                  persons: persons,
                  selectedPersonId: _selectedPersonId,
                  onChangePerson: (id) => setState(() => _selectedPersonId = id),
                )
              else
                _ListView(
                  visibleCount: _visibleCount,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.graphMode, required this.onChanged});

  final bool graphMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () => onChanged(false),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: graphMode ? AppColors.white : AppColors.indigo50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '列表',
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: graphMode ? AppColors.textSecondary : AppColors.indigo700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PressableScale(
              onTap: () => onChanged(true),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: graphMode ? AppColors.indigo50 : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '图谱',
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: graphMode ? AppColors.indigo700 : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.visibleCount});

  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    final relations = data.contactRelations.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final showCount = relations.length < visibleCount ? relations.length : visibleCount;
    return PrototypeCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (relations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '暂无关系，点击右上角添加',
                style: AppTypography.base(
                  fontSize: 14,
                  fontWeight: AppTypography.medium,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (var i = 0; i < showCount; i++)
              _RelationRow(
                relation: relations[i],
                borderBottom: i != showCount - 1,
                onTap: () => AppNav.push(context, ContactRelationEditPage(id: relations[i].id)),
                onLongPress: () => _confirmDelete(context, data, relations[i]),
              ),
          if (showCount < relations.length)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '继续下拉加载更多…',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppData data, ContactRelationData rel) async {
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
      await data.deleteContactRelation(rel.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }
}

class _RelationRow extends StatelessWidget {
  const _RelationRow({
    required this.relation,
    required this.onTap,
    required this.onLongPress,
    this.borderBottom = true,
  });

  final ContactRelationData relation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    final a = data.findPerson(relation.personAId);
    final b = data.findPerson(relation.personBId);
    final t = data.findRelationType(relation.typeId);

    final aName = a?.name ?? '未知';
    final bName = b?.name ?? '未知';
    final tName = t?.name ?? '未知';

    return PrototypePressableRow(
      onTap: onTap,
      onLongPress: onLongPress,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const FaIcon(FontAwesomeIcons.diagramProject, size: 14, color: AppColors.blue600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      aName,
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.medium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    PrototypePill(
                      label: tName,
                      background: AppColors.indigo50,
                      foreground: AppColors.indigo700,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      fontSize: 12,
                    ),
                    Text(
                      bName,
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.medium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  relation.note == null || relation.note!.trim().isEmpty ? '—' : relation.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textMuted,
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

class _GraphView extends StatelessWidget {
  const _GraphView({
    required this.persons,
    required this.selectedPersonId,
    required this.onChangePerson,
  });

  final List<PersonData> persons;
  final String? selectedPersonId;
  final ValueChanged<String> onChangePerson;

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    if (persons.isEmpty) {
      return PrototypeCard(
        child: Text(
          '暂无联系人',
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.medium,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    final selected = selectedPersonId == null ? persons.first : (data.findPerson(selectedPersonId!) ?? persons.first);
    final rels = data.contactRelations.where((e) => e.personAId == selected.id || e.personBId == selected.id).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrototypeCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const FaIcon(FontAwesomeIcons.user, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.name,
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const FaIcon(FontAwesomeIcons.chevronDown, size: 10, color: AppColors.gray300),
            ],
          ),
        ),
        const SizedBox(height: 8),
        PrototypeCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '关系图谱（以当前联系人为中心）',
                style: AppTypography.base(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.indigo50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.indigo100, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ContactAvatar(
                        name: selected.name,
                        avatarUrl: selected.avatarUrl,
                        size: 28,
                        shape: ContactAvatarShape.circle,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        selected.name,
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.bold,
                          color: AppColors.indigo900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (rels.isEmpty)
                Center(
                  child: Text(
                    '暂无关联关系',
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final rel in rels)
                      _GraphEdgePill(
                        centerPersonId: selected.id,
                        relation: rel,
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        PrototypeCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                '切换中心联系人',
                style: AppTypography.base(
                  fontSize: 12,
                  fontWeight: AppTypography.medium,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              PressableScale(
                onTap: () async {
                  final picked = await _pickPerson(context, persons);
                  if (picked == null) return;
                  onChangePerson(picked.id);
                },
                child: Row(
                  children: [
                    Text(
                      '选择',
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.medium,
                        color: AppColors.indigo700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
}

class _GraphEdgePill extends StatelessWidget {
  const _GraphEdgePill({required this.centerPersonId, required this.relation});

  final String centerPersonId;
  final ContactRelationData relation;

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    final otherId = relation.personAId == centerPersonId ? relation.personBId : relation.personAId;
    final other = data.findPerson(otherId);
    final type = data.findRelationType(relation.typeId);

    return PressableScale(
      onTap: () => AppNav.push(context, ContactRelationEditPage(id: relation.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray100, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              other?.name ?? '未知',
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.medium,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            PrototypePill(
              label: type?.name ?? '未知',
              background: AppColors.indigo50,
              foreground: AppColors.indigo700,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              fontSize: 12,
            ),
          ],
        ),
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
