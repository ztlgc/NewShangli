import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/platform/app_platform.dart';
import 'package:newshangli/platform/flutter_platform_adapter.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/data_export_page.dart';

class _ExportTestPlatform extends FlutterPlatformAdapter {
  _ExportTestPlatform(this.directory);
  final Directory directory;

  @override
  Future<Directory> documentsDirectory() async => directory;
}

void main() {
  testWidgets('本地导出页展示账簿和备份提示，允许切换文件格式', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final temp = Directory.systemTemp.createTempSync('shangli_export_ui_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final previous = AppPlatform.instance;
    AppPlatform.instance = _ExportTestPlatform(temp);
    addTearDown(() => AppPlatform.instance = previous);
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.runAsync(() async {
      await tester.pumpWidget(
        AppDatabaseScope(
          db: db,
          child: const MaterialApp(home: DataExportPage()),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('数据导出'), findsOneWidget);
    expect(find.text('账簿'), findsOneWidget);
    expect(find.text('全部账簿'), findsOneWidget);
    expect(find.text('共 0 条记录'), findsOneWidget);
    expect(find.textContaining('完整备份请使用'), findsOneWidget);
    expect(find.textContaining('云同步'), findsNothing);
    expect(find.textContaining('登录'), findsNothing);

    await tester.tap(find.text('ZIP 压缩包'));
    await tester.pumpAndSettle();
    expect(find.text('ZIP 压缩包'), findsOneWidget);
    expect(find.text('Excel 表格'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
    await tester.pump(const Duration(seconds: 1));
  });
}
