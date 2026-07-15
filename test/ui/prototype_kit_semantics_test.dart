import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:newshangli/ui/components.dart';
import 'package:newshangli/ui/prototype_kit.dart';

void main() {
  testWidgets('原型组件为关键按钮提供基础语义', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PrototypeIconButton(
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                  semanticLabel: '返回上一页',
                  onPressed: () {},
                ),
                PrototypePrimaryButton(label: '立即备份', onTap: () {}),
                PrototypeSecondaryButton(label: '取消', onTap: () {}),
                PrototypeButton(label: '手动备份', onPressed: () {}),
              ],
            ),
            bottomNavigationBar: PrototypeBottomNav(
              activeIndex: 3,
              onTap: (_) {},
            ),
          ),
        ),
      );

      // 共享原型组件提供的基础语义，供页面层直接复用。
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
