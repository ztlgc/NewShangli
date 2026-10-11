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
    final List<PlatformFile> result;
    if (allowMultiple) {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
    } else {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      result = file == null ? [] : [file];
    }
    if (result.isEmpty) return null;
    final files = <AppPickedFile>[];
    for (final file in result) {
      var localPath = file.path;
      final bytes = withData || localPath == null
          ? await file.readAsBytes()
          : null;
      if (localPath == null) {
        final directory = await (await temporaryDirectory()).createTemp(
          'picked_',
        );
        final safeName = file.name.replaceAll(
          RegExp(r'[<>:"/\\|?*\x00-\x1f]'),
          '_',
        );
        final local = File(
          '${directory.path}/${safeName.isEmpty ? 'file' : safeName}',
        );
        await local.writeAsBytes(bytes!, flush: true);
        localPath = local.path;
      }
      files.add(
        AppPickedFile(
          name: file.name,
          size: bytes?.length ?? await file.length() ?? 0,
          path: localPath,
          bytes: withData ? bytes : null,
        ),
      );
    }
    return AppPickedFiles(List.unmodifiable(files));
  }

  @override
  Future<String?> pickDirectory({String? dialogTitle}) =>
      FilePicker.getDirectoryPath(dialogTitle: dialogTitle);
  @override
  Future<void> shareFile(String path, {required String text}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: text),
    );
  }
}
