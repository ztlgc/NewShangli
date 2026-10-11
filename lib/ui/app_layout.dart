import 'package:flutter/widgets.dart';

import 'app_tokens.dart';

/// Shared geometry preserves the current Forui visual language.
abstract final class AppLayout {
  static const pagePadding = EdgeInsets.all(AppTokens.space4);
  static const tabContentPadding = EdgeInsets.fromLTRB(
    AppTokens.space4,
    AppTokens.space4,
    AppTokens.space4,
    96,
  );
  static const sectionGap = AppTokens.space6;
  static const floatingNavigationInset = AppTokens.space2;
}
