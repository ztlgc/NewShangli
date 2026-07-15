import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show OrderingTerm, Variable;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/drift/app_database.dart';
import '../../export/data_export_service.dart';
import '../app_tokens.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_session.dart';
import '../components.dart';
import '../lunar_date_picker.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../../utils/date_util.dart';

/// 页面：系统设置 - 导出数据
/// 对照原型：prototype/index.html -> "导出数据"
class DataExportPage extends StatelessWidget {
  const DataExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(backgroundColor: AppColors.surfaceApp, body: _Canvas());
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  final DataExportService _service = DataExportService();

  DataExportFormat _format = DataExportFormat.excel;
  late DateTime _start;
  late DateTime _end;
  bool _allTime = true;
  bool _allTimeRangeInitialized = false;
  String? _selectedBookId;
  bool _exporting = false;
  double _progress = 0;
  Timer? _progressTimer;
  File? _lastExportFile;
  String _exportDirPath = '';
  bool _exportPathVisible = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, 1, 1);
    _end = DateTime(now.year, now.month, now.day);
    _loadExportDir();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    final showExportPath =
        _exportPathVisible || _exporting || _lastExportFile != null;
    final db = AppDatabaseScope.of(context);
    _ensureAllTimeRangeInitialized(db);
    return Column(
      children: [
        PrototypeTopBar(
          title: '数据导出',
          left: PrototypeIconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: () => AppNav.pop(context),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  FutureBuilder<List<AccountBook>>(
                    future: (db.select(
                      db.accountBooks,
                    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get(),
                    builder: (context, bookSnapshot) {
                      final books = bookSnapshot.data ?? const <AccountBook>[];
                      final bookLabel = _resolveBookLabel(books);
                      return Column(
                        children: [
                          _Card(
                            children: [
                              _SettingRow(
                                label: '日期范围',
                                value: _allTime
                                    ? '所有时间'
                                    : '${_formatDate(_start)}\n${_formatDate(_end)}',
                                onTap: _exporting
                                    ? null
                                    : () => _pickDateRange(db),
                              ),
                              _SettingRow(
                                label: '账簿',
                                value: bookLabel,
                                onTap: _exporting
                                    ? null
                                    : () => _pickBook(db, books),
                              ),
                              _SettingRow(
                                label: '文件格式',
                                value: _formatLabel(_format),
                                onTap: _exporting ? null : _pickFormat,
                                borderBottom: showExportPath,
                              ),
                              if (showExportPath)
                                _SettingRow(
                                  label: '导出路径',
                                  subtitle: _exportDirPath.isEmpty
                                      ? '加载中...'
                                      : _exportDirPath,
                                  value: '分享至',
                                  onTap: _exporting
                                      ? null
                                      : (_lastExportFile == null
                                            ? null
                                            : _shareLastFile),
                                  borderBottom: false,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _HintArea(allTime: _allTime),
                          const SizedBox(height: 18),
                          FutureBuilder<int>(
                            future: _countBillsDb(db),
                            builder: (context, countSnapshot) {
                              final billCount = countSnapshot.data ?? 0;
                              return Text(
                                '共$billCount条记录',
                                style: AppTypography.base(
                                  fontSize: 14,
                                  fontWeight: AppTypography.regular,
                                  color: AppColors.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _exporting
                        ? _ExportProgress(progress: _progress)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 18),
                  _PrimaryButton(
                    enabled: !_exporting,
                    label: _exporting
                        ? '导出中 ${(math.min(_progress, 0.999) * 100).round()}%'
                        : (_lastExportFile == null ? '开始导出' : '分享文件'),
                    onTap: _exporting
                        ? null
                        : (_lastExportFile == null
                              ? () => _export(session: session, db: db)
                              : _shareLastFile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadExportDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);
    if (!mounted) return;
    setState(() => _exportDirPath = exportDir.path);
  }

  Future<int> _countBillsDb(AppDatabase db) async {
    final start = DateTime(
      _start.year,
      _start.month,
      _start.day,
    ).millisecondsSinceEpoch;
    final endExclusive = DateTime(
      _end.year,
      _end.month,
      _end.day,
    ).add(const Duration(days: 1)).millisecondsSinceEpoch;
    final sql = _selectedBookId == null
        ? 'SELECT COUNT(1) AS c FROM gift_record WHERE deleted_at IS NULL AND occurred_at >= ? AND occurred_at < ?;'
        : 'SELECT COUNT(1) AS c FROM gift_record WHERE deleted_at IS NULL AND occurred_at >= ? AND occurred_at < ? AND book_id = ?;';
    final vars = <Variable<Object>>[
      Variable<int>(start),
      Variable<int>(endExclusive),
      if (_selectedBookId != null) Variable<String>(_selectedBookId!),
    ];
    final rows = await db.customSelect(sql, variables: vars).get();
    return (rows.first.data['c'] as int?) ?? 0;
  }

  String _resolveBookLabel(List<AccountBook> books) {
    if (_selectedBookId == null) return '所有账簿';
    for (final b in books) {
      if (b.bookId == _selectedBookId) return b.name;
    }
    return '所有账簿';
  }

  String _formatDate(DateTime d) {
    return DateUtil.format(d);
  }

  String _formatLabel(DataExportFormat f) {
    switch (f) {
      case DataExportFormat.excel:
        return 'Excel 文件';
      case DataExportFormat.zip:
        return 'ZIP 文件';
    }
  }

  Future<void> _pickBook(AppDatabase db, List<AccountBook> books) async {
    const allKey = '__all__';
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '选择账簿',
                  style: AppTypography.h2().copyWith(fontSize: 16),
                ),
              ),
              ListTile(
                title: const Text('所有账簿'),
                trailing: _selectedBookId == null
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(allKey),
              ),
              for (final b in books)
                ListTile(
                  title: Text(b.name),
                  trailing: _selectedBookId == b.bookId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(b.bookId),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    final nextBookId = picked == allKey ? null : picked;
    final minMax = _allTime
        ? await _minMaxRecordDate(db, bookId: nextBookId)
        : null;
    if (!mounted) return;
    setState(() {
      _selectedBookId = nextBookId;
      _lastExportFile = null;
      if (minMax != null) {
        _start = minMax.$1;
        _end = minMax.$2;
      }
    });
  }

  Future<void> _pickFormat() async {
    final picked = await showModalBottomSheet<DataExportFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '选择文件格式',
                  style: AppTypography.h2().copyWith(fontSize: 16),
                ),
              ),
              ListTile(
                title: const Text('Excel 文件'),
                trailing: _format == DataExportFormat.excel
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(DataExportFormat.excel),
              ),
              ListTile(
                title: const Text('ZIP 文件'),
                trailing: _format == DataExportFormat.zip
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(DataExportFormat.zip),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _format = picked;
      _lastExportFile = null;
    });
  }

  Future<void> _pickDateRange(AppDatabase db) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '日期范围',
                  style: AppTypography.h2().copyWith(fontSize: 16),
                ),
              ),
              ListTile(
                title: const Text('所有时间'),
                trailing: _allTime ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop('all'),
              ),
              ListTile(
                title: const Text('自定义时间'),
                trailing: !_allTime ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop('custom'),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (!mounted) return;

    if (picked == 'all') {
      final minMax = await _minMaxRecordDate(db, bookId: _selectedBookId);
      setState(() {
        _allTime = true;
        _start = minMax.$1;
        _end = minMax.$2;
      });
      return;
    }

    final start = await showLunarDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (start == null) return;
    if (!mounted) return;
    final end = await showLunarDatePicker(
      context: context,
      initialDate: _end.isBefore(start) ? start : _end,
      firstDate: start,
      lastDate: DateTime(2100, 12, 31),
    );
    if (end == null) return;
    if (!mounted) return;
    setState(() {
      _allTime = false;
      _start = start;
      _end = end;
    });
  }

  Future<(DateTime, DateTime)> _minMaxRecordDate(
    AppDatabase db, {
    String? bookId,
  }) async {
    final query = db.select(db.giftRecords)..where((t) => t.deletedAt.isNull());
    if (bookId != null) {
      query.where((t) => t.bookId.equals(bookId));
    }
    final rows = await (query..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .get();
    if (rows.isEmpty) {
      final now = DateTime.now();
      final d = DateTime(now.year, now.month, now.day);
      return (d, d);
    }
    var min = DateTime.fromMillisecondsSinceEpoch(rows.first.occurredAt);
    var max = min;
    for (final r in rows) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.occurredAt);
      if (dt.isBefore(min)) min = dt;
      if (max.isBefore(dt)) max = dt;
    }
    final s = DateTime(min.year, min.month, min.day);
    final e = DateTime(max.year, max.month, max.day);
    return (s, e);
  }

  void _ensureAllTimeRangeInitialized(AppDatabase db) {
    if (!_allTime) return;
    if (_allTimeRangeInitialized) return;
    _allTimeRangeInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final minMax = await _minMaxRecordDate(db, bookId: _selectedBookId);
      setState(() {
        _start = minMax.$1;
        _end = minMax.$2;
      });
    });
  }

  Future<void> _export({
    required AppSession session,
    required AppDatabase db,
  }) async {
    if (_exporting) return;
    _progressTimer?.cancel();
    setState(() {
      _exportPathVisible = true;
      _exporting = true;
      _progress = 0;
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!_exporting) {
        t.cancel();
        return;
      }
      setState(() => _progress = math.min(0.9, _progress + 0.02));
    });
    try {
      final file = await _service.exportFromDrift(
        loggedIn: session.loggedIn,
        db: db,
        request: DataExportRequest(
          format: _format,
          start: _start,
          end: _end,
          bookId: _selectedBookId,
          includeRecords: true,
          includePersons: true,
          includeImages: _format == DataExportFormat.zip,
        ),
      );
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _progress = 1;
          _lastExportFile = file;
        });
      }
      try {
        await SharePlus.instance.share(
          ShareParams(files: <XFile>[XFile(file.path)], text: '尚礼数据导出'),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导出到：${file.path}')));
      }
    } on DataExportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：$e')));
    } finally {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _shareLastFile() async {
    final file = _lastExportFile;
    if (file == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先导出文件')));
      return;
    }
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导出文件不存在，请重新导出')));
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile(file.path)], text: '尚礼数据导出'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('文件路径：${file.path}')));
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.subtitle,
    this.borderBottom = true,
  });

  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return _HoverableRow(
      onTap: onTap,
      borderBottom: borderBottom,
      child: Row(
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.base(
                      fontSize: 16,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 18, bottom: 18),
            child: Row(
              children: [
                Text(
                  value,
                  style: AppTypography.base(
                    fontSize: 16,
                    fontWeight: AppTypography.regular,
                    color: onTap == null
                        ? AppColors.gray300
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: onTap == null ? AppColors.gray300 : AppColors.gray400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverableRow extends StatefulWidget {
  const _HoverableRow({
    required this.child,
    required this.onTap,
    required this.borderBottom,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool borderBottom;

  @override
  State<_HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<_HoverableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hover = true) : null,
      onExit: enabled ? (_) => setState(() => _hover = false) : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: PrototypePressableRow(
        onTap: widget.onTap,
        pressedColor: AppColors.gray50,
        borderBottom: widget.borderBottom,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          color: _hover ? colors.surfacePressed : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

class _HintArea extends StatelessWidget {
  const _HintArea({required this.allTime});

  final bool allTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '提示：',
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.medium,
            color: AppColors.stateDangerStrong,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '如果要备份或转移数据，请使用云同步或数据备份功能，请勿通过数据导出备份数据',
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.regular,
            color: AppColors.stateDangerStrong,
            height: 1.35,
          ),
        ),
        if (allTime) ...[
          const SizedBox(height: 6),
          Text(
            '当前为所有时间导出，数据量可能较大，请耐心等待',
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.regular,
              color: AppColors.stateDangerStrong,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Excel 文件导出记录明细；图片字段仅输出本地路径',
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.regular,
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ZIP 文件导出记录并打包本地图片文件',
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.regular,
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ExportProgress extends StatelessWidget {
  const _ExportProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '正在导出...',
              style: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.medium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress <= 0 ? null : progress,
            backgroundColor: context.appColors.surfaceDisabled,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.brandSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final bg = enabled
        ? (_hover ? AppColors.indigo800 : AppColors.brandPrimary)
        : AppColors.gray300;
    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hover = true) : null,
      onExit: enabled ? (_) => setState(() => _hover = false) : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: PressableScale(
        onTap: enabled ? widget.onTap : null,
        pressedScale: 0.98,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          height: 54,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brXl,
            boxShadow: enabled ? AppShadows.brandSoft : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: AppTypography.base(
              fontSize: 18,
              fontWeight: AppTypography.medium,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
