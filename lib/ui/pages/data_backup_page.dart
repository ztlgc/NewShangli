import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../backup/backup_config.dart';
import '../../backup/data_backup_service.dart';
import '../../backup/webdav_client.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../app_session.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

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
    webDavRemoteDir: BackupConfig.defaultWebDavRemoteDir,
    autoBackupEnabled: false,
    backupFrequency: BackupFrequency.daily,
  );
  BackupLastState? _last;
  List<BackupHistoryEntry> _history = const <BackupHistoryEntry>[];
  bool _loading = true;
  bool _saving = false;
  bool _backingUp = false;
  bool _testing = false;
  BackupProgress? _progress;

  bool get _webDavReady {
    if (!_config.webDavEnabled) return false;
    if (_config.webDavBaseUrl.trim().isEmpty) return false;
    if (_config.webDavUsername.trim().isEmpty) return false;
    if (_config.webDavPassword.isEmpty) return false;
    return true;
  }

  bool get _busy => _saving || _backingUp || _testing;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final c = await BackupConfig.load();
      final last = await BackupStateStore.getLastBackup();
      final history = await BackupStateStore.getHistory();
      final remoteDirRaw = c.webDavRemoteDir.trim();
      final normalizedRemoteDir = remoteDirRaw.isEmpty || !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)
          ? BackupConfig.defaultWebDavRemoteDir
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
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
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
              _Overline(title: '网盘设置（WebDAV）'),
              const SizedBox(height: 12),
              _WebDavConfigCard(
                config: _config,
                saving: _busy,
                onToggleEnabled: (v) => _setConfig(_config.copyWith(webDavEnabled: v)),
                onEditBaseUrl: () => _editAndSet(
                  title: '服务器地址',
                  label: '地址',
                  initial: _config.webDavBaseUrl,
                  hintText: '例如：https://example.com/remote.php/dav/files/user/',
                  multiline: false,
                  requiredField: true,
                  onValue: (v) => _setConfig(_config.copyWith(webDavBaseUrl: v)),
                ),
                onEditUsername: () => _editAndSet(
                  title: '用户名',
                  label: '用户名',
                  initial: _config.webDavUsername,
                  hintText: '请输入用户名',
                  multiline: false,
                  requiredField: true,
                  onValue: (v) => _setConfig(_config.copyWith(webDavUsername: v)),
                ),
                onEditPassword: () => _editAndSet(
                  title: '密码',
                  label: '密码',
                  initial: _config.webDavPassword,
                  hintText: '请输入密码',
                  multiline: false,
                  requiredField: true,
                  obscureText: true,
                  onValue: (v) => _setConfig(_config.copyWith(webDavPassword: v)),
                ),
                onEditRemoteDir: () => _editAndSet(
                  title: '远程目录',
                  label: '目录',
                  initial: _config.webDavRemoteDir,
                  hintText: '例如：backup/newshangli',
                  multiline: false,
                  requiredField: false,
                  onValue: (v) => _setConfig(_config.copyWith(webDavRemoteDir: v)),
                ),
                onTest: _busy ? null : _testWebDav,
                onSave: _busy ? null : _persistConfig,
                readyHint: _webDavReady,
              ),
              const SizedBox(height: 16),
              _DriveExtraConfigCard(
                config: _config,
                history: _history,
                saving: _busy,
                onToggleAutoBackup: (v) => _setConfig(_config.copyWith(autoBackupEnabled: v)),
                onPickFrequency: _busy ? null : _pickBackupFrequency,
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

  Future<void> _persistConfig() async {
    setState(() => _saving = true);
    final remoteDirRaw = _config.webDavRemoteDir.trim();
    if (remoteDirRaw.isNotEmpty && !BackupConfig.isValidWebDavRemoteDir(remoteDirRaw)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('远程目录格式不正确')),
        );
        setState(() => _saving = false);
      }
      return;
    }
    final normalizedRemoteDir = BackupConfig.normalizeWebDavRemoteDir(remoteDirRaw);
    final next = _config.copyWith(webDavRemoteDir: normalizedRemoteDir);
    setState(() => _config = next);
    try {
      await BackupConfig.save(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runBackup() async {
    final session = AppSessionScope.of(context);
    if (!session.networkAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络异常，请稍后重试')),
      );
      return;
    }
    if (!_webDavReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先完善 WebDAV 配置')),
      );
      return;
    }

    setState(() {
      _backingUp = true;
      _progress = const BackupProgress(stage: BackupStage.packaging, message: '准备中…');
    });
    try {
      final service = DataBackupService();
      await service.run(
        config: _config,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份完成')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份失败：$e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写服务器地址')),
      );
      return;
    }
    final baseUrl = Uri.tryParse(baseUrlRaw);
    if (baseUrl == null || (!baseUrl.hasScheme) || baseUrl.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('服务器地址格式不正确')),
      );
      return;
    }
    if (_config.webDavUsername.trim().isEmpty || _config.webDavPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写用户名与密码')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message)),
      );
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
          decoration: const BoxDecoration(
            color: AppColors.white,
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

  void _restoreBackup(BackupHistoryEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已选择恢复：${entry.fileName}')),
    );
  }

  Future<void> _editAndSet({
    required String title,
    required String label,
    required String initial,
    required String hintText,
    required bool multiline,
    required bool requiredField,
    required ValueChanged<String> onValue,
    bool obscureText = false,
  }) async {
    if (_saving) return;
    final v = await _editText(
      title: title,
      label: label,
      initial: initial,
      hintText: hintText,
      multiline: multiline,
      requiredField: requiredField,
      obscureText: obscureText,
    );
    if (v == null) return;
    onValue(v);
  }

  Future<String?> _editText({
    required String title,
    required String label,
    required String initial,
    required String hintText,
    required bool multiline,
    required bool requiredField,
    required bool obscureText,
    TextInputType? keyboardType,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final ok = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        var saving = false;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadii.br2xl,
              boxShadow: AppShadows.lg,
            ),
            clipBehavior: Clip.antiAlias,
            child: StatefulBuilder(
              builder: (context, setState) {
                final canSubmit = !saving && (!requiredField || ctrl.text.trim().isNotEmpty);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          PrototypeIconButton(
                            icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                            backgroundColor: AppColors.gray100,
                            foregroundColor: AppColors.textSecondary,
                            onPressed: saving ? null : () => Navigator.of(context).pop(),
                            radius: 12,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTypography.base(
                                fontSize: 12,
                                fontWeight: AppTypography.medium,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(text: label),
                                if (requiredField)
                                  const TextSpan(
                                    text: ' *',
                                    style: TextStyle(color: AppColors.red500),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: ctrl,
                            obscureText: obscureText,
                            keyboardType: keyboardType,
                            maxLines: multiline ? 4 : 1,
                            minLines: multiline ? 4 : 1,
                            style: AppTypography.base(
                              fontSize: 14,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: hintText,
                              hintStyle: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.regular,
                                color: AppColors.textMuted,
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.gray50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.gray100),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.gray100),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                // 使用主题内已定义的焦点边框色，避免引用不存在的色值常量。
                                borderSide: const BorderSide(color: AppColors.borderFocus),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          PrototypePrimaryButton(
                            label: saving ? '保存中' : '确定',
                            onTap: canSubmit
                                ? () async {
                                    setState(() => saving = true);
                                    try {
                                      Navigator.of(context).pop(ctrl.text.trim());
                                    } finally {
                                      setState(() => saving = false);
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    return ok;
  }
}

String _formatBackupTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
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
            decoration: BoxDecoration(color: enabled ? AppColors.green50 : AppColors.gray100, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: FaIcon(
              FontAwesomeIcons.cloudArrowUp,
              size: 30,
              color: enabled ? AppColors.green500 : AppColors.textTertiary,
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
          PrototypePrimaryButton(label: running ? '备份中' : '立即备份', onTap: onBackup),
        ],
      ),
    );
  }
}

class _WebDavConfigCard extends StatelessWidget {
  const _WebDavConfigCard({
    required this.config,
    required this.saving,
    required this.onToggleEnabled,
    required this.onEditBaseUrl,
    required this.onEditUsername,
    required this.onEditPassword,
    required this.onEditRemoteDir,
    required this.onTest,
    required this.onSave,
    required this.readyHint,
  });

  final BackupConfig config;
  final bool saving;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onEditBaseUrl;
  final VoidCallback onEditUsername;
  final VoidCallback onEditPassword;
  final VoidCallback onEditRemoteDir;
  final VoidCallback? onTest;
  final VoidCallback? onSave;
  final bool readyHint;

  @override
  Widget build(BuildContext context) {
    final passwordMasked = config.webDavPassword.isEmpty ? '' : '••••••••';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _OptionRow(
            title: '启用 WebDAV 备份',
            subtitle: '开启后，备份文件会上传到你的网盘目录',
            trailing: _Toggle(
              value: config.webDavEnabled,
              onChanged: saving ? null : onToggleEnabled,
            ),
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _OptionRow(
            title: '服务器地址',
            subtitle: config.webDavBaseUrl.isEmpty ? '未设置' : config.webDavBaseUrl,
            trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
            onTap: saving ? null : onEditBaseUrl,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _OptionRow(
            title: '用户名',
            subtitle: config.webDavUsername.isEmpty ? '未设置' : config.webDavUsername,
            trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
            onTap: saving ? null : onEditUsername,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _OptionRow(
            title: '密码',
            subtitle: passwordMasked.isEmpty ? '未设置' : passwordMasked,
            trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
            onTap: saving ? null : onEditPassword,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _OptionRow(
            title: '远程目录',
            subtitle: config.webDavRemoteDir.isEmpty ? '（可选）例如：backup/newshangli' : config.webDavRemoteDir,
            trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
            onTap: saving ? null : onEditRemoteDir,
            borderBottom: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!readyHint)
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
                        onTap: onTest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrototypePrimaryButton(
                        label: saving ? '保存中' : '保存配置',
                        onTap: onSave,
                      ),
                    ),
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

class _DriveExtraConfigCard extends StatelessWidget {
  const _DriveExtraConfigCard({
    required this.config,
    required this.history,
    required this.saving,
    required this.onToggleAutoBackup,
    required this.onPickFrequency,
    required this.onRestore,
  });

  final BackupConfig config;
  final List<BackupHistoryEntry> history;
  final bool saving;
  final ValueChanged<bool> onToggleAutoBackup;
  final VoidCallback? onPickFrequency;
  final ValueChanged<BackupHistoryEntry>? onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
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
            trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
            onTap: saving ? null : onPickFrequency,
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
                          onRestore: onRestore == null ? null : () => onRestore!(history[i]),
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

class _BackupHistoryItem extends StatelessWidget {
  const _BackupHistoryItem({
    required this.entry,
    required this.onRestore,
  });

  final BackupHistoryEntry entry;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadii.brXl,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const FaIcon(FontAwesomeIcons.fileLines, size: 16, color: AppColors.gray500),
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
                color: AppColors.white,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.gray200),
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
          if (selected) const FaIcon(FontAwesomeIcons.check, size: 14, color: AppColors.green500),
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
    this.borderBottom = true,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: onTap,
      borderBottom: borderBottom,
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
    final bg = !enabled
        ? AppColors.gray200
        : (on ? AppColors.green500 : AppColors.gray200);
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
            decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: AppShadows.sm),
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
