// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app.dart';
import 'package:newshangli/ui/app_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('App opens record home page', (WidgetTester tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('NetworkImageLoadException')) {
        return;
      }
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    await tester.pumpWidget(
      NewShangliApp(
        databaseFactory: () => AppDatabase.forTesting(NativeDatabase.memory()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('礼记'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Empty record list shows placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      NewShangliApp(
        databaseFactory: () => AppDatabase.forTesting(NativeDatabase.memory()),
      ),
    );

    expect(find.text('暂无记录'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Dark mode still renders', (WidgetTester tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      () =>
          tester.binding.platformDispatcher.clearPlatformBrightnessTestValue(),
    );

    await tester.pumpWidget(
      NewShangliApp(
        databaseFactory: () => AppDatabase.forTesting(NativeDatabase.memory()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('礼记'), findsOneWidget);

    final context = tester.element(find.text('礼记'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      AppThemeColors.of(context).surfaceApp,
      AppThemeColors.dark.surfaceApp,
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppThemeColors.dark.surfaceApp);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
