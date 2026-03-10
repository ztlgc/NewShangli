import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/data_import_service.dart';
import '../../import/data_import_template_service.dart';
import '../../import/default_book_service.dart';
import '../../import/import_file_reader.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

class DataImportPage extends StatelessWidget {
  const DataImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: const _Canvas(),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  late final AppDatabase _db;
  late final DataImportService _importService;
  final DataImportTemplateService _templateService = DataImportTemplateService();
  final DefaultBookService _defaultBookService = DefaultBookService();
  late final Future<String> _bookIdFuture;

  PlatformFile? _picked;
  ImportPreview? _preview;
  bool _loadingPreview = false;

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
    '金额(分)',
    '事由',
    '关系人ID',
    '关系人姓名',
    '关系人关系',
    '手机号',
    '支付方式',
    '发生时间',
    '备注',
  ];

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    _importService = DataImportService(db: _db);
    _bookIdFuture = _defaultBookService.ensureDefaultBookId(_db);
  }

  @override
  void dispose() {
    _runHandle?.cancel();
    _progressSub?.cancel();
    _db.close();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'xlsx'],
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法读取文件路径，请重试')),
      );
      return;
    }

    setState(() {
      _picked = f;
      _preview = null;
      _loadingPreview = true;
      _errors.clear();
      _fieldMapping.clear();
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
    final choice = await showModalBottomSheet<DataImportTemplateFormat>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.fileCsv, size: 18),
                title: const Text('CSV 模板'),
                onTap: () => Navigator.of(context).pop(DataImportTemplateFormat.csv),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.fileExcel, size: 18),
                title: const Text('Excel 模板 (.xlsx)'),
                onTap: () => Navigator.of(context).pop(DataImportTemplateFormat.xlsx),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;

    try {
      final file = await _templateService.generateTemplate(format: choice);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: '尚礼导入模板');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模板生成失败：$e')),
      );
    }
  }

  Future<void> _showHistorySheet() async {
    final bookId = await _bookIdFuture;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final job = list[i];
                    return ListTile(
                      title: Text(job.fileName),
                      subtitle: Text(
                        '状态：${job.status}  成功：${job.successRows}  跳过：${job.skippedRows}  失败：${job.failedRows}',
                      ),
                      trailing: (job.status == DataImportStatus.paused.name || job.status == DataImportStatus.failed.name)
                          ? TextButton(
                              onPressed: () async {
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
      },
    );
  }

  Future<void> _startNewJob() async {
    if (_picked?.path == null) return;
    final bookId = await _bookIdFuture;
    if (!mounted) return;
    try {
      final jobId = await _importService.createJob(
        bookId: bookId,
        sourceFilePath: _picked!.path!,
        kind: DataImportKind.recordsAndPersons,
      );
      await _startJob(jobId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errors.add(e.toString()));
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

    final handle = await _importService.start(jobId);
    _runHandle = handle;
    _progressSub = handle.progress.listen(
      (p) async {
        if (!mounted) return;
        setState(() => _progress = p);
        await _refreshLogTail();
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _errors.add(e.toString()));
      },
    );
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
      final tail = lines.length <= 60 ? lines : lines.sublist(lines.length - 60);
      if (!mounted) return;
      setState(() => _logTail = tail.join('\n'));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
                    '导入数据',
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              PrototypeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('文件上传', style: AppTypography.h3()),
                    const SizedBox(height: 10),
                    _UploadArea(
                      fileName: _picked?.name,
                      loading: _loadingPreview,
                      onTap: _loadingPreview ? null : _pickFile,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PrototypeSecondaryButton(
                            label: '下载模板',
                            onTap: _downloadTemplate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrototypeSecondaryButton(
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
              PrototypeCard(
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
              PrototypeCard(
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
              PrototypeCard(
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
                            '状态：${_progress!.status.name}',
                            style: AppTypography.base(
                              fontSize: AppTypography.fs14,
                              fontWeight: AppTypography.medium,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: null,
                            minHeight: 6,
                            backgroundColor: AppColors.gray100,
                            color: AppColors.indigo600,
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
                          child: PrototypePrimaryButton(
                            label: '开始导入',
                            icon: FontAwesomeIcons.play,
                            onTap: (_preview == null || _picked?.path == null) ? null : _startNewJob,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrototypeSecondaryButton(
                            label: _progress?.status == DataImportStatus.running ? '暂停' : '取消',
                            onTap: _runHandle == null
                                ? null
                                : () async {
                                    if (_progress?.status == DataImportStatus.running) {
                                      await _runHandle!.pause();
                                      return;
                                    }
                                    await _runHandle!.cancel();
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if ((_logTail ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                PrototypeCard(
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
                PrototypeCard(
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
    required this.onTap,
  });

  final String? fileName;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          radius: Radius.circular(16),
          color: AppColors.gray200,
          strokeWidth: 1.5,
          dashPattern: <double>[6, 4],
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.indigo50,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const FaIcon(
                        FontAwesomeIcons.fileArrowUp,
                        size: 18,
                        color: AppColors.indigo700,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName == null ? '点击选择 Excel/CSV 文件' : fileName!,
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.semibold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '支持 .xlsx / .csv；大文件建议使用 CSV。',
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
              const FaIcon(FontAwesomeIcons.chevronRight, size: 14, color: AppColors.textTertiary),
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
    final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(
          '不导入',
          style: AppTypography.base(
            fontSize: AppTypography.fs14,
            fontWeight: AppTypography.regular,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      ...headers.map(
        (h) => DropdownMenuItem<String?>(
          value: h,
          child: Text(h, overflow: TextOverflow.ellipsis),
        ),
      ),
    ];

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
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: mapping[f],
                    items: items,
                    onChanged: (v) => onChanged(f, v),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
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
  const _PreviewTable({
    required this.headers,
    required this.rows,
  });

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
        columns: [
          for (final h in showHeaders) DataColumn(label: Text(h)),
        ],
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
