import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_tokens.dart';
import 'app_forui_theme.dart';
import 'forui_search_field.dart';

class AppCard extends StatelessWidget {
  const AppCard({
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
    final content = Padding(padding: padding, child: child);
    if (color == AppColors.white &&
        radius == AppRadii.br2xl &&
        shadow == AppShadows.sm &&
        border == null) {
      return AppForuiBoundary(child: FCard(child: content));
    }
    final base = context.theme.cardStyle;
    return AppForuiBoundary(
      child: FCard(
        style: FCardStyle(
          decoration: BoxDecoration(
            color: colors.surfaceFor(color),
            borderRadius: radius,
            boxShadow: shadow,
            border: border,
          ),
          titleTextStyle: base.titleTextStyle,
          subtitleTextStyle: base.subtitleTextStyle,
          padding: padding,
        ),
        child: content,
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppForuiBoundary(
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: FButton(
          size: .lg,
          semanticsLabel: semanticLabel ?? label,
          onPress: onTap,
          prefix: icon == null ? null : Icon(icon, size: 16),
          child: Text(label),
        ),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppForuiBoundary(
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: FButton(
          variant: .outline,
          size: .lg,
          semanticsLabel: semanticLabel ?? label,
          onPress: onTap,
          child: Text(label),
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.background = AppColors.brandPrimary,
    this.foreground = AppColors.white,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final Color background;
  final Color foreground;
  final BoxBorder? border;
  final EdgeInsets padding;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isOutline = background == AppColors.white || border != null;
    return AppForuiBoundary(
      child: FButton(
        variant: isOutline ? .outline : .primary,
        size: .sm,
        mainAxisSize: MainAxisSize.min,
        style: .delta(contentStyle: .delta(padding: .value(padding))),
        semanticsLabel: semanticLabel ?? label,
        onPress: onPressed,
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class AppPill extends StatelessWidget {
  const AppPill({
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
    return AppForuiBoundary(
      child: FBadge(
        style: FBadgeStyle(
          decoration: BoxDecoration(
            color: colors.softFor(background),
            borderRadius: BorderRadius.circular(radius),
          ),
          labelTextStyle: AppTypography.base(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: colors.foregroundFor(foreground),
          ),
          padding: padding,
        ),
        child: Text(label),
      ),
    );
  }
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.color = AppColors.borderDivider});

  final Color color;

  @override
  Widget build(BuildContext context) => AppForuiBoundary(
    child: FDivider(
      style: FDividerStyle(
        color: context.appColors.borderFor(color),
        padding: EdgeInsets.zero,
      ),
    ),
  );
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
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
    return ForuiSearchField(
      controller: controller,
      hint: hintText,
      onChanged: (value) => onChanged?.call(value),
      showClearButton: showClearButton,
    );
  }
}

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
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

class AppPressableRow extends StatelessWidget {
  const AppPressableRow({
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
      onTapDown: feedbackEnabled ? (_) => _handleTapDown() : null,
      onTapCancel: feedbackEnabled ? _clearPressed : null,
      onTapUp: feedbackEnabled ? (_) => _clearPressed() : null,
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

  void _handleTapDown() {
    if (widget.onLongPress != null) return;
    setState(() => _pressed = true);
  }

  void _clearPressed() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }
}
