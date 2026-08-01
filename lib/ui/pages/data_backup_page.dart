import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as p;

import '../../backup/backup_config.dart';
import '../../backup/data_backup_service.dart';
import '../../backup/data_restore_service.dart';
import '../../backup/webdav_client.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_notification_tokens.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../app_session.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../../utils/date_util.dart';

/// 页面：系统设置 - 数据备份
/// 对照原型：prototype/index.html -> "数据备份"
class DataBackupPage extends StatelessWidget {
  const DataBackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  BackupConfig _config = const BackupConfig(
    webDavEnabled: false,
    webDavBaseUrl: '',
    webDavUsername: '',
    webDavPassword: '',
    webDavRemoteDir: '',
    autoBackupEnabled: false,
    backupFrequency: BackupFrequency.daily,
  );
  BackupLastState? _cloudLast;
  BackupLastState? _localLast;
  BackupFailureState? _cloudFailure;
  BackupFailureState? _localFailure;
  String? _preferredLocalBackupDir;
  LocalBackupDirectoryInfo? _localDirInfo;
  List<BackupHistoryEntry> _history = const <BackupHistoryEntry>[];
  bool _loading = true;
  bool _saving = false;
  bool _backingUp = false;
  bool _testing = false;
  bool _restoring = false;
  bool _localBackingUp = false;
  bool _localRestoring = false;
  BackupProgress? _progress;
  String? _localRunningText;

  bool get _webDavReady {
    if (!_config.webDavEnabled) return false;
    if (_config.webDavBaseUrl.trim().isEmpty) return false;
    if (_config.webDavUsername.trim().isEmpty) return false;
    if (_config.webDavPassword.isEmpty) return false;
    return true;
  }

  bool get _busy =>
      _saving ||
      _backingUp ||
      _testing ||
      _restoring ||
      _localBackingUp ||
      _localRestoring;

  @override
  void initState() {
    super.initState();
    Future<void>(_loadPageState);
  }

  @override
  Widget build(BuildContext context) {
    final progressText = _progress == null ? null : _formatProgress(_progress!);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            border: Border(
              bottom: BorderSide(
                color: context.appColors.surfaceSubtle,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                onPressed: _busy ? null : () => AppNav.pop(context),
                semanticLabel: '返回上一页',
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '数据备份',
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 36, height: 36),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Overline(title: '状态摘要'),
              const SizedBox(height: 12),
              _BackupStatusSummaryCard(
                cloudLast: _cloudLast,
                localLast: _localLast,
                cloudFailure: _cloudFailure,
                localFailure: _localFailure,
                runningText: progressText,
                cloudRunning: _backingUp || _testing || _restoring,
                localRunning: _localBackingUp || _localRestoring,
                localRunningText: _localRunningText,
              ),
              const SizedBox(height: 24),
              const _Overline(title: 'WebDAV云端备份'),
              const SizedBox(height: 12),
              _DriveExtraConfigCard(
                loading: _loading,
                config: _config,
                last: _cloudLast,
                runningText: progressText,
                running: _backingUp,
                saving: _busy,
                onBackup: _busy ? null : _runBackup,
                onToggleAutoBackup: _busy ? null : _toggleAutoBackup,
                onPickFrequency: _busy ? null : _pickBackupFrequency,
                webDavConfigured: _webDavReady,
                onOpenWebDavConfig: _busy ? null : _openWebDavConfigDialog,
              ),
              const SizedBox(height: 24),
              const _Overline(title: '本地备份'),
              const SizedBox(height: 12),
              _LocalBackupSectionCard(
                resolvedPath:
                    _localDirInfo?.directory.path ??
                    _preferredLocalBackupDir ??
                    '应用默认目录/backups',
                pathWritable: _localDirInfo?.writable,
                usingDefault: _localDirInfo?.usingDefault ?? true,
                last: _localLast,
                failure: _localFailure,
                running: _localBackingUp || _localRestoring,
                runningText: _localRunningText,
                onPickDirectory: _busy ? null : _pickLocalBackupDirectory,
                onExport: _busy ? null : _exportLocalBackup,
                onImport: _busy ? null : _pickLocalBackupZip,
              ),
              const SizedBox(height: 24),
              const _Overline(title: '历史记录'),
              const SizedBox(height: 12),
              _BackupHistoryCard(
                history: _history,
                onRestore: _busy ? null : _restoreBackup,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setConfig(BackupConfig next) {
    setState(() => _config = next);
  }

  Future<void> _loadPageState() async {
    final c = await BackupConfig.load();
    final cloudLast = await BackupStateStore.getLastBackup();
    final localLast = await BackupStateStore.getLastBackupFor(
      BackupTarget.local,
    );
    final history = await BackupStateStore.getHistory();
    final cloudFailure = await BackupStateStore.getLastFailure(
      BackupTarget.cloud,
    );
    final localFailure = await BackupStateStore.getLastFailure(
      BackupTarget.local,
    );
    final preferredLocalBackupDir =
        await BackupStateStore.getPreferredLocalBackupDir();
    final remoteDirRaw = c.webDavRemoteDir.trim();
    final normalizedRemoteDir =
        remoteDirRaw.isNotEmpty &&
            !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)
        ? ''
        : remoteDirRaw;
    if (!mounted) return;
    setState(() {
      _config = c.copyWith(webDavRemoteDir: normalizedRemoteDir);
      _cloudLast = cloudLast;
      _localLast = localLast;
      _history = history;
      _cloudFailure = cloudFailure;
      _localFailure = localFailure;
      _preferredLocalBackupDir = preferredLocalBackupDir;
      _loading = false;
    });
    unawaited(
      _refreshLocalDirectoryInfo(preferredOutputDir: preferredLocalBackupDir),
    );
  }

  Future<void> _refreshLocalDirectoryInfo({String? preferredOutputDir}) async {
    final effectiveDir = preferredOutputDir ?? _preferredLocalBackupDir;
    try {
      final info = await DataBackupService().inspectLocalBackupDirectory(
        preferredOutputDir: effectiveDir,
      );
      if (!mounted) return;
      setState(() {
        _preferredLocalBackupDir = effectiveDir?.trim().isEmpty ?? true
            ? null
            : effectiveDir!.trim();
        _localDirInfo = info;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preferredLocalBackupDir = effectiveDir?.trim().isEmpty ?? true
            ? null
            : effectiveDir!.trim();
        _localDirInfo = null;
      });
    }
  }

  Future<bool> _persistConfig() async {
    setState(() => _saving = true);
    final remoteDirRaw = _config.webDavRemoteDir.trim();
    if (remoteDirRaw.isNotEmpty &&
        !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)) {
      if (mounted) {
      AppNotifier.error(context, '远程目录格式不正确');
      setState(() => _saving = false);
    }
      return false;
    }
    final normalizedRemoteDir = BackupConfig.normalizeWebDavRemoteDir(
      remoteDirRaw,
    );
    final next = _config.copyWith(
      webDavEnabled: true,
      webDavRemoteDir: normalizedRemoteDir,
    );
    setState(() => _config = next);
    try {
      await BackupConfig.save(next);
      if (!mounted) return false;
      AppNotifier.success(context, '已保存');
      return true;
    } catch (e) {
      if (!mounted) return false;
      AppNotifier.error(context, '保存失败：$e');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleAutoBackup(bool enabled) async {
    if (_saving) return;
    final previous = _config;
    final next = _config.copyWith(autoBackupEnabled: enabled);
    setState(() => _config = next);
    await _saveCloudSettings(next, fallback: previous);
  }

  Future<void> _saveCloudSettings(
    BackupConfig next, {
    BackupConfig? fallback,
  }) async {
    setState(() => _saving = true);
    try {
      await BackupConfig.save(next);
      if (!mounted) return;
      setState(() => _config = next);
    } catch (e) {
      if (!mounted) return;
      if (fallback != null) {
        setState(() => _config = fallback);
      }
      AppNotifier.error(context, '保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runBackup() async {
    final session = AppSessionScope.of(context);
    if (!session.networkAvailable) {
      AppNotifier.error(context, '网络异常，请稍后重试');
      return;
    }
    if (!_webDavReady) {
      AppNotifier.error(context, '请先完善 WebDAV 配置');
      return;
    }

    final remoteDirRaw = _config.webDavRemoteDir.trim();
    if (remoteDirRaw.isNotEmpty &&
        !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)) {
      AppNotifier.error(context, '远程目录格式不正确');
      return;
    }
    final nextConfig = _config.copyWith(
      webDavRemoteDir: BackupConfig.normalizeWebDavRemoteDir(remoteDirRaw),
    );
    if (nextConfig.webDavRemoteDir != _config.webDavRemoteDir) {
      setState(() => _config = nextConfig);
    }
    await BackupConfig.save(nextConfig);

    setState(() {
      _backingUp = true;
      _progress = const BackupProgress(
        stage: BackupStage.packaging,
        message: '准备中…',
      );
    });
    try {
      final service = DataBackupService();
      await service.run(
        config: nextConfig,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
        historyType: BackupHistoryType.manual,
      );
      await BackupStateStore.clearLastFailure(BackupTarget.cloud);
      final last = await BackupStateStore.getLastBackup();
      final history = await BackupStateStore.getHistory();
      final cloudFailure = await BackupStateStore.getLastFailure(
        BackupTarget.cloud,
      );
      if (!mounted) return;
      setState(() {
        _cloudLast = last;
        _history = history;
        _cloudFailure = cloudFailure;
      });
      AppNotifier.success(context, '备份完成');
    } on WebDavException catch (e) {
      await BackupStateStore.setLastFailure(
        target: BackupTarget.cloud,
        message: e.message,
      );
      if (mounted) {
        setState(() {
          _cloudFailure = BackupFailureState(
            target: BackupTarget.cloud,
            at: DateTime.now(),
            message: e.message,
          );
        });
      }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('备份失败'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      await BackupStateStore.setLastFailure(
        target: BackupTarget.cloud,
        message: e.toString(),
      );
      if (mounted) {
        setState(() {
          _cloudFailure = BackupFailureState(
            target: BackupTarget.cloud,
            at: DateTime.now(),
            message: e.toString(),
          );
        });
      }
      if (!mounted) return;
      AppNotifier.error(context, '备份失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _backingUp = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _testWebDav() async {
    final baseUrlRaw = _config.webDavBaseUrl.trim();
    if (baseUrlRaw.isEmpty) {
      AppNotifier.warning(context, '请先填写服务器地址');
      return;
    }
    final baseUrl = BackupConfig.parseAndNormalizeWebDavBaseUrl(baseUrlRaw);
    if (baseUrl == null) {
      AppNotifier.warning(context, '服务器地址格式不正确');
      return;
    }
    if (_config.webDavUsername.trim().isEmpty ||
        _config.webDavPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先填写用户名与密码')));
      return;
    }

    setState(() {
      _testing = true;
      _progress = const BackupProgress(
        stage: BackupStage.packaging,
        message: '正在测试连接…',
      );
    });
    final client = WebDavClient(
      baseUrl: baseUrl,
      username: _config.webDavUsername.trim(),
      password: _config.webDavPassword,
    );
    try {
      final r = await client.test();
      if (!mounted) return;
      if (r.ok) {
        await BackupStateStore.clearLastFailure(BackupTarget.cloud);
        final cloudFailure = await BackupStateStore.getLastFailure(
          BackupTarget.cloud,
        );
        setState(() => _cloudFailure = cloudFailure);
        AppNotifier.error(context, r.message);
      } else {
        await BackupStateStore.setLastFailure(
          target: BackupTarget.cloud,
          message: r.message,
        );
        setState(() {
          _cloudFailure = BackupFailureState(
            target: BackupTarget.cloud,
            at: DateTime.now(),
            message: r.message,
          );
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('连接失败'),
            content: Text(r.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } finally {
      await client.close();
      if (mounted) {
        setState(() {
          _testing = false;
          _progress = null;
        });
      }
    }
  }

  String _formatProgress(BackupProgress p) {
    final total = p.totalBytes;
    final sent = p.sentBytes;
    if (total == null || sent == null || total <= 0) return p.message;
    final percent = (sent / total * 100).clamp(0, 100).toStringAsFixed(0);
    return '${p.message} $percent%';
  }

  Future<void> _pickBackupFrequency() async {
    if (_saving) return;
    final picked = await showModalBottomSheet<BackupFrequency>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            borderRadius: AppRadii.br2xl,
            boxShadow: AppShadows.lg,
          ),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FrequencyOption(
                label: backupFrequencyLabel(BackupFrequency.daily),
                selected: _config.backupFrequency == BackupFrequency.daily,
                onTap: () => Navigator.of(context).pop(BackupFrequency.daily),
              ),
              const PrototypeDivider(color: AppColors.borderDivider),
              _FrequencyOption(
                label: backupFrequencyLabel(BackupFrequency.weekly),
                selected: _config.backupFrequency == BackupFrequency.weekly,
                onTap: () => Navigator.of(context).pop(BackupFrequency.weekly),
              ),
              const PrototypeDivider(color: AppColors.borderDivider),
              _FrequencyOption(
                label: backupFrequencyLabel(BackupFrequency.monthly),
                selected: _config.backupFrequency == BackupFrequency.monthly,
                onTap: () => Navigator.of(context).pop(BackupFrequency.monthly),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    final previous = _config;
    final next = _config.copyWith(backupFrequency: picked);
    setState(() => _config = next);
    await _saveCloudSettings(next, fallback: previous);
  }

  Future<void> _restoreBackup(BackupHistoryEntry entry) async {
    if (entry.target == BackupTarget.local) {
      await _restoreLocalBackupEntry(entry);
      return;
    }
    if (_restoring) return;
    if (!_webDavReady) {
      AppNotifier.error(context, '请先完善 WebDAV 配置');
      return;
    }
    final confirmed = await AppDialog.confirm(
      context,
      title: '确认恢复备份',
      message: '恢复将覆盖当前本地数据：${entry.fileName}',
      confirmLabel: '继续恢复',
      cancelLabel: '取消',
      tone: AppNotificationTone.warning,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _restoring = true;
      _progress = const BackupProgress(
        stage: BackupStage.packaging,
        message: '准备恢复…',
      );
    });
    try {
      final controller = AppDatabaseControllerScope.of(context);
      await controller.withDatabasePaused(() async {
        final service = DataRestoreService();
        await service.restoreFromRemote(
          config: _config,
          entry: entry,
          onProgress: (message) {
            if (!mounted) return;
            setState(() {
              _progress = BackupProgress(
                stage: BackupStage.packaging,
                message: message,
              );
            });
          },
        );
      });
      await BackupStateStore.clearLastFailure(BackupTarget.cloud);
      final cloudFailure = await BackupStateStore.getLastFailure(
        BackupTarget.cloud,
      );
      if (!mounted) return;
      setState(() => _cloudFailure = cloudFailure);
      AppNotifier.success(context, '恢复成功');
    } catch (e) {
      await BackupStateStore.setLastFailure(
        target: BackupTarget.cloud,
        message: e.toString(),
      );
      if (!mounted) return;
      setState(() {
        _cloudFailure = BackupFailureState(
          target: BackupTarget.cloud,
          at: DateTime.now(),
          message: e.toString(),
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('恢复失败：$e')));
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _openWebDavConfigDialog() async {
    if (_busy) return;
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.scrimBlack30,
      builder: (dialogContext) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _WebDavConfigDialog(
                  config: _config,
                  saving: _busy,
                  onChangedBaseUrl: (v) =>
                      _setConfig(_config.copyWith(webDavBaseUrl: v)),
                  onChangedUsername: (v) =>
                      _setConfig(_config.copyWith(webDavUsername: v)),
                  onChangedPassword: (v) =>
                      _setConfig(_config.copyWith(webDavPassword: v)),
                  onChangedRemoteDir: (v) =>
                      _setConfig(_config.copyWith(webDavRemoteDir: v)),
                  onTest: _busy ? null : _testWebDav,
                  onSave: _busy
                      ? null
                      : () async {
                          final ok = await _persistConfig();
                          if (!dialogContext.mounted || !ok) return;
                          Navigator.of(dialogContext).pop();
                        },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickLocalBackupDirectory() async {
    try {
      final pickedDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择本地备份目录',
      );
      if (pickedDir == null || pickedDir.trim().isEmpty) return;
      final service = DataBackupService();
      final pickedInfo = await service.inspectLocalBackupDirectory(
        preferredOutputDir: pickedDir,
      );
      if (!pickedInfo.writable) {
        await BackupStateStore.setPreferredLocalBackupDir(null);
        await _refreshLocalDirectoryInfo(preferredOutputDir: null);
        await _setLocalFailure('所选目录当前不可写，已继续使用默认备份目录');
        if (!mounted) return;
        AppNotifier.warning(
          context,
          '所选目录当前不可写，已继续使用默认备份目录',
        );
        return;
      }
      await BackupStateStore.setPreferredLocalBackupDir(pickedInfo.directory.path);
      await _refreshLocalDirectoryInfo(
        preferredOutputDir: pickedInfo.directory.path,
      );
      if (!mounted) return;
      AppNotifier.success(context, '已更新本地备份目录');
    } catch (_) {
      if (!mounted) return;
      AppNotifier.warning(
        context,
        '当前平台暂不支持选择目录，继续使用默认目录',
      );
    }
  }

  Future<void> _exportLocalBackup() async {
    if (_localBackingUp) return;
    final service = DataBackupService();
    if (mounted) {
      setState(() {
        _localBackingUp = true;
        _localRunningText = '准备导出…';
      });
    }
    try {
      final directoryInfo = await service.inspectLocalBackupDirectory(
        preferredOutputDir: _preferredLocalBackupDir,
      );
      if (!directoryInfo.writable) {
        await _setLocalFailure('备份目录不可写：${directoryInfo.directory.path}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份目录不可写：${directoryInfo.directory.path}')),
        );
        return;
      }
      final file = await service.exportLocalBackupZip(
        preferredOutputDir: _preferredLocalBackupDir,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _localRunningText = _formatProgress(progress));
        },
      );
      final sizeBytes = await file.length();
      final now = DateTime.now();
      await BackupStateStore.setLastBackupFor(
        target: BackupTarget.local,
        at: now,
        fileName: p.basename(file.path),
        sizeBytes: sizeBytes,
        localPath: file.path,
      );
      await BackupStateStore.addHistory(
        BackupHistoryEntry(
          type: BackupHistoryType.manual,
          at: now,
          fileName: p.basename(file.path),
          sizeBytes: sizeBytes,
          target: BackupTarget.local,
          localPath: file.path,
        ),
      );
      await BackupStateStore.clearLastFailure(BackupTarget.local);
      final localLast = await BackupStateStore.getLastBackupFor(
        BackupTarget.local,
      );
      final history = await BackupStateStore.getHistory();
      final localFailure = await BackupStateStore.getLastFailure(
        BackupTarget.local,
      );
      if (!mounted) return;
      setState(() {
        _localLast = localLast;
        _history = history;
        _localFailure = localFailure;
      });
      await _refreshLocalDirectoryInfo(
        preferredOutputDir: _preferredLocalBackupDir,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('本地备份已导出到：${file.path}')));
    } catch (e) {
      await _setLocalFailure(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('本地备份失败：$e')));
    } finally {
      if (mounted) {
        setState(() {
          _localBackingUp = false;
          _localRunningText = null;
        });
      }
    }
  }

  Future<void> _pickLocalBackupZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['zip'],
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null || picked.path!.trim().isEmpty) {
      AppNotifier.warning(context, '无法读取备份文件路径，请重试');
      return;
    }
    await _restoreLocalZipFile(
      filePath: picked.path!,
      displayName: picked.name,
    );
  }

  Future<void> _restoreLocalBackupEntry(BackupHistoryEntry entry) async {
    final localPath = entry.localPath?.trim() ?? '';
    if (localPath.isEmpty) {
      await _setLocalFailure('本地备份记录缺少文件路径');
      if (!mounted) return;
      AppNotifier.warning(context, '本地备份记录缺少文件路径');
      return;
    }
    if (!await File(localPath).exists()) {
      await _setLocalFailure('本地备份文件不存在：$localPath');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('本地备份文件不存在')));
      return;
    }
    await _restoreLocalZipFile(
      filePath: localPath,
      displayName: entry.fileName,
    );
  }

  Future<void> _restoreLocalZipFile({
    required String filePath,
    required String displayName,
  }) async {
    if (_localRestoring) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认导入恢复'),
          content: Text('恢复将覆盖当前本地数据：$displayName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续恢复'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _localRestoring = true;
      _localRunningText = '准备恢复…';
    });
    try {
      final controller = AppDatabaseControllerScope.of(context);
      await controller.withDatabasePaused(() async {
        final service = DataRestoreService();
        await service.restoreFromLocalPath(
          zipFilePath: filePath,
          onProgress: (message) {
            if (!mounted) return;
            setState(() => _localRunningText = message);
          },
        );
      });
      await BackupStateStore.clearLastFailure(BackupTarget.local);
      final localFailure = await BackupStateStore.getLastFailure(
        BackupTarget.local,
      );
      if (!mounted) return;
      setState(() => _localFailure = localFailure);
      AppNotifier.success(context, '本地恢复成功');
    } catch (e) {
      await _setLocalFailure(e.toString());
      if (!mounted) return;
      AppNotifier.error(context, '本地恢复失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _localRestoring = false;
          _localRunningText = null;
        });
      }
    }
  }

  Future<void> _setLocalFailure(String message) async {
    await BackupStateStore.setLastFailure(
      target: BackupTarget.local,
      message: message,
    );
    final failure = await BackupStateStore.getLastFailure(BackupTarget.local);
    if (!mounted) return;
    setState(() => _localFailure = failure);
  }
}

String _formatBackupTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${DateUtil.format(d)} ${two(d.hour)}:${two(d.minute)}';
}

String _formatBackupSemanticTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  // 语义朗读优先使用纯数字时间，避免把农历等装饰性信息混入操作摘要，影响理解效率。
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

String _formatBackupSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  final kb = bytes / 1024.0;
  if (kb < 1024) return '${kb.toStringAsFixed(1)}KB';
  final mb = kb / 1024.0;
  if (mb < 1024) return '${mb.toStringAsFixed(1)}MB';
  final gb = mb / 1024.0;
  return '${gb.toStringAsFixed(1)}GB';
}

class _DriveExtraConfigCard extends StatelessWidget {
  const _DriveExtraConfigCard({
    required this.loading,
    required this.config,
    required this.last,
    required this.running,
    required this.runningText,
    required this.saving,
    required this.onBackup,
    required this.onToggleAutoBackup,
    required this.onPickFrequency,
    required this.webDavConfigured,
    required this.onOpenWebDavConfig,
  });

  final bool loading;
  final BackupConfig config;
  final BackupLastState? last;
  final bool running;
  final String? runningText;
  final bool saving;
  final VoidCallback? onBackup;
  final ValueChanged<bool>? onToggleAutoBackup;
  final VoidCallback? onPickFrequency;
  final bool webDavConfigured;
  final VoidCallback? onOpenWebDavConfig;

  @override
  Widget build(BuildContext context) {
    final statusLabel = config.webDavEnabled ? '已开启' : '未开启';
    final detailText = running
        ? (runningText ?? '备份中…')
        : (loading
              ? '读取配置中…'
              : (last == null
                    ? '暂无备份记录'
                    : '上次备份：${_formatBackupTime(last!.at)} • ${_formatBackupSize(last!.sizeBytes)}'));
    final subtitle = '$statusLabel · $detailText';
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: config.webDavEnabled
                            ? context.appColors.stateSuccessSoft
                            : context.appColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: FaIcon(
                        FontAwesomeIcons.cloudArrowUp,
                        size: 16,
                        color: config.webDavEnabled
                            ? context.appColors.stateSuccess
                            : context.appColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '备份状态',
                            style: AppTypography.base(
                              fontSize: 16,
                              fontWeight: AppTypography.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrototypePrimaryButton(
                  label: running ? '备份中' : '立即备份',
                  onTap: onBackup,
                ),
              ],
            ),
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _OptionRow(
            title: '自动备份',
            subtitle: '仅在 Wi-Fi 环境下进行',
            trailing: _Toggle(
              value: config.autoBackupEnabled,
              onChanged: saving ? null : onToggleAutoBackup,
              semanticLabel: '自动备份',
            ),
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _OptionRow(
            title: '备份频率',
            subtitle: backupFrequencyLabel(config.backupFrequency),
            trailing: const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 10,
              color: AppColors.gray300,
            ),
            onTap: saving ? null : onPickFrequency,
            semanticLabel: '备份频率',
            semanticValue: backupFrequencyLabel(config.backupFrequency),
            semanticHint: '打开备份频率选择',
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _OptionRow(
            title: 'WebDAV 配置',
            subtitle: webDavConfigured ? '已配置' : '未设置',
            trailing: const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 10,
              color: AppColors.gray300,
            ),
            onTap: saving ? null : onOpenWebDavConfig,
            semanticLabel: 'WebDAV 配置',
            semanticValue: webDavConfigured ? '已配置' : '未设置',
            semanticHint: '打开 WebDAV 配置',
          ),
        ],
      ),
    );
  }
}

class _LocalBackupSectionCard extends StatelessWidget {
  const _LocalBackupSectionCard({
    required this.resolvedPath,
    required this.pathWritable,
    required this.usingDefault,
    required this.last,
    required this.failure,
    required this.running,
    required this.runningText,
    required this.onPickDirectory,
    required this.onExport,
    required this.onImport,
  });

  final String resolvedPath;
  final bool? pathWritable;
  final bool usingDefault;
  final BackupLastState? last;
  final BackupFailureState? failure;
  final bool running;
  final String? runningText;
  final VoidCallback? onPickDirectory;
  final VoidCallback? onExport;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final subtitle = running
        ? (runningText ?? '处理中…')
        : (last == null
              ? '尚未生成本地备份'
              : '最近一次本地备份：${_formatBackupTime(last!.at)} • ${_formatBackupSize(last!.sizeBytes)}');
    final failureText = failure == null ? '暂无失败记录' : '最近失败：${failure!.message}';
    final pathStatusText = pathWritable == null
        ? '目录状态读取中…'
        : (pathWritable! ? (usingDefault ? '默认目录，可写' : '自定义目录，可写') : '目录不可写');
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  FontAwesomeIcons.hardDrive,
                  size: 16,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本地 ZIP 备份',
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BackupInfoLine(label: '保存位置', value: resolvedPath),
          const SizedBox(height: 8),
          _BackupInfoLine(label: '目录状态', value: pathStatusText),
          const SizedBox(height: 8),
          _BackupInfoLine(label: '状态', value: failureText),
          const SizedBox(height: 16),
          PrototypeSecondaryButton(
            label: '更改位置',
            onTap: onPickDirectory,
            semanticLabel: '更改本地备份保存位置',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrototypeSecondaryButton(
                  label: running && onExport == null ? '处理中' : '导出备份',
                  onTap: onExport,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrototypeSecondaryButton(label: '导入恢复', onTap: onImport),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackupStatusSummaryCard extends StatelessWidget {
  const _BackupStatusSummaryCard({
    required this.cloudLast,
    required this.localLast,
    required this.cloudFailure,
    required this.localFailure,
    required this.runningText,
    required this.cloudRunning,
    required this.localRunning,
    required this.localRunningText,
  });

  final BackupLastState? cloudLast;
  final BackupLastState? localLast;
  final BackupFailureState? cloudFailure;
  final BackupFailureState? localFailure;
  final String? runningText;
  final bool cloudRunning;
  final bool localRunning;
  final String? localRunningText;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _BackupStatusTile(
            icon: FontAwesomeIcons.cloudArrowUp,
            title: 'WebDAV云端备份',
            statusText: cloudRunning
                ? (runningText ?? '处理中…')
                : (cloudLast == null
                      ? '暂无成功记录'
                      : '最近成功：${_formatBackupTime(cloudLast!.at)}'),
            detailText: cloudFailure == null
                ? '最近失败：无'
                : '最近失败：${_formatBackupTime(cloudFailure!.at)} • ${cloudFailure!.message}',
          ),
          const SizedBox(height: 12),
          const PrototypeDivider(color: AppColors.borderDivider),
          const SizedBox(height: 12),
          _BackupStatusTile(
            icon: FontAwesomeIcons.hardDrive,
            title: '本地备份',
            statusText: localRunning
                ? (localRunningText ?? '处理中…')
                : (localLast == null
                      ? '暂无成功记录'
                      : '最近成功：${_formatBackupTime(localLast!.at)}'),
            detailText: localFailure == null
                ? '最近失败：无'
                : '最近失败：${_formatBackupTime(localFailure!.at)} • ${localFailure!.message}',
          ),
        ],
      ),
    );
  }
}

class _BackupStatusTile extends StatelessWidget {
  const _BackupStatusTile({
    required this.icon,
    required this.title,
    required this.statusText,
    required this.detailText,
  });

  final IconData icon;
  final String title;
  final String statusText;
  final String detailText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.appColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: FaIcon(icon, size: 14, color: context.appColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.base(
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: AppTypography.base(
                  fontSize: 12,
                  fontWeight: AppTypography.regular,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detailText,
                style: AppTypography.base(
                  fontSize: 12,
                  fontWeight: AppTypography.regular,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackupHistoryCard extends StatelessWidget {
  const _BackupHistoryCard({required this.history, required this.onRestore});

  final List<BackupHistoryEntry> history;
  final ValueChanged<BackupHistoryEntry>? onRestore;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.isEmpty)
            Text(
              '暂无历史备份',
              style: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < history.length; i++) ...[
                  _BackupHistoryItem(
                    entry: history[i],
                    onRestore: onRestore == null
                        ? null
                        : (history[i].target == BackupTarget.local &&
                                  (history[i].localPath?.trim().isEmpty ?? true)
                              ? null
                              : () => onRestore!(history[i])),
                  ),
                  if (i != history.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _BackupInfoLine extends StatelessWidget {
  const _BackupInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.medium,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.regular,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _WebDavConfigDialog extends StatefulWidget {
  const _WebDavConfigDialog({
    required this.config,
    required this.saving,
    required this.onChangedBaseUrl,
    required this.onChangedUsername,
    required this.onChangedPassword,
    required this.onChangedRemoteDir,
    required this.onTest,
    required this.onSave,
  });

  final BackupConfig config;
  final bool saving;
  final ValueChanged<String> onChangedBaseUrl;
  final ValueChanged<String> onChangedUsername;
  final ValueChanged<String> onChangedPassword;
  final ValueChanged<String> onChangedRemoteDir;
  final VoidCallback? onTest;
  final VoidCallback? onSave;

  @override
  State<_WebDavConfigDialog> createState() => _WebDavConfigDialogState();
}

class _WebDavConfigDialogState extends State<_WebDavConfigDialog> {
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _remoteDirCtrl;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _baseUrlCtrl = TextEditingController(text: widget.config.webDavBaseUrl);
    _usernameCtrl = TextEditingController(text: widget.config.webDavUsername);
    _passwordCtrl = TextEditingController(text: widget.config.webDavPassword);
    _remoteDirCtrl = TextEditingController(text: widget.config.webDavRemoteDir);
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _remoteDirCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = widget.saving;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: AppRadii.br3xl,
          boxShadow: AppShadows.lg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InputRow(
              title: '服务器地址',
              hintText: '例如：https://example.com/remote.php/dav/files/user/',
              controller: _baseUrlCtrl,
              enabled: !saving,
              onChanged: widget.onChangedBaseUrl,
            ),
            const PrototypeDivider(color: AppColors.borderDivider),
            _InputRow(
              title: '用户名',
              hintText: '请输入用户名',
              controller: _usernameCtrl,
              enabled: !saving,
              onChanged: widget.onChangedUsername,
            ),
            const PrototypeDivider(color: AppColors.borderDivider),
            _InputRow(
              title: '密码',
              hintText: '请输入密码',
              controller: _passwordCtrl,
              enabled: !saving,
              obscureText: _obscurePassword,
              onToggleObscure: () {
                if (saving) return;
                setState(() => _obscurePassword = !_obscurePassword);
              },
              onChanged: widget.onChangedPassword,
            ),
            const PrototypeDivider(color: AppColors.borderDivider),
            _InputRow(
              title: '远程目录',
              hintText: '（可选）例如：backup/newshangli',
              controller: _remoteDirCtrl,
              enabled: !saving,
              onChanged: widget.onChangedRemoteDir,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '提示：启用后需至少填写地址、用户名、密码',
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: PrototypeSecondaryButton(
                          label: saving ? '测试中' : '测试连接',
                          onTap: widget.onTest,
                          semanticLabel: '测试 WebDAV 连接',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrototypePrimaryButton(
                          label: saving ? '保存中' : '保存配置',
                          onTap: widget.onSave,
                          semanticLabel: '保存 WebDAV 配置',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.title,
    required this.hintText,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.obscureText = false,
    this.onToggleObscure,
  });

  final String title;
  final String hintText;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.medium,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            obscureText: obscureText,
            style: AppTypography.base(
              fontSize: 13,
              fontWeight: AppTypography.regular,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.base(
                fontSize: 13,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
              isDense: true,
              filled: true,
              fillColor: context.appColors.surfaceSubtle,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderFocus),
              ),
              suffixIcon: onToggleObscure == null
                  ? null
                  : IconButton(
                      onPressed: enabled ? onToggleObscure : null,
                      tooltip: obscureText ? '显示密码' : '隐藏密码',
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _BackupHistoryItem extends StatelessWidget {
  const _BackupHistoryItem({required this.entry, required this.onRestore});

  final BackupHistoryEntry entry;
  final VoidCallback? onRestore;

  String get _restoreSemanticValue =>
      '${backupHistoryTypeLabel(entry.type)}，${_formatBackupSemanticTime(entry.at)}，${_formatBackupSize(entry.sizeBytes)}';

  String get _restoreSemanticHint =>
      onRestore == null ? '当前不可恢复该备份' : '双击后恢复文件 ${entry.fileName}，并覆盖当前本地数据';

  @override
  Widget build(BuildContext context) {
    final handleRestore = onRestore;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSubtle,
        borderRadius: AppRadii.brXl,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.appColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: FaIcon(
              FontAwesomeIcons.fileLines,
              size: 16,
              color: context.appColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backupHistoryTypeLabel(entry.type),
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.target == BackupTarget.local ? '本地备份' : 'WebDAV云端备份',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatBackupTime(entry.at)} • ${_formatBackupSize(entry.sizeBytes)}',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            enabled: onRestore != null,
            label: '恢复备份文件 ${entry.fileName}',
            value: _restoreSemanticValue,
            hint: _restoreSemanticHint,
            onTap: handleRestore,
            // 将“备份文件标识 + 条目摘要 + 恢复动作”合并成单一语义节点，
            // 让读屏和自动化测试都能稳定获取可操作信息。
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: handleRestore,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceCard,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: context.appColors.borderDefault),
                  ),
                  child: Text(
                    '恢复',
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  const _FrequencyOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: PrototypePressableRow(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const FaIcon(
                  FontAwesomeIcons.check,
                  size: 14,
                  color: AppColors.green500,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
    this.semanticLabel,
    this.semanticValue,
    this.semanticHint,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticValue;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final row = PrototypePressableRow(
      onTap: onTap,
      borderBottom: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.regular,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel ?? title,
      value: semanticValue ?? subtitle,
      hint: semanticHint,
      // 行级语义用于把“标题 + 当前值 + 打开动作”合并成一条稳定朗读信息。
      child: ExcludeSemantics(child: row),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final on = value;
    final handleToggle = enabled ? () => onChanged!(!value) : null;
    final colors = context.appColors;
    final bg = !enabled
        ? colors.surfaceDisabled
        : (on ? colors.stateSuccess : colors.surfaceDisabled);
    final alignment = on ? Alignment.centerRight : Alignment.centerLeft;
    return Semantics(
      button: true,
      enabled: enabled,
      checked: value,
      label: semanticLabel,
      value: value ? '已开启' : '已关闭',
      hint: enabled ? '双击切换自动备份开关' : '自动备份开关当前不可切换',
      onTap: handleToggle,
      // 自定义开关没有原生 Switch 的状态播报，这里补足状态值与操作提示，
      // 让“自动备份”不仅能被识别，还能明确当前状态和下一步动作。
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: handleToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Align(
              alignment: alignment,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceCard,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.sm,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Overline extends StatelessWidget {
  const _Overline({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.base(
          fontSize: 12,
          fontWeight: AppTypography.bold,
          color: AppColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
