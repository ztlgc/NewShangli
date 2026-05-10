import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../app_toast.dart';
import '../prototype_kit.dart';

/// 页面：用户登录页面
class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String _buildLoginErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return '登录失败：邮箱或密码错误';
    }
    if (message.contains('email not confirmed')) {
      return '登录失败：邮箱尚未完成验证';
    }
    if (message.contains('too many requests')) {
      return '登录失败：操作过于频繁，请稍后再试';
    }
    if (message.contains('network')) {
      return '登录失败：网络异常，请检查网络后重试';
    }
    return '登录失败，请检查账号信息后重试';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 登录逻辑
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppToast.show(context, '请输入邮箱和密码');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 调用 Supabase 的密码登录接口
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      AppToast.show(context, '登录成功');
      Navigator.of(context).pop(true); // 登录成功返回 true
    } on TimeoutException {
      if (!mounted) return;
      AppToast.show(context, '登录超时，请检查网络或稍后重试');
    } on AuthException catch (e) {
      if (!mounted) return;
      AppToast.show(context, _buildLoginErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '发生未知错误: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          PrototypeTopBar(
            title: '用户登录',
            left: PrototypeIconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  // 提示信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.blueSoft,
                      borderRadius: AppRadii.brLg,
                      border: Border.all(color: colors.borderSubtle, width: 1),
                    ),
                    child: Text(
                      '未登录用户可正常使用所有功能，登陆后可使用云端数据库进行同步备份。',
                      style: AppTypography.base(
                        color: colors.blueAccent,
                        fontSize: 14,
                        fontWeight: AppTypography.regular,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // 邮箱输入框
                  TextField(
                    controller: _emailController,
                    style: AppTypography.base(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: AppTypography.regular,
                    ),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: '登录邮箱',
                      prefixIcon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  // 密码输入框
                  TextField(
                    controller: _passwordController,
                    style: AppTypography.base(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: AppTypography.regular,
                    ),
                    decoration: _inputDecoration(
                      context: context,
                      labelText: '密码',
                      prefixIcon: Icons.lock_outline,
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 40),
                  // 登录按钮
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.brandPrimary,
                        foregroundColor: colors.textInverse,
                        disabledBackgroundColor: colors.surfaceDisabled,
                        disabledForegroundColor: colors.textMuted,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.brLg,
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: colors.textInverse,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '登录',
                              style: AppTypography.base(
                                fontSize: 16,
                                fontWeight: AppTypography.medium,
                                color: colors.textInverse,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '如需开通账号，请联系管理员。',
                    textAlign: TextAlign.center,
                    style: AppTypography.base(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String labelText,
    required IconData prefixIcon,
  }) {
    final colors = context.appColors;
    final enabledBorder = OutlineInputBorder(
      borderRadius: AppRadii.brLg,
      borderSide: BorderSide(color: colors.borderDefault, width: 1),
    );
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTypography.base(
        fontSize: 14,
        fontWeight: AppTypography.regular,
        color: colors.textTertiary,
      ),
      floatingLabelStyle: AppTypography.base(
        fontSize: 14,
        fontWeight: AppTypography.medium,
        color: colors.brandSecondary,
      ),
      prefixIcon: Icon(prefixIcon, color: colors.textTertiary),
      filled: true,
      fillColor: colors.surfaceCard,
      border: enabledBorder,
      enabledBorder: enabledBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.brLg,
        borderSide: BorderSide(color: colors.borderFocus, width: 1),
      ),
    );
  }
}
