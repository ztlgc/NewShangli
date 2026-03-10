import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/backup/backup_config.dart';
import 'package:newshangli/ui/pages/data_backup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('数据备份页展示自动备份与历史备份', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const config = BackupConfig(
      webDavEnabled: true,
      webDavBaseUrl: 'https://example.com/remote.php/dav/files/user/',
      webDavUsername: 'user',
      webDavPassword: 'pass',
      webDavRemoteDir: BackupConfig.defaultWebDavRemoteDir,
      autoBackupEnabled: true,
      backupFrequency: BackupFrequency.weekly,
    );
    await BackupConfig.save(config);
    await BackupStateStore.addHistory(
      BackupHistoryEntry(
        type: BackupHistoryType.auto,
        at: DateTime(2026, 2, 12, 9, 30),
        fileName: 'auto_20260212.zip',
        sizeBytes: 2400000,
      ),
    );
    await BackupStateStore.addHistory(
      BackupHistoryEntry(
        type: BackupHistoryType.manual,
        at: DateTime(2026, 2, 10, 18, 20),
        fileName: 'manual_20260210.zip',
        sizeBytes: 2300000,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DataBackupPage(),
      ),
    );
    await tester.pumpAndSettle();

    // 页面主体是可滚动列表，测试环境下首屏高度可能不足以直接渲染到“自动备份/历史备份”区域。
    // 因此这里通过滚动确保目标控件进入可视范围后再断言，避免测试对屏幕尺寸过于敏感。
    await tester.dragUntilVisible(
      find.text('历史备份'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    // “自动备份”既会出现在开关标题，也可能出现在历史备份条目类型中，因此这里用 findsWidgets 更稳健。
    expect(find.text('自动备份'), findsWidgets);
    expect(find.text('每周'), findsOneWidget);
    expect(find.text('历史备份'), findsOneWidget);
    expect(find.text('恢复'), findsWidgets);
  });
}
