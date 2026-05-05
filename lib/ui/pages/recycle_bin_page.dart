import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../contact_avatar.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas();

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          PrototypeTopBar(
            title: '回收站',
            left: PrototypeIconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textPrimary,
              onPressed: () => AppNav.pop(context),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DeletedGiftRecordWithPerson>>(
              stream: db.giftRecordsDao.watchDeletedWithPerson(),
              builder: (context, recordSnapshot) {
                return StreamBuilder<List<Person>>(
                  stream: db.personsDao.watchDeleted(),
                  builder: (context, personSnapshot) {
                    final records =
                        recordSnapshot.data ??
                        const <DeletedGiftRecordWithPerson>[];
                    final persons = personSnapshot.data ?? const <Person>[];
                    return _RecycleBinContent(
                      db: db,
                      records: records,
                      persons: persons,
                      recordsLoading:
                          recordSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !recordSnapshot.hasData,
                      personsLoading:
                          personSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !personSnapshot.hasData,
                      recordsError: recordSnapshot.error,
                      personsError: personSnapshot.error,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecycleBinContent extends StatelessWidget {
  const _RecycleBinContent({
    required this.db,
    required this.records,
    required this.persons,
    required this.recordsLoading,
    required this.personsLoading,
    required this.recordsError,
    required this.personsError,
  });

  final AppDatabase db;
  final List<DeletedGiftRecordWithPerson> records;
  final List<Person> persons;
  final bool recordsLoading;
  final bool personsLoading;
  final Object? recordsError;
  final Object? personsError;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: _RecycleSummaryCard(
            recordCount: records.length,
            personCount: persons.length,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _RecycleTabBar(
            recordCount: records.length,
            personCount: persons.length,
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _TrashedRecordsTab(
                db: db,
                items: records,
                isLoading: recordsLoading,
                error: recordsError,
              ),
              _TrashedPersonsTab(
                db: db,
                items: persons,
                isLoading: personsLoading,
                error: personsError,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecycleSummaryCard extends StatelessWidget {
  const _RecycleSummaryCard({
    required this.recordCount,
    required this.personCount,
  });

  final int recordCount;
  final int personCount;

  @override
  Widget build(BuildContext context) {
    final totalCount = recordCount + personCount;
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(color: AppColors.borderSubtle),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.red100,
              borderRadius: AppRadii.brXl,
            ),
            alignment: Alignment.center,
            child: const FaIcon(
              FontAwesomeIcons.trashCan,
              size: 18,
              color: AppColors.red600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已删除项目',
                  style: AppTypography.base(
                    fontSize: 16,
                    fontWeight: AppTypography.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalCount == 0 ? '暂无待处理内容' : '可恢复，也可彻底删除',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SummaryMetric(value: '$totalCount', label: '合计'),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: AppTypography.base(
            fontSize: 24,
            fontWeight: AppTypography.bold,
            color: AppColors.brandPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.regular,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _RecycleTabBar extends StatelessWidget {
  const _RecycleTabBar({required this.recordCount, required this.personCount});

  final int recordCount;
  final int personCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSubtle,
        borderRadius: AppRadii.brXl,
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: AppRadii.brLg,
          boxShadow: AppShadows.sm,
        ),
        labelPadding: EdgeInsets.zero,
        labelColor: AppColors.brandPrimary,
        unselectedLabelColor: AppColors.textTertiary,
        tabs: [
          _RecycleTab(label: '收支记录', count: recordCount),
          _RecycleTab(label: '联系人', count: personCount),
        ],
      ),
    );
  }
}

class _RecycleTab extends StatelessWidget {
  const _RecycleTab({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.semibold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.indigo50,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$count',
                  maxLines: 1,
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.semibold,
                    color: AppColors.indigo700,
                    height: 1.0,
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

class _TrashedRecordsTab extends StatelessWidget {
  const _TrashedRecordsTab({
    required this.db,
    required this.items,
    required this.isLoading,
    required this.error,
  });

  final AppDatabase db;
  final List<DeletedGiftRecordWithPerson> items;
  final bool isLoading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return const _StateMessage(
        icon: FontAwesomeIcons.triangleExclamation,
        title: '加载失败',
        message: '暂时无法读取已删除记录',
      );
    }
    if (isLoading) {
      return const _LoadingState(label: '正在读取已删除记录');
    }
    if (items.isEmpty) {
      return const _StateMessage(
        icon: FontAwesomeIcons.boxOpen,
        title: '暂无收支记录',
        message: '删除后的收支记录会显示在这里',
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ListCard(
          children: [
            for (var i = 0; i < items.length; i++)
              _TrashedRecordRow(
                item: items[i],
                borderBottom: i != items.length - 1,
                onRestore: () async {
                  await db.giftRecordsDao.restoreById(items[i].record.recordId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('记录已恢复')));
                },
                onPurge: () async {
                  final ok = await _confirmPurge(context, title: '彻底删除记录');
                  if (!context.mounted || ok != true) return;
                  await db.giftRecordsDao.purgeById(items[i].record.recordId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('记录已彻底删除')));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _TrashedPersonsTab extends StatelessWidget {
  const _TrashedPersonsTab({
    required this.db,
    required this.items,
    required this.isLoading,
    required this.error,
  });

  final AppDatabase db;
  final List<Person> items;
  final bool isLoading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return const _StateMessage(
        icon: FontAwesomeIcons.triangleExclamation,
        title: '加载失败',
        message: '暂时无法读取已删除联系人',
      );
    }
    if (isLoading) {
      return const _LoadingState(label: '正在读取已删除联系人');
    }
    if (items.isEmpty) {
      return const _StateMessage(
        icon: FontAwesomeIcons.userGroup,
        title: '暂无联系人',
        message: '删除后的联系人会显示在这里',
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ListCard(
          children: [
            for (var i = 0; i < items.length; i++)
              _TrashedPersonRow(
                person: items[i],
                borderBottom: i != items.length - 1,
                onRestore: () async {
                  await db.personsDao.restoreById(items[i].personId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('联系人已恢复')));
                },
                onPurge: () async {
                  final ok = await _confirmPurge(context, title: '彻底删除联系人');
                  if (!context.mounted || ok != true) return;
                  await db.personsDao.purgeById(items[i].personId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('联系人已彻底删除')));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(children: children),
    );
  }
}

class _TrashedRecordRow extends StatelessWidget {
  const _TrashedRecordRow({
    required this.item,
    required this.borderBottom,
    required this.onRestore,
    required this.onPurge,
  });

  final DeletedGiftRecordWithPerson item;
  final bool borderBottom;
  final Future<void> Function() onRestore;
  final Future<void> Function() onPurge;

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final isIncome = record.direction == '收入';
    final amountText = _formatSignedAmount(isIncome, record.amountCent);
    final amountColor = isIncome ? AppColors.green600 : AppColors.red500;
    final personName = (item.personName ?? '').trim().isEmpty
        ? '已删除联系人'
        : item.personName!.trim();
    final eventName = (record.eventName ?? '').trim().isEmpty
        ? '未设置事由'
        : record.eventName!.trim();
    final paymentMethod = (record.paymentMethod ?? '').trim().isEmpty
        ? '未设置'
        : record.paymentMethod!.trim();
    final subtitle = paymentMethod == '未设置'
        ? eventName
        : '$eventName · $paymentMethod';

    return PrototypePressableRow(
      onTap: null,
      borderBottom: borderBottom,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContactAvatar(
                name: personName,
                avatarUrl: item.personAvatarUri,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            personName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.base(
                              fontSize: 16,
                              fontWeight: AppTypography.medium,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          amountText,
                          style: AppTypography.base(
                            fontSize: 16,
                            fontWeight: AppTypography.semibold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.base(
                        fontSize: 13,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _MetadataText(
                          icon: FontAwesomeIcons.clockRotateLeft,
                          text: _formatDeletedAt(record.deletedAt),
                        ),
                        _MetadataText(
                          icon: FontAwesomeIcons.calendarDay,
                          text: '发生 ${_formatShortDate(record.occurredAt)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RowActions(onRestore: onRestore, onPurge: onPurge),
        ],
      ),
    );
  }
}

class _TrashedPersonRow extends StatelessWidget {
  const _TrashedPersonRow({
    required this.person,
    required this.borderBottom,
    required this.onRestore,
    required this.onPurge,
  });

  final Person person;
  final bool borderBottom;
  final Future<void> Function() onRestore;
  final Future<void> Function() onPurge;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: null,
      borderBottom: borderBottom,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContactAvatar(
                name: person.name,
                avatarUrl: person.avatarUri,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: AppTypography.medium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      person.relationshipType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.base(
                        fontSize: 13,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MetadataText(
                      icon: FontAwesomeIcons.clockRotateLeft,
                      text: _formatDeletedAt(person.deletedAt),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RowActions(onRestore: onRestore, onPurge: onPurge),
        ],
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.onRestore, required this.onPurge});

  final Future<void> Function() onRestore;
  final Future<void> Function() onPurge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InlineActionButton(
            label: '恢复',
            icon: FontAwesomeIcons.rotateLeft,
            backgroundColor: AppColors.green600.withValues(alpha: 0.10),
            borderColor: AppColors.green600.withValues(alpha: 0.36),
            foregroundColor: AppColors.green600,
            onTap: onRestore,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InlineActionButton(
            label: '删除',
            icon: FontAwesomeIcons.trashCan,
            backgroundColor: AppColors.red600.withValues(alpha: 0.10),
            borderColor: AppColors.red600.withValues(alpha: 0.36),
            foregroundColor: AppColors.red600,
            onTap: onPurge,
          ),
        ),
      ],
    );
  }
}

class _InlineActionButton extends StatefulWidget {
  const _InlineActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final Future<void> Function() onTap;

  @override
  State<_InlineActionButton> createState() => _InlineActionButtonState();
}

class _InlineActionButtonState extends State<_InlineActionButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: PressableScale(
        onTap: _busy ? null : _handleTap,
        child: Container(
          height: AppTokens.tapTargetMin,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: widget.borderColor),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _busy
                ? SizedBox(
                    key: const ValueKey('busy'),
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.foregroundColor,
                    ),
                  )
                : Row(
                    key: const ValueKey('idle'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        widget.icon,
                        size: 13,
                        color: widget.foregroundColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.label,
                        style: AppTypography.base(
                          fontSize: 13,
                          fontWeight: AppTypography.medium,
                          color: widget.foregroundColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MetadataText extends StatelessWidget {
  const _MetadataText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.regular,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTypography.base(
              fontSize: 13,
              fontWeight: AppTypography.regular,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.appColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FaIcon(icon, size: 18, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.base(
                fontSize: 16,
                fontWeight: AppTypography.semibold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.base(
                fontSize: 13,
                fontWeight: AppTypography.regular,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> _confirmPurge(BuildContext context, {required String title}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: const Text('删除后无法恢复，确认继续？'),
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
}

String _formatSignedAmount(bool isIncome, int cent) {
  final sign = isIncome ? '+' : '-';
  final absCent = cent.abs();
  final yuan = (absCent / 100).toStringAsFixed(2);
  final parts = yuan.split('.');
  final intPart = parts[0];
  final fracPart = parts[1];
  final grouped = intPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '$sign$grouped.$fracPart';
}

String _formatDeletedAt(int? millisecondsSinceEpoch) {
  if (millisecondsSinceEpoch == null) return '删除时间未知';
  return '删除 ${_formatShortDate(millisecondsSinceEpoch)}';
}

String _formatShortDate(int millisecondsSinceEpoch) {
  final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}
