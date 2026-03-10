import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_data.dart';
import 'package:newshangli/ui/pages/account_book_records_page.dart';
import 'package:newshangli/ui/pages/record_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils.dart';

void main() {
  testWidgets('记录详情页：信息区末行展示所属礼簿', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await tester.runAsync(() async {
      await waitAppDataReady(data);
    });
    final record = data.records.first;

    await tester.pumpWidget(
      AppDataScope(
        data: data,
        child: MaterialApp(
          home: RecordDetailPage(recordId: record.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('所属礼簿'), findsOneWidget);
    expect(find.text(AppData.defaultBookName), findsOneWidget);
  });

  testWidgets('账簿记录页：默认账簿展示全部记录，非默认账簿按 bookId 过滤', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final data = AppData();
    await tester.runAsync(() async {
      await waitAppDataReady(data);
    });
    final person = data.persons.first;

    data.createRecord(
      personId: person.id,
      direction: RecordDirection.income,
      amountCent: 100,
      eventName: '默认账簿记录_仅测试',
      paymentMethod: '现金',
      occurredAt: DateTime(2099, 1, 2, 10, 0),
      note: null,
    );
    data.createRecord(
      bookId: 'book_other_for_test',
      personId: person.id,
      direction: RecordDirection.income,
      amountCent: 200,
      eventName: '其他账簿记录_仅测试',
      paymentMethod: '现金',
      occurredAt: DateTime(2099, 1, 2, 11, 0),
      note: null,
    );

    await tester.pumpWidget(
      AppDataScope(
        data: data,
        child: const MaterialApp(
          home: AccountBookRecordsPage(
            bookId: AppData.defaultBookId,
            bookName: '默认账簿',
            isDefaultBook: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('默认账簿记录_仅测试'), findsOneWidget);
    expect(find.textContaining('其他账簿记录_仅测试'), findsOneWidget);

    await tester.pumpWidget(
      AppDataScope(
        data: data,
        child: const MaterialApp(
          home: AccountBookRecordsPage(
            bookId: 'book_other_for_test',
            bookName: '其他账簿',
            isDefaultBook: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('默认账簿记录_仅测试'), findsNothing);
    expect(find.textContaining('其他账簿记录_仅测试'), findsOneWidget);
  });
}
