import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:newshangli/ui/app_bottom_sheet.dart';
import 'package:newshangli/ui/app_notification_tokens.dart';

const _panelKey = ValueKey('panel');

Future<void> _openPicker(
  WidgetTester tester, {
  required Offset position,
  bool anchored = true,
  int count = 2,
  ValueChanged<String?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Builder(
                builder: (anchorContext) => SizedBox(
                  width: 48,
                  height: 48,
                  child: TextButton(
                    onPressed: () async {
                      final result = await AppBottomSheet.showPicker<String>(
                        anchorContext,
                        anchorContext: anchored ? anchorContext : null,
                        title: '选择',
                        options: [
                          for (var i = 0; i < count; i++)
                            AppSheetOption(label: '选项 $i', value: '$i'),
                        ],
                      );
                      onResult?.call(result);
                    },
                    child: const Text('打开'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

void main() {
  for (final position in [
    const Offset(20, 70),
    const Offset(322, 70),
    const Offset(20, 710),
    const Offset(322, 710),
  ]) {
    testWidgets('菜单贴近触发控件并避开屏幕边缘 $position', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? result;
      await _openPicker(
        tester,
        position: position,
        onResult: (v) => result = v,
      );
      final panel = tester.getRect(find.byType(FCard));
      expect(panel.left, greaterThanOrEqualTo(16));
      expect(panel.right, lessThanOrEqualTo(374));
      expect(panel.top, greaterThanOrEqualTo(16));
      expect(panel.bottom, lessThanOrEqualTo(784));
      if (position.dy < 400) {
        expect(panel.top, closeTo(position.dy + 48 + 8, 0.1));
      } else {
        expect(panel.bottom, closeTo(position.dy - 8, 0.1));
      }
      await tester.tap(find.text('选项 1'));
      await tester.pumpAndSettle();
      expect(result, '1');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('就近菜单长列表可以滚动到末项', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? result;
    await _openPicker(
      tester,
      position: const Offset(290, 480),
      count: 30,
      onResult: (v) => result = v,
    );
    await tester.scrollUntilVisible(find.text('选项 29'), 250);
    await tester.tap(find.text('选项 29'));
    await tester.pumpAndSettle();
    expect(result, '29');
    expect(tester.takeException(), isNull);
  });

  testWidgets('横屏键盘打开并放大文字时菜单仍可滚动选择', (tester) async {
    tester.view.physicalSize = const Size(800, 390);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    String? result;
    await _openPicker(
      tester,
      position: const Offset(700, 75),
      count: 10,
      onResult: (v) => result = v,
    );
    expect(tester.takeException(), isNull);
    final panel = tester.getRect(find.byType(FCard));
    expect(panel.top, greaterThanOrEqualTo(16));
    expect(panel.bottom, lessThanOrEqualTo(390 - 180 - 16));
    await tester.scrollUntilVisible(find.text('选项 9'), 150);
    await tester.tap(find.text('选项 9'));
    await tester.pumpAndSettle();
    expect(result, '9');
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 800), const Size(800, 390)]) {
    testWidgets('大面板在安全区与键盘之间居中 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppBottomSheet.showCustom<void>(
                  context,
                  builder: (_) => const SizedBox(
                    key: _panelKey,
                    height: 140,
                    child: ColoredBox(color: Colors.white),
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      var panel = tester.getRect(find.byKey(_panelKey));
      expect(panel.center.dx, closeTo(size.width / 2, 0.1));
      expect(panel.center.dy, closeTo((24 + size.height - 20) / 2, 0.1));
      expect(
        panel.width,
        lessThanOrEqualTo(AppNotificationTokens.popupPanelMaxWidth),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pumpAndSettle();
      panel = tester.getRect(find.byKey(_panelKey));
      expect(panel.center.dy, closeTo((24 + size.height - 180) / 2, 0.1));
      expect(panel.bottom, lessThanOrEqualTo(size.height - 180 - 16));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('账簿式选择器未传锚点时始终居中', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _openPicker(
      tester,
      position: const Offset(322, 710),
      anchored: false,
    );
    final panel = tester.getRect(find.byType(FCard));
    expect(panel.center, const Offset(195, 400));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('选择'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
