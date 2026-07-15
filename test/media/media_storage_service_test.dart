import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/media/media_storage_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MediaStorageService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('newshangli_media_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('保存头像与附件到私有目录', () async {
      final sourceAvatar = File('${tempDir.path}/src/avatar.png');
      await sourceAvatar.parent.create(recursive: true);
      await sourceAvatar.writeAsBytes(const <int>[1, 2, 3], flush: true);
      final sourceAttachment = File('${tempDir.path}/src/att.jpg');
      await sourceAttachment.writeAsBytes(const <int>[4, 5], flush: true);

      final service = MediaStorageService(
        documentsDirectoryProvider: () async => tempDir,
      );
      final avatarPath = await service.saveAvatarFromPath(sourceAvatar.path);
      final attachmentPath = await service.saveAttachmentFromPath(
        sourceAttachment.path,
      );

      expect(await File(avatarPath).exists(), true);
      expect(await File(attachmentPath).exists(), true);
      expect(avatarPath.contains('media'), true);
      expect(attachmentPath.contains('media'), true);
    });

    test('仅允许解析和删除应用私有 media 目录内的文件', () async {
      final outsideFile = File('${tempDir.path}/outside.txt');
      await outsideFile.writeAsString('outside', flush: true);
      final mediaFile = File('${tempDir.path}/media/avatars/in_media.png');
      await mediaFile.parent.create(recursive: true);
      await mediaFile.writeAsBytes(const <int>[7, 8, 9], flush: true);

      final service = MediaStorageService(
        documentsDirectoryProvider: () async => tempDir,
      );

      expect(await service.toAbsolutePath(outsideFile.path), isNull);
      expect(await service.toAbsolutePath('../outside.txt'), isNull);
      expect(
        await service.toAbsolutePath('media/avatars/in_media.png'),
        p.normalize(mediaFile.path),
      );

      await service.deleteStoredPath(outsideFile.path);
      await service.deleteStoredPath(mediaFile.path);

      expect(await outsideFile.exists(), true);
      expect(await mediaFile.exists(), false);
    });
  });
}
