import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/backup/backup_config.dart';
import 'package:newshangli/backup/data_restore_service.dart';

void main() {
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

