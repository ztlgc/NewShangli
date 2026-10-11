import 'dart:io';

import 'flutter_platform_adapter.dart';
import 'platform_contract.dart';

export 'platform_contract.dart';

/// Register a new platform adapter here; domain data and UI stay unchanged.
abstract final class AppPlatform {
  static AppPlatformAdapter instance = const FlutterPlatformAdapter();
  static Future<Directory> documentsDirectory() =>
      instance.documentsDirectory();
  static Future<Directory> temporaryDirectory() =>
      instance.temporaryDirectory();
}
