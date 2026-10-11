import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;

import '../../data/local/drift/app_database.dart';
import '../../media/media_storage_service.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_notification_tokens.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../edit_protection_guard.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import '../../utils/date_util.dart';
import 'person_detail_page.dart';
import 'record_add_page.dart';

import '../app_icons.dart';

import '../../platform/app_platform.dart';

import '../app_layout.dart';

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

class _Canvas extends StatefulWidget {
  const _Canvas({required this.recordId});

  final String recordId;

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  late Future<_RecordView?> _recordFuture;
  final MediaStorageService _mediaStorageService = MediaStorageService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recordFuture = _loadRecord();
  }

  @override
  void didUpdateWidget(covariant _Canvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recordId != widget.recordId) {
      _recordFuture = _loadRecord();
    }
  }

  void _reloadRecord() {
    if (!mounted) return;
    setState(() {
      _recordFuture = _loadRecord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RecordView?>(
      future: _recordFuture,
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

  Future<_RecordView?> _loadRecord() async {
    return _loadFromDb();
  }

  Future<_RecordView?> _loadFromDb() async {
    try {
      final db = AppDatabaseScope.of(context);
      final GiftRecord? record = await db.giftRecordsDao.findById(
        widget.recordId,
      );
      if (record == null) return null;
      final Person? person = await db.personsDao.findById(record.personId);
      final AccountBook? book = await db.accountBooksDao.findById(
        record.bookId,
      );
      return _RecordView(
        personId: record.personId,
        personName: person?.name ?? '未知联系人',
        isIncome: record.direction != '支出',
        amountCent: record.amountCent,
        eventName: record.eventName ?? '未设置事由',
        occurredAt: DateTime.fromMillisecondsSinceEpoch(record.occurredAt),
        note: record.note,
        bookName: book?.name ?? '未知账簿',
        attachments: List<String>.from(record.attachments ?? const <String>[]),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildLoaded(BuildContext context, _RecordView record) {
    return Column(
      children: [
        AppTopBar(
          title: '记录详情',
          left: AppIconButton(
            icon: const Icon(AppIcons.arrowLeft, size: 18),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: () => AppNav.pop(context),
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
                  const SizedBox(height: AppLayout.sectionGap),
                  _DetailInfoCard(record: record),
                  const SizedBox(height: AppLayout.sectionGap),
                  const _SectionTitle(title: '备注'),
                  const SizedBox(height: 12),
                  _NoteCard(note: record.note),
                  const SizedBox(height: AppLayout.sectionGap),
                  const _SectionTitle(title: '附件'),
                  const SizedBox(height: 12),
                  _AttachmentRow(
                    attachments: record.attachments,
                    onAdd: _addAttachments,
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomActions(
                  recordId: widget.recordId,
                  onEditFinished: _reloadRecord,
                ),
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
        AppTopBar(
          title: '记录详情',
          left: AppIconButton(
            icon: const Icon(AppIcons.arrowLeft, size: 18),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: () => AppNav.pop(context),
          ),
        ),
        const Expanded(child: Center(child: Text('记录不存在'))),
      ],
    );
  }

  Future<void> _addAttachments() async {
    final db = AppDatabaseScope.of(context);
    final record = await db.giftRecordsDao.findById(widget.recordId);
    if (!mounted) return;
    if (record == null) {
      AppNotifier.warning(context, '记录不存在');
      return;
    }
    final result = await AppPlatform.instance.pickFiles(
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final next = List<String>.from(record.attachments ?? const <String>[]);
    try {
      for (final f in result.files) {
        final path = f.path;
        if (path == null || path.trim().isEmpty) continue;
        final stored = await _mediaStorageService.saveAttachmentFromPath(path);
        next.add(stored);
      }
      await db.giftRecordsDao.updateOne(
        record.copyWith(attachments: Value(next.isEmpty ? null : next)),
      );
      if (!mounted) return;
      _reloadRecord();
      AppNotifier.success(context, '已添加附件');
    } catch (e) {
      if (!mounted) return;
      AppNotifier.error(context, '添加附件失败：$e');
    }
  }
}

class _RecordView {
  const _RecordView({
    required this.personId,
    required this.personName,
    required this.isIncome,
    required this.amountCent,
    required this.eventName,
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
    final IconData pillIcon = isIncome ? AppIcons.arrowDown : AppIcons.arrowUp;
    final String title = isIncome ? '收礼金额' : '送礼金额';
    final String pillLabel = isIncome ? '收入' : '支出';

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(pillIcon, size: 12, color: pillFg),
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
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: AppIcons.userRound,
            title: '联系人',
            value: record.personName,
            chevron: true,
            onTap: () => AppNav.push(
              context,
              PersonDetailPage(personId: record.personId),
            ),
          ),
          const AppDivider(color: AppColors.borderDivider),
          _InfoRow(icon: AppIcons.gift, title: '事由', value: record.eventName),
          const AppDivider(color: AppColors.borderDivider),
          _InfoRow(
            icon: AppIcons.calendarDays,
            title: '时间',
            value: _formatDateTime(record.occurredAt),
          ),
          const AppDivider(color: AppColors.borderDivider),
          _InfoRow(
            icon: AppIcons.bookOpen,
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
    return AppPressableRow(
      onTap: onTap,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppColors.textTertiary),
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
            const Icon(
              AppIcons.chevronRight,
              size: 10,
              color: AppColors.gray300,
            ),
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
    return AppCard(
      padding: AppLayout.pagePadding,
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
              color: context.appColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appColors.borderDefault),
            ),
            alignment: Alignment.center,
            child: const Icon(AppIcons.plus, size: 18),
          ),
        ),
        for (final path in attachments)
          Container(
            width: 96,
            height: 96,
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
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.recordId, required this.onEditFinished});

  final String recordId;
  final VoidCallback onEditFinished;

  Future<void> _editRecord(BuildContext context) async {
    final ok = await requireEditProtectionPassword(context, title: '编辑记录');
    if (!ok) return;
    if (!context.mounted) return;
    await AppNav.push(context, RecordAddPage(recordId: recordId));
    if (!context.mounted) return;
    onEditFinished();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final okAuth = await requireEditProtectionPassword(context, title: '删除记录');
    if (!okAuth) return;
    if (!context.mounted) return;
    final db = AppDatabaseScope.of(context);
    final ok = await AppDialog.confirm(
      context,
      title: '删除记录',
      message: '确认删除该记录？删除后将进入回收站。',
      confirmLabel: '删除',
      cancelLabel: '取消',
      tone: AppNotificationTone.error,
    );
    if (ok != true) return;
    await db.giftRecordsDao.deleteById(recordId);
    if (!context.mounted) return;
    AppNav.pop(context);
    AppNotifier.success(context, '记录已移入回收站');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppLayout.pagePadding,
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        border: Border(
          top: BorderSide(color: context.appColors.borderDivider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () => _confirmDelete(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceSubtle,
                  borderRadius: AppRadii.brXl,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      AppIcons.trash2,
                      size: 16,
                      color: AppColors.red500,
                    ),
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
              onTap: () => _editRecord(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: AppRadii.brXl,
                  boxShadow: AppShadows.brandSoft,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.pen, size: 16, color: AppColors.white),
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
  final grouped = intPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '¥$grouped.$fracPart';
}

String _formatDateTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${DateUtil.format(dt)} $hh:$mm';
}
