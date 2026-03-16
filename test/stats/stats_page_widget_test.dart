import 'package:fl_chart/fl_chart.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/stats/stats_models.dart';
import 'package:newshangli/stats/stats_repository.dart';
import 'package:newshangli/stats/stats_time_range.dart';
import 'package:newshangli/ui/app_data.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/pages/stats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils.dart';

class _FakeStatsRepository implements IStatsRepository {
  @override
  Future<StatsSnapshot> load(
    StatsTimePreset preset, {
    required List<StatsSourceRecord> records,
    String? bookId,
    DateTime? now,
    StatsDateRange? customRange,
  }) async {
    if (preset == StatsTimePreset.thisMonth) {
      return StatsSnapshot(
        incomeTotalCent: 10000,
        expenseTotalCent: 20000,
        buckets: [
          StatsBarBucket(
            start: DateTime(2026, 3, 1),
            endExclusive: DateTime(2026, 3, 6),
            label: '1-5日',
            incomeCent: 10000,
            expenseCent: 20000,
          ),
        ],
        expenseCategories: [
          StatsCategorySlice(category: '婚礼', amountCent: 20000),
        ],
        ranking: [
          StatsRankItem(personName: '张伟', incomeCent: 10000, expenseCent: 20000),
        ],
      );
    }
    if (preset == StatsTimePreset.custom) {
      return StatsSnapshot(
        incomeTotalCent: 30000,
        expenseTotalCent: 40000,
        buckets: [
          StatsBarBucket(
            start: DateTime(2026, 10, 1),
            endExclusive: DateTime(2026, 11, 1),
            label: '10月',
            incomeCent: 30000,
            expenseCent: 40000,
          ),
        ],
        expenseCategories: [
          StatsCategorySlice(category: '其他', amountCent: 40000),
        ],
        ranking: [
          StatsRankItem(personName: '李娜', incomeCent: 30000, expenseCent: 40000),
        ],
      );
    }
    return StatsSnapshot(
      incomeTotalCent: 50000,
      expenseTotalCent: 60000,
      buckets: [
        StatsBarBucket(
          start: DateTime(2026, 1, 1),
          endExclusive: DateTime(2026, 2, 1),
          label: '1月',
          incomeCent: 50000,
          expenseCent: 60000,
        ),
      ],
      expenseCategories: [
        StatsCategorySlice(category: '乔迁', amountCent: 60000),
      ],
      ranking: [
        StatsRankItem(personName: '王强', incomeCent: 50000, expenseCent: 60000),
      ],
    );
  }
}

void main() {
  testWidgets('统计页：默认本月，选择自定义时间触发刷新并更新UI', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final data = AppData();
    await tester.runAsync(() async {
      await waitAppDataReady(data);
    });
    final repo = _FakeStatsRepository();
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      AppDatabaseScope(
        db: db,
        child: AppDataScope(
          data: data,
          child: MaterialApp(
            home: StatsPage(
              now: () => DateTime(2026, 3, 1),
              repository: repo,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('月统计'), findsOneWidget);
    expect(find.text('总支出'), findsOneWidget);
    expect(find.text('总收入'), findsOneWidget);

    expect(find.byType(BarChart), findsOneWidget);

    await tester.tap(find.text('自定义'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('起始时间'), findsOneWidget);
    expect(find.text('截止时间'), findsOneWidget);

    expect(find.text('收支走势'), findsOneWidget);
  });
}

