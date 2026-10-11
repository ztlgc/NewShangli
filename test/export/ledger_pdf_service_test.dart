import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/export/ledger_pdf_service.dart';
import 'package:newshangli/export/ledger_pdf_system_text.dart';

import '../support/preview_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadForuiPreviewFonts);
  test('金额列以负数保留支出方向，合计使用分计算', () {
    final request = LedgerPrintRequest(
      bookName: '测试账簿',
      reason: '结婚',
      bookDate: DateTime(2026, 10, 11),
      rows: [
        LedgerPrintRow(
          occurredAt: DateTime(2026),
          direction: '收入',
          amountCent: 20001,
          personName: '张三',
        ),
        LedgerPrintRow(
          occurredAt: DateTime(2026),
          direction: '支出',
          amountCent: 5002,
          personName: '李四',
        ),
      ],
    );
    expect(request.rows.last.signedAmountCent, -5002);
    expect(request.amountTotalCent, 14999);
  });

  test('竖向四列 PDF 支持多页、长备注和空记录', () async {
    for (final count in [0, 8, 46]) {
      final request = LedgerPrintRequest(
        bookName: '测试账簿',
        reason: '结婚礼金',
        bookDate: DateTime(2026, 10, 11),
        rows: [
          for (var i = 0; i < count; i++)
            LedgerPrintRow(
              occurredAt: DateTime(2026, 10, i + 1),
              direction: '收入',
              amountCent: 120001,
              personName: '张三$i',
              note: i == 2 ? '亲友祝福与备注' * 40 : '新婚祝福',
            ),
        ],
      );
      final bytes = await const LedgerPdfService().generatePdf(
        request: request,
        renderText: renderLedgerPdfSystemText,
      );
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      final pdf = latin1.decode(bytes);
      expect(pdf, isNot(contains('/FontFile')));
      expect(RegExp(r'/Subtype\s*/Image').hasMatch(pdf), isTrue);
      final pages = RegExp(r'/MediaBox\[0 0 ([\d.]+) ([\d.]+)\]')
          .allMatches(pdf)
          .toList();
      expect(pages, isNotEmpty);
      for (final page in pages) {
        expect(double.parse(page.group(1)!), closeTo(595.28, 0.1));
        expect(double.parse(page.group(2)!), closeTo(841.89, 0.1));
      }
      expect(pages.length, count == 46 ? greaterThan(1) : 1);
      final previewDirectory = Platform.environment['PDF_SYSTEM_PREVIEW_DIR'];
      if (previewDirectory != null) {
        await File('$previewDirectory/system-font-ledger-$count.pdf')
            .writeAsBytes(bytes);
      }
    }
  });
}
