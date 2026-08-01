import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

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
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
                  backgroundColor: AppColors.indigo50,
                  foregroundColor: AppColors.indigo700,
                  onPressed: () => AppNav.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '账簿数据导入',
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
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
                            child: const FaIcon(
                              FontAwesomeIcons.paste,
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
                      TextField(
                        controller: _textCtrl,
                        minLines: 12,
                        maxLines: 16,
                        decoration: InputDecoration(
                          hintText: '例如：\n王小明 500元\n李华, 800 (同事)\n赵大宝 1000',
                          hintStyle: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: context.appColors.surfaceCard,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.orange100,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.orange100,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.orange500,
                              width: 1.5,
                            ),
                          ),
                        ),
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
                            const FaIcon(
                              FontAwesomeIcons.circleInfo,
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
                        child: PrototypePrimaryButton(
                          label: _submitting ? '导入中...' : '立即解析并导入',
                          onTap: _submitting ? null : _handleImport,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: PrototypeSecondaryButton(
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
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      _toast('请先粘贴文本数据');
      return;
    }

    setState(() => _submitting = true);
    final db = AppDatabaseScope.of(context);
    try {
      final lines = text
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        _toast('未识别到有效行');
        return;
      }

      final persons = await (db.select(
        db.persons,
      )..where((t) => t.bookId.equals(widget.bookId))).get();
      final personByName = <String, Person>{
        for (final p in persons) p.name.trim(): p,
      };
      final existing = await (db.select(
        db.giftRecords,
      )..where((t) => t.bookId.equals(widget.bookId))).get();
      final book = await db.accountBooksDao.findById(widget.bookId);
      final now = DateTime.now().millisecondsSinceEpoch;
      final defaultReason = (book?.reasonType.trim().isNotEmpty ?? false)
          ? book!.reasonType.trim()
          : '粘贴导入';
      final bookTime = book?.bookTime ?? now;
      final lockByBookTime = book != null && book.isDefault != 1;
      final existedKeys = <String>{
        for (final r in existing.where((e) => e.direction == '收入'))
          '${r.personId}|${r.amountCent}',
      };

      var success = 0;
      var duplicate = 0;
      var invalid = 0;
      final duplicateRecords = <String>[];

      for (final entry in lines.asMap().entries) {
        final lineNo = entry.key + 1;
        final line = entry.value;
        final parsed = _parseLine(line);
        if (parsed == null) {
          invalid++;
          continue;
        }

        var person = personByName[parsed.name];
        if (person == null) {
          final personId = await db.personsDao.insertOne(
            PersonsCompanion.insert(
              bookId: widget.bookId,
              name: parsed.name,
              createdAt: now,
              updatedAt: now,
            ),
          );
          person = await db.personsDao.findById(personId);
          if (person == null) {
            invalid++;
            continue;
          }
          personByName[parsed.name] = person;
        }

        final key = '${person.personId}|${parsed.amountCent}';
        if (existedKeys.contains(key)) {
          duplicate++;
          duplicateRecords.add(
            '第$lineNo行：${parsed.name} ${((parsed.amountCent) / 100).toStringAsFixed(2)}元',
          );
          continue;
        }

        await db.giftRecordsDao.insertOne(
          GiftRecordsCompanion.insert(
            bookId: widget.bookId,
            personId: person.personId,
            amountCent: parsed.amountCent,
            direction: const Value('收入'),
            eventName: Value(defaultReason),
            note: Value(parsed.note),
            occurredAt: lockByBookTime
                ? bookTime
                : DateTime.now().millisecondsSinceEpoch,
            paymentMethod: const Value('未设置'),
            createdAt: now,
            updatedAt: now,
          ),
        );
        existedKeys.add(key);
        success++;
      }

      if (!mounted) return;
      final duplicateDetails = duplicateRecords.isEmpty
          ? ''
          : '\n\n重复记录：\n${duplicateRecords.take(10).join('\n')}${duplicateRecords.length > 10 ? '\n…等 ${duplicateRecords.length} 条' : ''}';
      await AppDialog.showAlert(
        context,
        title: '导入完成',
        message:
            '成功 $success 条\n重复跳过 $duplicate 条\n解析失败 $invalid 条$duplicateDetails',
        closeLabel: '确定',
      );
    } catch (e) {
      _toast('导入失败：$e');
    } finally {
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
    final amount = double.tryParse(amountText);
    if (name.isEmpty || amount == null || amount <= 0) return null;
    return _ParsedLine(
      name: name,
      amountCent: (amount * 100).round(),
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
