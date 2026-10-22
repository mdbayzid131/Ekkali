import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeb_26/core/widgets/DeleteAccountBottomSheet.dart';

void main() {
  testWidgets('delete sheet stays above keyboard with reachable controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(376, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const DeleteAccountBottomSheet(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextFormField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 330);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'example-password');
    expect(tester.getTopLeft(find.text('Delete account?')).dy, greaterThan(16));
    expect(tester.getBottomLeft(find.text('Delete account')).dy, lessThan(470));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Show password'));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteAccountBottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short screen scrolls and empty password shows inline error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 320,
              height: 280,
              child: DeleteAccountBottomSheet(),
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

