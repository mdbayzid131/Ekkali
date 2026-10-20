import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/firebase_notification_service.dart';
import 'package:moeb_26/data/models/notification_payload.dart';
import 'package:moeb_26/data/models/notifications_model.dart';
import 'package:moeb_26/modules/notifications/widgets/broadcast_notification_card.dart';

NotificationItem announcement({String? image}) => NotificationItem.fromJson({
  '_id': 'announcement',
  'type': 'ADMIN',
  'title': 'Community update',
  'text': 'A full description from the dashboard.',
  'isBroadcast': true,
  'createdAt': '2026-10-20T10:20:53Z',
  'image': image,
});

void main() {
  tearDown(() {
    Get.reset();
  });

  test(
    'REST broadcast fields parse without treating other ADMIN notices as broadcasts',
    () {
      final item = announcement();
      expect(item.isBroadcast, isTrue);
      expect(item.subtitle, 'A full description from the dashboard.');
      expect(item.imageUrl, isNull);
      expect(
        NotificationPayload.isBroadcast({
          'type': 'ADMIN',
          'metadata': {'eventType': 'USER_STATUS_UPDATED'},
        }),
        isFalse,
      );
      expect(
        NotificationPayload.isBroadcast({
          'isBroadcast': 'false',
          'type': 'ADMIN',
        }),
        isFalse,
      );
    },
  );

  test('FCM encoded metadata and nested broadcast IDs are recognised', () {
    expect(
      NotificationPayload.isBroadcast({
        'type': 'ADMIN',
        'metadata': jsonEncode({
          'broadcast': true,
          'broadcastId': 'broadcast-1',
        }),
      }),
      isTrue,
    );
    expect(
      NotificationPayload.isBroadcast({
        'data': jsonEncode({
          'metadata': {'broadcastId': 'broadcast-1'},
        }),
      }),
      isTrue,
    );
    expect(NotificationPayload.isBroadcast({'type': 'BROADCAST'}), isTrue);
  });

  test(
    'image paths and nested dashboard descriptions survive read-state updates',
    () {
      final item = NotificationItem.fromJson({
        '_id': 'a',
        'type': 'ADMIN',
        'metadata': {'broadcast': true, 'imageUrl': '/uploads/banner.jpg'},
        'title': 'Title',
        'description': 'Description',
      });
      expect(item.imageUrl, endsWith('/uploads/banner.jpg'));
      expect(Uri.parse(item.imageUrl!).hasScheme, isTrue);
      expect(item.subtitle, 'Description');
      final read = item.copyWith(isRead: true);
      expect(read.isBroadcast, isTrue);
      expect(read.imageUrl, item.imageUrl);
      expect(
        NotificationPayload.imageUrl({
          'image': 'https://example.com/banner.jpg',
        }),
        'https://example.com/banner.jpg',
      );
      expect(
        NotificationPayload.imageUrl({'image': 'javascript:alert(1)'}),
        isNull,
      );
    },
  );

  testWidgets(
    'broadcast card has full text, no category icon and no tap action',
    (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(376, 856),
          builder: (_, child) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BroadcastNotificationCard(notification: announcement()),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Community update'), findsOneWidget);
      expect(
        find.text('A full description from the dashboard.'),
        findsOneWidget,
      );
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      await tester.tap(find.text('Community update'));
      await tester.pump();
      expect(find.text('Community update'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'broadcast image spans the card above its title and description',
    (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(376, 856),
          builder: (_, child) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BroadcastNotificationCard(
                  notification: announcement(
                    image: 'https://example.com/banner.jpg',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final finder = find.byKey(const ValueKey('broadcast-image'));
      expect(finder, findsOneWidget);
      expect(tester.widget<Image>(finder).width, double.infinity);
      expect(
        tester.getTopLeft(finder).dy,
        lessThan(tester.getTopLeft(find.text('Community update')).dy),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'broadcast push and unified router leave the current page and overlays intact',
    (tester) async {
      Get.testMode = true;
      await tester.pumpWidget(
        GetMaterialApp(home: const Scaffold(body: Text('Current page'))),
      );
      final currentRoute = Get.currentRoute;
      Get.bottomSheet(
        const Material(
          child: SizedBox(height: 100, child: Text('Existing sheet')),
        ),
      );
      await tester.pumpAndSettle();
      FirebaseNotificationService.navigateToNotificationTarget(
        type: 'ADMIN',
        title: 'Vehicle document update',
        data: {
          'isBroadcast': true,
          'resourceType': 'JOB',
          'jobId': 'job-1',
          'link': {'url': 'https://example.com'},
        },
      );
      FirebaseNotificationService.handleNotificationMessage(
        RemoteMessage(
          data: {
            'type': 'ADMIN',
            'metadata': jsonEncode({'broadcast': true}),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(Get.currentRoute, currentRoute);
      expect(find.text('Current page'), findsOneWidget);
      expect(find.text('Existing sheet'), findsOneWidget);
      Get.back();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('ordinary notifications retain their default navigation', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: Text('Home')),
        getPages: [
          GetPage(
            name: Routes.notificationsView,
            page: () => const Scaffold(body: Text('Notification destination')),
          ),
        ],
      ),
    );
    FirebaseNotificationService.navigateToNotificationTarget(
      type: 'GENERAL',
      data: {'type': 'GENERAL'},
    );
    await tester.pumpAndSettle();
    expect(find.text('Notification destination'), findsOneWidget);
  });
}
