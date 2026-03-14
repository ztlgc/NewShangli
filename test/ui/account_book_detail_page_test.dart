import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';
import 'package:newshangli/ui/app_session.dart';
import 'package:newshangli/ui/pages/account_book_detail_page.dart';

void main() {
  testWidgets('账簿详情显示概览与收礼记录列表', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final now = DateTime.now().millisecondsSinceEpoch;
    const bookId = 'book_1';
    const personId = 'person_1';

    await db.accountBooksDao.insertOne(
      AccountBooksCompanion.insert(
        bookId: const Value(bookId),
        name: '礼金账簿',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.personsDao.insertOne(
      PersonsCompanion.insert(
        personId: const Value(personId),
        bookId: bookId,
        name: '李四',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.giftRecordsDao.insertOne(
      GiftRecordsCompanion.insert(
        bookId: bookId,
        personId: personId,
        amountCent: 88800,
        direction: const Value('收入'),
        eventName: const Value('结婚礼金'),
        paymentMethod: const Value('微信'),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        session: AppSession(),
        child: AppDatabaseScope(
          db: db,
          child: const MaterialApp(
            home: AccountBookDetailPage(bookId: bookId),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('总收入'), findsOneWidget);
    expect(find.text('记录数量'), findsOneWidget);
    expect(find.text('暂无记录'), findsOneWidget);
    final importIcon = find.byIcon(FontAwesomeIcons.fileImport);
    expect(importIcon, findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await db.close();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
