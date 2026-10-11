import 'package:flutter/widgets.dart';

class AppSession extends ChangeNotifier {
  bool _networkAvailable = true;
  bool _contactModuleEnabled = true;

  bool get networkAvailable => _networkAvailable;
  bool get contactModuleEnabled => _contactModuleEnabled;

  void setNetworkAvailable(bool value) {
    if (_networkAvailable == value) return;
    _networkAvailable = value;
    notifyListeners();
  }

  void setContactModuleEnabled(bool value) {
    if (_contactModuleEnabled == value) return;
    _contactModuleEnabled = value;
    notifyListeners();
  }
}

class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    assert(scope != null, 'AppSessionScope not found in widget tree.');
    return scope!.notifier!;
  }
}
