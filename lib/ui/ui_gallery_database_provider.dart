import 'package:flutter/widgets.dart';
import 'package:drift/native.dart';

import '../data/local/drift/app_database.dart';
import 'app_database_scope.dart';
import 'ui_gallery_database_seeder.dart';

class UiGalleryDatabaseProvider extends StatefulWidget {
  const UiGalleryDatabaseProvider({super.key, required this.child});

  final Widget child;

  @override
  State<UiGalleryDatabaseProvider> createState() =>
      _UiGalleryDatabaseProviderState();
}

class _UiGalleryDatabaseProviderState extends State<UiGalleryDatabaseProvider> {
  late AppDatabase _db;
  Future<void> _seedFuture = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _openDb();
    _seedFuture = UiGalleryDatabaseSeeder.seed(_db);
  }

  void _openDb() {
    _db = AppDatabase.forTesting(NativeDatabase.memory());
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> restartDatabase() async {
    await _db.close();
    _openDb();
    _seedFuture = UiGalleryDatabaseSeeder.seed(_db);
    if (mounted) setState(() {});
  }

  Future<T> _withDatabasePausedInternal<T>(Future<T> Function() action) async {
    await _db.close();
    try {
      return await action();
    } finally {
      _openDb();
      _seedFuture = UiGalleryDatabaseSeeder.seed(_db);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDatabaseControllerScope(
      restartDatabase: restartDatabase,
      withDatabasePaused: (action) async {
        await _seedFuture;
        return _withDatabasePausedInternal(action);
      },
      child: AppDatabaseScope(db: _db, child: widget.child),
    );
  }
}
