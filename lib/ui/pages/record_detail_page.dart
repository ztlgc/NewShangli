import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../../data/local/entity_remarks_store.dart';
import '../../media/media_storage_service.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../edit_protection_guard.dart';
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

  Widget _buildLoaded(BuildContext context, _RecordView record) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            border: Border(
              bottom: BorderSide(
                color: context.appColors.surfaceSubtle,
                width: 1,
              ),
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
                  const _SectionTitle(title: '追加备注'),
                  const SizedBox(height: 12),
                  _EntityRemarksCard(
                    entityType: EntityRemarkType.giftRecord,
                    entityId: widget.recordId,
                  ),
                  const SizedBox(height: 24),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            border: Border(
              bottom: BorderSide(
                color: context.appColors.surfaceSubtle,
                width: 1,
              ),
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
              const Expanded(child: Center(child: Text('记录详情'))),
              const SizedBox(width: 36, height: 36),
            ],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('记录不存在')));
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已添加附件')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('添加附件失败：$e')));
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
    final IconData pillIcon = isIncome
        ? FontAwesomeIcons.arrowDown
        : FontAwesomeIcons.arrowUp;
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
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
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
            onTap: () => AppNav.push(
              context,
              PersonDetailPage(personId: record.personId),
              requiresLogin: true,
            ),
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
            decoration: BoxDecoration(
              color: context.appColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
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
            const FaIcon(
              FontAwesomeIcons.chevronRight,
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
    final db = AppDatabaseScope.of(context);
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
    final db = AppDatabaseScope.of(context);
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
                    color: context.appColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: context.appColors.surfaceDisabled,
                    ),
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
        color: context.appColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.borderSubtle),
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
            child: const FaIcon(FontAwesomeIcons.plus, size: 18),
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.recordId, required this.onEditFinished});

  final String recordId;
  final VoidCallback onEditFinished;

  Future<void> _editRecord(BuildContext context) async {
    final ok = await requireEditProtectionPassword(context, title: '编辑记录');
    if (!ok) return;
    await AppNav.push(
      context,
      RecordAddPage(recordId: recordId),
      requiresLogin: true,
    );
    if (!context.mounted) return;
    onEditFinished();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final okAuth = await requireEditProtectionPassword(context, title: '删除记录');
    if (!okAuth) return;
    final db = AppDatabaseScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Align(
          alignment: Alignment.center,
          child: AlertDialog(
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
          ),
        );
      },
    );
    if (ok != true) return;
    await db.giftRecordsDao.deleteById(recordId);
    if (!context.mounted) return;
    AppNav.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('记录已移入回收站')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    const FaIcon(
                      FontAwesomeIcons.trashCan,
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
                    const FaIcon(
                      FontAwesomeIcons.pen,
                      size: 16,
                      color: AppColors.white,
                    ),
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
