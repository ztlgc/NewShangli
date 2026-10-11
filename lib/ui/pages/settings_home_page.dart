import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../app_tokens.dart';
import '../app_dialog.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import 'account_books_page.dart';
import 'data_backup_page.dart';
import 'data_export_page.dart';
import 'data_import_page.dart';
import 'edit_protection_page.dart';
import 'reason_manage_page.dart';
import 'relation_type_manage_page.dart';
import 'recycle_bin_page.dart';

import '../app_icons.dart';

import '../app_layout.dart';

class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});
  @override
  Widget build(BuildContext context) => AppScaffold(
    body: Column(
      children: [
        const FHeader(title: Text('设置')),
        Expanded(
          child: ListView(
            padding: AppLayout.tabContentPadding,
            children: [
              _GroupCard(
                rows: [
                  _SettingRow(
                    iconBg: AppColors.indigo50,
                    iconFg: AppColors.indigo700,
                    icon: AppIcons.tags,
                    title: '事由管理',
                    onTap: () => AppNav.push(context, const ReasonManagePage()),
                  ),
                  _SettingRow(
                    iconBg: AppColors.blue50,
                    iconFg: AppColors.blue600,
                    icon: AppIcons.network,
                    title: '关系类型管理',
                    borderBottom: false,
                    onTap: () =>
                        AppNav.push(context, const RelationTypeManagePage()),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.sectionGap),
              _SingleRowCard(
                iconBg: AppColors.indigo100,
                iconFg: AppColors.indigo600,
                icon: AppIcons.bookOpen,
                title: '账簿管理',
                onTap: () => AppNav.push(context, const AccountBooksPage()),
              ),
              const SizedBox(height: AppLayout.sectionGap),
              _GroupCard(
                rows: [
                  _SettingRow(
                    iconBg: AppColors.orange50,
                    iconFg: AppColors.orange500,
                    icon: AppIcons.cloudUpload,
                    title: '数据备份',
                    onTap: () => AppNav.push(context, const DataBackupPage()),
                  ),
                  _SettingRow(
                    iconBg: AppColors.gray100,
                    iconFg: AppColors.textSecondary,
                    icon: AppIcons.lock,
                    title: '编辑保护',
                    onTap: () =>
                        AppNav.push(context, const EditProtectionPage()),
                  ),
                  _SettingRow(
                    iconBg: AppColors.purple50,
                    iconFg: AppColors.purple500,
                    icon: AppIcons.fileOutput,
                    title: '导出数据',
                    onTap: () => AppNav.push(context, const DataExportPage()),
                  ),
                  _SettingRow(
                    iconBg: AppColors.indigo50,
                    iconFg: AppColors.indigo700,
                    icon: AppIcons.fileInput,
                    title: '导入数据',
                    onTap: () => AppNav.push(context, const DataImportPage()),
                  ),
                  _SettingRow(
                    iconBg: AppColors.red100,
                    iconFg: AppColors.red600,
                    icon: AppIcons.trash2,
                    title: '回收站',
                    borderBottom: false,
                    onTap: () => AppNav.push(context, const RecycleBinPage()),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.sectionGap),
              _SingleRowCard(
                iconBg: AppColors.gray100,
                iconFg: AppColors.textTertiary,
                icon: AppIcons.info,
                title: '关于尚礼',
                trailingText: 'v1.2.1',
                onTap: () => AppDialog.showAlert(
                  context,
                  title: '关于尚礼',
                  message: '版本 v1.2.1',
                  closeLabel: '确定',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
    return FCard(
      clipBehavior: Clip.antiAlias,
      child: AppPressableRow(
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
    return FCard(
      clipBehavior: Clip.antiAlias,
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
    return AppPressableRow(
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
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.softFor(iconBg),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: colors.foregroundFor(iconFg)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.medium,
              color: colors.textPrimary,
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
                color: colors.textMuted,
              ),
            ),
          ),
        Icon(AppIcons.chevronRight, size: 10, color: colors.textMuted),
      ],
    );
  }
}
