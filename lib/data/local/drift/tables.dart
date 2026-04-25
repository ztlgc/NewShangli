import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'converters.dart';

/// 账簿表：account_book
///
/// 关键规范：
/// - 账簿是一级上下文：其它核心数据必须归属 book_id
/// - 主键使用 TEXT（UUID）
class AccountBooks extends Table {
  @override
  String get tableName => 'account_book';

  TextColumn get bookId =>
      text().named('book_id').clientDefault(() => const Uuid().v4())();

  TextColumn get name => text()
      .withLength(min: 1, max: 64)
      .customConstraint('NOT NULL CHECK(length(name) BETWEEN 1 AND 32)')();

  TextColumn get reasonType =>
      text().named('reason_type').withDefault(const Constant(''))();

  TextColumn get themeColor =>
      text().named('theme_color').withDefault(const Constant('#312E81'))();

  TextColumn get icon => text().nullable()();

  TextColumn get description => text().nullable()();

  IntColumn get bookTime => integer()
      .named('book_time')
      .clientDefault(() => DateTime.now().millisecondsSinceEpoch)
      .customConstraint('NOT NULL')();

  IntColumn get isDefault => integer()
      .named('is_default')
      .customConstraint('NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1))')();

  IntColumn get createdAt =>
      integer().named('created_at').customConstraint('NOT NULL')();

  IntColumn get updatedAt =>
      integer().named('updated_at').customConstraint('NOT NULL')();

  IntColumn get deletedAt => integer().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {bookId};
}

/// 关系人表：person
class Persons extends Table {
  @override
  String get tableName => 'person';

  TextColumn get personId =>
      text().named('person_id').clientDefault(() => const Uuid().v4())();

  TextColumn get bookId => text()
      .named('book_id')
      .customConstraint(
        'NOT NULL REFERENCES account_book(book_id) ON DELETE CASCADE',
      )();

  TextColumn get name => text()
      .withLength(min: 1, max: 64)
      .customConstraint('NOT NULL CHECK(length(name) BETWEEN 1 AND 32)')();

  TextColumn get relationshipType =>
      text().named('relationship_type').withDefault(const Constant('其他'))();

  TextColumn get phone => text().nullable()();

  TextColumn get birthday => text().nullable()();

  TextColumn get anniversary => text().nullable()();

  TextColumn get avatarUri => text().named('avatar_uri').nullable()();

  TextColumn get note => text().nullable()();

  IntColumn get createdAt =>
      integer().named('created_at').customConstraint('NOT NULL')();

  IntColumn get updatedAt =>
      integer().named('updated_at').customConstraint('NOT NULL')();

  IntColumn get deletedAt => integer().named('deleted_at').nullable()();

  List<Index> get indexes => [
    Index(
      'idx_person_book_name',
      'CREATE INDEX idx_person_book_name ON person(book_id, name)',
    ),
  ];

  @override
  Set<Column> get primaryKey => {personId};
}

/// 礼金记录表：gift_record
class GiftRecords extends Table {
  @override
  String get tableName => 'gift_record';

  TextColumn get recordId =>
      text().named('record_id').clientDefault(() => const Uuid().v4())();

  TextColumn get bookId => text()
      .named('book_id')
      .customConstraint(
        'NOT NULL REFERENCES account_book(book_id) ON DELETE CASCADE',
      )();

  TextColumn get personId => text()
      .named('person_id')
      .customConstraint(
        'NOT NULL REFERENCES person(person_id) ON DELETE CASCADE',
      )();

  TextColumn get direction => text().customConstraint(
    "NOT NULL DEFAULT '收入' CHECK(direction IN ('收入', '支出'))",
  )();

  IntColumn get amountCent => integer()
      .named('amount_cent')
      .customConstraint('NOT NULL CHECK(amount_cent > 0)')();

  TextColumn get currency => text().withDefault(const Constant('CNY'))();

  TextColumn get eventName => text().named('event_name').nullable()();

  IntColumn get occurredAt =>
      integer().named('occurred_at').customConstraint('NOT NULL')();

  TextColumn get paymentMethod => text().named('payment_method').nullable()();

  TextColumn get note => text().nullable()();

  TextColumn get attachments =>
      text().nullable().map(const JsonStringListConverter())();

  IntColumn get createdAt =>
      integer().named('created_at').customConstraint('NOT NULL')();

  IntColumn get updatedAt =>
      integer().named('updated_at').customConstraint('NOT NULL')();

  IntColumn get deletedAt => integer().named('deleted_at').nullable()();

  List<Index> get indexes => [
    Index(
      'idx_gift_record_book_occurred',
      'CREATE INDEX idx_gift_record_book_occurred ON gift_record(book_id, occurred_at)',
    ),
    Index(
      'idx_gift_record_book_person',
      'CREATE INDEX idx_gift_record_book_person ON gift_record(book_id, person_id)',
    ),
  ];

  @override
  Set<Column> get primaryKey => {recordId};
}

class Reasons extends Table {
  @override
  String get tableName => 'reason';

  TextColumn get reasonId => text().named('reason_id')();

  TextColumn get name => text().named('name').withLength(min: 1, max: 64)();

  TextColumn get description => text().named('description').nullable()();

  BoolColumn get enabled =>
      boolean().named('enabled').withDefault(const Constant(true))();

  IntColumn get createdAt =>
      integer().named('created_at').customConstraint('NOT NULL')();

  IntColumn get updatedAt =>
      integer().named('updated_at').customConstraint('NOT NULL')();

  List<Index> get indexes => [
    Index(
      'idx_reason_name',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_reason_name ON reason(name COLLATE NOCASE)',
    ),
    Index(
      'idx_reason_updated_at',
      'CREATE INDEX IF NOT EXISTS idx_reason_updated_at ON reason(updated_at DESC)',
    ),
  ];

  @override
  Set<Column> get primaryKey => {reasonId};
}

class RelationTypes extends Table {
  @override
  String get tableName => 'relation_type';

  TextColumn get typeId => text().named('type_id')();

  TextColumn get name => text().named('name').withLength(min: 1, max: 64)();

  IntColumn get createdAt =>
      integer().named('created_at').customConstraint('NOT NULL')();

  IntColumn get updatedAt =>
      integer().named('updated_at').customConstraint('NOT NULL')();

  List<Index> get indexes => [
    Index(
      'idx_relation_type_name',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_relation_type_name ON relation_type(name COLLATE NOCASE)',
    ),
    Index(
      'idx_relation_type_updated_at',
      'CREATE INDEX IF NOT EXISTS idx_relation_type_updated_at ON relation_type(updated_at DESC)',
    ),
  ];

  @override
  Set<Column> get primaryKey => {typeId};
}

class ContactRelations extends Table {
  @override
  String get tableName => 'contact_relation';

  TextColumn get relationId => text().named('relation_id')();

  TextColumn get personAId => text()
      .named('person_a_id')
      .customConstraint(
        'NOT NULL REFERENCES person(person_id) ON DELETE CASCADE',
      )();

  TextColumn get personBId => text()
      .named('person_b_id')
      .customConstraint(
        'NOT NULL REFERENCES person(person_id) ON DELETE CASCADE',
      )();

  TextColumn get typeId => text()
      .named('type_id')
      .customConstraint(
        'NOT NULL REFERENCES relation_type(type_id) ON DELETE RESTRICT',
      )();

  TextColumn get note => text().named('note').nullable()();

  IntColumn get createdAt =>
      integer().named('created_at').customConstraint('NOT NULL')();

  IntColumn get updatedAt =>
      integer().named('updated_at').customConstraint('NOT NULL')();

  List<Index> get indexes => [
    Index(
      'idx_contact_relation_pair_type',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_contact_relation_pair_type ON contact_relation(person_a_id, person_b_id, type_id)',
    ),
    Index(
      'idx_contact_relation_updated_at',
      'CREATE INDEX IF NOT EXISTS idx_contact_relation_updated_at ON contact_relation(updated_at DESC)',
    ),
  ];

  @override
  Set<Column> get primaryKey => {relationId};
}

class DataImportJobs extends Table {
  @override
  String get tableName => 'data_import_job';

  TextColumn get jobId =>
      text().named('job_id').clientDefault(() => const Uuid().v4())();

  TextColumn get bookId => text()
      .named('book_id')
      .customConstraint(
        'NOT NULL REFERENCES account_book(book_id) ON DELETE CASCADE',
      )();

  TextColumn get filePath => text().named('file_path')();
  TextColumn get fileName => text().named('file_name')();
  TextColumn get fileHash => text().named('file_hash')();
  IntColumn get fileSize => integer().named('file_size')();
  TextColumn get format => text().named('format')();

  TextColumn get status => text().named('status')();
  TextColumn get importKind => text().named('import_kind')();

  TextColumn get mappingJson => text().named('mapping_json').nullable()();

  IntColumn get totalRows => integer().named('total_rows').nullable()();
  IntColumn get processedRows =>
      integer().named('processed_rows').withDefault(const Constant(0))();
  IntColumn get successRows =>
      integer().named('success_rows').withDefault(const Constant(0))();
  IntColumn get skippedRows =>
      integer().named('skipped_rows').withDefault(const Constant(0))();
  IntColumn get failedRows =>
      integer().named('failed_rows').withDefault(const Constant(0))();

  IntColumn get byteOffset =>
      integer().named('byte_offset').withDefault(const Constant(0))();
  IntColumn get lastRowIndex =>
      integer().named('last_row_index').withDefault(const Constant(0))();

  TextColumn get errorLogPath => text().named('error_log_path').nullable()();

  IntColumn get startedAt =>
      integer().named('started_at').customConstraint('NOT NULL')();
  IntColumn get finishedAt => integer().named('finished_at').nullable()();
  IntColumn get updatedAt =>
      integer().named('updated_at').customConstraint('NOT NULL')();

  @override
  Set<Column> get primaryKey => {jobId};
}
