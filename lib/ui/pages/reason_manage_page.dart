import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'reason_detail_page.dart';

class ReasonManagePage extends StatelessWidget {
  const ReasonManagePage({super.key});

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
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    setState(() => _visibleCount += _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);

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
              Expanded(child: Text('事由管理', style: AppTypography.h2().copyWith(fontSize: 20))),
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                backgroundColor: AppColors.gray100,
                foregroundColor: AppColors.textSecondary,
                onPressed: () => AppNav.push(context, const ReasonDetailPage.create()),
                radius: 12,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Reason>>(
            stream: db.reasonsDao.watchAll(),
            builder: (context, snapshot) {
              final reasons = snapshot.data ?? const <Reason>[];
              final showCount = reasons.length < _visibleCount ? reasons.length : _visibleCount;
              return ListView(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  PrototypeCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        if (reasons.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '暂无事由，点击右上角添加',
                              style: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.medium,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        else
                          for (var i = 0; i < showCount; i++)
                            _ReasonRow(
                              reason: reasons[i],
                              borderBottom: i != showCount - 1,
                              onTap: () => AppNav.push(context, ReasonDetailPage(id: reasons[i].reasonId)),
                              onToggleEnabled: (v) => db.reasonsDao.setEnabled(id: reasons[i].reasonId, enabled: v),
                              onLongPress: () => _confirmDelete(context, db, reasons[i]),
                            ),
                        if (showCount < reasons.length)
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
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppDatabase db, Reason reason) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除事由'),
          content: Text('确认删除「${reason.name}」？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await db.reasonsDao.deleteById(reason.reasonId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.onTap,
    required this.onToggleEnabled,
    required this.onLongPress,
    this.borderBottom = true,
  });

  final Reason reason;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleEnabled;
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
            decoration: BoxDecoration(
              color: reason.enabled ? AppColors.indigo50 : AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: FaIcon(
              FontAwesomeIcons.tag,
              size: 14,
              color: reason.enabled ? AppColors.indigo700 : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason.name,
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: reason.enabled ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (reason.description == null || reason.description!.trim().isEmpty) ? '—' : reason.description!,
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
          Switch(
            value: reason.enabled,
            onChanged: onToggleEnabled,
          ),
        ],
      ),
    );
  }
}
