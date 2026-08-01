import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_notification_tokens.dart';
import 'app_tokens.dart';

/// 统一 Toast 通知
///
/// ## 设计目标
/// - 与 DESIGN_SPEC.md 第 3.5.1 章节规范一致
/// - 支持 success / error / warning / info / neutral 五种语义态
/// - 支持可选主操作按钮（如"撤销"）
/// - 后入覆盖（连续触发时新消息替换旧消息）
/// - 跟随系统明暗主题
/// - 可访问性：文本节点 `IgnorePointer`，主操作按钮保留点击
///
/// ## 使用方式
/// 推荐通过 `AppNotifier.toast(...)` 调用；保留 `AppToast` 静态门面以兼容旧代码。
class AppToast {
  AppToast._();

  /// 当前展示中的 OverlayEntry（单例，保证后入覆盖）。
  static OverlayEntry? _currentEntry;

  /// 当前展示中的退出定时器。
  static Timer? _dismissTimer;

  /// 当前展示中的入场动画控制器。
  static AnimationController? _enterController;

  /// 触发一次 Toast 提示。
  ///
  /// 参数说明：
  /// - [message] 必填，提示文本
  /// - [tone] 语义态，决定颜色与图标；默认 [AppNotificationTone.neutral]
  /// - [title] 可选大标题
  /// - [actionLabel] + [onAction] 可选主操作（按钮文字与点击回调）
  /// - [duration] 自定义显示时长；不传则按 tone 自动选择
  /// - [icon] 自定义图标；不传则按 tone 自动选择
  static void show(
    BuildContext context,
    String message, {
    AppNotificationTone tone = AppNotificationTone.neutral,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
    Duration? duration,
  }) {
    // 1. 后入覆盖：先清理旧的 OverlayEntry 与定时器
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _enterController?.stop();
    _enterController?.dispose();
    _enterController = null;
    _currentEntry?.remove();
    _currentEntry = null;

    // 2. 解析显示时长
    final effectiveDuration = duration ?? _defaultDurationFor(tone, actionLabel);

    // 3. 解析图标
    final effectiveIcon = icon ?? _defaultIconFor(tone);

    // 4. 构造 OverlayEntry
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return _AppToastHost(
          tone: tone,
          title: title,
          message: message,
          icon: effectiveIcon,
          actionLabel: actionLabel,
          onAction: onAction != null
              ? () {
                  // 点击主操作后立即关闭并触发回调
                  _dismissNow();
                  onAction();
                }
              : null,
          onEntered: (controller) {
            _enterController = controller;
          },
        );
      },
    );
    overlay.insert(entry);
    _currentEntry = entry;

    // 5. 启动退场定时器
    _dismissTimer = Timer(effectiveDuration, _dismissNow);
  }

  /// 立即关闭当前 Toast（无动画）。
  ///
  /// 注意：AnimationController 的 dispose 由对应 Widget 的 `dispose` 负责；
  /// 本方法只停止动画并移除 OverlayEntry，避免双重 dispose 报错。
  static void _dismissNow() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    final controller = _enterController;
    if (controller != null) {
      // 防御性 stop：避免测试中 ticker 已经被释放
      try {
        controller.stop();
      } catch (_) {/* ticker 已释放 */}
    }
    _enterController = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// 主动关闭当前 Toast（带退场动画）。
  static void dismiss() => _dismissNow();

  /// 根据 tone 与是否带主操作选择默认时长。
  static Duration _defaultDurationFor(
    AppNotificationTone tone,
    String? actionLabel,
  ) {
    if (actionLabel != null) return AppNotificationTokens.toastLongDuration;
    switch (tone) {
      case AppNotificationTone.info:
      case AppNotificationTone.success:
      case AppNotificationTone.neutral:
        return AppNotificationTokens.toastShortDuration;
      case AppNotificationTone.warning:
      case AppNotificationTone.error:
        return AppNotificationTokens.toastMediumDuration;
    }
  }

  /// 根据 tone 选择默认 FA 图标。
  static IconData _defaultIconFor(AppNotificationTone tone) {
    switch (tone) {
      case AppNotificationTone.success:
        return FontAwesomeIcons.check;
      case AppNotificationTone.warning:
        return FontAwesomeIcons.triangleExclamation;
      case AppNotificationTone.error:
        return FontAwesomeIcons.circleXmark;
      case AppNotificationTone.info:
        return FontAwesomeIcons.circleInfo;
      case AppNotificationTone.neutral:
        return FontAwesomeIcons.bell;
    }
  }
}

/// Toast 实际渲染的宿主 Widget
///
/// 负责：
/// - 调度入场动画（slide + fade）
/// - 渲染主容器（圆角白底 + 左侧状态色竖条 + 图标头 + 文案 + 主操作）
class _AppToastHost extends StatefulWidget {
  const _AppToastHost({
    required this.tone,
    required this.message,
    required this.icon,
    this.title,
    this.actionLabel,
    this.onAction,
    required this.onEntered,
  });

  final AppNotificationTone tone;
  final String? title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ValueChanged<AnimationController> onEntered;

  @override
  State<_AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<_AppToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppNotificationTokens.toastEnterDuration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(_fade);

    // 通知外部接管 controller 引用，便于后入覆盖时停止动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onEntered(_controller);
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneFg = widget.tone.resolveForeground(colors);
    final toneSoft = widget.tone.resolveSoft(colors);
    final toneOnSoft = widget.tone.resolveOnSoft(colors);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppNotificationTokens.toastTopOffset,
            left: AppNotificationTokens.toastHorizontalPadding,
            right: AppNotificationTokens.toastHorizontalPadding,
          ),
          child: IgnorePointer(
            ignoring: widget.onAction == null,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppNotificationTokens.toastMaxWidth,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      label: _semanticsLabel(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceCard,
                          borderRadius: BorderRadius.circular(
                            AppNotificationTokens.containerRadius,
                          ),
                          boxShadow: AppShadows.lg,
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 左侧状态色竖条（4px）
                            Container(
                              width: 4,
                              height: 56,
                              decoration: BoxDecoration(
                                color: toneFg,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(
                                    AppNotificationTokens.containerRadius,
                                  ),
                                  bottomLeft: Radius.circular(
                                    AppNotificationTokens.containerRadius,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 圆形软色图标头
                            _ToastIconWell(
                              background: toneSoft,
                              foreground: toneOnSoft,
                              icon: widget.icon,
                            ),
                            const SizedBox(width: 10),
                            // 文案（标题可选）
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.title != null &&
                                        widget.title!.isNotEmpty) ...[
                                      Text(
                                        widget.title!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.base(
                                          fontSize: AppTypography.fs16,
                                          fontWeight: AppTypography.bold,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      widget.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.base(
                                        fontSize: AppTypography.fs14,
                                        fontWeight: AppTypography.regular,
                                        color: widget.title != null
                                            ? colors.textSecondary
                                            : colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 主操作（可选）
                            if (widget.actionLabel != null &&
                                widget.onAction != null) ...[
                              const SizedBox(width: 4),
                              _ToastActionButton(
                                label: widget.actionLabel!,
                                onTap: widget.onAction!,
                                foreground: toneFg,
                              ),
                            ],
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticsLabel() {
    if (widget.title != null && widget.title!.isNotEmpty) {
      return '${widget.title}，${widget.message}';
    }
    return widget.message;
  }
}

/// Toast 内嵌的圆形软色图标头。
class _ToastIconWell extends StatelessWidget {
  const _ToastIconWell({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppNotificationTokens.toastIconSize,
      height: AppNotificationTokens.toastIconSize,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: FaIcon(icon, size: AppNotificationTokens.toastIconGlyphSize, color: foreground),
    );
  }
}

/// Toast 主操作按钮。
class _ToastActionButton extends StatelessWidget {
  const _ToastActionButton({
    required this.label,
    required this.onTap,
    required this.foreground,
  });

  final String label;
  final VoidCallback onTap;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: AppTypography.base(
              fontSize: AppTypography.fs14,
              fontWeight: AppTypography.semibold,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
