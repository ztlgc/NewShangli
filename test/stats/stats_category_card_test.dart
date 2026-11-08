import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/stats/stats_models.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/stats/stats_cards.dart';

Future<void> _pumpCard(WidgetTester tester, int totalExpenseCent) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: StatsCategoryCard(
            categories: [
              StatsCategorySlice(
                category: '结婚礼金',
                amountCent: totalExpenseCent - 20000,
              ),
              const StatsCategorySlice(category: '丧事慰问', amountCent: 20000),
            ],
            totalExpenseCent: totalExpenseCent,
            periodLabel: '本月',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final totalExpenseCent in [908888, 123456789, 9876543210]) {
    testWidgets('送礼事由环形图：金额完整显示在内圈空白区域 ($totalExpenseCent)', (tester) async {
      await _pumpCard(tester, totalExpenseCent);

      final chartRect = tester.getRect(find.byType(PieChart));
      final center = chartRect.center;
      // 内圈半径 = 环宽 14 之外的空白区（128 / 2 - 14 - 2）。
      final innerRadius = chartRect.width / 2 - 16;
      final amountRect = tester.getRect(
        find.text(formatCentToYuan(totalExpenseCent)),
      );

      expect(amountRect.center.dx, closeTo(center.dx, 0.5));
      for (final corner in [
        amountRect.topLeft,
        amountRect.topRight,
        amountRect.bottomLeft,
        amountRect.bottomRight,
      ]) {
        expect(
          (corner - center).distance,
          lessThan(innerRadius - 4),
          reason: '金额文字压到了环形色带: $amountRect',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
