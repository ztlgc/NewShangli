import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../data/local/drift/app_database.dart';
import '../../media/media_storage_service.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_notification_tokens.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import '../../utils/date_util.dart';
import '../widgets/record_list_row.dart';
import 'account_book_data_import_page.dart';
import 'record_detail_page.dart';

import '../app_icons.dart';

import '../../platform/app_platform.dart';

import '../app_layout.dart';

class AccountBookDetailPage extends StatelessWidget {
  const AccountBookDetailPage({super.key, required this.bookId});

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

  Future<void> _addAttachments(BuildContext context, AccountBook book) async {
    final db = AppDatabaseScope.of(context);
    final result = await AppPlatform.instance.pickFiles(
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: false,
    );
    if (!context.mounted) return;
    if (result == null || result.files.isEmpty) return;

    final next = List<String>.from(book.attachments ?? const <String>[]);
    final mediaStorageService = MediaStorageService();
    try {
      for (final f in result.files) {
        final path = f.path;
        if (path == null || path.trim().isEmpty) continue;
        final stored = await mediaStorageService.saveAttachmentFromPath(path);
        next.add(stored);
      }
      await db.accountBooksDao.updateOne(
        book.copyWith(attachments: Value(next.isEmpty ? null : next)),
      );
      if (!context.mounted) return;
      AppNotifier.success(context, '已添加附件');
    } catch (e) {
      if (!context.mounted) return;
      AppNotifier.error(context, '添加附件失败：$e');
    }
  }

  Future<void> _deleteAttachment(
    BuildContext context,
    AccountBook book,
    String path,
  ) async {
    final ok = await AppDialog.confirm(
      context,
      title: '删除附件',
      message: '确认删除该附件？',
      confirmLabel: '删除',
      cancelLabel: '取消',
      tone: AppNotificationTone.error,
    );
    if (ok != true) return;
    if (!context.mounted) return;

    final db = AppDatabaseScope.of(context);
    final next = List<String>.from(book.attachments ?? const <String>[]);
    if (!next.remove(path)) return;

    try {
      await db.accountBooksDao.updateOne(
        book.copyWith(attachments: Value(next.isEmpty ? null : next)),
      );
      await MediaStorageService().deleteStoredPath(path);
      if (!context.mounted) return;
      AppNotifier.success(context, '附件已删除');
    } catch (e) {
      if (!context.mounted) return;
      AppNotifier.error(context, '删除附件失败：$e');
    }
  }

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
            AppTopBar(
              title: book.name,
              left: AppIconButton(
                icon: const Icon(AppIcons.arrowLeft, size: 18),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                onPressed: () => AppNav.pop(context),
                semanticLabel: '返回上一页',
              ),
              right: AppIconButton(
                icon: const Icon(AppIcons.fileInput, size: 16),
                backgroundColor: AppColors.indigo50,
                foregroundColor: AppColors.indigo700,
                onPressed: () => AppNav.push(
                  context,
                  AccountBookDataImportPage(
                    bookId: bookId,
                    bookName: book.name,
                  ),
                ),
                semanticLabel: '导入账簿数据',
              ),
            ),
            Expanded(
              child: StreamBuilder<List<GiftRecordWithPerson>>(
                stream: recordsStream,
                builder: (context, rowsSnapshot) {
                  final rows =
                      rowsSnapshot.data ?? const <GiftRecordWithPerson>[];
                  var income = 0;
                  for (final row in rows) {
                    if (row.record.direction == '收入') {
                      income += row.record.amountCent;
                    }
                  }
                  final count = rows.length;

                  return ListView(
                    padding: AppLayout.tabContentPadding,
                    children: [
                      _OverviewCard(
                        incomeCent: income,
                        recordCount: count,
                        bookTime: book.bookTime,
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          '附件',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      _AttachmentRow(
                        attachments: book.attachments ?? const <String>[],
                        onAdd: () => _addAttachments(context, book),
                        onDelete: (path) =>
                            _deleteAttachment(context, book, path),
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
    final colors = context.appColors;
    return Container(
      padding: AppLayout.pagePadding,
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
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
              Container(width: 1, height: 44, color: colors.borderDivider),
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
          Container(height: 1, color: colors.borderDivider),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Text(
              '账簿时间：${DateUtil.format(DateTime.fromMillisecondsSinceEpoch(bookTime))}',
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.regular,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.title,
    required this.value,
    required this.color,
  });

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
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
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
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            borderRadius: AppRadii.br2xl,
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                RecordListRow(
                  avatarUrl: rows[i].person.avatarUri,
                  name: rows[i].person.name,
                  direction: rows[i].record.direction == '收入'
                      ? RecordDirection.income
                      : RecordDirection.expense,
                  amountCent: rows[i].record.amountCent,
                  subtitle: rows[i].record.eventName ?? '未设置事由',
                  occurredAt: DateTime.fromMillisecondsSinceEpoch(
                    rows[i].record.occurredAt,
                  ),
                  borderBottom: i != rows.length - 1,
                  onTap: () => AppNav.push(
                    context,
                    RecordDetailPage(recordId: rows[i].record.recordId),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachments,
    required this.onAdd,
    required this.onDelete,
  });

  final List<String> attachments;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        Semantics(
          button: true,
          label: '添加附件',
          // 这里是纯图标入口，显式语义标签可以让读屏明确这是附件主入口。
          child: ExcludeSemantics(
            child: PressableScale(
              onTap: onAdd,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appColors.borderDefault),
                ),
                alignment: Alignment.center,
                child: const Icon(AppIcons.plus, size: 18),
              ),
            ),
          ),
        ),
        for (final path in attachments)
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceDisabled,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: context.appColors.surfaceSubtle,
                          alignment: Alignment.center,
                          child: const Icon(AppIcons.triangleAlert, size: 14),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Semantics(
                    button: true,
                    label: '删除附件',
                    hint: path,
                    child: ExcludeSemantics(
                      child: PressableScale(
                        onTap: () => onDelete(path),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.scrimBlack30,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            AppIcons.x,
                            size: 13,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
