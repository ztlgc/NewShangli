import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/backup/backup_config.dart';
import 'package:newshangli/ui/pages/data_backup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('数据备份页展示自动备份与历史备份', (WidgetTester tester) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
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

      expect(find.bySemanticsLabel('返回上一页'), findsOneWidget);
      // 自动备份是自定义开关，这里直接校验补齐后的状态值和点击动作语义，
      // 避免后续仅保留标题文本却丢失“当前开关状态”的无障碍信息。
      expect(
        tester.getSemantics(find.bySemanticsLabel('自动备份')),
        matchesSemantics(
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: '自动备份',
          value: '已开启',
          hint: '双击切换自动备份开关',
        ),
      );
      // 页面主体是可滚动列表，测试环境下首屏高度可能不足以直接渲染到“自动备份/历史备份”区域。
      // 因此这里通过滚动确保目标控件进入可视范围后再断言，避免测试对屏幕尺寸过于敏感。
      await tester.dragUntilVisible(
        find.text('历史备份'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('备份频率'), findsOneWidget);
      expect(find.bySemanticsLabel('网盘配置'), findsOneWidget);
      expect(find.text('历史备份'), findsOneWidget);
      // 恢复入口需要同时表达“恢复哪条备份”和“执行后会做什么”，
      // 因此这里同时断言标签、条目摘要和值和操作提示。
      expect(
        tester.getSemantics(find.bySemanticsLabel('恢复备份文件 auto_20260212.zip')),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: '恢复备份文件 auto_20260212.zip',
          value: '自动备份，2026-02-12 09:30，2.3MB',
          hint: '双击后恢复文件 auto_20260212.zip，并覆盖当前本地数据',
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('恢复备份文件 manual_20260210.zip')),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: '恢复备份文件 manual_20260210.zip',
          value: '手动备份，2026-02-10 18:20，2.2MB',
          hint: '双击后恢复文件 manual_20260210.zip，并覆盖当前本地数据',
        ),
      );
    } finally {
      semanticsHandle.dispose();
    }
  });
}
