import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../../utils/date_util.dart';

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
            ),
            child: Row(
              children: [
                PrototypeIconButton(
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textPrimary,
                  onPressed: () => AppNav.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text('回收站', style: AppTypography.h2().copyWith(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 36, height: 36),
              ],
            ),
          ),
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TabBar(
              labelColor: AppColors.indigo700,
              unselectedLabelColor: AppColors.textTertiary,
              labelStyle: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.semibold,
                color: AppColors.indigo700,
              ),
              unselectedLabelStyle: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.regular,
                color: AppColors.textTertiary,
              ),
              indicatorColor: AppColors.indigo600,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '收支记录'),
                Tab(text: '联系人'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TrashedRecordsList(db: db),
                _TrashedPersonsList(db: db),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashedRecordsList extends StatelessWidget {
  const _TrashedRecordsList({required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DeletedGiftRecordWithPerson>>(
      stream: db.giftRecordsDao.watchDeletedWithPerson(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <DeletedGiftRecordWithPerson>[];
        if (items.isEmpty) {
          return const Center(child: Text('回收站暂无收支记录'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + AppTokens.tabBarHeight),
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadii.br2xl,
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _TrashedRecordRow(
                      item: items[i],
                      borderBottom: i != items.length - 1,
                      onRestore: () async {
                        await db.giftRecordsDao.restoreById(items[i].record.recordId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已恢复')));
                      },
                      onPurge: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await _confirmPurge(context);
                        if (ok != true) return;
                        await db.giftRecordsDao.purgeById(items[i].record.recordId);
                        messenger.showSnackBar(const SnackBar(content: Text('已彻底删除')));
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrashedPersonsList extends StatelessWidget {
  const _TrashedPersonsList({required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Person>>(
      stream: db.personsDao.watchDeleted(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Person>[];
        if (items.isEmpty) {
          return const Center(child: Text('回收站暂无联系人'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + AppTokens.tabBarHeight),
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadii.br2xl,
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _TrashedPersonRow(
                      person: items[i],
                      borderBottom: i != items.length - 1,
                      onRestore: () async {
                        await db.personsDao.restoreById(items[i].personId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已恢复')));
                      },
                      onPurge: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await _confirmPurge(context);
                        if (ok != true) return;
                        await db.personsDao.purgeById(items[i].personId);
                        messenger.showSnackBar(const SnackBar(content: Text('已彻底删除')));
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
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
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final isIncome = record.direction != '支出';
    final amountText = _formatSignedAmount(isIncome, record.amountCent);
    final amountColor = isIncome ? AppColors.green600 : AppColors.red500;
    final personName = (item.personName ?? '').trim().isEmpty ? '已删除联系人' : item.personName!;
    final eventName = (record.eventName ?? '').trim().isEmpty ? '未设置事由' : record.eventName!.trim();
    final paymentMethod = (record.paymentMethod ?? '').trim().isEmpty ? '未设置' : record.paymentMethod!.trim();
    final subtitle = (paymentMethod == '未设置' || paymentMethod.isEmpty) ? eventName : '$eventName - $paymentMethod';
    final dateText = DateUtil.format(DateTime.fromMillisecondsSinceEpoch(record.occurredAt));

    return PrototypePressableRow(
      onTap: null,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        personName,
                        style: AppTypography.base(
                          fontSize: 16,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      dateText,
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PrototypeIconButton(
            icon: const FaIcon(FontAwesomeIcons.rotateLeft, size: 16),
            backgroundColor: AppColors.green50,
            foregroundColor: AppColors.green600,
            onPressed: onRestore,
          ),
          const SizedBox(width: 8),
          PrototypeIconButton(
            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
            backgroundColor: AppColors.red100,
            foregroundColor: AppColors.red600,
            onPressed: onPurge,
          ),
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
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: null,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: AppTypography.base(
                    fontSize: 16,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  person.relationshipType,
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PrototypeIconButton(
            icon: const FaIcon(FontAwesomeIcons.rotateLeft, size: 16),
            backgroundColor: AppColors.green50,
            foregroundColor: AppColors.green600,
            onPressed: onRestore,
          ),
          const SizedBox(width: 8),
          PrototypeIconButton(
            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
            backgroundColor: AppColors.red100,
            foregroundColor: AppColors.red600,
            onPressed: onPurge,
          ),
        ],
      ),
    );
  }
}

Future<bool?> _confirmPurge(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('彻底删除'),
        content: const Text('确认彻底删除？该操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
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
  final grouped = intPart.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$sign$grouped.$fracPart';
}
