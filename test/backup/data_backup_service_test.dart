import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/backup/backup_config.dart';
import 'package:newshangli/backup/data_backup_service.dart';

void main() {
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
