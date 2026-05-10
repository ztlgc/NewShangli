import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_theme.dart';
import 'package:newshangli/ui/app_tokens.dart';
import 'package:newshangli/ui/pages/user_login_page.dart';

void main() {
  testWidgets('登录页适配深色模式基础背景和输入区', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const UserLoginPage()),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppThemeColors.dark.surfaceApp);
    expect(find.text('用户登录'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
