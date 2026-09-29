import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/backup/backup_config.dart';
import 'package:newshangli/backup/data_restore_service.dart';

void main() {
  group('DataRestoreService local zip restore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('newshangli_restore_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('旧格式和伪数据库被拒绝，原数据库与媒体保持不变', () async {
      final dbFile = File('${tempDir.path}/newshangli_drift.sqlite');
      await dbFile.writeAsBytes(const <int>[1, 1, 1], flush: true);
      final oldMedia = File('${tempDir.path}/media/avatars/old.png');
      await oldMedia.parent.create(recursive: true);
      await oldMedia.writeAsBytes(const <int>[2], flush: true);

      final archive = Archive();
      archive.addFile(
        ArchiveFile('db/newshangli_drift.snapshot.sqlite', 3, const <int>[
          7,
          8,
          9,
        ]),
      );
      final manifestBytes = utf8.encode(
        jsonEncode(<String, Object?>{
          'dbFile': 'db/newshangli_drift.snapshot.sqlite',
          'backupMode': 'snapshot_vacuum_into',
        }),
      );
      archive.addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      );
      archive.addFile(
        ArchiveFile('media/avatars/new.png', 2, const <int>[5, 6]),
      );
      final zipFile = File('${tempDir.path}/restore.zip');
      await zipFile.writeAsBytes(ZipEncoder().encode(archive)!, flush: true);

      final service = DataRestoreService(
        documentsDirectoryProvider: () async => tempDir,
      );
      await expectLater(
        service.restoreFromLocalZip(zipFile: zipFile, onProgress: (_) {}),
        throwsA(isA<DataRestoreException>()),
      );

      expect(await dbFile.readAsBytes(), const <int>[1, 1, 1]);
      expect(File('${tempDir.path}/media/avatars/new.png').existsSync(), false);
      expect(oldMedia.existsSync(), true);
    });

    test('本地ZIP非法时返回明确错误', () async {
      final zipFile = File('${tempDir.path}/invalid.zip');
      await zipFile.writeAsBytes(const <int>[1, 2, 3], flush: true);
      final service = DataRestoreService(
        documentsDirectoryProvider: () async => tempDir,
      );

      await expectLater(
        service.restoreFromLocalZip(zipFile: zipFile, onProgress: (_) {}),
        throwsA(
          isA<DataRestoreException>().having(
            (e) => e.message,
            'message',
            '备份包不是有效的 ZIP 文件',
          ),
        ),
      );
    });

    test('本地ZIP缺少manifest时返回明确错误', () async {
      final archive = Archive();
      archive.addFile(
        ArchiveFile('db/newshangli_drift.snapshot.sqlite', 3, const <int>[
          7,
          8,
          9,
        ]),
      );
      final zipFile = File('${tempDir.path}/missing_manifest.zip');
      await zipFile.writeAsBytes(ZipEncoder().encode(archive)!, flush: true);
      final service = DataRestoreService(
        documentsDirectoryProvider: () async => tempDir,
      );

      await expectLater(
        service.restoreFromLocalZip(zipFile: zipFile, onProgress: (_) {}),
        throwsA(
          isA<DataRestoreException>().having(
            (e) => e.message,
            'message',
            '备份包缺少 manifest.json',
          ),
        ),
      );
    });
  });

  test('DataRestoreService 服务器地址非法时拦截', () async {
    final service = DataRestoreService();
    const config = BackupConfig(
      webDavEnabled: true,
      webDavBaseUrl: 'not-a-url',
      webDavUsername: 'user',
      webDavPassword: 'pass',
      webDavRemoteDir: 'backup/newshangli',
      autoBackupEnabled: false,
      backupFrequency: BackupFrequency.daily,
    );
    final entry = BackupHistoryEntry(
      type: BackupHistoryType.manual,
      at: DateTime(2026, 1, 1),
      fileName: 'backup.zip',
      sizeBytes: 1024,
    );
    await expectLater(
      service.restoreFromRemote(
        config: config,
        entry: entry,
        onProgress: (_) {},
      ),
      throwsA(isA<DataRestoreException>()),
    );
  });
}
