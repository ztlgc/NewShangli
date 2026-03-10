import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

