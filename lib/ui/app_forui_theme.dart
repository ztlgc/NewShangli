import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Rebuilds Forui's component styles with a Chinese-capable typeface.
abstract final class AppForuiTheme {
  static final FThemeData light = _create(FTheme.neutral.light.touch);
  static final FThemeData dark = _create(FTheme.neutral.dark.touch);

  static FThemeData of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static FThemeData _create(FThemeData base) {
    final typeface = FTypeface(
      fontFamily: 'Noto Sans SC',
      fontFamilyFallback: const ['Noto Sans CJK SC', 'sans-serif'],
    );
    return FThemeData(
      colors: base.colors,
      touch: true,
      typography: FTypography(display: typeface, body: typeface),
      icons: base.icons,
    );
  }
}

/// Keeps shared controls usable in standalone pages, dialogs, and widget tests.
class AppForuiBoundary extends StatelessWidget {
  const AppForuiBoundary({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<FAccessibilityScope>() != null) {
      return child;
    }
    return FTheme(
      data: AppForuiTheme.of(Theme.of(context).brightness),
      child: child,
    );
  }
}
