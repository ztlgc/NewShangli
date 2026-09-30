import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/export/ledger_pdf_service.dart';

void main() {
  group('LedgerPdfService', () {
    test('computeRunningBalances 按收入/支出滚动累计', () {
      final rows = [
        LedgerPrintRow(
          occurredAt: DateTime(2025, 1, 1),
          direction: '收入',
          amountCent: 20000,
          personName: '张三',
        ),
        LedgerPrintRow(
          occurredAt: DateTime(2025, 1, 2),
          direction: '支出',
          amountCent: 5000,
          personName: '李四',
        ),
        LedgerPrintRow(
          occurredAt: DateTime(2025, 1, 3),
          direction: '收入',
          amountCent: 3000,
          personName: '王五',
        ),
      ];

      final balances = LedgerPdfService.computeRunningBalances(
        rows,
        openingBalanceCent: 10000,
      );

      expect(balances, [30000, 25000, 28000]);
    });

    test('generatePdf 输出合法 PDF（使用系统仿宋/黑体）', () async {
      const basePath = r'C:\Windows\Fonts\simfang.ttf';
      const boldPath = r'C:\Windows\Fonts\simhei.ttf';
      if (!File(basePath).existsSync() || !File(boldPath).existsSync()) {
        markTestSkipped('当前环境缺少系统 CJK 字体，跳过 PDF 冒烟测试');
        return;
      }

      final fonts = await LedgerPdfFonts.fromFiles(
        basePath: basePath,
        boldPath: boldPath,
      );
      final request = LedgerPrintRequest(
        bookName: '测试账簿',
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 12, 31),
        openingBalanceCent: 10000,
        rows: [
          LedgerPrintRow(
            occurredAt: DateTime(2025, 3, 8),
            direction: '收入',
            amountCent: 60000,
            personName: '张三',
            eventName: '婚礼',
          ),
          LedgerPrintRow(
            occurredAt: DateTime(2025, 5, 1),
            direction: '支出',
            amountCent: 10000,
            personName: '李四',
            eventName: '乔迁随礼',
          ),
        ],
      );

      final bytes = await const LedgerPdfService().generatePdf(
        request: request,
        fonts: fonts,
      );

      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
