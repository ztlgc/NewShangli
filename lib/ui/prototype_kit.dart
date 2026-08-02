import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_tokens.dart';

/// 用于像素级还原的“原型画布”：
/// - 设计稿基于 393x852（iPhone 15 Pro 逻辑尺寸）。
/// - 运行在任意 Android 设备时：等比缩放显示，以保证像素对齐关系不变。
class PrototypeFrame extends StatelessWidget {
  const PrototypeFrame({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.surfaceApp,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ColoredBox(
      color: colors.pageBackgroundFor(backgroundColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = _scaleFor(constraints.biggest);
          return Center(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: AppTokens.designSize.width,
                height: AppTokens.designSize.height,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  double _scaleFor(Size available) {
    final sx = available.width / AppTokens.designSize.width;
    final sy = available.height / AppTokens.designSize.height;
    return sx < sy ? sx : sy;
  }
}

class PrototypeStatusBar extends StatelessWidget {
  const PrototypeStatusBar({
    super.key,
    this.backgroundColor = AppColors.white,
    this.foregroundColor = AppColors.textPrimary,
  });

  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class PrototypeTopBar extends StatelessWidget {
  const PrototypeTopBar({
    super.key,
    required this.title,
    this.backgroundColor = AppColors.white,
    this.foregroundColor = AppColors.textPrimary,
    this.left,
    this.right,
    this.bottomBorder = true,
    this.shadow = false,
  });

  final String title;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? left;
  final Widget? right;
  final bool bottomBorder;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final border = bottomBorder
        ? Border(bottom: BorderSide(color: colors.borderDivider, width: 1))
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceFor(backgroundColor),
        border: border,
        boxShadow: shadow ? AppShadows.sm : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 36, height: 36, child: left ?? const SizedBox()),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: AppTypography.base(
                  fontSize: AppTypography.fs20,
                  fontWeight: AppTypography.bold,
                  color: colors.foregroundFor(foregroundColor),
                ),
              ),
            ),
          ),
          SizedBox(width: 36, height: 36, child: right ?? const SizedBox()),
        ],
      ),
    );
  }
}

class PrototypeIconButton extends StatelessWidget {
  const PrototypeIconButton({
    super.key,
    required this.icon,
    this.size = 36,
    this.backgroundColor = AppColors.gray100,
    this.foregroundColor = AppColors.textSecondary,
    this.onPressed,
    this.radius = 9999,
    this.semanticLabel,
    this.semanticHint,
  });

  final Widget icon;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double radius;
  final String? semanticLabel;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      hint: semanticHint,
      // 图标按钮通常没有可读文本，这里显式透出语义标签，避免读屏只读出图标类型。
      child: ExcludeSemantics(
        child: PressableScale(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.surfaceFor(backgroundColor),
              borderRadius: BorderRadius.circular(radius),
            ),
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(
                color: colors.foregroundFor(foregroundColor),
                size: 18,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

class PrototypeBottomNav extends StatelessWidget {
  const PrototypeBottomNav({
    super.key,
    required this.activeIndex,
    this.onTap,
    this.floating = false,
  });

  final int activeIndex;
  final ValueChanged<int>? onTap;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = (MediaQuery.paddingOf(context).bottom - 12)
        .clamp(0.0, double.infinity)
        .toDouble();
    return Container(
      height: floating
          ? AppTokens.floatingNavHeight
          : AppTokens.tabBarHeight + bottomInset,
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        border: floating
            ? Border.all(color: colors.borderSubtle, width: 1)
            : Border(top: BorderSide(color: colors.borderDefault, width: 1)),
        borderRadius: floating ? AppRadii.br2xl : null,
        boxShadow: floating ? AppShadows.lg : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: floating ? 0 : bottomInset),
        child: SizedBox(
          height: floating
              ? AppTokens.floatingNavHeight
              : AppTokens.tabBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                activeIndex: activeIndex,
                index: 0,
                label: '记录',
                icon: const FaIcon(FontAwesomeIcons.book),
                onTap: onTap,
              ),
              _NavItem(
                activeIndex: activeIndex,
                index: 1,
                label: '关系',
                icon: const FaIcon(FontAwesomeIcons.userGroup),
                onTap: onTap,
              ),
              _NavItem(
                activeIndex: activeIndex,
                index: 2,
                label: '统计',
                icon: const FaIcon(FontAwesomeIcons.chartPie),
                onTap: onTap,
              ),
              _NavItem(
                activeIndex: activeIndex,
                index: 3,
                label: '设置',
                icon: const FaIcon(FontAwesomeIcons.gear),
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.activeIndex,
    required this.index,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final int activeIndex;
  final int index;
  final String label;
  final Widget icon;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final active = activeIndex == index;
    final color = active ? colors.brandPrimary : colors.textMuted;
    return SizedBox(
      width: 64,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        selected: active,
        label: label,
        child: ExcludeSemantics(
          child: PressableScale(
            onTap: () => onTap?.call(index),
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(color: color, size: 20),
                    child: icon,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppTypography.base(
                      fontSize: 10,
                      fontWeight: AppTypography.medium,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
