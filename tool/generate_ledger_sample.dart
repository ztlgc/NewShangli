import 'dart:io';

import 'package:newshangli/export/ledger_pdf_service.dart';

/// 生成账簿打印样例 PDF（纸质账簿样式）。
///
/// 用法：
///   dart run tool/generate_ledger_sample.dart
///
/// 样例使用 Windows 自带中文字体：
/// - 仿宋 simfang.ttf 作为正文；
/// - 黑体 simhei.ttf 作为标题/加粗。
Future<void> main() async {
  final fonts = await LedgerPdfFonts.fromFiles(
    basePath: r'C:\Windows\Fonts\simfang.ttf',
    boldPath: r'C:\Windows\Fonts\simhei.ttf',
  );

  final request = LedgerPrintRequest(
    bookName: '亲友礼金账簿',
    bookKind: '三栏式明细账',
    start: DateTime(2025, 1, 1),
    end: DateTime(2025, 12, 31),
    openingBalanceCent: 880000, // 期初结余 ¥8,800.00
    rows: _sampleRows(),
  );

  final service = const LedgerPdfService(rowsPerPage: 32);
  final bytes = await service.generatePdf(request: request, fonts: fonts);

  final output = File(r'E:\NewShangli\output\pdf\尚礼_礼金账簿_样例.pdf');
  await output.create(recursive: true);
  await output.writeAsBytes(bytes, flush: true);
  stdout.writeln('PDF 已生成：${output.path}（${bytes.length} bytes）');
}

class _Seed {
  const _Seed(
    this.month,
    this.day,
    this.name,
    this.event,
    this.income,
    this.amountYuan,
    this.method,
    this.note,
  );

  final int month;
  final int day;
  final String name;
  final String event;
  final bool income;
  final int amountYuan;
  final String method;
  final String note;
}

List<LedgerPrintRow> _sampleRows() {
  const seeds = <_Seed>[
    _Seed(1, 1, '王建国', '元旦红包', true, 200, '微信', '新年问候'),
    _Seed(1, 15, '李秀英', '寿宴', true, 600, '现金', ''),
    _Seed(1, 22, '张伟', '婚礼随礼', false, 1000, '微信', ''),
    _Seed(2, 2, '陈静', '春节红包', true, 500, '现金', ''),
    _Seed(2, 9, '刘洋', '春节拜年', true, 800, '微信', ''),
    _Seed(2, 18, '赵磊', '订婚宴', true, 1000, '现金', ''),
    _Seed(2, 26, '孙丽', '乔迁随礼', false, 800, '微信', ''),
    _Seed(3, 6, '周涛', '满月酒', true, 500, '现金', ''),
    _Seed(3, 14, '吴婷', '生日礼', true, 300, '微信', ''),
    _Seed(3, 21, '马超', '升学宴随礼', false, 500, '现金', ''),
    _Seed(4, 3, '黄敏', '清明祭扫', false, 300, '现金', ''),
    _Seed(4, 12, '杨帆', '婚礼', true, 1200, '微信', ''),
    _Seed(4, 19, '朱琳', '孩子满月', true, 800, '现金', ''),
    _Seed(4, 28, '胡军', '白事慰问', false, 1000, '现金', ''),
    _Seed(5, 1, '郭雪', '五一聚会红包', true, 200, '微信', ''),
    _Seed(5, 10, '林浩', '乔迁之喜', true, 1000, '现金', ''),
    _Seed(5, 17, '何洁', '婚礼随礼', false, 1200, '微信', ''),
    _Seed(5, 25, '高翔', '寿宴', true, 800, '现金', ''),
    _Seed(6, 1, '罗丹', '儿童节红包', true, 200, '微信', ''),
    _Seed(6, 9, '王芳', '婚礼', true, 2000, '现金', ''),
    _Seed(6, 18, '李娜', '满月酒随礼', false, 600, '微信', ''),
    _Seed(6, 27, '徐强', '乔迁随礼', false, 1000, '现金', ''),
    _Seed(7, 4, '陈静', '暑假走访', true, 300, '现金', ''),
    _Seed(7, 12, '刘洋', '订婚', true, 1600, '微信', ''),
    _Seed(7, 20, '孙丽', '升学宴', true, 1000, '现金', ''),
    _Seed(7, 29, '马超', '白事慰问', false, 500, '现金', ''),
    _Seed(8, 6, '吴婷', '升学红包', true, 600, '微信', ''),
    _Seed(8, 15, '赵磊', '乔迁随礼', false, 800, '微信', ''),
    _Seed(8, 24, '朱琳', '孩子周岁', true, 800, '现金', ''),
    _Seed(9, 1, '周涛', '开学红包', true, 500, '微信', ''),
    _Seed(9, 10, '黄敏', '婚礼', true, 1000, '现金', ''),
    _Seed(9, 19, '胡军', '新房暖房', true, 1200, '现金', ''),
    _Seed(9, 28, '何洁', '生日随礼', false, 300, '微信', ''),
    _Seed(10, 1, '高翔', '国庆红包', true, 500, '微信', ''),
    _Seed(10, 8, '张伟', '婚礼', true, 1000, '现金', ''),
    _Seed(10, 16, '李秀英', '寿宴随礼', false, 800, '现金', ''),
    _Seed(10, 25, '林浩', '满月酒', true, 600, '微信', ''),
    _Seed(11, 2, '郭雪', '乔迁随礼', false, 1000, '现金', ''),
    _Seed(11, 11, '王建国', '生日礼', true, 500, '现金', ''),
    _Seed(11, 20, '罗丹', '婚礼', true, 1500, '微信', ''),
    _Seed(11, 29, '杨帆', '白事慰问', false, 600, '现金', ''),
    _Seed(12, 5, '王芳', '孩子周岁', true, 800, '现金', ''),
    _Seed(12, 13, '李娜', '婚礼', true, 2000, '微信', ''),
    _Seed(12, 21, '徐强', '冬至探望', true, 300, '现金', ''),
    _Seed(12, 25, '陈静', '圣诞红包', true, 200, '微信', ''),
    _Seed(12, 31, '刘洋', '跨年红包', true, 600, '微信', ''),
  ];

  return [
    for (final s in seeds)
      LedgerPrintRow(
        occurredAt: DateTime(2025, s.month, s.day),
        direction: s.income ? '收入' : '支出',
        amountCent: s.amountYuan * 100,
        personName: s.name,
        eventName: s.event,
        paymentMethod: s.method,
        note: s.note,
      ),
  ];
}
