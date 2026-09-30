import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'ledger_pdf_service.dart';

/// 从应用 assets 加载打印字体，供 App 内“导出/打印账簿 PDF”使用。
///
/// 注意：
/// - 需要把开源中文字体（TTF 格式，如 Noto Sans SC）放入 assets；
/// - pdf 包基于 TrueType 解析器，请使用 .ttf 而非 CFF 轮廓的 .otf；
/// - 首次加载后可缓存 [LedgerPdfFonts] 实例，避免重复解析字体。
Future<LedgerPdfFonts> loadLedgerPdfFontsFromAssets({
  String baseAsset = 'assets/fonts/NotoSansSC-Regular.ttf',
  String boldAsset = 'assets/fonts/NotoSansSC-Bold.ttf',
}) async {
  final baseData = await rootBundle.load(baseAsset);
  final boldData = await rootBundle.load(boldAsset);
  return LedgerPdfFonts.fromBytes(
    base: _byteDataToUint8List(baseData),
    bold: _byteDataToUint8List(boldData),
  );
}

Uint8List _byteDataToUint8List(ByteData data) =>
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
