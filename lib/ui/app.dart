import 'package:flutter/material.dart';

import 'app_data.dart';
import 'app_database_scope.dart';
import 'app_session.dart';
import 'app_theme.dart';
import 'pages/record_home_page.dart';

class NewShangliApp extends StatelessWidget {
  const NewShangliApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppSession();
    final data = AppData();
    return AppSessionScope(
      session: session,
      child: AppDataScope(
        data: data,
        child: AppDatabaseProvider(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: '尚礼',
            theme: AppTheme.light(),
            // 暂时取消深色模式显示，固定使用浅色模式
            // darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.light,
            home: const RecordHomePage(),
          ),
        ),
      ),
    );
  }
}
