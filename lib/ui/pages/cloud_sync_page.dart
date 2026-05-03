import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../backup/cloud_backup_service.dart';
import '../../backup/supabase_sync_service.dart';
import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../app_toast.dart';
import '../components.dart';
import '../prototype_kit.dart';

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
  bool _cloudCountLoading = false;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<_SyncDataCounts>? _localCountsSubscription;
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  DateTime? _lastSyncAt;
  int _lastSyncItemCount = 0;
  String? _lastSyncAction;
  _SyncDataCounts _localCounts = _SyncDataCounts.zero;
  _SyncDataCounts? _cloudCounts;
  String? _cloudCountError;
  AppDatabase? _db;
  final CloudBackupService _cloudBackupService = CloudBackupService();
  bool _backupVersionLoading = false;
  String? _backupVersionError;
  List<CloudBackupVersion> _backupVersions = const <CloudBackupVersion>[];

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (!mounted) return;
          setState(() {
            _user = data.session?.user;
            if (_user == null) {
              _cloudCounts = null;
              _cloudCountError = null;
              _cloudCountLoading = false;
            }
          });
          unawaited(_refreshCloudCounts(silent: true));
          unawaited(_refreshBackupVersions(silent: true));
          unawaited(_maybeRunAutoBackup(silent: true));
        });
    _addLog('云同步模块初始化成功。');
    unawaited(_refreshCloudCounts(silent: true));
    unawaited(_refreshBackupVersions(silent: true));
    unawaited(_maybeRunAutoBackup(silent: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDatabaseScope.of(context);
    if (identical(_db, db)) return;
    _db = db;
    _localCountsSubscription?.cancel();
    _localCountsSubscription = _watchLocalDataCounts(db).listen((counts) {
      if (!mounted) return;
      setState(() => _localCounts = counts);
    });
    unawaited(_loadSyncOverview(db));
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _localCountsSubscription?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    if (!mounted) return;
    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$time] $message');
    });
    Future<void>.delayed(const Duration(milliseconds: 100), () {
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
    setState(() => _isWorking = working);
  }

  Future<void> _loadSyncOverview(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncAtMs = prefs.getInt(_kLastSyncAtKey);
    final persistedAction = prefs.getString(_kLastSyncActionKey);
    final persistedCount = prefs.getInt(_kLastSyncCountKey) ?? 0;
    final localCounts = await _queryLocalDataCounts(db);
    if (!mounted) return;
    setState(() {
      _lastSyncAt = lastSyncAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastSyncAtMs);
      _lastSyncItemCount = persistedCount;
      _lastSyncAction = persistedAction;
      _localCounts = localCounts;
    });
  }

  Future<_SyncDataCounts> _queryLocalDataCounts(AppDatabase db) async {
    final row = await db.customSelect('''
      SELECT
        (SELECT COUNT(*) FROM account_book) AS account_books,
        (SELECT COUNT(*) FROM person) AS persons,
        (SELECT COUNT(*) FROM gift_record) AS gift_records,
        (SELECT COUNT(*) FROM reason) AS reasons,
        (SELECT COUNT(*) FROM relation_type) AS relation_types,
        (SELECT COUNT(*) FROM contact_relation) AS contact_relations
      ''').getSingle();
    return _SyncDataCounts.fromRow(row.data);
  }

  Stream<_SyncDataCounts> _watchLocalDataCounts(AppDatabase db) {
    return db
        .customSelect(
          '''
          SELECT
            (SELECT COUNT(*) FROM account_book) AS account_books,
            (SELECT COUNT(*) FROM person) AS persons,
            (SELECT COUNT(*) FROM gift_record) AS gift_records,
            (SELECT COUNT(*) FROM reason) AS reasons,
            (SELECT COUNT(*) FROM relation_type) AS relation_types,
            (SELECT COUNT(*) FROM contact_relation) AS contact_relations
          ''',
          readsFrom: {
            db.accountBooks,
            db.persons,
            db.giftRecords,
            db.reasons,
            db.relationTypes,
            db.contactRelations,
          },
        )
        .watch()
        .map((rows) {
          if (rows.isEmpty) return _SyncDataCounts.zero;
          return _SyncDataCounts.fromRow(rows.first.data);
        });
  }

  Future<_SyncDataCounts> _queryCloudDataCounts(User user) async {
    Future<int> countRows(String tableName) async {
      return Supabase.instance.client
          .from(tableName)
          .count(CountOption.exact)
          .eq('user_id', user.id);
    }

    final results = await Future.wait<int>([
      countRows('account_book'),
      countRows('person'),
      countRows('gift_record'),
      countRows('reason'),
      countRows('relation_type'),
      countRows('contact_relation'),
    ]);

    return _SyncDataCounts(
      accountBooks: results[0],
      persons: results[1],
      giftRecords: results[2],
      reasons: results[3],
      relationTypes: results[4],
      contactRelations: results[5],
    );
  }

  Future<void> _refreshCloudCounts({bool silent = false}) async {
    final user = _user;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _cloudCounts = null;
        _cloudCountError = null;
        _cloudCountLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _cloudCountLoading = true;
      _cloudCountError = null;
    });

    try {
      final counts = await _queryCloudDataCounts(user);
      if (!mounted) return;
      setState(() {
        _cloudCounts = counts;
        _cloudCountLoading = false;
      });
      if (!silent) _addLog('云端数据统计已刷新：${counts.total} 条。');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cloudCountError = '云端统计获取失败';
        _cloudCountLoading = false;
      });
      if (!silent) _addLog('云端统计获取失败: $e');
    }
  }

  Future<void> _saveSyncSnapshot(
    String action, {
    _SyncDataCounts? localCounts,
  }) async {
    final db = _db;
    if (db == null) return;
    final counts = localCounts ?? await _queryLocalDataCounts(db);
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSyncAtKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_kLastSyncCountKey, counts.total);
    await prefs.setString(_kLastSyncActionKey, action);
    if (!mounted) return;
    setState(() {
      _lastSyncAt = now;
      _lastSyncItemCount = counts.total;
      _lastSyncAction = action;
      _localCounts = counts;
    });
  }

  String _formatDateTime(DateTime? time) {
    if (time == null) return '暂无记录';
    final now = DateTime.now();
    final sameDay =
        now.year == time.year && now.month == time.month && now.day == time.day;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    if (sameDay) return '今天 $hh:$mm';
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _backupToCloud() async {
    if (_user == null) {
      AppToast.show(context, '请先登录');
      return;
    }
    _setWorking(true);
    _addLog('开始上传本地数据...');

    try {
      final db = AppDatabaseScope.of(context);
      final syncService = SupabaseSyncService(db);

      await syncService.syncToCloud(onProgress: (msg) => _addLog(msg));

      final localCounts = await _queryLocalDataCounts(db);
      _addLog('上传完成：本地 ${localCounts.total} 条已写入云端。');
      await _saveSyncSnapshot('上传', localCounts: localCounts);
      await _refreshCloudCounts(silent: true);
      if (mounted) AppToast.show(context, '同步至云端成功');
    } catch (e) {
      _addLog('上传失败: $e');
      if (mounted) AppToast.show(context, '同步失败');
    } finally {
      _setWorking(false);
    }
  }

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
          content: const Text('此操作会从云端拉取当前账号的数据，并覆盖本地同 ID 的相关记录。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                '继续恢复',
                style: AppTypography.base(
                  fontSize: AppTypography.fs14,
                  fontWeight: AppTypography.medium,
                  color: AppColors.red500,
                ),
              ),
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

  Future<void> _performRestore() async {
    _setWorking(true);
    _addLog('开始从云端拉取数据...');

    try {
      final db = AppDatabaseScope.of(context);
      final syncService = SupabaseSyncService(db);

      await syncService.syncFromCloud(onProgress: (msg) => _addLog(msg));

      final localCounts = await _queryLocalDataCounts(db);
      _addLog('恢复完成：本地当前共有 ${localCounts.total} 条同步数据。');
      await _saveSyncSnapshot('恢复', localCounts: localCounts);
      await _refreshCloudCounts(silent: true);
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('恢复成功'),
            content: const Text('数据已恢复。若其它页面仍显示旧数据，请返回后重新进入页面。'),
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
      if (mounted) AppToast.show(context, '恢复失败: $e');
    } finally {
      _setWorking(false);
    }
  }

  Future<void> _refreshBackupVersions({bool silent = false}) async {
    if (_user == null) {
      if (!mounted) return;
      setState(() {
        _backupVersions = const <CloudBackupVersion>[];
        _backupVersionError = null;
        _backupVersionLoading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _backupVersionLoading = true;
      _backupVersionError = null;
    });
    try {
      final rows = await _cloudBackupService.listVersions();
      if (!mounted) return;
      setState(() {
        _backupVersions = rows;
        _backupVersionLoading = false;
      });
      if (!silent) _addLog('备份版本列表已刷新：${rows.length} 条。');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupVersionError = '备份版本读取失败';
        _backupVersionLoading = false;
      });
      if (!silent) _addLog('备份版本读取失败: $e');
    }
  }

  Future<void> _manualBackupToCloud() async {
    if (_user == null) {
      AppToast.show(context, '请先登录');
      return;
    }
    if (_isWorking) return;
    _setWorking(true);
    _addLog('开始手动云端备份…');
    try {
      await _cloudBackupService.createManualBackup(
        onProgress: (msg) => _addLog(msg),
      );
      _addLog('手动备份完成。');
      await _refreshBackupVersions(silent: true);
      if (mounted) AppToast.show(context, '手动备份成功');
    } catch (e) {
      _addLog('手动备份失败: $e');
      if (mounted) AppToast.show(context, '手动备份失败');
    } finally {
      _setWorking(false);
    }
  }

  Future<void> _maybeRunAutoBackup({bool silent = false}) async {
    if (_user == null) return;
    if (_isWorking) return;
    try {
      final v = await _cloudBackupService.runAutoBackupIfNeeded(
        onProgress: silent ? (_) {} : (msg) => _addLog(msg),
      );
      if (v != null) {
        if (!silent) _addLog('自动备份已更新。');
        await _refreshBackupVersions(silent: true);
      }
    } catch (e) {
      if (!silent) _addLog('自动备份失败: $e');
    }
  }

  Future<void> _restoreFromBackupVersion(CloudBackupVersion version) async {
    if (_user == null) {
      AppToast.show(context, '请先登录');
      return;
    }
    if (_isWorking) return;
    final kindLabel =
        version.kind == CloudBackupKind.auto ? '自动备份' : '手动备份';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('按版本恢复'),
          content: Text('将从云端 $kindLabel 下载备份包并覆盖恢复本地数据（含媒体文件）。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                '继续恢复',
                style: AppTypography.base(
                  fontSize: AppTypography.fs14,
                  fontWeight: AppTypography.medium,
                  color: AppColors.red500,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    _setWorking(true);
    _addLog('开始按版本恢复…');
    try {
      await _cloudBackupService.restoreVersion(
        version: version,
        onProgress: (msg) => _addLog(msg),
      );
      final db = _db;
      if (db != null) {
        final localCounts = await _queryLocalDataCounts(db);
        await _saveSyncSnapshot('版本恢复', localCounts: localCounts);
      }
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('恢复成功'),
          content: const Text('数据已恢复。若其它页面仍显示旧数据，请返回后重新进入页面。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      _addLog('版本恢复失败: $e');
      if (mounted) AppToast.show(context, '版本恢复失败');
    } finally {
      _setWorking(false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var v = bytes.toDouble();
    var idx = 0;
    while (v >= 1024 && idx < units.length - 1) {
      v /= 1024;
      idx++;
    }
    return '${v.toStringAsFixed(idx == 0 ? 0 : 1)} ${units[idx]}';
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _user != null;
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          PrototypeTopBar(
            title: '云同步管理',
            left: PrototypeIconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textPrimary,
              onPressed: _isWorking ? null : () => Navigator.of(context).pop(),
            ),
            right: PrototypeIconButton(
              icon: const FaIcon(FontAwesomeIcons.rotate, size: 15),
              backgroundColor: AppColors.indigo50,
              foregroundColor: AppColors.indigo700,
              onPressed: _isWorking || _cloudCountLoading || !isLoggedIn
                  ? null
                  : () => _refreshCloudCounts(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildStatusCard(isLoggedIn),
                const SizedBox(height: 24),
                _buildDataOverviewCard(isLoggedIn),
                const SizedBox(height: 24),
                _buildSectionTitle('快速操作'),
                const SizedBox(height: 12),
                _buildActionTile(
                  title: '同步本地到云端',
                  subtitle: '上传当前本地 ${_localCounts.total} 条同步数据',
                  icon: FontAwesomeIcons.cloudArrowUp,
                  onTap: _isWorking || !isLoggedIn ? null : _backupToCloud,
                  isPrimary: true,
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  title: '从云端恢复数据',
                  subtitle: _cloudCounts == null
                      ? '先读取云端统计后再恢复'
                      : '拉取云端 ${_cloudCounts!.total} 条同步数据',
                  icon: FontAwesomeIcons.cloudArrowDown,
                  onTap: _isWorking || !isLoggedIn ? null : _showRestoreDialog,
                  isPrimary: false,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('备份版本'),
                const SizedBox(height: 12),
                _buildBackupVersionsCard(isLoggedIn),
                const SizedBox(height: 24),
                _buildSyncScopeCard(),
                const SizedBox(height: 24),
                _buildLogPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isLoggedIn) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(color: AppColors.indigo100, width: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.indigo50,
              borderRadius: AppRadii.brXl,
            ),
            alignment: Alignment.center,
            child: FaIcon(
              FontAwesomeIcons.cloud,
              color: isLoggedIn ? AppColors.indigo700 : AppColors.gray400,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLoggedIn ? '云端已连接' : '未连接云端',
                        style: AppTypography.base(
                          fontSize: AppTypography.fs16,
                          fontWeight: AppTypography.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    PrototypePill(
                      label: _isWorking ? '同步中' : (isLoggedIn ? '已登录' : '未登录'),
                      background: _isWorking
                          ? AppColors.orange100
                          : (isLoggedIn
                                ? AppColors.green100
                                : AppColors.gray100),
                      foreground: _isWorking
                          ? AppColors.orange600
                          : (isLoggedIn
                                ? AppColors.green600
                                : AppColors.textTertiary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isLoggedIn ? (_user!.email ?? '未知账号') : '请先登录后使用云同步',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.base(
                    fontSize: AppTypography.fs14,
                    fontWeight: AppTypography.regular,
                    color: isLoggedIn
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        label: '上次同步',
                        value: _formatDateTime(_lastSyncAt),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniMetric(
                        label: '同步条目',
                        value: _lastSyncAt == null
                            ? '暂无记录'
                            : '$_lastSyncItemCount 条',
                      ),
                    ),
                  ],
                ),
                if (_lastSyncAction != null) ...[
                  const SizedBox(height: 8),
                  Text('最近操作：$_lastSyncAction', style: AppTypography.caption()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOverviewCard(bool isLoggedIn) {
    final cloudTotalText = !isLoggedIn
        ? '未登录'
        : (_cloudCountLoading
              ? '读取中'
              : (_cloudCountError != null
                    ? '读取失败'
                    : '${_cloudCounts?.total ?? 0}'));
    final cloudSubtitle = !isLoggedIn
        ? '登录后统计'
        : (_cloudCountError ?? '当前账号云端数据');

    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '真实数据统计',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs16,
                    fontWeight: AppTypography.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_cloudCountLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.indigo600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CountSummaryTile(
                  title: '本地数据',
                  value: '${_localCounts.total}',
                  subtitle: '本机数据库',
                  icon: FontAwesomeIcons.database,
                  background: AppColors.indigo50,
                  foreground: AppColors.indigo700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountSummaryTile(
                  title: '云端数据',
                  value: cloudTotalText,
                  subtitle: cloudSubtitle,
                  icon: FontAwesomeIcons.cloud,
                  background: AppColors.blue50,
                  foreground: AppColors.blue600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const PrototypeDivider(),
          const SizedBox(height: 12),
          _CountsBreakdown(
            localCounts: _localCounts,
            cloudCounts: _cloudCounts,
            showCloudCounts: isLoggedIn && !_cloudCountLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupVersionsCard(bool isLoggedIn) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '云端备份版本',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs16,
                    fontWeight: AppTypography.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.rotate, size: 14),
                backgroundColor: AppColors.gray50,
                foregroundColor: AppColors.textSecondary,
                onPressed: _isWorking || _backupVersionLoading || !isLoggedIn
                    ? null
                    : () => _refreshBackupVersions(),
              ),
              const SizedBox(width: 8),
              PrototypeButton(
                label: '手动备份',
                background: AppColors.indigo600,
                foreground: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                onPressed: _isWorking || !isLoggedIn ? null : _manualBackupToCloud,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isLoggedIn)
            Text('登录后可查看与创建云端备份版本。', style: AppTypography.caption())
          else if (_backupVersionLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_backupVersionError != null)
            Text(_backupVersionError!, style: AppTypography.caption())
          else if (_backupVersions.isEmpty)
            Text('暂无备份版本', style: AppTypography.caption())
          else
            Column(
              children: [
                for (final v in _backupVersions) ...[
                  _BackupVersionRow(
                    version: v,
                    sizeLabel: _formatBytes(v.sizeBytes),
                    timeLabel: _formatDateTime(
                      DateTime.fromMillisecondsSinceEpoch(v.createdAt),
                    ),
                    onRestore: _isWorking ? null : () => _restoreFromBackupVersion(v),
                  ),
                  if (v != _backupVersions.last) const SizedBox(height: 10),
                ],
              ],
            ),
          const SizedBox(height: 8),
          Text(
            '自动备份每 3 天覆盖更新一次；手动备份每次点击生成新版本。',
            style: AppTypography.caption(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.base(
        fontSize: AppTypography.fs12,
        fontWeight: AppTypography.bold,
        color: AppColors.textTertiary,
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
    final enabled = onTap != null;
    final background = isPrimary ? AppColors.brandPrimary : AppColors.white;
    final foreground = isPrimary ? AppColors.white : AppColors.textPrimary;
    final mutedForeground = isPrimary
        ? AppColors.indigo100
        : AppColors.textSecondary;

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.br2xl,
            border: Border.all(
              color: isPrimary
                  ? AppColors.brandPrimary
                  : AppColors.borderSubtle,
              width: 1,
            ),
            boxShadow: isPrimary ? AppShadows.brandFab : AppShadows.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPrimary ? AppColors.white20 : AppColors.indigo50,
                  borderRadius: AppRadii.brXl,
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  icon,
                  color: isPrimary ? AppColors.white : AppColors.indigo700,
                  size: 18,
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
                        fontSize: AppTypography.fs16,
                        fontWeight: AppTypography.semibold,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.base(
                        fontSize: AppTypography.fs12,
                        fontWeight: AppTypography.regular,
                        color: mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                color: isPrimary ? AppColors.white20 : AppColors.textTertiary,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncScopeCard() {
    return PrototypeCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.orange50,
              borderRadius: AppRadii.brLg,
            ),
            alignment: Alignment.center,
            child: const FaIcon(
              FontAwesomeIcons.circleInfo,
              color: AppColors.orange600,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '同步范围',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs14,
                    fontWeight: AppTypography.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '统计与同步范围一致：账簿、关系人、礼金记录、事由、关系类型、联系人关系。附件媒体会随同步流程处理，但不计入条目数。',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textSecondary,
                    height: 1.45,
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
                      fontSize: AppTypography.fs14,
                      fontWeight: AppTypography.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
                PrototypePill(
                  label: '本地 ${_localCounts.total} 条',
                  background: AppColors.white10,
                  foreground: AppColors.gray300,
                  fontSize: AppTypography.fs12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
                    fontSize: AppTypography.fs12,
                    fontWeight: AppTypography.medium,
                    color: AppColors.gray300,
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
                  _isWorking ? '同步中' : '空闲',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs12,
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
                      style: AppTypography.base(
                        fontSize: AppTypography.fs12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.gray300,
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

class _SyncDataCounts {
  const _SyncDataCounts({
    required this.accountBooks,
    required this.persons,
    required this.giftRecords,
    required this.reasons,
    required this.relationTypes,
    required this.contactRelations,
  });

  static const zero = _SyncDataCounts(
    accountBooks: 0,
    persons: 0,
    giftRecords: 0,
    reasons: 0,
    relationTypes: 0,
    contactRelations: 0,
  );

  factory _SyncDataCounts.fromRow(Map<String, Object?> row) {
    int readCount(String key) {
      final value = row[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return _SyncDataCounts(
      accountBooks: readCount('account_books'),
      persons: readCount('persons'),
      giftRecords: readCount('gift_records'),
      reasons: readCount('reasons'),
      relationTypes: readCount('relation_types'),
      contactRelations: readCount('contact_relations'),
    );
  }

  final int accountBooks;
  final int persons;
  final int giftRecords;
  final int reasons;
  final int relationTypes;
  final int contactRelations;

  int get total =>
      accountBooks +
      persons +
      giftRecords +
      reasons +
      relationTypes +
      contactRelations;
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadii.brLg,
      ),
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
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.base(
              fontSize: AppTypography.fs14,
              fontWeight: AppTypography.semibold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountSummaryTile extends StatelessWidget {
  const _CountSummaryTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: background, borderRadius: AppRadii.brXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 14, color: foreground),
              const Spacer(),
              Text(
                title,
                style: AppTypography.base(
                  fontSize: AppTypography.fs12,
                  fontWeight: AppTypography.medium,
                  color: foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.base(
              fontSize: AppTypography.fs24,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.base(
              fontSize: AppTypography.fs12,
              fontWeight: AppTypography.regular,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountsBreakdown extends StatelessWidget {
  const _CountsBreakdown({
    required this.localCounts,
    required this.cloudCounts,
    required this.showCloudCounts,
  });

  final _SyncDataCounts localCounts;
  final _SyncDataCounts? cloudCounts;
  final bool showCloudCounts;

  @override
  Widget build(BuildContext context) {
    final cloud = cloudCounts;
    final rows = [
      ('账簿', localCounts.accountBooks, cloud?.accountBooks),
      ('关系人', localCounts.persons, cloud?.persons),
      ('礼金记录', localCounts.giftRecords, cloud?.giftRecords),
      ('事由', localCounts.reasons, cloud?.reasons),
      ('关系类型', localCounts.relationTypes, cloud?.relationTypes),
      ('联系人关系', localCounts.contactRelations, cloud?.contactRelations),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text('数据类型', style: AppTypography.caption())),
            _BreakdownHeader(label: '本地'),
            _BreakdownHeader(label: '云端'),
          ],
        ),
        const SizedBox(height: 8),
        for (final row in rows) ...[
          _BreakdownRow(
            label: row.$1,
            localCount: row.$2,
            cloudCount: showCloudCounts ? row.$3 : null,
          ),
          if (row != rows.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _BreakdownHeader extends StatelessWidget {
  const _BreakdownHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: AppTypography.caption(),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.localCount,
    required this.cloudCount,
  });

  final String label;
  final int localCount;
  final int? cloudCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.base(
              fontSize: AppTypography.fs12,
              fontWeight: AppTypography.medium,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _BreakdownCount(value: '$localCount'),
        _BreakdownCount(value: cloudCount == null ? '-' : '$cloudCount'),
      ],
    );
  }
}

class _BreakdownCount extends StatelessWidget {
  const _BreakdownCount({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: AppTypography.base(
          fontSize: AppTypography.fs12,
          fontWeight: AppTypography.semibold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _BackupVersionRow extends StatelessWidget {
  const _BackupVersionRow({
    required this.version,
    required this.sizeLabel,
    required this.timeLabel,
    required this.onRestore,
  });

  final CloudBackupVersion version;
  final String sizeLabel;
  final String timeLabel;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final isAuto = version.kind == CloudBackupKind.auto;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          PrototypePill(
            label: isAuto ? '自动' : '手动',
            background: isAuto ? AppColors.blue100 : AppColors.green100,
            foreground: isAuto ? AppColors.blue700 : AppColors.green600,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.base(
                    fontSize: AppTypography.fs14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sizeLabel,
                  style: AppTypography.base(
                    fontSize: AppTypography.fs12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PrototypeButton(
            label: '恢复',
            background: AppColors.white,
            foreground: AppColors.indigo700,
            border: Border.all(color: AppColors.indigo200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onPressed: onRestore,
          ),
        ],
      ),
    );
  }
}
