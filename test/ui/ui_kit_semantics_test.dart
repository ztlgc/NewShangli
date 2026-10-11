import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/components.dart';
import 'package:newshangli/ui/ui_kit.dart';

void main() {
  testWidgets('共享 UI 组件为关键按钮提供基础语义', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppIconButton(
                  icon: const Icon(FLucideIcons.arrowLeft),
                  semanticLabel: '返回上一页',
                  onPressed: () {},
                ),
                AppPrimaryButton(label: '立即备份', onTap: () {}),
                AppSecondaryButton(label: '取消', onTap: () {}),
                AppButton(label: '手动备份', onPressed: () {}),
              ],
            ),
            bottomNavigationBar: AppBottomNav(activeIndex: 3, onTap: (_) {}),
          ),
        ),
      );

      // 共享 UI 组件提供基础语义，供页面层直接复用。
      expect(find.bySemanticsLabel('返回上一页'), findsOneWidget);
      expect(find.bySemanticsLabel('立即备份'), findsOneWidget);
      expect(find.bySemanticsLabel('取消'), findsOneWidget);
      expect(find.bySemanticsLabel('手动备份'), findsOneWidget);
      expect(find.bySemanticsLabel('设置'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
