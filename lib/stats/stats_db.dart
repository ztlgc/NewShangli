import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../platform/app_platform.dart';

class StatsDb {
  Database? _db;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await AppPlatform.documentsDirectory();
    final dbPath = p.join(dir.path, 'newshangli.db');
    final db = await openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE IF NOT EXISTS records(
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  direction INTEGER NOT NULL,
  amount_cent INTEGER NOT NULL,
  event_name TEXT NOT NULL,
  person_name TEXT NOT NULL,
  occurred_at_s INTEGER NOT NULL
)
''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_records_book_time ON records(book_id, occurred_at_s)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_records_event ON records(event_name)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_records_person ON records(person_name)',
        );
      },
    );
    _db = db;
    return db;
  }

  Future<void> upsertRecords(List<Map<String, Object?>> rows) async {
    final db = await _open();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final r in rows) {
        batch.insert(
          'records',
          r,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, Object?>>> query(
    String sql,
    List<Object?> args,
  ) async {
    final db = await _open();
    return db.rawQuery(sql, args);
  }
}
