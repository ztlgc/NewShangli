import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import '../data/local/drift/app_database.dart';
import 'app_data.dart';
import 'app_database_scope.dart';
import 'app_forui_theme.dart';
import 'app_localizations.dart';
import 'app_session.dart';
import 'app_theme.dart';
import 'tab_shell.dart';

class NewShangliApp extends StatefulWidget {
  const NewShangliApp({
    super.key,
    this.databaseFactory,
    this.initialTabIndex = 0,
  });

  final AppDatabase Function()? databaseFactory;
  final int initialTabIndex;

  /// 全局 ScaffoldMessengerKey
  ///
  /// 用于在无 BuildContext 的场景（如 Service / 后台任务）通过
  /// `appMessengerKey.currentState` 主动弹出 SnackBar。
  /// 普通页面调用请使用 `AppNotifier.snack(context, ...)`。
  static final GlobalKey<ScaffoldMessengerState> appMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  State<NewShangliApp> createState() => _NewShangliAppState();
}

class _NewShangliAppState extends State<NewShangliApp> {
  final session = AppSession();
  final data = AppData();
  @override
  void dispose() {
    session.dispose();
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSessionScope(
      session: session,
      child: AppDataScope(
        data: data,
        child: AppDatabaseProvider(
          databaseFactory: widget.databaseFactory,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: NewShangliApp.appMessengerKey,
            title: '礼记',
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.delegates,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            builder: (context, child) {
              final theme = Theme.of(context);
              final foruiTheme = AppForuiTheme.of(theme.brightness);
              final overlayStyle = theme.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayStyle.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: theme.scaffoldBackgroundColor,
                  systemNavigationBarDividerColor: Colors.transparent,
                ),
                child: FTheme(
                  data: foruiTheme,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(decoration: TextDecoration.none),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
            home: MainTabShell(initialIndex: widget.initialTabIndex),
          ),
        ),
      ),
    );
  }
}
