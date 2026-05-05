import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../app_toast.dart';
import '../components.dart';
import '../prototype_kit.dart';

/// 页面：登录成功页面 / 用户信息页面
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? _user;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
  }

  /// 退出登录逻辑
  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      AppToast.show(context, '已退出登录');
      Navigator.of(context).pop(true); // 退出成功返回 true
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '退出失败：$e');
      setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final email = user?.email?.trim();
    final displayEmail = email == null || email.isEmpty ? '未知邮箱' : email;
    final userId = user?.id.trim();
    final displayUserId = userId == null || userId.isEmpty
        ? '未知'
        : _compactId(userId);

    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          PrototypeTopBar(
            title: '用户信息',
            left: PrototypeIconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textPrimary,
              onPressed: _isLoggingOut
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ProfileHeaderCard(email: displayEmail),
                const SizedBox(height: 24),
                _SectionLabel(title: '账号信息'),
                const SizedBox(height: 12),
                PrototypeCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: FontAwesomeIcons.envelope,
                        iconBackground: AppColors.blue50,
                        iconForeground: AppColors.blue600,
                        label: '登录邮箱',
                        value: displayEmail,
                      ),
                      const PrototypeDivider(),
                      _InfoRow(
                        icon: FontAwesomeIcons.fingerprint,
                        iconBackground: AppColors.indigo50,
                        iconForeground: AppColors.indigo700,
                        label: '用户 ID',
                        value: displayUserId,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionLabel(title: '云端能力'),
                const SizedBox(height: 12),
                PrototypeCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: const [
                      _InfoRow(
                        icon: FontAwesomeIcons.cloud,
                        iconBackground: AppColors.green50,
                        iconForeground: AppColors.green600,
                        label: '云同步',
                        value: '可使用',
                      ),
                      PrototypeDivider(),
                      _InfoRow(
                        icon: FontAwesomeIcons.shieldHalved,
                        iconBackground: AppColors.orange50,
                        iconForeground: AppColors.orange600,
                        label: '认证状态',
                        value: '已登录',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _LogoutButton(loggingOut: _isLoggingOut, onTap: _logout),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _compactId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.indigo50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.indigo100, width: 1),
            ),
            alignment: Alignment.center,
            child: const FaIcon(
              FontAwesomeIcons.user,
              size: 30,
              color: AppColors.indigo700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.base(
              fontSize: AppTypography.fs18,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const PrototypePill(
            label: '已登录',
            background: AppColors.green100,
            foreground: AppColors.green600,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.base(
        fontSize: AppTypography.fs12,
        fontWeight: AppTypography.bold,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: AppRadii.brXl,
            ),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 16, color: iconForeground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.base(
                    fontSize: AppTypography.fs12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.base(
                    fontSize: AppTypography.fs16,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.loggingOut, required this.onTap});

  final bool loggingOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: loggingOut ? 0.72 : 1,
      child: IgnorePointer(
        ignoring: loggingOut,
        child: PressableScale(
          onTap: onTap,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: AppRadii.brXl,
              border: Border.all(color: AppColors.red100, width: 1),
              boxShadow: AppShadows.sm,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: loggingOut
                  ? Row(
                      key: const ValueKey('logging-out'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.red500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '退出中',
                          style: AppTypography.base(
                            fontSize: AppTypography.fs14,
                            fontWeight: AppTypography.medium,
                            color: AppColors.red500,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('logout'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.arrowRightFromBracket,
                          size: 15,
                          color: AppColors.red500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '退出登录',
                          style: AppTypography.base(
                            fontSize: AppTypography.fs14,
                            fontWeight: AppTypography.medium,
                            color: AppColors.red500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
