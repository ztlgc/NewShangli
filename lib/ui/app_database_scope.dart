import 'package:flutter/widgets.dart';

import '../data/local/drift/app_database.dart';
import '../import/data_import_service.dart';

class AppDatabaseProvider extends StatefulWidget {
  const AppDatabaseProvider({
    super.key,
    required this.child,
    this.databaseFactory,
  });

  final Widget child;
  final AppDatabase Function()? databaseFactory;

  @override
  State<AppDatabaseProvider> createState() => _AppDatabaseProviderState();
}

class _AppDatabaseProviderState extends State<AppDatabaseProvider> {
  late AppDatabase _db;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _openDb();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  void _openDb() {
    final factory = widget.databaseFactory;
    if (factory != null) {
      _db = factory();
      return;
    }
    _db = AppDatabase();
  }

  Future<void> restartDatabase() async {
    await _db.close();
    _openDb();
    if (mounted) {
      setState(() {});
    }
  }

  Future<T> withDatabasePaused<T>(Future<T> Function() action) async {
    if (_paused) throw StateError('数据库正在恢复，请稍候');
    if (DataImportService.isRunning(_db)) {
      throw StateError('导入进行中，请等待完成或暂停后再恢复');
    }
    setState(() => _paused = true);
    try {
      await _db.close();
      return await action();
    } finally {
      _openDb();
      try {
        await _db.customSelect('SELECT 1').get();
      } finally {
        _paused = false;
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDatabaseControllerScope(
      restartDatabase: restartDatabase,
      withDatabasePaused: withDatabasePaused,
      child: AppDatabaseScope(
        db: _db,
        child: AbsorbPointer(absorbing: _paused, child: widget.child),
      ),
    );
  }
}

class AppDatabaseControllerScope extends InheritedWidget {
  const AppDatabaseControllerScope({
    super.key,
    required this.restartDatabase,
    required this.withDatabasePaused,
    required super.child,
  });

  final Future<void> Function() restartDatabase;
  final Future<dynamic> Function(Future<dynamic> Function() action)
  withDatabasePaused;

  static AppDatabaseControllerScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppDatabaseControllerScope>();
  }

  static AppDatabaseControllerScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
      scope != null,
      'AppDatabaseControllerScope not found in widget tree.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppDatabaseControllerScope oldWidget) =>
      identical(restartDatabase, oldWidget.restartDatabase) == false;
}

class AppDatabaseScope extends InheritedWidget {
  const AppDatabaseScope({super.key, required this.db, required super.child});

  final AppDatabase db;

  static AppDatabase? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppDatabaseScope>()?.db;
  }

  static AppDatabase of(BuildContext context) {
    final db = maybeOf(context);
    assert(db != null, 'AppDatabaseScope not found in widget tree.');
    return db!;
  }

  @override
  bool updateShouldNotify(AppDatabaseScope oldWidget) =>
      identical(db, oldWidget.db) == false;
}
