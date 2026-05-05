import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../backup/backup_config.dart';
import '../../backup/data_backup_service.dart';
import '../../backup/data_restore_service.dart';
import '../../backup/webdav_client.dart';
import '../app_database_scope.dart';
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
  BackupLastState? _last;
  List<BackupHistoryEntry> _history = const <BackupHistoryEntry>[];
  bool _loading = true;
  bool _saving = false;
  bool _backingUp = false;
  bool _testing = false;
  bool _restoring = false;
  BackupProgress? _progress;

  bool get _webDavReady {
    if (!_config.webDavEnabled) return false;
    if (_config.webDavBaseUrl.trim().isEmpty) return false;
    if (_config.webDavUsername.trim().isEmpty) return false;
    if (_config.webDavPassword.isEmpty) return false;
    return true;
  }

  bool get _busy => _saving || _backingUp || _testing || _restoring;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final c = await BackupConfig.load();
      final last = await BackupStateStore.getLastBackup();
      final history = await BackupStateStore.getHistory();
      final remoteDirRaw = c.webDavRemoteDir.trim();
      final normalizedRemoteDir =
          remoteDirRaw.isNotEmpty &&
              !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)
          ? ''
          : remoteDirRaw;
      if (!mounted) return;
      setState(() {
        _config = c.copyWith(webDavRemoteDir: normalizedRemoteDir);
        _last = last;
        _history = history;
        _loading = false;
      });
    });
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
              _BackupMainCard(
                loading: _loading,
                enabled: _config.webDavEnabled,
                last: _last,
                runningText: progressText,
                running: _backingUp,
                onBackup: _busy ? null : _runBackup,
              ),
              const SizedBox(height: 24),
              _Overline(title: '备份设置'),
              const SizedBox(height: 12),
              _DriveExtraConfigCard(
                config: _config,
                history: _history,
                saving: _busy,
                onToggleAutoBackup: (v) =>
                    _setConfig(_config.copyWith(autoBackupEnabled: v)),
                onPickFrequency: _busy ? null : _pickBackupFrequency,
                webDavConfigured: _webDavReady,
                onOpenWebDavConfig: _busy ? null : _openWebDavConfigDialog,
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

  Future<bool> _persistConfig() async {
    setState(() => _saving = true);
    final remoteDirRaw = _config.webDavRemoteDir.trim();
    if (remoteDirRaw.isNotEmpty &&
        !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('远程目录格式不正确')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已保存')));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runBackup() async {
    final session = AppSessionScope.of(context);
    if (!session.networkAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('网络异常，请稍后重试')));
      return;
    }
    if (!_webDavReady) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先完善 WebDAV 配置')));
      return;
    }

    final remoteDirRaw = _config.webDavRemoteDir.trim();
    if (remoteDirRaw.isNotEmpty &&
        !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('远程目录格式不正确')));
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
      final last = await BackupStateStore.getLastBackup();
      final history = await BackupStateStore.getHistory();
      if (!mounted) return;
      setState(() {
        _last = last;
        _history = history;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('备份完成')));
    } on WebDavException catch (e) {
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('备份失败：$e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先填写服务器地址')));
      return;
    }
    final baseUrl = BackupConfig.parseAndNormalizeWebDavBaseUrl(baseUrlRaw);
    if (baseUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('服务器地址格式不正确')));
      return;
    }
    if (_config.webDavUsername.trim().isEmpty ||
        _config.webDavPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先填写用户名与密码')));
      return;
    }

    setState(() => _testing = true);
    final client = WebDavClient(
      baseUrl: baseUrl,
      username: _config.webDavUsername.trim(),
      password: _config.webDavPassword,
    );
    try {
      final r = await client.test();
      if (!mounted) return;
      if (r.ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(r.message)));
      } else {
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
      if (mounted) setState(() => _testing = false);
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
    _setConfig(_config.copyWith(backupFrequency: picked));
  }

  Future<void> _restoreBackup(BackupHistoryEntry entry) async {
    if (_restoring) return;
    if (!_webDavReady) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先完善 WebDAV 配置')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认恢复备份'),
          content: Text('恢复将覆盖当前本地数据：${entry.fileName}'),
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('恢复成功')));
    } catch (e) {
      if (!mounted) return;
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
}

String _formatBackupTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${DateUtil.format(d)} ${two(d.hour)}:${two(d.minute)}';
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

class _BackupMainCard extends StatelessWidget {
  const _BackupMainCard({
    required this.loading,
    required this.enabled,
    required this.last,
    required this.running,
    required this.runningText,
    required this.onBackup,
  });

  final bool loading;
  final bool enabled;
  final BackupLastState? last;
  final bool running;
  final String? runningText;
  final VoidCallback? onBackup;

  @override
  Widget build(BuildContext context) {
    final subtitle = running
        ? (runningText ?? '备份中…')
        : (loading
              ? '读取配置中…'
              : (last == null
                    ? '暂无备份记录'
                    : '上次备份：${_formatBackupTime(last!.at)} • ${_formatBackupSize(last!.sizeBytes)}'));
    final title = enabled ? '云端备份已开启' : '云端备份未开启';
    return PrototypeCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: enabled
                  ? context.appColors.stateSuccessSoft
                  : context.appColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: FaIcon(
              FontAwesomeIcons.cloudArrowUp,
              size: 30,
              color: enabled
                  ? context.appColors.stateSuccess
                  : context.appColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.base(
              fontSize: 18,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.regular,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          PrototypePrimaryButton(
            label: running ? '备份中' : '立即备份',
            onTap: onBackup,
          ),
        ],
      ),
    );
  }
}

class _DriveExtraConfigCard extends StatelessWidget {
  const _DriveExtraConfigCard({
    required this.config,
    required this.history,
    required this.saving,
    required this.onToggleAutoBackup,
    required this.onPickFrequency,
    required this.webDavConfigured,
    required this.onOpenWebDavConfig,
    required this.onRestore,
  });

  final BackupConfig config;
  final List<BackupHistoryEntry> history;
  final bool saving;
  final ValueChanged<bool> onToggleAutoBackup;
  final VoidCallback? onPickFrequency;
  final bool webDavConfigured;
  final VoidCallback? onOpenWebDavConfig;
  final ValueChanged<BackupHistoryEntry>? onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _OptionRow(
            title: '自动备份',
            subtitle: '仅在 Wi-Fi 环境下进行',
            trailing: _Toggle(
              value: config.autoBackupEnabled,
              onChanged: saving ? null : onToggleAutoBackup,
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
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _OptionRow(
            title: '网盘配置（WebDAV）',
            subtitle: webDavConfigured ? '已配置' : '未设置',
            trailing: const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 10,
              color: AppColors.gray300,
            ),
            onTap: saving ? null : onOpenWebDavConfig,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '历史备份',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                if (history.isNotEmpty)
                  Column(
                    children: [
                      for (int i = 0; i < history.length; i++) ...[
                        _BackupHistoryItem(
                          entry: history[i],
                          onRestore: onRestore == null
                              ? null
                              : () => onRestore!(history[i]),
                        ),
                        if (i != history.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrototypePrimaryButton(
                          label: saving ? '保存中' : '保存配置',
                          onTap: widget.onSave,
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

  @override
  Widget build(BuildContext context) {
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
          GestureDetector(
            onTap: onRestore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
    return PrototypePressableRow(
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
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
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
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final on = value;
    final colors = context.appColors;
    final bg = !enabled
        ? colors.surfaceDisabled
        : (on ? colors.stateSuccess : colors.surfaceDisabled);
    final alignment = on ? Alignment.centerRight : Alignment.centerLeft;
    return GestureDetector(
      onTap: enabled ? () => onChanged!(!value) : null,
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
