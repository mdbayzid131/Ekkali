import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/widgets/android_navigation_safe_area.dart';
import 'package:moeb_26/modules/my_schedule/controllers/my_schedule_controller.dart';
import 'package:moeb_26/modules/my_schedule/views/widgets/add_schedule_job_sheet.dart';

class SafeAreaScheduleController extends MyScheduleController {
  @override
  Future<void> fetchCalendarJobs({DateTime? targetDate}) async {}
}

void main() {
  tearDown(() {
    Get.reset();
  });

  void configureView(WidgetTester tester, double bottom) {
    tester.view.physicalSize = const Size(376, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(top: 24, bottom: bottom);
    tester.view.viewPadding = FakeViewPadding(top: 24, bottom: bottom);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);
  }

  for (final inset in [0.0, 24.0, 48.0]) {
    testWidgets(
      'bottom actions respect $inset system inset without double padding',
      (tester) async {
        configureView(tester, inset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (_, child) => AndroidNavigationSafeArea(child: child!),
            home: Scaffold(
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      key: const Key('action'),
                      height: 50,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(
          tester.getBottomLeft(find.byKey(const Key('action'))).dy,
          800 - inset,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'private booking save button scrolls above Android system buttons',
    (tester) async {
      configureView(tester, 48);
      Get.put<MyScheduleController>(SafeAreaScheduleController());
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(376, 856),
          builder: (_, child) => GetMaterialApp(
            builder: (_, child) => AndroidNavigationSafeArea(child: child!),
            home: const AddScheduleJobSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Direct Booking'));
      await tester.pumpAndSettle();
      final button = find.ancestor(
        of: find.text('Save Direct Booking'),
        matching: find.byType(ElevatedButton),
      );
      expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(752));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('modal bottom sheets also stay above system navigation', (
    tester,
  ) async {
    configureView(tester, 48);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => AndroidNavigationSafeArea(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const SizedBox(
                  key: Key('modal'),
                  height: 120,
                  width: double.infinity,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.byKey(const Key('modal'))).dy, 752);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard inset is handled once by Scaffold', (tester) async {
    configureView(tester, 48);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = const FakeViewPadding(top: 24);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => AndroidNavigationSafeArea(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              Container(key: const Key('keyboard-action'), height: 50),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getBottomLeft(find.byKey(const Key('keyboard-action'))).dy,
      500,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS keeps its existing page-level safe area behaviour', (
    tester,
  ) async {
    configureView(tester, 34);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => AndroidNavigationSafeArea(child: child!),
        home: Scaffold(body: Container(key: const Key('ios-body'))),
      ),
    );
    expect(tester.getBottomLeft(find.byKey(const Key('ios-body'))).dy, 800);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
