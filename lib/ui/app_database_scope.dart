import 'package:flutter/widgets.dart';

import '../data/local/drift/app_database.dart';
import '../data/local/drift/reason_relation_migrator.dart';

class AppDatabaseProvider extends StatefulWidget {
  const AppDatabaseProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppDatabaseProvider> createState() => _AppDatabaseProviderState();
}

class _AppDatabaseProviderState extends State<AppDatabaseProvider> {
  late final AppDatabase _db;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    ReasonRelationMigrator.migrateIfNeeded(_db);
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDatabaseScope(
      db: _db,
      child: widget.child,
    );
  }
}

class AppDatabaseScope extends InheritedWidget {
  const AppDatabaseScope({
    super.key,
    required this.db,
    required super.child,
  });

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
  bool updateShouldNotify(AppDatabaseScope oldWidget) => identical(db, oldWidget.db) == false;
}
