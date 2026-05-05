import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_tokens.dart';
import 'prototype_kit.dart';

class PrototypeCard extends StatelessWidget {
  const PrototypeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadii.br2xl,
    this.color = AppColors.white,
    this.shadow = AppShadows.sm,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius radius;
  final Color color;
  final List<BoxShadow>? shadow;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceFor(color),
        borderRadius: radius,
        boxShadow: shadow,
        border: border,
      ),
      child: child,
    );
  }
}

class PrototypePrimaryButton extends StatelessWidget {
  const PrototypePrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colors.brandPrimary,
          borderRadius: AppRadii.brXl,
          boxShadow: AppShadows.brandSoft,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: colors.textInverse, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.medium,
                color: colors.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrototypeSecondaryButton extends StatelessWidget {
  const PrototypeSecondaryButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colors.brandSoft,
          borderRadius: AppRadii.brXl,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.medium,
            color: colors.brandOnSoft,
          ),
        ),
      ),
    );
  }
}

class PrototypeButton extends StatelessWidget {
  const PrototypeButton({
    super.key,
    required this.label,
    this.background = AppColors.brandPrimary,
    this.foreground = AppColors.white,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final BoxBorder? border;
  final EdgeInsets padding;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    final resolvedForeground = foreground == AppColors.white
        ? colors.textInverse
        : colors.foregroundFor(foreground);
    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: PressableScale(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: padding,
          decoration: BoxDecoration(
            color: _buttonBackgroundFor(colors, background),
            borderRadius: AppRadii.brXl,
            border: border,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.base(
              fontSize: AppTypography.fs12,
              fontWeight: AppTypography.semibold,
              color: resolvedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class PrototypePill extends StatelessWidget {
  const PrototypePill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.fontSize = 12,
    this.fontWeight = AppTypography.medium,
    this.radius = 9999,
  });

  final String label;
  final Color background;
  final Color foreground;
  final EdgeInsets padding;
  final double fontSize;
  final FontWeight fontWeight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.softFor(background),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: AppTypography.base(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: colors.foregroundFor(foreground),
        ),
      ),
    );
  }
}

class PrototypeDivider extends StatelessWidget {
  const PrototypeDivider({super.key, this.color = AppColors.borderDivider});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.appColors.borderFor(color));
  }
}

class PrototypeSearchField extends StatelessWidget {
  const PrototypeSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.showClearButton = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool showClearButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final showClear = showClearButton && controller.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            size: 14,
            color: colors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.regular,
                color: colors.textSecondary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: AppTypography.base(
                  fontSize: 14,
                  fontWeight: AppTypography.regular,
                  color: colors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (showClear) ...[
            const SizedBox(width: 8),
            PressableScale(
              onTap: () {
                controller.clear();
                onChanged?.call('');
              },
              child: FaIcon(
                FontAwesomeIcons.circleXmark,
                size: 16,
                color: colors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PrototypeNetworkImage extends StatelessWidget {
  const PrototypeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderColor = AppColors.gray200,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: colors.surfaceFor(placeholderColor),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: colors.surfaceFor(placeholderColor),
        );
      },
    );
  }
}

class PrototypePressableRow extends StatelessWidget {
  const PrototypePressableRow({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.pressedColor = AppColors.gray50,
    this.enablePressedFeedback = true,
    this.borderBottom = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final Color pressedColor;
  final bool enablePressedFeedback;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _PressedBackground(
      onTap: onTap,
      onLongPress: onLongPress,
      pressedColor: colors.surfaceFor(pressedColor),
      enablePressedFeedback: enablePressedFeedback,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: borderBottom
              ? Border(
                  bottom: BorderSide(color: colors.borderDivider, width: 1),
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

Color _buttonBackgroundFor(AppThemeColors colors, Color color) {
  if (color == AppColors.brandPrimary || color == AppColors.indigo900) {
    return colors.brandPrimary;
  }
  if (color == AppColors.brandSecondary || color == AppColors.indigo600) {
    return colors.brandSecondary;
  }
  if (color == AppColors.stateDanger ||
      color == AppColors.red500 ||
      color == AppColors.red600) {
    return colors.stateDanger;
  }
  if (color == AppColors.stateSuccess ||
      color == AppColors.green500 ||
      color == AppColors.green600) {
    return colors.stateSuccess;
  }
  if (color == AppColors.stateWarning ||
      color == AppColors.orange500 ||
      color == AppColors.orange600) {
    return colors.stateWarning;
  }
  return colors.surfaceFor(color);
}

class _PressedBackground extends StatefulWidget {
  const _PressedBackground({
    required this.child,
    required this.pressedColor,
    required this.enablePressedFeedback,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final Color pressedColor;
  final bool enablePressedFeedback;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<_PressedBackground> createState() => _PressedBackgroundState();
}

class _PressedBackgroundState extends State<_PressedBackground> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canHandleTap = widget.onTap != null || widget.onLongPress != null;
    final feedbackEnabled = widget.enablePressedFeedback && canHandleTap;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: feedbackEnabled
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapCancel: feedbackEnabled
          ? () => setState(() => _pressed = false)
          : null,
      onTapUp: feedbackEnabled ? (_) => setState(() => _pressed = false) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        color: (_pressed && feedbackEnabled)
            ? widget.pressedColor
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
