import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_forui_theme.dart';
import 'app_notification_tokens.dart';

/// Shared modal positioning. A missing anchor means a centered content panel.
abstract final class AppPopup {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    BuildContext? anchorContext,
    bool isDismissible = true,
  }) {
    final navigator = Navigator.of(context);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final anchorBox = anchorContext?.findRenderObject();
    final anchor =
        anchorBox is RenderBox && anchorBox.attached && anchorBox.hasSize
        ? anchorBox.localToGlobal(Offset.zero, ancestor: overlay) &
              anchorBox.size
        : null;
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final foruiTheme = FTheme.capture(from: context, to: navigator.context);
    return navigator.push<T>(
      _AppPopupRoute<T>(
        barrierLabel: MaterialLocalizations.of(context)
            .modalBarrierDismissLabel,
        barrierDismissible: isDismissible,
        builder: (context) => themes.wrap(
          foruiTheme.wrap(
            AppForuiBoundary(
              child: _PopupLayout(anchor: anchor, builder: builder),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppPopupRoute<T> extends PopupRoute<T> {
  _AppPopupRoute({
    required this.builder,
    required this.barrierLabel,
    required this.barrierDismissible,
  }) : super(
         requestFocus: true,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );

  final WidgetBuilder builder;

  @override
  final String barrierLabel;

  @override
  final bool barrierDismissible;

  @override
  Color get barrierColor => Colors.black54;

  @override
  Duration get transitionDuration => AppNotificationTokens.dialogEnterDuration;

  @override
  Duration get reverseTransitionDuration =>
      AppNotificationTokens.dialogExitDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);
}

class _PopupLayout extends StatelessWidget {
  const _PopupLayout({required this.anchor, required this.builder});

  final Rect? anchor;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final padding = EdgeInsets.fromLTRB(
      math.max(media.viewPadding.left, media.viewInsets.left) +
          AppNotificationTokens.popupScreenPadding,
      math.max(media.viewPadding.top, media.viewInsets.top) +
          AppNotificationTokens.popupScreenPadding,
      math.max(media.viewPadding.right, media.viewInsets.right) +
          AppNotificationTokens.popupScreenPadding,
      math.max(media.viewPadding.bottom, media.viewInsets.bottom) +
          AppNotificationTokens.popupScreenPadding,
    );
    final animation = ModalRoute.of(context)!.animation!
        .drive(CurveTween(curve: Curves.easeOutCubic));
    return CustomSingleChildLayout(
      delegate: _PopupPositionDelegate(anchor: anchor, padding: padding),
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: media.disableAnimations
              ? const AlwaysStoppedAnimation(1)
              : Tween<double>(begin: 0.97, end: 1).animate(animation),
          child: MediaQuery(
            data: media.copyWith(
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
            ),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              child: Material(
                type: MaterialType.transparency,
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupPositionDelegate extends SingleChildLayoutDelegate {
  const _PopupPositionDelegate({required this.anchor, required this.padding});

  final Rect? anchor;
  final EdgeInsets padding;

  Rect _bounds(Size size) => Rect.fromLTRB(
    padding.left,
    padding.top,
    math.max(padding.left, size.width - padding.right),
    math.max(padding.top, size.height - padding.bottom),
  );

  (double, double) _spaces(Rect bounds) => (
    (anchor!.top - AppNotificationTokens.popupAnchorGap - bounds.top).clamp(
      0.0,
      bounds.height,
    ),
    (bounds.bottom - anchor!.bottom - AppNotificationTokens.popupAnchorGap)
        .clamp(0.0, bounds.height),
  );

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final bounds = _bounds(constraints.biggest);
    final width = math.min(
      bounds.width,
      anchor == null
          ? AppNotificationTokens.popupPanelMaxWidth
          : AppNotificationTokens.popupMenuMaxWidth,
    );
    // When neither side has enough room (for example with a landscape
    // keyboard), allow overlap with the anchor rather than squeezing out
    // the menu header and options. Positioning still keeps it on screen.
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: bounds.height * AppNotificationTokens.sheetMaxHeightRatio,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bounds = _bounds(size);
    if (anchor == null) {
      return Offset(
        bounds.left + (bounds.width - childSize.width) / 2,
        bounds.top + (bounds.height - childSize.height) / 2,
      );
    }
    final (above, below) = _spaces(bounds);
    final placeBelow = below >= childSize.height || below >= above;
    final top = placeBelow
        ? anchor!.bottom + AppNotificationTokens.popupAnchorGap
        : anchor!.top - AppNotificationTokens.popupAnchorGap - childSize.height;
    return Offset(
      anchor!.left.clamp(bounds.left, bounds.right - childSize.width),
      top.clamp(bounds.top, bounds.bottom - childSize.height),
    );
  }

  @override
  bool shouldRelayout(_PopupPositionDelegate oldDelegate) =>
      anchor != oldDelegate.anchor || padding != oldDelegate.padding;
}
