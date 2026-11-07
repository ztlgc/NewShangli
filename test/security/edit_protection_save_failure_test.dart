import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/security/edit_protection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// 包装内存实现，让指定键的写入返回 false，模拟持久化失败。
class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore(this._failKey) : super.empty();

  final String _failKey;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == _failKey) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  late SharedPreferencesStorePlatform original;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    original = SharedPreferencesStorePlatform.instance;
  });

  tearDown(() {
    SharedPreferencesStorePlatform.instance = original;
  });

  test('开关写入失败时 save 抛出异常，不静默成功', () async {
    SharedPreferencesStorePlatform.instance = _FailingStore(
      'flutter.edit_protection_enabled_v1',
    );
    await expectLater(
      EditProtectionConfig.save(
        const EditProtectionConfig(
          enabled: true,
          passwordSalt: 'salt',
          passwordHash: 'hash',
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('凭据写入失败时 save 抛出异常，且开关不会生效', () async {
    SharedPreferencesStorePlatform.instance = _FailingStore(
      'flutter.edit_protection_hash_v1',
    );
    await expectLater(
      EditProtectionConfig.save(
        const EditProtectionConfig(
          enabled: true,
          passwordSalt: 'salt',
          passwordHash: 'hash',
        ),
      ),
      throwsA(isA<StateError>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('edit_protection_enabled_v1'), isNull);
  });
}
