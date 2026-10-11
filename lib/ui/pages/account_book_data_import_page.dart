import 'dart:io';

import '../../import/data_import_service.dart';
import '../../import/import_value_codec.dart';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../navigation.dart';
import '../ui_kit.dart';

import '../app_icons.dart';

import '../../platform/app_platform.dart';

import '../app_layout.dart';

class AccountBookDataImportPage extends StatefulWidget {
  const AccountBookDataImportPage({
    super.key,
    required this.bookId,
    required this.bookName,
  });

  final String bookId;
  final String bookName;

  @override
  State<AccountBookDataImportPage> createState() =>
      _AccountBookDataImportPageState();
}

class _AccountBookDataImportPageState extends State<AccountBookDataImportPage> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          AppTopBar(
            title: '账簿数据导入',
            left: AppIconButton(
              icon: const Icon(AppIcons.arrowLeft, size: 16),
              backgroundColor: AppColors.indigo50,
              foregroundColor: AppColors.indigo700,
              onPressed: () => AppNav.pop(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Container(
                  padding: AppLayout.pagePadding,
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceCard,
                    borderRadius: AppRadii.br2xl,
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.orange100,
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              AppIcons.clipboardPaste,
                              size: 20,
                              color: AppColors.orange600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '粘贴您的账簿数据',
                              style: AppTypography.base(
                                fontSize: 20,
                                fontWeight: AppTypography.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '请将备份文本、礼金清单或账目明细粘贴到下方输入框，系统会解析姓名与金额并做重复检查。',
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '账簿文本数据',
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.semibold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FTextField(
                        control: FTextFieldControl.managed(
                          controller: _textCtrl,
                        ),
                        minLines: 12,
                        maxLines: 16,
                        hint: '例如：\n王小明 500元\n李华, 800 (同事)\n赵大宝 1000',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.orange100.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.orange100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              AppIcons.info,
                              size: 14,
                              color: AppColors.orange600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '导入前请确认姓名与金额清晰。解析后将自动写入当前账簿：${widget.bookName}。',
                                style: AppTypography.base(
                                  fontSize: 12,
                                  fontWeight: AppTypography.regular,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: AppPrimaryButton(
                          label: _submitting ? '导入中...' : '立即解析并导入',
                          onTap: _submitting ? null : _handleImport,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: AppSecondaryButton(
                          label: '查看支持的格式范例',
                          onTap: _showExamples,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExamples() async {
    await AppDialog.showAlert(
      context,
      title: '格式范例',
      message:
          '支持以下格式：\n\n'
          '1) 王小明 500\n'
          '2) 李华, 800\n'
          '3) 赵大宝 1000元\n'
          '4) 王芳 666 (同学)\n'
          '5) 刘强,1200（客户）',
    );
  }

  Future<void> _handleImport() async {
    if (_submitting) return;
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      _toast('请先粘贴文本数据');
      return;
    }
    setState(() => _submitting = true);
    final db = AppDatabaseScope.of(context);
    File? temporary;
    try {
      final book = await db.accountBooksDao.findById(widget.bookId);
      if (book == null || book.deletedAt != null) throw StateError('账簿已删除');
      final today = DateTime.now();
      final date = book.isDefault != 1
          ? DateTime.fromMillisecondsSinceEpoch(book.bookTime)
          : DateTime(today.year, today.month, today.day);
      final rows = <List<String>>[
        ['数据类型', '联系人姓名', '金额(元)', '收支方向', '事由', '发生时间', '备注'],
      ];
      final invalidLines = <int>[];
      final lines = text.split(RegExp(r'\r?\n'));
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        final parsed = _parseLine(lines[i]);
        if (parsed == null) {
          invalidLines.add(i + 1);
          continue;
        }
        rows.add([
          '礼金收支记录',
          parsed.name,
          '${parsed.amountCent ~/ 100}.${(parsed.amountCent % 100).toString().padLeft(2, '0')}',
          '收入',
          book.reasonType.isEmpty ? '粘贴导入' : book.reasonType,
          date.toIso8601String(),
          parsed.note ?? '',
        ]);
      }
      if (invalidLines.isNotEmpty) {
        throw FormatException('以下行无法识别，请修正后重试：${invalidLines.join('、')}');
      }
      if (rows.length == 1) throw const FormatException('未识别到有效行');
      String cell(String value) => '"${value.replaceAll('"', '""')}"';
      final directory = await AppPlatform.temporaryDirectory();
      temporary = File(
        '${directory.path}${Platform.pathSeparator}shangli_paste_${db.newId()}.csv',
      );
      await temporary.writeAsString(
        rows.map((row) => row.map(cell).join(',')).join('\r\n'),
        flush: true,
      );
      final service = DataImportService(db: db);
      final id = await service.createJob(
        bookId: widget.bookId,
        sourceFilePath: temporary.path,
        kind: DataImportKind.recordsOnly,
      );
      final handle = await service.start(
        id,
        onDuplicate: (duplicate) async {
          if (!mounted) throw const DataImportException('页面已退出');
          return await AppDialog.confirm(
                context,
                title: '疑似重复记录',
                message:
                    '${duplicate.personName}，收入 ${(duplicate.amountCent / 100).toStringAsFixed(2)} 元。是否保留为新记录？',
                confirmLabel: '保留',
                cancelLabel: '跳过',
              ) ==
              true;
        },
      );
      final result = await handle.progress.last;
      if (!mounted) return;
      await AppDialog.showAlert(
        context,
        title: result.status == DataImportStatus.completed ? '导入完成' : '导入未完成',
        message:
            '写入 ${result.successRows} 个数据项（含新联系人）\n跳过 ${result.skippedRows} 行\n失败 ${result.failedRows} 行。可在文件导入的历史中查看日志。',
      );
    } catch (e) {
      _toast('导入失败：$e');
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (mounted) setState(() => _submitting = false);
    }
  }

  _ParsedLine? _parseLine(String raw) {
    final line = raw.trim();
    final p1 = RegExp(
      r'^\s*(.+?)\s*[,，]\s*([+-]?\d+(?:\.\d{1,2})?)\s*(?:元|块|RMB|rmb|¥|￥)?\s*(?:[（(](.*?)[）)])?\s*$',
    );
    final p2 = RegExp(
      r'^\s*(.+?)\s+([+-]?\d+(?:\.\d{1,2})?)\s*(?:元|块|RMB|rmb|¥|￥)?\s*(?:[（(](.*?)[）)])?\s*$',
    );
    final m = p1.firstMatch(line) ?? p2.firstMatch(line);
    if (m == null) return null;
    final name = (m.group(1) ?? '').trim();
    final amountText = (m.group(2) ?? '').replaceAll(',', '');
    final note = (m.group(3) ?? '').trim();
    final amount = ImportValueCodec.amountCent(amountText);
    if (name.isEmpty || amount == null || amount <= 0) return null;
    return _ParsedLine(
      name: name,
      amountCent: amount,
      note: note.isEmpty ? null : note,
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    AppNotifier.info(context, msg);
  }
}

class _ParsedLine {
  const _ParsedLine({
    required this.name,
    required this.amountCent,
    required this.note,
  });

  final String name;
  final int amountCent;
  final String? note;
}
