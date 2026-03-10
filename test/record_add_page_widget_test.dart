import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_data.dart';
import 'package:newshangli/ui/pages/record_add_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_utils.dart';

void main() {
  testWidgets('收支录入：保存后直接返回，不弹出放弃确认', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final data = AppData();
    await tester.runAsync(() async {
      await waitAppDataReady(data);
    });
    final initialCount = data.records.length;

    await tester.pumpWidget(
      AppDataScope(
        data: data,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecordAddPage())),
                    child: const Text('打开录入'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开录入'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RecordAddPage), findsOneWidget);

    await tester.tap(find.text('200'));
    await tester.pump();

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('放弃编辑？'), findsNothing);
    expect(find.byType(RecordAddPage), findsNothing);
    expect(data.records.length, initialCount + 1);
  });

  testWidgets('收支录入：编辑记录保存应保留原 bookId', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final data = AppData();
    await tester.runAsync(() async {
      await waitAppDataReady(data);
    });
    final person = data.persons.first;
    final beforeIds = data.records.map((e) => e.id).toSet();

    data.createRecord(
      bookId: 'book_other_for_test',
      personId: person.id,
      direction: RecordDirection.income,
      amountCent: 100,
      eventName: '其他账簿记录_仅测试',
      paymentMethod: '现金',
      occurredAt: DateTime(2099, 1, 2, 12, 0),
      note: null,
    );
    final created = data.records.firstWhere((e) => !beforeIds.contains(e.id));

    await tester.pumpWidget(
      AppDataScope(
        data: data,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecordAddPage(recordId: created.id),
                      ),
                    ),
                    child: const Text('打开编辑'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开编辑'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('200'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final updated = data.findRecord(created.id);
    expect(updated, isNotNull);
    expect(updated!.bookId, 'book_other_for_test');
  });
}
