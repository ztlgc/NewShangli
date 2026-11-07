import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/pages/edit_protection_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 首次加载抛出异常，之后的加载委托给真实服务。
class _FlakyService extends EditProtectionService {
  int loadCalls = 0;

  @override
  Future<EditProtectionConfig> load() async {
    loadCalls++;
    if (loadCalls == 1) throw StateError('模拟读取失败');
    return super.load();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('设置加载失败时显示错误并可重试恢复', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FlakyService();

    await tester.pumpWidget(
      MaterialApp(home: EditProtectionPage(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑保护设置加载失败'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(FSwitch), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(service.loadCalls, 2);
    expect(find.text('编辑保护设置加载失败'), findsNothing);
    expect(find.byType(FSwitch), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
