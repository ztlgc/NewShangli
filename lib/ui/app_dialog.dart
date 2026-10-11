import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_notification_tokens.dart';
import 'app_forui_theme.dart';
import 'app_tokens.dart';

import 'app_icons.dart';

/// 标准化的弹窗容器与工厂方法
///
/// ## 设计目标
/// - 与 DESIGN_SPEC.md 第 3.5.3 章节规范一致
/// - 统一带图标头 + 标题 + 内容 + 双按钮的弹窗样式
/// - 三个工厂方法：confirm（确认）、showInput（表单）、showAlert（告警）
/// - 横屏时自动切换为 BottomSheet 形态
/// - 可访问性：标题/按钮语义化，主按钮默认聚焦
class AppDialog {
  AppDialog._();

  /// 显示确认型 Dialog
  ///
  /// 返回 [bool]：true 表示用户确认；false 或 null 表示取消/关闭
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    bool danger = false,
    AppNotificationTone tone = AppNotificationTone.warning,
    IconData? icon,
  }) async {
    final result = await _showAdaptive<bool>(
      context,
      tone: tone,
      icon: icon,
      title: title,
      message: message,
      content: null,
      actions: _DialogActionSpec.buttons(
        confirm: confirmLabel,
        cancel: cancelLabel,
        danger: danger,
      ),
    );
    return result;
  }

  /// 显示输入型 Dialog（密码、文本、备注等）
  ///
  /// 返回 [Map<String, String>]?：用户输入结果（key = field.id）；null 表示取消
  static Future<Map<String, String>?> showInput(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    AppNotificationTone tone = AppNotificationTone.info,
    IconData? icon,
    required List<AppDialogField> fields,
  }) async {
    final controllers = <String, TextEditingController>{
      for (final f in fields) f.id: TextEditingController(text: f.initialValue),
    };
    try {
      final result = await _showAdaptive<Map<String, String>>(
        context,
        tone: tone,
        icon: icon,
        title: title,
        message: message,
        content: _InputForm(fields: fields, controllers: controllers),
        actions: _DialogActionSpec.buttons(
          confirm: confirmLabel,
          cancel: cancelLabel,
          danger: false,
        ),
      );
      return result;
    } finally {
      for (final c in controllers.values) {
        c.dispose();
      }
    }
  }

  /// 显示告警型 Dialog（仅一个"知道了"按钮）
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    String? message,
    String closeLabel = '知道了',
    AppNotificationTone tone = AppNotificationTone.info,
    IconData? icon,
  }) async {
    await _showAdaptive<void>(
      context,
      tone: tone,
      icon: icon,
      title: title,
      message: message,
      content: null,
      actions: _DialogActionSpec.single(closeLabel),
    );
  }

  // ---------------------------------------------------------------------------
  // 内部：根据方向选择 Dialog 或 BottomSheet
  // ---------------------------------------------------------------------------

  static Future<T?> _showAdaptive<T>(
    BuildContext context, {
    required AppNotificationTone tone,
    required IconData? icon,
    required String title,
    String? message,
    required Widget? content,
    required _DialogActionSpec actions,
  }) {
    final orientation = MediaQuery.orientationOf(context);
    if (orientation == Orientation.landscape) {
      return _showAsBottomSheet<T>(
        context,
        tone: tone,
        icon: icon,
        title: title,
        message: message,
        content: content,
        actions: actions,
      );
    }
    return _showAsDialog<T>(
      context,
      tone: tone,
      icon: icon,
      title: title,
      message: message,
      content: content,
      actions: actions,
    );
  }

  static Future<T?> _showAsDialog<T>(
    BuildContext context, {
    required AppNotificationTone tone,
    required IconData? icon,
    required String title,
    String? message,
    required Widget? content,
    required _DialogActionSpec actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: actions.dismissible,
      builder: (context) {
        return _AppDialogShell(
          tone: tone,
          icon: icon ?? _defaultIconFor(tone),
          title: title,
          message: message,
          content: content,
          actions: actions,
        );
      },
    );
  }

  static Future<T?> _showAsBottomSheet<T>(
    BuildContext context, {
    required AppNotificationTone tone,
    required IconData? icon,
    required String title,
    String? message,
    required Widget? content,
    required _DialogActionSpec actions,
  }) {
    // 横屏时退化到底部弹窗，避免过窄
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: actions.dismissible,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppForuiBoundary(
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).cardColor,
                borderRadius: BorderRadius.circular(
                  AppNotificationTokens.dialogRadius,
                ),
                boxShadow: AppShadows.lg,
              ),
              child: _AppDialogShell(
                tone: tone,
                icon: icon ?? _defaultIconFor(tone),
                title: title,
                message: message,
                content: content,
                actions: actions,
                skipOuterDialog: true,
              ),
            ),
          ),
        );
      },
    );
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

/// Dialog 输入字段定义
class AppDialogField {
  const AppDialogField({
    required this.id,
    required this.label,
    this.hint,
    this.initialValue,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction = TextInputAction.done,
  });

  /// 字段 ID，结果 Map 的 key。
  final String id;

  /// 输入框 label（暂未渲染到 UI，预留给未来）。
  final String label;

  /// 输入框占位提示。
  final String? hint;

  /// 初始值。
  final String? initialValue;

  /// 是否为密码字段。
  final bool obscureText;

  /// 最大行数。
  final int maxLines;

  /// 最小行数。
  final int? minLines;

  /// 软键盘动作。
  final TextInputAction textInputAction;
}

/// Dialog 按钮配置
class _DialogActionSpec {
  const _DialogActionSpec._({
    this.confirmLabel,
    this.cancelLabel,
    this.danger = false,
    this.single = false,
    this.dismissible = true,
  });

  factory _DialogActionSpec.buttons({
    required String confirm,
    required String cancel,
    bool danger = false,
  }) {
    return _DialogActionSpec._(
      confirmLabel: confirm,
      cancelLabel: cancel,
      danger: danger,
    );
  }

  factory _DialogActionSpec.single(String closeLabel) {
    return _DialogActionSpec._(
      confirmLabel: closeLabel,
      single: true,
      dismissible: true,
    );
  }

  final String? confirmLabel;
  final String? cancelLabel;
  final bool danger;
  final bool single;
  final bool dismissible;
}

/// Dialog 实际渲染的容器
class _AppDialogShell extends StatelessWidget {
  const _AppDialogShell({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    required this.content,
    required this.actions,
    this.skipOuterDialog = false,
  });

  final AppNotificationTone tone;
  final IconData icon;
  final String title;
  final String? message;
  final Widget? content;
  final _DialogActionSpec actions;
  final bool skipOuterDialog;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneFg = tone.resolveForeground(colors);
    final toneSoft = tone.resolveSoft(colors);
    final toneOnSoft = tone.resolveOnSoft(colors);

    final body = Padding(
      padding: const EdgeInsets.all(
        AppNotificationTokens.dialogContentVerticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 图标头 + 标题
          _DialogHeader(
            tone: tone,
            icon: icon,
            toneSoft: toneSoft,
            toneOnSoft: toneOnSoft,
            title: title,
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                message!,
                style: AppTypography.base(
                  fontSize: AppTypography.fs14,
                  fontWeight: AppTypography.regular,
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ],
          if (content != null) ...[const SizedBox(height: 16), content!],
          const SizedBox(height: 20),
          // 按钮区
          _DialogActionRow(actions: actions, toneFg: toneFg),
        ],
      ),
    );

    if (skipOuterDialog) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(
            AppNotificationTokens.dialogRadius,
          ),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: body,
      );
    }
    return AppForuiBoundary(
      child: FDialog(
        semanticsLabel: title,
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: AppNotificationTokens.dialogMaxWidth,
        ),
        builder: (context, style) => body,
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.tone,
    required this.icon,
    required this.toneSoft,
    required this.toneOnSoft,
    required this.title,
  });

  final AppNotificationTone tone;
  final IconData icon;
  final Color toneSoft;
  final Color toneOnSoft;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: AppNotificationTokens.dialogIconSize,
            height: AppNotificationTokens.dialogIconSize,
            decoration: BoxDecoration(
              color: toneSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: AppNotificationTokens.dialogIconGlyphSize,
              color: toneOnSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.base(
                fontSize: AppTypography.fs18,
                fontWeight: AppTypography.bold,
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogActionRow extends StatelessWidget {
  const _DialogActionRow({required this.actions, required this.toneFg});

  final _DialogActionSpec actions;
  final Color toneFg;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (actions.single) {
      return _DialogButton(
        label: actions.confirmLabel!,
        background: colors.brandPrimary,
        foreground: colors.textInverse,
        autofocus: true,
        onTap: () => Navigator.of(context).pop(),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _DialogButton(
            label: actions.cancelLabel!,
            background: colors.surfaceSubtle,
            foreground: colors.textSecondary,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: AppNotificationTokens.dialogButtonSpacing),
        Expanded(
          child: _DialogButton(
            label: actions.confirmLabel!,
            background: actions.danger
                ? colors.stateDanger
                : colors.brandPrimary,
            foreground: colors.textInverse,
            autofocus: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.autofocus = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppForuiBoundary(
      child: SizedBox(
        height: AppNotificationTokens.dialogButtonHeight,
        width: double.infinity,
        child: FButton(
          variant: background == colors.stateDanger
              ? .destructive
              : background == colors.surfaceSubtle
              ? .outline
              : .primary,
          onPress: onTap,
          autofocus: autofocus,
          semanticsLabel: label,
          child: Text(label),
        ),
      ),
    );
  }
}

/// Dialog 内嵌的输入表单
class _InputForm extends StatelessWidget {
  const _InputForm({required this.fields, required this.controllers});

  final List<AppDialogField> fields;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(
              controller: controllers[fields[i].id],
            ),
            label: Text(fields[i].label),
            hint: fields[i].hint,
            autofocus: i == 0,
            obscureText: fields[i].obscureText,
            maxLines: fields[i].maxLines,
            minLines: fields[i].minLines,
            textInputAction: fields[i].textInputAction,
          ),
        ],
      ],
    );
  }
}
