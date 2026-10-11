import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/export/account_book_pdf_export_service.dart';
import 'package:newshangli/platform/app_platform.dart';
import 'package:newshangli/platform/flutter_platform_adapter.dart';

class _Platform extends FlutterPlatformAdapter {
  _Platform(this.directory);
  final Directory directory;
  @override
  Future<Directory> documentsDirectory() async => directory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  final service = AccountBookPdfExportService();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    for (final id in ['default', 'other']) {
      await db.accountBooksDao.insertOne(
        AccountBooksCompanion.insert(
          bookId: Value(id),
          name: '账簿/$id',
          createdAt: 1,
          updatedAt: 1,
        ),
      );
      await db.personsDao.insertOne(
        PersonsCompanion.insert(
          personId: Value(id),
          bookId: id,
          name: '张三$id',
          createdAt: 1,
          updatedAt: 1,
        ),
      );
    }
    Future<void> record(
      String id,
      String book,
      String direction,
      int time, {
      bool deleted = false,
    }) async {
      await db.giftRecordsDao.insertOne(
        GiftRecordsCompanion.insert(
          recordId: Value(id),
          bookId: book,
          personId: book,
          amountCent: 12345,
          direction: Value(direction),
          occurredAt: time,
          eventName: const Value('结婚'),
          note: const Value('祝福'),
          deletedAt: Value(deleted ? 1 : null),
          createdAt: 1,
          updatedAt: 1,
        ),
      );
    }

    await record('default-income', 'default', '收入', 3000);
    await record('other-expense', 'other', '支出', 1000);
    await record('other-income', 'other', '收入', 2000);
    await record('deleted', 'other', '收入', 4000, deleted: true);
  });
  tearDown(() => db.close());

  test('普通账簿仅导出本簿有效记录，保留金额事由备注并按时间排序', () async {
    final request = await service.buildRequest(db, 'other');
    expect(request.rows.map((r) => r.direction), ['支出', '收入']);
    expect(request.rows.map((r) => r.personName), ['张三other', '张三other']);
    expect(request.rows.first.amountCent, 12345);
    expect(request.rows.first.eventName, '结婚');
    expect(request.rows.first.note, '祝福');
    expect(request.rows.map((r) => r.occurredAt.millisecondsSinceEpoch), [
      1000,
      2000,
    ]);
    expect(request.reason, '礼金往来');
    expect(
      request.bookDate.millisecondsSinceEpoch,
      (await db.accountBooksDao.findById('other'))!.bookTime,
    );
    expect(request.amountTotalCent, 0);
  });

  test('默认账簿与详情页一致：本簿收入及跨簿支出', () async {
    final request = await service.buildRequest(db, 'default');
    expect(request.rows.map((r) => r.direction), ['支出', '收入']);
    expect(request.rows.map((r) => r.personName), ['张三other', '张三default']);
  });

  test('空账簿和已删除账簿拒绝导出', () async {
    await db.delete(db.giftRecords).go();
    await expectLater(service.buildRequest(db, 'other'), throwsStateError);
    await (db.update(db.accountBooks)..where((b) => b.bookId.equals('other')))
        .write(const AccountBooksCompanion(deletedAt: Value(1)));
    await expectLater(service.buildRequest(db, 'other'), throwsStateError);
    await expectLater(service.buildRequest(db, 'missing'), throwsStateError);
  });

  test('系统字体离线生成真实 PDF，文件名安全且每次导出独立保存', () async {
    final directory = Directory.systemTemp.createTempSync('ledger_pdf_test_');
    final previous = AppPlatform.instance;
    AppPlatform.instance = _Platform(directory);
    try {
      final first = await service.export(db, 'other');
      final second = await service.export(db, 'other');
      final book = (await db.accountBooksDao.findById('other'))!;
      final date = DateTime.fromMillisecondsSinceEpoch(book.bookTime);
      final dateText =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      expect(
        first.parent.parent.path,
        endsWith('${Platform.pathSeparator}pdf'),
      );
      expect(first.uri.pathSegments.last, '账簿_other账簿$dateText.pdf');
      expect(second.uri.pathSegments.last, first.uri.pathSegments.last);
      expect(second.path, isNot(first.path));
      expect(
        String.fromCharCodes((await first.readAsBytes()).take(5)),
        '%PDF-',
      );
      expect(await first.length(), greaterThan(1000));
    } finally {
      AppPlatform.instance = previous;
      directory.deleteSync(recursive: true);
    }
  });
}
