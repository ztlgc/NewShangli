import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_tokens.dart';
import '../app_toast.dart';
import '../app_database_scope.dart';
import '../../backup/supabase_sync_service.dart';

class CloudSyncPage extends StatefulWidget {
  const CloudSyncPage({super.key});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  User? _user;
  bool _isWorking = false;
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
        });
      }
    });
    _addLog('云同步模块初始化成功。');
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    if (!mounted) return;
    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$time] $message');
    });
    // 延迟滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setWorking(bool working) {
    if (!mounted) return;
    setState(() {
      _isWorking = working;
    });
  }

  /// 备份到云端
  Future<void> _backupToCloud() async {
    if (_user == null) {
      AppToast.show(context, '请先登录');
      return;
    }
    _setWorking(true);
    _addLog('开始同步本地数据到云端...');

    try {
      final db = AppDatabaseScope.of(context);
      final syncService = SupabaseSyncService(db);
      
      await syncService.syncToCloud(
        onProgress: (msg) => _addLog(msg),
      );

      _addLog('数据同步成功。');
      if (mounted) AppToast.show(context, '同步至云端成功');
    } catch (e) {
      _addLog('同步失败: $e');
      if (mounted) AppToast.show(context, '同步失败');
    } finally {
      _setWorking(false);
    }
  }

  /// 恢复前确认提示
  Future<void> _showRestoreDialog() async {
    if (_user == null) {
      AppToast.show(context, '请先登录');
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('恢复云端数据'),
          content: const Text('此操作将从云端拉取所有数据并覆盖本地相关记录，是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续恢复', style: TextStyle(color: AppColors.red500)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _performRestore();
    } else {
      _addLog('已取消恢复操作。');
    }
  }

  /// 执行下载与恢复
  Future<void> _performRestore() async {
    _setWorking(true);
    _addLog('开始从云端拉取数据...');
    
    try {
      final db = AppDatabaseScope.of(context);
      final syncService = SupabaseSyncService(db);
      
      await syncService.syncFromCloud(
        onProgress: (msg) => _addLog(msg),
      );

      _addLog('数据拉取成功！请重新启动应用以确保数据完全生效。');
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('恢复成功'),
            content: const Text('数据已恢复，建议重新启动应用以确保数据完全加载。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _addLog('恢复失败: $e');
      if (mounted) {
        AppToast.show(context, '恢复失败: $e');
      }
    } finally {
      _setWorking(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('云同步管理'),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 状态面板
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    
                    // 操作面板
                    Text(
                      '同步操作',
                      style: AppTypography.h3(),
                    ),
                    const SizedBox(height: 12),
                    
                    // 备份按钮组
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadii.brXl,
                        boxShadow: AppShadows.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isWorking || _user == null
                                ? null
                                : _backupToCloud,
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('同步本地数据至云端'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '将本地数据(包含账簿、关系人、记录及附件)推送到云端。',
                            style: AppTypography.caption(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 恢复按钮组
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadii.brXl,
                        boxShadow: AppShadows.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isWorking || _user == null
                                ? null
                                : _showRestoreDialog,
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: const Text('从云端恢复数据'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green600,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '提示：恢复操作会自动覆盖本地数据，存在冲突保护机制。',
                            style: AppTypography.caption(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 日志面板
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: AppColors.gray900,
                  borderRadius: AppRadii.brXl,
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '操作日志',
                            style: AppTypography.base(
                              fontSize: 14,
                              fontWeight: AppTypography.bold,
                              color: AppColors.white,
                            ),
                          ),
                          if (_isWorking)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: AppColors.brandPrimary,
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.gray700, height: 1),
                    Expanded(
                      child: Scrollbar(
                        controller: _logScrollController,
                        thumbVisibility: _logs.isNotEmpty,
                        child: ListView.builder(
                          controller: _logScrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  color: AppColors.gray300,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isLoggedIn = _user != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLoggedIn ? AppColors.blue50 : AppColors.gray100,
        borderRadius: AppRadii.brXl,
        border: Border.all(
          color: isLoggedIn ? AppColors.blue100 : AppColors.gray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLoggedIn ? AppColors.blue500 : AppColors.gray400,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_sync, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '认证状态',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLoggedIn ? AppColors.green500 : AppColors.gray400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLoggedIn ? '已连接云端服务' : '未连接 (请先登录)',
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                        color: isLoggedIn ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (isLoggedIn) ...[
                  const SizedBox(height: 4),
                  Text(
                    _user!.email ?? '未知账号',
                    style: AppTypography.caption().copyWith(color: AppColors.blue600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
