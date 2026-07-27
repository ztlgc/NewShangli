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

  test('BackupConfig 规范化 WebDAV 地址并移除 query/fragment', () {
    final uri = BackupConfig.parseAndNormalizeWebDavBaseUrl(
      ' https://example.com/remote.php/dav/files/user/?share=1#view ',
    );
    expect(uri, isNotNull);
    expect(uri.toString(), 'https://example.com/remote.php/dav/files/user/');
  });

  test('BackupConfig 拒绝非 http/https 的 WebDAV 地址', () {
    expect(
      BackupConfig.parseAndNormalizeWebDavBaseUrl(
        'ftp://example.com/remote.php/dav/files/user/',
      ),
      isNull,
    );
  });

  test('BackupStateStore 持久化本地备份状态与失败信息', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await BackupStateStore.setPreferredLocalBackupDir('D:/NewShangliBackup');
    await BackupStateStore.setLastBackupFor(
      target: BackupTarget.local,
      at: DateTime(2026, 7, 26, 10, 30),
      fileName: 'local_20260726.zip',
      sizeBytes: 4096,
      localPath: 'D:/NewShangliBackup/local_20260726.zip',
    );
    await BackupStateStore.setLastFailure(
      target: BackupTarget.local,
      message: '目录不可写',
      at: DateTime(2026, 7, 26, 10, 35),
    );

    final path = await BackupStateStore.getPreferredLocalBackupDir();
    final last = await BackupStateStore.getLastBackupFor(BackupTarget.local);
    final failure = await BackupStateStore.getLastFailure(BackupTarget.local);

    expect(path, 'D:/NewShangliBackup');
    expect(last, isNotNull);
    expect(last!.target, BackupTarget.local);
    expect(last.fileName, 'local_20260726.zip');
    expect(last.localPath, 'D:/NewShangliBackup/local_20260726.zip');
    expect(failure, isNotNull);
    expect(failure!.message, '目录不可写');
  });
}
