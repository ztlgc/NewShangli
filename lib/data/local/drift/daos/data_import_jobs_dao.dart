part of '../app_database.dart';

@DriftAccessor(tables: [DataImportJobs])
class DataImportJobsDao extends DatabaseAccessor<AppDatabase>
    with _$DataImportJobsDaoMixin {
  DataImportJobsDao(super.db);

  Stream<List<DataImportJob>> watchRecentInBook(String bookId, {int limit = 50}) {
    return (select(dataImportJobs)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .watch();
  }

  Future<DataImportJob?> findById(String jobId) {
    return (select(dataImportJobs)..where((t) => t.jobId.equals(jobId)))
        .getSingleOrNull();
  }

  Future<String> insertOne(DataImportJobsCompanion companion) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final DataImportJobsCompanion withDefaults = companion.copyWith(
      jobId: companion.jobId.present ? companion.jobId : Value(db.newId()),
      startedAt: companion.startedAt.present ? companion.startedAt : Value(now),
      updatedAt: companion.updatedAt.present ? companion.updatedAt : Value(now),
    );
    await into(dataImportJobs).insert(withDefaults);
    return withDefaults.jobId.value;
  }

  Future<bool> updateOne(DataImportJob job) {
    final DataImportJob updated = job.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return update(dataImportJobs).replace(updated);
  }
}

