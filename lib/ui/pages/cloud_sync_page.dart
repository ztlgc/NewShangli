import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../backup/cloud_backup_service.dart';
import '../../backup/supabase_sync_service.dart';
import '../../data/local/drift/app_database.dart';
import '../../media/media_storage_service.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_notification_tokens.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../prototype_kit.dart';

const Object _cloudSyncUnset = Object();

class _CloudSyncViewState {
  const _CloudSyncViewState({
    required this.user,
    required this.isWorking,
    required this.cloudCountLoading,
    required this.logs,
    required this.lastSyncAt,
    required this.lastSyncItemCount,
    required this.lastSyncAction,
    required this.localCounts,
    required this.cloudCounts,
    required this.cloudCountError,
    required this.backupVersionLoading,
    required this.backupVersionError,
    required this.backupVersions,
  });

  factory _CloudSyncViewState.initial({required User? user}) {
    return _CloudSyncViewState(
      user: user,
      isWorking: false,
      cloudCountLoading: false,
      logs: const <String>[],
      lastSyncAt: null,
      lastSyncItemCount: 0,
      lastSyncAction: null,
      localCounts: _SyncDataCounts.zero,
      cloudCounts: null,
      cloudCountError: null,
      backupVersionLoading: false,
      backupVersionError: null,
      backupVersions: const <CloudBackupVersion>[],
    );
  }

  final User? user;
  final bool isWorking;
  final bool cloudCountLoading;
  final List<String> logs;
  final DateTime? lastSyncAt;
  final int lastSyncItemCount;
  final String? lastSyncAction;
  final _SyncDataCounts localCounts;
  final _SyncDataCounts? cloudCounts;
  final String? cloudCountError;
  final bool backupVersionLoading;
  final String? backupVersionError;
  final List<CloudBackupVersion> backupVersions;

  bool get isLoggedIn => user != null;

  _CloudSyncViewState copyWith({
    Object? user = _cloudSyncUnset,
    bool? isWorking,
    bool? cloudCountLoading,
    List<String>? logs,
    Object? lastSyncAt = _cloudSyncUnset,
    int? lastSyncItemCount,
    Object? lastSyncAction = _cloudSyncUnset,
    _SyncDataCounts? localCounts,
    Object? cloudCounts = _cloudSyncUnset,
    Object? cloudCountError = _cloudSyncUnset,
    bool? backupVersionLoading,
    Object? backupVersionError = _cloudSyncUnset,
    List<CloudBackupVersion>? backupVersions,
  }) {
    return _CloudSyncViewState(
      user: identical(user, _cloudSyncUnset) ? this.user : user as User?,
      isWorking: isWorking ?? this.isWorking,
      cloudCountLoading: cloudCountLoading ?? this.cloudCountLoading,
      logs: logs ?? this.logs,
      lastSyncAt: identical(lastSyncAt, _cloudSyncUnset)
          ? this.lastSyncAt
          : lastSyncAt as DateTime?,
      lastSyncItemCount: lastSyncItemCount ?? this.lastSyncItemCount,
      lastSyncAction: identical(lastSyncAction, _cloudSyncUnset)
          ? this.lastSyncAction
          : lastSyncAction as String?,
      localCounts: localCounts ?? this.localCounts,
      cloudCounts: identical(cloudCounts, _cloudSyncUnset)
          ? this.cloudCounts
          : cloudCounts as _SyncDataCounts?,
      cloudCountError: identical(cloudCountError, _cloudSyncUnset)
          ? this.cloudCountError
          : cloudCountError as String?,
      backupVersionLoading: backupVersionLoading ?? this.backupVersionLoading,
      backupVersionError: identical(backupVersionError, _cloudSyncUnset)
          ? this.backupVersionError
          : backupVersionError as String?,
      backupVersions: backupVersions ?? this.backupVersions,
    );
  }
}

class _CloudSyncActionResult {
  const _CloudSyncActionResult.none()
    : toastMessage = null,
      dialogTitle = null,
      dialogMessage = null;

  const _CloudSyncActionResult.toast(String message)
    : toastMessage = message,
      dialogTitle = null,
      dialogMessage = null;

  const _CloudSyncActionResult.dialog({
    required String title,
    required String message,
  }) : toastMessage = null,
       dialogTitle = title,
       dialogMessage = message;

  final String? toastMessage;
  final String? dialogTitle;
  final String? dialogMessage;

  bool get hasToast => toastMessage != null;
  bool get hasDialog => dialogTitle != null && dialogMessage != null;
}

class _CloudSyncController extends ChangeNotifier {
  _CloudSyncController({CloudBackupService? cloudBackupService})
    : _cloudBackupService = cloudBackupService ?? CloudBackupService(),
      _state = _CloudSyncViewState.initial(
        user: Supabase.instance.client.auth.currentUser,
      );

  static const String _kLastSyncAtKey = 'cloud_sync_last_at_ms_v1';
  static const String _kLastSyncCountKey = 'cloud_sync_last_item_count_v1';
  static const String _kLastSyncActionKey = 'cloud_sync_last_action_v1';

  final CloudBackupService _cloudBackupService;

  _CloudSyncViewState _state;
  AppDatabase? _db;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<_SyncDataCounts>? _localCountsSubscription;
  bool _disposed = false;

  _CloudSyncViewState get state => _state;

  Future<void> initialize() async {
    _authStateSubscription ??= Supabase.instance.client.auth.onAuthStateChange
        .listen(_handleAuthStateChanged);
    _appendLog('云同步模块初始化成功。');
    await refreshCloudCounts(silent: true);
    await refreshBackupVersions(silent: true);
    // 自动备份尚未接入统一配置，暂不隐式上传。
  }

  void attachDatabase(AppDatabase db) {
    if (identical(_db, db)) return;
    _db = db;
    _localCountsSubscription?.cancel();
    _localCountsSubscription = _watchLocalDataCounts(db).listen((counts) {
      _updateState(_state.copyWith(localCounts: counts));
    });
    unawaited(_loadSyncOverview(db));
  }

  @override
  void dispose() {
    _disposed = true;
    _authStateSubscription?.cancel();
    _localCountsSubscription?.cancel();
    super.dispose();
  }

  Future<void> refreshCloudCounts({bool silent = false}) async {
    final user = _state.user;
    if (user == null) {
      _updateState(
        _state.copyWith(
          cloudCounts: null,
          cloudCountError: null,
          cloudCountLoading: false,
        ),
      );
      return;
    }

    _updateState(
      _state.copyWith(cloudCountLoading: true, cloudCountError: null),
    );

    try {
      final counts = await _queryCloudDataCounts(user);
      _updateState(
        _state.copyWith(cloudCounts: counts, cloudCountLoading: false),
      );
      if (!silent) _appendLog('云端数据统计已刷新：${counts.total} 条。');
    } catch (e) {
      _updateState(
        _state.copyWith(cloudCountError: '云端统计获取失败', cloudCountLoading: false),
      );
      if (!silent) _appendLog('云端统计获取失败: $e');
    }
  }

  Future<void> refreshBackupVersions({bool silent = false}) async {
    if (_state.user == null) {
      _updateState(
        _state.copyWith(
          backupVersions: const <CloudBackupVersion>[],
          backupVersionError: null,
          backupVersionLoading: false,
        ),
      );
      return;
    }

    _updateState(
      _state.copyWith(backupVersionLoading: true, backupVersionError: null),
    );
    try {
      final rows = await _cloudBackupService.listVersions();
      _updateState(
        _state.copyWith(backupVersions: rows, backupVersionLoading: false),
      );
      if (!silent) _appendLog('备份版本列表已刷新：${rows.length} 条。');
    } catch (e) {
      _updateState(
        _state.copyWith(
          backupVersionError: '备份版本读取失败',
          backupVersionLoading: false,
        ),
      );
      if (!silent) _appendLog('备份版本读取失败: $e');
    }
  }

  Future<void> maybeRunAutoBackup({bool silent = false}) async {
    if (_state.user == null || _state.isWorking) return;
    try {
      final version = await _cloudBackupService.runAutoBackupIfNeeded(
        onProgress: silent ? (_) {} : _appendLog,
      );
      if (version != null) {
        if (!silent) _appendLog('自动备份已更新。');
        await refreshBackupVersions(silent: true);
      }
    } catch (e) {
      if (!silent) _appendLog('自动备份失败: $e');
    }
  }

  Future<_CloudSyncActionResult> syncToCloud() async {
    if (_state.user == null) return const _CloudSyncActionResult.toast('请先登录');
    return _runAction(
      startLog: '开始上传本地数据...',
      failureLogPrefix: '上传失败',
      failureFeedback: (_) => '同步失败',
      task: () async {
        final db = _requireDb();
        final syncService = SupabaseSyncService(db);
        await syncService.syncToCloud(onProgress: _appendLog);

        final localCounts = await _queryLocalDataCounts(db);
        _appendLog('上传完成：本地 ${localCounts.total} 条已写入云端。');
        await _saveSyncSnapshot('上传', localCounts: localCounts);
        await refreshCloudCounts(silent: true);
        return const _CloudSyncActionResult.toast('同步至云端成功');
      },
    );
  }

  Future<_CloudSyncActionResult> restoreFromCloud() async {
    if (_state.user == null) return const _CloudSyncActionResult.toast('请先登录');
    return _runAction(
      startLog: '开始从云端拉取数据...',
      failureLogPrefix: '恢复失败',
      failureFeedback: (error) => '恢复失败: $error',
      task: () async {
        final db = _requireDb();
        final syncService = SupabaseSyncService(db);
        await syncService.syncFromCloud(onProgress: _appendLog);

        final localCounts = await _queryLocalDataCounts(db);
        _appendLog('恢复完成：本地当前共有 ${localCounts.total} 条同步数据。');
        await _saveSyncSnapshot('恢复', localCounts: localCounts);
        await refreshCloudCounts(silent: true);
        return const _CloudSyncActionResult.dialog(
          title: '恢复成功',
          message: '云端表数据已合并；本地独有数据已保留。',
        );
      },
    );
  }

  Future<_CloudSyncActionResult> createManualBackup() async {
    if (_state.user == null) return const _CloudSyncActionResult.toast('请先登录');
    return _runAction(
      startLog: '开始手动云端备份…',
      failureLogPrefix: '手动备份失败',
      failureFeedback: (_) => '手动备份失败',
      task: () async {
        await _cloudBackupService.createManualBackup(onProgress: _appendLog);
        _appendLog('手动备份完成。');
        await refreshBackupVersions(silent: true);
        return const _CloudSyncActionResult.toast('手动备份成功');
      },
    );
  }

  Future<_CloudSyncActionResult> restoreFromBackupVersion(
    CloudBackupVersion version,
    Future<dynamic> Function(Future<dynamic> Function()) withDatabasePaused,
  ) async {
    if (_state.user == null) return const _CloudSyncActionResult.toast('请先登录');
    return _runAction(
      startLog: '开始按版本恢复…',
      failureLogPrefix: '版本恢复失败',
      failureFeedback: (_) => '版本恢复失败',
      task: () async {
        await withDatabasePaused(
          () => _cloudBackupService.restoreVersion(
            version: version,
            onProgress: _appendLog,
          ),
        );
        return const _CloudSyncActionResult.dialog(
          title: '恢复成功',
          message: '数据已恢复，数据库已重新打开。',
        );
      },
    );
  }

  Future<_CloudSyncActionResult> _runAction({
    required String startLog,
    required String failureLogPrefix,
    required String Function(Object error) failureFeedback,
    required Future<_CloudSyncActionResult> Function() task,
  }) async {
    if (_state.isWorking) return const _CloudSyncActionResult.none();
    _updateState(_state.copyWith(isWorking: true));
    _appendLog(startLog);
    try {
      return await task();
    } catch (e) {
      _appendLog('$failureLogPrefix: $e');
      return _CloudSyncActionResult.toast(failureFeedback(e));
    } finally {
      _updateState(_state.copyWith(isWorking: false));
    }
  }

  void _handleAuthStateChanged(AuthState data) {
    final user = data.session?.user;
    _updateState(
      _state.copyWith(
        user: user,
        cloudCounts: null,
        cloudCountError: null,
        cloudCountLoading: false,
        backupVersions: const <CloudBackupVersion>[],
        backupVersionError: null,
        backupVersionLoading: false,
      ),
    );
    unawaited(refreshCloudCounts(silent: true));
    unawaited(refreshBackupVersions(silent: true));
    // 自动备份尚未接入统一配置，暂不隐式上传。
  }

  Future<void> _loadSyncOverview(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncAtMs = prefs.getInt(_kLastSyncAtKey);
    final persistedAction = prefs.getString(_kLastSyncActionKey);
    final persistedCount = prefs.getInt(_kLastSyncCountKey) ?? 0;
    final localCounts = await _queryLocalDataCounts(db);
    _updateState(
      _state.copyWith(
        lastSyncAt: lastSyncAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastSyncAtMs),
        lastSyncItemCount: persistedCount,
        lastSyncAction: persistedAction,
        localCounts: localCounts,
      ),
    );
  }

  Future<void> _saveSyncSnapshot(
    String action, {
    _SyncDataCounts? localCounts,
  }) async {
    final db = _requireDb();
    final counts = localCounts ?? await _queryLocalDataCounts(db);
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSyncAtKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_kLastSyncCountKey, counts.total);
    await prefs.setString(_kLastSyncActionKey, action);
    _updateState(
      _state.copyWith(
        lastSyncAt: now,
        lastSyncItemCount: counts.total,
        lastSyncAction: action,
        localCounts: counts,
      ),
    );
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
    final base = _SyncDataCounts.fromRow(row.data);
    final attachments = await _countLocalAttachments();
    return base.copyWith(attachments: attachments);
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
        .asyncMap((rows) async {
          if (rows.isEmpty) return _SyncDataCounts.zero;
          final base = _SyncDataCounts.fromRow(rows.first.data);
          final attachments = await _countLocalAttachments();
          return base.copyWith(attachments: attachments);
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
      _countCloudAttachments(user.id),
    ]);

    return _SyncDataCounts(
      accountBooks: results[0],
      persons: results[1],
      giftRecords: results[2],
      reasons: results[3],
      relationTypes: results[4],
      contactRelations: results[5],
      attachments: results[6],
    );
  }

  Future<int> _countLocalAttachments() async {
    final mediaRoot = await MediaStorageService().mediaRootDir();
    if (!await mediaRoot.exists()) return 0;
    final entities = await mediaRoot
        .list(recursive: true, followLinks: false)
        .toList();
    return entities.whereType<File>().length;
  }

  Future<int> _countCloudAttachments(String userId) async {
    final storage = Supabase.instance.client.storage.from('media');
    final rootEntries = await storage.list(path: userId);
    final rootFiles = rootEntries.where((entry) {
      final name = entry.name.trim();
      return name.isNotEmpty &&
          name != '.emptyFolderPlaceholder' &&
          name != 'avatars' &&
          name != 'attachments';
    });

    final avatarEntries = await storage.list(path: '$userId/avatars');
    final attachmentEntries = await storage.list(path: '$userId/attachments');

    int countFiles(List<FileObject> entries) {
      return entries.where((entry) {
        final name = entry.name.trim();
        return name.isNotEmpty && name != '.emptyFolderPlaceholder';
      }).length;
    }

    return rootFiles.length +
        countFiles(avatarEntries) +
        countFiles(attachmentEntries);
  }

  AppDatabase _requireDb() {
    final db = _db;
    if (db == null) {
      throw StateError('数据库未初始化');
    }
    return db;
  }

  void _appendLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final logs = List<String>.of(_state.logs)..add('[$time] $message');
    _updateState(_state.copyWith(logs: logs));
  }

  void _updateState(_CloudSyncViewState nextState) {
    if (_disposed) return;
    _state = nextState;
    notifyListeners();
  }
}

class CloudSyncPage extends StatefulWidget {
  const CloudSyncPage({super.key});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  late final _CloudSyncController _controller;
  final ScrollController _logScrollController = ScrollController();
  int _lastLogCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = _CloudSyncController()..addListener(_handleControllerChanged);
    unawaited(_controller.initialize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.attachDatabase(AppDatabaseScope.of(context));
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final logCount = _controller.state.logs.length;
    if (logCount > _lastLogCount) {
      _lastLogCount = logCount;
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        if (!mounted || !_logScrollController.hasClients) return;
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
      return;
    }
    _lastLogCount = logCount;
  }

  Future<void> _handleActionResult(
    Future<_CloudSyncActionResult> Function() action,
  ) async {
    final result = await action();
    if (!mounted) return;
    if (result.hasToast) {
      AppNotifier.info(context, result.toastMessage!);
    }
    if (!mounted || !result.hasDialog) return;
    await AppDialog.showAlert(
      context,
      title: result.dialogTitle!,
      message: result.dialogMessage!,
    );
  }

  Future<void> _showRestoreDialog(_CloudSyncViewState state) async {
    if (!state.isLoggedIn) {
      AppNotifier.warning(context, '请先登录');
      return;
    }

    final confirm = await AppDialog.confirm(
      context,
      title: '合并云端数据',
      message:
          '按 ID 合并当前账号的数据，保留本地独有数据，同 ID 联系人和记录取更新时间较新的版本。此操作不等同于完整备份恢复。是否继续？',
      confirmLabel: '继续恢复',
      cancelLabel: '取消',
      tone: AppNotificationTone.error,
    );

    if (confirm == true) {
      await _handleActionResult(_controller.restoreFromCloud);
    }
  }

  Future<void> _confirmRestoreVersion(
    _CloudSyncViewState state,
    CloudBackupVersion version,
  ) async {
    if (!state.isLoggedIn) {
      AppNotifier.warning(context, '请先登录');
      return;
    }
    if (state.isWorking) return;
    final kindLabel = version.kind == CloudBackupKind.auto ? '自动备份' : '手动备份';
    final confirm = await AppDialog.confirm(
      context,
      title: '按版本恢复',
      message: '将从云端 $kindLabel 下载备份包并覆盖恢复本地数据（含媒体文件）。是否继续？',
      confirmLabel: '继续恢复',
      cancelLabel: '取消',
      tone: AppNotificationTone.error,
    );
    if (confirm == true && mounted) {
      final databaseController = AppDatabaseControllerScope.of(context);
      await _handleActionResult(
        () => _controller.restoreFromBackupVersion(
          version,
          databaseController.withDatabasePaused,
        ),
      );
    }
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

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
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
                  onPressed: state.isWorking
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
                right: PrototypeIconButton(
                  icon: const FaIcon(FontAwesomeIcons.rotate, size: 15),
                  backgroundColor: AppColors.indigo50,
                  foregroundColor: AppColors.indigo700,
                  onPressed:
                      state.isWorking ||
                          state.cloudCountLoading ||
                          !state.isLoggedIn
                      ? null
                      : () => _controller.refreshCloudCounts(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildStatusCard(state),
                    const SizedBox(height: 24),
                    _buildDataOverviewCard(state),
                    const SizedBox(height: 24),
                    _buildSectionTitle('快速操作'),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      title: '同步本地到云端',
                      subtitle: '上传当前本地 ${state.localCounts.total} 项同步内容',
                      icon: FontAwesomeIcons.cloudArrowUp,
                      onTap: state.isWorking || !state.isLoggedIn
                          ? null
                          : () => _handleActionResult(_controller.syncToCloud),
                      isPrimary: true,
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      title: '从云端恢复数据',
                      subtitle: state.cloudCounts == null
                          ? '先读取云端统计后再恢复'
                          : '拉取云端 ${state.cloudCounts!.total} 项同步内容',
                      icon: FontAwesomeIcons.cloudArrowDown,
                      onTap: state.isWorking || !state.isLoggedIn
                          ? null
                          : () => _showRestoreDialog(state),
                      isPrimary: false,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('备份版本'),
                    const SizedBox(height: 12),
                    _buildBackupVersionsCard(state),
                    const SizedBox(height: 24),
                    _buildSyncScopeCard(),
                    const SizedBox(height: 24),
                    _buildLogPanel(state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(_CloudSyncViewState state) {
    final colors = context.appColors;
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(color: colors.borderFocus, width: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.brandSoft,
              borderRadius: AppRadii.brXl,
            ),
            alignment: Alignment.center,
            child: FaIcon(
              FontAwesomeIcons.cloud,
              color: state.isLoggedIn ? colors.brandOnSoft : colors.textMuted,
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
                        state.isLoggedIn ? '云端已连接' : '未连接云端',
                        style: AppTypography.base(
                          fontSize: AppTypography.fs16,
                          fontWeight: AppTypography.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    PrototypePill(
                      label: state.isWorking
                          ? '同步中'
                          : (state.isLoggedIn ? '已登录' : '未登录'),
                      background: state.isWorking
                          ? AppColors.orange100
                          : (state.isLoggedIn
                                ? AppColors.green100
                                : AppColors.gray100),
                      foreground: state.isWorking
                          ? AppColors.orange600
                          : (state.isLoggedIn
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
                  state.isLoggedIn
                      ? (state.user!.email ?? '未知账号')
                      : '请先登录后使用云同步',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.base(
                    fontSize: AppTypography.fs14,
                    fontWeight: AppTypography.regular,
                    color: state.isLoggedIn
                        ? colors.textSecondary
                        : colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        label: '上次同步',
                        value: _formatDateTime(state.lastSyncAt),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniMetric(
                        label: '同步条目',
                        value: state.lastSyncAt == null
                            ? '暂无记录'
                            : '${state.lastSyncItemCount} 条',
                      ),
                    ),
                  ],
                ),
                if (state.lastSyncAction != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '最近操作：${state.lastSyncAction}',
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

  Widget _buildDataOverviewCard(_CloudSyncViewState state) {
    final cloudTotalText = !state.isLoggedIn
        ? '未登录'
        : (state.cloudCountLoading
              ? '读取中'
              : (state.cloudCountError != null
                    ? '读取失败'
                    : '${state.cloudCounts?.total ?? 0}'));
    final cloudSubtitle = !state.isLoggedIn
        ? '登录后统计'
        : (state.cloudCountError ?? '当前账号云端数据');

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
              if (state.cloudCountLoading)
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
                  value: '${state.localCounts.total}',
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
            localCounts: state.localCounts,
            cloudCounts: state.cloudCounts,
            showCloudCounts: state.isLoggedIn && !state.cloudCountLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupVersionsCard(_CloudSyncViewState state) {
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
                backgroundColor: context.appColors.surfaceSubtle,
                foregroundColor: AppColors.textSecondary,
                onPressed:
                    state.isWorking ||
                        state.backupVersionLoading ||
                        !state.isLoggedIn
                    ? null
                    : () => _controller.refreshBackupVersions(),
              ),
              const SizedBox(width: 8),
              PrototypeButton(
                label: '手动备份',
                background: AppColors.indigo600,
                foreground: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                onPressed: state.isWorking || !state.isLoggedIn
                    ? null
                    : () => _handleActionResult(_controller.createManualBackup),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!state.isLoggedIn)
            Text('登录后可查看与创建云端备份版本。', style: AppTypography.caption())
          else if (state.backupVersionLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (state.backupVersionError != null)
            Text(state.backupVersionError!, style: AppTypography.caption())
          else if (state.backupVersions.isEmpty)
            Text('暂无备份版本', style: AppTypography.caption())
          else
            Column(
              children: [
                for (final v in state.backupVersions) ...[
                  _BackupVersionRow(
                    version: v,
                    sizeLabel: _formatBytes(v.sizeBytes),
                    timeLabel: _formatDateTime(
                      DateTime.fromMillisecondsSinceEpoch(v.createdAt),
                    ),
                    onRestore: state.isWorking
                        ? null
                        : () => _confirmRestoreVersion(state, v),
                  ),
                  if (v != state.backupVersions.last)
                    const SizedBox(height: 10),
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
    final colors = context.appColors;
    final enabled = onTap != null;
    final background = isPrimary ? colors.brandPrimary : colors.surfaceCard;
    final foreground = isPrimary ? colors.textInverse : colors.textPrimary;
    final mutedForeground = isPrimary
        ? AppColors.indigo100
        : colors.textSecondary;

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
              color: isPrimary ? colors.brandPrimary : colors.borderSubtle,
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
                  color: isPrimary ? AppColors.white20 : colors.brandSoft,
                  borderRadius: AppRadii.brXl,
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  icon,
                  color: isPrimary ? colors.textInverse : colors.brandOnSoft,
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
                color: isPrimary ? AppColors.white20 : colors.textTertiary,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncScopeCard() {
    final colors = context.appColors;
    return PrototypeCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.orangeSoft,
              borderRadius: AppRadii.brLg,
            ),
            alignment: Alignment.center,
            child: FaIcon(
              FontAwesomeIcons.circleInfo,
              color: colors.orangeAccent,
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
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '统计与同步范围一致：账簿、关系人、礼金记录、事由、关系类型、联系人关系，以及附件媒体文件。',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs12,
                    fontWeight: AppTypography.regular,
                    color: colors.textSecondary,
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

  Widget _buildLogPanel(_CloudSyncViewState state) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
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
                  label: '本地 ${state.localCounts.total} 条',
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
                    color: state.isWorking
                        ? AppColors.orange600
                        : AppColors.gray500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  state.isWorking ? '同步中' : '空闲',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs12,
                    fontWeight: AppTypography.semibold,
                    color: state.isWorking
                        ? AppColors.orange100
                        : AppColors.gray300,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.gray700, height: 1),
          Expanded(
            child: Scrollbar(
              controller: _logScrollController,
              thumbVisibility: state.logs.isNotEmpty,
              child: ListView.builder(
                controller: _logScrollController,
                padding: const EdgeInsets.all(12),
                itemCount: state.logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      state.logs[index],
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
    required this.attachments,
  });

  static const zero = _SyncDataCounts(
    accountBooks: 0,
    persons: 0,
    giftRecords: 0,
    reasons: 0,
    relationTypes: 0,
    contactRelations: 0,
    attachments: 0,
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
      attachments: readCount('attachments'),
    );
  }

  final int accountBooks;
  final int persons;
  final int giftRecords;
  final int reasons;
  final int relationTypes;
  final int contactRelations;
  final int attachments;

  _SyncDataCounts copyWith({
    int? accountBooks,
    int? persons,
    int? giftRecords,
    int? reasons,
    int? relationTypes,
    int? contactRelations,
    int? attachments,
  }) {
    return _SyncDataCounts(
      accountBooks: accountBooks ?? this.accountBooks,
      persons: persons ?? this.persons,
      giftRecords: giftRecords ?? this.giftRecords,
      reasons: reasons ?? this.reasons,
      relationTypes: relationTypes ?? this.relationTypes,
      contactRelations: contactRelations ?? this.contactRelations,
      attachments: attachments ?? this.attachments,
    );
  }

  int get total =>
      accountBooks +
      persons +
      giftRecords +
      reasons +
      relationTypes +
      contactRelations +
      attachments;
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSubtle,
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
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.softFor(background),
        borderRadius: AppRadii.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 14, color: colors.foregroundFor(foreground)),
              const Spacer(),
              Text(
                title,
                style: AppTypography.base(
                  fontSize: AppTypography.fs12,
                  fontWeight: AppTypography.medium,
                  color: colors.foregroundFor(foreground),
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
              color: colors.textPrimary,
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
              color: colors.textSecondary,
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
      ('附件', localCounts.attachments, cloud?.attachments),
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
        color: context.appColors.surfaceSubtle,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Row(
        children: [
          PrototypePill(
            label: isAuto ? '自动' : '手动',
            background: isAuto ? AppColors.blue100 : AppColors.green100,
            foreground: isAuto ? AppColors.blue600 : AppColors.green600,
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
            border: Border.all(color: context.appColors.borderFocus),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onPressed: onRestore,
          ),
        ],
      ),
    );
  }
}
