import 'package:flutter/services.dart';

import '../update/app_version.dart';

abstract interface class AppUpdatePlatform {
  Future<AppVersion> installedVersion();
  Future<bool> openRelease(Uri uri);
}

/// Android reads the original Flutter build number, before split-per-ABI adds
/// its offset to versionCode. Platform calls stay outside the update UI/service.
class AndroidAppUpdatePlatform implements AppUpdatePlatform {
  const AndroidAppUpdatePlatform();

  static const channel = MethodChannel('liji/app_update');

  @override
  Future<AppVersion> installedVersion() async {
    final info = await channel.invokeMapMethod<String, String>(
      'installedVersion',
    );
    final version = info?['version'];
    final build = info?['build'];
    if (version == null || build == null) {
      throw const FormatException('无法读取应用版本');
    }
    return AppVersion.parse('$version+$build');
  }

  @override
  Future<bool> openRelease(Uri uri) async =>
      await channel.invokeMethod<bool>('openRelease', uri.toString()) ?? false;
}
