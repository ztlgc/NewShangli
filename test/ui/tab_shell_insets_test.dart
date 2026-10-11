import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app.dart';
import 'package:newshangli/ui/tab_shell.dart';

void main() {
  testWidgets('主导航避让底部安全区并在键盘或选择模式下隐藏', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      NewShangliApp(
        databaseFactory: () => AppDatabase.forTesting(NativeDatabase.memory()),
      ),
    );
    await tester.pumpAndSettle();
    final navigation = find.byType(FBottomNavigationBar);
    expect(tester.getRect(navigation).bottom, lessThanOrEqualTo(876));
    expect(navigation.hitTestable(), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(navigation.hitTestable(), findsNothing);
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    expect(navigation.hitTestable(), findsOneWidget);
    TabShellScope.setNavHidden(tester.element(navigation), hidden: true);
    await tester.pumpAndSettle();
    expect(navigation.hitTestable(), findsNothing);
    TabShellScope.setNavHidden(tester.element(navigation), hidden: false);
    await tester.pumpAndSettle();
    expect(navigation.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
