import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/data_import_service.dart';
import '../../import/data_import_template_service.dart';
import '../../import/default_book_service.dart';
import '../../import/import_field_mapping.dart';
import '../../import/import_file_reader.dart';
import '../../platform/app_platform.dart';
import '../app_bottom_sheet.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_icons.dart';
import '../app_notifier.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../data_transfer/import_review_widgets.dart';
import '../data_transfer/transfer_widgets.dart';
import '../ui_kit.dart';

class DataImportPage extends StatefulWidget {
  const DataImportPage({super.key, this.initialBookId, this.serviceFactory});
  final String? initialBookId;
  final DataImportService Function(AppDatabase)? serviceFactory;
  @override
  State<DataImportPage> createState() => _DataImportPageState();
}

class _DataImportPageState extends State<DataImportPage> {
  AppDatabase? _database;
  late DataImportService _service;
  late Future<String> _bookId;
  AppPickedFile? _file;
  AppPickedFile? _media;
  ImportPreview? _preview;
  Map<String, String?> _mapping = {};
  bool _reading = false;
  bool _picking = false;
  bool _starting = false;
  bool _templateBusy = false;
  bool _leaving = false;
  String? _controlHint;
  String? _error;
  String? _jobId;
  String? _logPath;
  String _logTail = '';
  int _logRequest = 0;
  DataImportRunHandle? _handle;
  StreamSubscription<DataImportProgress>? _subscription;
  DataImportProgress? _progress;
  Completer<void>? _settled;

  bool get _busy => _starting || _handle != null;
  bool get _canResume =>
      !_busy &&
      _jobId != null &&
      [
        DataImportStatus.paused,
        DataImportStatus.failed,
        DataImportStatus.pending,
      ].contains(_progress?.status);
  String? get _mappingProblem =>
      _preview == null ? null : importMappingProblem(_preview!, _mapping);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDatabaseScope.of(context);
    if (identical(db, _database)) return;
    unawaited(_handle?.pause());
    unawaited(_subscription?.cancel());
    _database = db;
    _service = widget.serviceFactory?.call(db) ?? DataImportService(db: db);
    _bookId = widget.initialBookId == null
        ? DefaultBookService().ensureDefaultBookId(db)
        : Future.value(widget.initialBookId!);
  }

  @override
  void dispose() {
    unawaited(_handle?.pause());
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_busy || _reading || _picking) return;
    setState(() => _picking = true);
    try {
      final files = await AppPlatform.instance.pickFiles(
        allowedExtensions: const ['xlsx', 'csv'],
      );
      if (!mounted || files == null || files.files.isEmpty) return;
      final file = files.files.first;
      if (file.path == null) throw const DataImportException('无法读取文件路径，请重新选择');
      setState(() {
        _file = file;
        _media = null;
        _preview = null;
        _mapping = {};
        _reading = true;
        _error = null;
        _jobId = null;
        _progress = null;
        _logPath = null;
        _logTail = '';
        _controlHint = null;
      });
      final preview = await ImportFileReader.preview(
        filePath: file.path!,
        maxPreviewRows: 20,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _mapping = defaultImportMapping(preview.headers);
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error, '文件读取失败，请检查文件后重试'));
    } finally {
      if (mounted) {
        setState(() {
          _picking = false;
          _reading = false;
        });
      }
    }
  }

  Future<void> _pickMedia() async {
    if (_busy || _picking) return;
    setState(() => _picking = true);
    try {
      final files = await AppPlatform.instance.pickFiles(
        allowedExtensions: const ['zip'],
      );
      if (!mounted || files == null || files.files.isEmpty) return;
      final file = files.files.first;
      if (file.path == null || !await File(file.path!).exists()) {
        throw const DataImportException('无法读取图片 ZIP，请重新选择');
      }
      if (mounted) {
        setState(() {
          _media = file;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error, '图片 ZIP 读取失败，请重试'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _editMapping() async {
    if (_preview == null || _busy) return;
    final draft = await AppBottomSheet.show<Map<String, String?>>(
      context,
      title: '字段匹配',
      child: ImportMappingSheet(headers: _preview!.headers, mapping: _mapping),
    );
    if (draft != null && mounted) setState(() => _mapping = draft);
  }

  Future<void> _openPreview() async {
    if (_preview == null) return;
    await AppBottomSheet.show<void>(
      context,
      title: '数据预览',
      child: ImportPreviewSheet(preview: _preview!),
    );
  }

  Future<void> _template(BuildContext anchorContext) async {
    if (_templateBusy || _busy) return;
    final choice = await AppBottomSheet.showPicker<DataImportTemplateFormat>(
      context,
      anchorContext: anchorContext,
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
    if (choice == null || !mounted) return;
    setState(() => _templateBusy = true);
    try {
      final file = await DataImportTemplateService().generateTemplate(
        format: choice,
      );
      if (!mounted) return;
      try {
        await AppPlatform.instance.shareFile(file.path, text: '礼记导入模板');
      } catch (_) {
        if (mounted) AppNotifier.info(context, '模板已生成，可重新下载后分享');
      }
    } catch (error) {
      if (mounted) AppNotifier.error(context, _message(error, '模板生成失败，请重试'));
    } finally {
      if (mounted) setState(() => _templateBusy = false);
    }
  }

  Future<void> _begin() async {
    if (_busy ||
        _reading ||
        _file?.path == null ||
        _preview == null ||
        _mappingProblem != null) {
      return;
    }
    // Lock immediately, before the asynchronous default-book lookup and file copy.
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final bookId = await _bookId;
      if (!mounted) return;
      final job = await _service.createJob(
        bookId: bookId,
        sourceFilePath: _file!.path!,
        kind: DataImportKind.recordsAndPersons,
        fieldMapping: Map.of(_mapping),
        mediaZipPath: _media?.path,
      );
      if (!mounted) return;
      setState(() => _jobId = job);
      await _run(job);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error, '无法开始导入，请重试'));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _resume() async {
    if (!_canResume) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await _run(_jobId!);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error, '无法继续导入，请重试'));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _run(String jobId) async {
    await _subscription?.cancel();
    final job = await _database!.dataImportJobsDao.findById(jobId);
    if (!mounted) return;
    setState(() {
      _logPath = job?.errorLogPath;
      _controlHint = null;
    });
    try {
      final handle = await _service.start(
        jobId,
        onDuplicate: (duplicate) async {
          if (!mounted) return false;
          return await AppDialog.confirm(
                context,
                title: '疑似重复记录',
                message:
                    '第 ${duplicate.rowIndex} 行：${duplicate.personName}，${duplicate.direction} '
                    '${(duplicate.amountCent / 100).toStringAsFixed(2)} 元。是否仍保留为一条新记录？',
                confirmLabel: '保留',
                cancelLabel: '跳过',
              ) ==
              true;
        },
      );
      if (!mounted) {
        await handle.pause();
        unawaited(handle.progress.drain<void>());
        return;
      }
      _settled = Completer<void>();
      setState(() => _handle = handle);
      _subscription = handle.progress.listen(
        (progress) {
          if (!mounted || _jobId != jobId) return;
          setState(() {
            _progress = progress;
            if (progress.status != DataImportStatus.running &&
                progress.status != DataImportStatus.pending) {
              _handle = null;
              _controlHint = null;
            }
          });
          if (_handle == null && !(_settled?.isCompleted ?? true)) {
            _settled!.complete();
          }
          unawaited(_refreshLog(jobId));
        },
        onError: (Object error) {
          if (mounted) {
            setState(() {
              _handle = null;
              _error = _message(error, '导入中断，可从历史继续');
            });
          }
          if (!(_settled?.isCompleted ?? true)) _settled!.complete();
        },
        onDone: () {
          if (!(_settled?.isCompleted ?? true)) _settled!.complete();
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _handle = null;
          _progress = DataImportProgress(
            jobId: jobId,
            status: DataImportStatus.failed,
            processedRows: job?.processedRows ?? 0,
            successRows: job?.successRows ?? 0,
            skippedRows: job?.skippedRows ?? 0,
            failedRows: job?.failedRows ?? 0,
          );
          _error = _message(error, '导入中断，请重试');
        });
      }
    }
  }

  Future<void> _control({required bool cancel}) async {
    final handle = _handle;
    if (handle == null || _controlHint != null) return;
    if (cancel) {
      final confirm = await AppDialog.confirm(
        context,
        title: '取消本次导入？',
        message: '已提交的数据会保留，本任务取消后无法继续。',
        confirmLabel: '取消导入',
        cancelLabel: '继续导入',
      );
      if (confirm != true || !mounted) return;
    }
    setState(() => _controlHint = cancel ? '正在取消…' : '正在暂停…');
    try {
      await (cancel ? handle.cancel() : handle.pause());
      await _settled?.future;
    } finally {
      if (mounted) setState(() => _controlHint = null);
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    if (_starting) {
      AppNotifier.info(context, '正在准备导入，请稍候');
      return;
    }
    if (_busy) {
      final confirm = await AppDialog.confirm(
        context,
        title: '暂停并离开？',
        message: '已提交的数据会保留，可在导入历史中继续。',
        confirmLabel: '暂停并离开',
        cancelLabel: '留在此页',
      );
      if (confirm != true || !mounted) return;
      await _control(cancel: false);
    }
    if (mounted) {
      _leaving = true;
      Navigator.of(context).pop();
    }
  }

  Future<void> _refreshLog(String jobId) async {
    final version = ++_logRequest;
    try {
      final job = await _database!.dataImportJobsDao.findById(jobId);
      if (!mounted || _jobId != jobId || version != _logRequest) return;
      final path = job?.errorLogPath;
      final file = path == null ? null : File(path);
      final lines = file != null && await file.exists()
          ? await file.readAsLines()
          : <String>[];
      if (mounted && _jobId == jobId && version == _logRequest) {
        setState(() {
          _logPath = path;
          _logTail = lines
              .skip(lines.length > 60 ? lines.length - 60 : 0)
              .join('\n');
        });
      }
    } catch (_) {
      /* The persisted job counters remain available if log reading fails. */
    }
  }

  Future<void> _details() async {
    if (_jobId == null) return;
    await _refreshLog(_jobId!);
    if (!mounted) return;
    await AppBottomSheet.show<void>(
      context,
      title: '处理详情',
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _logTail.isEmpty ? '暂无错误或跳过详情。' : _logTail,
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
            ),
            if (_logPath != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppSecondaryButton(
                  label: '分享处理日志',
                  onTap: () async {
                    try {
                      await AppPlatform.instance.shareFile(
                        _logPath!,
                        text: '礼记导入处理日志',
                      );
                    } catch (_) {
                      if (mounted) AppNotifier.error(context, '日志分享失败，请重试');
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _history() async {
    if (_busy) return;
    final job = await AppBottomSheet.show<DataImportJob>(
      context,
      title: '导入历史',
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: StreamBuilder<List<DataImportJob>>(
          stream: _database!.dataImportJobsDao.watchRecent(
            bookId: widget.initialBookId,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('历史读取失败，请重新打开'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final jobs = snapshot.data!;
            if (jobs.isEmpty) return const Center(child: Text('暂无导入历史'));
            return ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final status = _savedStatus(job);
                return AppPressableRow(
                  onTap: () => Navigator.of(context).pop(job),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            transferText(
                              context,
                              job.fileName,
                              14,
                              weight: FontWeight.w600,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 5),
                            transferText(
                              context,
                              '${importStatusLabel(status)} · 成功 ${job.successRows} · 跳过 ${job.skippedRows} · 失败 ${job.failedRows}',
                              11,
                              color: context.appColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      transferText(
                        context,
                        [
                              DataImportStatus.paused,
                              DataImportStatus.failed,
                              DataImportStatus.pending,
                            ].contains(status)
                            ? '继续'
                            : '查看',
                        12,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
    if (job == null || !mounted) return;
    final status = _savedStatus(job);
    setState(() {
      _file = AppPickedFile(
        name: job.fileName,
        path: job.filePath,
        size: job.fileSize,
      );
      _jobId = job.jobId;
      _preview = null;
      _error = null;
      _media = null;
      _logTail = '';
      _logPath = job.errorLogPath;
      _progress = DataImportProgress(
        jobId: job.jobId,
        status: status,
        processedRows: job.processedRows,
        successRows: job.successRows,
        skippedRows: job.skippedRows,
        failedRows: job.failedRows,
      );
    });
    unawaited(_refreshLog(job.jobId));
    if (_canResume) await _resume();
  }

  DataImportStatus _savedStatus(DataImportJob job) {
    final status =
        DataImportStatus.values
            .where((s) => s.name == job.status)
            .firstOrNull ??
        DataImportStatus.failed;
    return status == DataImportStatus.running &&
            !DataImportService.isRunning(_database!)
        ? DataImportStatus.paused
        : status;
  }

  String _message(Object error, String fallback) => error is DataImportException
      ? error.message
      : error is FormatException
      ? error.message.toString()
      : fallback;

  @override
  Widget build(BuildContext context) {
    final canPick = !_busy && !_reading && !_picking;
    final hasJob = _jobId != null;
    final label = _busy
        ? (_controlHint ?? (_starting ? '准备导入…' : '导入中…'))
        : _canResume
        ? '继续导入'
        : hasJob
        ? '选择其他文件'
        : '开始导入';
    final VoidCallback? action = _busy || _reading || _picking
        ? null
        : _canResume
        ? () => unawaited(_resume())
        : hasJob
        ? () => unawaited(_pickFile())
        : _preview != null && _mappingProblem == null
        ? () => unawaited(_begin())
        : null;
    return PopScope<Object?>(
      canPop: _leaving || !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: AppScaffold(
        body: Column(
          children: [
            AppTopBar(
              title: '数据导入',
              left: AppIconButton(
                size: 44,
                backgroundColor: Colors.transparent,
                icon: const Icon(AppIcons.arrowLeft, size: 18),
                onPressed: () => unawaited(_leave()),
              ),
              right: SizedBox(
                height: 44,
                child: FButton.raw(
                  variant: .ghost,
                  semanticsLabel: '导入历史',
                  onPress: _busy ? null : () => unawaited(_history()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.history, size: 14),
                        const SizedBox(width: 5),
                        transferText(context, '历史', 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ImportFileCard(
                        file: _file,
                        loading: _reading,
                        templateBusy: _templateBusy,
                        onPick: canPick ? () => unawaited(_pickFile()) : null,
                        onTemplate: _busy || _templateBusy
                            ? null
                            : (anchorContext) =>
                                  unawaited(_template(anchorContext)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        TransferMessage(message: _error!, error: true),
                      ],
                      if (hasJob) ...[
                        const SizedBox(height: 16),
                        ImportResultCard(
                          progress: _progress,
                          controlHint: _controlHint,
                          onDetails: () => unawaited(_details()),
                        ),
                      ] else if (_preview != null) ...[
                        const SizedBox(height: 16),
                        ImportMappingCard(
                          preview: _preview!,
                          mapping: _mapping,
                          onEdit: () => unawaited(_editMapping()),
                        ),
                        const SizedBox(height: 16),
                        ImportPreviewCard(
                          preview: _preview!,
                          mapping: _mapping,
                          onOpen: () => unawaited(_openPreview()),
                        ),
                        const SizedBox(height: 16),
                        ImportMediaCard(
                          file: _media,
                          onPick: canPick
                              ? () => unawaited(_pickMedia())
                              : null,
                          onRemove: canPick
                              ? () => setState(() => _media = null)
                              : null,
                        ),
                      ] else if (!_reading) ...[
                        const SizedBox(height: 20),
                        transferText(
                          context,
                          '选择文件后，可核对字段并预览前 20 行。\n首次导入可先下载模板填写。',
                          12,
                          color: context.appColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            TransferFooter(
              label: label,
              onPressed: action,
              hint: _canResume ? '从原任务断点继续，已提交的数据保留' : '遇到疑似重复记录时，将逐条确认',
              secondary: _handle == null
                  ? null
                  : Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            label: '暂停',
                            onTap: _controlHint == null
                                ? () => unawaited(_control(cancel: false))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppSecondaryButton(
                            label: '取消导入',
                            onTap: _controlHint == null
                                ? () => unawaited(_control(cancel: true))
                                : null,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
