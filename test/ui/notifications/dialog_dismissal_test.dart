import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_dialog.dart';
import 'package:newshangli/ui/app_bottom_sheet.dart';

void main() {
  for (final size in [const Size(393, 852), const Size(852, 393)]) {
    for (final action in ['close', 'back', 'barrier']) {
      testWidgets('picker $action dismisses at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var completed = false;
        String? result = 'pending';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  child: const Text('open'),
                  onPressed: () async {
                    result = await AppBottomSheet.showPicker<String>(
                      context,
                      title: 'picker',
                      options: const [
                        AppSheetOption(label: 'first', value: '1'),
                      ],
                    );
                    completed = true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        if (action == 'close') {
          await tester.tap(find.bySemanticsLabel('关闭'));
        } else if (action == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tapAt(const Offset(5, 5));
        }
        await tester.pumpAndSettle();
        expect(completed, isTrue);
        expect(result, isNull);
        expect(find.text('picker'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('input remains usable with keyboard at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      Map<String, String>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('open'),
                onPressed: () async {
                  result = await AppDialog.showInput(
                    context,
                    title: 'password',
                    confirmLabel: 'save',
                    fields: const [
                      AppDialogField(id: 'p1', label: 'first'),
                      AppDialogField(id: 'p2', label: 'second'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(
        bottom: size.height > 500 ? 300 : 180,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(EditableText).at(0), '1234');
      await tester.enterText(find.byType(EditableText).at(1), '1234');
      await tester.ensureVisible(find.text('save'));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.text('save')).dy,
        lessThan(size.height - (size.height > 500 ? 300 : 180)),
      );
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();
      expect(result, {'p1': '1234', 'p2': '1234'});
      expect(tester.takeException(), isNull);
    });
    for (final action in ['save', 'cancel', 'back', 'barrier']) {
      testWidgets('input $action closes and returns correct values at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Map<String, String>? result;
        var completed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  child: const Text('open'),
                  onPressed: () async {
                    result = await AppDialog.showInput(
                      context,
                      title: 'password',
                      confirmLabel: 'save',
                      cancelLabel: 'cancel',
                      fields: const [
                        AppDialogField(
                          id: 'p1',
                          label: 'first',
                          obscureText: true,
                        ),
                        AppDialogField(
                          id: 'p2',
                          label: 'second',
                          obscureText: true,
                        ),
                      ],
                    );
                    completed = true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText).at(0), '1234');
        await tester.enterText(find.byType(EditableText).at(1), '1234');
        if (action == 'back') {
          await tester.binding.handlePopRoute();
        } else if (action == 'barrier') {
          await tester.tapAt(const Offset(5, 5));
        } else {
          await tester.tap(find.text(action));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(completed, isTrue);
        expect(find.text('password'), findsNothing);
        expect(
          result,
          action == 'save' ? {'p1': '1234', 'p2': '1234'} : isNull,
        );
        // Opening again catches disposed controllers and stuck modal routes.
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
    for (final confirm in [true, false]) {
      testWidgets('confirmation $confirm closes at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                child: const Text('open'),
                onPressed: () async {
                  result = await AppDialog.confirm(
                    context,
                    title: 'question',
                    confirmLabel: 'yes',
                    cancelLabel: 'no',
                  );
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(confirm ? 'yes' : 'no'));
        await tester.pumpAndSettle();
        expect(result, confirm);
        expect(find.text('question'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('alert closes at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              child: const Text('open'),
              onPressed: () async {
                await AppDialog.showAlert(
                  context,
                  title: 'alert',
                  closeLabel: 'close',
                );
                completed = true;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(find.text('alert'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
