import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../security/edit_protection.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../navigation.dart';
import '../ui_kit.dart';

import '../app_icons.dart';

import '../app_layout.dart';

class EditProtectionPage extends StatelessWidget {
  const EditProtectionPage({super.key});

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
  final EditProtectionService _service = EditProtectionService();
  EditProtectionConfig _config = const EditProtectionConfig(
    enabled: false,
    passwordSalt: '',
    passwordHash: '',
  );
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final c = await _service.load();
      if (!mounted) return;
      setState(() {
        _config = c;
        _loading = false;
      });
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    if (_busy) return;
    if (!_loading && value == _config.enabled) return;
    setState(() => _busy = true);
    try {
      if (value) {
        if (!_config.hasPassword) {
          final ok = await _setNewPasswordDialog();
          if (!ok) return;
        } else {
          await _service.setEnabled(true);
        }
      } else {
        if (_config.hasPassword) {
          final verified = await _verifyPasswordDialog(title: '关闭编辑保护');
          if (!verified) return;
        }
        await _service.setEnabled(false);
      }
      final c = await _service.load();
      if (!mounted) return;
      setState(() => _config = c);
      if (mounted) {
        AppNotifier.success(context, value ? '编辑保护已开启' : '编辑保护已关闭');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_config.hasPassword) {
        final verified = await _verifyPasswordDialog(title: '修改密码');
        if (!mounted || !verified) return;
      }
      final ok = await _setNewPasswordDialog();
      if (!mounted || !ok) return;
      final c = await _service.load();
      if (!mounted) return;
      setState(() => _config = c);
      AppNotifier.success(context, '密码已更新');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _verifyPasswordDialog({required String title}) async {
    final input = await AppDialog.showInput(
      context,
      title: title,
      confirmLabel: '验证',
      cancelLabel: '取消',
      fields: const [
        AppDialogField(
          id: 'password',
          label: '编辑密码',
          hint: '请输入编辑密码',
          obscureText: true,
        ),
      ],
    );
    final v = (input?['password'] ?? '').trim();
    if (v.isEmpty) return false;
    final ok = await _service.verifyPassword(v);
    if (!ok && mounted) {
      AppNotifier.error(context, '密码错误');
    }
    return ok;
  }

  Future<bool> _setNewPasswordDialog() async {
    final result = await AppDialog.showInput(
      context,
      title: '设置编辑密码',
      confirmLabel: '保存',
      cancelLabel: '取消',
      fields: const [
        AppDialogField(
          id: 'p1',
          label: '新密码',
          hint: '请输入新密码',
          obscureText: true,
        ),
        AppDialogField(
          id: 'p2',
          label: '再次输入',
          hint: '再次输入新密码',
          obscureText: true,
        ),
      ],
    );
    final s1 = (result?['p1'] ?? '').trim();
    final s2 = (result?['p2'] ?? '').trim();
    if (result == null) return false;
    if (s1.length < 4) {
      if (mounted) {
        AppNotifier.warning(context, '密码至少 4 位');
      }
      return false;
    }
    if (s1 != s2) {
      if (mounted) {
        AppNotifier.warning(context, '两次输入不一致');
      }
      return false;
    }
    await _service.setPassword(newPassword: s1, enabled: true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(
          title: '编辑保护',
          left: AppIconButton(
            icon: const Icon(AppIcons.arrowLeft, size: 18),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: _busy ? null : () => AppNav.pop(context),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: AppLayout.pagePadding,
                  children: [
                    AppCard(
                      padding: AppLayout.pagePadding,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '开启编辑保护',
                              style: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.medium,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          FSwitch(
                            value: _config.enabled,
                            onChange: _busy ? null : _toggleEnabled,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          AppPressableRow(
                            onTap: _busy ? null : _changePassword,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _config.hasPassword ? '修改密码' : '设置密码',
                                    style: AppTypography.base(
                                      fontSize: 14,
                                      fontWeight: AppTypography.medium,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  AppIcons.chevronRight,
                                  size: 18,
                                  color: AppColors.gray300,
                                ),
                              ],
                            ),
                          ),
                          const AppDivider(color: AppColors.borderDivider),
                          AppPressableRow(
                            onTap: _busy ? null : () => _toggleEnabled(false),
                            borderBottom: false,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '关闭编辑保护',
                                    style: AppTypography.base(
                                      fontSize: 14,
                                      fontWeight: AppTypography.medium,
                                      color: AppColors.red500,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  AppIcons.chevronRight,
                                  size: 18,
                                  color: AppColors.gray300,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '开启后，已保存的账簿/联系人/记录修改与删除需要输入密码；新增备注与新增附件、首次设置头像不需要密码。',
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppTokens.bottomSafeSpacing),
      ],
    );
  }
}
