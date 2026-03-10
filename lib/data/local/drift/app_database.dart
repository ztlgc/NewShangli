import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';
part 'daos/account_books_dao.dart';
part 'daos/persons_dao.dart';
part 'daos/gift_records_dao.dart';
part 'daos/event_reminders_dao.dart';
part 'daos/data_import_jobs_dao.dart';

/// 应用主数据库（Drift）。
///
/// 设计规范要点：
/// - 账簿是一级上下文：person / gift_record / event_reminder 都必须归属 book_id
/// - 外键约束必须生效：在 SQLite 中需要显式开启 `PRAGMA foreign_keys = ON`
@DriftDatabase(
  tables: [
    AccountBooks,
    Persons,
    GiftRecords,
    EventReminders,
    DataImportJobs,
  ],
  daos: [
    AccountBooksDao,
    PersonsDao,
    GiftRecordsDao,
    EventRemindersDao,
    DataImportJobsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 用于测试时注入内存数据库或自定义执行器。
  AppDatabase.forTesting(super.executor);

  /// 当前 schema 版本。
  ///
  /// 版本升级时在 [migration] 中补齐迁移逻辑，并同步单元测试。
  @override
  int get schemaVersion => 4;

  /// 统一注入迁移策略：
  /// - onCreate：创建所有表与索引
  /// - onUpgrade：按版本增量迁移
  /// - beforeOpen：开启外键约束
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _ensureIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 1) {
            await m.createAll();
            await _ensureIndexes();
            return;
          }
          if (from < 2) {
            await m.createTable(dataImportJobs);
            await _ensureIndexes();
          }
          if (from < 3) {
            final cols = await customSelect('PRAGMA table_info(account_book);').get();
            final names = cols.map((e) => (e.data['name'] as String?) ?? '').toSet();

            if (names.contains('reason_type')) {
              await customStatement(
                "UPDATE account_book SET reason_type = CASE reason_type WHEN 'default' THEN '结婚礼金' WHEN 'wedding' THEN '结婚礼金' WHEN 'business' THEN '商务往来' ELSE reason_type END;",
              );
            } else if (names.contains('type')) {
              await customStatement(
                "UPDATE account_book SET type = CASE type WHEN 'default' THEN '结婚礼金' WHEN 'wedding' THEN '结婚礼金' WHEN 'business' THEN '商务往来' ELSE type END;",
              );
              try {
                await customStatement('ALTER TABLE account_book RENAME COLUMN type TO reason_type;');
              } catch (_) {
                await customStatement('ALTER TABLE account_book RENAME TO account_book__old;');
                await m.createTable(accountBooks);
                await customStatement(
                  'INSERT INTO account_book(book_id, name, reason_type, theme_color, icon, description, is_default, created_at, updated_at) '
                  'SELECT book_id, name, type, theme_color, icon, description, is_default, created_at, updated_at FROM account_book__old;',
                );
                await customStatement('DROP TABLE account_book__old;');
              }
            }
          }
          if (from < 4) {
            await m.addColumn(eventReminders, eventReminders.title as GeneratedColumn<Object>);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA synchronous = NORMAL;');
        },
      );

  /// 统一生成 UUID（TEXT 主键）。
  String newId() => const Uuid().v4();

  Future<void> _ensureIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_person_book_name ON person(book_id, name);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_gift_record_book_occurred ON gift_record(book_id, occurred_at);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_gift_record_book_person ON gift_record(book_id, person_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_event_reminder_book_remind_at ON event_reminder(book_id, remind_at);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_event_reminder_book_target_date ON event_reminder(book_id, target_date);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_import_job_book_started ON data_import_job(book_id, started_at);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_import_job_status_updated ON data_import_job(status, updated_at);',
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'newshangli_drift.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
