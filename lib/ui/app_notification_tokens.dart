import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// 通知系统专用设计令牌
///
/// 集中管理 Toast、SnackBar、Dialog、BottomSheet 四类通知的：
/// - 尺寸（宽度、最大高度、内边距）
/// - 圆角、阴影
/// - 动效时长、缓动曲线
/// - 状态色映射
///
/// 所有数值与 DESIGN_SPEC.md 第 3.5 章节一一对应；调整时需同步更新文档。
class AppNotificationTokens {
  // 通用 ----------------------------------------------------------------------

  /// 通知系统全局圆角（卡片/弹窗容器）。
  static const double containerRadius = 12;

  /// 弹窗专用圆角（更大，营造悬浮卡片感）。
  static const double dialogRadius = 16;

  /// 底部弹窗顶部圆角。
  static const double sheetTopRadius = 24;

  /// drag handle 尺寸。
  static const Size dragHandleSize = Size(48, 4);

  /// drag handle 与弹窗顶部的距离。
  static const double dragHandleTopMargin = 8;

  // 水平内边距 -----------------------------------------------------------------

  /// Toast 水平安全边距（距屏幕左右两侧）。
  static const double toastHorizontalPadding = 16;

  /// Toast 距屏幕顶部的偏移（在 SafeArea 之外再下移）。
  static const double toastTopOffset = 16;

  /// SnackBar 水平内边距。
  static const double snackHorizontalPadding = 16;

  /// Dialog 水平内边距（距屏幕左右两侧）。
  static const double dialogHorizontalPadding = 24;

  /// Dialog 内容区垂直内边距。
  static const double dialogContentVerticalPadding = 20;

  // 最大宽度 -------------------------------------------------------------------

  /// Toast 最大宽度（平板居中显示）。
  static const double toastMaxWidth = 420;

  /// Dialog 最大宽度。
  static const double dialogMaxWidth = 360;

  /// BottomSheet 最大高度占屏比。
  static const double sheetMaxHeightRatio = 0.9;

  // 图标尺寸 -------------------------------------------------------------------

  /// Toast 左侧图标头尺寸。
  static const double toastIconSize = 24;

  /// Toast 内部 FA 图标实际渲染尺寸。
  static const double toastIconGlyphSize = 14;

  /// Dialog 图标头容器尺寸。
  static const double dialogIconSize = 40;

  /// Dialog 图标头内部 FA 图标尺寸。
  static const double dialogIconGlyphSize = 16;

  /// SnackBar 前置图标尺寸。
  static const double snackIconSize = 18;

  // 按钮 ----------------------------------------------------------------------

  /// Dialog 按钮高度。
  static const double dialogButtonHeight = 44;

  /// Dialog 按钮间距。
  static const double dialogButtonSpacing = 10;

  // 动效时长 -------------------------------------------------------------------

  /// Toast 入场动画时长。
  static const Duration toastEnterDuration = Duration(milliseconds: 250);

  /// Toast 退场动画时长。
  static const Duration toastExitDuration = Duration(milliseconds: 200);

  /// Dialog 入场动画时长。
  static const Duration dialogEnterDuration = Duration(milliseconds: 200);

  /// Dialog 退场动画时长。
  static const Duration dialogExitDuration = Duration(milliseconds: 150);

  // 时长策略 -------------------------------------------------------------------

  /// Toast 默认时长（success / info）。
  static const Duration toastShortDuration = Duration(seconds: 2);

  /// Toast 中等时长（warning / 无图标提示）。
  static const Duration toastMediumDuration = Duration(milliseconds: 3500);

  /// Toast 长时长（error 或带主操作）。
  static const Duration toastLongDuration = Duration(seconds: 5);

  /// SnackBar 默认时长。
  static const Duration snackDefaultDuration = Duration(seconds: 4);

  /// SnackBar 带操作按钮时长。
  static const Duration snackWithActionDuration = Duration(seconds: 6);
}

/// 通知的语义状态。
///
/// 决定 Toast 左侧竖条 / 图标头背景色、图标与文字色。
enum AppNotificationTone {
  /// 信息（品牌主色）。
  info,

  /// 成功（绿色）。
  success,

  /// 警告（橙色）。
  warning,

  /// 错误（红色）。
  error,

  /// 中性（仅黑色 / 灰色，用于无明确语义的提示）。
  neutral,
}

/// AppNotificationTone → AppThemeColors 颜色映射工具。
///
/// 集中维护状态色到主题色扩展的对应关系，避免散落在多个组件中。
extension AppNotificationToneColors on AppNotificationTone {
  /// 取该语义态对应的主题色（用于 Toast 竖条 / 图标等）。
  Color resolveForeground(AppThemeColors colors) {
    switch (this) {
      case AppNotificationTone.info:
        return colors.brandPrimary;
      case AppNotificationTone.success:
        return colors.stateSuccess;
      case AppNotificationTone.warning:
        return colors.stateWarning;
      case AppNotificationTone.error:
        return colors.stateDanger;
      case AppNotificationTone.neutral:
        return colors.neutralAccent;
    }
  }

  /// 取该语义态对应的"软色"背景（用于图标头底色）。
  Color resolveSoft(AppThemeColors colors) {
    switch (this) {
      case AppNotificationTone.info:
        return colors.brandSoft;
      case AppNotificationTone.success:
        return colors.stateSuccessSoft;
      case AppNotificationTone.warning:
        return colors.stateWarningSoft;
      case AppNotificationTone.error:
        return colors.stateDangerSoft;
      case AppNotificationTone.neutral:
        return colors.surfaceSubtle;
    }
  }

  /// 取该语义态对应的"深色"前景（用于深底图标的图标字色）。
  Color resolveOnSoft(AppThemeColors colors) {
    switch (this) {
      case AppNotificationTone.info:
        return colors.brandOnSoft;
      case AppNotificationTone.success:
        return colors.stateSuccess;
      case AppNotificationTone.warning:
        return colors.stateWarning;
      case AppNotificationTone.error:
        return colors.stateDanger;
      case AppNotificationTone.neutral:
        return colors.textPrimary;
    }
  }
}
