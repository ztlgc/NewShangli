import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProtectionConfig {
  const EditProtectionConfig({
    required this.enabled,
    required this.passwordSalt,
    required this.passwordHash,
  });

  final bool enabled;
  final String passwordSalt;
  final String passwordHash;

  bool get hasPassword => passwordSalt.trim().isNotEmpty && passwordHash.trim().isNotEmpty;

  EditProtectionConfig copyWith({
    bool? enabled,
    String? passwordSalt,
    String? passwordHash,
  }) {
    return EditProtectionConfig(
      enabled: enabled ?? this.enabled,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  static const String _kEnabledKey = 'edit_protection_enabled_v1';
  static const String _kSaltKey = 'edit_protection_salt_v1';
  static const String _kHashKey = 'edit_protection_hash_v1';

  static Future<EditProtectionConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return EditProtectionConfig(
      enabled: prefs.getBool(_kEnabledKey) ?? false,
      passwordSalt: (prefs.getString(_kSaltKey) ?? '').trim(),
      passwordHash: (prefs.getString(_kHashKey) ?? '').trim(),
    );
  }

  static Future<void> save(EditProtectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, config.enabled);
    await prefs.setString(_kSaltKey, config.passwordSalt.trim());
    await prefs.setString(_kHashKey, config.passwordHash.trim());
  }
}

class EditProtectionService {
  Future<EditProtectionConfig> load() => EditProtectionConfig.load();

  Future<void> setPassword({
    required String newPassword,
    bool enabled = true,
  }) async {
    final salt = _randomSalt();
    final hash = _hashPassword(salt: salt, password: newPassword);
    await EditProtectionConfig.save(
      EditProtectionConfig(enabled: enabled, passwordSalt: salt, passwordHash: hash),
    );
  }

  Future<bool> verifyPassword(String password) async {
    final config = await EditProtectionConfig.load();
    if (!config.hasPassword) return false;
    final computed = _hashPassword(salt: config.passwordSalt, password: password);
    return _constantTimeEquals(computed, config.passwordHash);
  }

  Future<void> setEnabled(bool enabled) async {
    final config = await EditProtectionConfig.load();
    await EditProtectionConfig.save(config.copyWith(enabled: enabled));
  }

  String _randomSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword({required String salt, required String password}) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes).bytes;
    return base64UrlEncode(digest);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

