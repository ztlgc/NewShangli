import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../../data/local/entity_remarks_store.dart';
import '../../media/media_storage_service.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../../utils/date_util.dart';
import '../widgets/record_list_row.dart';
import 'account_book_data_import_page.dart';
import 'record_detail_page.dart';

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
    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('数据库未初始化')));
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已添加附件')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('添加附件失败：$e')));
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.gray100, width: 1),
                ),
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
                      AccountBookDataImportPage(
                        bookId: bookId,
                        bookName: book.name,
                      ),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                          '追加备注',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      _EntityRemarksCard(
                        entityType: EntityRemarkType.accountBook,
                        entityId: book.bookId,
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
                  direction: rows[i].record.direction == '收入'
                      ? RecordDirection.income
                      : RecordDirection.expense,
                  amountCent: rows[i].record.amountCent,
                  subtitle:
                      (rows[i].record.paymentMethod == null ||
                          rows[i].record.paymentMethod!.isEmpty ||
                          rows[i].record.paymentMethod == '未设置')
                      ? (rows[i].record.eventName ?? '未设置事由')
                      : '${rows[i].record.eventName ?? '未设置事由'} - ${rows[i].record.paymentMethod}',
                  occurredAt: DateTime.fromMillisecondsSinceEpoch(
                    rows[i].record.occurredAt,
                  ),
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

class _EntityRemarksCard extends StatefulWidget {
  const _EntityRemarksCard({required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;

  @override
  State<_EntityRemarksCard> createState() => _EntityRemarksCardState();
}

class _EntityRemarksCardState extends State<_EntityRemarksCard> {
  late Future<List<EntityRemark>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  Future<List<EntityRemark>> _load() async {
    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) return const <EntityRemark>[];
    return EntityRemarksStore(
      db,
    ).listByEntity(entityType: widget.entityType, entityId: widget.entityId);
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  Future<void> _addRemark(BuildContext context, AppDatabase db) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增备注'),
          content: TextField(
            controller: controller,
            maxLines: 6,
            minLines: 3,
            decoration: const InputDecoration(hintText: '请输入备注内容'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true) return;
    if (text.isEmpty) return;
    await EntityRemarksStore(db).addRemark(
      entityType: widget.entityType,
      entityId: widget.entityId,
      content: text,
    );
    if (!context.mounted) return;
    _reload();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('备注已添加')));
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) {
      return const PrototypeCard(
        padding: EdgeInsets.all(16),
        child: Text('数据库未初始化'),
      );
    }
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '备注列表',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              PressableScale(
                onTap: () => _addRemark(context, db),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Text(
                    '新增',
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<EntityRemark>>(
            future: _future,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <EntityRemark>[];
              if (rows.isEmpty) {
                return Text(
                  '暂无追加备注',
                  style: AppTypography.base(
                    fontSize: 13,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textMuted,
                  ),
                );
              }
              return Column(
                children: [
                  for (final r in rows) ...[
                    _RemarkRow(content: r.content, createdAt: r.createdAt),
                    if (r != rows.last) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachments, required this.onAdd});

  final List<String> attachments;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        PressableScale(
          onTap: onAdd,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            alignment: Alignment.center,
            child: const FaIcon(FontAwesomeIcons.plus, size: 18),
          ),
        ),
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
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.gray100,
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 14,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RemarkRow extends StatelessWidget {
  const _RemarkRow({required this.content, required this.createdAt});

  final String content;
  final int createdAt;

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final label = '${DateUtil.format(time)} $hh:$mm';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.base(
              fontSize: 11,
              fontWeight: AppTypography.regular,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: AppTypography.base(
              fontSize: 13,
              fontWeight: AppTypography.regular,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
