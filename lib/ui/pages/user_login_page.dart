import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_tokens.dart';
import '../app_toast.dart';

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
          .signInWithPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      
      if (!mounted) return;
      AppToast.show(context, '登录成功');
      Navigator.of(context).pop(true); // 登录成功返回 true
    } on TimeoutException {
      if (!mounted) return;
      AppToast.show(context, '登录超时，请检查网络或稍后重试');
    } on AuthException catch (e) {
      if (!mounted) return;
      AppToast.show(context, '登录失败: ${e.message}');
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

  /// 注册逻辑（方便测试）
  Future<void> _signUp() async {
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
      // 调用 Supabase 的注册接口
      await Supabase.instance.client.auth
          .signUp(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      
      if (!mounted) return;
      AppToast.show(context, '注册成功，请重新点击登录');
    } on TimeoutException {
      if (!mounted) return;
      AppToast.show(context, '注册超时，请检查网络或稍后重试');
    } on AuthException catch (e) {
      if (!mounted) return;
      AppToast.show(context, '注册失败: ${e.message}');
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
    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('用户登录'),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // 提示信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: AppRadii.brLg,
                ),
                child: Text(
                  '未登录用户可正常使用所有功能，登陆后可使用云端数据库进行同步备份。',
                  style: AppTypography.base(
                    color: AppColors.blue600,
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
                decoration: const InputDecoration(
                  labelText: '登录邮箱',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              // 密码输入框
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
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
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.brLg,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // 注册按钮
              TextButton(
                onPressed: _isLoading ? null : _signUp,
                child: Text(
                  '没有账号？点击注册',
                  style: AppTypography.base(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: AppTypography.regular,
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
