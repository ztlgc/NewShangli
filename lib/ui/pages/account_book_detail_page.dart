import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../../utils/date_util.dart';
import '../widgets/record_list_row.dart';
import 'account_book_data_import_page.dart';
import 'record_detail_page.dart';

class AccountBookDetailPage extends StatelessWidget {
  const AccountBookDetailPage({
    super.key,
    required this.bookId,
  });

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(bookId: bookId),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return StreamBuilder<AccountBook>(
      stream: db.accountBooksDao.watchBook(bookId),
      builder: (context, bookSnapshot) {
        if (!bookSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final book = bookSnapshot.data!;
        final isDefaultBook = book.isDefault == 1;
        final recordsStream = isDefaultBook
            ? db.giftRecordsDao.watchAllWithPersonInDefaultScope(book.bookId)
            : db.giftRecordsDao.watchAllWithPersonInBook(bookId);

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
                        book.name,
                        style: AppTypography.base(
                          fontSize: 18,
                          fontWeight: AppTypography.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  PrototypeIconButton(
                    icon: const FaIcon(FontAwesomeIcons.fileImport, size: 16),
                    backgroundColor: AppColors.indigo50,
                    foregroundColor: AppColors.indigo700,
                    onPressed: () => AppNav.push(
                      context,
                      AccountBookDataImportPage(bookId: bookId, bookName: book.name),
                      requiresLogin: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<GiftRecordWithPerson>>(
                stream: recordsStream,
                builder: (context, rowsSnapshot) {
                  final rows = rowsSnapshot.data ?? const <GiftRecordWithPerson>[];
                  var income = 0;
                  for (final row in rows) {
                    if (row.record.direction == '收入') {
                      income += row.record.amountCent;
                    }
                  }
                  final count = rows.length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      _OverviewCard(
                        incomeCent: income,
                        recordCount: count,
                        bookTime: book.bookTime,
                      ),
                      const SizedBox(height: 16),
                      _RecordsSection(rows: rows),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.incomeCent,
    required this.recordCount,
    required this.bookTime,
  });

  final int incomeCent;
  final int recordCount;
  final int bookTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  title: '总收入',
                  value: (incomeCent / 100).toStringAsFixed(2),
                  color: AppColors.red600,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.gray100),
              Expanded(
                child: _MetricItem(
                  title: '记录数量',
                  value: '$recordCount 笔',
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.gray100),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '账簿时间：${DateUtil.format(DateTime.fromMillisecondsSinceEpoch(bookTime))}',
                style: AppTypography.base(
                  fontSize: 12,
                  fontWeight: AppTypography.regular,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.regular,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.base(
            fontSize: 18,
            fontWeight: AppTypography.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RecordsSection extends StatelessWidget {
  const _RecordsSection({required this.rows});

  final List<GiftRecordWithPerson> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadii.br2xl,
          boxShadow: AppShadows.sm,
        ),
        alignment: Alignment.center,
        child: Text(
          '暂无记录',
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.regular,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '收礼记录',
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.br2xl,
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                RecordListRow(
                  avatarUrl: rows[i].person.avatarUri,
                  name: rows[i].person.name,
                  direction: rows[i].record.direction == '收入' ? RecordDirection.income : RecordDirection.expense,
                  amountCent: rows[i].record.amountCent,
                  subtitle: (rows[i].record.paymentMethod == null || rows[i].record.paymentMethod!.isEmpty || rows[i].record.paymentMethod == '未设置')
                      ? (rows[i].record.eventName ?? '未设置事由')
                      : '${rows[i].record.eventName ?? '未设置事由'} - ${rows[i].record.paymentMethod}',
                  occurredAt: DateTime.fromMillisecondsSinceEpoch(rows[i].record.occurredAt),
                  borderBottom: i != rows.length - 1,
                  onTap: () => AppNav.push(
                    context,
                    RecordDetailPage(recordId: rows[i].record.recordId),
                    requiresLogin: true,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
