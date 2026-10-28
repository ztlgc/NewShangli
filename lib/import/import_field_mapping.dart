import 'import_file_reader.dart';

const importFields = <String>[
  '数据类型',
  '记录ID',
  '收支方向',
  '金额(元)',
  '事由',
  '所属账簿名称',
  '联系人ID',
  '联系人姓名',
  '联系人关系',
  '手机号',
  '发生时间',
  '备注',
  '头像文件名',
  '附件1名称',
  '附件2名称',
  '附件3名称',
  '附件4名称',
  '附件5名称',
  '所属账簿ID',
  '账簿时间',
  '账簿事由',
  '默认账簿',
  '创建时间',
  '生日',
  '纪念日',
];

const _aliases = <String, List<String>>{
  '数据类型': ['类型'],
  '记录ID': ['RID'],
  '收支方向': ['方向', '收送'],
  '金额(元)': ['金额（元）', '金额元', '金额'],
  '事由': ['事项'],
  '联系人ID': ['关系人ID', 'PID'],
  '联系人姓名': ['关系人姓名', '姓名'],
  '联系人关系': ['关系人关系', '关系'],
  '手机号': ['电话'],
  '发生时间': ['时间', '日期'],
  '头像文件名': ['头像'],
};

Map<String, String?> defaultImportMapping(List<String> headers) => {
  for (final field in importFields)
    field: [field, ...?_aliases[field]].where(headers.contains).firstOrNull,
};

String importPreviewCell(
  ImportPreview preview,
  Map<String, String?> mapping,
  List<String> row,
  String field,
) {
  final source = mapping[field];
  if (source == null || source.isEmpty) return '';
  final index = preview.headers.indexOf(source);
  return index < 0 || index >= row.length ? '' : row[index];
}

String? importMappingProblem(
  ImportPreview preview,
  Map<String, String?> mapping,
) {
  bool matched(String field) => (mapping[field] ?? '').isNotEmpty;
  final missing = <String>[];
  if (!preview.usesSeparateSheets && !matched('数据类型')) missing.add('数据类型');
  if (!matched('联系人姓名') && !matched('联系人ID')) missing.add('联系人姓名或ID');
  final records =
      preview.hasRecordSheet ||
      (!preview.hasPersonSheet &&
          preview.rows.any(
            (row) =>
                importPreviewCell(preview, mapping, row, '数据类型').trim() ==
                '礼金收支记录',
          ));
  if (records) {
    for (final field in ['收支方向', '金额(元)', '发生时间']) {
      if (!matched(field)) missing.add(field);
    }
  }
  if (missing.isNotEmpty) return '请匹配：${missing.join('、')}';
  if (!preview.usesSeparateSheets &&
      preview.rows.isNotEmpty &&
      !preview.rows.any(
        (row) => [
          '礼金收支记录',
          '联系人列表',
          '关系人列表',
        ].contains(importPreviewCell(preview, mapping, row, '数据类型').trim()),
      )) {
    return '数据类型须为“礼金收支记录”或“联系人列表”，可下载模板核对';
  }
  if (preview.rows.isEmpty && !preview.hasPersonSheet) return '文件中没有可预览的数据行';
  return null;
}
