import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as flutter_l10n;
import 'package:forui/forui.dart';

/// Language resources for both Flutter's Material widgets and Forui widgets.
abstract final class AppLocalizations {
  static const supportedLocales = FLocalizations.supportedLocales;

  // Forui 0.27 uses material_ui/cupertino_ui localization types. Flutter's
  // showDialog/showModalBottomSheet still need the SDK's distinct types.
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    ...flutter_l10n.GlobalMaterialLocalizations.delegates,
    ...FLocalizations.localizationsDelegates,
  ];
}
