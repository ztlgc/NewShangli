import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class StatsDb {
  Database? _db;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'newshangli.db');
    final db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE IF NOT EXISTS records(
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  direction INTEGER NOT NULL,
  amount_cent INTEGER NOT NULL,
  event_name TEXT NOT NULL,
  person_name TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  occurred_at_s INTEGER NOT NULL
)
''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_records_book_time ON records(book_id, occurred_at_s)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_records_event ON records(event_name)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_records_person ON records(person_name)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // 版本 2：为统计库增加 book_id 维度，支持按账簿统计与“默认账簿”兜底归属。
          await db.execute("ALTER TABLE records ADD COLUMN book_id TEXT NOT NULL DEFAULT 'book_default'");
          await db.execute('CREATE INDEX IF NOT EXISTS idx_records_book_time ON records(book_id, occurred_at_s)');
        }
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
        batch.insert('records', r, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, Object?>>> query(String sql, List<Object?> args) async {
    final db = await _open();
    return db.rawQuery(sql, args);
  }
}
