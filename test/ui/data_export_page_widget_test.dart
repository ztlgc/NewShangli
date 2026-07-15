import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  test('数据导出页文案统一为数据导出与账簿术语', () async {
    final source = await File(
      'e:/NewShangli/lib/ui/pages/data_export_page.dart',
    ).readAsString();

    expect(source, contains("title: '数据导出'"));
    expect(source, contains("label: '账簿'"));
    expect(source, contains("return '所有账簿';"));
    expect(source, contains("'共\$billCount条记录'"));
    expect(source, contains("'尚礼数据导出'"));
    expect(
      source,
      contains('请勿通过数据导出备份数据'),
    );
    expect(source, contains('Excel 文件导出记录明细；图片字段仅输出本地路径'));
    expect(source, contains('ZIP 文件导出记录并打包本地图片文件'));
    expect(source, isNot(contains('账单导出')));
  });
}
