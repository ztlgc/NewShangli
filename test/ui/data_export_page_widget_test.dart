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
    addTearDown(db.close);

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
    expect(find.text('所有账簿'), findsOneWidget);
    expect(find.text('共0条记录'), findsOneWidget);
    expect(find.textContaining('本地或 WebDAV 备份'), findsOneWidget);
    expect(find.textContaining('云同步'), findsNothing);
    expect(find.textContaining('登录'), findsNothing);

    await tester.tap(find.text('文件格式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ZIP 文件'));
    await tester.pumpAndSettle();
    expect(find.text('ZIP 文件'), findsOneWidget);
    expect(find.text('Excel 文件'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
