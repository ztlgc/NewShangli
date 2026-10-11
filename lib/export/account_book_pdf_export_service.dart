import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/local/drift/app_database.dart';
import '../platform/app_platform.dart';
import 'ledger_pdf_system_text.dart';
import 'ledger_pdf_service.dart';

/// Exports the same record scope shown on the account book detail page.
class AccountBookPdfExportService {
  Future<LedgerPrintRequest> buildRequest(AppDatabase db, String bookId) async {
    final book = await db.accountBooksDao.findById(bookId);
    if (book == null || book.deletedAt != null) {
      throw StateError('账簿不存在或已删除');
    }
    final records =
        await (book.isDefault == 1
                ? db.giftRecordsDao.watchAllWithPersonInDefaultScope(bookId)
                : db.giftRecordsDao.watchAllWithPersonInBook(bookId))
            .first;
    if (records.isEmpty) throw StateError('暂无可导出的记录');
    final rows = records.map((entry) {
      final record = entry.record;
      return LedgerPrintRow(
        occurredAt: DateTime.fromMillisecondsSinceEpoch(record.occurredAt),
        direction: record.direction,
        amountCent: record.amountCent,
        personName: entry.person.name,
        eventName: record.eventName ?? '',
        note: record.note ?? '',
      );
    }).toList()..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return LedgerPrintRequest(
      bookName: book.name,
      reason: book.reasonType.trim().isEmpty ? '礼金往来' : book.reasonType,
      bookDate: DateTime.fromMillisecondsSinceEpoch(book.bookTime),
      rows: rows,
    );
  }

  Future<File> export(AppDatabase db, String bookId) async {
    final request = await buildRequest(db, bookId);
    final bytes = await const LedgerPdfService().generatePdf(
      request: request,
      renderText: renderLedgerPdfSystemText,
    );
    final root = await AppPlatform.documentsDirectory();
    final directory = Directory(p.join(root.path, 'exports', 'pdf'));
    await directory.create(recursive: true);
    final name = request.bookName
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
        .trim();
    // Keep filenames safe even when a book has a very long name.
    final safeName = String.fromCharCodes(name.runes.take(40));
    final date = request.bookDate;
    final dateText =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    // Separate export folders keep the requested filename without overwriting
    // a PDF that the user may already be sharing.
    final exportDirectory = await directory.createTemp();
    final file = File(p.join(exportDirectory.path, '$safeName账簿$dateText.pdf'));
    try {
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      if (await file.exists()) await file.delete();
      await exportDirectory.delete();
      rethrow;
    }
  }
}
