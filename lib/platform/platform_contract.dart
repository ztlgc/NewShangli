import 'dart:io';
import 'dart:typed_data';

/// Plugin-free values used by pages and business services.
/// Import/media workflows require a readable local path. An adapter that receives
/// only bytes must materialize them into its temporary directory before returning.
class AppPickedFile {
  const AppPickedFile({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
  });
  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;
  String? get extension => name.contains('.') ? name.split('.').last : null;
}

class AppPickedFiles {
  const AppPickedFiles(this.files);
  final List<AppPickedFile> files;
}

abstract interface class AppPlatformAdapter {
  Future<Directory> documentsDirectory();
  Future<Directory> temporaryDirectory();
  Future<AppPickedFiles?> pickFiles({
    required List<String> allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
  });
  Future<String?> pickDirectory({String? dialogTitle});
  Future<void> shareFile(String path, {required String text});
}
