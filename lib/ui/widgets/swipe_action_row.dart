import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../app_icons.dart';
import '../app_tokens.dart';

/// Reveals actions without ever executing them from a swipe gesture.
/// The parent coordinates [active] so only one row can remain open.
class SwipeActionRow extends StatefulWidget {
  const SwipeActionRow({
    super.key,
    required this.active,
    required this.enabled,
    required this.onActivate,
    required this.onClose,
    required this.onRestore,
    required this.onDelete,
    required this.child,
  });

  final bool active;
  final bool enabled;
  final VoidCallback onActivate;
  final VoidCallback onClose;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final Widget child;

  @override
  State<SwipeActionRow> createState() => _SwipeActionRowState();
}

class _SwipeActionRowState extends State<SwipeActionRow>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void didUpdateWidget(covariant SwipeActionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || !widget.active) _animate(false);
  }

  void _animate(bool open) =>
      _animation.animateTo(open ? 1 : 0, curve: Curves.easeOutCubic);

  void _close() {
    _animate(false);
    widget.onClose();
  }

  void _reveal() {
    widget.onActivate();
    _animate(true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionWidth = math.max(
          72.0,
          MediaQuery.textScalerOf(context).scale(14) * 2 + 32,
        );
        final railWidth = math.min(actionWidth * 2, constraints.maxWidth);
        return TapRegion(
          onTapOutside: (_) {
            if (widget.active) _close();
          },
          child: Semantics(
            customSemanticsActions: {
              const CustomSemanticsAction(label: '显示恢复和删除按钮'): _reveal,
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                _animation.stop();
                widget.onActivate();
              },
              onHorizontalDragUpdate: (details) {
                _animation.value =
                    (_animation.value - details.delta.dx / railWidth).clamp(
                      0,
                      1,
                    );
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                final open = velocity.abs() > 450
                    ? velocity < 0
                    : _animation.value >= 0.5;
                if (open) {
                  _animate(true);
                } else {
                  _close();
                }
              },
              onHorizontalDragCancel: _close,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) => ClipRect(
                  child: Stack(
                    children: [
                      if (_animation.value > 0)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: railWidth,
                          child: IgnorePointer(
                            ignoring: !widget.active || _animation.value < 1,
                            child: ExcludeSemantics(
                              excluding: !widget.active || _animation.value < 1,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Action(
                                    label: '恢复',
                                    icon: AppIcons.rotateCcw,
                                    background: colors.brandPrimary,
                                    foreground: colors.textInverse,
                                    onPressed: widget.onRestore,
                                  ),
                                  _Action(
                                    label: '删除',
                                    semanticLabel: '彻底删除',
                                    icon: AppIcons.trash2,
                                    background: colors.stateDangerStrong,
                                    foreground:
                                        ThemeData.estimateBrightnessForColor(
                                              colors.stateDangerStrong,
                                            ) ==
                                            Brightness.light
                                        ? AppColors.gray900
                                        : AppColors.white,
                                    onPressed: widget.onDelete,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Transform.translate(
                        offset: Offset(-railWidth * _animation.value, 0),
                        child: child,
                      ),
                    ],
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.semanticLabel,
  });
  final String label;
  final String? semanticLabel;
  final IconData icon;
  final Color background, foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: semanticLabel ?? label,
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size(
            AppTokens.tapTargetMin,
            AppTokens.tapTargetMin,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: const RoundedRectangleBorder(),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.medium,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
