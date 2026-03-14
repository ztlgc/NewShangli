import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';

import 'package:newshangli/ui/lunar_date_picker.dart';

void main() {
  testWidgets('日期选择弹窗展示公历月份与农历信息，并可确认返回日期', (tester) async {
    DateTime? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Center(
              child: TextButton(
                onPressed: () async {
                  result = await showLunarDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 2, 17),
                    firstDate: DateTime(2000, 1, 1),
                    lastDate: DateTime(2100, 12, 31),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('2月'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('春节'), findsWidgets);

    await tester.tap(find.text('18').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.year, 2026);
    expect(result!.month, 2);
    expect(result!.day, 18);
  });

  test('农历闰月日期可正确识别', () {
    final lunar = Lunar.fromDate(DateTime(2020, 6, 1));
    expect(lunar.getMonthInChinese(), contains('闰'));
  });

  test('正月初一可正确识别', () {
    final lunar = Lunar.fromDate(DateTime(2026, 2, 17));
    expect(lunar.getDayInChinese(), '初一');
    expect(lunar.getFestivals(), contains('春节'));
  });

  testWidgets('公历 2 月 29 日可正确回填', (tester) async {
    DateTime? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Center(
              child: TextButton(
                onPressed: () async {
                  result = await showLunarDatePicker(
                    context: context,
                    initialDate: DateTime(2024, 2, 29),
                    firstDate: DateTime(2000, 1, 1),
                    lastDate: DateTime(2100, 12, 31),
                  );
                },
                child: const Text('open-229'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open-229'));
    await tester.pumpAndSettle();
    expect(find.text('2月'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, DateTime(2024, 2, 29));
  });
}
