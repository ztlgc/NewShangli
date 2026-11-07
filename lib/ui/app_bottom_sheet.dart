import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_popup.dart';
import 'app_forui_theme.dart';
import 'app_tokens.dart';

import 'app_icons.dart';

/// 统一弹出面板入口，保留原有名称以兼容业务调用。
///
/// 默认居中；小菜单传入触发控件的 [anchorContext] 后就近显示。
/// 内容不足时不强制定高，长列表在面板内部滚动。
class AppBottomSheet {
  AppBottomSheet._();

  /// 自行管理外观和内部布局的内容面板。
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    BuildContext? anchorContext,
    bool isDismissible = true,
  }) => AppPopup.show<T>(
    context,
    builder: builder,
    anchorContext: anchorContext,
    isDismissible: isDismissible,
  );

  /// 标准内容面板。返回 Navigator.pop 时传入的结果。
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    Widget? child,
    BuildContext? anchorContext,
    bool isDismissible = true,
  }) => AppPopup.show<T>(
    context,
    anchorContext: anchorContext,
    isDismissible: isDismissible,
    builder: (_) => _AppSheetShell(title: title, child: child),
  );

  /// 选择后自动关闭并返回结果；大选择器不传锚点，始终居中。
  static Future<T?> showPicker<T>(
    BuildContext context, {
    String? title,
    BuildContext? anchorContext,
    required List<AppSheetOption<T>> options,
  }) => show<T>(
    context,
    title: title,
    anchorContext: anchorContext,
    child: ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (sheetContext, index) => _PickerTile(
        option: options[index],
        onTap: () => Navigator.of(sheetContext).pop(options[index].value),
      ),
    ),
  );
}

/// 选项定义（用于 `showPicker`）
class AppSheetOption<T> {
  const AppSheetOption({
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
    this.danger = false,
    this.selected = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final String? subtitle;
  final bool danger;
  final bool selected;
}

class _AppSheetShell extends StatelessWidget {
  const _AppSheetShell({required this.title, required this.child});

  final String? title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AppForuiBoundary(
      child: FCard(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null && title!.isNotEmpty) ...[
              _SheetHeader(title: title!),
              const Divider(height: 1, color: AppColors.borderDivider),
            ] else ...[
              const SizedBox(height: 12),
            ],
            Flexible(child: child ?? const SizedBox.shrink()),
            const SizedBox(height: 12),
          ],
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
          FButton.icon(
            variant: .ghost,
            size: .sm,
            semanticsLabel: '关闭',
            onPress: () => Navigator.of(context).pop(),
            child: const Icon(AppIcons.x),
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
      child: FButton.raw(
        variant: .ghost,
        onPress: onTap,
        semanticsLabel: option.label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(borderRadius: AppRadii.brXl),
          child: Row(
            children: [
              if (option.icon != null) ...[
                Icon(option.icon, size: 18, color: fg),
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
              if (option.selected)
                Icon(AppIcons.check, size: 18, color: colors.brandPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
