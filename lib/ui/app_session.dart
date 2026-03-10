import 'package:flutter/widgets.dart';

class AppSession extends ChangeNotifier {
  bool _loggedIn = true;
  bool _networkAvailable = true;

  bool get loggedIn => _loggedIn;
  bool get networkAvailable => _networkAvailable;

  void setLoggedIn(bool value) {
    if (_loggedIn == value) return;
    _loggedIn = value;
    notifyListeners();
  }

  void setNetworkAvailable(bool value) {
    if (_networkAvailable == value) return;
    _networkAvailable = value;
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

