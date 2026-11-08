import 'dart:io';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/stats/stats_models.dart';
import 'package:newshangli/stats/stats_repository.dart';
import 'package:newshangli/stats/stats_time_range.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_forui_theme.dart';
import 'package:newshangli/ui/app_icons.dart';
import 'package:newshangli/ui/app_localizations.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/pages/stats_page.dart';
import 'package:newshangli/ui/stats/stats_cards.dart';

import '../support/preview_fonts.dart';
import '../support/stats_preview_data.dart';

const _now = _fixedNow;
DateTime _fixedNow() => DateTime(2026, 10, 26);
final _verticalScroll = find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    )
    .first;

Future<AppDatabase> _database(WidgetTester tester) async {
  late AppDatabase db;
  await tester.runAsync(() async {
    db = await createStatsPreviewDatabase();
  });
  return db;
}

void _statsTest(
  String description,
  Future<void> Function(WidgetTester, AppDatabase) body,
) {
  testWidgets(description, (tester) async {
    final db = await _database(tester);
    try {
      await body(tester, db);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(db.close);
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  AppDatabase db, {
  Size size = const Size(393, 852),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  GlobalKey? captureKey,
  IStatsRepository? repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: AppDatabaseScope(
        db: db,
        child: RepaintBoundary(
          key: captureKey,
          child: Stack(
            children: [
              StatsPage(now: _now, repository: repository),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: FTheme(
                  data: AppForuiTheme.of(brightness),
                  child: FBottomNavigationBar(
                    index: 2,
                    onChange: (_) {},
                    children: const [
                      FBottomNavigationBarItem(
                        icon: Icon(AppIcons.bookOpen),
                        label: Text('记录'),
                      ),
                      FBottomNavigationBarItem(
                        icon: Icon(AppIcons.users),
                        label: Text('联系人'),
                      ),
                      FBottomNavigationBarItem(
                        icon: Icon(AppIcons.chartNoAxesCombined),
                        label: Text('统计'),
                      ),
                      FBottomNavigationBarItem(
                        icon: Icon(AppIcons.settings2),
                        label: Text('设置'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final directory = Platform.environment['STATS_PREVIEW_DIR'];
  if (directory == null) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  boundary.markNeedsPaint();
  await tester.pump();
  await tester.runAsync(() async {
    await Directory(directory).create(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadForuiPreviewFonts);

  _statsTest('real ledger totals, paired trend, categories and ranking agree', (
    tester,
    db,
  ) async {
    await _pump(tester, db);
    expect(find.text('2026年10月'), findsOneWidget);
    expect(find.text('全部账簿'), findsOneWidget);
    expect(find.text('¥12,800', findRichText: true), findsOneWidget);
    expect(find.text('+¥4,200'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart)).data;
    expect(chart.barGroups.length, 31);
    expect(
      chart.barGroups
          .map((group) => group.barRods[0].toY)
          .reduce((a, b) => a + b),
      12800,
    );
    expect(
      chart.barGroups
          .map((group) => group.barRods[1].toY)
          .reduce((a, b) => a + b),
      8600,
    );
    await tester.scrollUntilVisible(
      find.text('刘洋'),
      180,
      scrollable: _verticalScroll,
    );
    await tester.pumpAndSettle();
    final ranking = tester.widget<StatsRankingCard>(
      find.byType(StatsRankingCard),
    );
    expect(ranking.items.map((item) => item.personName), [
      '张伟',
      '李娜',
      '王芳',
      '陈明',
      '刘洋',
    ]);
    expect(ranking.items.first.totalCent, 480000);
    expect(
      tester.getBottomLeft(find.text('刘洋')).dy,
      lessThan(tester.getTopLeft(find.byType(FBottomNavigationBar)).dy),
    );
    expect(tester.takeException(), isNull);
  });

  _statsTest('month arrows and month picker load the selected calendar month', (
    tester,
    db,
  ) async {
    await _pump(tester, db);
    await tester.tap(find.byKey(const ValueKey('stats_previous_period')));
    await tester.pumpAndSettle();
    expect(find.text('2026年9月'), findsOneWidget);
    expect(find.text('9月收支'), findsOneWidget);
    expect(find.text('¥10,800', findRichText: true), findsOneWidget);
    expect(find.text('¥12,800', findRichText: true), findsNothing);
    await tester.tap(find.text('2026年9月'));
    await tester.pumpAndSettle();
    expect(find.text('选择月份'), findsOneWidget);
    await tester.tap(find.text('10月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年10月'), findsOneWidget);
    expect(find.text('¥12,800', findRichText: true), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stats_next_period')));
    await tester.pumpAndSettle();
    expect(find.text('2026年10月'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  _statsTest(
    'year view includes all months and all-years view remains available',
    (tester, db) async {
      await _pump(tester, db);
      await tester.tap(find.text('年统计'));
      await tester.pumpAndSettle();
      expect(find.text('2026年'), findsOneWidget);
      expect(find.text('本年收支'), findsOneWidget);
      expect(find.text('¥23,600', findRichText: true), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('stats_previous_period')));
      await tester.pumpAndSettle();
      expect(find.text('2025年收支'), findsOneWidget);
      expect(find.text('当前时段暂无收礼或送礼记录'), findsOneWidget);
      await tester.tap(find.text('2025年'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部年份'));
      await tester.pumpAndSettle();
      expect(find.text('全部年份'), findsOneWidget);
      expect(find.text('全部收支'), findsOneWidget);
      expect(find.text('¥23,600', findRichText: true), findsOneWidget);
      expect(find.textContaining('较去年'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  _statsTest(
    'custom end date includes that day and cancel preserves the range',
    (tester, db) async {
      await _pump(tester, db);
      await tester.tap(find.text('自定义'));
      await tester.pumpAndSettle();
      expect(find.text('2026.09.27'), findsOneWidget);
      expect(find.text('2026.10.26'), findsOneWidget);
      await tester.tap(find.text('起始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('2026.09.27'), findsOneWidget);
      await tester.tap(find.text('截止'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25').hitTestable().first);
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(find.text('2026.10.25'), findsOneWidget);
      expect(find.text('¥10,600', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (slug, size, scale, brightness) in [
    ('light', const Size(393, 852), 1.0, Brightness.light),
    ('dark', const Size(393, 852), 1.0, Brightness.dark),
    ('compact-large-text', const Size(360, 800), 1.3, Brightness.light),
    ('wide', const Size(800, 900), 1.0, Brightness.light),
  ]) {
    _statsTest('actual page renders and scrolls completely: $slug', (
      tester,
      db,
    ) async {
      final key = GlobalKey();
      await _pump(
        tester,
        db,
        size: size,
        textScale: scale,
        brightness: brightness,
        captureKey: key,
      );
      expect(tester.takeException(), isNull);
      await _capture(tester, key, '$slug-overview');
      await tester.scrollUntilVisible(
        find.text('刘洋'),
        180,
        scrollable: _verticalScroll,
      );
      await tester.pumpAndSettle();
      if (size.width == 393) {
        await Scrollable.ensureVisible(
          tester.element(find.byType(StatsCategoryCard)),
          alignment: 0.03,
        );
        await tester.pumpAndSettle();
      }
      await _capture(tester, key, '$slug-breakdown');
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('送 800').last,
        80,
        scrollable: _verticalScroll,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('送 800').last),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.text('送 800').last).dy,
        lessThan(tester.getTopLeft(find.byType(FBottomNavigationBar)).dy),
      );
    });
  }

  _statsTest(
    'long names and large amounts remain readable at 360px with large text',
    (tester, db) async {
      await _pump(
        tester,
        db,
        size: const Size(360, 800),
        textScale: 1.3,
        repository: _LongLabelsRepository(),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('¥123,456,789.12', findRichText: true), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(StatsRankingCard),
        180,
        scrollable: _verticalScroll,
      );
      await tester.pumpAndSettle();
      expect(find.text('收 123,456,789.12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  _statsTest(
    'failed month change hides stale amounts and retry loads the selected month',
    (tester, db) async {
      final repository = _RetryRepository();
      await _pump(tester, db, repository: repository);
      expect(find.text('¥123,456,789.12', findRichText: true), findsOneWidget);
      repository.fail = true;
      await tester.tap(find.byKey(const ValueKey('stats_previous_period')));
      await tester.pumpAndSettle();
      expect(find.text('2026年9月'), findsOneWidget);
      expect(find.text('统计加载失败'), findsOneWidget);
      expect(find.text('¥123,456,789.12', findRichText: true), findsNothing);
      repository.fail = false;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('9月收支'), findsOneWidget);
      expect(find.text('¥123,456,789.12', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _RetryRepository extends _LongLabelsRepository {
  bool fail = false;
  @override
  Future<StatsSnapshot> load(
    StatsTimePreset preset, {
    required List<StatsSourceRecord> records,
    String? bookId,
    DateTime? now,
    StatsDateRange? customRange,
  }) {
    if (fail) return Future.error(StateError('sample load failed'));
    return super.load(
      preset,
      records: records,
      bookId: bookId,
      now: now,
      customRange: customRange,
    );
  }
}

class _LongLabelsRepository implements IStatsRepository {
  @override
  Future<StatsSnapshot> load(
    StatsTimePreset preset, {
    required List<StatsSourceRecord> records,
    String? bookId,
    DateTime? now,
    StatsDateRange? customRange,
  }) async => const StatsSnapshot(
    incomeTotalCent: 12345678912,
    expenseTotalCent: 9876543210,
    buckets: [],
    expenseCategories: [
      StatsCategorySlice(category: '亲友婚礼及家庭庆祝活动礼金', amountCent: 9876543210),
    ],
    ranking: [
      StatsRankItem(
        personName: '一位姓名很长的联系人及其家庭成员',
        incomeCent: 12345678912,
        expenseCent: 9876543210,
      ),
    ],
  );
}
