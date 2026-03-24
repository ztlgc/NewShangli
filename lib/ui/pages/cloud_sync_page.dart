import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/drift/app_database.dart';
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
  static const String _kLastSyncAtKey = 'cloud_sync_last_at_ms_v1';
  static const String _kLastSyncCountKey = 'cloud_sync_last_item_count_v1';
  static const String _kLastSyncActionKey = 'cloud_sync_last_action_v1';

  User? _user;
  bool _isWorking = false;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<int>? _localItemCountSubscription;
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  DateTime? _lastSyncAt;
  int _lastSyncItemCount = 0;
  String? _lastSyncAction;
  int _localItemCount = 0;
  AppDatabase? _db;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
        });
      }
    });
    _addLog('云同步模块初始化成功。');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDatabaseScope.of(context);
    if (identical(_db, db)) return;
    _db = db;
    _localItemCountSubscription?.cancel();
    _localItemCountSubscription = _watchLocalDataItemCount(db).listen((count) {
      if (!mounted) return;
      setState(() {
        _localItemCount = count;
        if (_lastSyncAt != null) {
          _lastSyncItemCount = count;
        }
      });
    });
    _loadSyncOverview(db);
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _localItemCountSubscription?.cancel();
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

  Future<void> _loadSyncOverview(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final int? lastSyncAtMs = prefs.getInt(_kLastSyncAtKey);
    final String? persistedAction = prefs.getString(_kLastSyncActionKey);
    final int persistedCount = prefs.getInt(_kLastSyncCountKey) ?? 0;
    final int localCount = await _queryLocalDataItemCount(db);
    if (!mounted) return;
    setState(() {
      _lastSyncAt = lastSyncAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastSyncAtMs);
      _lastSyncItemCount = lastSyncAtMs == null ? persistedCount : localCount;
      _lastSyncAction = persistedAction;
      _localItemCount = localCount;
    });
  }

  Future<int> _queryLocalDataItemCount(AppDatabase db) async {
    final row = await db.customSelect(
      '''
      SELECT
        (SELECT COUNT(*) FROM account_book) +
        (SELECT COUNT(*) FROM person) +
        (SELECT COUNT(*) FROM gift_record) +
        (SELECT COUNT(*) FROM reason) +
        (SELECT COUNT(*) FROM relation_type) +
        (SELECT COUNT(*) FROM contact_relation) +
        (SELECT COUNT(*) FROM reminder_type) +
        (SELECT COUNT(*) FROM event_reminder) AS total
      ''',
    ).getSingle();
    return row.read<int>('total');
  }

  Stream<int> _watchLocalDataItemCount(AppDatabase db) {
    return db.customSelect(
      '''
      SELECT
        (SELECT COUNT(*) FROM account_book) +
        (SELECT COUNT(*) FROM person) +
        (SELECT COUNT(*) FROM gift_record) +
        (SELECT COUNT(*) FROM reason) +
        (SELECT COUNT(*) FROM relation_type) +
        (SELECT COUNT(*) FROM contact_relation) +
        (SELECT COUNT(*) FROM reminder_type) +
        (SELECT COUNT(*) FROM event_reminder) AS total
      ''',
      readsFrom: {
        db.accountBooks,
        db.persons,
        db.giftRecords,
        db.reasons,
        db.relationTypes,
        db.contactRelations,
        db.reminderTypes,
        db.eventReminders,
      },
    ).watch().map((rows) {
      if (rows.isEmpty) return 0;
      return rows.first.read<int>('total');
    });
  }

  Future<void> _saveSyncSnapshot(String action) async {
    final db = _db;
    if (db == null) return;
    final int total = await _queryLocalDataItemCount(db);
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSyncAtKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_kLastSyncCountKey, total);
    await prefs.setString(_kLastSyncActionKey, action);
    if (!mounted) return;
    setState(() {
      _lastSyncAt = now;
      _lastSyncItemCount = total;
      _lastSyncAction = action;
      _localItemCount = total;
    });
  }

  String _formatDateTime(DateTime? time) {
    if (time == null) return '暂无记录';
    final now = DateTime.now();
    final bool sameDay =
        now.year == time.year && now.month == time.month && now.day == time.day;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    if (sameDay) return '今天 $hh:$mm';
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
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
      await _saveSyncSnapshot('上传');
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
      await _saveSyncSnapshot('恢复');
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
    final isLoggedIn = _user != null;
    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('云同步管理'),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(isLoggedIn),
              const SizedBox(height: 16),
              _buildSectionTitle('快速操作'),
              const SizedBox(height: 10),
              _buildActionTile(
                title: '同步本地到云端',
                subtitle: '增量上传，保留版本快照',
                icon: Icons.cloud_upload_outlined,
                onTap: _isWorking || !isLoggedIn ? null : _backupToCloud,
                isPrimary: true,
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                title: '从云端恢复数据',
                subtitle: '自动校验冲突，可回滚',
                icon: Icons.cloud_download_outlined,
                onTap: _isWorking || !isLoggedIn ? null : _showRestoreDialog,
                isPrimary: false,
              ),
              const SizedBox(height: 16),
              _buildProtectionCard(),
              const SizedBox(height: 16),
              _buildLogPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
        border: Border.all(
          color: AppColors.orange600.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.orange100,
              borderRadius: AppRadii.brXl,
            ),
            child: Icon(
              Icons.cloud_done_outlined,
              color: isLoggedIn ? AppColors.orange600 : AppColors.gray400,
              size: 24,
            ),
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
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLoggedIn ? AppColors.orange600 : AppColors.gray400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLoggedIn ? '已连接云端服务' : '未连接 (请先登录)',
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: AppRadii.brLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '上次同步',
                              style: AppTypography.base(
                                fontSize: 11,
                                fontWeight: AppTypography.regular,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(_lastSyncAt),
                              style: AppTypography.base(
                                fontSize: 13,
                                fontWeight: AppTypography.semibold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: AppRadii.brLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '上次同步条目',
                              style: AppTypography.base(
                                fontSize: 11,
                                fontWeight: AppTypography.regular,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _lastSyncAt == null ? '暂无记录' : '$_lastSyncItemCount 条',
                              style: AppTypography.base(
                                fontSize: 13,
                                fontWeight: AppTypography.semibold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isLoggedIn) ...[
                  const SizedBox(height: 8),
                  Text(
                    _user!.email ?? '未知账号',
                    style: AppTypography.caption().copyWith(color: AppColors.orange600),
                  ),
                ],
                if (_lastSyncAction != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '最近操作：$_lastSyncAction · ${_formatDateTime(_lastSyncAt)}',
                    style: AppTypography.caption(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.base(
        fontSize: 15,
        fontWeight: AppTypography.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.br2xl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.orange600 : AppColors.white,
            borderRadius: AppRadii.br2xl,
            border: Border.all(
              color: isPrimary
                  ? AppColors.orange600
                  : AppColors.orange600.withValues(alpha: 0.16),
              width: 1,
            ),
            boxShadow: isPrimary ? AppShadows.brandSoft : AppShadows.sm,
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? AppColors.white.withValues(alpha: 0.14)
                        : AppColors.orange100,
                    borderRadius: AppRadii.brXl,
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? AppColors.white : AppColors.orange600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.base(
                          fontSize: 15,
                          fontWeight: AppTypography.semibold,
                          color: isPrimary ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: isPrimary
                              ? AppColors.white.withValues(alpha: 0.82)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isPrimary
                      ? AppColors.white.withValues(alpha: 0.8)
                      : AppColors.textTertiary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.brXl,
        border: Border.all(
          color: AppColors.orange600.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.orange100,
              borderRadius: AppRadii.brLg,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.orange600,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '恢复保护提醒',
                  style: AppTypography.base(
                    fontSize: 13,
                    fontWeight: AppTypography.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '恢复前将自动生成本地快照，若发现异常可在 7 天内一键回退。',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    return Container(
      height: 240,
      decoration: const BoxDecoration(
        color: AppColors.gray900,
        borderRadius: AppRadii.brXl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '同步日志',
                    style: AppTypography.base(
                      fontSize: 14,
                      fontWeight: AppTypography.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange600.withValues(alpha: 0.2),
                    borderRadius: AppRadii.brPill,
                  ),
                  child: Text(
                    '本地数据 $_localItemCount 条',
                    style: AppTypography.base(
                      fontSize: 11,
                      fontWeight: AppTypography.semibold,
                      color: AppColors.orange100,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                Text(
                  '实时输出',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.medium,
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isWorking ? AppColors.orange600 : AppColors.gray500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isWorking
                      ? '同步中'
                      : (_lastSyncAt == null ? '空闲' : '上次 ${_formatDateTime(_lastSyncAt)}'),
                  style: AppTypography.base(
                    fontSize: 11,
                    fontWeight: AppTypography.semibold,
                    color: _isWorking ? AppColors.orange100 : AppColors.gray300,
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
    );
  }
}
