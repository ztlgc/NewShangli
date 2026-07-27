import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../app_toast.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'account_books_page.dart';
import 'data_backup_page.dart';
import 'data_export_page.dart';
import 'data_import_page.dart';
import 'person_list_page.dart';
import 'edit_protection_page.dart';
import 'record_home_page.dart';
import 'reason_manage_page.dart';
import 'stats_page.dart';
import 'relation_type_manage_page.dart';
import 'recycle_bin_page.dart';
import 'user_login_page.dart';
import 'user_profile_page.dart';
import 'cloud_sync_page.dart';

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

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  User? _user;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (!mounted) return;
          setState(() {
            _user = data.session?.user;
          });
        });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final syncRows = <_SettingRow>[
      if (_user != null)
        _SettingRow(
          iconBg: AppColors.blue50,
          iconFg: AppColors.blue500,
          icon: FontAwesomeIcons.cloud,
          title: '云同步管理',
          onTap: () =>
              AppNav.push(context, const CloudSyncPage(), requiresLogin: true),
        ),
      _SettingRow(
        iconBg: AppColors.orange50,
        iconFg: AppColors.orange500,
        icon: FontAwesomeIcons.cloudArrowUp,
        title: '数据备份',
        onTap: () =>
            AppNav.push(context, const DataBackupPage(), requiresLogin: true),
      ),
      _SettingRow(
        iconBg: AppColors.gray100,
        iconFg: AppColors.textSecondary,
        icon: FontAwesomeIcons.lock,
        title: '编辑保护',
        onTap: () => AppNav.push(context, const EditProtectionPage()),
      ),
      _SettingRow(
        iconBg: AppColors.purple50,
        iconFg: AppColors.purple500,
        icon: FontAwesomeIcons.fileExport,
        title: '导出数据',
        onTap: () =>
            AppNav.push(context, const DataExportPage(), requiresLogin: true),
      ),
      _SettingRow(
        iconBg: AppColors.indigo50,
        iconFg: AppColors.indigo700,
        icon: FontAwesomeIcons.fileImport,
        title: '导入数据',
        onTap: () =>
            AppNav.push(context, const DataImportPage(), requiresLogin: true),
      ),
      _SettingRow(
        iconBg: AppColors.red100,
        iconFg: AppColors.red600,
        icon: FontAwesomeIcons.trashCan,
        title: '回收站',
        borderBottom: false,
        onTap: () =>
            AppNav.push(context, const RecycleBinPage(), requiresLogin: true),
      ),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            border: Border(
              bottom: BorderSide(color: colors.borderDivider, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                '设置',
                style: AppTypography.h2().copyWith(
                  fontSize: 20,
                  color: colors.textPrimary,
                ),
              ),
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
                    onTap: () => AppNav.push(
                      context,
                      const ReasonManagePage(),
                      requiresLogin: true,
                    ),
                  ),
                  _SettingRow(
                    iconBg: AppColors.blue50,
                    iconFg: AppColors.blue600,
                    icon: FontAwesomeIcons.diagramProject,
                    title: '关系类型管理',
                    borderBottom: false,
                    onTap: () => AppNav.push(
                      context,
                      const RelationTypeManagePage(),
                      requiresLogin: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _SingleRowCard(
                iconBg: AppColors.indigo100,
                iconFg: AppColors.indigo600,
                icon: FontAwesomeIcons.book,
                title: '账簿管理',
                onTap: () => AppNav.push(
                  context,
                  const AccountBooksPage(),
                  requiresLogin: true,
                ),
              ),
              SizedBox(height: 24),
              _GroupCard(rows: syncRows),
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
              const SizedBox(height: 24),
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

class _UserCard extends StatefulWidget {
  const _UserCard();

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    // 监听认证状态变化
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: PrototypePressableRow(
        onTap: () async {
          if (_user == null) {
            // 未登录，前往登录页面
            await AppNav.push(context, const UserLoginPage());
          } else {
            // 已登录，前往用户信息页面
            await AppNav.push(context, const UserProfilePage());
          }
        },
        borderBottom: false,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _user == null ? colors.surfaceSubtle : colors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 32,
                color: _user == null ? colors.textMuted : colors.blueAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user == null ? '未登录' : (_user!.email ?? '已登录用户'),
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: AppTypography.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user == null ? '点击登录享受云端同步' : '已连接到云端数据库',
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.regular,
                      color: _user == null
                          ? colors.textTertiary
                          : colors.stateSuccess,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 10,
              color: colors.textMuted,
            ),
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
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
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
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
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
          child: FaIcon(icon, size: 14, color: colors.foregroundFor(iconFg)),
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
        FaIcon(
          FontAwesomeIcons.chevronRight,
          size: 10,
          color: colors.textMuted,
        ),
      ],
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton();

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isLoggedIn = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      AppToast.show(context, '已退出登录');
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '退出登录失败');
    }
  }

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (mounted) {
            setState(() {
              _isLoggedIn = data.session?.user != null;
            });
          }
        });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return const SizedBox.shrink();
    final colors = context.appColors;

    return PressableScale(
      onTap: _signOut,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: colors.surfaceCard,
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
