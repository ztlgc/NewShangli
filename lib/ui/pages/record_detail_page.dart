import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_data.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
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
    final data = AppDataScope.of(context);
    final record = data.findRecord(recordId);
    if (record == null) {
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
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('仅原型展示：更多操作未实现')),
                  );
                },
              ),
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
                    isIncome: record.direction == RecordDirection.income,
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
                  const _AttachmentRow(),
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

  final RecordData record;

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    final bookName = data.resolveBookName(record.bookId);
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
            value: bookName,
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
  const _AttachmentRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: const PrototypeNetworkImage(
            url: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=150&h=150&fit=crop',
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.recordId});

  final String recordId;

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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('仅原型展示：删除未实现')),
                );
              },
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
  final y = dt.year.toString();
  final m = dt.month.toString();
  final d = dt.day.toString();
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y年$m月$d日 $hh:$mm';
}

