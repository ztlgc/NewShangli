import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_tokens.dart';
import '../app_toast.dart';

/// 页面：登录成功页面 / 用户信息页面
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
  }

  /// 退出登录逻辑
  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      AppToast.show(context, '已退出登录');
      Navigator.of(context).pop(true); // 退出成功返回 true
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '退出失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('用户信息'),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // 用户头像
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blue100, width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.blue500,
                ),
              ),
              const SizedBox(height: 24),
              // 登录状态
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.green500, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '已登录',
                      style: AppTypography.base(
                        fontSize: 14,
                        color: AppColors.green600,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 登录邮箱信息卡片
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadii.br2xl,
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '账号信息',
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, color: AppColors.textTertiary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '登录邮箱',
                                style: AppTypography.base(
                                  fontSize: 12,
                                  fontWeight: AppTypography.regular,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _user?.email ?? '未知邮箱',
                                style: AppTypography.base(
                                  fontSize: 16,
                                  fontWeight: AppTypography.medium,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // 退出登录按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red500,
                    side: const BorderSide(color: AppColors.red500),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.brLg,
                    ),
                  ),
                  child: const Text(
                    '退出登录',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
