import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 账簿打印用的单行数据。
///
/// 与数据库解耦，方便在 Drift / AppData 两条数据通道上复用。
class LedgerPrintRow {
  const LedgerPrintRow({
    required this.occurredAt,
    required this.direction,
    required this.amountCent,
    required this.personName,
    this.eventName = '',
    this.note = '',
  }) : assert(direction == '收入' || direction == '支出');

  final DateTime occurredAt;

  /// 收入 / 支出
  final String direction;

  /// 金额，单位：分
  final int amountCent;
  final String personName;
  final String eventName;
  final String note;

  bool get isIncome => direction == '收入';
}

/// 生成账簿 PDF 的请求参数。
class LedgerPrintRequest {
  const LedgerPrintRequest({
    required this.bookName,
    required this.start,
    required this.end,
    this.bookKind = '礼金账簿',
    this.openingBalanceCent = 0,
    this.rows = const <LedgerPrintRow>[],
  });

  final String bookName;

  /// 账簿种类说明，例如“三栏式明细账”。
  final String bookKind;
  final DateTime start;
  final DateTime end;

  /// 期初结余（分），用于滚动余额。
  final int openingBalanceCent;
  final List<LedgerPrintRow> rows;
}

/// 打印字体。中文账簿建议使用 仿宋(正文) + 黑体(标题/加粗) 组合。
class LedgerPdfFonts {
  const LedgerPdfFonts({required this.base, required this.bold});

  final pw.Font base;
  final pw.Font bold;

  /// 从本地 TTF 文件加载（样例工具/桌面调试用）。
  static Future<LedgerPdfFonts> fromFiles({
    required String basePath,
    required String boldPath,
  }) async {
    final baseBytes = await File(basePath).readAsBytes();
    final boldBytes = await File(boldPath).readAsBytes();
    return fromBytes(base: baseBytes, bold: boldBytes);
  }

  static LedgerPdfFonts fromBytes({
    required Uint8List base,
    required Uint8List bold,
  }) {
    return LedgerPdfFonts(
      base: pw.Font.ttf(base.buffer.asByteData()),
      bold: pw.Font.ttf(bold.buffer.asByteData()),
    );
  }
}

/// 三栏式纸质账簿样式 PDF 生成服务。
///
/// 版式说明：
/// - A4 纵向，纸张白色，网格为灰蓝细线，金额区两侧为经典红色竖线；
/// - 表头含账簿名称、账簿种类、期间、单位；
/// - 收入 / 支出 / 结余三栏，滚动结余逐笔累计；
/// - 每页有“承前页 / 过次页”结转行与本页小计；
/// - 末页输出本期收入、支出合计与期末结余；
/// - 页脚含页码与打印日期。
class LedgerPdfService {
  const LedgerPdfService({this.rowsPerPage = 32});

  /// 每页正文行数（不含表头与小计行）。
  final int rowsPerPage;

  /// 计算滚动结余（分），供页面展示与测试复用。
  static List<int> computeRunningBalances(
    List<LedgerPrintRow> rows, {
    int openingBalanceCent = 0,
  }) {
    final balances = <int>[];
    var running = openingBalanceCent;
    for (final r in rows) {
      running += r.isIncome ? r.amountCent : -r.amountCent;
      balances.add(running);
    }
    return balances;
  }

  Future<Uint8List> generatePdf({
    required LedgerPrintRequest request,
    required LedgerPdfFonts fonts,
  }) async {
    final sorted = [...request.rows]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final balances = computeRunningBalances(
      sorted,
      openingBalanceCent: request.openingBalanceCent,
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fonts.base, bold: fonts.bold),
    );

    final incomeTotal = sorted
        .where((r) => r.isIncome)
        .fold<int>(0, (sum, r) => sum + r.amountCent);
    final expenseTotal = sorted
        .where((r) => !r.isIncome)
        .fold<int>(0, (sum, r) => sum + r.amountCent);
    final closingBalance =
        request.openingBalanceCent + incomeTotal - expenseTotal;

    final chunks = _chunkRows(
      rows: sorted,
      balances: balances,
      perPage: rowsPerPage,
      openingBalanceCent: request.openingBalanceCent,
    );

    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final isFirst = i == 0;
      final isLast = i == chunks.length - 1;
      doc.addPage(
        _buildPage(
          request: request,
          fonts: fonts,
          chunk: chunk,
          pageIndex: i,
          pageCount: chunks.length,
          isFirstPage: isFirst,
          isLastPage: isLast,
          incomeTotal: incomeTotal,
          expenseTotal: expenseTotal,
          closingBalance: closingBalance,
          printDate: DateTime.now(),
        ),
      );
    }

    return doc.save();
  }

  List<_PageChunk> _chunkRows({
    required List<LedgerPrintRow> rows,
    required List<int> balances,
    required int perPage,
    required int openingBalanceCent,
  }) {
    if (rows.isEmpty) {
      return [
        _PageChunk(
          rows: const <LedgerPrintRow>[],
          balances: const <int>[],
          startIndex: 0,
          carryIn: openingBalanceCent,
          carryOut: openingBalanceCent,
        ),
      ];
    }
    final chunks = <_PageChunk>[];
    for (var i = 0; i < rows.length; i += perPage) {
      final end = math.min(i + perPage, rows.length);
      chunks.add(
        _PageChunk(
          rows: rows.sublist(i, end),
          balances: balances.sublist(i, end),
          startIndex: i,
          carryIn: i == 0 ? openingBalanceCent : balances[i - 1],
          carryOut: balances[end - 1],
        ),
      );
    }
    return chunks;
  }

  pw.Page _buildPage({
    required LedgerPrintRequest request,
    required LedgerPdfFonts fonts,
    required _PageChunk chunk,
    required int pageIndex,
    required int pageCount,
    required bool isFirstPage,
    required bool isLastPage,
    required int incomeTotal,
    required int expenseTotal,
    required int closingBalance,
    required DateTime printDate,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 34, vertical: 28),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              request: request,
              fonts: fonts,
              totalCount: request.rows.length,
            ),
            pw.SizedBox(height: 6),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildTable(
                    fonts: fonts,
                    chunk: chunk,
                    isFirstPage: isFirstPage,
                    isLastPage: isLastPage,
                    incomeTotal: incomeTotal,
                    expenseTotal: expenseTotal,
                    closingBalance: closingBalance,
                    recordCount: request.rows.length,
                  ),
                  if (isLastPage) ...[
                    pw.SizedBox(height: 8),
                    _buildSummary(
                      fonts: fonts,
                      incomeTotal: incomeTotal,
                      expenseTotal: expenseTotal,
                      closingBalance: closingBalance,
                      openingBalanceCent: request.openingBalanceCent,
                      recordCount: request.rows.length,
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            _buildFooter(
              fonts: fonts,
              bookName: request.bookName,
              pageIndex: pageIndex,
              pageCount: pageCount,
              printDate: printDate,
            ),
          ],
        );
      },
    );
  }

  pw.Widget _buildHeader({
    required LedgerPrintRequest request,
    required LedgerPdfFonts fonts,
    required int totalCount,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          request.bookName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: fonts.bold, fontSize: 16, color: _ink),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          '${request.bookKind}　|　期间：${_periodText(request.start, request.end)}　|　共 $totalCount 笔',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: fonts.base, fontSize: 9, color: _muted),
        ),
        pw.SizedBox(height: 6),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '单位：元',
            style: pw.TextStyle(font: fonts.base, fontSize: 8, color: _muted),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          height: 3,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: _red, width: 1.2),
              bottom: pw.BorderSide(color: _red, width: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTable({
    required LedgerPdfFonts fonts,
    required _PageChunk chunk,
    required bool isFirstPage,
    required bool isLastPage,
    required int incomeTotal,
    required int expenseTotal,
    required int closingBalance,
    required int recordCount,
  }) {
    final rows = <pw.TableRow>[];
    if (!isFirstPage) {
      rows.add(
        _carryRow(fonts: fonts, label: '承前页', balanceCent: chunk.carryIn),
      );
    }

    var pageIncome = 0;
    var pageExpense = 0;
    for (var i = 0; i < chunk.rows.length; i++) {
      final r = chunk.rows[i];
      if (r.isIncome) {
        pageIncome += r.amountCent;
      } else {
        pageExpense += r.amountCent;
      }
      rows.add(
        _bodyRow(
          fonts: fonts,
          index: chunk.startIndex + i + 1,
          row: r,
          balanceCent: chunk.balances[i],
        ),
      );
    }

    if (chunk.rows.isEmpty) {
      rows.add(
        pw.TableRow(
          children: [
            _cell(child: pw.SizedBox()),
            _cell(child: pw.SizedBox()),
            _cell(
              child: pw.Text(
                '本期暂无记录',
                style: pw.TextStyle(
                  font: fonts.base,
                  fontSize: 9,
                  color: _muted,
                ),
              ),
            ),
            _cell(child: pw.SizedBox()),
            _cell(child: pw.SizedBox()),
            _cell(child: pw.SizedBox(), amountLeftRule: true),
            _cell(child: pw.SizedBox()),
            _cell(child: pw.SizedBox(), amountRightRule: true),
            _cell(child: pw.SizedBox()),
          ],
        ),
      );
    }

    rows.add(
      _subtotalRow(
        fonts: fonts,
        incomeCent: pageIncome,
        expenseCent: pageExpense,
        balanceCent: chunk.carryOut,
      ),
    );

    if (isLastPage) {
      rows.add(
        _totalRow(
          fonts: fonts,
          incomeCent: incomeTotal,
          expenseCent: expenseTotal,
          balanceCent: closingBalance,
          recordCount: recordCount,
        ),
      );
    } else {
      rows.add(
        _carryRow(fonts: fonts, label: '过次页', balanceCent: chunk.carryOut),
      );
    }

    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FixedColumnWidth(56),
        2: pw.FixedColumnWidth(86),
        3: pw.FixedColumnWidth(52),
        4: pw.FixedColumnWidth(48),
        5: pw.FixedColumnWidth(48),
        6: pw.FixedColumnWidth(52),
        7: pw.FlexColumnWidth(),
      },
      border: pw.TableBorder(
        left: const pw.BorderSide(color: _rule, width: 0.6),
        right: const pw.BorderSide(color: _rule, width: 0.6),
        top: const pw.BorderSide(color: _ink, width: 1.0),
        bottom: const pw.BorderSide(color: _ink, width: 1.0),
        horizontalInside: const pw.BorderSide(color: _rule, width: 0.4),
        verticalInside: const pw.BorderSide(color: _rule, width: 0.4),
      ),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        _headerRow(fonts: fonts),
        ...rows,
      ],
    );
  }

  pw.TableRow _headerRow({required LedgerPdfFonts fonts}) {
    final style = pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: _ink);
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _headerFill),
      children: [
        _cell(
          child: pw.Text('序号', style: style, textAlign: pw.TextAlign.center),
          alignment: pw.Alignment.center,
        ),
        _cell(
          child: pw.Text('日期', style: style, textAlign: pw.TextAlign.center),
          alignment: pw.Alignment.center,
        ),
        _cell(
          child: pw.Text(
            '摘要（事由）',
            style: style,
            textAlign: pw.TextAlign.center,
          ),
          alignment: pw.Alignment.center,
        ),
        _cell(
          child: pw.Text('关系人', style: style, textAlign: pw.TextAlign.center),
          alignment: pw.Alignment.center,
        ),
        _cell(
          child: pw.Text('收入', style: style, textAlign: pw.TextAlign.center),
          alignment: pw.Alignment.center,
          amountLeftRule: true,
        ),
        _cell(
          child: pw.Text('支出', style: style, textAlign: pw.TextAlign.center),
          alignment: pw.Alignment.center,
        ),
        _cell(
          child: pw.Text('结余', style: style, textAlign: pw.TextAlign.center),
          alignment: pw.Alignment.center,
          amountRightRule: true,
        ),
        _cell(
          child: pw.Text('备注', style: style, textAlign: pw.TextAlign.center),
          alignment: pw.Alignment.center,
        ),
      ],
    );
  }

  pw.TableRow _bodyRow({
    required LedgerPdfFonts fonts,
    required int index,
    required LedgerPrintRow row,
    required int balanceCent,
  }) {
    final style = pw.TextStyle(font: fonts.base, fontSize: 8, color: _ink);
    final muted = pw.TextStyle(font: fonts.base, fontSize: 8, color: _muted);
    final moneyStyle = pw.TextStyle(font: fonts.base, fontSize: 8, color: _ink);
    return pw.TableRow(
      children: [
        _cell(
          child: pw.Text(
            '$index',
            style: muted,
            textAlign: pw.TextAlign.center,
          ),
          alignment: pw.Alignment.center,
        ),
        _cell(
          child: pw.Text(
            _dateText(row.occurredAt),
            style: style,
            textAlign: pw.TextAlign.center,
          ),
          alignment: pw.Alignment.center,
        ),
        _cell(
          child: pw.Text(
            row.eventName.isEmpty ? '礼金往来' : row.eventName,
            style: style,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ),
        _cell(child: pw.Text(row.personName, style: style, maxLines: 1)),
        _cell(
          child: pw.Text(
            row.isIncome ? _formatYuan(row.amountCent) : '',
            style: moneyStyle,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
          amountLeftRule: true,
        ),
        _cell(
          child: pw.Text(
            !row.isIncome ? _formatYuan(row.amountCent) : '',
            style: moneyStyle,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
        ),
        _cell(
          child: pw.Text(
            _formatYuan(balanceCent),
            style: moneyStyle,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
          amountRightRule: true,
        ),
        _cell(
          child: pw.Text(
            row.note,
            style: muted,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ),
      ],
    );
  }

  pw.TableRow _subtotalRow({
    required LedgerPdfFonts fonts,
    required int incomeCent,
    required int expenseCent,
    required int balanceCent,
  }) {
    final style = pw.TextStyle(font: fonts.bold, fontSize: 8, color: _ink);
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _subtotalFill),
      children: [
        _cell(child: pw.SizedBox()),
        _cell(child: pw.SizedBox()),
        _cell(child: pw.Text('本页小计', style: style)),
        _cell(child: pw.SizedBox()),
        _cell(
          child: pw.Text(
            incomeCent == 0 ? '' : _formatYuan(incomeCent),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
          amountLeftRule: true,
        ),
        _cell(
          child: pw.Text(
            expenseCent == 0 ? '' : _formatYuan(expenseCent),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
        ),
        _cell(
          child: pw.Text(
            _formatYuan(balanceCent),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
          amountRightRule: true,
        ),
        _cell(child: pw.SizedBox()),
      ],
    );
  }

  pw.TableRow _totalRow({
    required LedgerPdfFonts fonts,
    required int incomeCent,
    required int expenseCent,
    required int balanceCent,
    required int recordCount,
  }) {
    final style = pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: _ink);
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _totalFill),
      children: [
        _cell(child: pw.SizedBox()),
        _cell(child: pw.SizedBox()),
        _cell(child: pw.Text('本期合计（$recordCount 笔）', style: style)),
        _cell(child: pw.SizedBox()),
        _cell(
          child: pw.Text(
            incomeCent == 0 ? '' : _formatYuan(incomeCent),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
          amountLeftRule: true,
        ),
        _cell(
          child: pw.Text(
            expenseCent == 0 ? '' : _formatYuan(expenseCent),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
        ),
        _cell(
          child: pw.Text(
            _formatYuan(balanceCent),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
          amountRightRule: true,
        ),
        _cell(child: pw.SizedBox()),
      ],
    );
  }

  pw.TableRow _carryRow({
    required LedgerPdfFonts fonts,
    required String label,
    required int balanceCent,
  }) {
    final style = pw.TextStyle(font: fonts.bold, fontSize: 8, color: _muted);
    return pw.TableRow(
      children: [
        _cell(child: pw.SizedBox()),
        _cell(child: pw.SizedBox()),
        _cell(child: pw.Text(label, style: style)),
        _cell(child: pw.SizedBox()),
        _cell(child: pw.SizedBox(), amountLeftRule: true),
        _cell(child: pw.SizedBox()),
        _cell(
          child: pw.Text(
            _formatYuan(balanceCent),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
          alignment: pw.Alignment.centerRight,
          amountRightRule: true,
        ),
        _cell(child: pw.SizedBox()),
      ],
    );
  }

  pw.Widget _cell({
    required pw.Widget child,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    bool amountLeftRule = false,
    bool amountRightRule = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      alignment: alignment,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: amountLeftRule
              ? const pw.BorderSide(color: _red, width: 1.8)
              : pw.BorderSide.none,
          right: amountRightRule
              ? const pw.BorderSide(color: _red, width: 1.8)
              : pw.BorderSide.none,
        ),
      ),
      child: child,
    );
  }

  pw.Widget _buildSummary({
    required LedgerPdfFonts fonts,
    required int incomeTotal,
    required int expenseTotal,
    required int closingBalance,
    required int openingBalanceCent,
    required int recordCount,
  }) {
    final labelStyle = pw.TextStyle(
      font: fonts.base,
      fontSize: 8.5,
      color: _muted,
    );
    final valueStyle = pw.TextStyle(font: fonts.bold, fontSize: 9, color: _ink);
    final closingStyle = pw.TextStyle(
      font: fonts.bold,
      fontSize: 9.5,
      color: _red,
    );

    pw.Widget item(String label, String value, pw.TextStyle valueStyle) {
      return pw.Expanded(
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(label, style: labelStyle),
            pw.SizedBox(width: 4),
            pw.Text(value, style: valueStyle),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _rule, width: 0.8),
        color: _subtotalFill,
      ),
      child: pw.Row(
        children: [
          item('期初结余', _formatYuan(openingBalanceCent), valueStyle),
          item('本期收入（$recordCount 笔）', _formatYuan(incomeTotal), valueStyle),
          item('本期支出', _formatYuan(expenseTotal), valueStyle),
          item('期末结余', _formatYuan(closingBalance), closingStyle),
        ],
      ),
    );
  }

  pw.Widget _buildFooter({
    required LedgerPdfFonts fonts,
    required String bookName,
    required int pageIndex,
    required int pageCount,
    required DateTime printDate,
  }) {
    final style = pw.TextStyle(font: fonts.base, fontSize: 8, color: _muted);
    return pw.Row(
      children: [
        pw.Text(bookName, style: style),
        pw.Spacer(),
        pw.Text(
          '第 ${pageIndex + 1} 页 / 共 $pageCount 页',
          style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _ink),
        ),
        pw.Spacer(),
        pw.Text('打印日期：${_dateText(printDate)}', style: style),
      ],
    );
  }
}

class _PageChunk {
  const _PageChunk({
    required this.rows,
    required this.balances,
    required this.startIndex,
    required this.carryIn,
    required this.carryOut,
  });

  final List<LedgerPrintRow> rows;
  final List<int> balances;
  final int startIndex;
  final int carryIn;
  final int carryOut;
}

const _ink = PdfColor.fromInt(0xFF1F2937);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _rule = PdfColor.fromInt(0xFFC7CBD4);
const _red = PdfColor.fromInt(0xFFB42318);
const _headerFill = PdfColor.fromInt(0xFFF3F1EA);
const _subtotalFill = PdfColor.fromInt(0xFFF7F5EF);
const _totalFill = PdfColor.fromInt(0xFFEDEAE0);

String _dateText(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

String _periodText(DateTime start, DateTime end) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${start.year}年${two(start.month)}月${two(start.day)}日'
      ' 至 '
      '${end.year}年${two(end.month)}月${two(end.day)}日';
}

String _formatYuan(int cent) {
  final negative = cent < 0;
  final abs = cent.abs();
  final yuan = abs ~/ 100;
  final fen = (abs % 100).toString().padLeft(2, '0');
  final digits = yuan.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer.$fen';
}
