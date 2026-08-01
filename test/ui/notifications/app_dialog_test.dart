import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_dialog.dart';
import 'package:newshangli/ui/app_notification_tokens.dart';

void main() {
  group('AppDialog.confirm', () {
    testWidgets('展示带标题、消息、确认/取消按钮的 Dialog',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => AppDialog.confirm(
                    context,
                    title: '删除联系人',
                    message: '确认删除？',
                    confirmLabel: '删除',
                    cancelLabel: '取消',
                    tone: AppNotificationTone.error,
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

      expect(find.text('删除联系人'), findsOneWidget);
      expect(find.text('确认删除？'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('点击取消返回 false', (tester) async {
      bool? result = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await AppDialog.confirm(
                      context,
                      title: '删除',
                      message: '确认？',
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
      await tester.tap(find.text('取消').last);
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('AppDialog.showAlert', () {
    testWidgets('展示告警 Dialog 并显示"知道了"按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => AppDialog.showAlert(
                    context,
                    title: '提示',
                    message: '这是提示',
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
      expect(find.text('提示'), findsOneWidget);
      expect(find.text('这是提示'), findsOneWidget);
      expect(find.text('知道了'), findsOneWidget);
    });
  });

  group('AppDialog.showInput', () {
    testWidgets('展示输入型 Dialog 并支持多字段', (tester) async {
      Map<String, String>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await AppDialog.showInput(
                      context,
                      title: '设置密码',
                      fields: const [
                        AppDialogField(
                          id: 'p1',
                          label: '密码',
                          obscureText: true,
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
      expect(find.text('设置密码'), findsOneWidget);
      expect(result, isNull);
    });
  });
}
