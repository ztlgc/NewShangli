import 'dart:convert';

import 'package:drift/drift.dart';

/// 将 `List<String>` 存为 JSON 字符串，并在读取时还原。
///
/// 设计文档要求：
/// - `attachments` 字段在本地以 JSON 数组字符串存储
/// - 导出/DTO 侧以数组形式表达
class JsonStringListConverter extends TypeConverter<List<String>, String> {
  const JsonStringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final dynamic decoded = jsonDecode(fromDb);
    if (decoded is! List) {
      throw FormatException('attachments 期望为 JSON 数组', fromDb);
    }
    return decoded.map((e) => e.toString()).toList(growable: false);
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

