import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/backup/backup_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BackupConfig 空远程目录与新增字段持久化', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const config = BackupConfig(
      webDavEnabled: true,
      webDavBaseUrl: 'https://example.com/remote.php/dav/files/user/',
      webDavUsername: 'user',
      webDavPassword: 'pass',
      webDavRemoteDir: '',
      autoBackupEnabled: true,
      backupFrequency: BackupFrequency.weekly,
    );
    await BackupConfig.save(config);
    final loaded = await BackupConfig.load();
    expect(loaded.webDavRemoteDir, '');
    expect(loaded.autoBackupEnabled, true);
    expect(loaded.backupFrequency, BackupFrequency.weekly);
  });

  test('BackupConfig 远程目录合法性校验', () {
    expect(BackupConfig.isValidWebDavRemoteDir('backup/newshangli'), true);
    expect(BackupConfig.isValidWebDavRemoteDir('backup/2026_03'), true);
    expect(BackupConfig.isValidWebDavRemoteDir('/backup/newshangli'), false);
    expect(BackupConfig.isValidWebDavRemoteDir('backup//newshangli'), false);
    expect(BackupConfig.isValidWebDavRemoteDir('backup/../newshangli'), false);
    expect(BackupConfig.isValidWebDavRemoteDir('backup\\newshangli'), false);
    expect(BackupConfig.normalizeWebDavRemoteDir(''), '');
  });
}
