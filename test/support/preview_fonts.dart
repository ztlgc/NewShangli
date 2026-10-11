import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Preview-only fonts: use real app icon assets and an explicitly supplied CJK
/// font. Never bundle a Windows system font or alter the production theme.
Future<void> loadForuiPreviewFonts() async {
  if (Platform.environment['UPDATE_FORUI_PREVIEWS'] != 'true') return;
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  final path = Platform.environment['FORUI_PREVIEW_FONT'];
  if (path == null || !File(path).existsSync()) {
    throw StateError(
      'Set FORUI_PREVIEW_FONT to a readable CJK font before updating previews.',
    );
  }
  final bytes = ByteData.sublistView(File(path).readAsBytesSync());
  for (final family in [
    'Noto Sans SC',
    'Noto Sans CJK SC',
    'sans-serif',
    'Roboto',
  ]) {
    await (FontLoader(family)..addFont(Future.value(bytes))).load();
  }
}
