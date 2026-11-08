import 'dart:async';

import 'package:flutter/material.dart';

import '../update/app_update_service.dart';
import '../update/app_version.dart';
import 'app_dialog.dart';
import 'app_notifier.dart';

enum _UpdateAction { download, later, ignore }

/// Shares version information and a single check/dialog lock with settings.
class AppUpdateScope extends InheritedWidget {
  const AppUpdateScope({
    super.key,
    required this.versionLabel,
    required this.checking,
    required this.checkForUpdates,
    required super.child,
  });

  final String versionLabel;
  final bool checking;
  final VoidCallback checkForUpdates;

  static AppUpdateScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppUpdateScope>();

  @override
  bool updateShouldNotify(AppUpdateScope oldWidget) =>
      versionLabel != oldWidget.versionLabel || checking != oldWidget.checking;
}

class AppUpdateHost extends StatefulWidget {
  const AppUpdateHost({super.key, required this.child, this.service});

  final Widget child;
  final AppUpdateService? service;

  @override
  State<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends State<AppUpdateHost>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? AppUpdateService();
  AppVersion? _version;
  bool _loadingVersion = true;
  bool _checking = false;
  bool _dialogOpen = false;
  UpdateCheckResult? _pending;

  bool get _canPrompt =>
      (ModalRoute.isCurrentOf(context) ?? true) &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    AppVersion? version;
    try {
      version = await _service.installedVersion();
    } catch (_) {
      // Missing/unsupported platform information must never block startup.
    }
    if (!mounted) return;
    setState(() {
      _version = version;
      _loadingVersion = false;
    });
    if (version != null) await _check(manual: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_showPending());
  }

  Future<void> _check({required bool manual}) async {
    if (_checking || _dialogOpen) return;
    setState(() => _checking = true);
    try {
      final result = await _service.check(manual: manual);
      if (!mounted || result == null) return;
      setState(() {
        _version = result.current;
        _loadingVersion = false;
        if (result.release != null) _pending = result;
      });
      if (result.release == null && manual) {
        AppNotifier.info(context, '当前已是最新版本（${result.current.label}）');
      }
    } catch (_) {
      if (mounted && manual) {
        AppNotifier.error(context, '检查更新失败，请检查网络后重试');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
    if (mounted) await _showPending();
  }

  Future<void> _showPending() async {
    final result = _pending;
    if (!mounted || result == null || _checking || _dialogOpen || !_canPrompt) {
      return;
    }
    _pending = null;
    setState(() => _dialogOpen = true);
    final release = result.release!;
    try {
      final action = await AppDialog.choose<_UpdateAction>(
        context,
        title: '发现新版本 ${release.version.label}',
        message:
            '当前版本：${result.current.label}\n\n'
            '${release.notes.isEmpty ? '新版本已发布，可前往 GitHub 查看详情并下载安装。' : release.notes}',
        choices: const [
          AppDialogChoice(
            label: '前往下载',
            value: _UpdateAction.download,
            primary: true,
          ),
          AppDialogChoice(label: '稍后', value: _UpdateAction.later),
          AppDialogChoice(label: '忽略此版本', value: _UpdateAction.ignore),
        ],
      );
      if (!mounted) return;
      switch (action) {
        case _UpdateAction.download:
          if (!await _service.openRelease(release) && mounted) {
            AppNotifier.error(context, '无法打开下载页面，请检查是否已安装浏览器');
          }
        case _UpdateAction.ignore:
          await _service.ignore(release);
          if (mounted) {
            AppNotifier.info(context, '已忽略 ${release.version.label}，仍可手动检查');
          }
        case _UpdateAction.later:
        case null:
          break;
      }
    } catch (_) {
      if (mounted) AppNotifier.error(context, '操作失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ModalRoute's current-state dependency resumes a deferred startup prompt
    // when the user returns from another page. Never interrupt an open form.
    if ((ModalRoute.isCurrentOf(context) ?? true) && _pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showPending());
      });
    }
    return AppUpdateScope(
      versionLabel: _version != null
          ? 'v${_version!.label}'
          : _loadingVersion
          ? '读取中…'
          : '版本信息不可用',
      checking: _checking || _dialogOpen,
      checkForUpdates: () => unawaited(_check(manual: true)),
      child: widget.child,
    );
  }
}
