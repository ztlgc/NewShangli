// Independent 1.2.4 audit: intentionally does not import any other test.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/backup/backup_config.dart';
import 'package:newshangli/backup/data_backup_service.dart';
import 'package:newshangli/backup/data_restore_service.dart';
import 'package:newshangli/backup/restore_safety.dart';
import 'package:newshangli/backup/webdav_client.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

const _dbName = 'newshangli_drift.sqlite';
const _dbEntry = 'db/newshangli_drift.snapshot.sqlite';
const _tables = <String>[
  'account_book',
  'contact_relation',
  'data_import_job',
  'entity_remark',
  'gift_record',
  'person',
  'reason',
  'relation_type',
];
typedef _Snapshot = Map<String, List<Map<String, Object?>>>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The binding installs a mock returning HTTP 400 even for plain tests.
  // Remove that global override so all WebDAV tests use real loopback sockets.
  HttpOverrides.global = null;
  if (Platform.isWindows) {
    final dll =
        Platform.environment['BACKUP_AUDIT_SQLITE_DLL'] ??
        p.join(
          Directory.current.path,
          'build',
          'navigation_probe',
          'build',
          'windows',
          'x64',
          'runner',
          'Release',
          'sqlite3.dll',
        );
    if (File(dll).existsSync()) {
      open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open(dll));
    }
  }

  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('liji_backup_audit_20261104_');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<Directory> fixture(
    String name, {
    bool media = true,
    bool mediaReferences = true,
  }) => _fixture(
    Directory(p.join(root.path, name)),
    media: media,
    mediaReferences: mediaReferences,
  );
  DataBackupService backup(Directory docs) =>
      DataBackupService(documentsDirectoryProvider: () async => docs);
  DataRestoreService restore(Directory docs) =>
      DataRestoreService(documentsDirectoryProvider: () async => docs);
  Future<File> zip(Directory docs, {bool media = true}) =>
      backup(docs).buildLocalBackupZip(onProgress: (_) {}, includeMedia: media);
  Future<void> apply(Directory docs, File file) =>
      restore(docs).restoreFromLocalZip(zipFile: file, onProgress: (_) {});

  group('local snapshot and exact data fidelity', () {
    test(
      'manifest, every table, WAL snapshot, media SHA256 and cleanup',
      () async {
        final docs = await fixture('source');
        final db = sql.sqlite3.open(_database(docs).path);
        addTearDown(db.dispose);
        db.execute('PRAGMA journal_mode=WAL');
        db.execute('PRAGMA wal_autocheckpoint=0');
        db.execute(
          "UPDATE person SET note='committed WAL only; 特殊备注\\n' WHERE person_id='p1'",
        );
        final before = _snapshot(docs);
        expect(
          File('${_database(docs).path}-wal').lengthSync(),
          greaterThan(0),
        );
        final file = await zip(docs);
        final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
        final manifest = _manifest(archive);
        final bytes = archive.findFile(_dbEntry)!.content as List<int>;
        expect(manifest['formatVersion'], 1);
        expect(manifest['schemaVersion'], 15);
        expect(manifest['backupMode'], 'snapshot_vacuum_into');
        expect(manifest['dbFile'], _dbEntry);
        expect(manifest['dbSizeBytes'], bytes.length);
        expect(manifest['dbSha256'], sha256.convert(bytes).toString());
        expect(manifest['mediaIncluded'], isTrue);
        final hashes = await _mediaHashes(docs);
        expect(manifest['mediaFilesCount'], hashes.length);
        expect(manifest['mediaBytes'], await _mediaBytes(docs));
        expect((manifest['files'] as List).toSet(), {_dbEntry, ...hashes.keys});
        for (final entry in hashes.entries) {
          expect(
            sha256
                .convert(archive.findFile(entry.key)!.content as List<int>)
                .toString(),
            entry.value,
          );
        }
        final unpacked = File(p.join(root.path, 'snapshot.sqlite'));
        await unpacked.writeAsBytes(bytes);
        expect(_snapshotFile(unpacked), before);
        expect(
          _snapshot(docs),
          before,
          reason: 'backup must not mutate any table',
        );
        expect(
          archive.files.any(
            (e) => e.name.endsWith('-wal') || e.name.endsWith('-shm'),
          ),
          isFalse,
        );
        expect(
          await Directory(p.join(docs.path, 'backups', 'snapshots'))
              .list()
              .toList(),
          isEmpty,
        );
      },
    );

    test(
      'same-directory restore preserves all columns, recycle bin and remarks',
      () async {
        final docs = await fixture('source');
        final before = _snapshot(docs);
        final hashes = await _mediaHashes(docs);
        final file = await zip(docs);
        _edit(
          docs,
          "UPDATE entity_remark SET content='overwritten'; UPDATE gift_record SET note='mutated'",
        );
        await File(p.join(docs.path, 'media', 'extra.bin')).writeAsBytes([88]);
        await apply(docs, file);
        expect(_snapshot(docs), _expectedRestore(before, docs));
        expect(await _mediaHashes(docs), hashes);
        expect(await RestoreSafety.journal(docs).exists(), isFalse);
        expect(_snapshot(docs)['entity_remark']!.length, 6);
        expect(
          _snapshot(
            docs,
          )['gift_record']!.where((r) => r['deleted_at'] != null).length,
          2,
        );
      },
    );

    test('cross-directory rebase preserves every nonpath field and exact media bytes', () async {
      final source = await fixture('old device');
      final target = await fixture('new device');
      final before = _snapshot(source);
      final file = await zip(source);
      await apply(target, file);
      expect(_snapshot(target), _expectedRestore(before, target));
      expect(await _mediaHashes(target), await _mediaHashes(source));
      expect(_snapshot(source), before);
    });

    test(
      'database-only boundary clears media fields and replaces old media tree',
      () async {
        final source = await fixture('source');
        final target = await fixture('target');
        final before = _snapshot(source);
        final file = await zip(source, media: false);
        final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
        expect(_manifest(archive)['mediaIncluded'], isFalse);
        expect(_manifest(archive)['mediaFilesCount'], 0);
        expect(
          archive.files.where((f) => f.name.startsWith('media/')),
          isEmpty,
        );
        await apply(target, file);
        expect(
          _snapshot(target),
          _expectedRestore(before, target, includeMedia: false),
        );
        expect(await _mediaHashes(target), isEmpty);
      },
    );

    test(
      'no media directory and null references restores all tables exactly',
      () async {
        final source = await fixture('source', media: false);
        final target = Directory(p.join(root.path, 'empty target'));
        await target.create();
        final file = await zip(source);
        await apply(target, file);
        expect(_snapshot(target), _snapshot(source));
        expect(await _mediaHashes(target), isEmpty);
      },
    );

    test('active import jobs cancel, all other job columns and tables remain exact', () async {
      final source = await fixture('source');
      for (final status in ['running', 'pending', 'paused', 'failed']) {
        _edit(
          source,
          "INSERT INTO data_import_job SELECT 'job-$status',book_id,file_path,file_name,file_hash,file_size,format,'$status',import_kind,mapping_json,total_rows,processed_rows,success_rows,skipped_rows,failed_rows,byte_offset,last_row_index,error_log_path,started_at,finished_at,updated_at FROM data_import_job WHERE job_id='job-completed'",
        );
      }
      final target = await fixture('target');
      final before = _snapshot(source);
      await apply(target, await zip(source));
      expect(_snapshot(target), _expectedRestore(before, target));
      expect(_snapshot(source), before);
    });

    test(
      'preferred export directory, writable probe and invalid output path',
      () async {
        final docs = await fixture('source');
        final out = Directory(p.join(root.path, 'custom output'));
        final info = await backup(docs)
            .inspectLocalBackupDirectory(preferredOutputDir: out.path);
        expect(info.writable, isTrue);
        expect(info.usingDefault, isFalse);
        final file = await backup(docs).exportLocalBackupZip(
          onProgress: (_) {},
          preferredOutputDir: out.path,
        );
        expect(p.dirname(file.path), out.path);
        expect(
          ZipDecoder().decodeBytes(await file.readAsBytes()).findFile(_dbEntry),
          isNotNull,
        );
        expect(
          (await out.list().toList()).length,
          1,
          reason: 'write probe must be deleted',
        );
        final blocker = File(p.join(root.path, 'blocked'));
        await blocker.writeAsString('not a directory');
        await expectLater(
          backup(docs).exportLocalBackupZip(
            onProgress: (_) {},
            preferredOutputDir: blocker.path,
          ),
          throwsA(isA<BackupException>()),
        );
      },
    );

    test('missing source database fails without creating a database', () async {
      final docs = Directory(p.join(root.path, 'missing'));
      await docs.create();
      await expectLater(zip(docs), throwsA(isA<BackupException>()));
      expect(await _database(docs).exists(), isFalse);
    });

    test(
      'failed snapshot executor removes partial snapshot and preserves source',
      () async {
        final docs = await fixture('source');
        final before = _snapshot(docs);
        final svc = DataBackupService(
          documentsDirectoryProvider: () async => docs,
          snapshotExecutor:
              ({required sourceDbPath, required outputDbPath}) async {
                await File(outputDbPath).writeAsBytes([1, 2, 3]);
                throw StateError('independent injected snapshot failure');
              },
        );
        await expectLater(
          svc.buildLocalBackupZip(onProgress: (_) {}),
          throwsA(isA<BackupException>()),
        );
        expect(_snapshot(docs), before);
        expect(
          await Directory(p.join(docs.path, 'backups', 'snapshots'))
              .list()
              .toList(),
          isEmpty,
        );
      },
    );

    test('empty snapshot executor result is rejected', () async {
      final docs = await fixture('source');
      final svc = DataBackupService(
        documentsDirectoryProvider: () async => docs,
        snapshotExecutor:
            ({required sourceDbPath, required outputDbPath}) async {
              await File(outputDbPath).writeAsBytes([]);
            },
      );
      await expectLater(
        svc.buildLocalBackupZip(onProgress: (_) {}),
        throwsA(isA<BackupException>()),
      );
    });
  });

  group('producer and consumer limits', () {
    test('DEFECT: backup must reject media beyond its own restore expansion limit', () async {
      final source = await fixture('source');
      final target = await fixture('target');
      final before = _snapshot(target);
      final hashes = await _mediaHashes(target);
      final oversized = File(
        p.join(source.path, 'media', 'oversized-zero.bin'),
      );
      final handle = await oversized.open(mode: FileMode.write);
      try {
        // Extending a temporary file yields zeros without allocating a giant
        // random input buffer in the test. The product performs real encoding.
        await handle.truncate(RestoreSafety.maxExpandedBytes + 1);
      } finally {
        await handle.close();
      }
      Object? backupFailure;
      File? produced;
      try {
        produced = await zip(source);
      } catch (e) {
        backupFailure = e;
      }
      if (produced != null) {
        stdout.writeln(
          'AUDIT oversized media=${await oversized.length()} zip=${await produced.length()} expandedLimit=${RestoreSafety.maxExpandedBytes}',
        );
        expect(
          await produced.length(),
          lessThan(RestoreSafety.maxZipBytes),
          reason: 'highly compressible payload isolates expanded-size mismatch',
        );
        await expectLater(
          apply(target, produced),
          throwsA(isA<DataRestoreException>()),
        );
        expect(_snapshot(target), before);
        expect(await _mediaHashes(target), hashes);
      }
      expect(
        backupFailure,
        isA<BackupException>(),
        reason: 'backup currently emits a successful ZIP which its own restore rejects at expanded-size guard',
      );
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('fixed backup limit regressions', () {
    test('expanded-size preflight includes exact manifest and cleans snapshot without reading oversized media', () async {
      final source = await fixture('source', media: false);
      final before = _snapshot(source);
      final dbSize = await _database(source).length();
      final media = File(p.join(source.path, 'media', 'manifest-boundary.bin'));
      await media.parent.create(recursive: true);
      final handle = await media.open(mode: FileMode.write);
      try {
        await handle.truncate(RestoreSafety.maxExpandedBytes - dbSize);
      } finally {
        await handle.close();
      }
      final service = DataBackupService(
        documentsDirectoryProvider: () async => source,
        snapshotExecutor:
            ({required sourceDbPath, required outputDbPath}) async {
              await File(sourceDbPath).copy(outputDbPath);
            },
      );
      await expectLater(
        service.buildLocalBackupZip(onProgress: (_) {}),
        throwsA(isA<BackupException>()),
      );
      expect(_snapshot(source), before);
      expect(
        await Directory(p.join(source.path, 'backups', 'snapshots'))
            .list()
            .toList(),
        isEmpty,
      );
      final files = await Directory(p.join(source.path, 'backups'))
          .list(recursive: true)
          .toList();
      expect(
        files.whereType<File>(),
        isEmpty,
        reason: 'no snapshot or partially written ZIP may remain',
      );
    });
  });

  group('producer edge regressions', () {
    test('includeMedia=false does not fail because an oversized media directory exists', () async {
      final source = await fixture('source', media: false);
      final media = File(p.join(source.path, 'media', 'ignored-zero.bin'));
      await media.parent.create(recursive: true);
      final handle = await media.open(mode: FileMode.write);
      try {
        await handle.truncate(RestoreSafety.maxExpandedBytes + 1);
      } finally {
        await handle.close();
      }
      final file = await zip(source, media: false);
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      expect(_manifest(archive)['mediaIncluded'], isFalse);
      expect(archive.files.any((e) => e.name.startsWith('media/')), isFalse);
      await media.delete();
    });

    test(
      'empty media ZIP is accepted and clears media fields and tree',
      () async {
        // Source has media files but no media references, so every local media
        // entry can be removed while the manifest still declares media support.
        final source = await fixture('source', mediaReferences: false);
        final target = await fixture('target');
        final hashes = await _mediaHashes(source);
        expect(hashes, isNotEmpty);
        final rewritten = await _rewrite(
          await zip(source),
          root,
          remove: hashes.keys.toSet(),
        );
        await apply(target, rewritten);
        expect(await _mediaHashes(target), isEmpty);
        expect(_snapshot(target), _expectedRestore(_snapshot(source), target));
      },
    );
  });

  group('import-history backup boundary', () {
    test('fresh target keeps old source/log/ZIP metadata, cancels unfinished job, omits nonmedia import files', () async {
      final source = await fixture('old device');
      final target = Directory(p.join(root.path, 'fresh device'));
      await target.create();
      final csv = File(p.join(source.path, 'imports', 'source.csv'));
      final mediaZip = File(p.join(source.path, 'imports', 'attachments.zip'));
      final log = File(p.join(source.path, 'import_logs', 'errors.log'));
      for (final file in [csv, mediaZip, log]) {
        await file.parent.create(recursive: true);
        await file.writeAsString('temporary audit source file');
      }
      final db = sql.sqlite3.open(_database(source).path);
      try {
        db.execute(
          'UPDATE data_import_job SET status=?,file_path=?,error_log_path=?,mapping_json=? WHERE job_id=?',
          [
            'paused',
            csv.path,
            log.path,
            jsonEncode({'__media_zip_path__': mediaZip.path, 'name': '联系人'}),
            'job-canceled',
          ],
        );
      } finally {
        db.dispose();
      }
      final before = _snapshot(source);
      final file = await zip(source);
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      expect(
        archive.files.where(
          (e) =>
              e.name.startsWith('imports/') ||
              e.name.startsWith('import_logs/'),
        ),
        isEmpty,
      );
      await apply(target, file);
      expect(_snapshot(target), _expectedRestore(before, target));
      final job = _snapshot(
        target,
      )['data_import_job']!.singleWhere((j) => j['job_id'] == 'job-canceled');
      expect(job['status'], 'canceled');
      expect(job['file_path'], csv.path);
      expect(job['error_log_path'], log.path);
      expect(
        (jsonDecode(job['mapping_json'] as String)
            as Map)['__media_zip_path__'],
        mediaZip.path,
      );
      await source.delete(recursive: true);
      expect(await File(job['file_path'] as String).exists(), isFalse);
      expect(await File(job['error_log_path'] as String).exists(), isFalse);
      expect(
        await File(
          (jsonDecode(job['mapping_json'] as String)
                  as Map)['__media_zip_path__']
              as String,
        ).exists(),
        isFalse,
      );
      expect(await Directory(p.join(target.path, 'imports')).exists(), isFalse);
    });
  });

  group('failure rollback and interruption protocol', () {
    for (final stage in ['正在恢复数据库…', '正在恢复媒体文件…']) {
      test(
        'callback failure at $stage restores exact original database and media',
        () async {
          final source = await fixture('source');
          final target = await fixture('target');
          _edit(
            target,
            "UPDATE entity_remark SET content='target original 特有'; UPDATE gift_record SET note='target only'",
          );
          await File(p.join(target.path, 'media', 'target-only.bin'))
              .writeAsBytes([91, 0, 7]);
          final before = _snapshot(target);
          final hashes = await _mediaHashes(target);
          final file = await zip(source);
          await expectLater(
            restore(target).restoreFromLocalZip(
              zipFile: file,
              onProgress: (m) {
                if (m == stage) throw StateError('injected callback failure');
              },
            ),
            throwsA(isA<DataRestoreException>()),
          );
          expect(_snapshot(target), before);
          expect(await _mediaHashes(target), hashes);
          expect(await RestoreSafety.journal(target).exists(), isFalse);
        },
      );
    }

    test('actual media file/directory collision rolls back database and partial media', () async {
      final source = await fixture('source');
      final target = await fixture('target');
      _edit(target, "UPDATE person SET note='rollback marker'");
      final before = _snapshot(target);
      final hashes = await _mediaHashes(target);
      final file = await _rewrite(
        await zip(source),
        root,
        add: {
          'media/collision': [4],
          'media/collision/child.bin': [5],
        },
      );
      await expectLater(
        apply(target, file),
        throwsA(isA<DataRestoreException>()),
      );
      expect(_snapshot(target), before);
      expect(await _mediaHashes(target), hashes);
      expect(await RestoreSafety.journal(target).exists(), isFalse);
    });

    test(
      'failed first restore returns to absent database and absent media',
      () async {
        final source = await fixture('source');
        final target = Directory(p.join(root.path, 'fresh target'));
        await target.create();
        final file = await zip(source);
        await expectLater(
          restore(target).restoreFromLocalZip(
            zipFile: file,
            onProgress: (m) {
              if (m == '正在恢复媒体文件…') {
                throw StateError('first restore interrupted');
              }
            },
          ),
          throwsA(isA<DataRestoreException>()),
        );
        expect(await _database(target).exists(), isFalse);
        expect(await Directory(p.join(target.path, 'media')).exists(), isFalse);
        expect(await RestoreSafety.journal(target).exists(), isFalse);
      },
    );

    test(
      'saved WAL and SHM are restored as exact bytes during rollback',
      () async {
        final source = await fixture('source');
        final target = await fixture('target');
        final before = _snapshot(target);
        // Deliberate sidecar sentinels: not opened by SQLite before rollback.
        final wal = File('${_database(target).path}-wal');
        final shm = File('${_database(target).path}-shm');
        await wal.writeAsBytes([11, 22, 33, 44]);
        await shm.writeAsBytes([55, 66, 77]);
        final file = await zip(source);
        await expectLater(
          restore(target).restoreFromLocalZip(
            zipFile: file,
            onProgress: (m) {
              if (m == '正在恢复媒体文件…') throw StateError('sidecar rollback');
            },
          ),
          throwsA(isA<DataRestoreException>()),
        );
        expect(await wal.readAsBytes(), [11, 22, 33, 44]);
        expect(await shm.readAsBytes(), [55, 66, 77]);
        await wal.delete();
        await shm.delete();
        expect(_snapshot(target), before);
      },
    );

    test('startup recovery after simulated interrupted replacement is exact and idempotent', () async {
      final docs = await fixture('target');
      final before = _snapshot(docs);
      final hashes = await _mediaHashes(docs);
      final guard = await _guard(docs);
      await RestoreSafety.begin(docs, guard);
      _edit(docs, "UPDATE entity_remark SET content='partial replacement'");
      await Directory(p.join(docs.path, 'media')).delete(recursive: true);
      await File(p.join(docs.path, 'media', 'partial.bin'))
          .create(recursive: true);
      await RestoreSafety.recoverIfNeeded(docs);
      expect(_snapshot(docs), before);
      expect(await _mediaHashes(docs), hashes);
      expect(await RestoreSafety.journal(docs).exists(), isFalse);
      await RestoreSafety.recoverIfNeeded(docs);
      expect(_snapshot(docs), before);
      expect(await _mediaHashes(docs), hashes);
    });

    test('restore entry point recovers pending replacement before rejecting damaged new ZIP', () async {
      final docs = await fixture('target');
      final before = _snapshot(docs);
      final hashes = await _mediaHashes(docs);
      await RestoreSafety.begin(docs, await _guard(docs));
      _edit(docs, "UPDATE person SET note='interrupted state'");
      final bad = File(p.join(root.path, 'bad.zip'));
      await bad.writeAsBytes([0, 1, 2]);
      await expectLater(apply(docs, bad), throwsA(anything));
      expect(_snapshot(docs), before);
      expect(await _mediaHashes(docs), hashes);
      expect(await RestoreSafety.journal(docs).exists(), isFalse);
    });

    test(
      'recovery without original database deletes partial database and media',
      () async {
        final docs = Directory(p.join(root.path, 'fresh'));
        final guard = Directory(
          p.join(docs.path, 'backups', 'restore_guard', 'first'),
        );
        await guard.create(recursive: true);
        await RestoreSafety.begin(docs, guard);
        await _database(docs).writeAsBytes([1, 2]);
        await File(p.join(docs.path, 'media', 'partial'))
            .create(recursive: true);
        await RestoreSafety.recoverIfNeeded(docs);
        expect(await _database(docs).exists(), isFalse);
        expect(await Directory(p.join(docs.path, 'media')).exists(), isFalse);
      },
    );

    test('unsafe journal guard path rejected without touching live database or media', () async {
      final docs = await fixture('target');
      final before = _snapshot(docs);
      final hashes = await _mediaHashes(docs);
      await RestoreSafety.journal(docs).parent.create(recursive: true);
      await RestoreSafety.journal(docs).writeAsString(
        jsonEncode({'guard': '../outside', 'hadDb': true, 'hadMedia': true}),
      );
      await expectLater(
        RestoreSafety.recoverIfNeeded(docs),
        throwsFormatException,
      );
      expect(_snapshot(docs), before);
      expect(await _mediaHashes(docs), hashes);
      expect(await RestoreSafety.journal(docs).exists(), isTrue);
    });

    test(
      'missing guard database rejected without changing live state',
      () async {
        final docs = await fixture('target');
        final before = _snapshot(docs);
        final hashes = await _mediaHashes(docs);
        final guard = await _guard(docs);
        await RestoreSafety.begin(docs, guard);
        await File(p.join(guard.path, _dbName)).delete();
        await expectLater(
          RestoreSafety.recoverIfNeeded(docs),
          throwsFormatException,
        );
        expect(_snapshot(docs), before);
        expect(await _mediaHashes(docs), hashes);
      },
    );
  });

  group('recovery protection validation', () {
    test('DEFECT: missing saved media must be detected before replacing any live database', () async {
      final docs = await fixture('target');
      final guard = await _guard(docs);
      await RestoreSafety.begin(docs, guard);
      _edit(
        docs,
        "UPDATE entity_remark SET content='current live state after interruption'",
      );
      final beforeRecovery = _snapshot(docs);
      final hashes = await _mediaHashes(docs);
      await Directory(p.join(guard.path, 'media')).delete(recursive: true);
      await expectLater(
        RestoreSafety.recoverIfNeeded(docs),
        throwsFormatException,
      );
      expect(await RestoreSafety.journal(docs).exists(), isTrue);
      expect(
        _snapshot(docs),
        beforeRecovery,
        reason: 'unrecoverable guard must be fully validated before rollback mutates live data',
      );
      expect(await _mediaHashes(docs), hashes);
    });
  });

  group('guard integrity regression', () {
    test('corrupted saved media is rejected before live changes and recovery succeeds after guard repair', () async {
      final docs = await fixture('target');
      final original = _snapshot(docs);
      final originalHashes = await _mediaHashes(docs);
      final guard = await _guard(docs);
      await RestoreSafety.begin(docs, guard);
      _edit(docs, "UPDATE entity_remark SET content='live interruption state'");
      final interrupted = _snapshot(docs);
      final saved = File(p.join(guard.path, 'media', 'avatar.bin'));
      final originalBytes = await saved.readAsBytes();
      final corrupted = List<int>.from(originalBytes);
      corrupted[5] ^= 0xff;
      await saved.writeAsBytes(corrupted, flush: true);
      await expectLater(
        RestoreSafety.recoverIfNeeded(docs),
        throwsFormatException,
      );
      expect(_snapshot(docs), interrupted);
      expect(await _mediaHashes(docs), originalHashes);
      expect(await RestoreSafety.journal(docs).exists(), isTrue);
      await saved.writeAsBytes(originalBytes, flush: true);
      await RestoreSafety.recoverIfNeeded(docs);
      expect(_snapshot(docs), original);
      expect(await _mediaHashes(docs), originalHashes);
      expect(await RestoreSafety.journal(docs).exists(), isFalse);
    });
  });

  group('damaged archive and current-schema invalid data', () {
    final corruptions = <String, Future<File> Function(File, Directory)>{
      'not ZIP': (_, r) async =>
          File(p.join(r.path, 'not.zip')).writeAsBytes([1, 2, 3, 4]),
      'missing manifest': (f, r) => _rewrite(f, r, remove: {'manifest.json'}),
      'manifest is array': (f, r) =>
          _rewrite(f, r, add: {'manifest.json': utf8.encode('[]')}),
      'invalid manifest JSON': (f, r) =>
          _rewrite(f, r, add: {'manifest.json': utf8.encode('{')}),
      'missing database': (f, r) => _rewrite(f, r, remove: {_dbEntry}),
      'database checksum mismatch': (f, r) =>
          _rewrite(f, r, manifestEdit: (m) => m['dbSha256'] = '0' * 64),
      'wrong format version': (f, r) =>
          _rewrite(f, r, manifestEdit: (m) => m['formatVersion'] = 900),
      'wrong current schema marker': (f, r) =>
          _rewrite(f, r, manifestEdit: (m) => m['schemaVersion'] = 900),
      'traversal path': (f, r) => _rewrite(
        f,
        r,
        add: {
          '../escaped.bin': [1],
        },
      ),
      'absolute path': (f, r) => _rewrite(
        f,
        r,
        add: {
          '/escaped.bin': [1],
        },
      ),
      'drive-qualified path': (f, r) => _rewrite(
        f,
        r,
        add: {
          'C:/escaped.bin': [1],
        },
      ),
      'backslash traversal': (f, r) => _rewrite(
        f,
        r,
        add: {
          r'media\..\escaped.bin': [1],
        },
      ),
      'case-insensitive duplicate path': (f, r) => _rewrite(
        f,
        r,
        add: {
          'MEDIA/avatar.bin': [1],
        },
      ),
      'missing referenced local media': (f, r) =>
          _rewrite(f, r, remove: {'media/avatar.bin'}),
      'SQLite payload is junk with correct SHA256': (f, r) =>
          _rewriteDb(f, r, bytes: [1, 2, 3, 4]),
      'SQLite user_version wrong with correct SHA256': (f, r) =>
          _rewriteDb(f, r, sqlText: 'PRAGMA user_version=900'),
      'missing required table': (f, r) =>
          _rewriteDb(f, r, sqlText: 'DROP TABLE entity_remark'),
      'missing required column': (f, r) => _rewriteDb(
        f,
        r,
        sqlText: 'ALTER TABLE entity_remark DROP COLUMN content',
      ),
      'foreign key orphan': (f, r) => _rewriteDb(
        f,
        r,
        sqlText: "PRAGMA foreign_keys=OFF; UPDATE gift_record SET person_id='missing' WHERE record_id='g1'",
      ),
      'invalid integer amount': (f, r) => _rewriteDb(
        f,
        r,
        sqlText: "PRAGMA ignore_check_constraints=ON; UPDATE gift_record SET amount_cent=0 WHERE record_id='g1'",
      ),
      'invalid direction': (f, r) => _rewriteDb(
        f,
        r,
        sqlText: "PRAGMA ignore_check_constraints=ON; UPDATE gift_record SET direction='invalid' WHERE record_id='g1'",
      ),
      'invalid attachment JSON': (f, r) => _rewriteDb(
        f,
        r,
        sqlText: "UPDATE gift_record SET attachments='{' WHERE record_id='g1'",
      ),
      'attachment JSON is object': (f, r) => _rewriteDb(
        f,
        r,
        sqlText: "UPDATE account_book SET attachments='{}' WHERE book_id='b1'",
      ),
      'attachment item is non-string': (f, r) => _rewriteDb(
        f,
        r,
        sqlText:
            "UPDATE gift_record SET attachments='[42]' WHERE record_id='g1'",
      ),
      'local media traversal reference': (f, r) => _rewriteDb(
        f,
        r,
        sqlText: "UPDATE person SET avatar_uri='media/../outside.bin' WHERE person_id='p1'",
      ),
    };
    for (final entry in corruptions.entries) {
      test(
        '${entry.key} rejects and keeps every original row/media hash',
        () async {
          final source = await fixture('source');
          final target = await fixture('target');
          _edit(
            target,
            "UPDATE entity_remark SET content='target guard assertion'",
          );
          final before = _snapshot(target);
          final hashes = await _mediaHashes(target);
          final malformed = await entry.value(await zip(source), root);
          Object? failure;
          try {
            await apply(target, malformed);
          } catch (e) {
            failure = e;
          }
          expect(failure, isNotNull, reason: 'invalid package must reject');
          expect(_snapshot(target), before);
          expect(await _mediaHashes(target), hashes);
          expect(await RestoreSafety.journal(target).exists(), isFalse);
        },
      );
    }

    test('boundary: mismatched central-directory CRC is ignored when payload checks pass', () async {
      final source = await fixture('source');
      final target = await fixture('target');
      final before = _snapshot(source);
      final hashes = await _mediaHashes(source);
      final bytes = await (await zip(source)).readAsBytes();
      // Mutate the central directory CRC, leaving compressed bytes intact.
      final mutated = List<int>.from(bytes);
      var offset = -1;
      for (var i = 0; i < mutated.length - 46; i++) {
        if (mutated[i] == 0x50 &&
            mutated[i + 1] == 0x4b &&
            mutated[i + 2] == 1 &&
            mutated[i + 3] == 2) {
          offset = i;
          break;
        }
      }
      expect(offset, greaterThanOrEqualTo(0));
      mutated[offset + 16] ^= 0xff;
      final file = await File(p.join(root.path, 'crc-bad.zip'))
          .writeAsBytes(mutated);
      // Central CRC differs, but the local-header CRC and actual bytes are
      // intact. Record this limited ZIP validation boundary separately from
      // payload corruption, which must still reject.
      await apply(target, file);
      expect(_snapshot(target), _expectedRestore(before, target));
      expect(await _mediaHashes(target), hashes);
    });

    test(
      'real media payload single-byte corruption with original CRC rejects',
      () async {
        final source = await fixture('source');
        final target = await fixture('target');
        final before = _snapshot(target);
        final hashes = await _mediaHashes(target);
        final original = ZipDecoder().decodeBytes(
          await (await zip(source)).readAsBytes(),
        );
        final stored = Archive();
        for (final entry in original.files) {
          final bytes = entry.content as List<int>;
          stored.addFile(
            ArchiveFile(entry.name, bytes.length, bytes)..compress = false,
          );
        }
        final bytes = List<int>.from(ZipEncoder().encode(stored)!);
        int u16(int at) => bytes[at] | bytes[at + 1] << 8;
        int u32(int at) => u16(at) | u16(at + 2) << 16;
        var found = false;
        for (var at = 0; at < bytes.length - 30;) {
          if (u32(at) != 0x04034b50) break;
          final nameLength = u16(at + 26);
          final extraLength = u16(at + 28);
          final name = utf8.decode(
            bytes.sublist(at + 30, at + 30 + nameLength),
          );
          final dataOffset = at + 30 + nameLength + extraLength;
          if (name == 'media/avatar.bin') {
            expect(
              u16(at + 8),
              0,
              reason:
                  'media must be stored, so mutated byte is actual media data',
            );
            bytes[dataOffset + 12] ^= 0xff;
            found = true;
            break;
          }
          at = dataOffset + u32(at + 18);
        }
        expect(found, isTrue);
        final file = await File(p.join(root.path, 'media-payload-bitflip.zip'))
            .writeAsBytes(bytes);
        await expectLater(apply(target, file), throwsA(anything));
        expect(_snapshot(target), before);
        expect(await _mediaHashes(target), hashes);
        expect(await RestoreSafety.journal(target).exists(), isFalse);
      },
    );

    test('local-file-header CRC mismatch rejects before replacement', () async {
      final source = await fixture('source');
      final target = await fixture('target');
      final before = _snapshot(target);
      final hashes = await _mediaHashes(target);
      final bytes = List<int>.from(await (await zip(source)).readAsBytes());
      expect(bytes.take(4).toList(), [0x50, 0x4b, 3, 4]);
      bytes[14] ^= 0xff; // Local file header CRC32, not central directory.
      final file = await File(p.join(root.path, 'local-crc-bad.zip'))
          .writeAsBytes(bytes);
      await expectLater(apply(target, file), throwsA(anything));
      expect(_snapshot(target), before);
      expect(await _mediaHashes(target), hashes);
    });

    test('symlink and declared expansion/file-count limits reject', () async {
      final symlink = ArchiveFile('media/link', 0, <int>[])
        ..isFile = false
        ..isSymbolicLink = true;
      expect(
        () => RestoreSafety.validateArchive(Archive()..addFile(symlink)),
        throwsFormatException,
      );
      expect(
        () => RestoreSafety.validateArchive(
          Archive()..addFile(
            ArchiveFile(
              'media/huge',
              RestoreSafety.maxExpandedBytes + 1,
              <int>[],
            ),
          ),
        ),
        throwsFormatException,
      );
      final many = Archive();
      for (var i = 0; i <= 20000; i++) {
        many.addFile(ArchiveFile('media/$i', 0, <int>[]));
      }
      expect(() => RestoreSafety.validateArchive(many), throwsFormatException);
      final oversized = List<int>.filled(RestoreSafety.maxZipBytes + 1, 0);
      expect(() => RestoreSafety.decodeZip(oversized), throwsFormatException);
    });

    // These are deliberately strict regression assertions. Failing cases are
    // retained, not skipped or changed to assert the observed unsafe behavior.
    test('boundary: media integrity uses ZIP CRC, not authenticated media hashes', () async {
      final source = await fixture('source');
      final target = await fixture('target');
      final before = _snapshot(source);
      final expectedHashes = await _mediaHashes(source);
      final rewritten = await _rewrite(
        await zip(source),
        root,
        add: {
          'media/avatar.bin': [99, 98, 97],
        },
      );
      // A deliberately repackaged ZIP has valid CRCs. Neither DB SHA256 nor
      // ZIP CRC authenticates the original producer. This is a trust boundary,
      // not evidence that ordinary corrupted media bytes evade the CRC check.
      await apply(target, rewritten);
      expectedHashes['media/avatar.bin'] = sha256.convert([
        99,
        98,
        97,
      ]).toString();
      expect(_snapshot(target), _expectedRestore(before, target));
      expect(await _mediaHashes(target), expectedHashes);
    });

    test('DEFECT: current-schema marker cannot admit missing account-book constraints', () async {
      final source = await fixture('source');
      final target = await fixture('target');
      final before = _snapshot(target);
      final hashes = await _mediaHashes(target);
      final bad = await _rewriteDb(
        await zip(source),
        root,
        sqlText: '''
        PRAGMA foreign_keys=OFF;
        CREATE TABLE book_copy AS SELECT * FROM account_book;
        DROP TABLE account_book;
        ALTER TABLE book_copy RENAME TO account_book;
        CREATE UNIQUE INDEX audit_keep_fk_valid ON account_book(book_id);
        UPDATE account_book SET name='',is_default=7 WHERE book_id='b1';
      ''',
      );
      Object? failure;
      try {
        await apply(target, bad);
      } catch (e) {
        failure = e;
      }
      expect(
        failure,
        isNotNull,
        reason: 'same column names and user_version are insufficient to validate schema and invalid book data',
      );
      expect(_snapshot(target), before);
      expect(await _mediaHashes(target), hashes);
    });
  });

  group('current schema constraint regression', () {
    test('missing CHECK rejects even when all columns, defaults, types, keys and data remain valid', () async {
      final source = await fixture('source');
      final target = await fixture('target');
      final before = _snapshot(target);
      final hashes = await _mediaHashes(target);
      final altered = await _rewriteDb(
        await zip(source),
        root,
        sqlText: '''
        PRAGMA writable_schema=ON;
        UPDATE sqlite_master SET sql=replace(sql,'CHECK(is_default IN (0, 1))','') WHERE name='account_book';
        PRAGMA writable_schema=OFF;
      ''',
      );
      await expectLater(apply(target, altered), throwsFormatException);
      expect(_snapshot(target), before);
      expect(await _mediaHashes(target), hashes);
      expect(await RestoreSafety.journal(target).exists(), isFalse);
    });
  });

  group('WebDAV real loopback HTTP', () {
    test('backup upload and remote restore preserve full database and media SHA256', () async {
      final server = await _Dav.start();
      addTearDown(server.close);
      final source = await fixture('source');
      final target = await fixture('target');
      final before = _snapshot(source);
      final stages = <BackupStage>[];
      final result = await backup(source)
          .run(config: server.config, onProgress: (v) => stages.add(v.stage));
      final key = Uri.parse(result.remoteUrl).path;
      expect(server.files[key], await result.localFile.readAsBytes());
      expect(
        server.requests.map((r) => r.method),
        containsAllInOrder(['PROPFIND', 'MKCOL', 'MKCOL', 'PUT']),
      );
      expect(
        server.requests
            .where((r) => r.method == 'MKCOL')
            .map((r) => r.path)
            .toList(),
        ['/dav/audit', '/dav/audit/nested'],
      );
      expect(
        server.requests.every(
          (r) =>
              r.auth ==
              'Basic ${base64Encode(utf8.encode('audit-user:audit-pass'))}',
        ),
        isTrue,
      );
      expect(
        server.requests.every((r) => r.agent == 'newshangli-webdav'),
        isTrue,
      );
      expect(stages.last, BackupStage.done);
      final last = (await BackupStateStore.getLastBackup())!;
      expect(last.remoteUrl, result.remoteUrl);
      expect(last.sizeBytes, await result.localFile.length());
      expect(
        (await BackupStateStore.getHistory()).single.fileName,
        p.basename(result.localFile.path),
      );
      await restore(target).restoreFromRemote(
        config: server.config,
        entry: BackupHistoryEntry(
          type: BackupHistoryType.manual,
          at: DateTime(2026, 11, 4),
          fileName: p.basename(result.localFile.path),
          sizeBytes: await result.localFile.length(),
          remoteUrl: result.remoteUrl,
        ),
        onProgress: (_) {},
      );
      expect(_snapshot(target), _expectedRestore(before, target));
      expect(await _mediaHashes(target), await _mediaHashes(source));
      expect(server.requests.last.method, 'GET');
      expect(server.requests.last.path, key);
      expect(
        await Directory(p.join(target.path, 'backups', 'restore_tmp'))
            .list()
            .toList(),
        isEmpty,
      );
    });

    for (final status in [401, 403, 404, 405, 302, 500]) {
      test(
        'PROPFIND $status reports failure and does not upload or record success',
        () async {
          final server = await _Dav.start(statuses: {'PROPFIND': status});
          addTearDown(server.close);
          final source = await fixture('source');
          final before = _snapshot(source);
          await expectLater(
            backup(source).run(config: server.config, onProgress: (_) {}),
            throwsA(isA<BackupException>()),
          );
          expect(server.requests.map((r) => r.method).toList(), ['PROPFIND']);
          expect(await BackupStateStore.getLastBackup(), isNull);
          expect(await BackupStateStore.getHistory(), isEmpty);
          expect(_snapshot(source), before);
        },
      );
    }

    for (final failure in [
      {'MKCOL': 409},
      {'MKCOL': 403},
      {'PUT': 403},
      {'PUT': 500},
      {'PUT': 307},
    ]) {
      test(
        'HTTP ${failure.keys.single} ${failure.values.single} fails without success history',
        () async {
          final server = await _Dav.start(statuses: failure);
          addTearDown(server.close);
          final source = await fixture('source');
          final before = _snapshot(source);
          final hashes = await _mediaHashes(source);
          await expectLater(
            backup(source).run(config: server.config, onProgress: (_) {}),
            throwsA(isA<WebDavException>()),
          );
          expect(await BackupStateStore.getLastBackup(), isNull);
          expect(await BackupStateStore.getHistory(), isEmpty);
          expect(_snapshot(source), before);
          expect(await _mediaHashes(source), hashes);
        },
      );
    }

    for (final status in [401, 403, 404, 500]) {
      test(
        'GET $status preserves target tables/media and cleans download directory',
        () async {
          final server = await _Dav.start(statuses: {'GET': status});
          addTearDown(server.close);
          final target = await fixture('target');
          final before = _snapshot(target);
          final hashes = await _mediaHashes(target);
          await expectLater(
            restore(target).restoreFromRemote(
              config: server.config,
              entry: _entry('missing.zip'),
              onProgress: (_) {},
            ),
            throwsA(isA<WebDavException>()),
          );
          expect(_snapshot(target), before);
          expect(await _mediaHashes(target), hashes);
          expect(
            await Directory(p.join(target.path, 'backups', 'restore_tmp'))
                .list()
                .toList(),
            isEmpty,
          );
        },
      );
    }

    test(
      'HTTP 200 corrupt ZIP download rejects and preserves target',
      () async {
        final server = await _Dav.start();
        addTearDown(server.close);
        server.files['/dav/audit/nested/bad.zip'] = [1, 2, 3, 4];
        final target = await fixture('target');
        final before = _snapshot(target);
        final hashes = await _mediaHashes(target);
        await expectLater(
          restore(target).restoreFromRemote(
            config: server.config,
            entry: _entry('bad.zip'),
            onProgress: (_) {},
          ),
          throwsA(anything),
        );
        expect(_snapshot(target), before);
        expect(await _mediaHashes(target), hashes);
      },
    );

    test(
      'GET follows redirect and progress equals actual downloaded byte count',
      () async {
        final server = await _Dav.start();
        addTearDown(server.close);
        server.files['/dav/final.bin'] = List<int>.generate(
          131073,
          (i) => i % 251,
        );
        server.redirects['/dav/redirect.bin'] = '/dav/final.bin';
        final client = WebDavClient(
          baseUrl: server.baseUrl,
          username: 'audit-user',
          password: 'audit-pass',
        );
        addTearDown(client.close);
        final out = File(p.join(root.path, 'download.bin'));
        final progress = <int>[];
        await client.getFile(
          remotePath: 'redirect.bin',
          outputFile: out,
          onProgress: (n, total) {
            progress.add(n);
            expect(total, 131073);
          },
        );
        expect(await out.readAsBytes(), server.files['/dav/final.bin']);
        expect(progress.last, 131073);
        expect(server.requests.map((r) => r.path).toList(), [
          '/dav/redirect.bin',
          '/dav/final.bin',
        ]);
      },
    );

    test('DEFECT: stalled GET response body must respect configured request timeout', () async {
      final server = await _Dav.start();
      addTearDown(server.close);
      server.stallDownloadBody = true;
      server.files['/dav/stalled.bin'] = List<int>.filled(128, 7);
      final client = WebDavClient(
        baseUrl: server.baseUrl,
        username: 'u',
        password: 'p',
        requestTimeout: const Duration(milliseconds: 40),
      );
      addTearDown(client.close);
      var completed = false;
      Object? error;
      final operation = client
          .getFile(
            remotePath: 'stalled.bin',
            outputFile: File(p.join(root.path, 'stalled-download.bin')),
            onProgress: (_, _) {},
          )
          .then<void>(
            (_) {
              completed = true;
            },
            onError: (Object e) {
              completed = true;
              error = e;
            },
          );
      await server.downloadStarted.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final finishedWithinDeadline = completed;
      // Always clean up the live socket before the strict assertion fails.
      await client.close();
      server.releaseDownload();
      await operation.timeout(const Duration(seconds: 5));
      expect(
        finishedWithinDeadline,
        isTrue,
        reason: 'headers arrive immediately, but stalled response body waits beyond requestTimeout',
      );
      expect(error, isA<TimeoutException>());
      expect(
        await File(p.join(root.path, 'stalled-download.bin')).exists(),
        isFalse,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final leftovers = await Directory(root.path)
          .list()
          .where((e) => p.basename(e.path).contains('.part_'))
          .toList();
      expect(
        leftovers,
        isEmpty,
        reason:
            'timeout must close the download handle and never continue writing',
      );
    });

    test(
      'stalled PUT response body is bounded and aborts the upload',
      () async {
        final server = await _Dav.start();
        addTearDown(server.close);
        server.stallDownloadBody = true;
        final client = WebDavClient(
          baseUrl: server.baseUrl,
          username: 'u',
          password: 'p',
          requestTimeout: const Duration(milliseconds: 40),
        );
        addTearDown(client.close);
        final input = File(p.join(root.path, 'upload.bin'))
          ..writeAsBytesSync(List<int>.filled(4096, 1));
        final watch = Stopwatch()..start();
        await expectLater(
          client.putFile(
            remotePath: 'stalled-put.bin',
            file: input,
            onProgress: (_, _) {},
          ),
          throwsA(isA<TimeoutException>()),
        );
        watch.stop();
        expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      },
    );

    test('PROPFIND real request timeout returns useful failure', () async {
      final server = await _Dav.start(delay: const Duration(milliseconds: 150));
      addTearDown(server.close);
      final client = WebDavClient(
        baseUrl: server.baseUrl,
        username: 'u',
        password: 'p',
        requestTimeout: const Duration(milliseconds: 25),
      );
      addTearDown(client.close);
      final result = await client.test();
      expect(result.ok, isFalse);
      expect(result.message, contains('超时'));
      expect(server.requests.single.method, 'PROPFIND');
    });
  });

  group('backup config and preference state boundaries', () {
    test('ZIP omits SharedPreferences settings, edit protection, WebDAV secrets and history', () async {
      final source = await fixture('source');
      final target = await fixture('target');
      const sourceConfig = BackupConfig(
        webDavEnabled: true,
        webDavBaseUrl: 'https://source.example.test/dav',
        webDavUsername: 'source-user',
        webDavPassword: 'source-secret',
        webDavRemoteDir: 'backup',
        autoBackupEnabled: true,
        backupFrequency: BackupFrequency.weekly,
      );
      await BackupConfig.save(sourceConfig);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('edit_protection_enabled_v1', true);
      await preferences.setString('edit_protection_salt_v1', 'source-salt');
      await preferences.setString(
        'edit_protection_hash_v1',
        'source-password-hash',
      );
      await preferences.setString('audit_app_setting', 'source-only setting');
      await BackupStateStore.addHistory(_entry('source-history.zip'));
      final file = await zip(source);
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      expect(
        archive.files.every(
          (e) =>
              e.name == 'manifest.json' ||
              e.name == _dbEntry ||
              e.name.startsWith('media/'),
        ),
        isTrue,
      );
      SharedPreferences.setMockInitialValues({});
      await apply(target, file);
      final targetConfig = await BackupConfig.load();
      expect(targetConfig.webDavEnabled, isFalse);
      expect(targetConfig.webDavUsername, isEmpty);
      expect(targetConfig.webDavPassword, isEmpty);
      expect(targetConfig.autoBackupEnabled, isFalse);
      expect(await BackupStateStore.getHistory(), isEmpty);
      final targetPreferences = await SharedPreferences.getInstance();
      expect(targetPreferences.getKeys(), isEmpty);
      await targetPreferences.setString('audit_app_setting', 'target setting');
      await BackupConfig.save(
        sourceConfig.copyWith(
          webDavUsername: 'target-user',
          webDavPassword: 'target-secret',
        ),
      );
      await apply(target, file);
      expect((await BackupConfig.load()).webDavPassword, 'target-secret');
      expect(
        targetPreferences.getString('audit_app_setting'),
        'target setting',
      );
    });
    test(
      'current config normalizes URL and rejects unsafe remote directories',
      () async {
        expect(
          BackupConfig.parseAndNormalizeWebDavBaseUrl(
            ' https://example.test/dav?drop=1#x ',
          ).toString(),
          'https://example.test/dav',
        );
        for (final invalid in [
          'ftp://example.test',
          'example.test',
          'http://',
        ]) {
          expect(BackupConfig.parseAndNormalizeWebDavBaseUrl(invalid), isNull);
        }
        for (final invalid in [
          '../backup',
          'a/../b',
          'a/./b',
          '/absolute',
          r'a\b',
          'a//b',
        ]) {
          expect(BackupConfig.isValidWebDavRemoteDir(invalid), isFalse);
        }
        expect(BackupConfig.isValidWebDavRemoteDir('audit/nested.v1'), isTrue);
      },
    );

    test('history retains newest twenty and local/cloud failure state stay independent', () async {
      for (var i = 0; i < 25; i++) {
        await BackupStateStore.addHistory(
          BackupHistoryEntry(
            type: BackupHistoryType.manual,
            at: DateTime.fromMillisecondsSinceEpoch(i),
            fileName: '$i.zip',
            sizeBytes: i + 1,
          ),
        );
      }
      final history = await BackupStateStore.getHistory();
      expect(history.length, 20);
      expect(history.first.fileName, '24.zip');
      expect(history.last.fileName, '5.zip');
      await BackupStateStore.setLastFailure(
        target: BackupTarget.cloud,
        message: 'cloud failure',
      );
      await BackupStateStore.setLastFailure(
        target: BackupTarget.local,
        message: 'local failure',
      );
      await BackupStateStore.clearLastFailure(BackupTarget.local);
      expect(await BackupStateStore.getLastFailure(BackupTarget.local), isNull);
      expect(
        (await BackupStateStore.getLastFailure(BackupTarget.cloud))!.message,
        'cloud failure',
      );
    });
  });
}

File _database(Directory docs) => File(p.join(docs.path, _dbName));

Future<Directory> _fixture(
  Directory docs, {
  bool media = true,
  bool mediaReferences = true,
}) async {
  await docs.create(recursive: true);
  final drift = AppDatabase.forTesting(NativeDatabase(_database(docs)));
  try {
    await drift.customSelect('SELECT * FROM account_book').get();
  } finally {
    await drift.close();
  }
  final db = sql.sqlite3.open(_database(docs).path);
  try {
    db.execute('PRAGMA foreign_keys=ON');
    void insert(String table, Map<String, Object?> row) {
      db.execute(
        'INSERT INTO $table (${row.keys.join(',')}) VALUES (${List.filled(row.length, '?').join(',')})',
        row.values.toList(),
      );
    }

    for (var i = 1; i <= 3; i++) {
      insert('account_book', {
        'book_id': 'b$i',
        'name': '审计账簿$i',
        'reason_type': '自定义事由',
        'theme_color': '#10203$i',
        'icon': 'book-$i',
        'description': '账簿多行描述$i\n引号"逗号, Unicode 礼',
        'attachments': media && mediaReferences
            ? jsonEncode(
                i == 1
                    ? [
                        p.join(docs.path, 'media', 'book.bin'),
                        'https://example.test/book.jpg',
                      ]
                    : <String>[],
              )
            : null,
        'book_time': 1793700000000 + i,
        'is_default': i == 1 ? 1 : 0,
        'created_at': 1700000000000 + i,
        'updated_at': 1793700000100 + i,
        'deleted_at': i == 3 ? 1793700000203 : null,
      });
      insert('person', {
        'person_id': 'p$i',
        'book_id': 'b$i',
        'name': '联系人$i',
        'relationship_type': '亲友$i',
        'phone': '+86 1380000000$i',
        'birthday': 'lunar:1990-02-03',
        'anniversary': '2020-01-0$i',
        'avatar_uri': media && mediaReferences
            ? (i == 1
                  ? p.join(docs.path, 'media', 'avatar.bin')
                  : i == 2
                  ? 'https://example.test/avatar.jpg'
                  : 'media/深层/凭证.bin')
            : null,
        'note': '原始备注$i\n不应丢失',
        'created_at': 1700000000100 + i,
        'updated_at': 1793700000300 + i,
        'deleted_at': i == 3 ? 1793700000403 : null,
      });
    }
    for (var i = 1; i <= 4; i++) {
      insert('gift_record', {
        'record_id': 'g$i',
        'book_id': i == 4 ? 'b3' : 'b1',
        'person_id': i == 4 ? 'p3' : 'p1',
        'direction': i.isOdd ? '收入' : '支出',
        'amount_cent': i == 4 ? 99999999999999 : 10000 + i,
        'currency': i == 2 ? 'USD' : 'CNY',
        'event_name': '完整事件$i',
        'occurred_at': 1793700010000 + i,
        'note': '礼金长备注$i\n保留,"',
        'attachments': media && mediaReferences
            ? jsonEncode(
                i == 1
                    ? [
                        p
                            .join(docs.path, 'media', '深层', '凭证.bin')
                            .replaceAll('/', '\\'),
                      ]
                    : i == 2
                    ? ['media/book.bin']
                    : <String>[],
              )
            : null,
        'created_at': 1700000000200 + i,
        'updated_at': 1793700000500 + i,
        'deleted_at': i >= 3 ? 1793700000600 + i : null,
      });
    }
    for (var i = 1; i <= 2; i++) {
      insert('reason', {
        'reason_id': 'reason$i',
        'name': '自定义事由$i',
        'normalized_name': 'normalized-reason$i',
        'description': '事由描述$i',
        'enabled': i == 1 ? 1 : 0,
        'created_at': 1700000000300 + i,
        'updated_at': 1793700000700 + i,
      });
      insert('relation_type', {
        'type_id': 'type$i',
        'name': '关系类型$i',
        'normalized_name': 'normalized-type$i',
        'created_at': 1700000000400 + i,
        'updated_at': 1793700000800 + i,
      });
      insert('contact_relation', {
        'relation_id': 'relation$i',
        'person_a_id': 'p1',
        'person_b_id': i == 1 ? 'p2' : 'p3',
        'type_id': 'type$i',
        'note': '关系备注$i\n完整',
        'created_at': 1700000000500 + i,
        'updated_at': 1793700000900 + i,
      });
    }
    for (final entity in {
      'account_book': ['b1', 'b3'],
      'person': ['p1', 'p3'],
      'gift_record': ['g1', 'g3'],
    }.entries) {
      for (final id in entity.value) {
        insert('entity_remark', {
          'remark_id': 'remark-${entity.key}-$id',
          'entity_type': entity.key,
          'entity_id': id,
          'content': '追加备注 $id\n特殊字符, " \\ 中文',
          'created_at': 1793700001000,
        });
      }
    }
    for (final status in ['completed', 'canceled']) {
      insert('data_import_job', {
        'job_id': 'job-$status',
        'book_id': 'b1',
        'file_path': p.join(docs.path, 'external', 'source.csv'),
        'file_name': '原始数据.csv',
        'file_hash': 'file-hash-$status',
        'file_size': 1024,
        'format': 'csv',
        'status': status,
        'import_kind': 'gift_record',
        'mapping_json': '{"source":"name","custom":true}',
        'total_rows': 13,
        'processed_rows': 11,
        'success_rows': 7,
        'skipped_rows': 2,
        'failed_rows': 2,
        'byte_offset': 987,
        'last_row_index': 11,
        'error_log_path': p.join(docs.path, 'logs', 'errors.csv'),
        'started_at': 1793700002000,
        'finished_at': status == 'completed' ? 1793700002100 : null,
        'updated_at': 1793700002200,
      });
    }
  } finally {
    db.dispose();
  }
  if (media) {
    final samples = <String, List<int>>{
      'avatar.bin': List<int>.generate(1025, (i) => (i * 31) % 256),
      'book.bin': [0, 255, 1, 254, 2, 128],
      '深层/凭证.bin': utf8.encode('回收站附件\n原始媒体字节\u0000'),
      'unreferenced-empty.bin': [],
    };
    for (final entry in samples.entries) {
      final file = File(
        p.joinAll([docs.path, 'media', ...entry.key.split('/')]),
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
  }
  return docs;
}

_Snapshot _snapshot(Directory docs) => _snapshotFile(_database(docs));
_Snapshot _snapshotFile(File file) {
  final db = sql.sqlite3.open(file.path, mode: sql.OpenMode.readOnly);
  try {
    final actualTables = db
        .select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .map((r) => r['name'] as String)
        .toList();
    expect(
      actualTables,
      _tables,
      reason: 'fixture and snapshot must cover every actual application table',
    );
    return {
      for (final table in actualTables)
        table:
            db
                .select('SELECT * FROM "$table"')
                .map((r) => Map<String, Object?>.from(r))
                .toList()
              ..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b))),
    };
  } finally {
    db.dispose();
  }
}

_Snapshot _expectedRestore(
  _Snapshot original,
  Directory target, {
  bool includeMedia = true,
}) {
  final copied = (jsonDecode(jsonEncode(original)) as Map<String, dynamic>).map(
    (table, rows) => MapEntry(
      table,
      (rows as List).map((r) => Map<String, Object?>.from(r as Map)).toList(),
    ),
  );
  String rebase(String value) {
    if (value.startsWith('https://') || value.startsWith('http://')) {
      return value;
    }
    // Independent fixture oracle: recognize known media basenames, never call
    // product rebaseMedia or derive expected values from restored data.
    final portable = value.replaceAll('\\', '/');
    final suffix = portable.contains('/media/')
        ? portable.split('/media/').last
        : portable.substring('media/'.length);
    return p.joinAll([target.path, 'media', ...suffix.split('/')]);
  }

  for (final table in ['account_book', 'gift_record']) {
    for (final row in copied[table]!) {
      if (row['attachments'] != null) {
        row['attachments'] = includeMedia
            ? jsonEncode(
                (jsonDecode(row['attachments'] as String) as List)
                    .map((s) => rebase(s as String))
                    .toList(),
              )
            : null;
      }
    }
  }
  for (final row in copied['person']!) {
    if (row['avatar_uri'] != null) {
      row['avatar_uri'] = includeMedia
          ? rebase(row['avatar_uri'] as String)
          : null;
    }
  }
  for (final row in copied['data_import_job']!) {
    if (['running', 'pending', 'paused', 'failed'].contains(row['status'])) {
      row['status'] = 'canceled';
    }
  }
  for (final rows in copied.values) {
    rows.sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
  }
  return copied;
}

void _edit(Directory docs, String statements) {
  final db = sql.sqlite3.open(_database(docs).path);
  try {
    db.execute(statements);
  } finally {
    db.dispose();
  }
}

Future<Map<String, String>> _mediaHashes(Directory docs) async {
  final media = Directory(p.join(docs.path, 'media'));
  final hashes = <String, String>{};
  if (!await media.exists()) return hashes;
  await for (final entity in media.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      hashes[p.relative(entity.path, from: docs.path).replaceAll('\\', '/')] =
          sha256.convert(await entity.readAsBytes()).toString();
    }
  }
  return hashes;
}

Future<int> _mediaBytes(Directory docs) async {
  var total = 0;
  await for (final entry in Directory(
    p.join(docs.path, 'media'),
  ).list(recursive: true)) {
    if (entry is File) total += await entry.length();
  }
  return total;
}

Map<String, dynamic> _manifest(Archive archive) => Map<String, dynamic>.from(
  jsonDecode(
    utf8.decode(archive.findFile('manifest.json')!.content as List<int>),
  ) as Map,
);

Future<File> _rewrite(
  File input,
  Directory root, {
  Set<String> remove = const {},
  Map<String, List<int>> add = const {},
  void Function(Map<String, dynamic>)? manifestEdit,
}) async {
  final source = ZipDecoder().decodeBytes(await input.readAsBytes());
  final archive = Archive();
  for (final entry in source.files) {
    if (remove.contains(entry.name) || add.containsKey(entry.name)) continue;
    var bytes = entry.content as List<int>;
    if (entry.name == 'manifest.json' && manifestEdit != null) {
      final m = _manifest(source);
      manifestEdit(m);
      bytes = utf8.encode(jsonEncode(m));
    }
    archive.addFile(ArchiveFile(entry.name, bytes.length, bytes));
  }
  for (final entry in add.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  return File(
    p.join(root.path, 'changed-${DateTime.now().microsecondsSinceEpoch}.zip'),
  ).writeAsBytes(ZipEncoder().encode(archive)!);
}

Future<File> _rewriteDb(
  File input,
  Directory root, {
  String? sqlText,
  List<int>? bytes,
}) async {
  final archive = ZipDecoder().decodeBytes(await input.readAsBytes());
  if (bytes == null) {
    final staged = File(
      p.join(
        root.path,
        'edited-${DateTime.now().microsecondsSinceEpoch}.sqlite',
      ),
    );
    await staged.writeAsBytes(archive.findFile(_dbEntry)!.content as List<int>);
    final db = sql.sqlite3.open(staged.path);
    try {
      db.execute(sqlText!);
    } finally {
      db.dispose();
    }
    bytes = await staged.readAsBytes();
  }
  final payload = bytes;
  return _rewrite(
    input,
    root,
    add: {_dbEntry: payload},
    manifestEdit: (m) {
      m['dbSha256'] = sha256.convert(payload).toString();
      m['dbSizeBytes'] = payload.length;
    },
  );
}

Future<Directory> _guard(Directory docs) async {
  final guard = Directory(
    p.join(
      docs.path,
      'backups',
      'restore_guard',
      'audit-simulated-interruption',
    ),
  );
  await guard.create(recursive: true);
  for (final name in [_dbName, '$_dbName-wal', '$_dbName-shm']) {
    final file = File(p.join(docs.path, name));
    if (await file.exists()) await file.copy(p.join(guard.path, name));
  }
  final media = Directory(p.join(docs.path, 'media'));
  if (await media.exists()) {
    await for (final entry in media.list(recursive: true, followLinks: false)) {
      if (entry is! File) continue;
      final dest = File(
        p.join(guard.path, 'media', p.relative(entry.path, from: media.path)),
      );
      await dest.parent.create(recursive: true);
      await entry.copy(dest.path);
    }
  }
  return guard;
}

BackupHistoryEntry _entry(String name) => BackupHistoryEntry(
  type: BackupHistoryType.manual,
  at: DateTime(2026, 11, 4),
  fileName: name,
  sizeBytes: 4,
);

class _Request {
  _Request(HttpRequest request)
    : method = request.method,
      path = request.uri.path,
      auth = request.headers.value(HttpHeaders.authorizationHeader),
      agent = request.headers.value(HttpHeaders.userAgentHeader);
  final String method;
  final String path;
  final String? auth;
  final String? agent;
}

class _Dav {
  _Dav(this.server, this.statuses, this.delay);
  final HttpServer server;
  final Map<String, int> statuses;
  final Duration delay;
  final files = <String, List<int>>{};
  final requests = <_Request>[];
  final redirects = <String, String>{};
  final pending = <Future<void>>[];
  bool stallDownloadBody = false;
  final downloadStarted = Completer<void>();
  final _downloadRelease = Completer<void>();
  void releaseDownload() {
    if (!_downloadRelease.isCompleted) _downloadRelease.complete();
  }

  Uri get baseUrl => Uri.parse('http://127.0.0.1:${server.port}/dav/');
  BackupConfig get config => BackupConfig(
    webDavEnabled: true,
    webDavBaseUrl: baseUrl.toString(),
    webDavUsername: 'audit-user',
    webDavPassword: 'audit-pass',
    webDavRemoteDir: 'audit/nested',
    autoBackupEnabled: false,
    backupFrequency: BackupFrequency.daily,
  );
  static Future<_Dav> start({
    Map<String, int> statuses = const {},
    Duration delay = Duration.zero,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final result = _Dav(server, statuses, delay);
    server.listen((request) {
      result.pending.add(result.handle(request));
    });
    return result;
  }

  Future<void> handle(HttpRequest request) async {
    requests.add(_Request(request));
    final body = await request.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    final response = request.response;
    try {
      final forced = statuses[request.method];
      if (forced != null) {
        response.statusCode = forced;
      } else if (request.method == 'PROPFIND') {
        response.statusCode = 207;
        response.write('<d:multistatus xmlns:d="DAV:"/>');
      } else if (request.method == 'MKCOL') {
        response.statusCode = 201;
      } else if (request.method == 'PUT') {
        files[request.uri.path] = body;
        response.statusCode = 201;
        if (stallDownloadBody) {
          await response.flush();
          await _downloadRelease.future;
        }
      } else if (request.method == 'GET') {
        final redirect = redirects[request.uri.path];
        if (redirect != null) {
          response.statusCode = 302;
          response.headers.set(HttpHeaders.locationHeader, redirect);
        } else {
          final bytes = files[request.uri.path];
          response.statusCode = bytes == null ? 404 : 200;
          if (bytes != null) {
            response.contentLength = bytes.length;
            if (stallDownloadBody) {
              response.add(bytes.sublist(0, 1));
              await response.flush();
              downloadStarted.complete();
              await _downloadRelease.future;
              response.add(bytes.sublist(1));
            } else {
              response.add(bytes);
            }
          }
        }
      } else {
        response.statusCode = 405;
      }
      await response.close();
    } on HttpException {
      /* client timeout/close */
    } on SocketException {
      /* client timeout/close */
    }
  }

  Future<void> close() async {
    releaseDownload();
    await server.close(force: true);
    await Future.wait(pending);
  }
}
