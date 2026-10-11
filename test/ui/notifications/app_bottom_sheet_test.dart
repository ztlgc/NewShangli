import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_bottom_sheet.dart';

void main() {
  group('AppBottomSheet.show', () {
    testWidgets('展示带标题与内容的 BottomSheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => AppBottomSheet.show<String>(
                    context,
                    title: '选择类型',
                    child: const Text('item-1'),
                  ),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('选择类型'), findsOneWidget);
      expect(find.text('item-1'), findsOneWidget);
    });
  });

  group('AppBottomSheet.showPicker', () {
    testWidgets('较多选项在窄屏上仍可滚动并选择末项', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await AppBottomSheet.showPicker<String>(
                    context,
                    title: '选择关系类型',
                    options: [
                      for (var i = 0; i < 20; i++)
                        AppSheetOption<String>(label: '关系类型 $i', value: '$i'),
                    ],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('关系类型 19'), 300);
      await tester.tap(find.text('关系类型 19'));
      await tester.pumpAndSettle();
      expect(picked, '19');
    });

    testWidgets('键盘打开时选择面板仍位于可见区域', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppBottomSheet.showPicker<String>(
                  context,
                  title: '选择关系类型',
                  options: const [
                    AppSheetOption<String>(label: '家人', value: 'family'),
                    AppSheetOption<String>(label: '亲戚', value: 'relative'),
                    AppSheetOption<String>(label: '同事', value: 'colleague'),
                    AppSheetOption<String>(label: '朋友', value: 'friend'),
                    AppSheetOption<String>(label: '同学', value: 'classmate'),
                    AppSheetOption<String>(label: '邻居', value: 'neighbor'),
                  ],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(find.text('选择关系类型')).dy, lessThan(360));
      expect(
        tester.getBottomLeft(find.byType(FCard).last).dy,
        lessThanOrEqualTo(360),
      );
    });

    testWidgets('选择项后返回对应 value 并关闭', (tester) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    picked = await AppBottomSheet.showPicker<String>(
                      context,
                      title: '关系类型',
                      options: const [
                        AppSheetOption<String>(
                          label: '家人',
                          value: 'family',
                          icon: FLucideIcons.messageCircle,
                        ),
                        AppSheetOption<String>(
                          label: '朋友',
                          value: 'friend',
                          icon: FLucideIcons.wallet,
                        ),
                      ],
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('朋友'));
      await tester.pumpAndSettle();
      expect(picked, 'friend');
    });

    testWidgets('当前选项显示 Forui 勾选图标', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppBottomSheet.showPicker<String>(
                  context,
                  title: '导出格式',
                  options: const [
                    AppSheetOption<String>(
                      label: 'Excel',
                      value: 'xlsx',
                      selected: true,
                    ),
                    AppSheetOption<String>(label: 'CSV', value: 'csv'),
                  ],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byIcon(FLucideIcons.check), findsOneWidget);
    });
  });

  group('AppBottomSheet.showCustom', () {
    testWidgets('复杂内容使用统一路由', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppBottomSheet.showCustom<void>(
                  context,
                  builder: (_) => const Text('custom-content'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('custom-content'), findsOneWidget);
      expect(
        ModalRoute.of(tester.element(find.text('custom-content'))),
        isA<ModalBottomSheetRoute<void>>(),
      );
    });
  });
}
