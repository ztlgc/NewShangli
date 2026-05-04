import 'package:flutter/widgets.dart';
import 'package:drift/native.dart';

import '../data/local/drift/app_database.dart';
import 'app_database_scope.dart';
import 'prototype_database_seeder.dart';

class PrototypeDatabaseProvider extends StatefulWidget {
  const PrototypeDatabaseProvider({super.key, required this.child});

  final Widget child;

  @override
  State<PrototypeDatabaseProvider> createState() =>
      _PrototypeDatabaseProviderState();
}

class _PrototypeDatabaseProviderState extends State<PrototypeDatabaseProvider> {
  late AppDatabase _db;
  Future<void> _seedFuture = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _openDb();
    _seedFuture = PrototypeDatabaseSeeder.seed(_db);
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
    _seedFuture = PrototypeDatabaseSeeder.seed(_db);
    if (mounted) setState(() {});
  }

  Future<T> _withDatabasePausedInternal<T>(Future<T> Function() action) async {
    await _db.close();
    try {
      return await action();
    } finally {
      _openDb();
      _seedFuture = PrototypeDatabaseSeeder.seed(_db);
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
