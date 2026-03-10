import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../app_session.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'account_books_page.dart';
import 'data_backup_page.dart';
import 'data_export_page.dart';
import 'data_import_page.dart';
import 'reminders_page.dart';
import 'person_list_page.dart';
import 'record_home_page.dart';
import 'reason_manage_page.dart';
import 'stats_page.dart';
import 'contact_relation_manage_page.dart';
import 'recycle_bin_page.dart';

/// 页面：系统设置 - 设置首页
/// 对照原型：prototype/index.html -> "设置首页"
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
          ),
          child: Row(
            children: [
              Text('设置', style: AppTypography.h2().copyWith(fontSize: 20)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              const _UserCard(),
              SizedBox(height: 24),
              _GroupCard(
                rows: [
                  _SettingRow(
                    iconBg: AppColors.indigo50,
                    iconFg: AppColors.indigo700,
                    icon: FontAwesomeIcons.tags,
                    title: '事由管理',
                    onTap: () => AppNav.push(context, const ReasonManagePage(), requiresLogin: true),
                  ),
                  _SettingRow(
                    iconBg: AppColors.blue50,
                    iconFg: AppColors.blue600,
                    icon: FontAwesomeIcons.diagramProject,
                    title: '联系人关系管理',
                    borderBottom: false,
                    onTap: () => AppNav.push(context, const ContactRelationManagePage(), requiresLogin: true),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _SingleRowCard(
                iconBg: AppColors.indigo100,
                iconFg: AppColors.indigo600,
                icon: FontAwesomeIcons.book,
                title: '账簿管理',
                onTap: () => AppNav.push(context, const AccountBooksPage(), requiresLogin: true),
              ),
              SizedBox(height: 24),
              _GroupCard(
                rows: [
                  _SettingRow(
                    iconBg: AppColors.blue50,
                    iconFg: AppColors.blue500,
                    icon: FontAwesomeIcons.bell,
                    title: '通知提醒',
                    onTap: () => AppNav.push(context, const RemindersPage(), requiresLogin: true),
                  ),
                  _SettingRow(
                    iconBg: AppColors.green50,
                    iconFg: AppColors.green500,
                    icon: FontAwesomeIcons.shieldHalved,
                    title: '隐私与安全',
                    borderBottom: false,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('隐私与安全：仅原型展示，暂未实现')),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
              _GroupCard(
                rows: [
                  _SettingRow(
                    iconBg: AppColors.orange50,
                    iconFg: AppColors.orange500,
                    icon: FontAwesomeIcons.cloudArrowUp,
                    title: '数据备份',
                    onTap: () => AppNav.push(context, const DataBackupPage(), requiresLogin: true),
                  ),
                  _SettingRow(
                    iconBg: AppColors.purple50,
                    iconFg: AppColors.purple500,
                    icon: FontAwesomeIcons.fileExport,
                    title: '导出数据 (Excel)',
                    onTap: () => AppNav.push(context, const DataExportPage(), requiresLogin: true),
                  ),
                  _SettingRow(
                    iconBg: AppColors.indigo50,
                    iconFg: AppColors.indigo700,
                    icon: FontAwesomeIcons.fileImport,
                    title: '导入数据 (Excel/CSV)',
                    onTap: () => AppNav.push(context, const DataImportPage(), requiresLogin: true),
                  ),
                  _SettingRow(
                    iconBg: AppColors.red100,
                    iconFg: AppColors.red600,
                    icon: FontAwesomeIcons.trashCan,
                    title: '回收站',
                    borderBottom: false,
                    onTap: () => AppNav.push(context, const RecycleBinPage(), requiresLogin: true),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _SingleRowCard(
                iconBg: AppColors.gray100,
                iconFg: AppColors.textTertiary,
                icon: FontAwesomeIcons.circleInfo,
                title: '关于尚礼',
                trailingText: 'v1.0.0',
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('关于尚礼'),
                        content: const Text('版本 v1.0.0'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('确定'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 24),
              const _LogoutButton(),
            ],
          ),
        ),
        PrototypeBottomNav(
          activeIndex: 3,
          onTap: (index) {
            if (index == 3) return;
            if (index == 0) {
              AppNav.replaceRoot(context, const RecordHomePage());
              return;
            }
            if (index == 1) {
              AppNav.replaceRoot(context, const PersonListPage());
              return;
            }
            if (index == 2) {
              AppNav.replaceRoot(context, const StatsPage());
              return;
            }
          },
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: PrototypePressableRow(
        onTap: () {
          final session = AppSessionScope.of(context);
          if (!session.loggedIn) {
            session.setLoggedIn(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已切换为登录状态（演示）')),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('用户信息：仅原型展示')),
          );
        },
        borderBottom: false,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipOval(
              child: const PrototypeNetworkImage(
                url: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '用户_9527',
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '已登录',
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.regular,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}

class _SingleRowCard extends StatelessWidget {
  const _SingleRowCard({
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: PrototypePressableRow(
        onTap: onTap,
        borderBottom: false,
        child: _RowContent(
          iconBg: iconBg,
          iconFg: iconFg,
          icon: icon,
          title: title,
          trailingText: trailingText,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.rows});

  final List<_SettingRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(children: rows),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.title,
    required this.onTap,
    this.borderBottom = true,
  });

  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: onTap,
      borderBottom: borderBottom,
      child: _RowContent(
        iconBg: iconBg,
        iconFg: iconFg,
        icon: icon,
        title: title,
      ),
    );
  }
}

class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.title,
    this.trailingText,
  });

  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final String title;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: FaIcon(icon, size: 14, color: iconFg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.medium,
              color: AppColors.gray800,
            ),
          ),
        ),
        if (trailingText != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              trailingText!,
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
            ),
          ),
        const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        final session = AppSessionScope.of(context);
        session.setLoggedIn(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已退出登录（演示）')),
        );
      },
      child: Container(
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadii.br2xl,
          boxShadow: AppShadows.sm,
        ),
        alignment: Alignment.center,
        child: Text(
          '退出登录',
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.medium,
            color: AppColors.red500,
          ),
        ),
      ),
    );
  }
}

