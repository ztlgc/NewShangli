import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_forui_theme.dart';
import 'app_session.dart';
import 'app_theme.dart';
import 'ui_gallery_database_provider.dart';
import 'pages/account_book_edit_page.dart';
import 'pages/account_books_page.dart';
import 'pages/data_backup_page.dart';
import 'pages/data_export_page.dart';
import 'pages/person_detail_page.dart';
import 'pages/person_edit_page.dart';
import 'pages/person_list_page.dart';
import 'pages/record_add_page.dart';
import 'pages/record_detail_page.dart';
import 'pages/record_home_page.dart';
import 'pages/settings_home_page.dart';
import 'pages/stats_page.dart';

import 'app_icons.dart';

class UiGalleryApp extends StatelessWidget {
  const UiGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppSession();
    return AppSessionScope(
      session: session,
      child: UiGalleryDatabaseProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '礼记界面预览',
          theme: AppTheme.light(),
          home: const UiGalleryHome(),
        ),
      ),
    );
  }
}

class UiGalleryHome extends StatelessWidget {
  const UiGalleryHome({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_GalleryItem>[
      _GalleryItem('收支记录-首页', (context) => const RecordHomePage()),
      _GalleryItem('收支记录-收支录入', (context) => const RecordAddPage()),
      _GalleryItem(
        '收支记录-收支详情',
        (context) => const RecordDetailPage(recordId: 'r_20260210_zw'),
      ),
      _GalleryItem('联系人-列表页', (context) => const PersonListPage()),
      _GalleryItem('联系人-详情页', (context) => const PersonDetailPage()),
      _GalleryItem('联系人-编辑/新增', (context) => const PersonEditPage()),
      _GalleryItem('统计分析-图表页', (context) => const StatsPage()),
      _GalleryItem('设置-设置首页', (context) => const SettingsHomePage()),
      _GalleryItem('设置-数据备份', (context) => const DataBackupPage()),
      _GalleryItem('设置-导出数据', (context) => const DataExportPage()),
      _GalleryItem('设置-账簿管理', (context) => const AccountBooksPage()),
      _GalleryItem('设置-编辑账簿', (context) => const AccountBookEditPage()),
    ];

    return Scaffold(
      body: AppForuiBoundary(
        child: SafeArea(
          child: Column(
            children: [
              const FHeader(title: Text('页面预览')),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const FDivider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FTile(
                      title: Text(item.title),
                      suffix: const Icon(AppIcons.chevronRight),
                      onPress: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: item.builder)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryItem {
  _GalleryItem(this.title, this.builder);

  final String title;
  final WidgetBuilder builder;
}
