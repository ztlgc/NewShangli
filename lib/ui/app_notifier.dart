import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_notification_tokens.dart';
import 'app_forui_theme.dart';
import 'app_toast.dart';
import 'app_tokens.dart';

import 'app_icons.dart';

/// 通知系统统一入口
///
/// ## 设计目标
/// 集中提供 Toast 与 SnackBar 的调用入口，简化业务侧调用：
/// - `AppNotifier.toast(...)`：轻量提示
/// - `AppNotifier.snack(...)`：与页面强关联的反馈
///
/// 实现细节由本类内部委托给 [AppToast]（Toast）和 [ScaffoldMessenger]（SnackBar）。
/// 业务侧无需关心后入覆盖、动效、暗色适配等实现。
class AppNotifier {
  AppNotifier._();

  // ---------------------------------------------------------------------------
  // Toast 入口
  // ---------------------------------------------------------------------------

  /// 触发一次轻量 Toast 提示
  ///
  /// 这是业务侧最常用的入口；颜色/图标/时长/动效均由 [AppToast] 内部按 [tone] 自动选择。
  static void toast(
    BuildContext context,
    String message, {
    AppNotificationTone tone = AppNotificationTone.neutral,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
    Duration? duration,
  }) {
    AppToast.show(
      context,
      message,
      tone: tone,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
      duration: duration,
    );
  }

  /// 成功态 Toast 快捷方法
  static void success(BuildContext context, String message) {
    toast(context, message, tone: AppNotificationTone.success);
  }

  /// 错误态 Toast 快捷方法
  static void error(BuildContext context, String message) {
    toast(context, message, tone: AppNotificationTone.error);
  }

  /// 警告态 Toast 快捷方法
  static void warning(BuildContext context, String message) {
    toast(context, message, tone: AppNotificationTone.warning);
  }

  /// 信息态 Toast 快捷方法
  static void info(BuildContext context, String message) {
    toast(context, message, tone: AppNotificationTone.info);
  }

  // ---------------------------------------------------------------------------
  // SnackBar 入口
  // ---------------------------------------------------------------------------

  /// 触发一次 SnackBar 反馈
  ///
  /// 适用场景：与具体页面强关联的反馈（删除 N 项成功/失败、批量导入进度提示、Undo 撤回等）
  static void snack(
    BuildContext context,
    String message, {
    AppNotificationTone tone = AppNotificationTone.neutral,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    // 后入覆盖：先关闭旧 SnackBar
    messenger.hideCurrentSnackBar();

    final effectiveIcon = icon ?? _defaultIconFor(tone);
    final effectiveDuration =
        duration ??
        (actionLabel != null
            ? AppNotificationTokens.snackWithActionDuration
            : AppNotificationTokens.snackDefaultDuration);

    final snackBar = SnackBar(
      duration: effectiveDuration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      content: _AppSnackBarContent(
        message: message,
        tone: tone,
        icon: effectiveIcon,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  static IconData _defaultIconFor(AppNotificationTone tone) {
    switch (tone) {
      case AppNotificationTone.success:
        return AppIcons.check;
      case AppNotificationTone.warning:
        return AppIcons.triangleAlert;
      case AppNotificationTone.error:
        return AppIcons.circleX;
      case AppNotificationTone.info:
        return AppIcons.info;
      case AppNotificationTone.neutral:
        return AppIcons.bell;
    }
  }
}

/// SnackBar 实际渲染的内容
class _AppSnackBarContent extends StatelessWidget {
  const _AppSnackBarContent({
    required this.message,
    required this.tone,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppNotificationTone tone;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneFg = tone.resolveForeground(colors);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppNotificationTokens.snackHorizontalPadding,
        vertical: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceSubtle : AppColors.gray900,
        borderRadius: BorderRadius.circular(
          AppNotificationTokens.containerRadius,
        ),
        boxShadow: AppShadows.lg,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppNotificationTokens.snackIconSize, color: toneFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.base(
                fontSize: AppTypography.fs14,
                fontWeight: AppTypography.medium,
                color: isDark ? colors.textPrimary : AppColors.white,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            AppForuiBoundary(
              child: FButton(
                variant: .ghost,
                size: .sm,
                mainAxisSize: MainAxisSize.min,
                onPress: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction!();
                },
                child: Text(
                  actionLabel!,
                  style: AppTypography.base(
                    fontSize: AppTypography.fs14,
                    fontWeight: AppTypography.semibold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
