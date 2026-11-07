import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/edit_protection_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newshangli/ui/app_toast.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('开启但缺少密码凭据时直接拒绝，不弹出密码框', (tester) async {
    await EditProtectionConfig.save(
      const EditProtectionConfig(
        enabled: true,
        passwordSalt: '',
        passwordHash: '',
      ),
    );
    var allowed = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            child: const Text('edit'),
            onPressed: () async {
              allowed = await requireEditProtectionPassword(
                context,
                title: '编辑记录',
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('edit'));
    await tester.pumpAndSettle();

    expect(allowed, isFalse);
    expect(find.text('编辑密码'), findsNothing);
    expect(find.text('编辑保护配置异常，请到设置页处理'), findsOneWidget);
    expect(tester.takeException(), isNull);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });
}
