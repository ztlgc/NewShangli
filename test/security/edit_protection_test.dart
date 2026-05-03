import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newshangli/security/edit_protection.dart';

void main() {
  group('EditProtectionService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('setPassword + verifyPassword', () async {
      final service = EditProtectionService();
      await service.setPassword(newPassword: '1234', enabled: true);

      final config = await service.load();
      expect(config.enabled, isTrue);
      expect(config.hasPassword, isTrue);
      expect(config.passwordSalt, isNotEmpty);
      expect(config.passwordHash, isNotEmpty);

      expect(await service.verifyPassword('1234'), isTrue);
      expect(await service.verifyPassword('9999'), isFalse);
    });

    test('setEnabled does not clear password', () async {
      final service = EditProtectionService();
      await service.setPassword(newPassword: 'abcd', enabled: true);
      await service.setEnabled(false);

      final config = await service.load();
      expect(config.enabled, isFalse);
      expect(config.hasPassword, isTrue);
      expect(await service.verifyPassword('abcd'), isTrue);
    });
  });
}

