import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum BackupFrequency { daily, weekly, monthly }

String backupFrequencyLabel(BackupFrequency value) {
  switch (value) {
    case BackupFrequency.daily:
      return '每天';
    case BackupFrequency.weekly:
      return '每周';
    case BackupFrequency.monthly:
      return '每月';
  }
}

String backupFrequencyToStorage(BackupFrequency value) {
  switch (value) {
    case BackupFrequency.daily:
      return 'daily';
    case BackupFrequency.weekly:
      return 'weekly';
    case BackupFrequency.monthly:
      return 'monthly';
  }
}

BackupFrequency backupFrequencyFromStorage(String? value) {
  switch (value) {
    case 'weekly':
      return BackupFrequency.weekly;
    case 'monthly':
      return BackupFrequency.monthly;
    case 'daily':
    default:
      return BackupFrequency.daily;
  }
}

enum BackupHistoryType { auto, manual }

enum BackupTarget { cloud, local }

String backupTargetToStorage(BackupTarget value) {
  switch (value) {
    case BackupTarget.cloud:
      return 'cloud';
    case BackupTarget.local:
      return 'local';
  }
}

BackupTarget backupTargetFromStorage(String? value) {
  switch (value) {
    case 'local':
      return BackupTarget.local;
    case 'cloud':
    default:
      return BackupTarget.cloud;
  }
}

String backupHistoryTypeLabel(BackupHistoryType value) {
  switch (value) {
    case BackupHistoryType.auto:
      return '自动备份';
    case BackupHistoryType.manual:
      return '手动备份';
  }
}

String backupHistoryTypeToStorage(BackupHistoryType value) {
  switch (value) {
    case BackupHistoryType.auto:
      return 'auto';
    case BackupHistoryType.manual:
      return 'manual';
  }
}

BackupHistoryType backupHistoryTypeFromStorage(String? value) {
  switch (value) {
    case 'auto':
      return BackupHistoryType.auto;
    case 'manual':
    default:
      return BackupHistoryType.manual;
  }
}

class BackupHistoryEntry {
  const BackupHistoryEntry({
    required this.type,
    required this.at,
    required this.fileName,
    required this.sizeBytes,
    this.target = BackupTarget.cloud,
    this.localPath,
    this.remoteUrl,
  });

  final BackupHistoryType type;
  final DateTime at;
  final String fileName;
  final int sizeBytes;
  final BackupTarget target;
  final String? localPath;
  final String? remoteUrl;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': backupHistoryTypeToStorage(type),
      'atMs': at.millisecondsSinceEpoch,
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'target': backupTargetToStorage(target),
      'localPath': localPath,
      'remoteUrl': remoteUrl,
    };
  }

  factory BackupHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BackupHistoryEntry(
      type: backupHistoryTypeFromStorage(json['type'] as String?),
      at: DateTime.fromMillisecondsSinceEpoch(
        (json['atMs'] as num?)?.toInt() ?? 0,
      ),
      fileName: (json['fileName'] as String?) ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      target: backupTargetFromStorage(json['target'] as String?),
      localPath: (json['localPath'] as String?)?.trim(),
      remoteUrl: json['remoteUrl'] as String?,
    );
  }
}

class BackupConfig {
  const BackupConfig({
    required this.webDavEnabled,
    required this.webDavBaseUrl,
    required this.webDavUsername,
    required this.webDavPassword,
    required this.webDavRemoteDir,
    required this.autoBackupEnabled,
    required this.backupFrequency,
  });

  final bool webDavEnabled;
  final String webDavBaseUrl;
  final String webDavUsername;
  final String webDavPassword;
  final String webDavRemoteDir;
  final bool autoBackupEnabled;
  final BackupFrequency backupFrequency;

  BackupConfig copyWith({
    bool? webDavEnabled,
    String? webDavBaseUrl,
    String? webDavUsername,
    String? webDavPassword,
    String? webDavRemoteDir,
    bool? autoBackupEnabled,
    BackupFrequency? backupFrequency,
  }) {
    return BackupConfig(
      webDavEnabled: webDavEnabled ?? this.webDavEnabled,
      webDavBaseUrl: webDavBaseUrl ?? this.webDavBaseUrl,
      webDavUsername: webDavUsername ?? this.webDavUsername,
      webDavPassword: webDavPassword ?? this.webDavPassword,
      webDavRemoteDir: webDavRemoteDir ?? this.webDavRemoteDir,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
    );
  }

  static const String defaultWebDavRemoteDir = 'backup/newshangli';

  static final RegExp _remoteDirPattern = RegExp(
    r'^[A-Za-z0-9._-]+(\/[A-Za-z0-9._-]+)*$',
  );

  static bool isValidWebDavRemoteDir(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    // 第一层：格式约束（仅允许用 / 作为分隔，禁止反斜杠与空段）。
    if (!_remoteDirPattern.hasMatch(trimmed)) return false;

    // 第二层：安全约束（禁止目录穿越片段 '.' 与 '..'）。
    //
    // 注意：正则允许 '.' 出现在目录名中（例如：backup.v1），但不应允许
    // 以 '.' 或 '..' 作为“完整片段”，否则会产生路径穿越风险（../）。
    final parts = trimmed.split('/');
    for (final p in parts) {
      if (p == '.' || p == '..') return false;
    }

    return true;
  }

  static String normalizeWebDavRemoteDir(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed;
  }

  static Uri? parseAndNormalizeWebDavBaseUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final parsed = Uri.tryParse(raw);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) return null;
    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    final normalizedPath = parsed.path.trim().isEmpty ? '/' : parsed.path;
    var authority = parsed.host;
    if (parsed.hasPort) {
      authority = '$authority:${parsed.port}';
    }
    if (parsed.userInfo.isNotEmpty) {
      authority = '${parsed.userInfo}@$authority';
    }
    return Uri.tryParse('$scheme://$authority$normalizedPath');
  }

  static const String _kWebDavEnabledKey = 'backup_webdav_enabled_v1';
  static const String _kWebDavBaseUrlKey = 'backup_webdav_base_url_v1';
  static const String _kWebDavUsernameKey = 'backup_webdav_username_v1';
  static const String _kWebDavPasswordKey = 'backup_webdav_password_v1';
  static const String _kWebDavRemoteDirKey = 'backup_webdav_remote_dir_v1';
  static const String _kAutoBackupEnabledKey = 'backup_auto_enabled_v1';
  static const String _kBackupFrequencyKey = 'backup_frequency_v1';

  static Future<BackupConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final remoteDirRaw = (prefs.getString(_kWebDavRemoteDirKey) ?? '').trim();
    final normalizedRemoteDir = isValidWebDavRemoteDir(remoteDirRaw)
        ? normalizeWebDavRemoteDir(remoteDirRaw)
        : '';
    return BackupConfig(
      webDavEnabled: prefs.getBool(_kWebDavEnabledKey) ?? false,
      webDavBaseUrl: (prefs.getString(_kWebDavBaseUrlKey) ?? '').trim(),
      webDavUsername: (prefs.getString(_kWebDavUsernameKey) ?? '').trim(),
      webDavPassword: prefs.getString(_kWebDavPasswordKey) ?? '',
      webDavRemoteDir: normalizedRemoteDir,
      autoBackupEnabled: prefs.getBool(_kAutoBackupEnabledKey) ?? false,
      backupFrequency: backupFrequencyFromStorage(
        prefs.getString(_kBackupFrequencyKey),
      ),
    );
  }

  static Future<void> save(BackupConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final remoteDirRaw = config.webDavRemoteDir.trim();
    final normalizedRemoteDir = isValidWebDavRemoteDir(remoteDirRaw)
        ? normalizeWebDavRemoteDir(remoteDirRaw)
        : '';
    final normalizedBaseUrl =
        parseAndNormalizeWebDavBaseUrl(config.webDavBaseUrl)?.toString() ??
        config.webDavBaseUrl.trim();
    await prefs.setBool(_kWebDavEnabledKey, config.webDavEnabled);
    await prefs.setString(_kWebDavBaseUrlKey, normalizedBaseUrl);
    await prefs.setString(_kWebDavUsernameKey, config.webDavUsername.trim());
    await prefs.setString(_kWebDavPasswordKey, config.webDavPassword);
    await prefs.setString(_kWebDavRemoteDirKey, normalizedRemoteDir);
    await prefs.setBool(_kAutoBackupEnabledKey, config.autoBackupEnabled);
    await prefs.setString(
      _kBackupFrequencyKey,
      backupFrequencyToStorage(config.backupFrequency),
    );
  }
}

class BackupStateStore {
  static const String _kLastBackupAtMsKey = 'backup_last_backup_at_ms_v1';
  static const String _kLastBackupNameKey = 'backup_last_backup_name_v1';
  static const String _kLastBackupSizeKey = 'backup_last_backup_size_b_v1';
  static const String _kLastBackupRemoteUrlKey =
      'backup_last_backup_remote_url_v1';
  static const String _kLastLocalBackupAtMsKey =
      'backup_last_local_backup_at_ms_v1';
  static const String _kLastLocalBackupNameKey =
      'backup_last_local_backup_name_v1';
  static const String _kLastLocalBackupSizeKey =
      'backup_last_local_backup_size_b_v1';
  static const String _kLastLocalBackupPathKey =
      'backup_last_local_backup_path_v1';
  static const String _kPreferredLocalBackupDirKey =
      'backup_preferred_local_dir_v1';
  static const String _kLastCloudFailureAtMsKey =
      'backup_last_cloud_failure_at_ms_v1';
  static const String _kLastCloudFailureMessageKey =
      'backup_last_cloud_failure_message_v1';
  static const String _kLastLocalFailureAtMsKey =
      'backup_last_local_failure_at_ms_v1';
  static const String _kLastLocalFailureMessageKey =
      'backup_last_local_failure_message_v1';
  static const String _kBackupHistoryKey = 'backup_history_entries_v1';
  static const int _historyLimit = 20;

  static Future<void> setLastBackup({
    required DateTime at,
    required String fileName,
    required int sizeBytes,
    String? remoteUrl,
  }) async {
    await setLastBackupFor(
      target: BackupTarget.cloud,
      at: at,
      fileName: fileName,
      sizeBytes: sizeBytes,
      remoteUrl: remoteUrl,
    );
  }

  static Future<void> setLastBackupFor({
    required BackupTarget target,
    required DateTime at,
    required String fileName,
    required int sizeBytes,
    String? localPath,
    String? remoteUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _keysForTarget(target);
    await prefs.setInt(keys.lastBackupAtMsKey, at.millisecondsSinceEpoch);
    await prefs.setString(keys.lastBackupNameKey, fileName);
    await prefs.setInt(keys.lastBackupSizeKey, sizeBytes);
    if (keys.lastBackupLocalPathKey != null) {
      if (localPath == null || localPath.trim().isEmpty) {
        await prefs.remove(keys.lastBackupLocalPathKey!);
      } else {
        await prefs.setString(keys.lastBackupLocalPathKey!, localPath.trim());
      }
    }
    if (keys.lastBackupRemoteUrlKey != null) {
      if (remoteUrl == null || remoteUrl.trim().isEmpty) {
        await prefs.remove(keys.lastBackupRemoteUrlKey!);
      } else {
        await prefs.setString(keys.lastBackupRemoteUrlKey!, remoteUrl.trim());
      }
    }
  }

  static Future<BackupLastState?> getLastBackup() async {
    return getLastBackupFor(BackupTarget.cloud);
  }

  static Future<BackupLastState?> getLastBackupFor(BackupTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _keysForTarget(target);
    final atMs = prefs.getInt(keys.lastBackupAtMsKey);
    final name = prefs.getString(keys.lastBackupNameKey);
    final size = prefs.getInt(keys.lastBackupSizeKey);
    if (atMs == null || name == null || name.trim().isEmpty || size == null)
      return null;
    return BackupLastState(
      at: DateTime.fromMillisecondsSinceEpoch(atMs),
      fileName: name,
      sizeBytes: size,
      target: target,
      localPath: keys.lastBackupLocalPathKey == null
          ? null
          : prefs.getString(keys.lastBackupLocalPathKey!),
      remoteUrl: keys.lastBackupRemoteUrlKey == null
          ? null
          : prefs.getString(keys.lastBackupRemoteUrlKey!),
    );
  }

  static Future<void> setPreferredLocalBackupDir(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = path?.trim() ?? '';
    if (normalized.isEmpty) {
      await prefs.remove(_kPreferredLocalBackupDirKey);
      return;
    }
    await prefs.setString(_kPreferredLocalBackupDirKey, normalized);
  }

  static Future<String?> getPreferredLocalBackupDir() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kPreferredLocalBackupDirKey)?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static Future<void> setLastFailure({
    required BackupTarget target,
    required String message,
    DateTime? at,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _keysForTarget(target);
    final normalized = message.trim();
    if (normalized.isEmpty) {
      await clearLastFailure(target);
      return;
    }
    await prefs.setInt(
      keys.lastFailureAtMsKey,
      (at ?? DateTime.now()).millisecondsSinceEpoch,
    );
    await prefs.setString(keys.lastFailureMessageKey, normalized);
  }

  static Future<void> clearLastFailure(BackupTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _keysForTarget(target);
    await prefs.remove(keys.lastFailureAtMsKey);
    await prefs.remove(keys.lastFailureMessageKey);
  }

  static Future<BackupFailureState?> getLastFailure(BackupTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _keysForTarget(target);
    final atMs = prefs.getInt(keys.lastFailureAtMsKey);
    final message = prefs.getString(keys.lastFailureMessageKey)?.trim() ?? '';
    if (atMs == null || message.isEmpty) return null;
    return BackupFailureState(
      target: target,
      at: DateTime.fromMillisecondsSinceEpoch(atMs),
      message: message,
    );
  }

  static Future<void> addHistory(BackupHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBackupHistoryKey);
    final items = _decodeHistory(raw);
    items.insert(0, entry);
    items.sort((a, b) => b.at.compareTo(a.at));
    final limited = items.take(_historyLimit).toList();
    final encoded = jsonEncode(limited.map((e) => e.toJson()).toList());
    await prefs.setString(_kBackupHistoryKey, encoded);
  }

  static Future<List<BackupHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeHistory(prefs.getString(_kBackupHistoryKey));
  }

  static List<BackupHistoryEntry> _decodeHistory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <BackupHistoryEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <BackupHistoryEntry>[];
      final items = <BackupHistoryEntry>[];
      for (final item in decoded) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final entry = BackupHistoryEntry.fromJson(map);
          if (entry.fileName.trim().isNotEmpty && entry.sizeBytes > 0) {
            items.add(entry);
          }
        }
      }
      return items;
    } catch (_) {
      return <BackupHistoryEntry>[];
    }
  }

  static _BackupTargetStoreKeys _keysForTarget(BackupTarget target) {
    switch (target) {
      case BackupTarget.cloud:
        return const _BackupTargetStoreKeys(
          lastBackupAtMsKey: _kLastBackupAtMsKey,
          lastBackupNameKey: _kLastBackupNameKey,
          lastBackupSizeKey: _kLastBackupSizeKey,
          lastBackupRemoteUrlKey: _kLastBackupRemoteUrlKey,
          lastFailureAtMsKey: _kLastCloudFailureAtMsKey,
          lastFailureMessageKey: _kLastCloudFailureMessageKey,
        );
      case BackupTarget.local:
        return const _BackupTargetStoreKeys(
          lastBackupAtMsKey: _kLastLocalBackupAtMsKey,
          lastBackupNameKey: _kLastLocalBackupNameKey,
          lastBackupSizeKey: _kLastLocalBackupSizeKey,
          lastBackupLocalPathKey: _kLastLocalBackupPathKey,
          lastFailureAtMsKey: _kLastLocalFailureAtMsKey,
          lastFailureMessageKey: _kLastLocalFailureMessageKey,
        );
    }
  }
}

class BackupLastState {
  const BackupLastState({
    required this.at,
    required this.fileName,
    required this.sizeBytes,
    this.target = BackupTarget.cloud,
    this.localPath,
    this.remoteUrl,
  });

  final DateTime at;
  final String fileName;
  final int sizeBytes;
  final BackupTarget target;
  final String? localPath;
  final String? remoteUrl;
}

class BackupFailureState {
  const BackupFailureState({
    required this.target,
    required this.at,
    required this.message,
  });

  final BackupTarget target;
  final DateTime at;
  final String message;
}

class _BackupTargetStoreKeys {
  const _BackupTargetStoreKeys({
    required this.lastBackupAtMsKey,
    required this.lastBackupNameKey,
    required this.lastBackupSizeKey,
    required this.lastFailureAtMsKey,
    required this.lastFailureMessageKey,
    this.lastBackupLocalPathKey,
    this.lastBackupRemoteUrlKey,
  });

  final String lastBackupAtMsKey;
  final String lastBackupNameKey;
  final String lastBackupSizeKey;
  final String? lastBackupLocalPathKey;
  final String? lastBackupRemoteUrlKey;
  final String lastFailureAtMsKey;
  final String lastFailureMessageKey;
}
