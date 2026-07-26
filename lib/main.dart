import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final _SupabaseConfig config = await _loadSupabaseConfig();

  await Supabase.initialize(url: config.url, anonKey: config.anonKey);

  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugPaintPointersEnabled = false;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Color(0x00000000)),
  );

  runApp(const NewShangliApp());
}

/// Supabase 运行时配置。
class _SupabaseConfig {
  const _SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;
}

Future<_SupabaseConfig> _loadSupabaseConfig() async {
  try {
    // 启动阶段直接从 Flutter 资源读取本地配置；如果失败则中断初始化。
    final String rawConfig = await rootBundle.loadString('supabase.local.json');
    final dynamic decoded = jsonDecode(rawConfig);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        '配置文件内容必须是 JSON 对象，并包含 "url" 与 "anonKey" 字段。',
      );
    }

    final dynamic urlValue = decoded['url'];
    final dynamic anonKeyValue = decoded['anonKey'];

    if (urlValue is! String || urlValue.trim().isEmpty) {
      throw const FormatException('配置文件缺少有效的 "url" 字段。');
    }

    if (anonKeyValue is! String || anonKeyValue.trim().isEmpty) {
      throw const FormatException('配置文件缺少有效的 "anonKey" 字段。');
    }

    final String url = urlValue.trim();
    final String anonKey = anonKeyValue.trim();
    final Uri? parsedUrl = Uri.tryParse(url);

    if (parsedUrl == null || !parsedUrl.hasScheme || parsedUrl.host.isEmpty) {
      throw const FormatException('配置文件中的 "url" 不是合法的 Supabase 服务地址。');
    }

    return _SupabaseConfig(url: url, anonKey: anonKey);
  } on FlutterError catch (error) {
    throw StateError(
      '无法加载 Supabase 配置资源文件 "supabase.local.json"：${error.message}',
    );
  } on FormatException catch (error) {
    throw StateError('Supabase 配置解析失败：${error.message}');
  } catch (error) {
    throw StateError('读取 Supabase 配置时发生未预期错误：$error');
  }
}
