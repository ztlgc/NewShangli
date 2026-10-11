import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:newshangli/ui/app_icons.dart';
import 'package:newshangli/ui/app_toast.dart';
import 'package:newshangli/ui/edit_protection_guard.dart';
import 'package:newshangli/ui/pages/edit_protection_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  AppToast.dismiss();
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> password(
  WidgetTester tester,
  String first, [
  String? second,
]) async {
  await tester.enterText(find.byType(EditableText).at(0), first);
  if (second != null) {
    await tester.enterText(find.byType(EditableText).at(1), second);
  }
  await tester.tap(find.text(second == null ? '验证' : '保存'));
  await settle(tester);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('设置取消、密码校验、修改、关闭、重新开启和返回', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('settings'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditProtectionPage(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('settings'));
    await settle(tester);
    final service = EditProtectionService();
    await tester.tap(find.byType(FSwitch));
    await settle(tester);
    await tester.tap(find.text('取消'));
    await settle(tester);
    expect((await service.load()).enabled, isFalse);
    expect(tester.widget<FSwitch>(find.byType(FSwitch)).onChange, isNotNull);
    await tester.tap(find.text('设置密码'));
    await settle(tester);
    await password(tester, '123', '123');
    expect((await service.load()).hasPassword, isFalse);
    await tester.tap(find.text('设置密码'));
    await settle(tester);
    await password(tester, '1234', '9999');
    expect((await service.load()).hasPassword, isFalse);
    await tester.tap(find.text('设置密码'));
    await settle(tester);
    await password(tester, '1234', '1234');
    expect((await service.load()).enabled, isTrue);
    expect(await service.verifyPassword('1234'), isTrue);
    expect(find.text('设置编辑密码'), findsNothing);

    await tester.tap(find.text('关闭编辑保护'));
    await settle(tester);
    await password(tester, 'wrong');
    expect((await service.load()).enabled, isTrue);
    await tester.tap(find.text('关闭编辑保护'));
    await settle(tester);
    await tester.tap(find.text('取消'));
    await settle(tester);
    expect((await service.load()).enabled, isTrue);

    await tester.tap(find.text('修改密码'));
    await settle(tester);
    await password(tester, '1234');
    expect(find.text('设置编辑密码'), findsOneWidget);
    await password(tester, '5678', '5678');
    expect(await service.verifyPassword('1234'), isFalse);
    expect(await service.verifyPassword('5678'), isTrue);
    await tester.tap(find.text('关闭编辑保护'));
    await settle(tester);
    await password(tester, '5678');
    expect((await service.load()).enabled, isFalse);
    expect((await service.load()).hasPassword, isTrue);
    await tester.tap(find.byType(FSwitch));
    await settle(tester);
    expect((await service.load()).enabled, isTrue);
    await tester.tap(find.byIcon(AppIcons.arrowLeft));
    await settle(tester);
    expect(find.text('settings'), findsOneWidget);
    expect(find.byType(EditProtectionPage), findsNothing);
  });

  for (final input in ['cancel', 'back', '', 'wrong', '1234']) {
    testWidgets('编辑保护拦截操作：$input', (tester) async {
      await EditProtectionService().setPassword(newPassword: '1234');
      var mutations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('edit'),
                onPressed: () async {
                  if (await requireEditProtectionPassword(
                    context,
                    title: '编辑记录',
                  )) {
                    mutations++;
                  }
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('edit'));
      await settle(tester);
      if (input == 'cancel') {
        await tester.tap(find.text('取消'));
      } else if (input == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.enterText(find.byType(EditableText), input);
        await tester.tap(find.text('确认'));
      }
      await settle(tester);
      expect(mutations, input == '1234' ? 1 : 0);
      expect(find.byType(EditableText), findsNothing);
    });
  }
  testWidgets('关闭编辑保护直接放行', (tester) async {
    var allowed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            child: const Text('edit'),
            onPressed: () async {
              allowed = await requireEditProtectionPassword(
                context,
                title: '编辑',
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('edit'));
    await settle(tester);
    expect(allowed, isTrue);
    expect(find.byType(EditableText), findsNothing);
  });
}
