import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
                      title: '支付方式',
                      options: const [
                        AppSheetOption<String>(
                          label: '微信',
                          value: 'wechat',
                          icon: FontAwesomeIcons.weixin,
                        ),
                        AppSheetOption<String>(
                          label: '支付宝',
                          value: 'alipay',
                          icon: FontAwesomeIcons.alipay,
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
      await tester.tap(find.text('支付宝'));
      await tester.pumpAndSettle();
      expect(picked, 'alipay');
    });
  });
}
