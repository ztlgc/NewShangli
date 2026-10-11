import 'dart:io';

import 'package:newshangli/export/ledger_pdf_service.dart';

/// 生成账簿打印样例 PDF（纸质账簿样式）。
///
/// 用法：
///   dart run tool/generate_ledger_sample.dart regular.ttf bold.ttf
///
/// 样例字体通过命令行指定，仅供开发工具使用，不打包到应用。
Future<void> main(List<String> args) async {
  if (args.length != 2) throw ArgumentError("Specify regular.ttf and bold.ttf");
  final fonts = await LedgerPdfFonts.fromFiles(
    basePath: args[0],
    boldPath: args[1],
  );

  final request = LedgerPrintRequest(
    bookName: '亲友礼金',
    reason: '亲友礼金往来',
    bookDate: DateTime(2025, 1, 1),
    rows: _sampleRows(),
  );

  final service = const LedgerPdfService();
  final bytes = await service.generatePdf(request: request, fonts: fonts);

  final output = File('output/pdf/尚礼_礼金账簿_样例.pdf');
  await output.create(recursive: true);
  await output.writeAsBytes(bytes, flush: true);
  stdout.writeln('PDF 已生成：${output.path}（${bytes.length} bytes）');
  final preview = LedgerPrintRequest(
    bookName: '结婚礼金',
    reason: '结婚礼金',
    bookDate: DateTime(2026, 10, 11),
    rows: [
      for (final (name, amount, note) in [
        ('王建国', 200000, '新婚祝福'),
        ('李秀英', 100000, ''),
        ('张伟', 80000, '同事'),
        ('陈静', 120000, ''),
        ('刘洋', 60000, '已回礼'),
        ('赵磊', 100000, ''),
        ('孙丽', 200000, '亲友'),
        ('周涛', 120000, ''),
      ])
        LedgerPrintRow(
          occurredAt: DateTime(2026, 10, 11),
          direction: '收入',
          amountCent: amount,
          personName: name,
          note: note,
        ),
    ],
  );
  final previewFile = File(
    'output/pdf/${preview.title}${preview.bookDate.toIso8601String().substring(0, 10)}.pdf',
  );
  await previewFile.writeAsBytes(
    await service.generatePdf(request: preview, fonts: fonts),
    flush: true,
  );
  stdout.writeln('确认版样例：${previewFile.path}');
}

class _Seed {
  const _Seed(
    this.month,
    this.day,
    this.name,
    this.event,
    this.income,
    this.amountYuan,
    this.note,
  );

  final int month;
  final int day;
  final String name;
  final String event;
  final bool income;
  final int amountYuan;
  final String note;
}

List<LedgerPrintRow> _sampleRows() {
  const seeds = <_Seed>[
    _Seed(1, 1, '王建国', '元旦红包', true, 200, '新年问候'),
    _Seed(1, 15, '李秀英', '寿宴', true, 600, ''),
    _Seed(1, 22, '张伟', '婚礼随礼', false, 1000, ''),
    _Seed(2, 2, '陈静', '春节红包', true, 500, ''),
    _Seed(2, 9, '刘洋', '春节拜年', true, 800, ''),
    _Seed(2, 18, '赵磊', '订婚宴', true, 1000, ''),
    _Seed(2, 26, '孙丽', '乔迁随礼', false, 800, ''),
    _Seed(3, 6, '周涛', '满月酒', true, 500, ''),
    _Seed(3, 14, '吴婷', '生日礼', true, 300, ''),
    _Seed(3, 21, '马超', '升学宴随礼', false, 500, ''),
    _Seed(4, 3, '黄敏', '清明祭扫', false, 300, ''),
    _Seed(4, 12, '杨帆', '婚礼', true, 1200, ''),
    _Seed(4, 19, '朱琳', '孩子满月', true, 800, ''),
    _Seed(4, 28, '胡军', '白事慰问', false, 1000, ''),
    _Seed(5, 1, '郭雪', '五一聚会红包', true, 200, ''),
    _Seed(5, 10, '林浩', '乔迁之喜', true, 1000, ''),
    _Seed(5, 17, '何洁', '婚礼随礼', false, 1200, ''),
    _Seed(5, 25, '高翔', '寿宴', true, 800, ''),
    _Seed(6, 1, '罗丹', '儿童节红包', true, 200, ''),
    _Seed(6, 9, '王芳', '婚礼', true, 2000, ''),
    _Seed(6, 18, '李娜', '满月酒随礼', false, 600, ''),
    _Seed(6, 27, '徐强', '乔迁随礼', false, 1000, ''),
    _Seed(7, 4, '陈静', '暑假走访', true, 300, ''),
    _Seed(7, 12, '刘洋', '订婚', true, 1600, ''),
    _Seed(7, 20, '孙丽', '升学宴', true, 1000, ''),
    _Seed(7, 29, '马超', '白事慰问', false, 500, ''),
    _Seed(8, 6, '吴婷', '升学红包', true, 600, ''),
    _Seed(8, 15, '赵磊', '乔迁随礼', false, 800, ''),
    _Seed(8, 24, '朱琳', '孩子周岁', true, 800, ''),
    _Seed(9, 1, '周涛', '开学红包', true, 500, ''),
    _Seed(9, 10, '黄敏', '婚礼', true, 1000, ''),
    _Seed(9, 19, '胡军', '新房暖房', true, 1200, ''),
    _Seed(9, 28, '何洁', '生日随礼', false, 300, ''),
    _Seed(10, 1, '高翔', '国庆红包', true, 500, ''),
    _Seed(10, 8, '张伟', '婚礼', true, 1000, ''),
    _Seed(10, 16, '李秀英', '寿宴随礼', false, 800, ''),
    _Seed(10, 25, '林浩', '满月酒', true, 600, ''),
    _Seed(11, 2, '郭雪', '乔迁随礼', false, 1000, ''),
    _Seed(11, 11, '王建国', '生日礼', true, 500, ''),
    _Seed(11, 20, '罗丹', '婚礼', true, 1500, ''),
    _Seed(11, 29, '杨帆', '白事慰问', false, 600, ''),
    _Seed(12, 5, '王芳', '孩子周岁', true, 800, ''),
    _Seed(12, 13, '李娜', '婚礼', true, 2000, ''),
    _Seed(12, 21, '徐强', '冬至探望', true, 300, ''),
    _Seed(12, 25, '陈静', '圣诞红包', true, 200, ''),
    _Seed(12, 31, '刘洋', '跨年红包', true, 600, ''),
  ];

  return [
    for (final s in seeds)
      LedgerPrintRow(
        occurredAt: DateTime(2025, s.month, s.day),
        direction: s.income ? '收入' : '支出',
        amountCent: s.amountYuan * 100,
        personName: s.name,
        eventName: s.event,
        note: s.note,
      ),
  ];
}
