import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../security/edit_protection.dart';
import 'app_dialog.dart';
import 'app_notifier.dart';
import 'app_notification_tokens.dart';

/// 触发编辑保护密码校验流程：
/// 1. 读取本地配置，未开启则直接放行
/// 2. 弹出统一 [AppDialog.showInput] 密码输入框
/// 3. 校验失败时通过 [AppNotifier] 触发统一 Toast
///
/// 业务侧统一通过本入口调用，未来新增敏感操作时无需重复实现弹窗。
Future<bool> requireEditProtectionPassword(
  BuildContext context, {
  required String title,
}) async {
  final config = await EditProtectionConfig.load();
  if (!config.enabled) return true;
  if (!context.mounted) return false;

  final result = await AppDialog.showInput(
    context,
    title: title,
    message: '验证后继续操作',
    confirmLabel: '确认',
    cancelLabel: '取消',
    tone: AppNotificationTone.info,
    icon: FontAwesomeIcons.lock,
    fields: const [
      AppDialogField(
        id: 'password',
        label: '编辑密码',
        hint: '请输入编辑密码',
        obscureText: true,
      ),
    ],
  );

  final password = result?['password']?.trim() ?? '';
  if (password.isEmpty) return false;

  final ok = await EditProtectionService().verifyPassword(password);
  if (!ok && context.mounted) {
    AppNotifier.error(context, '密码错误');
  }
  return ok;
}
