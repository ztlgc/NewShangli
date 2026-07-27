import 'dart:ui' show SemanticsAction, SemanticsFlag;

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
      await BackupStateStore.setPreferredLocalBackupDir('D:/NewShangliBackup');
      await BackupStateStore.setLastBackupFor(
        target: BackupTarget.local,
        at: DateTime(2026, 2, 11, 8, 0),
        fileName: 'local_20260211.zip',
        sizeBytes: 1800000,
        localPath: 'D:/NewShangliBackup/local_20260211.zip',
      );
      await BackupStateStore.setLastFailure(
        target: BackupTarget.local,
        message: '目录不可写',
        at: DateTime(2026, 2, 11, 8, 30),
      );

      await tester.pumpWidget(const MaterialApp(home: DataBackupPage()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('返回上一页'), findsOneWidget);
      expect(find.text('状态摘要'), findsOneWidget);
      expect(find.text('WebDAV云端备份'), findsWidgets);
      expect(find.text('本地备份'), findsOneWidget);

      // 页面主体是可滚动列表，测试环境下首屏高度可能不足以直接渲染到“云端设置”区域。
      // 因此这里先滚动到自动备份开关，再校验语义，避免断言依赖默认屏幕高度。
      await tester.dragUntilVisible(
        find.bySemanticsLabel('自动备份'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // 自动备份是自定义开关，这里直接校验补齐后的状态值和点击动作语义，
      // 避免后续仅保留标题文本却丢失“当前开关状态”的无障碍信息。
      final autoBackupSemantics = tester.getSemantics(
        find.bySemanticsLabel('自动备份'),
      );
      final autoBackupSemanticsData = autoBackupSemantics.getSemanticsData();
      expect(autoBackupSemantics.label, '自动备份');
      expect(autoBackupSemantics.value, '已开启');
      expect(autoBackupSemantics.hint, '双击切换自动备份开关');
      expect(autoBackupSemanticsData.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(
        autoBackupSemanticsData.hasFlag(SemanticsFlag.hasCheckedState),
        isTrue,
      );
      expect(autoBackupSemanticsData.hasFlag(SemanticsFlag.isChecked), isTrue);
      expect(autoBackupSemanticsData.hasAction(SemanticsAction.tap), isTrue);
      expect(find.bySemanticsLabel('备份频率'), findsOneWidget);
      expect(find.bySemanticsLabel('WebDAV 配置'), findsOneWidget);

      // 再继续滚动到历史记录和本地备份区块，避免测试对屏幕尺寸过于敏感。
      await tester.dragUntilVisible(
        find.text('历史记录'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(find.text('历史记录'), findsOneWidget);
      expect(find.text('导出备份'), findsOneWidget);
      expect(find.text('导入恢复'), findsOneWidget);
      expect(find.text('更改位置'), findsOneWidget);
      expect(find.textContaining('目录不可写'), findsOneWidget);
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
        tester.getSemantics(
          find.bySemanticsLabel('恢复备份文件 manual_20260210.zip'),
        ),
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

  testWidgets('数据备份页会持久化云端自动备份与备份频率设置', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const config = BackupConfig(
      webDavEnabled: true,
      webDavBaseUrl: 'https://example.com/remote.php/dav/files/user/',
      webDavUsername: 'user',
      webDavPassword: 'pass',
      webDavRemoteDir: BackupConfig.defaultWebDavRemoteDir,
      autoBackupEnabled: false,
      backupFrequency: BackupFrequency.daily,
    );
    await BackupConfig.save(config);

    await tester.pumpWidget(const MaterialApp(home: DataBackupPage()));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.bySemanticsLabel('自动备份'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('自动备份'));
    await tester.pumpAndSettle();

    var loaded = await BackupConfig.load();
    expect(loaded.autoBackupEnabled, true);

    await tester.tap(find.bySemanticsLabel('备份频率'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('每月'));
    await tester.pumpAndSettle();

    loaded = await BackupConfig.load();
    expect(loaded.backupFrequency, BackupFrequency.monthly);
  });

  testWidgets('数据备份页展示云端失败摘要', (WidgetTester tester) async {
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
    await BackupStateStore.setLastBackup(
      at: DateTime(2026, 7, 26, 8, 30),
      fileName: 'cloud_20260726.zip',
      sizeBytes: 1024,
      remoteUrl: 'https://example.com/backup/cloud_20260726.zip',
    );
    await BackupStateStore.setLastFailure(
      target: BackupTarget.cloud,
      message: '上传失败',
      at: DateTime(2026, 7, 26, 8, 45),
    );

    await tester.pumpWidget(const MaterialApp(home: DataBackupPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('最近成功：'), findsWidgets);
    expect(find.textContaining('08:30'), findsWidgets);
    expect(find.textContaining('最近失败：'), findsWidgets);
    expect(find.textContaining('08:45 • 上传失败'), findsOneWidget);
  });
}
