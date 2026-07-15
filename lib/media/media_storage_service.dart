import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaStorageService {
  MediaStorageService({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<String> saveAvatarFromPath(
    String sourcePath, {
    String? oldStoredPath,
  }) async {
    final ext = _normalizedExtension(sourcePath);
    final dir = await _avatarDir();
    final name = 'avatar_${DateTime.now().microsecondsSinceEpoch}$ext';
    final dest = File(p.join(dir.path, name));
    await File(sourcePath).copy(dest.path);
    await _tryDeleteStoredPath(oldStoredPath);
    return _toStoredPath(dest.path);
  }

  Future<String> saveAttachmentFromPath(String sourcePath) async {
    final ext = _normalizedExtension(sourcePath);
    final dir = await _attachmentDir();
    final name = 'att_${DateTime.now().microsecondsSinceEpoch}$ext';
    final dest = File(p.join(dir.path, name));
    await File(sourcePath).copy(dest.path);
    return _toStoredPath(dest.path);
  }

  Future<void> deleteStoredPath(String? storedPath) async {
    await _tryDeleteStoredPath(storedPath);
  }

  Future<String?> toAbsolutePath(String? storedPath) async {
    final raw = (storedPath ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return null;
    String candidate;
    if (raw.startsWith('file://')) {
      try {
        final uri = Uri.parse(raw);
        if (uri.scheme != 'file') return null;
        candidate = uri.toFilePath(windows: Platform.isWindows);
      } catch (_) {
        return null;
      }
    } else if (_isAbsolutePath(raw)) {
      candidate = raw;
    } else {
      final docs = await _documentsDirectoryProvider();
      candidate = p.join(docs.path, raw);
    }
    final normalized = p.normalize(candidate);
    if (!await _isWhitelistedMediaPath(normalized)) {
      return null;
    }
    return normalized;
  }

  Future<Directory> mediaRootDir() async {
    final docs = await _documentsDirectoryProvider();
    final dir = Directory(p.join(docs.path, 'media'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _avatarDir() async {
    final dir = Directory(p.join((await mediaRootDir()).path, 'avatars'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _attachmentDir() async {
    final dir = Directory(p.join((await mediaRootDir()).path, 'attachments'));
    await dir.create(recursive: true);
    return dir;
  }

  String _normalizedExtension(String sourcePath) {
    final ext = p.extension(sourcePath).trim().toLowerCase();
    if (ext.isEmpty || ext.length > 10) return '.bin';
    return ext;
  }

  String _toStoredPath(String absolutePath) {
    return p.normalize(absolutePath);
  }

  bool _isAbsolutePath(String path) {
    return p.isAbsolute(path) || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
  }

  Future<bool> _isWhitelistedMediaPath(String absolutePath) async {
    final mediaRoot = p.normalize((await mediaRootDir()).path);
    return _isPathWithinRoot(absolutePath, mediaRoot);
  }

  bool _isPathWithinRoot(String targetPath, String rootPath) {
    final normalizedTarget = _normalizeForComparison(targetPath);
    final normalizedRoot = _normalizeForComparison(rootPath);
    if (normalizedTarget == normalizedRoot) return true;
    return normalizedTarget.startsWith(
      '$normalizedRoot${Platform.pathSeparator}',
    );
  }

  String _normalizeForComparison(String value) {
    final normalized = p.normalize(value);
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  Future<void> _tryDeleteStoredPath(String? storedPath) async {
    final absolute = await toAbsolutePath(storedPath);
    if (absolute == null) return;
    final file = File(absolute);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
