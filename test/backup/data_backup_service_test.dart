import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/backup/backup_config.dart';
import 'package:newshangli/backup/data_backup_service.dart';

void main() {
  group('DataBackupService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('newshangli_backup_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('本地备份ZIP仅包含单数据库快照与manifest', () async {
      final sourceDb = File('${tempDir.path}/newshangli_drift.sqlite');
      await sourceDb.writeAsBytes(const <int>[1, 2, 3], flush: true);

      final service = DataBackupService(
        documentsDirectoryProvider: () async => tempDir,
        snapshotExecutor: ({required sourceDbPath, required outputDbPath}) async {
          expect(sourceDbPath.endsWith('newshangli_drift.sqlite'), true);
          await File(outputDbPath).writeAsBytes(const <int>[7, 8, 9], flush: true);
        },
      );

      final zip = await service.buildLocalBackupZip(onProgress: (_) {});
      expect(await zip.exists(), true);

      final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
      final names = archive.files.map((f) => f.name).toList();
      final dbNames = names.where((n) => n.startsWith('db/')).toList();
      expect(dbNames, <String>['db/newshangli_drift.snapshot.sqlite']);
      expect(names.contains('manifest.json'), true);

      final manifestEntry = archive.files.firstWhere((f) => f.name == 'manifest.json');
      final manifestText = utf8.decode(manifestEntry.content as List<int>);
      final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
      expect(manifest['backupMode'], 'snapshot_vacuum_into');
      expect(manifest['dbFile'], 'db/newshangli_drift.snapshot.sqlite');
      expect((manifest['dbSizeBytes'] as num?)?.toInt(), 3);

      final snapshotDir = Directory('${tempDir.path}/backups/snapshots');
      final remains = snapshotDir.existsSync() ? snapshotDir.listSync() : <FileSystemEntity>[];
      expect(remains, isEmpty);
    });

    test('快照执行失败时抛出BackupException', () async {
      final sourceDb = File('${tempDir.path}/newshangli_drift.sqlite');
      await sourceDb.writeAsBytes(const <int>[1], flush: true);

      final service = DataBackupService(
        documentsDirectoryProvider: () async => tempDir,
        snapshotExecutor: ({required sourceDbPath, required outputDbPath}) async {
          throw const BackupException('mock snapshot failed');
        },
      );

      await expectLater(
        service.buildLocalBackupZip(onProgress: (_) {}),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('生成数据库快照失败'),
          ),
        ),
      );
    });

    test('快照失败后会清理临时快照文件', () async {
      final sourceDb = File('${tempDir.path}/newshangli_drift.sqlite');
      await sourceDb.writeAsBytes(const <int>[1], flush: true);

      final service = DataBackupService(
        documentsDirectoryProvider: () async => tempDir,
        snapshotExecutor: ({required sourceDbPath, required outputDbPath}) async {
          await File(outputDbPath).writeAsBytes(const <int>[1, 2], flush: true);
          throw const BackupException('mock after file created');
        },
      );

      await expectLater(
        service.buildLocalBackupZip(onProgress: (_) {}),
        throwsA(isA<BackupException>()),
      );

      final snapshotDir = Directory('${tempDir.path}/backups/snapshots');
      final remains = snapshotDir.existsSync() ? snapshotDir.listSync() : <FileSystemEntity>[];
      expect(remains, isEmpty);
    });

    test('本地备份ZIP会包含media目录文件并写入manifest统计', () async {
      final sourceDb = File('${tempDir.path}/newshangli_drift.sqlite');
      await sourceDb.writeAsBytes(const <int>[1, 2], flush: true);
      final avatar = File('${tempDir.path}/media/avatars/a.png');
      await avatar.parent.create(recursive: true);
      await avatar.writeAsBytes(const <int>[9, 9, 9], flush: true);
      final attachment = File('${tempDir.path}/media/attachments/b.jpg');
      await attachment.parent.create(recursive: true);
      await attachment.writeAsBytes(const <int>[7], flush: true);

      final service = DataBackupService(
        documentsDirectoryProvider: () async => tempDir,
        snapshotExecutor: ({required sourceDbPath, required outputDbPath}) async {
          await File(outputDbPath).writeAsBytes(const <int>[4], flush: true);
        },
      );

      final zip = await service.buildLocalBackupZip(onProgress: (_) {});
      final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
      final names = archive.files.map((f) => f.name).toSet();
      expect(names.contains('media/avatars/a.png'), true);
      expect(names.contains('media/attachments/b.jpg'), true);

      final manifestEntry = archive.files.firstWhere((f) => f.name == 'manifest.json');
      final manifestText = utf8.decode(manifestEntry.content as List<int>);
      final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
      expect(manifest['mediaIncluded'], true);
      expect((manifest['mediaFilesCount'] as num?)?.toInt(), 2);
      expect((manifest['mediaBytes'] as num?)?.toInt(), 4);
    });
  });

  test('DataBackupService 远程目录非法时拦截', () async {
    final service = DataBackupService();
    const config = BackupConfig(
      webDavEnabled: true,
      webDavBaseUrl: 'https://example.com/remote.php/dav/files/user/',
      webDavUsername: 'user',
      webDavPassword: 'pass',
      webDavRemoteDir: 'backup//newshangli',
      autoBackupEnabled: false,
      backupFrequency: BackupFrequency.daily,
    );
    await expectLater(
      service.run(config: config, onProgress: (_) {}),
      throwsA(isA<BackupException>()),
    );
  });
}
