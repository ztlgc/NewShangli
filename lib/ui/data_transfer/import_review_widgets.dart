import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../import/data_import_service.dart';
import '../../import/import_field_mapping.dart';
import '../../import/import_file_reader.dart';
import '../../import/import_value_codec.dart';
import '../../platform/app_platform.dart';
import '../../stats/stats_models.dart';
import '../app_bottom_sheet.dart';
import '../app_icons.dart';
import '../app_tokens.dart';
import '../components.dart';
import 'transfer_widgets.dart';

class ImportFileCard extends StatelessWidget {
  const ImportFileCard({
    super.key,
    this.file,
    required this.loading,
    required this.templateBusy,
    this.onPick,
    this.onTemplate,
  });
  final AppPickedFile? file;
  final bool loading;
  final bool templateBusy;
  final VoidCallback? onPick;
  final VoidCallback? onTemplate;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: FButton.raw(
            variant: .ghost,
            onPress: onPick,
            semanticsLabel: '选择导入文件',
            child: Row(
              children: [
                if (loading)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  const TransferIconWell(icon: AppIcons.fileSpreadsheet),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: file?.name ?? '点击选择 Excel 或 CSV 文件',
                        child: transferText(
                          context,
                          file?.name ?? '点击选择 Excel 或 CSV 文件',
                          14,
                          weight: FontWeight.w600,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      transferText(
                        context,
                        loading
                            ? '正在读取文件…'
                            : file == null
                            ? '单个文件不超过 32 MB'
                            : '${file!.extension?.toUpperCase() ?? '表格'} 文件 · ${transferFileSize(file!.size)}',
                        11,
                        color: context.appColors.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                transferText(context, file == null ? '选择' : '更换', 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: transferText(
                context,
                '支持 Excel / CSV',
                11,
                color: context.appColors.textTertiary,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: FButton.raw(
                variant: .ghost,
                onPress: onTemplate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.arrowDown, size: 13),
                    const SizedBox(width: 4),
                    transferText(context, templateBusy ? '生成中…' : '下载模板', 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class ImportMappingCard extends StatelessWidget {
  const ImportMappingCard({
    super.key,
    required this.preview,
    required this.mapping,
    required this.onEdit,
  });
  final ImportPreview preview;
  final Map<String, String?> mapping;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final problem = importMappingProblem(preview, mapping);
    final count = mapping.values.where((v) => (v ?? '').isNotEmpty).length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TransferHeading(
            title: '字段匹配',
            detail: '已匹配 $count 项',
            onTap: onEdit,
            detailColor: problem == null
                ? context.appColors.stateSuccess
                : context.appColors.stateWarning,
          ),
          for (final field in ['联系人姓名', '金额(元)', '发生时间'])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: transferText(
                      context,
                      field,
                      12,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  Icon(
                    AppIcons.arrowLeft,
                    size: 12,
                    color: context.appColors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: transferText(
                        context,
                        mapping[field] == '' ? '不导入' : mapping[field] ?? '未匹配',
                        12,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (problem != null) ...[
            const SizedBox(height: 8),
            transferText(
              context,
              problem,
              11,
              color: context.appColors.stateWarning,
            ),
          ],
        ],
      ),
    );
  }
}

class ImportPreviewCard extends StatelessWidget {
  const ImportPreviewCard({
    super.key,
    required this.preview,
    required this.mapping,
    required this.onOpen,
  });
  final ImportPreview preview;
  final Map<String, String?> mapping;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        TransferHeading(
          title: '数据预览',
          detail: '前 ${preview.rows.length} 行',
          onTap: onOpen,
        ),
        _row(context, ['姓名', '收送', '金额', '日期'], header: true),
        Divider(height: 1, color: context.appColors.borderSubtle),
        if (preview.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: transferText(
              context,
              '当前工作表没有数据行',
              12,
              color: context.appColors.textTertiary,
            ),
          ),
        for (final row in preview.rows.take(2)) ...[
          _row(context, _values(row)),
          Divider(height: 1, color: context.appColors.borderSubtle),
        ],
      ],
    ),
  );

  List<String> _values(List<String> row) {
    String cell(String field) =>
        importPreviewCell(preview, mapping, row, field).trim();
    final date = ImportValueCodec.date(cell('发生时间'));
    final amount = ImportValueCodec.amountCent(cell('金额(元)'));
    return [
      cell('联系人姓名').isEmpty ? cell('联系人ID') : cell('联系人姓名'),
      switch (cell('收支方向')) {
        '收入' || '收礼' => '收礼',
        '支出' || '送礼' => '送礼',
        final value => value,
      },
      amount == null ? cell('金额(元)') : formatCentToYuan(amount).substring(1),
      date == null
          ? cell('发生时间')
          : '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
    ];
  }

  Widget _row(
    BuildContext context,
    List<String> values, {
    bool header = false,
  }) => Padding(
    padding: EdgeInsets.symmetric(vertical: header ? 5 : 8),
    child: Row(
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            flex: i == 1 ? 2 : 3,
            child: Align(
              alignment: i < 2 ? Alignment.centerLeft : Alignment.centerRight,
              child: Tooltip(
                message: values[i],
                child: transferText(
                  context,
                  values[i].isEmpty ? '—' : values[i],
                  header ? 11 : 12,
                  maxLines: 2,
                  weight: !header && i == 2 ? FontWeight.w600 : FontWeight.w400,
                  color: header || i == 3
                      ? context.appColors.textTertiary
                      : i == 1 && values[i] == '收礼'
                      ? context.appColors.stateSuccess
                      : i == 1 && values[i] == '送礼'
                      ? context.appColors.stateDanger
                      : context.appColors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class ImportMediaCard extends StatelessWidget {
  const ImportMediaCard({super.key, this.file, this.onPick, this.onRemove});
  final AppPickedFile? file;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Expanded(
          child: FButton.raw(
            variant: .ghost,
            onPress: onPick,
            semanticsLabel: '选择媒体 ZIP 文件（可选）',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Icon(
                    AppIcons.packageOpen,
                    size: 20,
                    color: context.appColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        transferText(
                          context,
                          '头像与附件',
                          13,
                          weight: FontWeight.w600,
                        ),
                        const SizedBox(height: 3),
                        transferText(
                          context,
                          file == null ? '选择配套图片 ZIP，可选' : file!.name,
                          11,
                          color: context.appColors.textTertiary,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  if (file == null)
                    Icon(
                      AppIcons.chevronRight,
                      size: 15,
                      color: context.appColors.textTertiary,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (file != null)
          SizedBox(
            width: 44,
            height: 44,
            child: FButton.icon(
              variant: .ghost,
              semanticsLabel: '移除图片 ZIP',
              onPress: onRemove,
              child: const Icon(AppIcons.x, size: 16),
            ),
          ),
      ],
    ),
  );
}

class ImportMappingSheet extends StatefulWidget {
  const ImportMappingSheet({
    super.key,
    required this.headers,
    required this.mapping,
  });
  final List<String> headers;
  final Map<String, String?> mapping;
  @override
  State<ImportMappingSheet> createState() => _ImportMappingSheetState();
}

class _ImportMappingSheetState extends State<ImportMappingSheet> {
  late final _draft = Map<String, String?>.from(widget.mapping);
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.7,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: transferText(
            context,
            '选择文件中的对应列；未设置的可选字段使用文件原有列名。',
            12,
            color: context.appColors.textSecondary,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: importFields.length,
            itemBuilder: (context, index) {
              final field = importFields[index];
              return AppPressableRow(
                key: ValueKey('import_mapping_$field'),
                onTap: () async {
                  final picked = await AppBottomSheet.showPicker<String>(
                    context,
                    title: field,
                    options: [
                      AppSheetOption(
                        label: '不导入',
                        value: '',
                        selected: _draft[field] == '',
                      ),
                      for (final header in widget.headers)
                        AppSheetOption(
                          label: header,
                          value: header,
                          selected: _draft[field] == header,
                        ),
                    ],
                  );
                  if (picked != null && mounted) {
                    setState(() => _draft[field] = picked);
                  }
                },
                child: Row(
                  children: [
                    Expanded(child: transferText(context, field, 13)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: transferText(
                        context,
                        _draft[field] == '' ? '不导入' : _draft[field] ?? '未设置',
                        12,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      AppIcons.chevronRight,
                      size: 14,
                      color: context.appColors.textTertiary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppPrimaryButton(
            label: '应用匹配',
            onTap: () => Navigator.of(context).pop(_draft),
          ),
        ),
      ],
    ),
  );
}

class ImportPreviewSheet extends StatelessWidget {
  const ImportPreviewSheet({super.key, required this.preview});
  final ImportPreview preview;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.7,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: transferText(
            context,
            '仅预览前 ${preview.rows.length} 行，导入时逐行检查数据。左右滑动查看全部列。',
            12,
            color: context.appColors.textSecondary,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: AppTypography.base(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
                dataTextStyle: AppTypography.base(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: context.appColors.textSecondary,
                ),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 72,
                columns: [
                  for (final header in preview.headers)
                    DataColumn(label: Text(header)),
                ],
                rows: [
                  for (final row in preview.rows)
                    DataRow(
                      cells: [
                        for (var i = 0; i < preview.headers.length; i++)
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Tooltip(
                                message: i < row.length ? row[i] : '',
                                child: Text(
                                  i < row.length ? row[i] : '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
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

String importStatusLabel(DataImportStatus status) => switch (status) {
  DataImportStatus.pending => '等待导入',
  DataImportStatus.running => '导入中',
  DataImportStatus.paused => '已暂停',
  DataImportStatus.completed => '导入完成',
  DataImportStatus.failed => '导入中断',
  DataImportStatus.canceled => '已取消',
};

class ImportResultCard extends StatelessWidget {
  const ImportResultCard({
    super.key,
    required this.progress,
    this.onDetails,
    this.controlHint,
  });
  final DataImportProgress? progress;
  final VoidCallback? onDetails;
  final String? controlHint;
  @override
  Widget build(BuildContext context) {
    final current = progress;
    final status = current?.status ?? DataImportStatus.pending;
    final active =
        status == DataImportStatus.running ||
        status == DataImportStatus.pending;
    final color = status == DataImportStatus.completed
        ? context.appColors.stateSuccess
        : status == DataImportStatus.failed
        ? context.appColors.stateDanger
        : context.appColors.textPrimary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TransferHeading(
            title: controlHint ?? importStatusLabel(status),
            detail: onDetails == null ? null : '查看详情',
            detailColor: color,
            onTap: onDetails,
          ),
          if (active) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 4),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final (label, count) in [
                ('成功', current?.successRows ?? 0),
                ('跳过', current?.skippedRows ?? 0),
                ('失败', current?.failedRows ?? 0),
              ])
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    transferText(
                      context,
                      '$count',
                      22,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 3),
                    transferText(
                      context,
                      label,
                      12,
                      color: context.appColors.textSecondary,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          transferText(
            context,
            '已处理 ${current?.processedRows ?? 0} 行',
            12,
            color: context.appColors.textTertiary,
          ),
          if (status == DataImportStatus.paused ||
              status == DataImportStatus.failed ||
              status == DataImportStatus.canceled) ...[
            const SizedBox(height: 8),
            transferText(
              context,
              status == DataImportStatus.canceled
                  ? '已提交的数据保留；本任务已取消。'
                  : '已提交的数据保留，可从断点继续。',
              12,
              color: context.appColors.textSecondary,
            ),
          ],
          if (status == DataImportStatus.completed &&
              (current?.failedRows ?? 0) > 0) ...[
            const SizedBox(height: 8),
            transferText(
              context,
              '部分行未导入，请查看处理详情。',
              12,
              color: context.appColors.stateWarning,
            ),
          ],
        ],
      ),
    );
  }
}
