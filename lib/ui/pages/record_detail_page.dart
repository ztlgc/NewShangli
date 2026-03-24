import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../../utils/date_util.dart';
import 'person_detail_page.dart';
import 'record_add_page.dart';

/// 页面：收支记录 - 收支详情
/// 对照原型：prototype/index.html -> "收支详情"
class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(recordId: recordId),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RecordView?>(
      future: _loadRecord(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final view = snapshot.data;
        if (view == null) {
          return _buildNotFound(context);
        }
        return _buildLoaded(context, view);
      },
    );
  }

  Future<_RecordView?> _loadRecord(BuildContext context) async {
    final fromDb = await _loadFromDb(context);
    if (fromDb != null) return fromDb;
    return _loadFromAppData(context);
  }

  Future<_RecordView?> _loadFromDb(BuildContext context) async {
    try {
      final db = AppDatabaseScope.maybeOf(context);
      if (db == null) return null;
      final GiftRecord? record = await db.giftRecordsDao.findById(recordId);
      if (record == null) return null;
      final Person? person = await db.personsDao.findById(record.personId);
      final AccountBook? book = await db.accountBooksDao.findById(record.bookId);
      return _RecordView(
        personId: record.personId,
        personName: person?.name ?? '未知联系人',
        isIncome: record.direction != '支出',
        amountCent: record.amountCent,
        eventName: record.eventName ?? '未设置事由',
        paymentMethod: record.paymentMethod ?? '未设置',
        occurredAt: DateTime.fromMillisecondsSinceEpoch(record.occurredAt),
        note: record.note,
        bookName: book?.name ?? '未知账簿',
        attachments: List<String>.from(record.attachments ?? const <String>[]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<_RecordView?> _loadFromAppData(BuildContext context) async {
    try {
      final element = context.getElementForInheritedWidgetOfExactType<AppDataScope>();
      final scope = element?.widget;
      if (scope is! AppDataScope) return null;
      final data = scope.notifier!;
      final record = data.findRecord(recordId);
      if (record == null) return null;
      final person = data.findPerson(record.personId);
      final bookName = data.resolveBookName(record.bookId);
      return _RecordView(
        personId: record.personId,
        personName: person?.name ?? record.personName,
        isIncome: record.direction == RecordDirection.income,
        amountCent: record.amountCent,
        eventName: record.eventName,
        paymentMethod: record.paymentMethod,
        occurredAt: record.occurredAt,
        note: record.note,
        bookName: bookName,
        attachments: const <String>[],
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildLoaded(BuildContext context, _RecordView record) {
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
                icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                onPressed: () => AppNav.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '记录详情',
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24 + 83),
                children: [
                  _AmountSummaryCard(
                    isIncome: record.isIncome,
                    amountText: _formatCurrency(record.amountCent),
                  ),
                  const SizedBox(height: 24),
                  _DetailInfoCard(record: record),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: '备注'),
                  const SizedBox(height: 12),
                  _NoteCard(note: record.note),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: '附件'),
                  const SizedBox(height: 12),
                  _AttachmentRow(attachments: record.attachments),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomActions(recordId: recordId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound(BuildContext context) {
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
                icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                onPressed: () => AppNav.pop(context),
              ),
              const Expanded(child: Center(child: Text('记录详情'))),
              const SizedBox(width: 36, height: 36),
            ],
          ),
        ),
        const Expanded(child: Center(child: Text('记录不存在'))),
      ],
    );
  }
}

class _RecordView {
  const _RecordView({
    required this.personId,
    required this.personName,
    required this.isIncome,
    required this.amountCent,
    required this.eventName,
    required this.paymentMethod,
    required this.occurredAt,
    required this.note,
    required this.bookName,
    required this.attachments,
  });

  final String personId;
  final String personName;
  final bool isIncome;
  final int amountCent;
  final String eventName;
  final String paymentMethod;
  final DateTime occurredAt;
  final String? note;
  final String bookName;
  final List<String> attachments;
}

class _AmountSummaryCard extends StatelessWidget {
  const _AmountSummaryCard({required this.isIncome, required this.amountText});

  final bool isIncome;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final Color accent = isIncome ? AppColors.green500 : AppColors.red500;
    final Color pillBg = isIncome ? AppColors.green50 : AppColors.red100;
    final Color pillFg = isIncome ? AppColors.green600 : AppColors.red600;
    final IconData pillIcon = isIncome ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp;
    final String title = isIncome ? '收礼金额' : '送礼金额';
    final String pillLabel = isIncome ? '收入' : '支出';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br3xl,
        boxShadow: AppShadows.sm,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.br3xl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: AppRadii.r3xl,
                  topRight: AppRadii.r3xl,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      amountText,
                      textAlign: TextAlign.center,
                      style: AppTypography.base(
                        fontSize: 36,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(pillIcon, size: 12, color: pillFg),
                          const SizedBox(width: 6),
                          Text(
                            pillLabel,
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.medium,
                              color: pillFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({required this.record});

  final _RecordView record;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: FontAwesomeIcons.user,
            title: '关系人',
            value: record.personName,
            chevron: true,
            onTap: () => AppNav.push(context, PersonDetailPage(personId: record.personId), requiresLogin: true),
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _InfoRow(
            icon: FontAwesomeIcons.gift,
            title: '事由',
            value: record.eventName,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _InfoRow(
            icon: FontAwesomeIcons.calendarDays,
            title: '时间',
            value: _formatDateTime(record.occurredAt),
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _InfoRow(
            icon: FontAwesomeIcons.wallet,
            title: '支付方式',
            value: record.paymentMethod,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _InfoRow(
            icon: FontAwesomeIcons.book,
            title: '所属礼簿',
            value: record.bookName,
            borderBottom: false,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.chevron = false,
    this.borderBottom = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool chevron;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: onTap,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.gray100, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 16, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (chevron)
            const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.base(
          fontSize: 12,
          fontWeight: AppTypography.bold,
          color: AppColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Text(
        (note == null || note!.trim().isEmpty) ? '暂无备注' : note!,
        style: AppTypography.base(
          fontSize: 14,
          fontWeight: AppTypography.regular,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachments});

  final List<String> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const PrototypeCard(
        padding: EdgeInsets.all(16),
        child: Text('暂无附件'),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final path in attachments)
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) {
                return Container(
                  color: AppColors.gray100,
                  alignment: Alignment.center,
                  child: const FaIcon(FontAwesomeIcons.triangleExclamation, size: 14),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.recordId});

  final String recordId;

  Future<void> _confirmDelete(BuildContext context) async {
    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前页面无法执行删除')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除记录'),
          content: const Text('确认删除该记录？删除后将进入回收站。'),
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
    if (ok != true) return;
    await db.giftRecordsDao.deleteById(recordId);
    if (!context.mounted) return;
    AppNav.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记录已移入回收站')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () => _confirmDelete(context),
              child: Container(
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: AppRadii.brXl,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.trashCan, size: 16, color: AppColors.red500),
                    const SizedBox(width: 8),
                    Text(
                      '删除',
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.medium,
                        color: AppColors.red500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PressableScale(
              onTap: () => AppNav.push(context, RecordAddPage(recordId: recordId), requiresLogin: true),
              child: Container(
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: AppRadii.brXl,
                  boxShadow: AppShadows.brandSoft,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.pen, size: 16, color: AppColors.white),
                    const SizedBox(width: 8),
                    Text(
                      '编辑',
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.medium,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int cent) {
  final absCent = cent.abs();
  final yuan = (absCent / 100).toStringAsFixed(2);
  final parts = yuan.split('.');
  final intPart = parts[0];
  final fracPart = parts[1];
  final grouped = intPart.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '¥$grouped.$fracPart';
}

String _formatDateTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${DateUtil.format(dt)} $hh:$mm';
}

