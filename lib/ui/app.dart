import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/local/drift/app_database.dart';
import 'app_data.dart';
import 'app_database_scope.dart';
import 'app_session.dart';
import 'app_theme.dart';
import 'pages/record_home_page.dart';

class NewShangliApp extends StatelessWidget {
  const NewShangliApp({super.key, this.databaseFactory});

  final AppDatabase Function()? databaseFactory;

  @override
  Widget build(BuildContext context) {
    final session = AppSession();
    final data = AppData();
    return AppSessionScope(
      session: session,
      child: AppDataScope(
        data: data,
        child: AppDatabaseProvider(
          databaseFactory: databaseFactory,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: '尚礼',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            builder: (context, child) {
              final theme = Theme.of(context);
              final overlayStyle = theme.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayStyle.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: theme.scaffoldBackgroundColor,
                  systemNavigationBarDividerColor: Colors.transparent,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(decoration: TextDecoration.none),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: const RecordHomePage(),
          ),
        ),
      ),
    );
  }
}
