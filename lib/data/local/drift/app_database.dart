import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'converters.dart';
import 'tables.dart';
import '../../../backup/restore_safety.dart';

import '../../../platform/app_platform.dart';

part 'app_database.g.dart';
part 'daos/account_books_dao.dart';
part 'daos/persons_dao.dart';
part 'daos/gift_records_dao.dart';
part 'daos/data_import_jobs_dao.dart';
part 'daos/reasons_dao.dart';
part 'daos/relation_types_dao.dart';
part 'daos/contact_relations_dao.dart';

/// 应用主数据库（Drift）。
///
/// 设计规范要点：
/// - 礼金记录归属账簿，联系人为全局实体
/// - 外键约束必须生效：在 SQLite 中需要显式开启 `PRAGMA foreign_keys = ON`
@DriftDatabase(
  tables: [
    AccountBooks,
    Persons,
    GiftRecords,
    Reasons,
    RelationTypes,
    ContactRelations,
    DataImportJobs,
  ],
  daos: [
    AccountBooksDao,
    PersonsDao,
    GiftRecordsDao,
    ReasonsDao,
    RelationTypesDao,
    ContactRelationsDao,
    DataImportJobsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : seedDefaults = true, super(_openConnection());

  /// 用于测试时注入内存数据库或自定义执行器。
  AppDatabase.forTesting(super.executor, {this.seedDefaults = false});

  final bool seedDefaults;

  /// 当前 schema 版本。
  static const currentSchemaVersion = 15;
  @override
  int get schemaVersion => currentSchemaVersion;

  /// 初始化当前结构，不提供历史版本升级。
  /// - onCreate：创建所有表与索引
  /// - beforeOpen：开启外键约束
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('''
        CREATE TABLE IF NOT EXISTS entity_remark (
          remark_id TEXT NOT NULL PRIMARY KEY,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL
        );
      ''');
      await _ensureIndexes();
      if (seedDefaults) await _createDefaults();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
      await customStatement('PRAGMA synchronous = NORMAL;');
    },
  );

  Future<void> _createDefaults() async {
    await reasonsDao.create(name: '结婚礼金');
    for (final name in const ['家人', '亲戚', '同事', '朋友', '同学', '邻居']) {
      await relationTypesDao.create(name: name);
    }
  }

  /// 统一生成 UUID（TEXT 主键）。
  String newId() => const Uuid().v4();

  Future<void> _ensureIndexes() async {
    Future<void> createIndexIfTableExists(String tableName, String sql) async {
      final exists = await customSelect(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?;",
        variables: [Variable<String>(tableName)],
      ).get();
      if (exists.isEmpty) return;
      await customStatement(sql);
    }

    await createIndexIfTableExists(
      'person',
      'CREATE INDEX IF NOT EXISTS idx_person_book_name ON person(book_id, name);',
    );
    await createIndexIfTableExists(
      'gift_record',
      'CREATE INDEX IF NOT EXISTS idx_gift_record_book_occurred ON gift_record(book_id, occurred_at);',
    );
    await createIndexIfTableExists(
      'gift_record',
      'CREATE INDEX IF NOT EXISTS idx_gift_record_book_person ON gift_record(book_id, person_id);',
    );
    await createIndexIfTableExists(
      'reason',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_reason_normalized_name ON reason(normalized_name);',
    );
    await createIndexIfTableExists(
      'reason',
      'CREATE INDEX IF NOT EXISTS idx_reason_updated_at ON reason(updated_at DESC);',
    );
    await createIndexIfTableExists(
      'relation_type',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_relation_type_normalized_name ON relation_type(normalized_name);',
    );
    await createIndexIfTableExists(
      'relation_type',
      'CREATE INDEX IF NOT EXISTS idx_relation_type_updated_at ON relation_type(updated_at DESC);',
    );
    await createIndexIfTableExists(
      'data_import_job',
      'CREATE INDEX IF NOT EXISTS idx_import_job_book_started ON data_import_job(book_id, started_at);',
    );
    await createIndexIfTableExists(
      'data_import_job',
      'CREATE INDEX IF NOT EXISTS idx_import_job_status_updated ON data_import_job(status, updated_at);',
    );
    await createIndexIfTableExists(
      'entity_remark',
      'CREATE INDEX IF NOT EXISTS idx_entity_remark_entity_time ON entity_remark(entity_type, entity_id, created_at DESC);',
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await AppPlatform.documentsDirectory();
    await RestoreSafety.recoverIfNeeded(dir);
    final File file = File(p.join(dir.path, 'newshangli_drift.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
