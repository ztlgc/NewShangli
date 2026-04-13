// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:newshangli/ui/app.dart';

void main() {
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

    await tester.pumpWidget(const NewShangliApp());
    await tester.pumpAndSettle();

    expect(find.text('尚礼'), findsOneWidget);
    
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Empty record list shows placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const NewShangliApp());
    await tester.pumpAndSettle();

    expect(find.text('暂无记录'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Dark mode still renders', (WidgetTester tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(() => tester.binding.platformDispatcher.clearPlatformBrightnessTestValue());

    await tester.pumpWidget(const NewShangliApp());
    await tester.pumpAndSettle();
    expect(find.text('尚礼'), findsOneWidget);
    
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
