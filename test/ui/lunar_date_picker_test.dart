import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';

import 'package:newshangli/ui/app_localizations.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/lunar_date_picker.dart';

import '../support/preview_fonts.dart';

Future<GlobalKey> _openPicker(
  WidgetTester tester, {
  required DateTime initialDate,
  required ValueChanged<DateTime?> onResult,
  Size size = const Size(393, 852),
  double textScale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  onResult(
                    await showLunarDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100, 12, 31),
                    ),
                  );
                },
                child: const Text('选择日期'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('选择日期'));
  await tester.pumpAndSettle();
  return key;
}

void _expectCalendarRows(WidgetTester tester, int rows) {
  final grid = tester.getRect(find.byType(PageView));
  expect(grid.height, rows * 52);
  expect(tester.getTopLeft(find.text('确定')).dy - grid.bottom, closeTo(24, 0.1));
  expect(tester.takeException(), isNull);
}

Future<void> _capturePicker(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final path = Platform.environment['DATE_PICKER_PREVIEW_DIR'];
  if (path == null) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    await Directory(path).create(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$path/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadForuiPreviewFonts);

  for (final (date, rows) in [
    (DateTime(2021, 2, 1), 4),
    (DateTime(2026, 7, 1), 5),
    (DateTime(2026, 8, 1), 6),
  ]) {
    testWidgets('$rows 行月份按实际日期收紧高度，月底日期可选', (tester) async {
      DateTime? result;
      final key = await _openPicker(
        tester,
        initialDate: date,
        onResult: (date) => result = date,
      );
      _expectCalendarRows(tester, rows);
      await _capturePicker(tester, key, '$rows-rows');

      final lastDay = DateTime(date.year, date.month + 1, 0);
      await tester.tap(find.text('${lastDay.day}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(result, lastDay);
    });
  }

  testWidgets('五六行月份双向滑动后高度更新，选择保留且无溢出', (tester) async {
    DateTime? result;
    await _openPicker(
      tester,
      initialDate: DateTime(2026, 7, 17),
      onResult: (date) => result = date,
    );
    for (final (offset, month, rows) in [
      (-300.0, '8月', 6),
      (-300.0, '9月', 5),
      (300.0, '8月', 6),
      (300.0, '7月', 5),
    ]) {
      await tester.drag(find.byType(PageView), Offset(offset, 0));
      await tester.pumpAndSettle();
      expect(find.text(month), findsOneWidget);
      _expectCalendarRows(tester, rows);
    }
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 7, 17));
  });

  testWidgets('窄屏大字体深色模式下六行日历及取消按钮完整可用', (tester) async {
    var returned = false;
    DateTime? result = DateTime(2000);
    final key = await _openPicker(
      tester,
      initialDate: DateTime(2026, 8, 17),
      onResult: (date) {
        returned = true;
        result = date;
      },
      size: const Size(360, 640),
      textScale: 1.3,
      dark: true,
    );
    _expectCalendarRows(tester, 6);
    await _capturePicker(tester, key, '6-rows-compact-dark');
    await tester.tap(find.text('31'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(result, isNull);
  });

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
