import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_notification_tokens.dart';
import 'app_tokens.dart';

/// 标准化 BottomSheet 容器
///
/// ## 设计目标
/// - 与 DESIGN_SPEC.md 第 3.5.4 章节规范一致
/// - 统一圆角顶部 24px + drag handle + 可选标题栏
/// - 包装 showModalBottomSheet，简化调用
/// - 内容不足时不强制定高
class AppBottomSheet {
  AppBottomSheet._();

  /// 显示标准化的底部弹窗
  ///
  /// [child] 是弹窗的内容区；返回 [T] 是 [Navigator.pop] 时传入的结果
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    Widget? child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _AppSheetShell(title: title, child: child);
      },
    );
  }

  /// 显示一个选择器型 BottomSheet（点击项后自动 pop 并返回结果）
  static Future<T?> showPicker<T>(
    BuildContext context, {
    String? title,
    required List<AppSheetOption<T>> options,
  }) {
    return show<T>(
      context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _PickerTile(
              option: options[i],
              onTap: () => Navigator.of(context).pop(options[i].value),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 选项定义（用于 `showPicker`）
class AppSheetOption<T> {
  const AppSheetOption({
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
    this.danger = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final String? subtitle;
  final bool danger;
}

class _AppSheetShell extends StatelessWidget {
  const _AppSheetShell({required this.title, required this.child});

  final String? title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height *
        AppNotificationTokens.sheetMaxHeightRatio;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppNotificationTokens.sheetTopRadius),
              topRight: Radius.circular(AppNotificationTokens.sheetTopRadius),
            ),
            boxShadow: AppShadows.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppNotificationTokens.dragHandleTopMargin),
              // drag handle
              Container(
                width: AppNotificationTokens.dragHandleSize.width,
                height: AppNotificationTokens.dragHandleSize.height,
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (title != null && title!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SheetHeader(title: title!),
                const SizedBox(height: 4),
                const Divider(height: 1, color: AppColors.borderDivider),
              ] else ...[
                const SizedBox(height: 12),
              ],
              // 内容区
              Flexible(
                child: child ?? const SizedBox.shrink(),
              ),
              // 底部安全区
              SizedBox(height: mediaQuery.viewPadding.bottom + 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.base(
                fontSize: AppTypography.fs18,
                fontWeight: AppTypography.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '关闭',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: FaIcon(
                  FontAwesomeIcons.xmark,
                  size: 16,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.option, required this.onTap});

  final AppSheetOption<dynamic> option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = option.danger ? colors.stateDanger : colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.brXl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: AppRadii.brXl,
            ),
            child: Row(
              children: [
                if (option.icon != null) ...[
                  FaIcon(option.icon, size: 18, color: fg),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: AppTypography.base(
                          fontSize: AppTypography.fs16,
                          fontWeight: AppTypography.medium,
                          color: fg,
                        ),
                      ),
                      if (option.subtitle != null &&
                          option.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle!,
                          style: AppTypography.base(
                            fontSize: AppTypography.fs12,
                            fontWeight: AppTypography.regular,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
