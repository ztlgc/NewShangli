import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  final String direction;
  final int amountCent;
  final String personName;
  final String eventName;
  final String note;
  bool get isIncome => direction == '收入';
  int get signedAmountCent => isIncome ? amountCent : -amountCent;
}

class LedgerPrintRequest {
  const LedgerPrintRequest({
    required this.bookName,
    required this.reason,
    required this.bookDate,
    this.rows = const <LedgerPrintRow>[],
  });

  final String bookName;
  String get title => '${bookName.trim()}账簿';
  final String reason;
  final DateTime bookDate;
  final List<LedgerPrintRow> rows;
  int get amountTotalCent =>
      rows.fold(0, (sum, row) => sum + row.signedAmountCent);
}

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
      base: pw.Font.ttf(ByteData.sublistView(base)),
      bold: pw.Font.ttf(ByteData.sublistView(bold)),
    );
  }
}

/// A4 竖向账簿：首页说明、四列明细、末尾合计。
class LedgerPdfService {
  const LedgerPdfService();

  Future<Uint8List> generatePdf({
    required LedgerPrintRequest request,
    LedgerPdfFonts? fonts,
    Future<pw.Widget> Function(String, double, bool, double)? renderText,
  }) async {
    final rows = [...request.rows]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    assert(fonts != null || renderText != null);
    final rendered = <String, pw.Widget>{};
    String key(String text, double size, bool bold, double width) =>
        '$text|$size|$bold|$width';
    Future<void> prepare(
      String text,
      double size,
      bool bold,
      double width,
    ) async {
      if (renderText == null) return;
      final id = key(text, size, bold, width);
      rendered[id] ??= await renderText(text, size, bold, width);
    }

    const pageWidth = 539.28;
    await prepare(request.title, 28, true, pageWidth);
    await prepare(request.title, 18, true, pageWidth);
    await prepare('事由：${request.reason}', 12, false, 340);
    await prepare('日期：${_dateText(request.bookDate)}', 12, false, 175);
    await prepare(
      '记录数量：${rows.length} 笔    金额合计：${_formatYuan(request.amountTotalCent)} 元',
      12,
      false,
      pageWidth,
    );
    const widths = [33.928, 98.6416, 109.4272, 217.2832];
    final labels = ['序号', '名字', '金额（元）', '备注'];
    for (var i = 0; i < 4; i++) {
      await prepare(labels[i], 13, true, widths[i]);
    }
    for (var i = 0; i < rows.length; i++) {
      final values = [
        '${i + 1}',
        rows[i].personName,
        _formatYuan(rows[i].signedAmountCent),
        rows[i].note,
      ];
      for (var col = 0; col < 4; col++) {
        await prepare(values[col], 12, false, widths[col]);
      }
    }
    await prepare('合计', 13, true, 152.5696);
    await prepare(_formatYuan(request.amountTotalCent), 13, true, widths[2]);
    await prepare('', 12, false, widths[3]);
    pw.Widget text(
      String value,
      pw.TextStyle style,
      double width, {
      bool bold = false,
      pw.TextAlign? align,
    }) {
      if (renderText != null) {
        return rendered[key(value, style.fontSize!, bold, width)]!;
      }
      return pw.Text(value, style: style, textAlign: align);
    }

    pw.Widget cell(
      String value,
      pw.TextStyle style,
      int col, {
      bool bold = false,
      pw.Alignment alignment = pw.Alignment.centerLeft,
      double? width,
    }) => pw.Container(
      constraints: const pw.BoxConstraints(minHeight: 36),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: alignment,
      child: text(value, style, width ?? widths[col], bold: bold),
    );
    final doc = pw.Document(
      theme: fonts == null
          ? null
          : pw.ThemeData.withFont(base: fonts.base, bold: fonts.bold),
    );
    final normal = pw.TextStyle(font: fonts?.base, fontSize: 12, color: _ink);
    final bold = pw.TextStyle(font: fonts?.bold, fontSize: 13, color: _ink);
    final border = pw.BorderSide(color: _rule, width: 0.6);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        maxPages: 10000,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: text(
                request.title,
                pw.TextStyle(
                  font: fonts?.bold,
                  fontSize: context.pageNumber == 1 ? 28 : 18,
                  color: _ink,
                ),
                pageWidth,
                bold: true,
                align: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 10),
            if (context.pageNumber == 1) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: text('事由：${request.reason}', normal, 340)),
                  pw.SizedBox(width: 24),
                  text('日期：${_dateText(request.bookDate)}', normal, 175),
                ],
              ),
              pw.SizedBox(height: 8),
              text(
                '记录数量：${rows.length} 笔    金额合计：${_formatYuan(request.amountTotalCent)} 元',
                normal,
                pageWidth,
              ),
              pw.SizedBox(height: 12),
            ],
          ],
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Center(
            child: pw.Text(
              '${context.pageNumber}',
              style: normal.copyWith(fontSize: 10),
            ),
          ),
        ),
        build: (context) => [
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(10),
              1: pw.FlexColumnWidth(22),
              2: pw.FlexColumnWidth(24),
              3: pw.FlexColumnWidth(44),
            },
            border: pw.TableBorder.all(color: _rule, width: 0.6),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              pw.TableRow(
                repeat: true,
                decoration: const pw.BoxDecoration(color: _headerFill),
                children: [
                  for (var col = 0; col < labels.length; col++)
                    cell(
                      labels[col],
                      bold,
                      col,
                      bold: true,
                      alignment: pw.Alignment.center,
                    ),
                ],
              ),
              for (var i = 0; i < rows.length; i++)
                pw.TableRow(
                  children: [
                    cell('${i + 1}', normal, 0, alignment: pw.Alignment.center),
                    cell(
                      rows[i].personName,
                      normal,
                      1,
                      alignment: pw.Alignment.center,
                    ),
                    cell(
                      _formatYuan(rows[i].signedAmountCent),
                      normal,
                      2,
                      alignment: pw.Alignment.centerRight,
                    ),
                    cell(rows[i].note, normal, 3),
                  ],
                ),
            ],
          ),
          // 合计的前两列合并，金额栏与上方表格保持对齐。
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(left: border, right: border, bottom: border),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 32,
                  child: cell(
                    '合计',
                    bold,
                    0,
                    bold: true,
                    width: 152.5696,
                    alignment: pw.Alignment.center,
                  ),
                ),
                pw.Expanded(
                  flex: 24,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(left: border, right: border),
                    ),
                    child: cell(
                      _formatYuan(request.amountTotalCent),
                      bold,
                      2,
                      bold: true,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ),
                ),
                pw.Expanded(flex: 44, child: cell('', normal, 3)),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }
}

const _ink = PdfColors.black;
const _rule = PdfColor.fromInt(0xFF888888);
const _headerFill = PdfColor.fromInt(0xFFECECEC);

String _dateText(DateTime date) => '${date.year}年${date.month}月${date.day}日';

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
