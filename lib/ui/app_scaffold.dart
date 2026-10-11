import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_tokens.dart';
import 'app_forui_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.backgroundColor,
    required this.body,
    this.bottomNavigationBar,
    this.extendBody = true,
  });

  final Color? backgroundColor;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FTheme(
      data: AppForuiTheme.of(Theme.of(context).brightness),
      child: Scaffold(
        backgroundColor: backgroundColor == null
            ? colors.surfaceApp
            : colors.pageBackgroundFor(backgroundColor!),
        extendBody: extendBody,
        body: SafeArea(child: body),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
