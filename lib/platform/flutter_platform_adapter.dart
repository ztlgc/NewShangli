import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'platform_contract.dart';

/// Android/current Flutter implementation. Only this adapter depends on plugins.
class FlutterPlatformAdapter implements AppPlatformAdapter {
  const FlutterPlatformAdapter();
  @override
  Future<Directory> documentsDirectory() => getApplicationDocumentsDirectory();
  @override
  Future<Directory> temporaryDirectory() => getTemporaryDirectory();
  @override
  Future<AppPickedFiles?> pickFiles({
    required List<String> allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
      withData: withData,
    );
    if (result == null) return null;
    return AppPickedFiles(
      List.unmodifiable(
        result.files.map(
          (file) => AppPickedFile(
            name: file.name,
            size: file.size,
            path: file.path,
            bytes: file.bytes,
          ),
        ),
      ),
    );
  }

  @override
  Future<String?> pickDirectory({String? dialogTitle}) =>
      FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);
  @override
  Future<void> shareFile(String path, {required String text}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: text),
    );
  }
}
