import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/data_import_service.dart';
import '../../import/data_import_template_service.dart';
import '../../import/default_book_service.dart';
import '../../import/import_file_reader.dart';
import '../app_bottom_sheet.dart';
import '../app_database_scope.dart';
import '../app_notifier.dart';
import '../app_dialog.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../ui_kit.dart';

import '../app_icons.dart';

import '../../platform/app_platform.dart';

import '../app_layout.dart';

class DataImportPage extends StatelessWidget {
  const DataImportPage({super.key, this.initialBookId});

  final String? initialBookId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(initialBookId: initialBookId),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas({this.initialBookId});

  final String? initialBookId;

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  late AppDatabase _db;
  late DataImportService _importService;
  final DataImportTemplateService _templateService =
      DataImportTemplateService();
  final DefaultBookService _defaultBookService = DefaultBookService();
  late Future<String> _bookIdFuture;
  bool _dbInitialized = false;

  AppPickedFile? _picked;
  AppPickedFile? _mediaZip;
  ImportPreview? _preview;
  bool _loadingPreview = false;
  bool _startingImport = false;

  String? _jobId;
  DataImportRunHandle? _runHandle;
  DataImportProgress? _progress;
  String? _logTail;
  StreamSubscription<DataImportProgress>? _progressSub;

  final Map<String, String?> _fieldMapping = <String, String?>{};
  final List<String> _errors = <String>[];

  static const List<String> _recordFields = <String>[
    '数据类型',
    '记录ID',
    '收支方向',
    '金额(元)',
    '事由',
    '所属账簿名称',
    '关系人ID',
    '关系人姓名',
    '关系人关系',
    '手机号',
    '发生时间',
    '备注',
    '头像文件名',
    '附件1名称',
    '附件2名称',
    '附件3名称',
    '附件4名称',
    '附件5名称',
  ];

  @override
  void dispose() {
    _runHandle?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scopedDb = AppDatabaseScope.of(context);
    if (_dbInitialized && identical(_db, scopedDb)) return;
    if (_dbInitialized) {
      unawaited(_runHandle?.cancel());
      unawaited(_progressSub?.cancel());
    }
    _db = scopedDb;
    _importService = DataImportService(db: _db);
    _bookIdFuture = widget.initialBookId == null
        ? _defaultBookService.ensureDefaultBookId(_db)
        : Future<String>.value(widget.initialBookId!);
    _dbInitialized = true;
  }

  Future<void> _pickFile() async {
    final result = await AppPlatform.instance.pickFiles(
      allowedExtensions: const <String>['xlsx', 'csv'],
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.path == null) {
      AppNotifier.warning(context, '无法读取文件路径，请重试');
      return;
    }

    setState(() {
      _picked = f;
      _preview = null;
      _loadingPreview = true;
      _errors.clear();
      _fieldMapping.clear();
      _mediaZip = null;
    });

    try {
      final p = await ImportFileReader.preview(
        filePath: f.path!,
        maxPreviewRows: 20,
      );
      if (!mounted) return;
      setState(() {
        _preview = p;
        _loadingPreview = false;
      });
      _initDefaultMapping();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPreview = false;
        _errors.add(e.toString());
      });
    }
  }

  Future<void> _pickMediaZip() async {
    final result = await AppPlatform.instance.pickFiles(
      allowedExtensions: const <String>['zip'],
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _mediaZip = result.files.first;
    });
  }

  void _initDefaultMapping() {
    final headers = _preview?.headers ?? const <String>[];
    for (final field in _recordFields) {
      if (headers.contains(field)) {
        _fieldMapping[field] = field;
      } else {
        _fieldMapping[field] = null;
      }
    }
    setState(() {});
  }

  Future<void> _downloadTemplate() async {
    final choice = await AppBottomSheet.showPicker<DataImportTemplateFormat>(
      context,
      title: '下载导入模板',
      options: const [
        AppSheetOption(
          label: 'Excel 模板 (.xlsx)',
          value: DataImportTemplateFormat.xlsx,
          icon: AppIcons.fileSpreadsheet,
        ),
        AppSheetOption(
          label: 'CSV 模板 (.csv)',
          value: DataImportTemplateFormat.csv,
          icon: AppIcons.fileSpreadsheet,
        ),
      ],
    );
    if (!mounted || choice == null) return;

    try {
      final file = await _templateService.generateTemplate(format: choice);
      if (!mounted) return;
      await AppPlatform.instance.shareFile(file.path, text: '尚礼导入模板');
    } catch (e) {
      if (!mounted) return;
      AppNotifier.error(context, '模板生成失败：$e');
    }
  }

  Future<void> _showHistorySheet() async {
    final bookId = await _bookIdFuture;
    if (!mounted) return;
    await AppBottomSheet.show<void>(
      context,
      title: '导入历史',
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: StreamBuilder<List<DataImportJob>>(
          stream: _db.dataImportJobsDao.watchRecentInBook(bookId, limit: 50),
          builder: (context, snapshot) {
            final list = snapshot.data ?? const <DataImportJob>[];
            if (list.isEmpty) {
              return const Center(child: Text('暂无导入历史'));
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final job = list[i];
                return FTile(
                  title: Text(job.fileName),
                  subtitle: Text(
                    '状态：${job.status}  成功：${job.successRows}  跳过：${job.skippedRows}  失败：${job.failedRows}',
                  ),
                  suffix:
                      (job.status == DataImportStatus.paused.name ||
                          job.status == DataImportStatus.failed.name)
                      ? FButton(
                          variant: .ghost,
                          size: .sm,
                          onPress: () async {
                            Navigator.of(context).pop();
                            await _startJob(job.jobId);
                          },
                          child: const Text('继续'),
                        )
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _startNewJob() async {
    if (_isImportBusy) return;
    if (_picked?.path == null) return;
    final bookId = await _bookIdFuture;
    if (!mounted) return;
    setState(() => _startingImport = true);
    try {
      final jobId = await _importService.createJob(
        bookId: bookId,
        sourceFilePath: _picked!.path!,
        kind: DataImportKind.recordsAndPersons,
        fieldMapping: _fieldMapping,
        mediaZipPath: _mediaZip?.path,
      );
      await _startJob(jobId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errors.add(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _startingImport = false);
      }
    }
  }

  Future<void> _startJob(String jobId) async {
    await _progressSub?.cancel();
    _progressSub = null;

    setState(() {
      _jobId = jobId;
      _progress = null;
      _logTail = null;
      _errors.clear();
    });

    try {
      final handle = await _importService.start(
        jobId,
        onDuplicate: (duplicate) async {
          if (!mounted) throw const DataImportException('页面已退出，导入停止');
          return await AppDialog.confirm(
                context,
                title: '疑似重复记录',
                message:
                    '第 ${duplicate.rowIndex} 行：${duplicate.personName}，${duplicate.direction} ${(duplicate.amountCent / 100).toStringAsFixed(2)} 元。是否仍保留为一条新记录？',
                confirmLabel: '保留',
                cancelLabel: '跳过',
              ) ==
              true;
        },
      );
      if (!mounted) return;
      setState(() => _runHandle = handle);
      _progressSub = handle.progress.listen(
        (p) async {
          if (!mounted) return;
          setState(() {
            _progress = p;
            if (_isTerminalStatus(p.status)) {
              _runHandle = null;
            }
          });
          if (p.status == DataImportStatus.completed) {
            await _bookIdFuture;
          }
          await _refreshLogTail();
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _runHandle = null;
            _errors.add(e.toString());
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errors.add(e.toString()));
    }
  }

  Future<void> _refreshLogTail() async {
    final jobId = _jobId;
    if (jobId == null) return;
    final job = await _db.dataImportJobsDao.findById(jobId);
    final path = job?.errorLogPath;
    if (path == null) return;
    try {
      final f = File(path);
      if (!await f.exists()) return;
      final lines = await f.readAsLines();
      final tail = lines.length <= 60
          ? lines
          : lines.sublist(lines.length - 60);
      if (!mounted) return;
      setState(() => _logTail = tail.join('\n'));
    } catch (_) {}
  }

  bool get _isImportRunning => _progress?.status == DataImportStatus.running;

  bool get _isImportBusy =>
      _startingImport || _runHandle != null || _isImportRunning;

  bool _isTerminalStatus(DataImportStatus status) {
    return status == DataImportStatus.completed ||
        status == DataImportStatus.failed ||
        status == DataImportStatus.paused ||
        status == DataImportStatus.canceled;
  }

  double? _progressIndicatorValue(DataImportStatus status) {
    return status == DataImportStatus.running ||
            status == DataImportStatus.pending
        ? null
        : 1;
  }

  Color _progressIndicatorColor(BuildContext context, DataImportStatus status) {
    final colors = context.appColors;
    return switch (status) {
      DataImportStatus.completed => colors.stateSuccess,
      DataImportStatus.failed ||
      DataImportStatus.canceled => colors.stateDanger,
      DataImportStatus.paused => colors.stateWarning,
      DataImportStatus.pending ||
      DataImportStatus.running => colors.brandSecondary,
    };
  }

  String _statusLabel(DataImportStatus status) {
    switch (status) {
      case DataImportStatus.pending:
        return '等待中';
      case DataImportStatus.running:
        return '导入中';
      case DataImportStatus.paused:
        return '已暂停';
      case DataImportStatus.completed:
        return '已完成';
      case DataImportStatus.failed:
        return '失败';
      case DataImportStatus.canceled:
        return '已取消';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(
          title: '导入数据',
          left: AppIconButton(
            icon: const Icon(AppIcons.arrowLeft, size: 18),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: () => AppNav.pop(context),
          ),
        ),
        Expanded(
          child: ListView(
            padding: AppLayout.tabContentPadding,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('文件上传', style: AppTypography.h3()),
                    const SizedBox(height: 10),
                    _UploadArea(
                      fileName: _picked?.name,
                      loading: _loadingPreview,
                      emptyLabel: '点击选择 Excel 或 CSV 文件',
                      helperText: '支持 Excel (.xlsx) 或 CSV (.csv) 格式。',
                      onTap: _loadingPreview ? null : _pickFile,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            label: '下载模板',
                            onTap: _downloadTemplate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppSecondaryButton(
                            label: '导入历史',
                            onTap: _showHistorySheet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('字段映射', style: AppTypography.h3()),
                    const SizedBox(height: 8),
                    if (_preview == null)
                      Text(
                        '请选择文件后配置字段映射。',
                        style: AppTypography.base(
                          fontSize: AppTypography.fs14,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      _MappingPanel(
                        fields: _recordFields,
                        headers: _preview!.headers,
                        mapping: _fieldMapping,
                        onChanged: (field, header) {
                          setState(() => _fieldMapping[field] = header);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('数据预览', style: AppTypography.h3()),
                    const SizedBox(height: 8),
                    if (_preview == null)
                      Text(
                        '请选择文件后查看数据预览。',
                        style: AppTypography.base(
                          fontSize: AppTypography.fs14,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      _PreviewTable(
                        headers: _preview!.headers,
                        rows: _preview!.rows,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('导入进度', style: AppTypography.h3()),
                    const SizedBox(height: 8),
                    if (_progress == null)
                      Text(
                        '请选择文件并开始导入。',
                        style: AppTypography.base(
                          fontSize: AppTypography.fs14,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '状态：${_statusLabel(_progress!.status)}',
                            style: AppTypography.base(
                              fontSize: AppTypography.fs14,
                              fontWeight: AppTypography.medium,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _progressIndicatorValue(_progress!.status),
                            minHeight: 6,
                            backgroundColor: context.appColors.surfaceSubtle,
                            color: _progressIndicatorColor(
                              context,
                              _progress!.status,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '已处理：${_progress!.processedRows}  成功：${_progress!.successRows}  跳过：${_progress!.skippedRows}  失败：${_progress!.failedRows}',
                            style: AppTypography.base(
                              fontSize: AppTypography.fs12,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: _progress?.status == DataImportStatus.paused
                                ? '已暂停'
                                : (_isImportBusy ? '导入中...' : '开始导入'),
                            icon: AppIcons.play,
                            onTap:
                                (_preview == null ||
                                    _picked?.path == null ||
                                    _isImportBusy)
                                ? null
                                : _startNewJob,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppSecondaryButton(
                            label: _progress?.status == DataImportStatus.running
                                ? '暂停'
                                : '取消',
                            onTap: _runHandle == null
                                ? null
                                : () async {
                                    if (_progress?.status ==
                                        DataImportStatus.running) {
                                      await _runHandle!.pause();
                                      return;
                                    }
                                    await _runHandle!.cancel();
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _UploadArea(
                      fileName: _mediaZip?.name,
                      loading: false,
                      emptyLabel: '选择媒体 ZIP 文件（可选）',
                      helperText: '用于恢复头像和附件，支持 ZIP (.zip) 格式。',
                      onTap: _pickMediaZip,
                    ),
                  ],
                ),
              ),
              if ((_logTail ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('错误日志', style: AppTypography.h3()),
                      const SizedBox(height: 8),
                      Text(
                        _logTail!,
                        style: AppTypography.base(
                          fontSize: AppTypography.fs12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('错误日志', style: AppTypography.h3()),
                      const SizedBox(height: 8),
                      for (final e in _errors)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            e,
                            style: AppTypography.base(
                              fontSize: AppTypography.fs14,
                              fontWeight: AppTypography.regular,
                              color: AppColors.red600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea({
    required this.fileName,
    required this.loading,
    required this.emptyLabel,
    required this.helperText,
    required this.onTap,
  });

  final String? fileName;
  final bool loading;
  final String emptyLabel;
  final String helperText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: Radius.circular(16),
          color: context.appColors.borderDefault,
          strokeWidth: 1.5,
          dashPattern: <double>[6, 4],
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: double.infinity,
          padding: AppLayout.pagePadding,
          decoration: BoxDecoration(
            color: context.appColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.appColors.brandSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        AppIcons.fileUp,
                        size: 18,
                        color: context.appColors.brandOnSoft,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName == null ? emptyLabel : fileName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.semibold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      helperText,
                      style: AppTypography.base(
                        fontSize: AppTypography.fs12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                AppIcons.chevronRight,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MappingPanel extends StatelessWidget {
  const _MappingPanel({
    required this.fields,
    required this.headers,
    required this.mapping,
    required this.onChanged,
  });

  final List<String> fields;
  final List<String> headers;
  final Map<String, String?> mapping;
  final void Function(String field, String? header) onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <String, String>{'不导入': '', for (final h in headers) h: h};

    return Column(
      children: [
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    f,
                    style: AppTypography.base(
                      fontSize: AppTypography.fs14,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: FSelect<String>(
                    items: items,
                    control: FSelectControl.lifted(
                      value: mapping[f] ?? '',
                      onChange: (value) => onChanged(
                        f,
                        value == null || value.isEmpty ? null : value,
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

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final showHeaders = headers.take(8).toList();
    final showRows = rows.take(20).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: AppTypography.base(
          fontSize: 12,
          fontWeight: AppTypography.semibold,
          color: AppColors.textPrimary,
        ),
        dataTextStyle: AppTypography.base(
          fontSize: 12,
          fontWeight: AppTypography.regular,
          color: AppColors.textSecondary,
        ),
        columns: [for (final h in showHeaders) DataColumn(label: Text(h))],
        rows: [
          for (final r in showRows)
            DataRow(
              cells: [
                for (var i = 0; i < showHeaders.length; i++)
                  DataCell(
                    Text(
                      i < r.length ? r[i] : '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
