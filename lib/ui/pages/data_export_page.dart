import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:path/path.dart' as p;

import '../../data/local/drift/app_database.dart';
import '../../export/data_export_service.dart';
import '../../platform/app_platform.dart';
import '../app_bottom_sheet.dart';
import '../app_database_scope.dart';
import '../app_icons.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../data_transfer/transfer_widgets.dart';
import '../lunar_date_picker.dart';
import '../navigation.dart';
import '../ui_kit.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key, this.service, this.now});
  final DataExportService? service;
  final DateTime Function()? now;
  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  late final DataExportService _service = widget.service ?? DataExportService();
  AppDatabase? _database;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  List<AccountBook> _books = [];
  String? _bookId;
  bool _allTime = true;
  late DateTime _start;
  late DateTime _end;
  DataExportFormat _format = DataExportFormat.excel;
  DataExportSummary? _summary;
  DataExportSummary? _exportedSummary;
  bool _loading = true;
  bool _exporting = false;
  bool _sharing = false;
  bool _scopeDirty = false;
  int _scopeVersion = 0;
  File? _file;
  int? _fileBytes;
  String? _error;
  String? _scopeError;
  String _phase = '正在准备导出…';
  bool get _busy => _exporting || _sharing;
  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    final now = _now;
    _start = DateTime(now.year, 1, 1);
    _end = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDatabaseScope.of(context);
    if (identical(db, _database)) return;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _database = db;
    _subscriptions.add(
      (db.select(
        db.accountBooks,
      )..where((t) => t.deletedAt.isNull())).watch().listen((books) {
        if (!mounted) return;
        setState(() {
          _books = books;
          if (_bookId != null && !books.any((book) => book.bookId == _bookId)) {
            _bookId = null;
            _file = null;
            _exportedSummary = null;
          }
        });
        unawaited(_refreshScope());
      }, onError: _watchError),
    );
    _subscriptions.add(
      db
          .select(db.giftRecords)
          .watch()
          .listen((_) => unawaited(_refreshScope()), onError: _watchError),
    );
    _subscriptions.add(
      db
          .select(db.persons)
          .watch()
          .listen((_) => unawaited(_refreshScope()), onError: _watchError),
    );
  }

  @override
  void dispose() {
    _scopeVersion++;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  void _watchError(Object _) {
    if (mounted) {
      setState(() {
        _loading = false;
        _scopeError = '导出范围读取失败，请重试';
      });
    }
  }

  Future<void> _refreshScope() async {
    if (!mounted) return;
    if (_busy) {
      _scopeDirty = true;
      return;
    }
    final version = ++_scopeVersion;
    final db = _database!;
    final allTime = _allTime;
    final bookId = _bookId;
    final start = _start;
    final end = _end;
    setState(() {
      _loading = true;
      _scopeError = null;
    });
    try {
      final summary = await _service.inspectScope(
        db: db,
        bookId: bookId,
        start: allTime ? null : start,
        end: allTime ? null : end,
      );
      if (!mounted || version != _scopeVersion) return;
      setState(() {
        _summary = summary;
        _loading = false;
        if (allTime) {
          final now = _now;
          _start = summary.firstDate ?? DateTime(now.year, now.month, now.day);
          _end = summary.lastDate ?? _start;
        }
      });
    } catch (_) {
      if (mounted && version == _scopeVersion) {
        setState(() {
          _loading = false;
          _summary = null;
          _scopeError = '导出范围读取失败，请重试';
        });
      }
    }
  }

  void _clearResult() {
    _file = null;
    _fileBytes = null;
    _exportedSummary = null;
    _error = null;
  }

  Future<void> _pickBook() async {
    if (_busy) return;
    const all = '__all_books__';
    final picked = await AppBottomSheet.showPicker<String>(
      context,
      title: '选择账簿',
      options: [
        AppSheetOption(label: '全部账簿', value: all, selected: _bookId == null),
        for (final book in _books)
          AppSheetOption(
            label: book.name,
            value: book.bookId,
            selected: _bookId == book.bookId,
            subtitle: book.isDefault == 1 ? '含其他账簿的送礼记录' : null,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    final next = picked == all ? null : picked;
    if (next == _bookId) return;
    setState(() {
      _bookId = next;
      _clearResult();
    });
    await _refreshScope();
  }

  Future<void> _pickDates() async {
    if (_busy) return;
    final picked = await AppBottomSheet.showPicker<String>(
      context,
      title: '日期范围',
      options: [
        AppSheetOption(label: '所有时间', value: 'all', selected: _allTime),
        AppSheetOption(label: '自定义时间', value: 'custom', selected: !_allTime),
      ],
    );
    if (picked == null || !mounted) return;
    if (picked == 'all') {
      if (_allTime) return;
      setState(() {
        _allTime = true;
        _clearResult();
      });
      await _refreshScope();
      return;
    }
    final start = await showLunarDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (start == null || !mounted) return;
    final end = await showLunarDatePicker(
      context: context,
      initialDate: _end.isBefore(start) ? start : _end,
      firstDate: start,
      lastDate: DateTime(2100, 12, 31),
    );
    if (end == null || !mounted) return;
    setState(() {
      _allTime = false;
      _start = start;
      _end = end;
      _clearResult();
    });
    await _refreshScope();
  }

  void _selectFormat(DataExportFormat format) {
    if (_busy || format == _format) return;
    setState(() {
      _format = format;
      _clearResult();
    });
  }

  Future<void> _export() async {
    if (_busy || _loading || _summary == null || _summary!.isEmpty) return;
    setState(() {
      _exporting = true;
      _clearResult();
      _phase = '正在准备导出…';
    });
    DataExportSummary? prepared;
    final request = DataExportRequest(
      format: _format,
      start: _start,
      end: _end,
      bookId: _bookId,
      includeRecords: true,
      includePersons: true,
      includeImages: _format == DataExportFormat.zip,
    );
    try {
      final file = await _service.exportFromDrift(
        db: _database!,
        request: request,
        onPrepared: (summary) {
          prepared = summary;
          if (mounted) {
            setState(
              () => _phase = request.format == DataExportFormat.zip
                  ? '正在生成 ZIP…'
                  : '正在生成 Excel…',
            );
          }
        },
      );
      final bytes = await file.length();
      if (!mounted) return;
      setState(() {
        _file = file;
        _fileBytes = bytes;
        _exportedSummary = prepared ?? _summary;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is DataExportException
              ? error.message
              : '导出失败，请重试',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
        if (_scopeDirty) {
          _scopeDirty = false;
          unawaited(_refreshScope());
        }
      }
    }
  }

  Future<void> _share() async {
    final file = _file;
    if (_busy || file == null) return;
    setState(() {
      _sharing = true;
      _error = null;
    });
    try {
      if (!await file.exists()) {
        if (mounted) {
          setState(() {
            _clearResult();
            _error = '文件已不存在，请重新导出';
          });
        }
        return;
      }
      await AppPlatform.instance.shareFile(file.path, text: '礼记数据导出');
    } catch (_) {
      if (mounted) setState(() => _error = '文件已生成，分享未完成，可重试分享');
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
        if (_scopeDirty) {
          _scopeDirty = false;
          unawaited(_refreshScope());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label = _exporting
        ? '正在导出…'
        : _sharing
        ? '正在打开分享…'
        : _file != null
        ? '分享文件'
        : _error != null
        ? '重试导出'
        : '开始导出';
    final enabled =
        !_busy && !_loading && _summary != null && !_summary!.isEmpty;
    final book = _books.where((book) => book.bookId == _bookId).firstOrNull;
    return AppScaffold(
      body: Column(
        children: [
          AppTopBar(
            title: '数据导出',
            left: AppIconButton(
              size: 44,
              icon: const Icon(AppIcons.arrowLeft, size: 18),
              backgroundColor: Colors.transparent,
              onPressed: () => AppNav.pop(context),
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
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TransferHeading(title: '导出范围'),
                          const SizedBox(height: 8),
                          TransferSelectionRow(
                            icon: AppIcons.bookOpen,
                            label: '账簿',
                            value: book?.name ?? '全部账簿',
                            subtitle: book?.isDefault == 1
                                ? '含其他账簿的送礼记录'
                                : null,
                            onTap: _busy ? null : () => unawaited(_pickBook()),
                          ),
                          Divider(height: 1, color: colors.borderSubtle),
                          TransferSelectionRow(
                            icon: AppIcons.calendarDays,
                            label: '日期范围',
                            value: _allTime ? '所有时间' : '自定义时间',
                            subtitle:
                                '${transferDate(_start)} — ${transferDate(_end)}',
                            onTap: _busy ? null : () => unawaited(_pickDates()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TransferHeading(title: '文件格式'),
                          const SizedBox(height: 12),
                          _formatOption(
                            DataExportFormat.excel,
                            'Excel 表格',
                            '.xlsx',
                            '记录与联系人，图片仅保留路径',
                          ),
                          const SizedBox(height: 8),
                          _formatOption(
                            DataExportFormat.zip,
                            'ZIP 压缩包',
                            '.zip',
                            'Excel 表格与可读取的本地图片',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_scopeError != null)
                      TransferMessage(
                        message: _scopeError!,
                        error: true,
                        action: AppSecondaryButton(
                          label: '重试读取',
                          onTap: () => unawaited(_refreshScope()),
                        ),
                      )
                    else
                      AppCard(
                        child: Row(
                          children: [
                            const TransferIconWell(icon: AppIcons.fileOutput),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  transferText(
                                    context,
                                    _loading
                                        ? '正在统计记录…'
                                        : '共 ${_summary?.recordCount ?? 0} 条记录',
                                    18,
                                    weight: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 5),
                                  transferText(
                                    context,
                                    _loading
                                        ? '按账簿和日期范围计算'
                                        : '另含 ${_summary?.personCount ?? 0} 位联系人资料${_format == DataExportFormat.zip ? '与可读取的本地图片' : ''}',
                                    11,
                                    color: colors.textTertiary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_exporting) ...[
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            transferText(
                              context,
                              _phase,
                              14,
                              weight: FontWeight.w600,
                            ),
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(minHeight: 4),
                            const SizedBox(height: 8),
                            transferText(
                              context,
                              '完成后可通过系统分享保存或发送',
                              12,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_file != null) ...[
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TransferHeading(
                              title: '导出完成',
                              detail:
                                  '已导出 ${_exportedSummary?.recordCount ?? 0} 条记录',
                              detailColor: colors.stateSuccess,
                            ),
                            const SizedBox(height: 12),
                            Tooltip(
                              message: p.basename(_file!.path),
                              child: transferText(
                                context,
                                p.basename(_file!.path),
                                13,
                                weight: FontWeight.w600,
                                maxLines: 2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            transferText(
                              context,
                              '${_fileBytes == null ? '已生成' : transferFileSize(_fileBytes!)} · '
                              '${_exportedSummary?.personCount ?? 0} 位联系人',
                              11,
                              color: colors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.info,
                            size: 15,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: transferText(
                              context,
                              '表格导出用于查看与整理。\n完整备份请使用「数据备份」。',
                              12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TransferFooter(
            label: label,
            hint: _error ?? '完成后可通过系统分享保存或发送',
            hintColor: _error == null ? null : colors.stateDangerStrong,
            onPressed: _file != null && !_busy
                ? () => unawaited(_share())
                : enabled
                ? () => unawaited(_export())
                : null,
            secondary: _file == null
                ? null
                : AppSecondaryButton(
                    label: '重新导出',
                    onTap: enabled ? () => unawaited(_export()) : null,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _formatOption(
    DataExportFormat format,
    String title,
    String extension,
    String subtitle,
  ) {
    final colors = context.appColors;
    final selected = _format == format;
    return Semantics(
      selected: selected,
      child: FButton.raw(
        variant: .ghost,
        onPress: _busy ? null : () => _selectFormat(format),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? colors.surfaceApp : colors.surfaceCard,
            borderRadius: AppRadii.brXl,
            border: Border.all(
              color: selected ? colors.textPrimary : colors.borderDefault,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 19,
                height: 19,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colors.textPrimary : colors.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.textPrimary : colors.borderDefault,
                  ),
                ),
                child: selected
                    ? Icon(AppIcons.check, size: 12, color: colors.surfaceCard)
                    : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        transferText(
                          context,
                          title,
                          14,
                          weight: FontWeight.w600,
                        ),
                        transferText(
                          context,
                          extension,
                          11,
                          color: colors.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    transferText(
                      context,
                      subtitle,
                      11,
                      color: colors.textTertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
