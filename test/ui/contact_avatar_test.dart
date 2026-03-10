import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/contact_avatar.dart';

void main() {
  group('contactAvatarTextFromName', () {
    test('空值/空白：返回 —', () {
      expect(contactAvatarTextFromName(null), '—');
      expect(contactAvatarTextFromName(''), '—');
      expect(contactAvatarTextFromName('   '), '—');
      expect(contactAvatarTextFromName('\n\t'), '—');
    });

    test('中文姓名：取第一个汉字（通常为姓氏首字）', () {
      expect(contactAvatarTextFromName('张三'), '张');
      expect(contactAvatarTextFromName(' 欧阳娜娜 '), '欧');
      expect(contactAvatarTextFromName('欧阳 娜娜'), '欧');
      expect(contactAvatarTextFromName('王小明Tom'), '王');
      expect(contactAvatarTextFromName('123张三'), '张');
    });

    test('英文姓名：取第一个单词中的首个英文字母并大写', () {
      expect(contactAvatarTextFromName('Tom Hanks'), 'T');
      expect(contactAvatarTextFromName('tom hanks'), 'T');
      expect(contactAvatarTextFromName('Tom·Hanks'), 'T');
      expect(contactAvatarTextFromName('  Tom   Hanks  '), 'T');
    });

    test('中英文混合：按首个有效片段规则；首片段无效则扫描全名', () {
      expect(contactAvatarTextFromName('Tom 张三'), 'T');
      expect(contactAvatarTextFromName('张三 Tom'), '张');
      expect(contactAvatarTextFromName('😀 Tom'), 'T');
    });

    test('无法识别：返回 #', () {
      expect(contactAvatarTextFromName('123'), '#');
      expect(contactAvatarTextFromName('---'), '#');
      expect(contactAvatarTextFromName('😀'), '#');
    });
  });

  group('contactAvatarColorScheme', () {
    test('对 # 与 — 使用统一中性配色', () {
      final hash = contactAvatarColorScheme('#');
      final dash = contactAvatarColorScheme('—');
      expect(hash.background, dash.background);
      expect(hash.foreground, dash.foreground);
    });

    test('同一字符配色稳定，字母大小写一致', () {
      final a1 = contactAvatarColorScheme('A');
      final a2 = contactAvatarColorScheme('A');
      final a3 = contactAvatarColorScheme('a');
      expect(a1.background, a2.background);
      expect(a1.foreground, a2.foreground);
      expect(a1.background, a3.background);
      expect(a1.foreground, a3.foreground);
    });
  });

  group('ContactAvatar widget', () {
    testWidgets('无头像 URL：稳定渲染文字头像', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContactAvatar(
                name: '张三',
                avatarUrl: null,
                size: 40,
              ),
            ),
          ),
        ),
      );

      expect(find.text('张'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('头像 URL 不可用：回退渲染文字头像且不抛异常', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContactAvatar(
                name: 'Tom Hanks',
                avatarUrl: 'https://example.invalid/avatar.png',
                size: 40,
              ),
            ),
          ),
        ),
      );

      // 首帧加载中即展示 fallback（文字头像）。
      expect(find.text('T'), findsOneWidget);

      // 继续推进几帧，覆盖“加载失败 -> errorBuilder 回退”的路径。
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('T'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

