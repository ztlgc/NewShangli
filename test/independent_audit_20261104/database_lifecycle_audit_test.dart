import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/data/local/drift/app_database.dart';
import 'package:newshangli/ui/app_database_scope.dart';

class _TrackedDatabase extends AppDatabase {
  _TrackedDatabase() : super.forTesting(NativeDatabase.memory());
  bool wasClosed = false;
  @override
  Future<void> close() async {
    wasClosed = true;
    await super.close();
  }
}

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets(
    'LC01 restore action closes database and refreshes dependent widgets',
    (tester) async {
      final opened = <_TrackedDatabase>[];
      AppDatabaseControllerScope? controller;
      AppDatabase? visible;
      await tester.pumpWidget(
        AppDatabaseProvider(
          databaseFactory: () {
            final db = _TrackedDatabase();
            opened.add(db);
            return db;
          },
          child: Builder(
            builder: (context) {
              controller = AppDatabaseControllerScope.of(context);
              visible = AppDatabaseScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      final first = visible!;
      await tester.runAsync(() async {
        await first.customSelect('SELECT 1').get();
        await controller!.withDatabasePaused(() async {
          expect(opened.single.wasClosed, isTrue);
          return 'restored';
        });
      });
      await tester.pump();
      expect(opened.length, 2);
      expect(visible, same(opened.last));
      expect(visible, isNot(same(first)));
      expect(opened.last.wasClosed, isFalse);
      await tester.runAsync(() async {
        expect(
          (await visible!.customSelect('SELECT 1 AS ok').get())
              .single
              .data['ok'],
          1,
        );
      });
      await tester.pumpWidget(const SizedBox());
      expect(opened.last.wasClosed, isTrue);
    },
  );

  testWidgets('LC02 restore exception reopens database and allows retry', (
    tester,
  ) async {
    final opened = <_TrackedDatabase>[];
    AppDatabaseControllerScope? controller;
    await tester.pumpWidget(
      AppDatabaseProvider(
        databaseFactory: () {
          final db = _TrackedDatabase();
          opened.add(db);
          return db;
        },
        child: Builder(
          builder: (context) {
            controller = AppDatabaseControllerScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      await expectLater(
        controller!.withDatabasePaused(() async {
          throw StateError('injected restore failure');
        }),
        throwsStateError,
      );
      expect(opened.length, 2);
      expect(opened.first.wasClosed, isTrue);
      expect(opened.last.wasClosed, isFalse);
      expect(
        await controller!.withDatabasePaused(() async => 'retry completed'),
        'retry completed',
      );
      expect(opened.length, 3);
    });
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('LC03 second restore cannot overlap a pending restore', (
    tester,
  ) async {
    final opened = <_TrackedDatabase>[];
    AppDatabaseControllerScope? controller;
    await tester.pumpWidget(
      AppDatabaseProvider(
        databaseFactory: () {
          final db = _TrackedDatabase();
          opened.add(db);
          return db;
        },
        child: Builder(
          builder: (context) {
            controller = AppDatabaseControllerScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      final gate = Completer<void>();
      final first = controller!.withDatabasePaused(() => gate.future);
      var secondCalled = false;
      await expectLater(
        controller!.withDatabasePaused(() async {
          secondCalled = true;
        }),
        throwsStateError,
      );
      expect(secondCalled, isFalse);
      gate.complete();
      await first;
      expect(opened.length, 2);
    });
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });
}
