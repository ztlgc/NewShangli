import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:pdf/widgets.dart' as pw;

/// Render with the device's font fallback, without bundled or downloaded fonts.
/// Three pixels per PDF point keep Chinese text clear when printed.
Future<pw.Widget> renderLedgerPdfSystemText(
  String text,
  double size,
  bool bold,
  double maxWidth,
) async {
  if (text.isEmpty) return pw.SizedBox();
  const scale = 3.0;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0xff000000),
        fontFamily: 'sans-serif',
        fontSize: size,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        height: 1.25,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  ui.Picture? picture;
  ui.Image? image;
  try {
    painter.layout(maxWidth: maxWidth);
    final width = (painter.width * scale).ceil().clamp(1, 10000);
    final height = (painter.height * scale).ceil().clamp(1, 30000);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    painter.paint(canvas, Offset.zero);
    picture = recorder.endRecording();
    image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('无法生成 PDF 文字');
    return pw.Image(
      pw.MemoryImage(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
      width: width / scale,
      height: height / scale,
    );
  } finally {
    image?.dispose();
    picture?.dispose();
    painter.dispose();
  }
}
