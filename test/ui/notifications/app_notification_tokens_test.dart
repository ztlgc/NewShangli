import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_notification_tokens.dart';

void main() {
  group('AppNotificationTokens', () {
    test('时长表与 DESIGN_SPEC.md 第 3.5.6 章节一致', () {
      expect(AppNotificationTokens.toastEnterDuration,
          const Duration(milliseconds: 250));
      expect(AppNotificationTokens.toastExitDuration,
          const Duration(milliseconds: 200));
      expect(AppNotificationTokens.dialogEnterDuration,
          const Duration(milliseconds: 200));
      expect(AppNotificationTokens.dialogExitDuration,
          const Duration(milliseconds: 150));
    });

    test('圆角尺寸与设计令牌一致', () {
      expect(AppNotificationTokens.containerRadius, 12);
      expect(AppNotificationTokens.dialogRadius, 16);
      expect(AppNotificationTokens.sheetTopRadius, 24);
    });

    test('容器最大宽度限制符合设计', () {
      expect(AppNotificationTokens.toastMaxWidth, 420);
      expect(AppNotificationTokens.dialogMaxWidth, 360);
    });
  });
}
